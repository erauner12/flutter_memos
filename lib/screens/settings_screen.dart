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
  // Memos server state
  bool _isTestingConnection = false;

  // Todoist state
  final _todoistApiKeyController = TextEditingController();
  bool _isTestingTodoistConnection = false;

  // OpenAI state
  final _openaiApiKeyController = TextEditingController();
  bool _isTestingOpenAiConnection = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers after the first frame ensures providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final initialTodoistKey = ref.read(todoistApiKeyProvider);
        _todoistApiKeyController.text = initialTodoistKey;

        final initialOpenAiKey = ref.read(openAiApiKeyProvider);
        _openaiApiKeyController.text = initialOpenAiKey;
      }
    });
  }

  @override
  void dispose() {
    _todoistApiKeyController.dispose();
    _openaiApiKeyController.dispose(); // Dispose the new controller
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

  // Test Memos connection
  Future<void> _testConnection() async {
    FocusScope.of(context).unfocus();
    final activeConfig = ref.read(activeServerConfigProvider);

    if (activeConfig == null) {
      _showResultDialog(
        'No Active Server',
        'Please select or add a Memos server configuration first.',
        isError: true,
      );
      return;
    }

    setState(() => _isTestingConnection = true);
    final apiService = ref.read(apiServiceProvider);

    try {
      await apiService.listMemos(pageSize: 1, parent: 'users/-');
      if (mounted) {
        _showResultDialog(
          'Success',
          'Connection to Memos server "${activeConfig.name ?? activeConfig.serverUrl}" successful!',
        );
      }
    } catch (e) {
      if (kDebugMode) print("[SettingsScreen] Test Memos Connection Error: $e");
      if (mounted) {
        _showResultDialog(
          'Connection Failed',
          'Could not connect to Memos server "${activeConfig.name ?? activeConfig.serverUrl}".\n\nError: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingConnection = false);
    }
  }

  // Test Todoist connection
  Future<void> _testTodoistConnection() async {
    FocusScope.of(context).unfocus();
    final todoistService = ref.read(todoistApiServiceProvider);
    final currentKey = ref.read(todoistApiKeyProvider);

    if (currentKey.isEmpty) {
      _showResultDialog(
        'API Key Missing',
        'Please enter and save your Todoist API key first.',
        isError: true,
      );
      return;
    }
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
        print("[SettingsScreen] Test Todoist Connection Error: $e");
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
        print("[SettingsScreen] Test OpenAI Connection Error: $e");
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          transitionBetweenRoutes: false,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const AddEditServerScreen(),
                ),
              );
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
                header: const Text('MEMOS SERVERS'),
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

              // Test Memos Connection Button
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
                              Text('Test Active Memos Connection'),
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
                            onPressed: () {
                              final newKey = _todoistApiKeyController.text;
                              ref
                                  .read(todoistApiKeyProvider.notifier)
                                  .set(newKey);
                              FocusScope.of(context).unfocus();
                              _showResultDialog(
                                'API Key Updated',
                                'Todoist API key has been saved.',
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
                              controller:
                                  _openaiApiKeyController, // Use OpenAI controller
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
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: CupertinoColors.activeBlue,
                            onPressed: () {
                              final newKey = _openaiApiKeyController.text;
                              // Use OpenAI provider notifier
                              ref
                                  .read(openAiApiKeyProvider.notifier)
                                  .set(newKey);
                              FocusScope.of(context).unfocus();
                              _showResultDialog(
                                'API Key Updated',
                                'OpenAI API key has been saved.',
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
                  // Test OpenAI Connection Tile
                  CupertinoListTile(
                    title: Center(
                      child: CupertinoButton(
                        onPressed:
                            _isTestingOpenAiConnection
                                ? null
                                : _testOpenAiConnection, // Use OpenAI test function
                        child:
                            _isTestingOpenAiConnection // Use OpenAI loading state
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
                ],
              ),
              // --- End Integrations Section ---

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
                        'Tap a server to make it active.\nUse "..." to Edit, Delete, or set a Default server.\n\nThe Memos authentication token (Access Token) is under Settings > My Account on your server.',
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
                        'API keys for integrations like Todoist and OpenAI are stored locally on your device.',
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
