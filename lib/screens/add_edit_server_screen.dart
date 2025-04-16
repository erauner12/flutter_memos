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
  ServerType _selectedServerType = ServerType.memos; // Default to memos

  bool _isTestingConnection = false;
  String? _urlError;
  String? _tokenError; // Optional: Add token validation if needed

  bool get _isEditing => widget.serverToEdit != null;
  bool get _isTodoist => _selectedServerType == ServerType.todoist;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.serverToEdit!.name ?? '';
      _urlController.text = widget.serverToEdit!.serverUrl;
      _tokenController.text = widget.serverToEdit!.authToken;
      _selectedServerType =
          widget.serverToEdit!.serverType; // Initialize server type
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  // Basic URL validation (can be enhanced) - only validate if not Todoist
  bool _validateUrl(String value) {
    if (_isTodoist) {
      setState(() => _urlError = null);
      return true; // No URL validation needed for Todoist
    }
    if (value.isEmpty) {
      setState(() => _urlError = 'Server URL cannot be empty');
      return false;
    }
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      setState(() => _urlError = 'URL must start with http:// or https://');
      return false;
    }
    // Basic check for domain presence (very rudimentary)
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
      setState(
        () =>
            _tokenError =
                _isTodoist
                    ? 'API Key cannot be empty'
                    : 'Token cannot be empty',
      );
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
    // Should not be called for Todoist as the button is disabled
    if (_isTodoist) return;

    FocusScope.of(context).unfocus();
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    final serverType = _selectedServerType; // Use current selection

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
        // This case should not be reached due to disabled button, but handle defensively
        _showResultDialog(
          'Info',
          'Test connection for Todoist via the main Settings screen.',
          isError: false,
        );
        setState(() {
          _isTestingConnection = false;
        });
        return;
    }

    try {
      await testApiService.configureService(baseUrl: url, authToken: token);
      // Use checkHealth as the primary test method now
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
    // Validate URL only if not Todoist
    if (!_isTodoist && !_validateUrl(_urlController.text.trim())) {
       _showResultDialog('Invalid URL', _urlError ?? 'Please enter a valid server URL.', isError: true);
      return;
    }
    // Always validate token/API key
    if (!_validateToken(_tokenController.text.trim())) {
      _showResultDialog(
        'Invalid Token/Key',
        _tokenError ?? 'Please enter a valid token or API key.',
        isError: true,
      );
      return;
    }

    final name = _nameController.text.trim();
    // Use empty string for URL if Todoist, otherwise use controller value
    final url = _isTodoist ? '' : _urlController.text.trim();
    final token = _tokenController.text.trim();
    final notifier = ref.read(multiServerConfigProvider.notifier);

    if (kDebugMode) {
      print(
        '[AddEditServerScreen] Saving config. UI _selectedServerType: ${_selectedServerType.name}',
      );
    }

    final config = ServerConfig(
      id: widget.serverToEdit?.id ?? const Uuid().v4(),
      name: name.isNotEmpty ? name : null,
      serverUrl: url, // Will be empty for Todoist
      authToken: token, // Stores API key for Todoist
      serverType: _selectedServerType,
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
      // If saving a Todoist config, trigger a refresh of the Todoist API key provider
      // This isn't strictly necessary if the main provider watches the config,
      // but can ensure immediate consistency.
      // if (_selectedServerType == ServerType.todoist) {
      //   ref.read(todoistApiKeyProvider.notifier).set(token); // Update global key
      // }
      Navigator.of(context).pop(); // Go back to settings screen
    } else if (!success && mounted) {
      _showResultDialog('Error', 'Failed to save configuration.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenLabel = _isTodoist ? 'API Key' : 'Token';
    final tokenPlaceholder =
        _isTodoist ? 'Enter Todoist API Key' : 'Enter Access Token';

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
                    // Server Type Picker
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
                          ServerType.todoist: Padding(
                            // Add Todoist option
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('Todoist'),
                          ),
                        },
                        groupValue: _selectedServerType,
                        onValueChanged: (ServerType? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedServerType = newValue;
                              // Clear URL error if switching to Todoist
                              if (newValue == ServerType.todoist) {
                                _urlError = null;
                              }
                              // Re-validate token/key label
                              _validateToken(_tokenController.text);
                            });
                          }
                        },
                      ),
                    ),
                    CupertinoTextFormFieldRow(
                      controller: _nameController,
                      placeholder:
                          _isTodoist
                              ? 'My Todoist (Optional)'
                              : 'My Memos Server (Optional)',
                      prefix: const Text('Name'),
                      textInputAction: TextInputAction.next,
                    ),
                    // Conditionally show URL field
                    if (!_isTodoist)
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
                    if (!_isTodoist && _urlError != null)
                       Padding(
                         padding: const EdgeInsets.only(left: 110, top: 4, bottom: 4, right: 15), // Adjust padding
                         child: Text(
                           _urlError!,
                           style: TextStyle(color: CupertinoColors.systemRed.resolveFrom(context), fontSize: 12),
                         ),
                       ),
                    // Token / API Key Field
                    CupertinoTextFormFieldRow(
                      controller: _tokenController,
                      placeholder: tokenPlaceholder,
                      prefix: Text(tokenLabel), // Dynamic label
                      obscureText: true,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onChanged: _validateToken, // Validate on change
                      validator:
                          (value) => _tokenError, // Use state for error message
                    ),
                    // Paste Button - aligned with Token/API Key field
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 110, // Align with text field content start
                        top: 0,
                        bottom: 0,
                        right: 15,
                      ),
                      child: Row(
                        // Use Row for alignment
                        mainAxisAlignment:
                            MainAxisAlignment.end, // Align button to the right
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.only(
                              right: 0,
                            ), // Adjust padding
                            minSize: 0,
                            // alignment: Alignment.centerRight, // Alignment within button
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

                // Test Connection Button - Disable for Todoist
                CupertinoButton.filled(
                  onPressed:
                      _isTestingConnection || _isTodoist
                          ? null
                          : _testConnection,
                  child: _isTestingConnection
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(
                                _isTodoist
                                    ? CupertinoIcons.nosign
                                    : CupertinoIcons.link,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isTodoist
                                    ? 'Test via Settings > Integrations'
                                    : 'Test Connection',
                              ),
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
                                'Are you sure you want to delete "${widget.serverToEdit!.name ?? (_isTodoist ? 'Todoist Config' : widget.serverToEdit!.serverUrl)}"?',
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
