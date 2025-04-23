import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
// Import MCP related files
import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/chat_providers.dart';
// ADD: Import the new MCP config provider
import 'package:flutter_memos/providers/mcp_server_config_provider.dart';
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
// Import new single-config providers
import 'package:flutter_memos/providers/note_server_config_provider.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // Import settings provider
import 'package:flutter_memos/providers/shared_prefs_provider.dart';
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_memos/providers/task_server_config_provider.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart'; // Add import for workbench instances
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/add_edit_mcp_server_screen.dart'; // Will be created next
import 'package:flutter_memos/screens/add_edit_server_screen.dart';
import 'package:flutter_memos/services/auth_strategy.dart'; // Import for BearerTokenAuthStrategy
import 'package:flutter_memos/services/base_api_service.dart'; // Import BaseApiService
import 'package:flutter_memos/services/blinko_api_service.dart';
// Removed CloudKitService import
// Import MCP client provider (for status later) - add "as mcp_service" to solve ambiguity
import 'package:flutter_memos/services/mcp_client_service.dart' as mcp_service;
// Import specific API services for testing
import 'package:flutter_memos/services/memos_api_service.dart';
import 'package:flutter_memos/services/supabase_data_service.dart'; // Import SupabaseDataService
import 'package:flutter_memos/services/vikunja_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase client for reset

class SettingsScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;
  const SettingsScreen({super.key, this.isInitialSetup = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // State for testing connections
  bool _isTestingNoteConnection = false;
  bool _isTestingTaskConnection = false;

  // OpenAI state
  final _openaiApiKeyController = TextEditingController();
  bool _isTestingOpenAiConnection = false;
  bool _isLoadingModels = false;
  List<String> _availableModels = [];
  String? _modelLoadError;

  // Gemini state
  final _geminiApiKeyController = TextEditingController();

  // REMOVED Vikunja state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final initialOpenAiKey = ref.read(openAiApiKeyProvider);
        _openaiApiKeyController.text = initialOpenAiKey;
        final initialGeminiKey = ref.read(geminiApiKeyProvider);
        _geminiApiKeyController.text = initialGeminiKey;
        // REMOVED Vikunja key init
      }
      _fetchModels();
    });
  }

  @override
  void dispose() {
    _openaiApiKeyController.dispose();
    _geminiApiKeyController.dispose();
    // REMOVED Vikunja controller dispose
    super.dispose();
  }

  Future<void> _fetchModels() async {
    if (!mounted) return;
    setState(() {
      _isLoadingModels = true;
      _modelLoadError = null;
      _availableModels = [];
    });

    final openaiService = ref.read(openaiApiServiceProvider);
    final apiKey = ref.read(openAiApiKeyProvider);

    if (apiKey.isEmpty) {
      setState(() {
        _isLoadingModels = false;
        _modelLoadError = 'OpenAI API Key not configured.';
      });
      return;
    }
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
    // No async gap here, so context usage is safe
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

  // Generic connection test function
  Future<void> _testServerConnection(ServerConfig? config, ServerPurpose purpose) async {
     if (config == null) {
       _showResultDialog(
         'No Server Configured',
         'Please configure a ${purpose.name} server first.',
         isError: true,
       );
       return;
     }

    // Use local variable for mounted check after await
    final isMounted = mounted;
     setState(() {
      if (purpose == ServerPurpose.note) {
        _isTestingNoteConnection = true;
      } else {
        _isTestingTaskConnection = true;
      }
     });

     // Instantiate the correct service based on ServerType
     BaseApiService testApiService;
    AuthStrategy authStrategy = BearerTokenAuthStrategy(
      config.authToken,
    ); // Default

     switch (config.serverType) {
       case ServerType.memos:
         testApiService = MemosApiService();
         break;
       case ServerType.blinko:
         testApiService = BlinkoApiService();
         break;
       case ServerType.vikunja:
         testApiService = VikunjaApiService();
        // Vikunja uses Bearer token auth, already covered by default
        // REMOVED check for legacy key
        if (purpose == ServerPurpose.task && config.authToken.isEmpty) {
          if (isMounted) {
            _showResultDialog(
              'Configuration Error',
              'Vikunja task server requires an API Key (Token) in its configuration.',
              isError: true,
            );
            setState(() {
              _isTestingTaskConnection = false;
            });
          }
            return;
         }
         break;
       case ServerType.todoist: // Should not happen
        if (isMounted) {
          _showResultDialog(
            'Internal Error',
            'Cannot test Todoist type.',
            isError: true,
          );
          setState(() {
            if (purpose == ServerPurpose.note) {
              _isTestingNoteConnection = false;
            } else {
              _isTestingTaskConnection = false;
            }
          });
        }
         return;
     }

     try {
       // Configure the service with the specific server's details
      // Use configureService with authStrategy
      await testApiService.configureService(
        baseUrl: config.serverUrl,
        authStrategy: authStrategy,
      );
       final isHealthy = await testApiService.checkHealth();

      // Check mounted *after* await
      if (!mounted) return;

      if (isHealthy) {
        _showResultDialog(
          'Success',
          'Connection to ${purpose.name} server "${config.name ?? config.serverUrl}" successful!',
        );
        // REMOVED direct setting of isVikunjaConfiguredProvider
      } else {
        _showResultDialog(
          'Connection Failed',
          'Could not connect to ${purpose.name} server "${config.name ?? config.serverUrl}". Check configuration.',
          isError: true,
        );
      }
     } catch (e) {
       if (kDebugMode) print("[SettingsScreen] Test ${purpose.name} Connection Error: $e");
      // Check mounted *after* await
      if (!mounted) return;
      _showResultDialog(
        'Connection Failed',
        'Could not connect to ${purpose.name} server "${config.name ?? config.serverUrl}".\n\nError: ${e.toString()}',
        isError: true,
      );
     } finally {
      // Check mounted *after* await
      if (mounted) {
        // Check mounted before calling setState
        setState(() {
          if (purpose == ServerPurpose.note) {
            _isTestingNoteConnection = false;
          } else {
            _isTestingTaskConnection = false;
          }
        });
      }
    }
  }


  Future<void> _testOpenAiConnection() async {
    FocusScope.of(context).unfocus();
    final openaiService = ref.read(openaiApiServiceProvider);
    final currentKey = ref.read(openAiApiKeyProvider);

    if (currentKey.isEmpty) {
      _showResultDialog('API Key Missing', 'Please enter and save your OpenAI API key first.', isError: true);
      return;
    }
    openaiService.configureService(authToken: currentKey);
    if (!openaiService.isConfigured) {
      _showResultDialog('Service Not Configured', 'OpenAI service is not configured. Please save the key.', isError: true);
      return;
    }

    // Use local variable for mounted check after await
    final isMounted = mounted;
    setState(() => _isTestingOpenAiConnection = true);
    try {
      final isHealthy = await openaiService.checkHealth();
      // Check mounted *after* await
      if (!isMounted) return;
      if (isHealthy) {
        _showResultDialog('Success', 'OpenAI connection successful!');
      } else {
        _showResultDialog(
          'Connection Failed',
          'Could not connect to OpenAI. Please verify your API key.',
          isError: true,
        );
      }
    } catch (e) {
      if (kDebugMode) print("[SettingsScreen] Test OpenAI Connection Error: $e");
      // Check mounted *after* await
      if (!isMounted) return;
      _showResultDialog(
        'Error',
        'An error occurred while testing the OpenAI connection:\n${e.toString()}',
        isError: true,
      );
    } finally {
      // Check mounted *after* await
      if (mounted) {
        // Check mounted before calling setState
        setState(() => _isTestingOpenAiConnection = false);
      }
    }
  }

  // --- Removed _showServerActions (replaced by Edit/Delete buttons per config) ---

  // Helper method to build MCP server list tiles (Unchanged from original, seems fine)
  List<Widget> _buildMcpServerListTiles(BuildContext context, WidgetRef ref) {
    final mcpServers = ref.watch(mcpServerConfigProvider);
    final mcpClientState = ref.watch(mcp_service.mcpClientProvider);
    final serverStatuses = mcpClientState.serverStatuses;
    final serverErrors = mcpClientState.serverErrorMessages;

    if (mcpServers.isEmpty) {
      return [
        const CupertinoListTile(
          title: Text('No MCP servers added yet'),
          subtitle: Text('Tap the gear icon in the navigation bar to add one'),
        ),
      ];
    }

    return mcpServers.map((server) {
      final status = serverStatuses[server.id] ?? mcp_service.McpConnectionStatus.disconnected;
      final error = serverErrors[server.id];
      final bool userWantsActive = server.isActive; // This 'isActive' is for connection management

      String subtitleText = '${server.host}:${server.port}';
      if (error != null && status == mcp_service.McpConnectionStatus.error) {
        final displayError = error.length > 100 ? '${error.substring(0, 97)}...' : error;
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
            color: status == mcp_service.McpConnectionStatus.error
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
                ref.read(mcpServerConfigProvider.notifier).toggleServerActive(server.id, value);
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

  Widget _buildMcpStatusIcon(mcp_service.McpConnectionStatus status, BuildContext context) {
     switch (status) {
       case mcp_service.McpConnectionStatus.connected:
         return const Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.activeGreen, size: 22);
       case mcp_service.McpConnectionStatus.connecting:
         return const CupertinoActivityIndicator(radius: 11);
       case mcp_service.McpConnectionStatus.error:
         return Icon(CupertinoIcons.xmark_octagon_fill, color: CupertinoColors.systemRed.resolveFrom(context), size: 22);
       case mcp_service.McpConnectionStatus.disconnected:
         return Icon(CupertinoIcons.circle, color: CupertinoColors.inactiveGray.resolveFrom(context), size: 22);
     }
   }

  void _showMcpServerActions(BuildContext context, WidgetRef ref, McpServerConfig server) {
     showCupertinoModalPopup<void>(
       context: context,
       builder: (BuildContext context) => CupertinoActionSheet(
         title: Text(server.name),
         message: Text('${server.host}:${server.port}', style: const TextStyle(fontSize: 13)),
         actions: <CupertinoActionSheetAction>[
           CupertinoActionSheetAction(
             child: const Text('Edit'),
             onPressed: () {
               Navigator.pop(context);
               Navigator.of(context).push(
                 CupertinoPageRoute(builder: (context) => AddEditMcpServerScreen(serverToEdit: server)),
               );
             },
           ),
           CupertinoActionSheetAction(
             isDestructiveAction: true,
             child: const Text('Delete'),
             onPressed: () async {
                  Navigator.pop(context); // Close sheet before showing dialog
                  final isMounted = mounted; // Check mounted before await
               final confirmed = await showCupertinoDialog<bool>(
                 context: context,
                 builder: (context) => CupertinoAlertDialog(
                   title: const Text('Delete MCP Server?'),
                   content: Text('Are you sure you want to delete "${server.name}"?'),
                   actions: [
                     CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
                     CupertinoDialogAction(isDestructiveAction: true, child: const Text('Delete'), onPressed: () => Navigator.of(context).pop(true)),
                   ],
                 ),
               );
                  // Check mounted *after* await
                  if (!isMounted) return;
               if (confirmed == true) {
                 final success = await ref.read(mcpServerConfigProvider.notifier).removeServer(server.id);
                    // Check mounted again before showing result dialog
                    if (!mounted) return;
                    if (!success) {
                   _showResultDialog('Error', 'Failed to delete MCP server.', isError: true);
                    } else {
                   _showResultDialog('Deleted', 'MCP Server "${server.name}" deleted.');
                 }
               }
             },
           ),
         ],
         cancelButton: CupertinoActionSheetAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
       ),
     );
   }

  void _showModelPicker(BuildContext context) {
    final currentModel = ref.read(openAiModelIdProvider);
    int initialItem = _availableModels.indexOf(currentModel);
    if (initialItem < 0) initialItem = 0;
    String selectedValue = _availableModels.isNotEmpty ? _availableModels[initialItem] : '';

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
                    color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
                    border: Border(bottom: BorderSide(color: CupertinoColors.separator.resolveFrom(context), width: 0.0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: const Text('Done'),
                        onPressed: () {
                          if (selectedValue.isNotEmpty && selectedValue != currentModel) {
                            ref.read(openAiModelIdProvider.notifier).set(selectedValue);
                            if (kDebugMode) print('Selected OpenAI Model: $selectedValue');
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: initialItem),
                    itemExtent: 32.0,
                    backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
                    onSelectedItemChanged: (int index) {
                      selectedValue = _availableModels[index];
                    },
                    children: _availableModels.map((modelId) {
                      return Center(child: Text(modelId, style: CupertinoTheme.of(context).textTheme.textStyle));
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getServerIcon(ServerType type) {
    switch (type) {
      case ServerType.memos: return CupertinoIcons.bolt_horizontal_circle_fill;
      case ServerType.blinko: return CupertinoIcons.sparkles;
      case ServerType.vikunja: return CupertinoIcons.list_bullet;
      case ServerType.todoist: return CupertinoIcons.check_mark_circled; // Should not appear
    }
  }

  // --- START: Updated Reset Logic ---
  Future<void> _performFullReset() async {
    if (kDebugMode) print('[SettingsScreen] Starting full data reset...');
    // Check mounted at the beginning
    if (!mounted) return;

    // Removed CloudKitService instance
    bool cloudSuccess = true; // Assume success unless Supabase fails
    String cloudErrorMessage = '';

    // Get current workbench instance IDs before clearing
    final instanceIdsToClear = ref.read(workbenchInstancesProvider).instances.map((i) => i.id).toList();

    // 1. Clear Supabase Data (Optional - uncomment and adapt if needed)
    try {
      final supabase = Supabase.instance.client;
      // Removed unused supabaseDataService variable
      // final supabaseDataService = ref.read(supabaseDataServiceProvider);

      if (kDebugMode) print('[SettingsScreen] Deleting Supabase data...');

      // Example: Clear chat sessions using SupabaseDataService method
      // This assumes you have a method like deleteAllChatSessions or similar
      // bool deleteChatsSuccess = await supabaseDataService.deleteAllChatSessions();
      // Or delete directly:
      await supabase
          .from(SupabaseDataService.chatSessionsTable)
          .delete()
          .neq('id', '0'); // Delete all rows

      // Add similar deletions for other tables if they exist in Supabase
      // await supabase.from('server_configs').delete().neq('id', '0');
      // await supabase.from('mcp_server_configs').delete().neq('id', '0');
      // await supabase.from('user_settings').delete().neq('id', '0'); // Assuming a single row or user-specific filter
      // await supabase.from('workbench_instances').delete().neq('id', '0');
      // await supabase.from('workbench_items').delete().neq('id', '0');

      // cloudSuccess = deleteChatsSuccess && ... ; // Combine results if needed

      if (kDebugMode) {
        print('[SettingsScreen] Supabase deletion attempt finished.');
      }

    } catch (e, s) {
      if (kDebugMode)
        print('[SettingsScreen] Error during Supabase deletion phase: $e\n$s');
      cloudSuccess = false; // Mark as failed if Supabase deletion has errors
      cloudErrorMessage = 'An error occurred during Supabase data deletion: $e';
    }

    // 2. Clear Local Notifiers and Cache (Keep this part)
    final noteServerNotifier = ref.read(noteServerConfigProvider.notifier);
    final taskServerNotifier = ref.read(taskServerConfigProvider.notifier);
    final mcpServerNotifier = ref.read(mcpServerConfigProvider.notifier);
    final openAiKeyNotifier = ref.read(openAiApiKeyProvider.notifier);
    final openAiModelNotifier = ref.read(openAiModelIdProvider.notifier);
    final geminiNotifier = ref.read(geminiApiKeyProvider.notifier);
    // REMOVED Vikunja Key Notifier
    // Removed unused workbenchInstancesNotifier variable
    // final workbenchInstancesNotifier = ref.read(workbenchInstancesProvider.notifier);
    final tasksNotifier = ref.read(tasksNotifierProvider.notifier);
    final chatNotifier = ref.read(chatProvider.notifier);
    final sharedPrefsService = await ref.read(sharedPrefsServiceProvider.future);

    try {
      if (kDebugMode) print('[SettingsScreen] Resetting local notifiers and cache...');
      // Reset Configs & Keys
      await noteServerNotifier.resetStateAndCache();
      await taskServerNotifier.resetStateAndCache();
      await mcpServerNotifier.resetStateAndCache();
      await openAiKeyNotifier.clear();
      await openAiModelNotifier.clear();
      await geminiNotifier.clear();
      // REMOVED Vikunja Key Clear

      // Clear Data Caches / Local State
      // Invalidate workbench providers (they load from prefs now)
      for (final instanceId in instanceIdsToClear) {
        ref.invalidate(workbenchProviderFamily(instanceId));
        // Also clear the prefs file for each instance's items
        // Use the correct method name from SharedPrefsService
        await sharedPrefsService.remove('workbench_items_$instanceId');
      }
      // Reset and reload instances (will load default from prefs)
      ref.invalidate(workbenchInstancesProvider);
      // Removed call to loadInstances, invalidation handles reload
      // await ref.read(workbenchInstancesProvider.notifier).loadInstances();


      tasksNotifier.clearTasks(); // Clear in-memory task state
      await chatNotifier.clearChat(); // Clears local state and Supabase entry

      // Clear remaining shared prefs (like last opened items, instance list)
      // Use the correct method name from SharedPrefsService
      await sharedPrefsService
          .clearAllWorkbenchData(); // Use specific clear method if available

      // REMOVED direct setting of isVikunjaConfiguredProvider

      if (kDebugMode) print('[SettingsScreen] Local reset finished.');
    } catch (e, s) {
      if (kDebugMode) print('[SettingsScreen] Error during local notifier reset phase: $e\n$s');
      cloudErrorMessage = cloudErrorMessage.isNotEmpty
          ? '$cloudErrorMessage\nAn error also occurred during local data reset.'
          : 'An error occurred during local data reset.';
      cloudSuccess = false; // Mark as failed if local reset has errors
    }

    // 3. Show Final Result Dialog - Check mounted *after* all awaits
    if (!mounted) {
      if (kDebugMode) {
        print(
          '[SettingsScreen] Widget unmounted before final reset dialog could be shown.',
        );
      }
      return;
    }
    _showResultDialog(
      cloudSuccess ? 'Reset Complete' : 'Reset Partially Failed',
      cloudSuccess
          ? 'All local configurations, settings, API keys, and cached data have been cleared. Supabase data deletion attempted. Please restart the app or reconfigure servers.'
          : 'The reset process encountered errors:\n$cloudErrorMessage\nSome data might remain. Please check Supabase data manually and restart the app.',
      isError: !cloudSuccess,
    );
    // Invalidate providers to force reload on next access
    ref.invalidate(noteServerConfigProvider);
    ref.invalidate(taskServerConfigProvider);
    ref.invalidate(mcpServerConfigProvider);
    ref.invalidate(workbenchInstancesProvider);
    // Invalidate note/task data providers (if they exist and depend on the config)
    ref.invalidate(
      note_providers.notesNotifierProvider,
    ); // Use non-family provider
    ref.invalidate(tasksNotifierProvider);
    ref.invalidate(chatProvider);
    // Invalidate API key providers
    ref.invalidate(openAiApiKeyProvider);
    ref.invalidate(openAiModelIdProvider);
    ref.invalidate(geminiApiKeyProvider);
    // REMOVED Vikunja Key Invalidation
    // Invalidate API service providers
    ref.invalidate(noteApiServiceProvider); // Use new provider name
    ref.invalidate(taskApiServiceProvider); // Use new provider name
    ref.invalidate(openaiApiServiceProvider);
    ref.invalidate(
      vikunjaApiServiceProvider,
    ); // Keep this if VikunjaApiService is still used directly elsewhere

  }
  // --- END: Updated Reset Logic ---

  // Helper to build the configuration tile for Note or Task server
  Widget _buildServerConfigTile(ServerConfig? config, ServerPurpose purpose) {
    // final String title = purpose == ServerPurpose.note ? 'Note Server' : 'Task Server'; // Unused variable
    final String addText = 'Tap to Add ${purpose.name.substring(0,1).toUpperCase()}${purpose.name.substring(1)} Server';
    // Explicitly type the notifier based on purpose
    final StateNotifier<ServerConfig?> notifier =
        purpose == ServerPurpose.note
        ? ref.read(noteServerConfigProvider.notifier)
        : ref.read(taskServerConfigProvider.notifier);

    if (config == null) {
      return CupertinoListTile(
        title: Text(addText),
        leading: const Icon(CupertinoIcons.add_circled),
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(builder: (context) => AddEditServerScreen(purpose: purpose)),
          );
        },
      );
    }

    final String displayName = config.name ?? config.serverUrl;
    final String subtitle = config.name != null ? config.serverUrl : 'No name';

    return CupertinoListTile(
      title: Text(displayName),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
      ),
      leading: Icon(_getServerIcon(config.serverType)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.only(left: 8, right: 4),
            minSize: 0,
            child: const Icon(CupertinoIcons.pencil, size: 22),
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (context) => AddEditServerScreen(serverToEdit: config, purpose: purpose)),
              );
            },
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(left: 4, right: 0),
            minSize: 0,
            child: Icon(CupertinoIcons.trash, color: CupertinoColors.systemRed.resolveFrom(context), size: 22),
            onPressed: () async {
              // Check mounted before showing dialog
              final isMounted = mounted;
              final confirmed = await showCupertinoDialog<bool>(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: Text('Delete ${purpose.name} Server?'),
                  content: Text('Are you sure you want to delete "$displayName"?'),
                  actions: [
                    CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
                    CupertinoDialogAction(isDestructiveAction: true, child: const Text('Delete'), onPressed: () => Navigator.of(context).pop(true)),
                  ],
                ),
              );
              // Check mounted *after* await
              if (!isMounted) return;
              if (confirmed == true) {
                // Call removeConfiguration on the correctly typed notifier
                bool success = false;
                if (notifier is NoteServerConfigNotifier) {
                  success = await notifier.removeConfiguration();
                } else if (notifier is TaskServerConfigNotifier) {
                  success = await notifier.removeConfiguration();
                }

                // Check mounted again before showing result dialog
                if (!mounted) return;
                if (!success) {
                  _showResultDialog('Error', 'Failed to delete ${purpose.name} server.', isError: true);
                } else {
                  _showResultDialog('Deleted', '${purpose.name.substring(0,1).toUpperCase()}${purpose.name.substring(1)} server "$displayName" deleted.');
                  // REMOVED direct setting of isVikunjaConfiguredProvider
                }
              }
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Watch the new single-config providers
    final noteServerConfig = ref.watch(noteServerConfigProvider);
    final taskServerConfig = ref.watch(taskServerConfigProvider);

    final bool automaticallyImplyLeading = !widget.isInitialSetup;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.isInitialSetup ? 'Server Setup' : 'Settings'),
          automaticallyImplyLeading: automaticallyImplyLeading,
          transitionBetweenRoutes: false,
          // Keep MCP add button, remove generic '+' button for Note/Task (handled in sections)
          trailing: CupertinoButton(
             padding: EdgeInsets.zero,
             onPressed: () {
               Navigator.of(context).push(
                 CupertinoPageRoute(builder: (context) => const AddEditMcpServerScreen()),
               );
             },
             child: const Icon(CupertinoIcons.gear_alt_fill, size: 24),
           ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(top: 16.0),
            children: [
              if (widget.isInitialSetup)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CupertinoColors.systemBlue.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.info_circle_fill, color: CupertinoColors.systemBlue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please add your Note server (Memos, Blinko, Vikunja) and/or Task server (Vikunja) details to get started.',
                            style: TextStyle(color: CupertinoColors.systemBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // --- Note Server Section ---
              CupertinoListSection.insetGrouped(
                header: const Text('NOTE SERVER'),
                footer: noteServerConfig == null
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15.0),
                        child: Text('Configure a server for note-taking (Memos, Blinko, or Vikunja).'),
                      )
                    : null,
                children: [
                  _buildServerConfigTile(noteServerConfig, ServerPurpose.note),
                ],
              ),
              // Test Note Connection Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: CupertinoButton( // Changed to non-filled
                  // color: CupertinoColors.systemBlue, // Optional color
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: _isTestingNoteConnection || noteServerConfig == null
                      ? null
                      : () => _testServerConnection(noteServerConfig, ServerPurpose.note),
                  child: _isTestingNoteConnection
                      ? const CupertinoActivityIndicator()
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.link),
                            SizedBox(width: 8),
                            Text('Test Note Connection'),
                          ],
                        ),
                ),
              ),

              // --- Task Server Section ---
              CupertinoListSection.insetGrouped(
                header: const Text('TASK SERVER'),
                 footer: taskServerConfig == null
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15.0),
                        child: Text('Configure a server for task management (e.g., Vikunja).'),
                      )
                    : null,
                children: [
                   _buildServerConfigTile(taskServerConfig, ServerPurpose.task),
                ],
              ),
               // Test Task Connection Button
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                 child: CupertinoButton( // Changed to non-filled
                   // color: CupertinoColors.systemBlue, // Optional color
                   padding: const EdgeInsets.symmetric(vertical: 10),
                   onPressed: _isTestingTaskConnection || taskServerConfig == null
                       ? null
                       : () => _testServerConnection(taskServerConfig, ServerPurpose.task),
                   child: _isTestingTaskConnection
                       ? const CupertinoActivityIndicator()
                       : const Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Icon(CupertinoIcons.link),
                             SizedBox(width: 8),
                             Text('Test Task Connection'),
                           ],
                         ),
                 ),
               ),

              // --- Integrations Section ---
              CupertinoListSection.insetGrouped(
                header: const Text('INTEGRATIONS'),
                children: [
                  // REMOVED Vikunja API Key Tile (Legacy)

                  // OpenAI Integration Tile
                  CupertinoListTile(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
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
                              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                              decoration: BoxDecoration(
                                color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
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
                              FocusScope.of(context).unfocus();
                              final isMounted =
                                  mounted; // Check mounted before await
                              final success = await ref.read(openAiApiKeyProvider.notifier).set(newKey);
                              if (!isMounted) {
                                return; // Check mounted after await
                              }
                              if (success) {
                                ref.read(openaiApiServiceProvider).configureService(authToken: newKey);
                                _showResultDialog('API Key Updated', 'OpenAI API key has been saved.');
                                _fetchModels();
                                ref.read(openaiApiHealthCheckerProvider);
                              } else {
                                _showResultDialog('Error', 'Failed to save OpenAI API key.', isError: true);
                              }
                            },
                            child: const Text('Save', style: TextStyle(color: CupertinoColors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Test OpenAI Connection Tile
                  CupertinoListTile(
                    title: Center(
                      child: CupertinoButton(
                        onPressed: _isTestingOpenAiConnection ? null : _testOpenAiConnection,
                        child: _isTestingOpenAiConnection
                            ? const CupertinoActivityIndicator()
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.link), SizedBox(width: 8), Text('Test OpenAI Connection'),
                                ],
                              ),
                      ),
                    ),
                  ),
                  // OpenAI Model Selection Tile
                  CupertinoListTile(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                    title: const Text('OpenAI Model (Grammar Fix)'),
                    additionalInfo: _isLoadingModels
                        ? const CupertinoActivityIndicator(radius: 10)
                        : (_modelLoadError != null || _availableModels.isEmpty)
                            ? CupertinoButton(
                                padding: EdgeInsets.zero, minSize: 0, onPressed: _fetchModels,
                                child: const Icon(CupertinoIcons.refresh, color: CupertinoColors.systemRed, size: 20),
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
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _modelLoadError != null
                            ? CupertinoColors.systemRed.resolveFrom(context)
                            : CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                    onTap: _isLoadingModels || _availableModels.isEmpty ? null : () => _showModelPicker(context),
                  ),
                  // Gemini Integration Tile
                  CupertinoListTile(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
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
                              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                              decoration: BoxDecoration(
                                color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
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
                              final newKey = _geminiApiKeyController.text.trim();
                              if (newKey.isEmpty) {
                                _showResultDialog('Error', 'Gemini API Key cannot be empty.', isError: true);
                                return;
                              }
                              FocusScope.of(context).unfocus();
                              final isMounted =
                                  mounted; // Check mounted before await
                              final success = await ref.read(geminiApiKeyProvider.notifier).set(newKey);
                              if (!isMounted) {
                                return; // Check mounted after await
                              }
                              if (success) {
                                _showResultDialog('API Key Updated', 'Gemini API key has been saved.');
                              } else {
                                _showResultDialog('Error', 'Failed to save Gemini API key.', isError: true);
                              }
                            },
                            child: const Text('Save', style: TextStyle(color: CupertinoColors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // --- MCP Server Section (Unchanged) ---
              CupertinoListSection.insetGrouped(
                header: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('MCP SERVERS'),
                    CupertinoButton(
                      padding: EdgeInsets.zero, minSize: 0,
                      onPressed: () {
                        ref.read(mcp_service.mcpClientProvider.notifier).syncConnections();
                        _showResultDialog('Applying Changes', 'Attempting to connect/disconnect MCP servers based on toggles.');
                      },
                      child: Row(
                        children: [
                          Text('Apply Changes', style: CupertinoTheme.of(context).textTheme.actionTextStyle),
                          const SizedBox(width: 4),
                          Icon(CupertinoIcons.refresh_circled, size: 18, color: CupertinoTheme.of(context).textTheme.actionTextStyle.color),
                        ],
                      ),
                    ),
                  ],
                ),
                footer: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 4.0),
                  child: Text('Toggle servers to connect and press "Apply Changes". Use "..." for more options.', style: TextStyle(fontSize: 12)),
                ),
                children: _buildMcpServerListTiles(context, ref),
              ),

              // Help Text Section (Updated)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [ Icon(CupertinoIcons.info_circle, size: 18), SizedBox(width: 6), Text('Server Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                      SizedBox(height: 8),
                      Text(
                        'Configure one Note server and one Task server.\nUse the pencil icon to Edit, and the trash icon to Delete.\n\nFor Memos/Blinko/Vikunja, the authentication token (Access Token or API Key) is usually found under Settings > My Account or API settings on your server.',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      Row(children: [ Icon(CupertinoIcons.info_circle, size: 18), SizedBox(width: 6), Text('Integrations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                      SizedBox(height: 8),
                      Text(
                        'API keys for integrations like OpenAI and Gemini are stored securely on your device.', // Removed "synced via iCloud"
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              // --- DANGER ZONE Section (Updated Reset Text) ---
              CupertinoListSection.insetGrouped(
                header: const Text('DANGER ZONE'),
                children: [
                  CupertinoListTile(
                    title: Text(
                      'Reset All Local Data',
                      style: TextStyle(
                        color: CupertinoColors.systemRed.resolveFrom(context),
                      ),
                    ), // Updated title
                    leading: Icon(CupertinoIcons.exclamationmark_octagon_fill, color: CupertinoColors.systemRed.resolveFrom(context)),
                    onTap: () async {
                      // Check mounted before showing dialog
                      final isMounted = mounted;
                      final confirmed = await showCupertinoDialog<bool>(
                        context: context,
                        builder: (dialogContext) => CupertinoAlertDialog(
                          title: const Text('Confirm Reset'),
                          content: const Text(
                                'This will permanently delete your configured Note server, Task server, all MCP servers, API keys (OpenAI, Gemini), cached data (notes, tasks, workbench items, chat history), and local settings from this device.\n\nSupabase data (like chat history) will also be deleted if configured.\n\nThis action cannot be undone. Are you absolutely sure?', // Updated content
                          ),
                          actions: [
                            CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(dialogContext, false)),
                            CupertinoDialogAction(isDestructiveAction: true, child: const Text('Reset Everything'), onPressed: () => Navigator.pop(dialogContext, true)),
                          ],
                        ),
                      );
                      // Check mounted *after* await
                      if (!isMounted) return;
                      if (confirmed == true) {
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
