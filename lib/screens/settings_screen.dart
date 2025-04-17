import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
// Import MCP related files
import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/chat_providers.dart';
// ADD: Import the new MCP config provider
import 'package:flutter_memos/providers/mcp_server_config_provider.dart';
import 'package:flutter_memos/providers/note_providers.dart'
    as note_providers; // For cache clearing?
import 'package:flutter_memos/providers/server_config_provider.dart';
// Import providers needed for reset
import 'package:flutter_memos/providers/service_providers.dart'; // For cloudKitServiceProvider
import 'package:flutter_memos/providers/settings_provider.dart'; // Import settings provider
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/add_edit_mcp_server_screen.dart'; // Will be created next
import 'package:flutter_memos/screens/add_edit_server_screen.dart';
import 'package:flutter_memos/services/base_api_service.dart'; // Import BaseApiService
// Import MCP client provider (for status later)
import 'package:flutter_memos/services/mcp_client_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;
  const SettingsScreen({super.key, this.isInitialSetup = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Memos/Blinko server state
  bool _isTestingConnection = false;

  // Todoist state
  final _todoistApiKeyController = TextEditingController();
  bool _isTestingTodoistConnection = false;

  // OpenAI state
  final _openaiApiKeyController = TextEditingController();
  bool _isTestingOpenAiConnection = false;
  // Add state for model loading
  bool _isLoadingModels = false;
  List<String> _availableModels = [];
  String? _modelLoadError;

  // Gemini state
  final _geminiApiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize controllers after the first frame ensures providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // --- START MODIFICATION ---
        // Directly read the persisted Todoist API key
        final initialTodoistKey = ref.read(todoistApiKeyProvider);
        _todoistApiKeyController.text = initialTodoistKey;
        // --- END MODIFICATION ---

        final initialOpenAiKey = ref.read(openAiApiKeyProvider);
        _openaiApiKeyController.text = initialOpenAiKey;

        // Initialize Gemini controller
        final initialGeminiKey = ref.read(geminiApiKeyProvider);
        _geminiApiKeyController.text = initialGeminiKey;
      }
      // Fetch models after initial setup
      _fetchModels();
    });
  }

  @override
  void dispose() {
    _todoistApiKeyController.dispose();
    _openaiApiKeyController.dispose(); // Dispose the new controller
    _geminiApiKeyController.dispose(); // Dispose Gemini controller
    super.dispose();
  }

  // Method to fetch models
  Future<void> _fetchModels() async {
    if (!mounted) return;
    setState(() {
      _isLoadingModels = true;
      _modelLoadError = null;
      _availableModels = []; // Clear previous models
    });

    final openaiService = ref.read(openaiApiServiceProvider);
    // Check API key provider directly as service config might lag
    final apiKey = ref.read(openAiApiKeyProvider);

    if (apiKey.isEmpty) {
      setState(() {
        _isLoadingModels = false;
        _modelLoadError = 'OpenAI API Key not configured.';
      });
      return;
    }
    // Ensure service is configured with the latest key before fetching
    openaiService.configureService(authToken: apiKey);

    try {
      final models = await openaiService.listCompletionModels();
      if (mounted) {
        setState(() {
          _availableModels = models;
          _isLoadingModels = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
          _modelLoadError = 'Failed to load models: ${e.toString()}';
        });
      }
    }
  }

  void _showResultDialog(String title, String content, {bool isError = false}) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  // Test Memos/Blinko connection (should not be called for Todoist)
  Future<void> _testConnection() async {
    FocusScope.of(context).unfocus();
    final activeConfig = ref.read(activeServerConfigProvider);

    if (activeConfig == null) {
      _showResultDialog(
        'No Active Server',
        'Please select or add a server configuration first.',
        isError: true,
      );
      return;
    }

    // This button should be disabled if active server is Todoist
    if (activeConfig.serverType == ServerType.todoist) {
      _showResultDialog(
        'Info',
        'Test Todoist connection via the Integrations section below.',
      );
      return;
    }

    setState(() => _isTestingConnection = true);
    // Get the service (already configured by the provider)
    final apiService = ref.read(apiServiceProvider);

    // Check if it's a dummy service (e.g., URL was empty)
    if (apiService is DummyApiService || !apiService.isConfigured) {
      _showResultDialog(
        'Configuration Error',
        'The active server is not properly configured.',
        isError: true,
      );
      setState(() => _isTestingConnection = false);
      return;
    }

    try {
      // Use checkHealth for Memos/Blinko
      final isHealthy = await apiService.checkHealth();
      if (mounted) {
        if (isHealthy) {
          _showResultDialog(
            'Success',
            'Connection to ${activeConfig.serverType.name} server "${activeConfig.name ?? activeConfig.serverUrl}" successful!',
          );
        } else {
          _showResultDialog(
            'Connection Failed',
            'Could not connect to ${activeConfig.serverType.name} server "${activeConfig.name ?? activeConfig.serverUrl}". Check configuration.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("[SettingsScreen] Test Connection Error: \$e");
      }
      if (mounted) {
        _showResultDialog(
          'Connection Failed',
          'Could not connect to ${activeConfig.serverType.name} server "${activeConfig.name ?? activeConfig.serverUrl}".\n\nError: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingConnection = false);
    }
  }

  // Test Todoist connection (using the dedicated service provider)
  Future<void> _testTodoistConnection() async {
    FocusScope.of(context).unfocus();
    // Use the dedicated Todoist service provider
    final todoistService = ref.read(todoistApiServiceProvider);
    final currentKey = ref.read(
      todoistApiKeyProvider,
    ); // Read the globally saved key

    if (currentKey.isEmpty) {
      _showResultDialog(
        'API Key Missing',
        'Please enter and save your Todoist API key first.',
        isError: true,
      );
      return;
    }
    // Check if the dedicated service is configured (it should be if key is not empty)
    if (!todoistService.isConfigured) {
      _showResultDialog(
        'Service Not Configured',
        'Todoist service is not configured. Please save the key.',
        isError: true,
      );
      return;
    }

    setState(() => _isTestingTodoistConnection = true);

    try {
      // Use the checkHealth method of the TodoistApiService instance
      final isHealthy = await todoistService.checkHealth();
      if (mounted) {
        if (isHealthy) {
          _showResultDialog('Success', 'Todoist connection successful!');
        } else {
          _showResultDialog(
            'Connection Failed',
            'Could not connect to Todoist. Please verify your API key.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("[SettingsScreen] Test Todoist Connection Error: \$e");
      }
      if (mounted) {
        _showResultDialog(
          'Error',
          'An error occurred while testing the Todoist connection:\n${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingTodoistConnection = false);
    }
  }

  // Test OpenAI connection
  Future<void> _testOpenAiConnection() async {
    FocusScope.of(context).unfocus();
    final openaiService = ref.read(openaiApiServiceProvider);
    final currentKey = ref.read(openAiApiKeyProvider);

    if (currentKey.isEmpty) {
      _showResultDialog(
        'API Key Missing',
        'Please enter and save your OpenAI API key first.',
        isError: true,
      );
      return;
    }
    if (!openaiService.isConfigured) {
      _showResultDialog(
        'Service Not Configured',
        'OpenAI service is not configured. Please save the key.',
        isError: true,
      );
      return;
    }

    setState(() => _isTestingOpenAiConnection = true);

    try {
      final isHealthy = await openaiService.checkHealth();
      if (mounted) {
        if (isHealthy) {
          _showResultDialog('Success', 'OpenAI connection successful!');
        } else {
          _showResultDialog(
            'Connection Failed',
            'Could not connect to OpenAI. Please verify your API key.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("[SettingsScreen] Test OpenAI Connection Error: \$e");
      }
      if (mounted) {
        _showResultDialog(
          'Error',
          'An error occurred while testing the OpenAI connection:\n${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingOpenAiConnection = false);
    }
  }

  // Show actions for Memos/Blinko/Todoist servers
  void _showServerActions(
    BuildContext context,
    ServerConfig server,
    MultiServerConfigNotifier notifier,
    bool isActive,
    bool isDefault,
  ) {
    final bool isTodoist = server.serverType == ServerType.todoist;
    final String displayName =
        server.name ?? (isTodoist ? 'Todoist Config' : server.serverUrl);
    final String subtitle =
        isTodoist ? 'Todoist Integration' : server.serverUrl;

    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: Text(displayName),
            message: Text(subtitle, style: const TextStyle(fontSize: 13)),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                child: const Text('Edit'),
                onPressed: () {
                  Navigator.pop(context); // Close the action sheet
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder:
                          (context) =>
                              AddEditServerScreen(serverToEdit: server),
                    ),
                  );
                },
              ),
              if (!isActive)
                CupertinoActionSheetAction(
                  child: const Text('Set Active'),
                  onPressed: () {
                    notifier.setActiveServer(server.id);
                    Navigator.pop(context);
                  },
                ),
              // Default setting might be less relevant for Todoist, but keep for consistency?
              if (!isDefault)
                CupertinoActionSheetAction(
                  child: const Text('Set Default'),
                  onPressed: () {
                    notifier.setDefaultServer(server.id);
                    Navigator.pop(context);
                  },
                ),
              if (isDefault)
                CupertinoActionSheetAction(
                  child: const Text('Unset Default'),
                  onPressed: () {
                    notifier.setDefaultServer(null);
                    Navigator.pop(context);
                  },
                ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () async {
                  Navigator.pop(context); // Close action sheet
                  final confirmed = await showCupertinoDialog<bool>(
                    context: context,
                    builder:
                        (context) => CupertinoAlertDialog(
                          title: const Text('Delete Server?'),
                          content: Text(
                            'Are you sure you want to delete "$displayName"?',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('Delete'),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        ),
                  );
                  if (confirmed == true) {
                    // Use the correct notifier (multiServerConfigProvider)
                    final success = await ref
                        .read(multiServerConfigProvider.notifier)
                        .removeServer(server.id);
                    if (!success && mounted) {
                      _showResultDialog(
                        'Error',
                        'Failed to delete server.',
                        isError: true,
                      );
                    } else if (success && mounted) {
                      _showResultDialog(
                        'Deleted',
                        'Server "$displayName" deleted.',
                      );
                    }
                  }
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
    );
  }

  // Helper method to build MCP server list tiles
  List<Widget> _buildMcpServerListTiles(BuildContext context, WidgetRef ref) {
    // MODIFY: Watch the new provider
    final mcpServers = ref.watch(mcpServerConfigProvider);
    // Watch the MCP client state to get statuses and errors
    final mcpClientState = ref.watch(mcpClientProvider);
    final serverStatuses = mcpClientState.serverStatuses;
    final serverErrors = mcpClientState.serverErrorMessages;

    if (mcpServers.isEmpty) {
      return [
        const CupertinoListTile(
          title: Text('No MCP servers added yet'),
          subtitle: Text('Tap "+" in the navigation bar to add one'),
        ),
      ];
    }

    return mcpServers.map((server) {
      final status =
          serverStatuses[server.id] ?? McpConnectionStatus.disconnected;
      final error = serverErrors[server.id];
      final bool userWantsActive = server.isActive;

      // Build subtitle text including error message if present
      String subtitleText;
      subtitleText = '${server.host}:${server.port}'; // Always show host:port
      if (error != null && status == McpConnectionStatus.error) {
        // Limit error message length for display
        final displayError =
            error.length > 100 ? '${error.substring(0, 97)}...' : error;
        subtitleText += '\nError: $displayError';
      }

      return CupertinoListTile(
        leading: _buildMcpStatusIcon(status, context),
        title: Text(server.name),
        subtitle: Text(
          subtitleText,
          maxLines: error != null ? 3 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color:
                status == McpConnectionStatus.error
                    ? CupertinoColors.systemRed.resolveFrom(context)
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoSwitch(
              value: userWantsActive,
              onChanged: (bool value) {
                // MODIFY: Call the method on the new notifier
                ref
                    .read(mcpServerConfigProvider.notifier)
                    .toggleServerActive(server.id, value);
              },
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              child: const Icon(CupertinoIcons.ellipsis),
              onPressed: () => _showMcpServerActions(context, ref, server),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Helper to build status icon based on McpConnectionStatus
  Widget _buildMcpStatusIcon(McpConnectionStatus status, BuildContext context) {
    switch (status) {
      case McpConnectionStatus.connected:
        return const Icon(
          CupertinoIcons.check_mark_circled_solid,
          color: CupertinoColors.activeGreen,
          size: 22,
        );
      case McpConnectionStatus.connecting:
        return const CupertinoActivityIndicator(radius: 11);
      case McpConnectionStatus.error:
        return Icon(
          CupertinoIcons.xmark_octagon_fill,
          color: CupertinoColors.systemRed.resolveFrom(context),
          size: 22,
        );
      case McpConnectionStatus.disconnected:
        return Icon(
          CupertinoIcons.circle,
          color: CupertinoColors.inactiveGray.resolveFrom(context),
          size: 22,
        );
    }
  }

  // Method to show actions for an MCP server
  void _showMcpServerActions(
    BuildContext context,
    WidgetRef ref,
    McpServerConfig server,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: Text(server.name),
            // Update message based on connection type - ALWAYS SHOW HOST/PORT
            message: Text(
              '${server.host}:${server.port}',
              style: const TextStyle(fontSize: 13),
            ),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                child: const Text('Edit'),
                onPressed: () {
                  Navigator.pop(context); // Close the action sheet
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder:
                          (context) =>
                              AddEditMcpServerScreen(serverToEdit: server),
                    ),
                  );
                },
              ),
              // Add other actions if needed (e.g., Duplicate)
              CupertinoActionSheetAction(
                // Make Delete an action, not the cancel button
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () async {
                  Navigator.pop(context); // Close action sheet
                  final confirmed = await showCupertinoDialog<bool>(
                    context: context,
                    builder:
                        (context) => CupertinoAlertDialog(
                          title: const Text('Delete MCP Server?'),
                          content: Text(
                            'Are you sure you want to delete "${server.name}"?',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('Delete'),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        ),
                  );
                  if (confirmed == true) {
                    // MODIFY: Call removeServer on the new notifier
                    final success = await ref
                        .read(mcpServerConfigProvider.notifier)
                        .removeServer(server.id);
                    if (!success && mounted) {
                      _showResultDialog(
                        'Error',
                        'Failed to delete MCP server.',
                        isError: true,
                      );
                    } else if (success && mounted) {
                      _showResultDialog(
                        'Deleted',
                        'MCP Server "${server.name}" deleted.',
                      );
                    }
                  }
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              // Add a separate Cancel button
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
    );
  }

  // Method to show the model picker
  void _showModelPicker(BuildContext context) {
    final currentModel = ref.read(openAiModelIdProvider);
    int initialItem = _availableModels.indexOf(currentModel);
    if (initialItem < 0) initialItem = 0; // Default to first if not found

    String selectedValue =
        _availableModels.isNotEmpty ? _availableModels[initialItem] : '';

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: Container(
            height: 250,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemBackground
                        .resolveFrom(context),
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.0,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        child: const Text('Done'),
                        onPressed: () {
                          if (selectedValue.isNotEmpty &&
                              selectedValue != currentModel) {
                            ref
                                .read(openAiModelIdProvider.notifier)
                                .set(selectedValue);
                            if (kDebugMode) {
                              print('Selected OpenAI Model: $selectedValue');
                            }
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: initialItem,
                    ),
                    itemExtent: 32.0,
                    backgroundColor: CupertinoColors.systemBackground
                        .resolveFrom(context),
                    onSelectedItemChanged: (int index) {
                      selectedValue = _availableModels[index];
                    },
                    children:
                        _availableModels
                            .map(
                              (modelId) => Center(
                                child: Text(
                                  modelId,
                                  style:
                                      CupertinoTheme.of(
                                        context,
                                      ).textTheme.textStyle,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper to get appropriate icon for server type
  IconData _getServerIcon(ServerType type) {
    switch (type) {
      case ServerType.memos:
        return CupertinoIcons.bolt_horizontal_circle_fill;
      case ServerType.blinko:
        return CupertinoIcons.sparkles;
      case ServerType.todoist:
        return CupertinoIcons.check_mark_circled; // Example icon for Todoist
    }
  }

  // --- START: Added Reset Logic ---
  Future<void> _performFullReset() async {
    if (kDebugMode) {
      print('[SettingsScreen] Starting full data reset...');
    }
    if (!mounted) {
      if (kDebugMode) {
        print(
          '[SettingsScreen] Reset aborted: Widget unmounted before starting.',
        );
      }
      return;
    }
    final cloudKitService = ref.read(cloudKitServiceProvider);

    bool cloudSuccess = true;
    String cloudErrorMessage = '';

    // 1. Clear CloudKit Data
    try {
      if (kDebugMode) {
        print('[SettingsScreen] Deleting CloudKit ServerConfig records...');
      }
      bool deleteServersSuccess = await cloudKitService.deleteAllRecordsOfType(
        'ServerConfig',
      );
      if (!deleteServersSuccess) {
        cloudSuccess = false;
        cloudErrorMessage += 'Failed to delete ServerConfig records. ';
        if (kDebugMode) {
          print('[SettingsScreen] Failed CloudKit ServerConfig deletion.');
        }
      }

      if (kDebugMode) {
        print('[SettingsScreen] Deleting CloudKit McpServerConfig records...');
      }
      bool deleteMcpSuccess = await cloudKitService.deleteAllRecordsOfType(
        'McpServerConfig',
      );
      if (!deleteMcpSuccess) {
        cloudSuccess = false;
        cloudErrorMessage += 'Failed to delete McpServerConfig records. ';
        if (kDebugMode) {
          print('[SettingsScreen] Failed CloudKit McpServerConfig deletion.');
        }
      }

      if (kDebugMode) {
        print('[SettingsScreen] Deleting CloudKit UserSettings record...');
      }
      bool deleteSettingsSuccess =
          await cloudKitService.deleteUserSettingsRecord();
      if (!deleteSettingsSuccess) {
        cloudSuccess = false;
        cloudErrorMessage += 'Failed to delete UserSettings record. ';
        if (kDebugMode) {
          print('[SettingsScreen] Failed CloudKit UserSettings deletion.');
        }
      }

      if (!cloudSuccess) {
        if (kDebugMode) {
          print(
            '[SettingsScreen] CloudKit deletion finished with errors: $cloudErrorMessage',
          );
        }
      } else {
        if (kDebugMode) {
          print('[SettingsScreen] CloudKit deletion finished successfully.');
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[SettingsScreen] Critical error during CloudKit deletion phase: $e\n$s',
        );
      }
      cloudSuccess = false;
      cloudErrorMessage =
          'A critical error occurred during CloudKit deletion: $e';
    }

    // 2. Clear Local Notifiers and Cache
    final multiServerNotifier = ref.read(multiServerConfigProvider.notifier);
    final mcpServerNotifier = ref.read(mcpServerConfigProvider.notifier);
    final todoistNotifier = ref.read(todoistApiKeyProvider.notifier);
    final openAiKeyNotifier = ref.read(openAiApiKeyProvider.notifier);
    final openAiModelNotifier = ref.read(openAiModelIdProvider.notifier);
    final geminiNotifier = ref.read(geminiApiKeyProvider.notifier);
    final workbenchNotifier = ref.read(workbenchProvider.notifier);
    final tasksNotifier = ref.read(tasksNotifierProvider.notifier);
    final chatNotifier = ref.read(chatProvider.notifier);
    // Consider if notes cache needs explicit clearing or if config reset handles it
    // final notesNotifier = ref.read(note_providers.notesNotifierProvider.notifier);

    try {
      if (kDebugMode) {
        print('[SettingsScreen] Resetting local notifiers and cache...');
      }
      // Reset Configs & Keys
      await multiServerNotifier.resetStateAndCache();
      await mcpServerNotifier.resetStateAndCache();
      await todoistNotifier.clear();
      await openAiKeyNotifier.clear();
      await openAiModelNotifier.clear();
      await geminiNotifier.clear();

      // Clear Data Caches
      await workbenchNotifier
          .clearAllItems(); // Assuming this method exists or is added
      tasksNotifier.clearTasks(); // Clear local task list
      chatNotifier.clearChat(); // Clear chat history
      // await notesNotifier.clearCache(); // If an explicit cache clear is needed

      if (kDebugMode) {
        print('[SettingsScreen] Local reset finished.');
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[SettingsScreen] Error during local notifier reset phase: $e\n$s',
        );
      }
      if (cloudErrorMessage.isNotEmpty) {
        cloudErrorMessage +=
            '\nAn error also occurred during local data reset.';
      } else {
        cloudErrorMessage = 'An error occurred during local data reset.';
        cloudSuccess = false; // Mark as failed if local reset fails
      }
    }

    // 3. Show Final Result Dialog
    if (mounted) {
      _showResultDialog(
        cloudSuccess ? 'Reset Complete' : 'Reset Partially Failed',
        cloudSuccess
            ? 'All cloud configurations, local settings, API keys, and cached data have been cleared. Please restart the app or reconfigure servers.'
            : 'The reset process encountered errors:\n$cloudErrorMessage\nSome data might remain. Please check iCloud data manually (Settings > Apple ID > iCloud > Manage Account Storage) and restart the app.',
        isError: !cloudSuccess,
      );
      // Invalidate providers to force reload/re-check after reset
      ref.invalidate(loadServerConfigProvider);
      ref.invalidate(loadMcpServerConfigProvider);
      ref.invalidate(note_providers.notesNotifierProvider);
      ref.invalidate(tasksNotifierProvider);
      ref.invalidate(workbenchProvider);
      ref.invalidate(chatProvider);
      // Potentially navigate away or prompt for restart
    } else {
      if (kDebugMode) {
        print(
          '[SettingsScreen] Widget unmounted before final reset dialog could be shown.',
        );
      }
    }
  }
  // --- END: Added Reset Logic ---

  @override
  Widget build(BuildContext context) {
    final multiServerState = ref.watch(multiServerConfigProvider);
    final servers = multiServerState.servers;
    final activeServerId = multiServerState.activeServerId;
    final defaultServerId = multiServerState.defaultServerId;
    final notifier = ref.read(multiServerConfigProvider.notifier);

    // Get active config to check its type for the test button
    final activeConfig = ref.watch(activeServerConfigProvider);
    final bool isTodoistActive = activeConfig?.serverType == ServerType.todoist;

    final bool automaticallyImplyLeading = !widget.isInitialSetup;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.isInitialSetup ? 'Server Setup' : 'Settings'),
          automaticallyImplyLeading: automaticallyImplyLeading,
          transitionBetweenRoutes: false,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Button to add Memos/Blinko/Todoist server
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const AddEditServerScreen(),
                    ),
                  );
                },
                child: const Icon(
                  CupertinoIcons.add,
                ),
              ),
              const SizedBox(width: 8),
              // Button to add MCP server
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const AddEditMcpServerScreen(),
                    ),
                  );
                },
                child: const Icon(CupertinoIcons.gear_alt_fill, size: 24),
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(top: 16.0),
            children: [
              // Initial setup prompt
              if (widget.isInitialSetup)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: CupertinoColors.systemBlue.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          color: CupertinoColors.systemBlue,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please add your Memos/Blinko/Todoist server details to get started.',
                            style: TextStyle(color: CupertinoColors.systemBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Server List Section (Memos/Blinko/Todoist)
              CupertinoListSection.insetGrouped(
                header: const Text(
                  'SERVERS (Memos, Blinko, Todoist)',
                ),
                footer:
                    servers.isEmpty
                        ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.0),
                          child: Text(
                            'No servers configured. Tap the "+" button to add one.',
                          ),
                        )
                        : null,
                children: [
                  if (servers.isEmpty && !widget.isInitialSetup)
                    const CupertinoListTile(
                      title: Text('No servers added yet'),
                      subtitle: Text('Tap "+" to add a server'),
                    ),
                  ...servers.map((server) {
                    final bool isActive = server.id == activeServerId;
                    final bool isDefault = server.id == defaultServerId;
                    final bool isTodoist =
                        server.serverType == ServerType.todoist;
                    final String displayName =
                        server.name ??
                        (isTodoist ? 'Todoist Config' : server.serverUrl);
                    final String subtitle =
                        isTodoist
                            ? 'Todoist Integration'
                            : (server.name != null
                                ? server.serverUrl
                                : 'No name');

                    return CupertinoListTile(
                      title: Text(displayName),
                      subtitle: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                      leading: Icon(
                        isActive
                            ? CupertinoIcons.check_mark_circled_solid
                            : CupertinoIcons.circle,
                        color:
                            isActive
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.inactiveGray,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              _getServerIcon(server.serverType),
                              size: 18,
                              color: CupertinoColors.tertiaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                          if (isDefault)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(
                                CupertinoIcons.star_fill,
                                size: 16,
                                color: CupertinoColors.systemYellow,
                              ),
                            ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 0,
                            child: const Icon(CupertinoIcons.ellipsis),
                            onPressed:
                                () => _showServerActions(
                                  context,
                                  server,
                                  notifier,
                                  isActive,
                                  isDefault,
                                ),
                          ),
                        ],
                      ),
                      onTap: () {
                        if (!isActive) notifier.setActiveServer(server.id);
                      },
                    );
                  }),
                ],
              ),
              // Test Active Connection Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed:
                      _isTestingConnection ||
                              activeServerId == null ||
                              isTodoistActive
                          ? null
                          : _testConnection,
                  child:
                      _isTestingConnection
                          ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isTodoistActive
                                    ? CupertinoIcons.nosign
                                    : CupertinoIcons.link,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isTodoistActive
                                    ? 'Test Todoist via Integrations'
                                    : 'Test Active Connection',
                              ),
                            ],
                          ),
                ),
              ),
              // --- Integrations Section ---
              CupertinoListSection.insetGrouped(
                header: const Text('INTEGRATIONS'),
                children: [
                  // Todoist Integration Tile
                  CupertinoListTile(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15.0,
                      vertical: 10.0,
                    ),
                    title: const Text('Todoist API Key'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              controller: _todoistApiKeyController,
                              placeholder: 'Enter Todoist API token',
                              obscureText: true,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 12.0,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.tertiarySystemFill
                                    .resolveFrom(context),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              clearButtonMode: OverlayVisibilityMode.editing,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: CupertinoColors.activeBlue,
                            onPressed: () async {
                              // Make async
                              final newKey =
                                  _todoistApiKeyController.text.trim();
                              // Save the key globally using the settings provider
                              final success = await ref
                                  .read(todoistApiKeyProvider.notifier)
                                  .set(newKey);

                              FocusScope.of(context).unfocus();

                              if (success) {
                                // --- START REMOVAL ---
                                // Removed ServerConfig update logic
                                // --- END REMOVAL ---
                                _showResultDialog(
                                  'API Key Updated',
                                  'Todoist API key has been saved.',
                                );
                                // Trigger health check after saving
                                ref.read(todoistApiHealthCheckerProvider);
                              } else {
                                _showResultDialog(
                                  'Error',
                                  'Failed to save Todoist API key.',
                                  isError: true,
                                );
                              }
                            },
                            child: const Text(
                              'Save',
                              style: TextStyle(color: CupertinoColors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Test Todoist Connection Tile
                  CupertinoListTile(
                    title: Center(
                      child: CupertinoButton(
                        onPressed:
                            _isTestingTodoistConnection
                                ? null
                                : _testTodoistConnection,
                        child:
                            _isTestingTodoistConnection
                                ? const CupertinoActivityIndicator()
                                : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.link),
                                    SizedBox(width: 8),
                                    Text('Test Todoist Connection'),
                                  ],
                                ),
                      ),
                    ),
                  ),
                  // OpenAI Integration Tile
                  CupertinoListTile(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15.0,
                      vertical: 10.0,
                    ),
                    title: const Text('OpenAI API Key'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              controller: _openaiApiKeyController,
                              placeholder: 'Enter OpenAI API key (sk-...)',
                              obscureText: true,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 12.0,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.tertiarySystemFill
                                    .resolveFrom(context),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              clearButtonMode: OverlayVisibilityMode.editing,
                              onSubmitted: (_) => _fetchModels(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: CupertinoColors.activeBlue,
                            onPressed: () async {
                              final newKey = _openaiApiKeyController.text;
                              final success = await ref
                                  .read(openAiApiKeyProvider.notifier)
                                  .set(newKey);
                              FocusScope.of(context).unfocus();
                              if (success) {
                                _showResultDialog(
                                  'API Key Updated',
                                  'OpenAI API key has been saved.',
                                );
                                _fetchModels(); // Fetch models after saving key
                                // Trigger health check
                                ref.read(openaiApiHealthCheckerProvider);
                              } else {
                                _showResultDialog(
                                  'Error',
                                  'Failed to save OpenAI API key.',
                                  isError: true,
                                );
                              }
                            },
                            child: const Text(
                              'Save',
                              style: TextStyle(color: CupertinoColors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Test OpenAI Connection Tile
                  CupertinoListTile(
                    title: Center(
                      child: CupertinoButton(
                        onPressed:
                            _isTestingOpenAiConnection
                                ? null
                                : _testOpenAiConnection,
                        child:
                            _isTestingOpenAiConnection
                                ? const CupertinoActivityIndicator()
                                : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.link),
                                    SizedBox(width: 8),
                                    Text('Test OpenAI Connection'),
                                  ],
                                ),
                      ),
                    ),
                  ),
                  // OpenAI Model Selection Tile
                  CupertinoListTile(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15.0,
                      vertical: 10.0,
                    ),
                    title: const Text('OpenAI Model (Grammar Fix)'),
                    additionalInfo:
                        _isLoadingModels
                            ? const CupertinoActivityIndicator(radius: 10)
                            : (_modelLoadError != null ||
                                _availableModels.isEmpty)
                            ? CupertinoButton(
                              padding: EdgeInsets.zero,
                              minSize: 0,
                              onPressed: _fetchModels,
                              child: const Icon(
                                CupertinoIcons.refresh,
                                color: CupertinoColors.systemRed,
                                size: 20,
                              ),
                            )
                            : null,
                    trailing: const CupertinoListTileChevron(),
                    subtitle: Text(
                      _isLoadingModels
                          ? 'Loading models...'
                          : _modelLoadError != null
                          ? _modelLoadError!
                          : ref.watch(openAiModelIdProvider).isNotEmpty
                          ? ref.watch(openAiModelIdProvider)
                          : 'Select Model',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            _modelLoadError != null
                                ? CupertinoColors.systemRed.resolveFrom(context)
                                : CupertinoColors.secondaryLabel.resolveFrom(
                                  context,
                                ),
                      ),
                    ),
                    onTap:
                        _isLoadingModels || _availableModels.isEmpty
                            ? null
                            : () => _showModelPicker(context),
                  ),
                  // --- Start Gemini ---
                  CupertinoListTile(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15.0,
                      vertical: 10.0,
                    ),
                    title: const Text('Gemini API Key'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              controller: _geminiApiKeyController,
                              placeholder: 'Enter Gemini API key',
                              obscureText: true,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 12.0,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.tertiarySystemFill
                                    .resolveFrom(context),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              clearButtonMode: OverlayVisibilityMode.editing,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: CupertinoColors.activeBlue,
                            onPressed: () async {
                              final newKey =
                                  _geminiApiKeyController.text.trim();
                              if (newKey.isEmpty) {
                                _showResultDialog(
                                  'Error',
                                  'Gemini API Key cannot be empty.',
                                  isError: true,
                                );
                                return;
                              }
                              final success = await ref
                                  .read(geminiApiKeyProvider.notifier)
                                  .set(newKey);
                              FocusScope.of(context).unfocus();
                              if (success) {
                                _showResultDialog(
                                  'API Key Updated',
                                  'Gemini API key has been saved.',
                                );
                                // TODO: Add Gemini health check trigger if implemented
                              } else {
                                _showResultDialog(
                                  'Error',
                                  'Failed to save Gemini API key.',
                                  isError: true,
                                );
                              }
                            },
                            child: const Text(
                              'Save',
                              style: TextStyle(color: CupertinoColors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // --- End Gemini ---
                ],
              ),
              // --- MCP Server Section ---
              CupertinoListSection.insetGrouped(
                header: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('MCP SERVERS'),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      onPressed: () {
                        // Trigger syncConnections from the MCP client notifier
                        ref.read(mcpClientProvider.notifier).syncConnections();
                        _showResultDialog(
                          'Applying Changes',
                          'Attempting to connect/disconnect MCP servers based on toggles.',
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            'Apply Changes',
                            style:
                                CupertinoTheme.of(
                                  context,
                                ).textTheme.actionTextStyle,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.refresh_circled,
                            size: 18,
                            color:
                                CupertinoTheme.of(
                                  context,
                                ).textTheme.actionTextStyle.color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                footer: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    'Toggle servers to connect and press "Apply Changes". Use "..." for more options.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                children: _buildMcpServerListTiles(context, ref),
              ),
              // --- End MCP Server Section ---
              // Help Text Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemGroupedBackground
                        .resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(CupertinoIcons.info_circle, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Server Management',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap a server to make it active.\nUse "..." to Edit, Delete, or set a Default server.\n\nFor Memos/Blinko, the authentication token (Access Token) is under Settings > My Account on your server.\n\nFor Todoist, add a server entry and use your Todoist API Key (found in Todoist Settings > Integrations > Developer).',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(CupertinoIcons.info_circle, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Integrations',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'API keys for integrations like Todoist, OpenAI, and Gemini are stored locally on your device. The Todoist key entered here is used for the integration.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              // --- DANGER ZONE Section ---
              CupertinoListSection.insetGrouped(
                header: const Text('DANGER ZONE'),
                children: [
                  CupertinoListTile(
                    title: Text(
                      'Reset All Cloud & Local Data',
                      style: TextStyle(
                        color: CupertinoColors.systemRed.resolveFrom(context),
                      ),
                    ),
                    leading: Icon(
                      CupertinoIcons.exclamationmark_octagon_fill,
                      color: CupertinoColors.systemRed.resolveFrom(context),
                    ),
                    onTap: () async {
                      final confirmed = await showCupertinoDialog<bool>(
                        context: context,
                        builder:
                            (dialogContext) => CupertinoAlertDialog(
                              title: const Text('Confirm Reset'),
                              content: const Text(
                                'This will permanently delete ALL server configurations (Memos, Blinko, Todoist, MCP), API keys (Todoist, OpenAI, Gemini), cached data (notes, tasks, workbench items, chat history), and local settings from this device AND from your iCloud account.\n\nThis action cannot be undone. Are you absolutely sure?',
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('Cancel'),
                                  onPressed:
                                      () => Navigator.pop(dialogContext, false),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  child: const Text('Reset Everything'),
                                  onPressed:
                                      () => Navigator.pop(dialogContext, true),
                                ),
                              ],
                            ),
                      );

                      if (confirmed == true && mounted) {
                        // --- Execute Reset Logic ---
                        await _performFullReset();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32), // Add space at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
