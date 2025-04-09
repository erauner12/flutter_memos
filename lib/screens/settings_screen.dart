import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // Import settings provider
import 'package:flutter_memos/screens/add_edit_server_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;
  const SettingsScreen({super.key, this.isInitialSetup = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Keep loading/testing state if needed for actions
  bool _isTestingConnection =
      false; // Specific state for testing the active Memos connection

  // Add state for Todoist configuration
  final _todoistApiKeyController = TextEditingController();
  bool _isTestingTodoistConnection = false;
  // String _currentTodoistApiKey = ''; // Can be read directly from provider when needed

  @override
  void initState() {
    super.initState();
    // No need to initialize Memos form values anymore

    // Initialize Todoist controller after the first frame ensures provider is ready
    // Use addPostFrameCallback to read the provider after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if mounted before accessing ref
      if (mounted) {
        final initialApiKey = ref.read(todoistApiKeyProvider);
        _todoistApiKeyController.text = initialApiKey;
      }
    });
  }

  @override
  void dispose() {
    // Dispose removed controllers
    _todoistApiKeyController.dispose(); // Dispose the new controller
    super.dispose();
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

  // Adapt _testConnection to test the *active* server
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

    setState(() {
      _isTestingConnection = true;
    });

    // Use the apiServiceProvider which is already configured for the active server
    final apiService = ref.read(apiServiceProvider);

    try {
      // Use a lightweight API call
      await apiService.listMemos(
        pageSize: 1,
        parent: 'users/1',
      ); // Or another suitable endpoint

      if (mounted) {
        _showResultDialog(
          'Success',
          'Connection to "${activeConfig.name ?? activeConfig.serverUrl}" successful!',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          "[SettingsScreen] Test Connection Error for ${activeConfig.id}: $e",
        );
      }
      if (mounted) {
        _showResultDialog(
          'Connection Failed',
          'Could not connect to "${activeConfig.name ?? activeConfig.serverUrl}".\n\nError: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });
      }
    }
  }

  Future<void> _testTodoistConnection() async {
    FocusScope.of(context).unfocus();
    // Read the service which is configured by the provider watching the key
    final todoistService = ref.read(todoistApiServiceProvider);
    final currentKey = ref.read(
      todoistApiKeyProvider,
    ); // Read current key state directly

    if (currentKey.isEmpty) {
      _showResultDialog(
        'API Key Missing',
        'Please enter and save your Todoist API key first.',
        isError: true,
      );
      return;
    }

    // Check if the service instance believes it's configured.
    // This depends on whether the provider passed a non-empty key during its build.
    if (!todoistService.isConfigured) {
      _showResultDialog(
        'Service Not Configured',
        'Todoist service is not configured, likely due to an empty key. Please save the key.',
        isError: true,
      );
      return;
    }

    setState(() => _isTestingTodoistConnection = true);

    try {
      // Use the checkHealth method from the service
      final isHealthy = await todoistService.checkHealth();
      if (mounted) {
        if (isHealthy) {
          _showResultDialog('Success', 'Todoist connection successful!');
        } else {
          // checkHealth returning false usually means an API error occurred (e.g., invalid token)
          _showResultDialog(
            'Connection Failed',
            'Could not connect to Todoist. Please verify your API key.',
            isError: true,
          );
        }
      }
    } catch (e) {
      // Catch other errors (like network issues)
      if (kDebugMode) {
        print("[SettingsScreen] Test Todoist Connection Error: \$e");
      }
      if (mounted) {
        _showResultDialog(
          'Error',
          'An error occurred while testing the connection:\n\${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingTodoistConnection = false);
      }
    }
  }

  void _showServerActions(
    BuildContext context,
    ServerConfig server,
    MultiServerConfigNotifier notifier,
    bool isActive,
    bool isDefault,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: Text(server.name ?? server.serverUrl),
            // message: const Text('Select an action'),
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
              if (!isActive) // Only show if not already active
                CupertinoActionSheetAction(
                  child: const Text('Set Active'),
                  onPressed: () {
                    notifier.setActiveServer(server.id);
                    Navigator.pop(context); // Close the action sheet
                  },
                ),
              if (!isDefault) // Only show if not already default
                CupertinoActionSheetAction(
                  child: const Text('Set Default'),
                  onPressed: () {
                    notifier.setDefaultServer(server.id);
                    Navigator.pop(context); // Close the action sheet
                  },
                ),
              if (isDefault) // Option to unset default
                CupertinoActionSheetAction(
                  child: const Text('Unset Default'),
                  onPressed: () {
                    notifier.setDefaultServer(null); // Set default to null
                    Navigator.pop(context); // Close the action sheet
                  },
                ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () async {
                  Navigator.pop(context); // Close the action sheet first
                  final confirmed = await showCupertinoDialog<bool>(
                    context: context, // Use the original context
                    builder:
                        (context) => CupertinoAlertDialog(
                          title: const Text('Delete Server?'),
                          content: Text(
                            'Are you sure you want to delete "${server.name ?? server.serverUrl}"?',
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
                    final success = await notifier.removeServer(server.id);
                    if (!success && mounted) {
                      _showResultDialog(
                        'Error',
                        'Failed to delete server.',
                        isError: true,
                      );
                    }
                  }
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the multi-server state
    final multiServerState = ref.watch(multiServerConfigProvider);
    final servers = multiServerState.servers;
    final activeServerId = multiServerState.activeServerId;
    final defaultServerId = multiServerState.defaultServerId;
    final notifier = ref.read(multiServerConfigProvider.notifier);

    final bool automaticallyImplyLeading = !widget.isInitialSetup;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.isInitialSetup ? 'Server Setup' : 'Settings'),
          automaticallyImplyLeading: automaticallyImplyLeading,
          transitionBetweenRoutes: false, // Add this line
          // Replace Save with Add button
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              // Navigate to AddEditServerScreen for adding a new server
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const AddEditServerScreen(),
                ),
              );
              // print("Navigate to Add Server Screen");
              // _showResultDialog("Not Implemented", "Adding servers will be implemented next.");
            },
            child: const Icon(CupertinoIcons.add),
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
                            'Please add your Memos server details to get started.',
                            style: TextStyle(color: CupertinoColors.systemBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Server List Section
              CupertinoListSection.insetGrouped(
                header: const Text('CONFIGURED SERVERS'),
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
                    return CupertinoListTile(
                      title: Text(server.name ?? server.serverUrl),
                      subtitle: Text(
                        server.name != null ? server.serverUrl : 'No name',
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
                          if (isDefault)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(
                                CupertinoIcons.star_fill,
                                size: 16,
                                color: CupertinoColors.systemYellow,
                              ),
                            ),
                          // TODO: Replace with CupertinoContextMenu or similar for actions
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 0,
                            child: const Icon(CupertinoIcons.ellipsis),
                            onPressed: () {
                              _showServerActions(
                                context,
                                server,
                                notifier,
                                isActive,
                                isDefault,
                              );
                              // print("Show actions for server: ${server.id}");
                              //  _showResultDialog("Not Implemented", "Server actions (Edit, Delete, etc.) will be implemented next.");
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        // Set server active on tap
                        if (!isActive) {
                          notifier.setActiveServer(server.id);
                        }
                      },
                    );
                  }),
                ],
              ),

              // Test Connection Button (tests the *active* server)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed:
                      _isTestingConnection || activeServerId == null
                          ? null
                          : _testConnection,
                  child:
                      _isTestingConnection
                          ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                          : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.link),
                              SizedBox(width: 8),
                              Text('Test Active Connection'),
                            ],
                          ),
                ),
              ),

              // --- Add Todoist Integration Section ---
              CupertinoListSection.insetGrouped(
                header: const Text('INTEGRATIONS'),
                children: [
                  CupertinoListTile(
                    // Use padding to avoid default list tile padding affecting layout
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
                              // Clear button might be useful
                              clearButtonMode: OverlayVisibilityMode.editing,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            // Use primary color for save action
                            color: CupertinoColors.activeBlue,
                            onPressed: () {
                              final newKey = _todoistApiKeyController.text;
                              // Update the key using the provider notifier
                              ref
                                  .read(todoistApiKeyProvider.notifier)
                                  .set(newKey);
                              FocusScope.of(context).unfocus();
                              // Replace SnackBar with _showResultDialog
                              _showResultDialog(
                                'API Key Updated',
                                'Todoist API key has been saved successfully.',
                              );
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
                  // Test Todoist Connection Button as a separate tile
                  CupertinoListTile(
                    title: Center(
                      // Center the button within the tile
                      child: CupertinoButton(
                        onPressed:
                            _isTestingTodoistConnection
                                ? null
                                : _testTodoistConnection,
                        child:
                            _isTestingTodoistConnection
                                ? const CupertinoActivityIndicator()
                                : const Row(
                                  mainAxisSize:
                                      MainAxisSize.min, // Keep row compact
                                  children: [
                                    Icon(CupertinoIcons.link),
                                    SizedBox(width: 8),
                                    Text('Test Todoist Connection'),
                                  ],
                                ),
                      ),
                    ),
                  ),
                ],
              ),
              // --- End Todoist Integration Section ---
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
                        'Tap a server to make it active for the current session.\n'
                        'Use the "..." menu to Edit, Delete, or set a server as Default (used on app startup).\n\n'
                        'The authentication token (Access Token) can be created in your Memos server under Settings > My Account.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
