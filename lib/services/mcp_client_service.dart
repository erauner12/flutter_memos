import 'dart:async';
import 'dart:io'; // Needed for Platform.environment and ProcessStartMode

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // To get server list and Gemini key
// import 'package:flutter_memos/services/gemini_service.dart'; // PHASE 3: To get Gemini model
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Import for Gemini types
import 'package:mcp_dart/mcp_dart.dart'
    as mcp_dart; // Import MCP types with prefix

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
  mcp_dart.StdioClientTransport? _transport;
  List<Tool> _tools = [];
  bool _isConnected = false;
  Function(String serverId, String errorMsg)? _onError;
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

  Future<void> connectToServer(
    String command,
    List<String> args,
    Map<String, String> environment,
  ) async {
    if (_isConnected) return;
    if (command.trim().isEmpty) throw Exception("MCP command cannot be empty.");
    debugPrint(
      "GoogleMcpClient [\$serverId]: Attempting connection: \$command \${args.join(' ')}",
    );

    try {
      _transport = mcp_dart.StdioClientTransport(
        mcp_dart.StdioServerParameters(
          command: command,
          args: args,
          // Pass the environment received from the notifier
          environment: environment,
          stderrMode: ProcessStartMode.normal,
        ),
      );

      _transport!.onerror = (error) {
        final errorMsg = "MCP Transport error [\$serverId]: \$error";
        debugPrint(errorMsg);
        _isConnected = false;
        _onError?.call(serverId, errorMsg);
        cleanup();
      };

      _transport!.onclose = () {
        debugPrint("MCP Transport closed [\$serverId].");
        _isConnected = false;
        _onClose?.call(serverId);
        _transport = null;
        _tools = [];
      };

      await mcp.connect(_transport!);
      _isConnected = true;
      debugPrint("GoogleMcpClient [\$serverId]: Connected successfully.");
      // *** ADD LOGGING HERE ***
      debugPrint(
        "GoogleMcpClient [\$serverId]: Connection successful, proceeding to fetch tools...",
      );
      await _fetchTools();
    } catch (e) {
      debugPrint("GoogleMcpClient [\$serverId]: Failed to connect: \$e");
      _isConnected = false;
      await cleanup();
      rethrow;
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
      // *** ADD LOGGING HERE ***
      debugPrint(
        "GoogleMcpClient [\$serverId]: Raw tools list result: \${toolsResult.tools.map((t) => t.toJson()).toList()}",
      );
      List<Tool> fetchedTools = [];
      for (var toolDef in toolsResult.tools) {
        try {
          final schemaJson = toolDef.inputSchema.toJson();
          final schema = SchemaExtension.fromJson(schemaJson);
          if (schema != null || (schemaJson['type'] == 'object' && (schemaJson['properties'] == null || (schemaJson['properties'] as Map).isEmpty))) {
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
      // *** ADD LOGGING HERE ***
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
        "MCP [\$serverId]: Already connected or connecting, skipping connection attempt.",
      );
      return;
    }
    /*
    final geminiService = ref.read(geminiServiceProvider);
    if (geminiService == null || !geminiService.isInitialized) {
       updateServerState(serverId, McpConnectionStatus.error, errorMsg: "Gemini service not ready.");
       return;
    }
    */
    if (serverConfig.command.trim().isEmpty) {
      updateServerState(serverId, McpConnectionStatus.error, errorMsg: "Server command is empty.");
      return;
    }

    updateServerState(serverId, McpConnectionStatus.connecting);
    GoogleMcpClient? newClientInstance;

    try {
      // Fetch Todoist token using the provider
      // Ensure todoistApiKeyProvider is accessible here (might need adjustment if not directly in ref scope)
      final todoistApiToken = ref.read(
        todoistApiKeyProvider,
      ); // Read the current token value

      // Prepare environment, including custom vars from config AND the token
      final Map<String, String> environmentToPass = {
        ...serverConfig.customEnvironment, // Keep existing custom vars
        // Conditionally add the token if it's not empty
        if (todoistApiToken.isNotEmpty) 'TODOIST_API_TOKEN': todoistApiToken,
      };
      // Log the environment being passed (excluding sensitive values in production)
      if (kDebugMode) {
        final safeEnvLog = Map.from(environmentToPass);
        if (safeEnvLog.containsKey('TODOIST_API_TOKEN')) {
          safeEnvLog['TODOIST_API_TOKEN'] = '********'; // Mask token in logs
        }
        debugPrint(
          "MCP [\$serverId]: Launching with environment: \$safeEnvLog",
        );
      }

      final command = serverConfig.command;
      final argsList =
          serverConfig.args.split(' ').where((s) => s.isNotEmpty).toList();
      // PHASE 3: Pass geminiService.model instead of null
      newClientInstance = GoogleMcpClient(
        serverId,
        null /* geminiService.model */,
      );
      newClientInstance.setupCallbacks(
        onError: handleClientError,
        onClose: handleClientClose,
      );

      await newClientInstance.connectToServer(
        command,
        argsList,
        // Pass the combined environment map here
        environmentToPass,
      );

      if (newClientInstance.isConnected) {
        // *** ADD LOGGING HERE ***
        debugPrint(
          "MCP [_connectServer - \$serverId]: Client connected successfully. Updating state and rebuilding tool map...",
        );
        state = state.copyWith(
          activeClients: {...state.activeClients, serverId: newClientInstance},
          serverStatuses: {...state.serverStatuses, serverId: McpConnectionStatus.connected},
          removeErrorIds: [serverId],
        );
        debugPrint(
          "MCP [\$serverId]: Connected successfully to \${serverConfig.name}.",
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
      debugPrint("MCP [\$serverId]: Connection failed during setup: \$e");
      if (state.serverStatuses[serverId] != McpConnectionStatus.error) {
        updateServerState(
          serverId,
          McpConnectionStatus.error,
          errorMsg: "Connection failed: \$e",
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
      debugPrint("MCP [\$serverId]: No active client found to disconnect.");
      if (state.activeClients.containsKey(serverId)) {
        state = state.copyWith(removeClientIds: [serverId]);
        rebuildToolMap(); // Call rebuild after removing client ID
      }
      return;
    }
    debugPrint("MCP [\$serverId]: Disconnecting client...");
    await clientToDisconnect.cleanup();
    // Check if the client still exists in the state *before* updating
    if (state.activeClients.containsKey(serverId)) {
      // Update state to remove the client
      state = state.copyWith(removeClientIds: [serverId]);
      debugPrint(
        "MCP [\$serverId]: Disconnect process complete, client removed from state.",
      );
      // Rebuild the tool map *after* the state update
      rebuildToolMap();
    } else {
      debugPrint(
        "MCP [\$serverId]: Client already removed from state during cleanup.",
      );
       // Ensure tool map is still rebuilt if the client might have been removed by error handler first
      rebuildToolMap();
    }
  }

  void syncConnections() {
    if (!mounted) return;
    final desiredActiveServers = state.serverConfigs.where((s) => s.isActive).map((s) => s.id).toSet();
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
    final serversToDisconnect = currentlyConnectingOrConnected.difference(desiredActiveServers)
        .union(currentlyConnectingOrConnected.difference(knownServerIds));
    if (serversToConnect.isNotEmpty || serversToDisconnect.isNotEmpty) {
      debugPrint("Syncing MCP Connections:");
      if (serversToConnect.isNotEmpty) {
        debugPrint(" - To Connect: \${serversToConnect.join(', ')}");
      }
      if (serversToDisconnect.isNotEmpty) {
        debugPrint(" - To Disconnect: \${serversToDisconnect.join(', ')}");
      }
    }
    for (final serverId in serversToDisconnect) {
      disconnectServer(serverId);
    }
    for (final serverId in serversToConnect) {
      final config = state.serverConfigs.firstWhereOrNull((s) => s.id == serverId);
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
        "MCP: Removing stale statuses/errors for IDs: \${statusesToRemove.join(', ')}",
      );
      state = state.copyWith(
        removeStatusIds: statusesToRemove.toList(),
        removeErrorIds: statusesToRemove.toList(),
      );
    }
  }

  // --- State Update Helpers ---
  void updateServerState(String serverId, McpConnectionStatus status, {String? errorMsg}) {
    if (!mounted) return;
    final newStatuses = Map<String, McpConnectionStatus>.from(state.serverStatuses);
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
    if (status == McpConnectionStatus.disconnected || status == McpConnectionStatus.error) {
      if (newClients.remove(serverId) != null) {
        clientRemoved = true;
      }
    }
    if (statusChanged || clientRemoved || (errorMsg != null && state.serverErrorMessages[serverId] != errorMsg) || (errorMsg == null && state.serverErrorMessages.containsKey(serverId))) {
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
    debugPrint("MCP [\$serverId]: Received error callback: \$errorMsg");
    updateServerState(serverId, McpConnectionStatus.error, errorMsg: errorMsg);
  }

  void handleClientClose(String serverId) {
    debugPrint("MCP [\$serverId]: Received close callback.");
    if (state.serverStatuses[serverId] != McpConnectionStatus.error) {
       // If not already in error, update status to disconnected which also removes client
       updateServerState(serverId, McpConnectionStatus.disconnected);
      // updateServerState calls rebuildToolMap if client was removed
    } else {
      // If it was already in error state, just ensure the client reference is removed
      if (state.activeClients.containsKey(serverId)) {
        state = state.copyWith(removeClientIds: [serverId]);
        rebuildToolMap(); // Explicitly rebuild map after removing client due to close in error state
      }
    }
  }

  // --- Tool Management (Adapted from example - for future use) ---
  void rebuildToolMap() {
    if (!mounted) return;
    final newToolMap = <String, String>{};
    final Set<String> uniqueToolNames = {};
    final List<String> duplicateToolNames = [];
    // Use a copy of keys to avoid concurrent modification issues if state changes during iteration
    final currentClientIds = List<String>.from(state.activeClients.keys);

    for (final serverId in currentClientIds) {
      final client = state.activeClients[serverId];
      if (client != null && client.isConnected) {
        for (final tool in client.availableTools) {
          // Ensure functionDeclarations is not null before iterating
          for (final funcDec in tool.functionDeclarations ?? []) {
            if (newToolMap.containsKey(funcDec.name)) {
              // Handle duplicates if necessary (e.g., log a warning)
              if (!duplicateToolNames.contains(funcDec.name)) {
                duplicateToolNames.add(funcDec.name);
                debugPrint(
                  "MCP Warning: Duplicate tool name '\${funcDec.name}' found on multiple servers. Using first encountered.",
                );
              }
            } else {
              newToolMap[funcDec.name] =
                  serverId; // Store tool name -> server ID
              uniqueToolNames.add(funcDec.name);
            }
          }
        }
      }
    }

    toolToServerIdMap = newToolMap; // Assign the populated map

    // *** ADD LOGGING HERE ***
    debugPrint(
      "MCP [_rebuildToolMap]: Finished rebuilding. Final map: \$toolToServerIdMap",
    );

    if (duplicateToolNames.isNotEmpty || uniqueToolNames.isNotEmpty) {
      debugPrint(
        "MCP: Rebuilt tool map. \${uniqueToolNames.length} unique tools found: [\${uniqueToolNames.join(', ')}]. Duplicates: [\${duplicateToolNames.join(', ')}]",
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
    // *** ADD LOGGING HERE ***
    debugPrint("MCP ProcessQuery: Entered processQuery with query: '\$query'");

    if (!state.hasActiveConnections) {
      debugPrint("MCP ProcessQuery: No active MCP connections.");
      return McpProcessResult(
        finalModelContent: Content('model', [
          TextPart("No active MCP server to process the request."),
        ]),
      );
    }

    // --- START TEMPORARY TEST CODE for create_todoist_task ---
    final toolToCall = 'create_todoist_task';
    final targetServerId = toolToServerIdMap[toolToCall];

    debugPrint(
      "MCP ProcessQuery: Looked up '\$toolToCall' tool. Found Server ID: \$targetServerId. Current tool map: \$toolToServerIdMap",
    );

    if (targetServerId == null) {
      debugPrint(
        "MCP ProcessQuery: '\$toolToCall' tool not found in map: \$toolToServerIdMap",
      );
      return McpProcessResult(
        finalModelContent: Content('model', [
          TextPart("MCP server connected, but '\$toolToCall' tool not found."),
        ]),
      );
    }

    final targetClient = state.activeClients[targetServerId];
    final isClientConnected = targetClient?.isConnected ?? false;

    debugPrint(
      "MCP ProcessQuery: Checking target client for server '\$targetServerId'. Found: \${targetClient != null}, Connected: \$isClientConnected",
    );

    if (targetClient == null || !isClientConnected) {
      debugPrint(
        "MCP ProcessQuery: Client for '\$toolToCall' tool (Server \$targetServerId) is not connected or found.",
      );
      updateServerState(
        targetServerId,
        McpConnectionStatus.error,
        errorMsg: "Client for '\$toolToCall' tool disconnected unexpectedly.",
      );
      return McpProcessResult(
        finalModelContent: Content('model', [
          TextPart(
            "Error: Client for '\$toolToCall' tool (Server \$targetServerId) is not connected.",
          ),
        ]),
        toolName: toolToCall,
        sourceServerId: targetServerId,
      );
    }

    debugPrint(
      "MCP ProcessQuery: Routing '\$toolToCall' tool call to server \$targetServerId",
    );

    try {
      // Define the arguments for the Todoist task here
      final taskArgs = {
        'content':
            'Test Task from Flutter Memos: \$query', // Use user query in content
        'description': 'Created via manual MCP test call.',
        // 'project_id': 'YOUR_PROJECT_ID', // Optional: Add a specific project ID if needed
        'labels': ['mcp_test', 'flutter'], // Optional: Add some labels
        'priority': 4, // Optional: Set priority (as integer)
        // 'due_string': 'tomorrow', // Optional: Set a due date
      };

      final params = mcp_dart.CallToolRequestParams(
        name: toolToCall,
        arguments: taskArgs,
      );
      final result = await targetClient.callTool(params);

      final toolResponseText = result.content
          .whereType<mcp_dart.TextContent>()
          .map((c) => c.text)
          .join('\n');

      debugPrint(
        "MCP ProcessQuery: Tool '\$toolToCall' executed on server \$targetServerId. Result: \$toolResponseText",
      );

      return McpProcessResult(
        modelCallContent: null,
        toolResponseContent: null,
        finalModelContent: Content('model', [TextPart(toolResponseText)]),
        toolName: toolToCall,
        toolArgs: params.arguments,
        toolResult: toolResponseText,
        sourceServerId: targetServerId,
      );
    } catch (e) {
      final errorMsg =
          "Error executing tool '\$toolToCall' on server \$targetServerId: \$e";
      debugPrint("MCP ProcessQuery: \$errorMsg");
      updateServerState(
        targetServerId,
        McpConnectionStatus.error,
        errorMsg: errorMsg,
      );
      return McpProcessResult(
        finalModelContent: Content('model', [
          TextPart("Error: \$errorMsg"),
        ]),
        toolName: toolToCall,
        sourceServerId: targetServerId,
      );
    }
    // --- END TEMPORARY TEST CODE ---

    /* --- ORIGINAL/FUTURE GEMINI LOGIC WOULD GO HERE ---
    // ... (Code to prepare tools for Gemini, call generateContent, handle FunctionCall, etc.)
    */
  }
  
  // --- Cleanup ---
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
final mcpClientProvider = StateNotifierProvider<McpClientNotifier, McpClientState>((ref) {
  return McpClientNotifier(ref);
});
