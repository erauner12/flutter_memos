import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
// Add imports for BaseApiService and specific services
import 'package:flutter_memos/services/base_api_service.dart';
import 'package:flutter_memos/services/blinko_api_service.dart';
import 'package:flutter_memos/services/memos_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class AddEditServerScreen extends ConsumerStatefulWidget {
  final ServerConfig? serverToEdit; // Null when adding a new server

  const AddEditServerScreen({super.key, this.serverToEdit});

  @override
  ConsumerState<AddEditServerScreen> createState() => _AddEditServerScreenState();
}

class _AddEditServerScreenState extends ConsumerState<AddEditServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  // Default to memos, Todoist is no longer an option here.
  ServerType _selectedServerType = ServerType.memos;

  bool _isTestingConnection = false;
  String? _urlError;
  String? _tokenError;

  bool get _isEditing => widget.serverToEdit != null;
  // Removed _isTodoist getter

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.serverToEdit!.name ?? '';
      _urlController.text = widget.serverToEdit!.serverUrl;
      _tokenController.text = widget.serverToEdit!.authToken;
      // Initialize server type, ensuring it's not Todoist (should be handled by loader)
      _selectedServerType =
          widget.serverToEdit!.serverType == ServerType.todoist
              ? ServerType
                  .memos // Fallback if somehow a Todoist config is passed
              : widget.serverToEdit!.serverType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  // Basic URL validation (now always required)
  bool _validateUrl(String value) {
    // Removed Todoist check
    if (value.isEmpty) {
      setState(() => _urlError = 'Server URL cannot be empty');
      return false;
    }
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      setState(() => _urlError = 'URL must start with http:// or https://');
      return false;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) {
       setState(() => _urlError = 'Invalid URL format');
       return false;
    }

    setState(() => _urlError = null);
    return true;
  }

  // Basic Token validation
  bool _validateToken(String value) {
    if (value.isEmpty) {
      setState(() => _tokenError = 'Token cannot be empty'); // Static label
      return false;
    }
    setState(() => _tokenError = null);
    return true;
  }


  Future<void> _pasteTokenFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _tokenController.text = clipboardData.text!;
        _validateToken(_tokenController.text); // Validate after pasting
      });
    }
  }

  void _showResultDialog(String title, String content, {bool isError = false}) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
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

  Future<void> _testConnection() async {
    // Removed Todoist check, button should always be enabled unless testing
    FocusScope.of(context).unfocus();
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    final serverType =
        _selectedServerType; // Use current selection (Memos/Blinko)

    if (!_validateUrl(url)) {
      _showResultDialog('Invalid URL', _urlError ?? 'Please enter a valid server URL.', isError: true);
      return;
    }
    if (!_validateToken(token)) {
      _showResultDialog(
        'Invalid Token',
        _tokenError ?? 'Please enter a valid token.',
        isError: true,
      );
      return;
    }

    setState(() { _isTestingConnection = true; });

    BaseApiService testApiService;

    switch (serverType) {
      case ServerType.memos:
        testApiService = MemosApiService();
        break;
      case ServerType.blinko:
        testApiService = BlinkoApiService();
        break;
      case ServerType.todoist:
        // This case should technically be unreachable now
        if (kDebugMode) {
          print(
            "[AddEditServerScreen] Error: Attempted test connection with Todoist type selected.",
          );
        }
        _showResultDialog(
          'Internal Error',
          'Cannot test connection for invalid type.',
          isError: true,
        );
        setState(() {
          _isTestingConnection = false;
        });
        return;
    }

    try {
      await testApiService.configureService(baseUrl: url, authToken: token);
      bool isHealthy = await testApiService.checkHealth();

      if (mounted) {
        if (isHealthy) {
          _showResultDialog('Success', 'Connection successful!');
        } else {
          _showResultDialog(
            'Connection Failed',
            'Could not connect. Check URL, Token, and Server Type.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("[AddEditServerScreen] Test Connection Error: $e");
      }
      if (mounted) {
        _showResultDialog(
          'Connection Failed',
          'Could not connect.\nCheck URL, Token, and Server Type.\n\nError: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isTestingConnection = false; });
      }
    }
  }

  Future<void> _saveConfiguration() async {
    FocusScope.of(context).unfocus();
    // Always validate URL now
    if (!_validateUrl(_urlController.text.trim())) {
       _showResultDialog('Invalid URL', _urlError ?? 'Please enter a valid server URL.', isError: true);
      return;
    }
    // Always validate token
    if (!_validateToken(_tokenController.text.trim())) {
      _showResultDialog(
        'Invalid Token', // Static label
        _tokenError ?? 'Please enter a valid token.', // Static message
        isError: true,
      );
      return;
    }

    final name = _nameController.text.trim();
    // URL is always from controller now
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    final notifier = ref.read(multiServerConfigProvider.notifier);

    if (kDebugMode) {
      print(
        '[AddEditServerScreen] Saving config. UI _selectedServerType: ${_selectedServerType.name}',
      );
    }

    // Ensure selected type is not Todoist before creating config
    if (_selectedServerType == ServerType.todoist) {
      if (kDebugMode) {
        print(
          "[AddEditServerScreen] Error: Attempted to save with Todoist type selected.",
        );
      }
      _showResultDialog(
        'Internal Error',
        'Cannot save configuration with invalid type.',
        isError: true,
      );
      return;
    }


    final config = ServerConfig(
      id: widget.serverToEdit?.id ?? const Uuid().v4(),
      name: name.isNotEmpty ? name : null,
      serverUrl: url, // Always use URL
      authToken: token,
      serverType: _selectedServerType, // Memos or Blinko
    );

    if (kDebugMode) {
      print(
        '[AddEditServerScreen] Created ServerConfig object to save: ${config.toString()}',
      );
    }

    bool success;
    if (_isEditing) {
      success = await notifier.updateServer(config);
    } else {
      success = await notifier.addServer(config);
    }

    if (success && mounted) {
      Navigator.of(context).pop(); // Go back to settings screen
    } else if (!success && mounted) {
      _showResultDialog('Error', 'Failed to save configuration.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Static labels now
    const tokenLabel = 'Token';
    const tokenPlaceholder = 'Enter Access Token';

    return GestureDetector(
       onTap: () => FocusScope.of(context).unfocus(),
       child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(_isEditing ? 'Edit Server' : 'Add Server'),
          transitionBetweenRoutes: false,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _saveConfiguration,
            child: const Text('Save'),
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                CupertinoFormSection.insetGrouped(
                  header: const Text('SERVER DETAILS'),
                  children: [
                    // Server Type Picker - Removed Todoist
                    CupertinoFormRow(
                      prefix: const Text('Type'),
                      child: CupertinoSegmentedControl<ServerType>(
                        children: const {
                          ServerType.memos: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('Memos'),
                          ),
                          ServerType.blinko: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('Blinko'),
                          ),
                          // Removed ServerType.todoist entry
                        },
                        groupValue: _selectedServerType,
                        onValueChanged: (ServerType? newValue) {
                          // Only allow switching between Memos and Blinko
                          if (newValue != null &&
                              newValue != ServerType.todoist) {
                            setState(() {
                              _selectedServerType = newValue;
                              // Re-validate token (label doesn't change, but good practice)
                              _validateToken(_tokenController.text);
                            });
                          }
                        },
                      ),
                    ),
                    CupertinoTextFormFieldRow(
                      controller: _nameController,
                      placeholder:
                          'My Memos Server (Optional)', // Static placeholder
                      prefix: const Text('Name'),
                      textInputAction: TextInputAction.next,
                    ),
                    // URL field always shown now
                    CupertinoTextFormFieldRow(
                      controller: _urlController,
                      placeholder: 'https://memos.example.com',
                      prefix: const Text('URL'),
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      onChanged: _validateUrl, // Validate on change
                      validator:
                          (value) => _urlError, // Use state for error message
                    ),
                    if (_urlError != null)
                       Padding(
                         padding: const EdgeInsets.only(left: 110, top: 4, bottom: 4, right: 15), // Adjust padding
                         child: Text(
                           _urlError!,
                           style: TextStyle(color: CupertinoColors.systemRed.resolveFrom(context), fontSize: 12),
                         ),
                       ),
                    // Token Field - Static labels
                    CupertinoTextFormFieldRow(
                      controller: _tokenController,
                      placeholder: tokenPlaceholder,
                      prefix: const Text(tokenLabel), // Static label
                      obscureText: true,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onChanged: _validateToken, // Validate on change
                      validator:
                          (value) => _tokenError, // Use state for error message
                    ),
                    // Paste Button - aligned with Token field
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 110, // Align with text field content start
                        top: 0,
                        bottom: 0,
                        right: 15,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end, // Align button to the right
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.only(
                              right: 0,
                            ), // Adjust padding
                            minSize: 0,
                            onPressed: _pasteTokenFromClipboard,
                            child: const Icon(
                              CupertinoIcons.doc_on_clipboard,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_tokenError != null)
                       Padding(
                         padding: const EdgeInsets.only(left: 110, top: 4, bottom: 4, right: 15), // Adjust padding
                         child: Text(
                           _tokenError!,
                           style: TextStyle(color: CupertinoColors.systemRed.resolveFrom(context), fontSize: 12),
                         ),
                       ),
                  ],
                ),

                const SizedBox(height: 20),

                // Test Connection Button - Always enabled unless testing
                CupertinoButton.filled(
                  onPressed: _isTestingConnection ? null : _testConnection,
                  child: _isTestingConnection
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : const Row(
                            // Static content now
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(CupertinoIcons.link),
                              SizedBox(width: 8),
                              Text('Test Connection'),
                          ],
                        ),
                ),

                 const SizedBox(height: 20),

                // Delete button only when editing
                 if (_isEditing)
                   CupertinoButton(
                     color: CupertinoColors.destructiveRed,
                     onPressed: () async {
                       final confirmed = await showCupertinoDialog<bool>(
                         context: context,
                         builder: (context) => CupertinoAlertDialog(
                           title: const Text('Delete Server?'),
                              content: Text(
                                // Updated delete confirmation message
                                'Are you sure you want to delete "${widget.serverToEdit!.name ?? widget.serverToEdit!.serverUrl}"?',
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
                         final success = await ref.read(multiServerConfigProvider.notifier).removeServer(widget.serverToEdit!.id);
                        if (!mounted) return; // Add mounted check here
                        if (success) {
                           Navigator.of(context).pop(); // Pop back to settings
                        } else {
                            _showResultDialog('Error', 'Failed to delete server.', isError: true);
                         }
                       }
                     },
                     child: const Text('Delete Server'),
                   ),
              ],
            ),
          ),
        ),
       ),
    );
  }
}
