import 'dart:async';
import 'dart:convert'; // For jsonEncode/Decode if needed for tool results

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // To get server list and Gemini key
import 'package:flutter_memos/services/gemini_service.dart'; // Import GeminiService
import 'package:flutter_memos/services/mcp_sse_client_transport.dart'; // Import the new SSE transport
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Import for Gemini types
// Import the rest with a prefix
import 'package:mcp_dart/mcp_dart.dart' as mcp_dart;
// Import Transport directly as it's not exported by the main library file
import 'package:mcp_dart/src/shared/transport.dart';

// --- Helper Extension (Schema parsing - adapted from example) ---
// Uses google_generative_ai.Schema
extension SchemaExtension on Schema {
  static Schema? fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final description = json['description'] as String?;
    switch (type) {
      case 'object':
        final properties = json['properties'] as Map<String, dynamic>?;
        if (properties == null || properties.isEmpty) {
          // Allow object schema without properties for tools that take no arguments
          // Pass an empty map for the required 'properties' argument
          return Schema.object(properties: {}, description: description);
        }
        try {
          return Schema.object(
            properties: properties.map(
              (key, value) => MapEntry(
                key,
                SchemaExtension.fromJson(value as Map<String, dynamic>)!,
              ),
            ),
            // Note: Gemini API might require explicit required properties if needed
            // requiredProperties: properties.keys.toList(),
            description: description,
          );
        } catch (e) {
          debugPrint(
            "Error parsing object properties for schema: $json. Error: $e",
          );
          throw FormatException(
            "Invalid properties definition in object schema",
            json,
          );
        }
      case 'string':
        final enumValues = (json['enum'] as List<dynamic>?)?.cast<String>();
        return enumValues != null
            ? Schema.enumString(
                enumValues: enumValues,
                description: description,
              )
            : Schema.string(description: description);
      case 'number':
      case 'integer': // Treat integer as number for Gemini
        return Schema.number(description: description);
      case 'boolean':
        return Schema.boolean(description: description);
      case 'array':
        final items = json['items'] as Map<String, dynamic>?;
        if (items == null) {
          throw FormatException(
            "Array schema must have an 'items' definition.",
            json,
          );
        }
        try {
          return Schema.array(
            items: SchemaExtension.fromJson(items)!,
            description: description,
          );
        } catch (e) {
          debugPrint("Error parsing array items for schema: $json. Error: $e");
          throw FormatException(
            "Invalid 'items' definition in array schema",
            json,
          );
        }
      default:
        debugPrint("Unsupported schema type encountered: $type");
        throw UnsupportedError("Unsupported schema type: $type");
    }
  }
}

// --- Result Type (Adapted from example - for potential future chat use) ---
// Uses google_generative_ai.Content
@immutable
class McpProcessResult {
  final Content? modelCallContent;
  final Content? toolResponseContent;
  final Content finalModelContent;
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final String? toolResult;
  final String? sourceServerId;

  const McpProcessResult({
    required this.finalModelContent,
    this.modelCallContent,
    this.toolResponseContent,
    this.toolName,
    this.toolArgs,
    this.toolResult,
    this.sourceServerId,
  });
}

// --- Connection Status Enum ---
enum McpConnectionStatus { disconnected, connecting, connected, error }

// --- Single MCP Client Wrapper Logic ---
// Uses google_generative_ai.GenerativeModel, google_generative_ai.Tool, google_generative_ai.FunctionDeclaration
// Uses mcp_dart types
class GoogleMcpClient {
  final String serverId;
  final mcp_dart.Client mcp;
  final GenerativeModel? model;
  // Use the directly imported Transport type
  Transport? _transport;
  List<Tool> _tools = [];
  bool _isConnected = false;
  Function(String serverId, String errorMsg)? _onError;
  // Add the missing onClose callback field
  Function(String serverId)? _onClose;

  bool get isConnected => _isConnected;
  List<Tool> get availableTools => List.unmodifiable(_tools);

  GoogleMcpClient(this.serverId, this.model)
      : mcp = mcp_dart.Client(
          const mcp_dart.Implementation(
            name: "flutter-memos-mcp-client",
            version: "1.0.0",
          ),
        );

  void setupCallbacks({
    Function(String serverId, String errorMsg)? onError,
    Function(String serverId)? onClose,
  }) {
    _onError = onError;
    _onClose = onClose;
  }

  // Modified to accept McpServerConfig
  Future<void> connectToServer(
    McpServerConfig config,
  ) async {
    if (_isConnected) return;
    _isConnected = false; // Reset connection status at the start
    _tools = []; // Clear tools

    debugPrint(
      "GoogleMcpClient [${config.id}]: Attempting SSE connection to manager at ${config.host}:${config.port}...",
    );

    try {
      // --- Always use SseClientTransport ---
      debugPrint(
        "GoogleMcpClient [${config.id}]: Creating SseClientTransport for manager at ${config.host}:${config.port}",
      );
      _transport = SseClientTransport(
        managerHost: config.host,
        managerPort: config.port,
        // ssePath: '/sse', // Use default or make configurable if needed
      );

      // --- Setup common callbacks ---
      _transport!.onerror = (error) {
        final errorMsg = "MCP SSE Transport error [${config.id}]: $error";
        debugPrint(errorMsg);
        _isConnected = false;
        _onError?.call(config.id, errorMsg);
        cleanup();
      };

      _transport!.onclose = () {
        debugPrint("MCP SSE Transport closed [${config.id}].");
        _isConnected = false;
        _onClose?.call(config.id);
        _transport = null;
        _tools = [];
      };

      // --- Connect using the chosen transport ---
      await mcp.connect(_transport!);
      _isConnected = true;
      debugPrint("GoogleMcpClient [${config.id}]: SSE Transport connected successfully.");
      debugPrint(
        "GoogleMcpClient [${config.id}]: Connection successful, proceeding to fetch tools...",
      );
      await _fetchTools();
    } catch (e) {
      String specificErrorDetails = "$e";
      debugPrint(
        "GoogleMcpClient [${config.id}]: Failed to establish SSE connection: $specificErrorDetails",
      );
      _isConnected = false;
      throw StateError(
        "SSE Connection failed for ${config.name} [${config.id}]: $specificErrorDetails",
      );
    }
  }

  Future<void> _fetchTools() async {
    if (!_isConnected) {
      _tools = [];
      return;
    }
    debugPrint("GoogleMcpClient [\$serverId]: Fetching tools...");
    try {
      final toolsResult = await mcp.listTools();
      List<Tool> fetchedTools = [];
      for (var toolDef in toolsResult.tools) {
        try {
          final schemaJson = toolDef.inputSchema.toJson();
          final schema = SchemaExtension.fromJson(schemaJson);
          if (schema != null ||
              (schemaJson['type'] == 'object' &&
                  (schemaJson['properties'] == null ||
                      (schemaJson['properties'] as Map).isEmpty))) {
            fetchedTools.add(
              Tool(
                functionDeclarations: [
                  FunctionDeclaration(
                    toolDef.name,
                    toolDef.description ?? 'No description provided.',
                    schema,
                  ),
                ],
              ),
            );
          } else {
            debugPrint(
              "Warning [\$serverId]: Skipping tool '\${toolDef.name}' due to unexpected null schema after parsing non-empty object.",
            );
          }
        } catch (e) {
          debugPrint(
            "Error processing schema for tool '\${toolDef.name}' [\$serverId]: \$e. Skipping tool.",
          );
        }
      }
      _tools = fetchedTools;
      debugPrint(
        "GoogleMcpClient [\$serverId]: Processed tools for Gemini: \${_tools.map((t) => t.functionDeclarations?.map((fd) => fd.name) ?? 'null').toList()}",
      );
      debugPrint(
        "GoogleMcpClient [\$serverId]: Successfully processed \${_tools.length} tools.",
      );
    } catch (e) {
      debugPrint(
        "GoogleMcpClient [\$serverId]: Failed to fetch MCP tools: \$e",
      );
      _tools = [];
    }
  }

  Future<mcp_dart.CallToolResult> callTool(
    mcp_dart.CallToolRequestParams params,
  ) async {
    if (!_isConnected) {
      throw Exception("Client [\$serverId] is not connected.");
    }
    debugPrint(
      "GoogleMcpClient [\$serverId]: Executing tool '\${params.name}' with args: \${jsonEncode(params.arguments)}",
    );
    try {
      return await mcp.callTool(params);
    } catch (e) {
      debugPrint(
        "GoogleMcpClient [\$serverId]: Error calling tool '\${params.name}': \$e",
      );
      rethrow;
    }
  }

  Future<void> cleanup() async {
    final transportToClose = _transport;
    _transport = null;
    if (transportToClose != null) {
      debugPrint("GoogleMcpClient [\$serverId]: Cleaning up transport...");
      try {
        await mcp.close();
        await transportToClose.close();
      } catch (e) {
        debugPrint("GoogleMcpClient [\$serverId]: Error during cleanup: \$e");
      }
    }
    _isConnected = false;
    _tools = [];
    debugPrint("GoogleMcpClient [\$serverId]: Cleanup complete.");
  }
}

// --- Riverpod Provider State and Notifier ---

@immutable
class McpClientState {
  final List<McpServerConfig> serverConfigs;
  final Map<String, McpConnectionStatus> serverStatuses;
  final Map<String, GoogleMcpClient> activeClients;
  final Map<String, String> serverErrorMessages;

  const McpClientState({
    this.serverConfigs = const [],
    this.serverStatuses = const {},
    this.activeClients = const {},
    this.serverErrorMessages = const {},
  });

  bool get hasActiveConnections =>
      serverStatuses.values.any((s) => s == McpConnectionStatus.connected);
  int get connectedServerCount =>
      serverStatuses.values
          .where((s) => s == McpConnectionStatus.connected)
          .length;

  McpClientState copyWith({
    List<McpServerConfig>? serverConfigs,
    Map<String, McpConnectionStatus>? serverStatuses,
    Map<String, GoogleMcpClient>? activeClients,
    Map<String, String>? serverErrorMessages,
    List<String>? removeClientIds,
    List<String>? removeStatusIds,
    List<String>? removeErrorIds,
  }) {
    final newStatuses = Map<String, McpConnectionStatus>.from(
      serverStatuses ?? this.serverStatuses,
    );
    final newClients = Map<String, GoogleMcpClient>.from(
      activeClients ?? this.activeClients,
    );
    final newErrors = Map<String, String>.from(
      serverErrorMessages ?? this.serverErrorMessages,
    );
    removeClientIds?.forEach(newClients.remove);
    removeStatusIds?.forEach(newStatuses.remove);
    removeErrorIds?.forEach(newErrors.remove);
    return McpClientState(
      serverConfigs: serverConfigs ?? this.serverConfigs,
      serverStatuses: newStatuses,
      activeClients: newClients,
      serverErrorMessages: newErrors,
    );
  }
}

// Manages the McpClientState, handling multiple connections
class McpClientNotifier extends StateNotifier<McpClientState> {
  final Ref ref;
  // Map to store tool names and the server ID that provides them
  Map<String, String> toolToServerIdMap = {};
  ProviderSubscription<List<McpServerConfig>>? serverListSubscription;

  McpClientNotifier(this.ref) : super(const McpClientState()) {
    initialize();
  }

  void initialize() {
    final initialConfigs = ref.read(mcpServerListProvider);
    final initialStatuses = <String, McpConnectionStatus>{};
    for (var config in initialConfigs) {
      initialStatuses[config.id] = McpConnectionStatus.disconnected;
    }
    state = McpClientState(
      serverConfigs: initialConfigs,
      serverStatuses: initialStatuses,
      activeClients: const {},
      serverErrorMessages: const {},
    );
    debugPrint(
      "McpClientNotifier: Initialized with \${initialConfigs.length} server configs.",
    );

    serverListSubscription = ref.listen<
        List<McpServerConfig>
    >(mcpServerListProvider, (previousList, newList) {
      debugPrint(
        "McpClientNotifier: Server list updated in settings. Syncing connections...",
      );
      final currentStatuses = Map<String, McpConnectionStatus>.from(
        state.serverStatuses,
      );
      final currentErrors = Map<String, String>.from(state.serverErrorMessages);
      final newServerIds = newList.map((s) => s.id).toSet();
      currentStatuses.removeWhere((id, _) => !newServerIds.contains(id));
      currentErrors.removeWhere((id, _) => !newServerIds.contains(id));
      for (final server in newList) {
        currentStatuses.putIfAbsent(
          server.id,
          () => McpConnectionStatus.disconnected,
        );
      }
      state = state.copyWith(
        serverConfigs: newList,
        serverStatuses: currentStatuses,
        serverErrorMessages: currentErrors,
      );
      syncConnections();
    }, fireImmediately: false);

    Future.microtask(() {
      debugPrint("McpClientNotifier: Triggering initial connection sync...");
      syncConnections();
    });
  }

  // --- Connection Management ---

  Future<void> connectServer(McpServerConfig serverConfig) async {
    final serverId = serverConfig.id;
    final currentStatus = state.serverStatuses[serverId];
    if (state.activeClients.containsKey(serverId) ||
        currentStatus == McpConnectionStatus.connecting ||
        currentStatus == McpConnectionStatus.connected) {
      debugPrint(
        "MCP [$serverId]: Already connected or connecting, skipping connection attempt.",
      );
      return;
    }

    updateServerState(serverId, McpConnectionStatus.connecting);
    GoogleMcpClient? newClientInstance;

    try {
      // Create the client instance
      newClientInstance = GoogleMcpClient(
        serverId,
        null, // geminiService.model would be passed here if available
      );
      // Setup callbacks BEFORE connectToServer
      newClientInstance.setupCallbacks(
        onError: handleClientError,
        onClose: handleClientClose,
      );

      // Pass config directly, connectToServer now expects manager host/port
      await newClientInstance.connectToServer(
        serverConfig,
      );

      if (newClientInstance.isConnected) {
        debugPrint(
          "MCP [_connectServer - $serverId]: Client connected successfully. Updating state and rebuilding tool map...",
        );
        state = state.copyWith(
          activeClients: {...state.activeClients, serverId: newClientInstance},
          serverStatuses: {
            ...state.serverStatuses,
            serverId: McpConnectionStatus.connected,
          },
          removeErrorIds: [serverId],
        );
        debugPrint(
          "MCP [$serverId]: Connected successfully to ${serverConfig.name}.",
        );
        rebuildToolMap();
      } else {
        if (state.serverStatuses[serverId] != McpConnectionStatus.error) {
          updateServerState(
            serverId,
            McpConnectionStatus.error,
            errorMsg: "Connection failed post-attempt.",
          );
        }
        await newClientInstance.cleanup();
      }
    } catch (e) {
      debugPrint(
        "MCP [$serverId]: Connection failed during setup: ${e.toString()}",
      );
      if (state.serverStatuses[serverId] != McpConnectionStatus.error) {
        updateServerState(
          serverId,
          McpConnectionStatus.error,
          errorMsg: "Connection failed: ${e.toString()}",
        );
      }
      await newClientInstance?.cleanup();
    }
  }

  Future<void> disconnectServer(String serverId) async {
    final clientToDisconnect = state.activeClients[serverId];
    if (state.serverStatuses[serverId] != McpConnectionStatus.disconnected) {
      updateServerState(serverId, McpConnectionStatus.disconnected);
    }
    if (clientToDisconnect == null) {
      debugPrint("MCP [$serverId]: No active client found to disconnect.");
      if (state.activeClients.containsKey(serverId)) {
        state = state.copyWith(removeClientIds: [serverId]);
        rebuildToolMap();
      }
      return;
    }
    debugPrint("MCP [$serverId]: Disconnecting client...");
    await clientToDisconnect.cleanup();
    if (state.activeClients.containsKey(serverId)) {
      state = state.copyWith(removeClientIds: [serverId]);
      debugPrint(
        "MCP [$serverId]: Disconnect process complete, client removed from state.",
      );
      rebuildToolMap();
    } else {
      debugPrint(
        "MCP [$serverId]: Client already removed from state during cleanup.",
      );
      rebuildToolMap();
    }
  }

  void syncConnections() {
    if (!mounted) return;
    final desiredActiveServers =
        state.serverConfigs.where((s) => s.isActive).map((s) => s.id).toSet();
    final currentlyConnectingOrConnected =
        state.serverStatuses.entries
            .where(
              (e) =>
                  e.value == McpConnectionStatus.connected ||
                  e.value == McpConnectionStatus.connecting,
            )
            .map((e) => e.key)
            .toSet();
    final knownServerIds = state.serverConfigs.map((s) => s.id).toSet();
    final serversToConnect = desiredActiveServers.difference(
      currentlyConnectingOrConnected,
    );
    final serversToDisconnect = currentlyConnectingOrConnected
        .difference(desiredActiveServers)
        .union(currentlyConnectingOrConnected.difference(knownServerIds));
    if (serversToConnect.isNotEmpty || serversToDisconnect.isNotEmpty) {
      debugPrint("Syncing MCP Connections:");
      if (serversToConnect.isNotEmpty) {
        debugPrint(" - To Connect: ${serversToConnect.join(', ')}");
      }
      if (serversToDisconnect.isNotEmpty) {
        debugPrint(" - To Disconnect: ${serversToDisconnect.join(', ')}");
      }
    }
    for (final serverId in serversToDisconnect) {
      disconnectServer(serverId);
    }
    for (final serverId in serversToConnect) {
      final config = state.serverConfigs.firstWhereOrNull(
        (s) => s.id == serverId,
      );
      if (config != null) {
        connectServer(config);
      } else {
        updateServerState(
          serverId,
          McpConnectionStatus.error,
          errorMsg: "Config not found during sync.",
        );
        if (state.activeClients.containsKey(serverId)) {
          state = state.copyWith(removeClientIds: [serverId]);
        }
      }
    }
    final currentStatusIds = state.serverStatuses.keys.toSet();
    final statusesToRemove = currentStatusIds.difference(knownServerIds);
    if (statusesToRemove.isNotEmpty) {
      debugPrint(
        "MCP: Removing stale statuses/errors for IDs: ${statusesToRemove.join(', ')}",
      );
      state = state.copyWith(
        removeStatusIds: statusesToRemove.toList(),
        removeErrorIds: statusesToRemove.toList(),
      );
    }
  }

  // --- State Update Helpers ---
  void updateServerState(
    String serverId,
    McpConnectionStatus status, {
    String? errorMsg,
  }) {
    if (!mounted) return;
    final newStatuses = Map<String, McpConnectionStatus>.from(
      state.serverStatuses,
    );
    final newErrors = Map<String, String>.from(state.serverErrorMessages);
    final newClients = Map<String, GoogleMcpClient>.from(state.activeClients);
    bool clientRemoved = false;
    bool statusChanged = newStatuses[serverId] != status;
    newStatuses[serverId] = status;
    if (errorMsg != null) {
      newErrors[serverId] = errorMsg;
    } else if (status != McpConnectionStatus.error) {
      newErrors.remove(serverId);
    }
    if (status == McpConnectionStatus.disconnected ||
        status == McpConnectionStatus.error) {
      if (newClients.remove(serverId) != null) {
        clientRemoved = true;
      }
    }
    if (statusChanged ||
        clientRemoved ||
        (errorMsg != null && state.serverErrorMessages[serverId] != errorMsg) ||
        (errorMsg == null && state.serverErrorMessages.containsKey(serverId))) {
      state = state.copyWith(
        serverStatuses: newStatuses,
        serverErrorMessages: newErrors,
        activeClients: newClients,
      );
      if (clientRemoved) {
        rebuildToolMap();
      }
    }
  }

  void handleClientError(String serverId, String errorMsg) {
    debugPrint("MCP [$serverId]: Received error callback: $errorMsg");
    updateServerState(serverId, McpConnectionStatus.error, errorMsg: errorMsg);
  }

  void handleClientClose(String serverId) {
    debugPrint("MCP [$serverId]: Received close callback.");
    if (state.serverStatuses[serverId] != McpConnectionStatus.error) {
      updateServerState(serverId, McpConnectionStatus.disconnected);
    } else {
      if (state.activeClients.containsKey(serverId)) {
        state = state.copyWith(removeClientIds: [serverId]);
        rebuildToolMap();
      }
    }
  }

  // --- Tool Management (Adapted from example - for future use) ---
  void rebuildToolMap() {
    if (!mounted) return;
    final newToolMap = <String, String>{};
    final Set<String> uniqueToolNames = {};
    final List<String> duplicateToolNames = [];
    final currentClientIds = List<String>.from(state.activeClients.keys);

    for (final serverId in currentClientIds) {
      final client = state.activeClients[serverId];
      if (client != null && client.isConnected) {
        for (final tool in client.availableTools) {
          for (final funcDec in tool.functionDeclarations ?? []) {
            if (newToolMap.containsKey(funcDec.name)) {
              if (!duplicateToolNames.contains(funcDec.name)) {
                duplicateToolNames.add(funcDec.name);
                debugPrint(
                  "MCP Warning: Duplicate tool name '${funcDec.name}' found on multiple servers. Using first encountered.",
                );
              }
            } else {
              newToolMap[funcDec.name] = serverId;
              uniqueToolNames.add(funcDec.name);
            }
          }
        }
      }
    }

    toolToServerIdMap = newToolMap;
    debugPrint(
      "MCP [_rebuildToolMap]: Finished rebuilding. Final map: $toolToServerIdMap",
    );

    if (duplicateToolNames.isNotEmpty || uniqueToolNames.isNotEmpty) {
      debugPrint(
        "MCP: Rebuilt tool map. ${uniqueToolNames.length} unique tools found: [${uniqueToolNames.join(', ')}]. Duplicates: [${duplicateToolNames.join(', ')}]",
      );
    } else {
      debugPrint("MCP: Rebuilt tool map. No tools found on connected servers.");
    }
  }

  // --- Query Processing ---
  Future<McpProcessResult> processQuery(
    String query,
    List<Content> history,
  ) async {
    debugPrint("MCP ProcessQuery: Entered processQuery with query: '$query'");

    // --- Step 1: Check for active connections ---
    if (!state.hasActiveConnections) {
      debugPrint("MCP ProcessQuery: No active MCP connections.");
      return McpProcessResult(
        finalModelContent: Content('model', [
          TextPart("No active MCP server to process the request."),
        ]),
      );
    }

    // --- Step 2: Get Gemini Service ---
    final geminiService = ref.read(geminiServiceProvider);
    if (geminiService == null ||
        !geminiService.isInitialized ||
        geminiService.model == null) {
      debugPrint(
        "MCP ProcessQuery: Gemini service not available or not initialized.",
      );
      return McpProcessResult(
        finalModelContent: Content('model', [
          TextPart(
            "AI service is not available: ${geminiService?.initializationError ?? 'Gemini service is null or model is missing.'}",
          ),
        ]),
      );
    }

    // --- Step 3: Gather Tools from Connected Clients ---
    final List<Tool> allAvailableTools =
        state.activeClients.values
            .where((client) => client.isConnected)
            .expand((client) => client.availableTools)
            .toList();

    if (allAvailableTools.isEmpty) {
      debugPrint(
        "MCP ProcessQuery: No tools available from connected MCP servers. Proceeding without tools.",
      );
    } else {
      debugPrint(
        "MCP ProcessQuery: Passing ${allAvailableTools.length} tools to Gemini: ${allAvailableTools.map((t) => t.functionDeclarations?.firstOrNull?.name ?? 'unknown').join(', ')}",
      );
    }

    // --- Step 4: First Gemini Call (with tools) ---
    GenerateContentResponse firstResponse;
    try {
      firstResponse = await geminiService.generateContent(
        query,
        history,
        tools: allAvailableTools.isNotEmpty ? allAvailableTools : null,
      );
    } catch (e) {
      debugPrint("MCP ProcessQuery: Error during first Gemini call: $e");
      return McpProcessResult(
        finalModelContent: Content('model', [
          TextPart("Error communicating with AI service: ${e.toString()}"),
        ]),
      );
    }

    // --- Step 5: Check for Function Call ---
    final candidate = firstResponse.candidates.firstOrNull;
    final functionCallPart = candidate?.content.parts.firstWhereOrNull(
      (part) => part is FunctionCall,
    );

    if (functionCallPart != null && functionCallPart is FunctionCall) {
      final functionCall = functionCallPart;
      final toolName = functionCall.name;
      final toolArgs = functionCall.args;

      debugPrint(
        "MCP ProcessQuery: Gemini requested Function Call: '$toolName' with args: $toolArgs",
      );

      // --- Step 6: Find and Execute Tool ---
      final targetServerId = toolToServerIdMap[toolName];
      if (targetServerId == null) {
        debugPrint(
          "MCP ProcessQuery: Error - Tool '$toolName' requested by AI not found in tool map.",
        );
        return McpProcessResult(
          finalModelContent: Content('model', [
            TextPart(
              "Sorry, I found a tool called '$toolName' but couldn't locate the server providing it.",
            ),
          ]),
        );
      }

      final targetClient = state.activeClients[targetServerId];
      if (targetClient == null || !targetClient.isConnected) {
        debugPrint(
          "MCP ProcessQuery: Error - Client for server '$targetServerId' (tool '$toolName') not found or not connected.",
        );
        return McpProcessResult(
          finalModelContent: Content('model', [
            TextPart(
              "Sorry, the server responsible for the '$toolName' tool is currently unavailable.",
            ),
          ]),
        );
      }

      mcp_dart.CallToolResult toolResult;
      String toolResultString = '';
      Map<String, dynamic> toolResultJson = {};

      try {
        final params = mcp_dart.CallToolRequestParams(
          name: toolName,
          arguments: toolArgs.map((key, value) => MapEntry(key, value)),
        );
        toolResult = await targetClient.callTool(params);

        // --- Step 7: Process Tool Result ---
        final textContent = toolResult.content.firstWhereOrNull(
          (c) => c is mcp_dart.TextContent,
        );

        if (textContent != null && textContent is mcp_dart.TextContent) {
          toolResultString = textContent.text;
          debugPrint(
            "MCP ProcessQuery: Tool '$toolName' executed successfully by server '$targetServerId'. Raw Result: $toolResultString",
          );
          debugPrint(
            "MCP ProcessQuery: Raw toolResultString: '$toolResultString'",
          );

          try {
            final decoded = jsonDecode(toolResultString);
            debugPrint(
              "MCP ProcessQuery: Decoded JSON from toolResultString: $decoded",
            );

            if (decoded is Map<String, dynamic>) {
              toolResultJson = decoded;
            } else if (decoded is List) {
              toolResultJson = {'result_list': decoded};
            } else {
              toolResultJson = {'result_text': toolResultString};
            }
          } catch (e) {
            debugPrint(
              "MCP ProcessQuery: Tool result was not valid JSON or processing failed: $e. Using raw string.",
            );
            toolResultJson = {'result_text': toolResultString};
          }
        } else {
          toolResultString = jsonEncode(toolResult.toJson());
          toolResultJson = {'result_raw': toolResult.toJson()};
          debugPrint(
            "MCP ProcessQuery: Tool '$toolName' executed by server '$targetServerId'. Result (non-text): $toolResultString",
          );
        }
        debugPrint("MCP ProcessQuery: Parsed toolResultJson: $toolResultJson");

        Map<String, dynamic> simplifiedResultJson;
        if (toolResultJson.containsKey('status')) {
          if (toolResultJson['status'] == 'success') {
            simplifiedResultJson = {'status': 'success'};
            if (toolResultJson.containsKey('taskId')) {
              simplifiedResultJson['taskId'] = toolResultJson['taskId'];
            }
            if (!simplifiedResultJson.containsKey('taskId') &&
                toolResultJson.containsKey('message')) {
              simplifiedResultJson['message'] = toolResultJson['message'];
            } else if (toolName == 'get_todoist_tasks' &&
                toolResultJson.containsKey('result_list')) {
              simplifiedResultJson['message'] =
                  "Found ${(toolResultJson['result_list'] as List?)?.length ?? 0} tasks.";
            }
          } else {
            simplifiedResultJson = {
              'status': toolResultJson['status'] ?? 'error',
              'message': toolResultJson['message'] ?? 'Unknown error occurred.',
            };
            if (toolResultJson.containsKey('taskId')) {
              simplifiedResultJson['taskId'] = toolResultJson['taskId'];
            }
          }
        } else {
          simplifiedResultJson = {'result_text': toolResultString};
          if (toolResultJson.containsKey('taskId')) {
            simplifiedResultJson['taskId'] = toolResultJson['taskId'];
          }
        }
        debugPrint(
          "MCP ProcessQuery: Simplified result JSON for FunctionResponse: $simplifiedResultJson",
        );

        String summaryText;
        final status = simplifiedResultJson['status'] as String?;
        final message = simplifiedResultJson['message'] as String?;
        final taskId = simplifiedResultJson['taskId'] as String?;
        debugPrint(
          "MCP ProcessQuery: Extracted for summary -> status: '$status', message: '$message', taskId: '$taskId'",
        );

        if (status == 'success') {
          summaryText = message ?? "Tool '$toolName' executed successfully.";

          if (toolName == 'create_todoist_task') {
            if (taskId != null) {
              summaryText =
                  'Todoist task created successfully: "${toolArgs['content'] as String? ?? "[unknown content]"}" (ID: $taskId).';
            } else {
              summaryText =
                  'Todoist task created successfully: "${toolArgs['content'] as String? ?? "[unknown content]"}."';
            }
            debugPrint(
              "MCP ProcessQuery [create_todoist_task]: Constructed summaryText: \"$summaryText\"",
            );
          } else if (toolName == 'update_todoist_task') {
            if (taskId != null) {
              summaryText = "Todoist task updated successfully (ID: $taskId).";
            } else {
              summaryText = "Todoist task updated successfully.";
            }
            debugPrint(
              "MCP ProcessQuery [update_todoist_task]: Constructed summaryText: \"$summaryText\"",
            );
          } else if (toolName == 'get_todoist_tasks') {
            summaryText = message ?? "Tasks retrieved successfully.";
            if (taskId != null) {
              final taskDetails =
                  (toolResultJson['result_text'] as String?) ??
                  (toolResultJson['message'] as String?);
              if (taskDetails != null && taskDetails.isNotEmpty) {
                final displayDetails =
                    taskDetails.length > 100
                        ? '${taskDetails.substring(0, 97)}...'
                        : taskDetails;
                summaryText = 'Found task (ID: $taskId): "$displayDetails"';
              } else {
                summaryText = 'Found task with ID: $taskId.';
              }
            } else {
              final taskList = toolResultJson['result_list'] as List?;
              if (taskList != null) {
                summaryText = message ?? "Found ${taskList.length} tasks.";
              }
            }
            debugPrint(
              "MCP ProcessQuery [get_todoist_tasks]: Constructed summaryText: \"$summaryText\"",
            );
          } else {
            if (taskId != null) {
              summaryText += " ID: $taskId.";
            }
            debugPrint(
              "MCP ProcessQuery [generic success]: Constructed summaryText: \"$summaryText\"",
            );
          }
        } else if (status == 'error') {
          if (taskId != null) {
            summaryText =
                "Tool '$toolName' failed: ${message ?? 'Unknown error'} (Related to Task ID: $taskId)";
          } else {
            summaryText =
                "Tool '$toolName' failed: ${message ?? 'Unknown error'}";
          }
          debugPrint(
            "MCP ProcessQuery [error]: Constructed summaryText: \"$summaryText\"",
          );
        } else {
          if (taskId != null) {
            summaryText =
                (toolResultJson['result_text'] as String?) ??
                "Tool '$toolName' executed. Result: $toolResultString (ID: $taskId)";
          } else {
            summaryText =
                (toolResultJson['result_text'] as String?) ??
                "Tool '$toolName' executed. Result: $toolResultString";
          }
          debugPrint(
            "MCP ProcessQuery [fallback]: Constructed summaryText: \"$summaryText\"",
          );
        }

        debugPrint(
          "MCP ProcessQuery: Final response to UI (tool summary): \"$summaryText\"",
        );

        final summaryTextPart = TextPart(summaryText);
        final finalContent = Content('model', [summaryTextPart]);

        debugPrint(
          "MCP ProcessQuery: Tool execution successful. Skipping second Gemini call. Returning direct summary.",
        );
        debugPrint(
          "MCP ProcessQuery: Final response to UI (tool summary): \"$summaryText\"",
        );

        return McpProcessResult(
          finalModelContent: finalContent,
          modelCallContent: candidate?.content,
          toolResponseContent: Content('function', [
            summaryTextPart,
            FunctionResponse(toolName, simplifiedResultJson),
          ]),
          toolName: toolName,
          toolArgs: toolArgs,
          toolResult: toolResultString,
          sourceServerId: targetServerId,
        );
      } catch (e) {
        debugPrint(
          "MCP ProcessQuery: Error calling tool '$toolName' on server '$targetServerId': $e",
        );
        final failedFunctionCallContent =
            candidate?.content ??
            Content('model', [TextPart("Model attempted to call '$toolName'")]);
        final errorResponsePart = FunctionResponse(toolName, {
          'error': e.toString(),
        });
        final errorTextPart = TextPart(
          "Failed to execute tool '$toolName': ${e.toString()}",
        );

        return McpProcessResult(
          finalModelContent: Content('model', [
            TextPart(
              "Sorry, I encountered an error while trying to execute the '$toolName' tool: ${e.toString()}",
            ),
          ]),
          modelCallContent: failedFunctionCallContent,
          toolResponseContent: Content('function', [
            errorTextPart,
            errorResponsePart,
          ]),
          toolName: toolName,
          toolArgs: toolArgs,
          sourceServerId: targetServerId,
        );
      }
    } else {
      debugPrint(
        "MCP ProcessQuery: No function call requested by Gemini. Returning direct response.",
      );
      final directContent =
          candidate?.content ??
          Content('model', [
            TextPart("Sorry, I couldn't generate a response."),
          ]);

      debugPrint(
        "MCP ProcessQuery: Final response to UI (direct): \"\${directContent.parts.whereType<TextPart>().map((p) => p.text).join('')}\"",
      );

      return McpProcessResult(finalModelContent: directContent);
    }
  }

  @override
  void dispose() {
    debugPrint("Disposing McpClientNotifier, cleaning up all clients...");
    serverListSubscription?.close();
    final clientIds = List<String>.from(state.activeClients.keys);
    for (final serverId in clientIds) {
      state.activeClients[serverId]?.cleanup();
    }
    super.dispose();
  }
}

// The main provider for accessing the MCP client state and notifier
final mcpClientProvider =
    StateNotifierProvider<McpClientNotifier, McpClientState>((ref) {
  return McpClientNotifier(ref);
});