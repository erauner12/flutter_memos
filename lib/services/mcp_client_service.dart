import 'dart:async';
import 'dart:convert'; // For jsonEncode/Decode if needed for tool results
import 'dart:io' as io; // Use 'io' prefix for dart:io types

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // To get server list and Gemini key
import 'package:flutter_memos/services/gemini_service.dart'; // Import GeminiService
import 'package:flutter_memos/services/mcp_sse_client_transport.dart'; // Import the new SSE transport
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Import for Gemini types (Content, Tool, etc.)
// MODIFY: Change import prefix to avoid conflict
import 'package:mcp_dart/mcp_dart.dart' as mcp_lib;
// Import Stdio types explicitly (less likely to conflict)
// Note: These should be available via the main lib export now
// REMOVE: Direct import of Transport

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
            description: description,
          );
        } catch (e) {
          debugPrint(
            "Error parsing object properties for schema: \$json. Error: \$e",
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
          debugPrint(
            "Error parsing array items for schema: \$json. Error: \$e",
          );
          throw FormatException(
            "Invalid 'items' definition in array schema",
            json,
          );
        }
      default:
        debugPrint("Unsupported schema type encountered: \$type");
        throw UnsupportedError("Unsupported schema type: \$type");
    }
  }
}

// --- Result Type (Adapted from example - for potential future chat use) ---
// Uses google_generative_ai.Content
@immutable
class McpProcessResult {
  final Content? modelCallContent; // google_generative_ai.Content
  final Content?
  toolResponseContent; // google_generative_ai.Content (FunctionResponse)
  final Content finalModelContent; // google_generative_ai.Content
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final String? toolResult; // Keep as string representation for now
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
// Uses prefixed mcp types
class GoogleMcpClient {
  final String serverId;
  // MODIFY: Rename the mcp client instance variable
  final mcp_lib.Client mcpClient;
  final GenerativeModel? model; // google_generative_ai.GenerativeModel
  // Use the Transport type if needed via mcp_lib
  mcp_lib.Transport? _transport; // MODIFY: Use prefixed type
  List<Tool> _tools = []; // google_generative_ai.Tool
  bool _isConnected = false;
  Function(String serverId, String errorMsg)? _onError;
  // Add the missing onClose callback field
  Function(String serverId)? _onClose;

  bool get isConnected => _isConnected;
  List<Tool> get availableTools => List.unmodifiable(_tools);

  // MODIFY: Fix constructor initialization
  GoogleMcpClient(this.serverId, this.model)
    : mcpClient = mcp_lib.Client(
        const mcp_lib.Implementation(
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

  // Modified to accept McpServerConfig and handle both connection types
  // MODIFY: Update connectToServer to use the correct model and mcpClient variable
  Future<void> connectToServer(
    McpServerConfig config,
  ) async {
    if (_isConnected) return;
    _isConnected = false;
    _tools = [];

    debugPrint(
      "GoogleMcpClient [${config.id}]: Attempting connection (Type: ${config.connectionType.name})...",
    );

    try {
      // --- Branch based on connection type ---
      if (config.connectionType == McpConnectionType.stdio) {
        // --- Stdio Connection ---
        debugPrint(
          "GoogleMcpClient [${config.id}]: Creating StdioClientTransport.",
        );
        debugPrint(
          "GoogleMcpClient [${config.id}]: Command='${config.command}', Args='${config.args}', Env=${config.customEnvironment.isNotEmpty ? config.customEnvironment.keys.join(',') : 'None'}",
        );

        if (config.command.trim().isEmpty) {
          throw StateError(
            "Stdio Connection failed: Command is missing in configuration for ${config.name} [${config.id}].",
          );
        }

        // MODIFY: Use library prefix for Stdio types
        final serverParams = mcp_lib.StdioServerParameters(
          command: config.command,
          args: config.args.split(' '),
          environment:
              config.customEnvironment.isEmpty
                  ? null
                  : config.customEnvironment,
          stderrMode: io.ProcessStartMode.normal,
        );

        final stdioTransport = mcp_lib.StdioClientTransport(serverParams);
        _transport = stdioTransport;

        stdioTransport.onerror = (error) {
          final errorMsg = "MCP Stdio Transport error [${config.id}]: $error";
          debugPrint(errorMsg);
          _isConnected = false;
          _onError?.call(config.id, errorMsg);
          cleanup();
        };

        stdioTransport.onclose = () {
          debugPrint("MCP Stdio Transport closed [${config.id}].");
          _isConnected = false;
          _onClose?.call(config.id);
          _transport = null;
          _tools = [];
        };

        // MODIFY: Use the renamed mcpClient variable
        await mcpClient.connect(stdioTransport);
        _isConnected = true;
        debugPrint(
          "GoogleMcpClient [${config.id}]: Stdio Transport connected successfully.",
        );
      } else {
        // McpConnectionType.sse
        // --- SSE Connection ---
        // MODIFY: Use nullable host/port safely
        final host = config.host;
        final port = config.port;

        debugPrint(
          "GoogleMcpClient [${config.id}]: Creating SseClientTransport for manager at $host:$port",
        );

        // Add Pre-connection Validation for SSE host/port
        // MODIFY: Add null checks and use trim() safely
        if (host == null || host.trim().isEmpty) {
          throw StateError(
            "SSE Connection failed: Host is missing in configuration for ${config.name} [${config.id}].",
          );
        }
        // MODIFY: Add null check for port
        if (port == null || port <= 0 || port > 65535) {
          throw StateError(
            "SSE Connection failed: Port is missing or invalid (must be 1-65535) in configuration for ${config.name} [${config.id}].",
          );
        }

        // MODIFY: Use non-nullable assertion (!) after validation
        final sseTransport = SseClientTransport(
          managerHost: host,
          managerPort: port,
        );
        _transport = sseTransport;

        sseTransport.onerror = (error) {
          final errorMsg = "MCP SSE Transport error [${config.id}]: $error";
          debugPrint(errorMsg);
          _isConnected = false;
          _onError?.call(config.id, errorMsg);
          cleanup();
        };

        sseTransport.onclose = () {
          debugPrint("MCP SSE Transport closed [${config.id}].");
          _isConnected = false;
          _onClose?.call(config.id);
          _transport = null;
          _tools = [];
        };

        // MODIFY: Use the renamed mcpClient variable
        await mcpClient.connect(sseTransport);
        _isConnected = true;
        debugPrint(
          "GoogleMcpClient [${config.id}]: SSE Transport connected successfully.",
        );
      }

      debugPrint(
        "GoogleMcpClient [${config.id}]: Connection successful (Type: ${config.connectionType.name}), proceeding to fetch tools...",
      );
      await _fetchTools();

    } catch (e) {
      final errorMsg =
          "GoogleMcpClient [${config.id}]: Failed to establish ${config.connectionType.name} connection: $e";
      debugPrint(errorMsg);
      _isConnected = false;
      await cleanup();
      throw StateError(errorMsg);
    }
  }

  // MODIFY: Update _fetchTools to use mcpClient and library prefix
  Future<void> _fetchTools() async {
    if (!_isConnected || _transport == null) {
      debugPrint(
        "GoogleMcpClient [$serverId]: Cannot fetch tools, not connected.",
      );
      _tools = [];
      return;
    }
    debugPrint("GoogleMcpClient [$serverId]: Fetching tools...");
    try {
      final mcp_lib.ListToolsResult toolsResult = await mcpClient.listTools();
      List<Tool> fetchedTools = [];
      for (var toolDef in toolsResult.tools) {
        try {
          final schemaJson = toolDef.inputSchema.toJson();
          Schema? schema;
          if (schemaJson.isNotEmpty &&
              !(schemaJson['type'] == 'object' &&
                  (schemaJson['properties'] == null ||
                      (schemaJson['properties'] as Map).isEmpty))) {
            schema = SchemaExtension.fromJson(schemaJson);
          }
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
        } catch (e) {
          debugPrint(
            "Error processing schema for tool '${toolDef.name}' [$serverId]: $e. Skipping tool.",
          );
        }
      }
      _tools = fetchedTools;
      debugPrint(
        "GoogleMcpClient [$serverId]: Processed tools for Gemini: ${_tools.map((t) => t.functionDeclarations?.map((fd) => fd.name) ?? 'null').toList()}",
      );
      debugPrint(
        "GoogleMcpClient [$serverId]: Successfully processed ${_tools.length} tools.",
      );
    } catch (e) {
      debugPrint(
        "GoogleMcpClient [$serverId]: Failed to fetch MCP tools: $e",
      );
      _tools = [];
    }
  }

  // MODIFY: Update callTool to use mcpClient and library prefix
  Future<mcp_lib.CallToolResult> callTool(
    mcp_lib.CallToolRequestParams params,
  ) async {
    if (!_isConnected || _transport == null) {
      throw Exception("Client [$serverId] is not connected.");
    }
    debugPrint(
      "GoogleMcpClient [$serverId]: Executing tool '${params.name}' with args: ${jsonEncode(params.arguments)}",
    );
    try {
      return await mcpClient.callTool(params);
    } catch (e) {
      debugPrint(
        "GoogleMcpClient [$serverId]: Error calling tool '${params.name}': $e",
      );
      rethrow;
    }
  }

  // MODIFY: Update cleanup to use mcpClient
  Future<void> cleanup() async {
    if (_transport == null && !_isConnected) {
      debugPrint("GoogleMcpClient [$serverId]: Already cleaned up.");
      return;
    }

    final transportToClose = _transport;
    final wasConnected = _isConnected;

    _transport = null;
    _isConnected = false;
    _tools = [];

    if (wasConnected || transportToClose != null) {
      debugPrint("GoogleMcpClient [$serverId]: Cleaning up...");
      try {
        await mcpClient.close();
        if (transportToClose is mcp_lib.StdioClientTransport) {
          await transportToClose.close();
        } else if (transportToClose is SseClientTransport) {
          await transportToClose.close();
        }
      } catch (e) {
        debugPrint("GoogleMcpClient [$serverId]: Error during cleanup: $e");
      }
      debugPrint("GoogleMcpClient [$serverId]: Cleanup complete.");
    } else {
      debugPrint(
        "GoogleMcpClient [$serverId]: Cleanup called but was not connected.",
      );
    }
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

class McpClientNotifier extends StateNotifier<McpClientState> {
  final Ref ref;
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
      "McpClientNotifier: Initialized with ${initialConfigs.length} server configs.",
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

  Future<void> connectServer(McpServerConfig serverConfig) async {
    final serverId = serverConfig.id;
    final currentStatus = state.serverStatuses[serverId];

    if (state.activeClients.containsKey(serverId) ||
        currentStatus == McpConnectionStatus.connecting ||
        currentStatus == McpConnectionStatus.connected) {
      debugPrint(
        "MCP [$serverId]: Already connected or connecting (Status: $currentStatus), skipping connection attempt.",
      );
      return;
    }

    updateServerState(serverId, McpConnectionStatus.connecting);
    GoogleMcpClient? newClientInstance;

    try {
      final geminiService = ref.read(geminiServiceProvider);
      if (geminiService == null ||
          !geminiService.isInitialized ||
          geminiService.model == null) {
        throw StateError("Gemini service not initialized or model is null.");
      }

      newClientInstance = GoogleMcpClient(serverId, geminiService.model);
      newClientInstance.setupCallbacks(
        onError: handleClientError,
        onClose: handleClientClose,
      );

      await newClientInstance.connectToServer(serverConfig);

      if (newClientInstance.isConnected) {
        debugPrint(
          "MCP [$serverId]: Client connected successfully. Updating state and rebuilding tool map...",
        );
        if (mounted &&
            state.serverStatuses[serverId] == McpConnectionStatus.connecting) {
          state = state.copyWith(
            activeClients: {
              ...state.activeClients,
              serverId: newClientInstance,
            },
            serverStatuses: {
              ...state.serverStatuses,
              serverId: McpConnectionStatus.connected,
            },
            removeErrorIds: [serverId],
          );
          debugPrint(
            "MCP [$serverId]: State updated to connected for ${serverConfig.name}.",
          );
          rebuildToolMap();
        } else {
          debugPrint(
            "MCP [$serverId]: Connection succeeded but state changed or unmounted during connection. Cleaning up.",
          );
          await newClientInstance.cleanup();
        }
      } else {
        debugPrint(
          "MCP [$serverId]: connectToServer completed but client is not connected. Setting status to error.",
        );
        if (mounted &&
            state.serverStatuses[serverId] != McpConnectionStatus.error) {
          updateServerState(
            serverId,
            McpConnectionStatus.error,
            errorMsg:
                "Connection attempt finished but client is not connected.",
          );
        }
        await newClientInstance.cleanup();
      }
    } catch (e) {
      final errorMsg = "Connection failed: ${e.toString()}";
      debugPrint(
        "MCP [$serverId]: Connection failed during setup: $errorMsg",
      );
      if (mounted &&
          state.serverStatuses[serverId] != McpConnectionStatus.error) {
        updateServerState(
          serverId,
          McpConnectionStatus.error,
          errorMsg: errorMsg,
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
    if (mounted && state.activeClients.containsKey(serverId)) {
      state = state.copyWith(removeClientIds: [serverId]);
      debugPrint(
        "MCP [$serverId]: Disconnect process complete, client removed from state.",
      );
      rebuildToolMap();
    } else if (mounted) {
      debugPrint(
        "MCP [$serverId]: Client already removed from state (likely via onClose).",
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
        debugPrint(
          "MCP Sync Warning: Config not found for server $serverId during connect phase.",
        );
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

  void updateServerState(
    String serverId,
    McpConnectionStatus status, {
    String? errorMsg,
  }) {
    if (!mounted) return;
    final currentStatus = state.serverStatuses[serverId];
    final currentError = state.serverErrorMessages[serverId];
    final clientExists = state.activeClients.containsKey(serverId);
    if (currentStatus == status &&
        currentError == errorMsg &&
        (status == McpConnectionStatus.connected ||
                status == McpConnectionStatus.connecting) ==
            clientExists) {
      return;
    }
    final newStatuses = Map<String, McpConnectionStatus>.from(
      state.serverStatuses,
    );
    final newErrors = Map<String, String>.from(state.serverErrorMessages);
    final newClients = Map<String, GoogleMcpClient>.from(state.activeClients);
    bool clientRemoved = false;

    newStatuses[serverId] = status;
    if (errorMsg != null) {
      newErrors[serverId] = errorMsg;
    } else {
      newErrors.remove(serverId);
    }
    if (status == McpConnectionStatus.disconnected ||
        status == McpConnectionStatus.error) {
      if (newClients.remove(serverId) != null) {
        clientRemoved = true;
        debugPrint(
          "MCP [$serverId]: Client removed from active list due to status change to $status.",
        );
      }
    }
    state = state.copyWith(
      serverStatuses: newStatuses,
      serverErrorMessages: newErrors,
      activeClients: newClients,
    );
    if (clientRemoved) {
      rebuildToolMap();
    }
  }

  void handleClientError(String serverId, String errorMsg) {
    debugPrint("MCP [$serverId]: Received error callback: $errorMsg");
    if (!mounted) return;
    updateServerState(serverId, McpConnectionStatus.error, errorMsg: errorMsg);
  }

  void handleClientClose(String serverId) {
    debugPrint("MCP [$serverId]: Received close callback.");
    if (!mounted) return;
    if (state.serverStatuses[serverId] != McpConnectionStatus.error) {
      updateServerState(serverId, McpConnectionStatus.disconnected);
    } else {
      if (state.activeClients.containsKey(serverId)) {
        debugPrint(
          "MCP [$serverId]: Close callback received while status is Error. Ensuring client instance is removed.",
        );
        state = state.copyWith(removeClientIds: [serverId]);
        rebuildToolMap();
      }
    }
  }

  void rebuildToolMap() {
    if (!mounted) return;
    final newToolMap = <String, String>{};
    final Set<String> uniqueToolNames = {};
    final List<String> duplicateToolNames = [];
    final currentClientIds = List<String>.from(state.activeClients.keys);
    debugPrint(
      "MCP [_rebuildToolMap]: Starting rebuild. Active clients: ${currentClientIds.join(', ')}",
    );
    for (final serverId in currentClientIds) {
      final client = state.activeClients[serverId];
      if (client != null && client.isConnected) {
        debugPrint(
          "MCP [_rebuildToolMap]: Processing tools for connected client [$serverId]",
        );
        for (final tool in client.availableTools) {
          for (final funcDec in tool.functionDeclarations ?? []) {
            if (newToolMap.containsKey(funcDec.name)) {
              if (!duplicateToolNames.contains(funcDec.name)) {
                duplicateToolNames.add(funcDec.name);
                debugPrint(
                  "MCP Warning: Duplicate tool name '${funcDec.name}' found. Client [$serverId] provides it, but already mapped to [${newToolMap[funcDec.name]}]. Using first encountered.",
                );
              }
            } else {
              newToolMap[funcDec.name] = serverId;
              uniqueToolNames.add(funcDec.name);
              debugPrint(
                "MCP [_rebuildToolMap]: Mapped tool '${funcDec.name}' to client [$serverId]",
              );
            }
          }
        }
      } else {
        debugPrint(
          "MCP [_rebuildToolMap]: Skipping client [$serverId] (not found in state or not connected).",
        );
      }
    }
    if (!const MapEquality().equals(toolToServerIdMap, newToolMap)) {
      toolToServerIdMap = newToolMap;
      debugPrint(
        "MCP [_rebuildToolMap]: Finished rebuilding. ${uniqueToolNames.length} unique tools. Final map: $toolToServerIdMap",
      );
    } else {
      debugPrint(
        "MCP [_rebuildToolMap]: Finished rebuilding. Tool map unchanged.",
      );
    }
    if (duplicateToolNames.isNotEmpty || uniqueToolNames.isNotEmpty) {
      debugPrint(
        "MCP: Tool map status: ${uniqueToolNames.length} unique tools [${uniqueToolNames.join(', ')}]. Duplicates ignored: [${duplicateToolNames.join(', ')}]",
      );
    } else {
      debugPrint("MCP: Tool map status: No tools found on connected servers.");
    }
  }

  // ADD BACK: processQuery method moved from GoogleMcpClient to McpClientNotifier
  Future<McpProcessResult> processQuery(
    String query,
    List<Content> history,
  ) async {
    debugPrint("MCP ProcessQuery: Entered processQuery with query: '$query'");
    if (!state.hasActiveConnections) {
      debugPrint("MCP ProcessQuery: No active MCP connections.");
      return McpProcessResult(
        finalModelContent: Content('model', [
          TextPart(
            "I cannot fulfill this request as no MCP servers are currently connected.",
          ),
        ]),
      );
    }
    final geminiService = ref.read(geminiServiceProvider);
    if (geminiService == null ||
        !geminiService.isInitialized ||
        geminiService.model == null) {
      final errorMsg =
          geminiService?.initializationError ??
          'Gemini service is null or model is missing.';
      debugPrint(
        "MCP ProcessQuery: Gemini service not available or not initialized. Error: $errorMsg",
      );
      return McpProcessResult(
        finalModelContent: Content('model', [
          TextPart("The AI service is not available: $errorMsg"),
        ]),
      );
    }
    final List<Tool> allAvailableTools = [];
    final processedToolNames = <String>{};
    debugPrint(
      "MCP ProcessQuery: Gathering tools from active clients based on tool map: $toolToServerIdMap",
    );
    for (final entry in toolToServerIdMap.entries) {
      final toolName = entry.key;
      final serverId = entry.value;
      final client = state.activeClients[serverId];
      if (client != null &&
          client.isConnected &&
          !processedToolNames.contains(toolName)) {
        final tool = client.availableTools.firstWhereOrNull(
          (t) => t.functionDeclarations?.firstOrNull?.name == toolName,
        );
        if (tool != null) {
          allAvailableTools.add(tool);
          processedToolNames.add(toolName);
          debugPrint(
            "MCP ProcessQuery: Added tool '$toolName' from client [$serverId]",
          );
        } else {
          debugPrint(
            "MCP ProcessQuery: Warning - Tool '$toolName' expected from client [$serverId] but not found in its availableTools list.",
          );
        }
      } else if (client == null || !client.isConnected) {
        debugPrint(
          "MCP ProcessQuery: Warning - Client [$serverId] for tool '$toolName' is not connected or not found.",
        );
      }
    }
    if (allAvailableTools.isEmpty) {
      debugPrint(
        "MCP ProcessQuery: No tools available from connected MCP servers. Proceeding without tools.",
      );
    } else {
      debugPrint(
        "MCP ProcessQuery: Passing ${allAvailableTools.length} unique tools to Gemini: ${allAvailableTools.map((t) => t.functionDeclarations?.firstOrNull?.name ?? 'unknown').join(', ')}",
      );
    }
    GenerateContentResponse firstResponse;
    try {
      final List<Content> cleanHistory =
          history
              .map(
                (c) => Content(
                  c.role ?? 'user',
                  c.parts
                      .where((p) => !(p is TextPart && p.text.isEmpty))
                      .toList(),
                ),
              )
              .toList();
      final Content cleanQueryContent = Content('user', [TextPart(query)]);
      firstResponse = await geminiService.generateContent(
        cleanQueryContent,
        cleanHistory,
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
      final targetServerId = toolToServerIdMap[toolName];
      if (targetServerId == null) {
        debugPrint(
          "MCP ProcessQuery: Error - Tool '$toolName' requested by AI not found in tool map.",
        );
        try {
          final errorFollowUp = await geminiService.generateContent(
            Content('user', [
              TextPart(
                "The tool '$toolName' you tried to call is not available. Please inform the user.",
              ),
            ]),
            // Ensure history includes the model's function call attempt
            // MODIFY: Print JSON representation for Content object
            (history.map((c) => c).toList() +
                [if (candidate?.content != null) candidate!.content]),
            tools: null,
          );
          debugPrint(
            "MCP ProcessQuery: Error follow-up response: \${errorFollowUp.candidates.firstOrNull?.content?.toJson()}",
          );
          return McpProcessResult(
            finalModelContent:
                errorFollowUp.candidates.firstOrNull?.content ??
                Content('model', [
                  TextPart(
                    "Sorry, I tried to use a tool called '$toolName', but it seems to be unavailable right now.",
                  ),
                ]),
          );
        } catch (e) {
          debugPrint(
            "MCP ProcessQuery: Error during error follow-up Gemini call: $e",
          );
          return McpProcessResult(
            finalModelContent: Content('model', [
              TextPart(
                "Sorry, I tried to use a tool called '$toolName', but it seems to be unavailable right now.",
              ),
            ]),
          );
        }
      }
      final targetClient = state.activeClients[targetServerId];
      if (targetClient == null || !targetClient.isConnected) {
        debugPrint(
          "MCP ProcessQuery: Error - Client for server '$targetServerId' (tool '$toolName') not found or not connected.",
        );
        try {
          final errorFollowUp = await geminiService.generateContent(
            Content('user', [
              TextPart(
                "The server responsible for the tool '$toolName' is currently unavailable. Please inform the user.",
              ),
            ]),
            // Ensure history includes the model's function call attempt
            // MODIFY: Print JSON representation for Content object
            (history.map((c) => c).toList() +
                [if (candidate?.content != null) candidate!.content]),
            tools: null,
          );
          debugPrint(
            "MCP ProcessQuery: Unavailable server follow-up response: \${errorFollowUp.candidates.firstOrNull?.content?.toJson()}",
          );
          return McpProcessResult(
            finalModelContent:
                errorFollowUp.candidates.firstOrNull?.content ??
                Content('model', [
                  TextPart(
                    "Sorry, the server needed for the '$toolName' tool is currently unavailable.",
                  ),
                ]),
          );
        } catch (e) {
          debugPrint(
            "MCP ProcessQuery: Error during unavailable server follow-up Gemini call: $e",
          );
          return McpProcessResult(
            finalModelContent: Content('model', [
              TextPart(
                "Sorry, the server needed for the '$toolName' tool is currently unavailable.",
              ),
            ]),
          );
        }
      }
      // MODIFY: Use library prefix
      mcp_lib.CallToolResult toolResult;
      String toolResultString = '';
      Map<String, dynamic> toolResultJson = {};
      try {
        // MODIFY: Use library prefix
        final params = mcp_lib.CallToolRequestParams(
          name: toolName,
          arguments: toolArgs.map((key, value) => MapEntry(key, value)),
        );
        toolResult = await targetClient.callTool(params);
        toolResultString =
            toolResult.content
                // MODIFY: Use library prefix
                .whereType<mcp_lib.TextContent>()
                .map((c) => c.text)
                .join('\n')
                .trim();
        if (toolResultString.isNotEmpty) {
          debugPrint(
            "MCP ProcessQuery: Tool '$toolName' executed by server '$targetServerId'. Combined Text Result: '$toolResultString'",
          );
          try {
            final decoded = jsonDecode(toolResultString);
            if (decoded is Map<String, dynamic>) {
              toolResultJson = decoded;
            } else if (decoded is List) {
              toolResultJson = {'result_list': decoded};
            } else {
              toolResultJson = {'result_text': toolResultString};
            }
          } catch (e) {
            debugPrint(
              "MCP ProcessQuery: Tool result is not valid JSON. Using raw text.",
            );
            toolResultJson = {'result_text': toolResultString};
          }
        } else {
          toolResultString = jsonEncode(toolResult.toJson());
          toolResultJson = {'result_raw': toolResult.toJson()};
          debugPrint(
            "MCP ProcessQuery: Tool '$toolName' executed by server '$targetServerId'. No text content found. Raw Result: $toolResultString",
          );
        }
        debugPrint("MCP ProcessQuery: Parsed toolResultJson: $toolResultJson");
        final Content toolResponseContent = Content('function', [
          FunctionResponse(toolName, toolResultJson),
        ]);
        final List<Content> historyForSecondCall =
            // Ensure history includes the model's function call attempt AND the function response
            history.map((c) => c).toList() +
            [
              if (candidate?.content != null) candidate!.content,
              toolResponseContent,
            ];
        debugPrint(
          "MCP ProcessQuery: Making second Gemini call with tool response...",
        );
        final secondResponse = await geminiService.generateContent(
          // Send an empty user message to trigger processing of the function response
          Content('user', []),
          historyForSecondCall,
          tools: null,
        );
        final Content finalContent =
            secondResponse.candidates.firstOrNull?.content ??
            Content('model', [
              TextPart("Tool '$toolName' executed. $toolResultString"),
            ]);
        // MODIFY: Print text parts for Content object
        debugPrint(
          "MCP ProcessQuery: Final response to UI (after tool call): \"\${finalContent.parts.whereType<TextPart>().map((p) => p.text).join('')}\"",
        );
        return McpProcessResult(
          finalModelContent: finalContent,
          modelCallContent: candidate?.content,
          toolResponseContent: toolResponseContent,
          toolName: toolName,
          toolArgs: toolArgs,
          toolResult: toolResultString,
          sourceServerId: targetServerId,
        );
      } catch (e) {
        debugPrint(
          "MCP ProcessQuery: Error calling tool '$toolName' on server '$targetServerId': $e",
        );
        try {
          final errorFollowUp = await geminiService.generateContent(
            Content('user', [
              TextPart(
                "Executing the tool '$toolName' failed with error: ${e.toString()}. Please inform the user.",
              ),
            ]),
            // Ensure history includes the model's function call attempt
            // MODIFY: Print JSON representation for Content object
            (history.map((c) => c).toList() +
                [if (candidate?.content != null) candidate!.content]),
            tools: null,
          );
          debugPrint(
            "MCP ProcessQuery: Tool execution error follow-up response: \${errorFollowUp.candidates.firstOrNull?.content?.toJson()}",
          );
          return McpProcessResult(
            finalModelContent:
                errorFollowUp.candidates.firstOrNull?.content ??
                Content('model', [
                  TextPart(
                    "Sorry, I encountered an error while trying to execute the '$toolName' tool: ${e.toString()}",
                  ),
                ]),
          );
        } catch (geminiError) {
          debugPrint(
            "MCP ProcessQuery: Error during tool execution error follow-up Gemini call: $geminiError",
          );
          return McpProcessResult(
            finalModelContent: Content('model', [
              TextPart(
                "Sorry, I encountered an error while trying to execute the '$toolName' tool: ${e.toString()}",
              ),
            ]),
            modelCallContent: candidate?.content,
            toolResponseContent: Content('function', [
              FunctionResponse(toolName, {'error': e.toString()}),
            ]),
            toolName: toolName,
            toolArgs: toolArgs,
            sourceServerId: targetServerId,
          );
        }
      }
    } else {
      debugPrint(
        "MCP ProcessQuery: No function call requested by Gemini. Returning direct response.",
      );
      final Content directContent =
          candidate?.content ??
          Content('model', [
            TextPart("Sorry, I couldn't generate a response."),
          ]);
      // MODIFY: Print text parts for Content object
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
    state = const McpClientState();
    super.dispose();
  }
}

final mcpClientProvider =
    StateNotifierProvider<McpClientNotifier, McpClientState>((ref) {
  return McpClientNotifier(ref);
});
