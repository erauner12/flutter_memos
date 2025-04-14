import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/services/api_service.dart'; // Import MemosApiService
// Add imports for BaseApiService and BlinkoApiService
import 'package:flutter_memos/services/base_api_service.dart';
import 'package:flutter_memos/services/blinko_api_service.dart';
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
  // Add state for ServerType
  ServerType _selectedServerType = ServerType.memos; // Default to memos

  bool _isTestingConnection = false;
  String? _urlError;
  String? _tokenError; // Optional: Add token validation if needed

  bool get _isEditing => widget.serverToEdit != null;

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

  // Basic URL validation (can be enhanced)
  bool _validateUrl(String value) {
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

  Future<void> _pasteTokenFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _tokenController.text = clipboardData.text!;
        // Optional: Add token validation feedback if needed
        // _validateToken(_tokenController.text);
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
    FocusScope.of(context).unfocus();
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    // Get the currently selected server type from the state
    final serverType = _selectedServerType;

    if (!_validateUrl(url)) {
      _showResultDialog('Invalid URL', _urlError ?? 'Please enter a valid server URL.', isError: true);
      return;
    }

    setState(() { _isTestingConnection = true; });

    // Declare variable with the BaseApiService type
    BaseApiService testApiService;

    // Instantiate the correct service based on the selected type
    switch (serverType) {
      case ServerType.memos:
        testApiService = MemosApiService();
        break;
      case ServerType.blinko:
        testApiService = BlinkoApiService();
        break;
      // Optional: Add default or error handling if ServerType could be null/unexpected
      // default:
      //   _showResultDialog('Error', 'Invalid server type selected.', isError: true);
      //   setState(() { _isTestingConnection = false; });
      //   return;
    }

    try {
      // Configure the selected service instance
      await testApiService.configureService(baseUrl: url, authToken: token);

      // Call the common health check method (preferred) or listNotes as fallback
      // Using listNotes as the primary check for now as checkHealth might vary
      await testApiService.listNotes(pageSize: 1);
      bool isHealthy = true; // Assume success if listNotes doesn't throw

      // Alternatively, use checkHealth if implemented consistently:
      // bool isHealthy = await testApiService.checkHealth();

      if (mounted) {
        if (isHealthy) {
          _showResultDialog('Success', 'Connection successful!');
        }
        // Removed the 'else' block causing dead code warning, as isHealthy is always true here
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
    if (!_validateUrl(_urlController.text.trim())) {
       _showResultDialog('Invalid URL', _urlError ?? 'Please enter a valid server URL.', isError: true);
      return;
    }
    // Add token validation if needed
    // if (!_validateToken(_tokenController.text.trim())) return;

    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    final notifier = ref.read(multiServerConfigProvider.notifier);

    // --- Add Logging Here ---
    if (kDebugMode) {
      print(
        '[AddEditServerScreen] Saving config. UI _selectedServerType: ${_selectedServerType.name}',
      );
    }
    // --- End Logging ---

    final config = ServerConfig(
      id: widget.serverToEdit?.id ?? const Uuid().v4(), // Use existing ID or generate new
      name: name.isNotEmpty ? name : null, // Store null if name is empty
      serverUrl: url,
      authToken: token,
      serverType: _selectedServerType, // Include selected server type
    );

    // --- Add Logging Here ---
    if (kDebugMode) {
      print(
        '[AddEditServerScreen] Created ServerConfig object to save: ${config.toString()}',
      );
    }
    // --- End Logging ---

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
    return GestureDetector(
       onTap: () => FocusScope.of(context).unfocus(),
       child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(_isEditing ? 'Edit Server' : 'Add Server'),
          transitionBetweenRoutes: false, // Disable Hero animation
          // leading: // Automatically implied back button
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
                        },
                        groupValue: _selectedServerType,
                        onValueChanged: (ServerType? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedServerType = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    CupertinoTextFormFieldRow(
                      controller: _nameController,
                      placeholder: 'My Memos Server (Optional)',
                      prefix: const Text('Name'),
                      textInputAction: TextInputAction.next,
                    ),
                    CupertinoTextFormFieldRow(
                      controller: _urlController,
                      placeholder: 'https://memos.example.com',
                      prefix: const Text('URL'),
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      onChanged: _validateUrl, // Validate on change
                      validator: (value) => _urlError, // Use state for error message
                    ),
                     if (_urlError != null)
                       Padding(
                         padding: const EdgeInsets.only(left: 110, top: 4, bottom: 4, right: 15), // Adjust padding
                         child: Text(
                           _urlError!,
                           style: TextStyle(color: CupertinoColors.systemRed.resolveFrom(context), fontSize: 12),
                         ),
                       ),
                    CupertinoTextFormFieldRow(
                      controller: _tokenController,
                      placeholder: 'Enter Access Token',
                      prefix: const Text('Token'),
                      obscureText: true,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      // validator: (value) => _tokenError, // Add token validation if needed
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 110,
                        top: 0,
                        bottom: 0,
                        right: 15,
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.only(right: 8),
                        minSize: 0,
                        alignment: Alignment.centerRight,
                        onPressed: _pasteTokenFromClipboard,
                        child: const Icon(CupertinoIcons.doc_on_clipboard, size: 20),
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

                CupertinoButton.filled(
                  onPressed: _isTestingConnection ? null : _testConnection,
                  child: _isTestingConnection
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.link),
                            SizedBox(width: 8),
                            Text('Test Connection'),
                          ],
                        ),
                ),

                 const SizedBox(height: 20),

                 // Add Delete button only when editing
                 if (_isEditing)
                   CupertinoButton(
                     color: CupertinoColors.destructiveRed,
                     onPressed: () async {
                       final confirmed = await showCupertinoDialog<bool>(
                         context: context,
                         builder: (context) => CupertinoAlertDialog(
                           title: const Text('Delete Server?'),
                           content: Text('Are you sure you want to delete "${widget.serverToEdit!.name ?? widget.serverToEdit!.serverUrl}"?'),
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
