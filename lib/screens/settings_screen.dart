import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;
  const SettingsScreen({super.key, this.isInitialSetup = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Remove old state variables
  // final _serverUrlController = TextEditingController();
  // final _authTokenController = TextEditingController();
  // bool _hasChanges = false;
  // ServerConfig? _initialConfig;
  // String? _serverUrlError;
  // String? _tokenError;

  // Keep loading/testing state if needed for actions
  bool _isTestingConnection =
      false; // Specific state for testing the active connection

  @override
  void initState() {
    super.initState();
    // No need to initialize form values anymore
  }

  @override
  void dispose() {
    // Dispose removed controllers
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
          // Replace Save with Add button
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              // TODO: Implement navigation to Add/Edit Server Screen
              print("Navigate to Add Server Screen");
              _showResultDialog(
                "Not Implemented",
                "Adding servers will be implemented next.",
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
                              // TODO: Show action sheet/menu for Edit, Delete, Set Active, Set Default
                              print("Show actions for server: ${server.id}");
                              _showResultDialog(
                                "Not Implemented",
                                "Server actions (Edit, Delete, etc.) will be implemented next.",
                              );
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
