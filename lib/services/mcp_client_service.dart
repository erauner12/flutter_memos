import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/providers/mcp_server_config_provider.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // Import settings for authentication keys
import 'package:flutter_memos/services/gemini_service.dart'; // Import for geminiServiceProvider
import 'package:flutter_memos/services/mcp_sse_client_transport.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp_lib;
import 'package:mcp_dart/src/shared/transport.dart' as transport_lib;

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
  final Content? toolResponseContent; // google_generative_ai.Content (FunctionResponse)
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

  McpProcessResult copyWith({
    Content? modelCallContent,
    Content? toolResponseContent,
    Content? finalModelContent,
    String? toolName,
    Map<String, dynamic>? toolArgs,
    String? toolResult,
    String? sourceServerId,
  }) {
    return McpProcessResult(
      modelCallContent: modelCallContent ?? this.modelCallContent,
      toolResponseContent: toolResponseContent ?? this.toolResponseContent,
      finalModelContent: finalModelContent ?? this.finalModelContent,
      toolName: toolName ?? this.toolName,
      toolArgs: toolArgs ?? this.toolArgs,
      toolResult: toolResult ?? this.toolResult,
      sourceServerId: sourceServerId ?? this.sourceServerId,
    );
  }
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
  transport_lib.Transport? _transport; // Use mcp_lib.Transport
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
            name: 'flutter-memos-mcp-client',
            version: '1.0.0',
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
      "GoogleMcpClient [\${config.id}]: Attempting connection (Type: \${config.connectionType.name})...",
    );

    try {
      // --- Branch based on connection type ---
      if (config.connectionType == McpConnectionType.stdio) {
        // --- Stdio Connection ---
        debugPrint(
          "GoogleMcpClient [\${config.id}]: Creating StdioClientTransport.",
        );
        debugPrint(
          "GoogleMcpClient [\${config.id}]: Command='\${config.command}', Args='\${config.args}', Env=\${config.customEnvironment.isNotEmpty ? config.customEnvironment.keys.join(',') : 'None'}",
        );

        if (config.command.trim().isEmpty) {
          throw StateError(
            "Stdio Connection failed: Command is missing in configuration for \${config.name} [\${config.id}].",
          );
        }

        // --- Environment Handling ---
        // Explicitly merge parent environment with custom environment.
        final Map<String, String> processEnvironment = Map.from(
          io.Platform.environment,
        );
        processEnvironment.addAll(
          config.customEnvironment,
        ); // Add/overwrite with custom vars

        debugPrint(
          "GoogleMcpClient [\${config.id}]: Prepared final environment for process: \${processEnvironment.keys.join(',')}",
        );
        // --- End Environment Handling ---

        // MODIFY: Use library prefix for Stdio types
        final serverParams = mcp_lib.StdioServerParameters(
          command: config.command,
          args: config.args.split(' ').where((s) => s.isNotEmpty).toList(),
          environment: processEnvironment,
          stderrMode: io.ProcessStartMode.normal,
        );

        debugPrint(
          "GoogleMcpClient [\${config.id}]: Passing environment to StdioServerParameters: \${serverParams.environment?.keys.join(',') ?? 'null'}",
        );

        final stdioTransport = mcp_lib.StdioClientTransport(
          serverParams,
        );
        _transport = stdioTransport;

        stdioTransport.onerror = (error) {
          final errorMsg = "MCP Stdio Transport error [\${config.id}]: \$error";
          debugPrint(errorMsg);
          _isConnected = false;
          _onError?.call(config.id, errorMsg);
          cleanup();
        };

        stdioTransport.onclose = () {
          debugPrint("MCP Stdio Transport closed [\${config.id}].");
          _isConnected = false;
          _onClose?.call(config.id);
          _transport = null;
          _tools = [];
        };

        await mcpClient.connect(stdioTransport);
        _isConnected = true;
        debugPrint(
          "GoogleMcpClient [\${config.id}]: Stdio Transport connected successfully.",
        );
      } else {
        // McpConnectionType.sse
        // --- SSE Connection ---
        final host = config.host;
        final port = config.port;

        debugPrint(
          "GoogleMcpClient [\${config.id}]: Creating SseClientTransport for manager at \$host:\$port",
        );

        if (host == null || host.trim().isEmpty) {
          throw StateError(
            "SSE Connection failed: Host is missing in configuration for \${config.name} [\${config.id}].",
          );
        }
        if (port == null || port <= 0 || port > 65535) {
          throw StateError(
            "SSE Connection failed: Port is missing or invalid (must be 1-65535) in configuration for \${config.name} [\${config.id}].",
          );
        }

        // MODIFY: Pass isSecure flag to SseClientTransport constructor
        final sseTransport = SseClientTransport(
          managerHost: host,
          managerPort: port,
          isSecure: config.isSecure, // Pass the flag here
        );
        _transport = sseTransport;

        sseTransport.onerror = (error) {
          final errorMsg = "MCP SSE Transport error [\${config.id}]: \$error";
          debugPrint(errorMsg);
          _isConnected = false;
          _onError?.call(config.id, errorMsg);
          cleanup();
        };

        sseTransport.onclose = () {
          debugPrint("MCP SSE Transport closed [\${config.id}].");
          _isConnected = false;
          _onClose?.call(config.id);
          _transport = null;
          _tools = [];
        };

        await mcpClient.connect(sseTransport);
        _isConnected = true;
        debugPrint(
          "GoogleMcpClient [\${config.id}]: SSE Transport connected successfully.",
        );
      }

      debugPrint(
        "GoogleMcpClient [\${config.id}]: Connection successful (Type: \${config.connectionType.name}), proceeding to fetch tools...",
      );
      await _fetchTools();

    } catch (e) {
      final errorMsg =
          "GoogleMcpClient [\${config.id}]: Failed to establish \${config.connectionType.name} connection: \$e";
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
        "GoogleMcpClient [\$serverId]: Cannot fetch tools, not connected.",
      );
      _tools = [];
      return;
    }
    debugPrint("GoogleMcpClient [\$serverId]: Fetching tools...");
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

  // MODIFY: Update callTool to use mcpClient and library prefix
  Future<mcp_lib.CallToolResult> callTool(
    mcp_lib.CallToolRequestParams params,
  ) async {
    if (!_isConnected || _transport == null) {
      throw Exception("Client [\$serverId] is not connected.");
    }
    debugPrint(
      "GoogleMcpClient [\$serverId]: Executing tool '\${params.name}' with args: \${jsonEncode(params.arguments)}",
    );
    try {
      return await mcpClient.callTool(params);
    } catch (e) {
      debugPrint(
        "GoogleMcpClient [\$serverId]: Error calling tool '\${params.name}': \$e",
      );
      rethrow;
    }
  }

  // MODIFY: Update cleanup to use mcpClient
  Future<void> cleanup() async {
    if (_transport == null && !_isConnected) {
      debugPrint("GoogleMcpClient [\$serverId]: Already cleaned up.");
      return;
    }

    final transportToClose = _transport;
    final wasConnected = _isConnected;

    _transport = null;
    _isConnected = false;
    _tools = [];

    if (wasConnected || transportToClose != null) {
      debugPrint("GoogleMcpClient [\$serverId]: Cleaning up...");
      try {
        await mcpClient.close();
        if (transportToClose is mcp_lib.StdioClientTransport) {
          await transportToClose.close();
        } else if (transportToClose is SseClientTransport) {
          await transportToClose.close();
        }
      } catch (e) {
        debugPrint("GoogleMcpClient [\$serverId]: Error during cleanup: \$e");
      }
      debugPrint("GoogleMcpClient [\$serverId]: Cleanup complete.");
    } else {
      debugPrint(
        "GoogleMcpClient [\$serverId]: Cleanup called but was not connected.",
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
  final Map<String, Timer> _reconnectTimers = {};
  // ADD: Map to track exponential backoff delays
  final Map<String, Duration> _reconnectDelays = {};
  // ADD: Constants for backoff timing
  static const Duration _initialReconnectDelay = Duration(seconds: 5);
  static const Duration _maxReconnectDelay = Duration(minutes: 1);

  McpClientNotifier(this.ref) : super(const McpClientState()) {
    initialize();
  }

  /// External callers may check the connection status without accessing the
  /// protected `state` field (which is forbidden outside a `StateNotifier`).
  bool get hasActiveConnections => state.hasActiveConnections;

  void initialize() {
    // MODIFY: Read from the new provider
    final initialConfigs = ref.read(mcpServerConfigProvider);
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

    // MODIFY: Listen to the new provider
    serverListSubscription = ref.listen<
      List<McpServerConfig>
    >(mcpServerConfigProvider, (previousList, newList) {
      debugPrint(
        "McpClientNotifier: Server list updated in settings. Syncing connections...",
      );
      final currentStatuses = Map<String, McpConnectionStatus>.from(
        state.serverStatuses,
      );
      final currentErrors = Map<String, String>.from(state.serverErrorMessages);
      final newServerIds = newList.map((s) => s.id).toSet();
      // Remove statuses/errors for servers that no longer exist
      currentStatuses.removeWhere((id, _) => !newServerIds.contains(id));
      currentErrors.removeWhere((id, _) => !newServerIds.contains(id));
      // Add default disconnected status for newly added servers
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
      // Trigger connection sync whenever the list changes
      syncConnections();
    }, fireImmediately: false);

    // Trigger initial sync after initialization
    Future.microtask(() {
      debugPrint("McpClientNotifier: Triggering initial connection sync...");
      syncConnections();
    });
  }

  // MODIFY: Helper method to schedule reconnection attempts with exponential backoff
  void _scheduleReconnect(String serverId) {
    if (!mounted) return;

    // Cancel any existing timer for this server
    _reconnectTimers[serverId]?.cancel();
    _reconnectTimers.remove(serverId);

    final serverConfig = state.serverConfigs.firstWhereOrNull(
      (s) => s.id == serverId,
    );

    // Only schedule if the server config exists and is marked active
    if (serverConfig != null && serverConfig.isActive) {
      // Get the current delay, default to initial if not set
      final currentDelay = _reconnectDelays[serverId] ?? _initialReconnectDelay;

      debugPrint(
        "MCP [_scheduleReconnect]: Scheduling reconnect for active server [\$serverId] in \$currentDelay.",
      );
      _reconnectTimers[serverId] = Timer(currentDelay, () {
        if (!mounted) return;
        _reconnectTimers.remove(
          serverId,
        ); // Remove timer entry before attempting connect

        // Re-check config and active status right before connecting
        final currentConfig = state.serverConfigs.firstWhereOrNull(
          (s) => s.id == serverId,
        );
        if (currentConfig != null && currentConfig.isActive) {
          // Check current status - don't try to connect if already connecting/connected
          final currentStatus = state.serverStatuses[serverId];
          if (currentStatus != McpConnectionStatus.connected &&
              currentStatus != McpConnectionStatus.connecting) {
            debugPrint(
              "MCP [_scheduleReconnect]: Timer fired for [\$serverId]. Attempting reconnect.",
            );
            connectServer(currentConfig); // Attempt connection
          } else {
            debugPrint(
              "MCP [_scheduleReconnect]: Timer fired for [\$serverId], but status is already \$currentStatus. Skipping reconnect.",
            );
            // Reset delay even if skipping, as it implies connection is okay now or being handled
            _reconnectDelays[serverId] = _initialReconnectDelay;
          }
        } else {
          debugPrint(
            "MCP [_scheduleReconnect]: Timer fired for [\$serverId], but server is no longer active or config removed. Skipping reconnect.",
          );
          _reconnectDelays.remove(
            serverId,
          ); // Clean up delay if server is gone/inactive
        }
      });

      // Calculate and store the *next* delay (exponential backoff)
      Duration nextDelay = currentDelay * 2;
      if (nextDelay > _maxReconnectDelay) {
        nextDelay = _maxReconnectDelay;
      }
      _reconnectDelays[serverId] = nextDelay;
      debugPrint(
        "MCP [_scheduleReconnect]: Next reconnect delay for [\$serverId] set to \$nextDelay.",
      );
    } else {
      debugPrint(
        "MCP [_scheduleReconnect]: Server [\$serverId] is not active or config not found. Skipping reconnect schedule.",
      );
      _reconnectDelays.remove(
        serverId,
      ); // Clean up delay if server is gone/inactive
    }
  }

  Future<void> connectServer(McpServerConfig serverConfig) async {
    final serverId = serverConfig.id;

    // ADD: Cancel any pending reconnect timer for this server before starting connection attempt
    _reconnectTimers[serverId]?.cancel();
    _reconnectTimers.remove(serverId);
    debugPrint(
      "MCP [connectServer]: Cleared any pending reconnect timer for [\$serverId].",
    );

    final currentStatus = state.serverStatuses[serverId];

    // --- START MODIFICATION: Inject Todoist API Key ---
    McpServerConfig configToUse = serverConfig;
    /* TODOIST INTEGRATION DISABLED
    if (serverConfig.customEnvironment.containsKey('TODOIST_API_TOKEN')) {
      debugPrint(
        "MCP [\$serverId]: Detected TODOIST_API_TOKEN key in config. Attempting to inject actual token.",
      );
      try {
        final todoistApiKey = ref.read(todoistApiKeyProvider);
        if (todoistApiKey.isNotEmpty) {
          final updatedEnv = Map<String, String>.from(
            serverConfig.customEnvironment,
          );
          updatedEnv['TODOIST_API_TOKEN'] = todoistApiKey;
          configToUse = serverConfig.copyWith(customEnvironment: updatedEnv);
          debugPrint(
            "MCP [\$serverId]: Successfully injected Todoist API token into environment for connection.",
          );
        } else {
          debugPrint(
            "MCP [\$serverId]: Warning - TODOIST_API_TOKEN key found, but token value from provider is empty. Proceeding without injection.",
          );
        }
      } catch (e) {
        debugPrint(
          "MCP [\$serverId]: Error reading Todoist API key provider: \$e. Proceeding without injection.",
        );
      }
    }
    */
    // --- END MODIFICATION ---

    debugPrint(
      "MCP [\$serverId]: Preparing to connect. Config Name: \${configToUse.name}, Custom Env Keys: \${configToUse.customEnvironment.keys.join(',')}",
    );

    if (state.activeClients.containsKey(serverId) ||
        currentStatus == McpConnectionStatus.connecting ||
        currentStatus == McpConnectionStatus.connected) {
      debugPrint(
        "MCP [\$serverId]: Already connected or connecting (Status: \$currentStatus), skipping connection attempt.",
      );
      return;
    }

    updateServerState(serverId, McpConnectionStatus.connecting);
    GoogleMcpClient? newClientInstance;

    try {
      final geminiService = ref.read(geminiServiceProvider);
      // Remove the model null check, GoogleMcpClient handles nullable model
      if (geminiService == null || !geminiService.isInitialized) {
        throw StateError("Gemini service not initialized.");
      }

      newClientInstance = GoogleMcpClient(serverId, geminiService.model);
      newClientInstance.setupCallbacks(
        onError: handleClientError,
        onClose: handleClientClose,
      );

      await newClientInstance.connectToServer(configToUse);

      if (newClientInstance.isConnected) {
        debugPrint(
          "MCP [\$serverId]: Client connected successfully. Updating state and rebuilding tool map...",
        );
        // Ensure reconnect timer is cancelled on successful connection
        _reconnectTimers[serverId]?.cancel();
        _reconnectTimers.remove(serverId);
        // ADD: Reset the reconnect delay back to initial on successful connection
        _reconnectDelays[serverId] = _initialReconnectDelay;
        debugPrint(
          "MCP [connectServer]: Reset reconnect delay for [\$serverId] to initial value.",
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
            "MCP [\$serverId]: State updated to connected for \${configToUse.name}.",
          );
          rebuildToolMap();
        } else {
          debugPrint(
            "MCP [\$serverId]: Connection succeeded but state changed or unmounted during connection. Cleaning up.",
          );
          await newClientInstance.cleanup();
        }
      } else {
        debugPrint(
          "MCP [\$serverId]: connectToServer completed but client is not connected. Setting status to error.",
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
      final errorMsg = "Connection failed: \${e.toString()}";
      debugPrint(
        "MCP [\$serverId]: Connection failed during setup: \$errorMsg",
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
    // ADD: Cancel any pending reconnect timer when explicitly disconnecting
    _reconnectTimers[serverId]?.cancel();
    _reconnectTimers.remove(serverId);
    // ADD: Remove the stored reconnect delay for this server
    _reconnectDelays.remove(serverId);
    debugPrint(
      "MCP [disconnectServer]: Cleared pending reconnect timer and delay for [\$serverId].",
    );

    final clientToDisconnect = state.activeClients[serverId];
    if (state.serverStatuses[serverId] != McpConnectionStatus.disconnected) {
      updateServerState(serverId, McpConnectionStatus.disconnected);
    }
    if (clientToDisconnect == null) {
      debugPrint("MCP [\$serverId]: No active client found to disconnect.");
      if (state.activeClients.containsKey(serverId)) {
        state = state.copyWith(removeClientIds: [serverId]);
        rebuildToolMap();
      }
      return;
    }
    debugPrint("MCP [\$serverId]: Disconnecting client...");
    await clientToDisconnect.cleanup();
    if (mounted && state.activeClients.containsKey(serverId)) {
      state = state.copyWith(removeClientIds: [serverId]);
      debugPrint(
        "MCP [\$serverId]: Disconnect process complete, client removed from state.",
      );
      rebuildToolMap();
    } else if (mounted) {
      debugPrint(
        "MCP [\$serverId]: Client already removed from state (likely via onClose).",
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
      final config = state.serverConfigs.firstWhereOrNull(
        (s) => s.id == serverId,
      );
      if (config != null) {
        connectServer(config);
      } else {
        debugPrint(
          "MCP Sync Warning: Config not found for server \$serverId during connect phase.",
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
        "MCP: Removing stale statuses/errors for IDs: \${statusesToRemove.join(', ')}",
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
          "MCP [\$serverId]: Client removed from active list due to status change to \$status.",
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
    debugPrint("MCP [\$serverId]: Received error callback: \$errorMsg");
    if (!mounted) return;
    // ADD: Schedule a reconnect attempt *before* updating state if server is active
    _scheduleReconnect(serverId);
    updateServerState(serverId, McpConnectionStatus.error, errorMsg: errorMsg);
  }

  void handleClientClose(String serverId) {
    debugPrint("MCP [\$serverId]: Received close callback.");
    if (!mounted) return;

    // Determine if the close was expected (e.g., due to error state already set)
    final wasInErrorState =
        state.serverStatuses[serverId] == McpConnectionStatus.error;

    // ADD: Schedule a reconnect attempt *before* updating state if server is active
    // Only schedule if not already in an error state (error state handles its own reconnect schedule)
    if (!wasInErrorState) {
      _scheduleReconnect(serverId);
    }

    if (state.serverStatuses[serverId] != McpConnectionStatus.error) {
      updateServerState(serverId, McpConnectionStatus.disconnected);
    } else {
      if (state.activeClients.containsKey(serverId)) {
        debugPrint(
          "MCP [\$serverId]: Close callback received while status is Error. Ensuring client instance is removed.",
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
      "MCP [_rebuildToolMap]: Starting rebuild. Active clients: \${currentClientIds.join(', ')}",
    );
    for (final serverId in currentClientIds) {
      final client = state.activeClients[serverId];
      if (client != null && client.isConnected) {
        debugPrint(
          "MCP [_rebuildToolMap]: Processing tools for connected client [\$serverId]",
        );
        for (final tool in client.availableTools) {
          for (final funcDec in tool.functionDeclarations ?? []) {
            if (newToolMap.containsKey(funcDec.name)) {
              if (!duplicateToolNames.contains(funcDec.name)) {
                duplicateToolNames.add(funcDec.name);
                debugPrint(
                  "MCP Warning: Duplicate tool name '\${funcDec.name}' found. Client [\$serverId] provides it, but already mapped to [\${newToolMap[funcDec.name]}]. Using first encountered.",
                );
              }
            } else {
              newToolMap[funcDec.name] = serverId;
              uniqueToolNames.add(funcDec.name);
              debugPrint(
                "MCP [_rebuildToolMap]: Mapped tool '\${funcDec.name}' to client [\$serverId]",
              );
            }
          }
        }
      } else {
        debugPrint(
          "MCP [_rebuildToolMap]: Skipping client [\$serverId] (not found in state or not connected).",
        );
      }
    }
    if (!const MapEquality().equals(toolToServerIdMap, newToolMap)) {
      toolToServerIdMap = newToolMap;
      debugPrint(
        "MCP [_rebuildToolMap]: Finished rebuilding. \${uniqueToolNames.length} unique tools. Final map: \$toolToServerIdMap",
      );
    } else {
      debugPrint(
        "MCP [_rebuildToolMap]: Finished rebuilding. Tool map unchanged.",
      );
    }
    if (duplicateToolNames.isNotEmpty || uniqueToolNames.isNotEmpty) {
      debugPrint(
        "MCP: Tool map status: \${uniqueToolNames.length} unique tools [\${uniqueToolNames.join(', ')}]. Duplicates ignored: [\${duplicateToolNames.join(', ')}]",
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
    debugPrint("MCP ProcessQuery: Entered processQuery with query: '\$query'");
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
    if (geminiService == null || !geminiService.isInitialized) {
      debugPrint(
        "MCP ProcessQuery: Gemini service not available or not initialized. Error: \${geminiService?.initializationError ?? 'Gemini service is null or model is missing.'}",
      );
      return McpProcessResult(
        finalModelContent: Content('model', [
          TextPart(
            "The AI service is not available: \${geminiService?.initializationError ?? 'Gemini service is null or model is missing.'}",
          ),
        ]),
      );
    }
    final List<Tool> allAvailableTools = [];
    final processedToolNames = <String>{};
    debugPrint(
      "MCP ProcessQuery: Gathering tools from active clients based on tool map: \$toolToServerIdMap",
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
            "MCP ProcessQuery: Added tool '\$toolName' from client [\$serverId]",
          );
        } else {
          debugPrint(
            "MCP ProcessQuery: Warning - Tool '\$toolName' expected from client [\$serverId] but not found in its availableTools list.",
          );
        }
      } else if (client == null || !client.isConnected) {
        debugPrint(
          "MCP ProcessQuery: Warning - Client [\$serverId] for tool '\$toolName' is not connected or not found.",
        );
      }
    }
    if (allAvailableTools.isEmpty) {
      debugPrint(
        "MCP ProcessQuery: No tools available from connected MCP servers. Proceeding without tools.",
      );
    } else {
      debugPrint(
        "MCP ProcessQuery: Passing \${allAvailableTools.length} unique tools to Gemini: \${allAvailableTools.map((t) => t.functionDeclarations?.firstOrNull?.name ?? 'unknown').join(', ')}",
      );
    }

    // --- First Gemini Call ---
    GenerateContentResponse firstResponse;
    try {
      final List<Content> cleanHistory =
          history
              .map(
                (c) => Content(
                  c.role ?? 'user',
                  c.parts.where((p) => !(p is TextPart && p.text.isEmpty)).toList(),
                ),
              )
              .toList();
      debugPrint(
        "MCP ProcessQuery: Making first Gemini call with query and \${allAvailableTools.length} tools.",
      );
      firstResponse = await geminiService.generateContent(
        query,
        cleanHistory,
        tools: allAvailableTools.isNotEmpty ? allAvailableTools : null,
      );
      final firstCandidate = firstResponse.candidates.firstOrNull;
      final functionCallPartCheck = firstCandidate?.content.parts
          .firstWhereOrNull((part) => part is FunctionCall);
      if (functionCallPartCheck != null &&
          functionCallPartCheck is FunctionCall) {
        debugPrint(
          "MCP ProcessQuery: First Gemini response contained FunctionCall: \${functionCallPartCheck.name}(\${functionCallPartCheck.args})",
        );
      } else {
        debugPrint(
          "MCP ProcessQuery: First Gemini response did NOT contain a FunctionCall.",
        );
      }
    } catch (e) {
      debugPrint("MCP ProcessQuery: Error during first Gemini call: \$e");
      return McpProcessResult(
        finalModelContent: Content('model', [
          TextPart("Error communicating with AI service: \${e.toString()}"),
        ]),
      );
    }

    final candidate = firstResponse.candidates.firstOrNull;
    final functionCallPart = candidate?.content.parts.firstWhereOrNull(
      (part) => part is FunctionCall,
    );

    // --- Handle Function Call ---
    if (functionCallPart != null && functionCallPart is FunctionCall) {
      final functionCall = functionCallPart;
      final toolName = functionCall.name;
      final toolArgs = functionCall.args;
      debugPrint(
        "MCP ProcessQuery: Gemini requested Function Call: '\$toolName' with args: \$toolArgs",
      );

      final targetServerId = toolToServerIdMap[toolName];
      if (targetServerId == null) {
        debugPrint(
          "MCP ProcessQuery: Error - Tool '\$toolName' requested by AI not found in tool map.",
        );
        try {
          final errorFollowUp = await geminiService.generateContent(
            "The tool '\$toolName' you tried to call is not available. Please inform the user.",
            (history.map((c) => c).toList() +
                [if (candidate?.content != null) candidate!.content]),
            tools: null,
          );
          debugPrint(
            "MCP ProcessQuery: Error follow-up response: \${errorFollowUp.candidates.firstOrNull?.content.toJson()}",
          );
          return McpProcessResult(
            finalModelContent:
                errorFollowUp.candidates.firstOrNull?.content ??
                Content('model', [
                  TextPart(
                    "Sorry, I tried to use a tool called '\$toolName', but it seems to be unavailable right now.",
                  ),
                ]),
          );
        } catch (e) {
          debugPrint(
            "MCP ProcessQuery: Error during error follow-up Gemini call: \$e",
          );
          return McpProcessResult(
            finalModelContent: Content('model', [
              TextPart(
                "Sorry, I tried to use a tool called '\$toolName', but it seems to be unavailable right now.",
              ),
            ]),
          );
        }
      }

      final targetClient = state.activeClients[targetServerId];
      if (targetClient == null || !targetClient.isConnected) {
        debugPrint(
          "MCP ProcessQuery: Error - Client for server '\$targetServerId' (tool '\$toolName') not found or not connected.",
        );
        try {
          final errorFollowUp = await geminiService.generateContent(
            "The server responsible for the tool '\$toolName' is currently unavailable. Please inform the user.",
            (history.map((c) => c).toList() +
                [if (candidate?.content != null) candidate!.content]),
            tools: null,
          );
          debugPrint(
            "MCP ProcessQuery: Unavailable server follow-up response: \${errorFollowUp.candidates.firstOrNull?.content.toJson()}",
          );
          return McpProcessResult(
            finalModelContent:
                errorFollowUp.candidates.firstOrNull?.content ??
                Content('model', [
                  TextPart(
                    "Sorry, the server needed for the '\$toolName' tool is currently unavailable.",
                  ),
                ]),
          );
        } catch (e) {
          debugPrint(
            "MCP ProcessQuery: Error during unavailable server follow-up Gemini call: \$e",
          );
          return McpProcessResult(
            finalModelContent: Content('model', [
              TextPart(
                "Sorry, the server needed for the '\$toolName' tool is currently unavailable.",
              ),
            ]),
          );
        }
      }

      // --- Execute Tool via MCP ---
      mcp_lib.CallToolResult toolResult;
      String toolResultString = '';
      Map<String, dynamic> toolResultJson = {}; // Keep this for fallback
      try {
        final params = mcp_lib.CallToolRequestParams(
          name: toolName,
          arguments: toolArgs.map((key, value) => MapEntry(key, value)),
        );
        debugPrint(
          "MCP ProcessQuery: Calling MCP tool '\$toolName' on server '\$targetServerId'...",
        );
        toolResult = await targetClient.callTool(params);
        toolResultString =
            toolResult.content
                .whereType<mcp_lib.TextContent>()
                .map((c) => c.text)
                .join('\n')
                .trim();

        // --- Phase 4: Parse standardized JSON (Keep existing logic) ---
        try {
          final decoded = jsonDecode(toolResultString);
          if (decoded is Map<String, dynamic>) {
            final status = decoded['status'] as String?;
            final message = decoded['message'] as String?;
            final resultData = decoded['result'] as Map<String, dynamic>?;
            if (status == 'success') {
              toolResultJson = resultData ?? {'message': message ?? 'Success'};
              debugPrint(
                "MCP ProcessQuery: Parsed SUCCESS result for Gemini: \$toolResultJson",
              );
            } else if (status == 'error') {
              toolResultJson = {
                'error': message ?? 'Unknown server error',
                ...?resultData,
              };
              debugPrint(
                "MCP ProcessQuery: Parsed ERROR result for Gemini: \$toolResultJson",
              );
            } else {
              debugPrint(
                "MCP ProcessQuery: Parsed JSON but status field ('\$status') is missing or unexpected. Using raw map.",
              );
              toolResultJson = decoded;
            }
          } else if (decoded is List) {
            debugPrint(
              "MCP ProcessQuery: Tool result is JSON List. Wrapping in 'result_list'.",
            );
            // Ensure toolResultJson is a Map for FunctionResponse
            toolResultJson = {'result_list': decoded};
          } else {
            debugPrint(
              "MCP ProcessQuery: Tool result is not a JSON Map or List. Wrapping in 'result_value'.",
            );
            toolResultJson = {'result_value': decoded};
          }
        } catch (e) {
          debugPrint(
            "MCP ProcessQuery: Tool result is not valid JSON ('\$e'). Using raw text.",
          );
          toolResultJson = {'result_text': toolResultString};
        }
        if (toolResultString.isEmpty) {
          toolResultString =
              '{"status": "success", "message": "Tool executed successfully but returned no content.", "result": {}}';
          toolResultJson = {'message': 'Tool executed successfully but returned no content.'};
          debugPrint(
            "MCP ProcessQuery: Tool '\$toolName' executed by server '\$targetServerId'. No text content found. Sending default success message.",
          );
        }
        // --- End Phase 4 ---

        // --- Refine FunctionResponse ---
        Map<String, dynamic> responseDataForGemini = {};
        try {
          // Attempt to parse the full MCP response string
          final Map<String, dynamic> mcpResponse = jsonDecode(toolResultString);
          // Include status, message, and the actual result data
          responseDataForGemini = {
            'status': mcpResponse['status'] ?? 'unknown',
            'message': mcpResponse['message'] ?? 'No message provided.',
            'result': mcpResponse['result'] ?? {}, // Include the original result data
          };
          debugPrint("MCP ProcessQuery: Refined FunctionResponse data for Gemini: \$responseDataForGemini");
        } catch (e) {
          debugPrint("MCP ProcessQuery: Failed to parse MCP response for FunctionResponse refinement. Using raw result map. Error: \$e");
          // Fallback to the previously parsed toolResultJson if full parsing fails
          responseDataForGemini = toolResultJson;
        }
        // --- End Refine FunctionResponse ---

        final Content toolResponseContent = Content('function', [
          // Use the refined map
          FunctionResponse(toolName, responseDataForGemini),
        ]);

        final List<Content> historyForSecondCall =
            history.map((c) => c).toList();
        historyForSecondCall.add(Content('user', [TextPart(query)]));
        if (candidate?.content != null) {
          historyForSecondCall.add(candidate!.content); // Gemini's function call request
        }
        historyForSecondCall.add(toolResponseContent); // The tool's refined response

        // *** ADD INSTRUCTION ***
        historyForSecondCall.add(Content('user', [
          TextPart(
            "Based *only* on the preceding tool execution result (FunctionResponse), formulate a direct response to the initial user query ('\$query'). Do not ask for information the tool should have provided. If the tool indicated success but found no results (e.g., no tasks for today), state that clearly. If the tool reported an error, state the error message."
          )
        ]));
        // *** END INSTRUCTION ***

        debugPrint(
          "MCP ProcessQuery: Making second Gemini call with tool response and explicit instruction...",
        );
        final secondResponse = await geminiService.generateContent(
          // Keep prompt empty, instruction is in history
          '',
          historyForSecondCall,
          tools: null, // No tools needed for the summarization call
        );

        final Content finalContent =
            secondResponse.candidates.firstOrNull?.content ??
            Content('model', [
              TextPart(
                "Tool '\$toolName' executed. Result: \$toolResultString",
              ),
            ]);
        final finalResponseText = finalContent.parts
            .whereType<TextPart>()
            .map((p) => p.text)
            .join('');
        debugPrint(
          "MCP ProcessQuery: Raw finalContent from Gemini (2nd call): \${jsonEncode(finalContent.toJson())}",
        );
        debugPrint(
          "MCP ProcessQuery: Extracted final text for UI: \"\$finalResponseText\"",
        );
        if (finalResponseText.isEmpty ||
            finalResponseText.toLowerCase().contains(
              "provide me with a prompt",
            )) {
          debugPrint(
            "MCP ProcessQuery: WARNING - Second Gemini call resulted in empty or generic response!",
          );
        }
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
          "MCP ProcessQuery: Error during tool execution or second Gemini call: \$e",
        );
        try {
          final errorFollowUp = await geminiService.generateContent(
            "Executing the tool '\$toolName' failed with error: \${e.toString()}. Please inform the user.",
            (history.map((c) => c).toList() +
                [if (candidate?.content != null) candidate!.content]),
            tools: null,
          );
          debugPrint(
            "MCP ProcessQuery: Tool execution error follow-up response: \${errorFollowUp.candidates.firstOrNull?.content.toJson()}",
          );
          return McpProcessResult(
            finalModelContent:
                errorFollowUp.candidates.firstOrNull?.content ??
                Content('model', [
                  TextPart(
                    "Sorry, I encountered an error while trying to execute the '\$toolName' tool: \${e.toString()}",
                  ),
                ]),
          );
        } catch (geminiError) {
          debugPrint(
            "MCP ProcessQuery: Error during tool execution error follow-up Gemini call: \$geminiError",
          );
          return McpProcessResult(
            finalModelContent: Content('model', [
              TextPart(
                "Sorry, I encountered an error while trying to execute the '\$toolName' tool: \${e.toString()}",
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
      
      debugPrint(
        "MCP ProcessQuery: Raw directContent from Gemini (1st call): \${jsonEncode(directContent.toJson())}",
      );
      
      return McpProcessResult(finalModelContent: directContent);
    }
  }

  @override
  void dispose() {
    debugPrint("Disposing McpClientNotifier, cleaning up all clients...");
    serverListSubscription?.close();
    // Cancel all pending reconnect timers
    _reconnectTimers.forEach((_, timer) => timer.cancel());
    _reconnectTimers.clear();
    // ADD: Clear the reconnect delays map
    _reconnectDelays.clear();
    debugPrint("MCP [dispose]: Cancelled timers and cleared reconnect delays.");

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
