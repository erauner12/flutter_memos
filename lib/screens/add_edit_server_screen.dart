import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/server_config.dart';
// Import new providers
import 'package:flutter_memos/providers/note_server_config_provider.dart';
import 'package:flutter_memos/providers/task_server_config_provider.dart';
// Import BaseApiService and specific services
import 'package:flutter_memos/services/base_api_service.dart';
import 'package:flutter_memos/services/blinko_api_service.dart';
import 'package:flutter_memos/services/memos_api_service.dart';
// Import Vikunja service
import 'package:flutter_memos/services/vikunja_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Enum to define the purpose of the server being added/edited
enum ServerPurpose { note, task }

class AddEditServerScreen extends ConsumerStatefulWidget {
  final ServerConfig? serverToEdit; // The existing config (if editing)
  final ServerPurpose purpose; // Purpose: Note or Task

  const AddEditServerScreen({
    super.key,
    this.serverToEdit,
    required this.purpose,
  });

  @override
  ConsumerState<AddEditServerScreen> createState() => _AddEditServerScreenState();
}

class _AddEditServerScreenState extends ConsumerState<AddEditServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  // Default server type based on purpose
  late ServerType _selectedServerType;

  bool _isTestingConnection = false;
  String? _urlError;
  String? _tokenError;

  bool get _isEditing => widget.serverToEdit != null;

  @override
  void initState() {
    super.initState();
    // Set initial server type based on purpose
    _selectedServerType =
        widget.purpose == ServerPurpose.note
            ? ServerType
                .memos // Default for notes (Memos)
            : ServerType.vikunja; // Default for tasks (Vikunja)

    if (_isEditing) {
      _nameController.text = widget.serverToEdit!.name ?? '';
      _urlController.text = widget.serverToEdit!.serverUrl;
      _tokenController.text = widget.serverToEdit!.authToken;
      // Ensure the edited server's type is valid for the purpose
      if (_isValidServerTypeForPurpose(
        widget.serverToEdit!.serverType,
        widget.purpose,
      )) {
        _selectedServerType = widget.serverToEdit!.serverType;
      } else {
        // If the existing type is somehow invalid for the purpose (e.g., Vikunja for Note),
        // log error and keep the default type for that purpose.
        if (kDebugMode) {
          print(
            "[AddEditServerScreen] Warning: Editing server with type ${widget.serverToEdit!.serverType} which is invalid for purpose ${widget.purpose}. Using default type '$_selectedServerType'.",
          );
        }
        // The default type set earlier based on purpose is already correct.
      }
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
    FocusScope.of(context).unfocus();
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    final serverType = _selectedServerType;

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
      case ServerType.vikunja:
        testApiService = VikunjaApiService();
        break;
      case ServerType.todoist: // Should not happen
        if (kDebugMode) {
          print(
            "[AddEditServerScreen] Error: Test connection attempted with Todoist type.",
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
      // Configure service with temporary details for testing
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
    if (!_validateUrl(_urlController.text.trim())) {
       _showResultDialog('Invalid URL', _urlError ?? 'Please enter a valid server URL.', isError: true);
      return;
    }
    if (!_validateToken(_tokenController.text.trim())) {
      _showResultDialog(
        'Invalid Token',
        _tokenError ?? 'Please enter a valid token.',
        isError: true,
      );
      return;
    }
    // Ensure selected type is valid for the purpose
    if (!_isValidServerTypeForPurpose(_selectedServerType, widget.purpose)) {
      if (kDebugMode) {
        print(
          "[AddEditServerScreen] Error: Attempted to save with invalid type '$_selectedServerType' for purpose '${widget.purpose}'.",
        );
      }
      _showResultDialog(
        'Internal Error',
        'Cannot save configuration with invalid type for this purpose.',
        isError: true,
      );
      return;
    }

    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();

    final config = ServerConfig(
      id: widget.serverToEdit?.id ?? const Uuid().v4(),
      name: name.isNotEmpty ? name : null,
      serverUrl: url,
      authToken: token,
      serverType: _selectedServerType,
    );

    if (kDebugMode) {
      print(
        '[AddEditServerScreen] Saving config for purpose: ${widget.purpose}. Config: ${config.toString()}',
      );
    }

    bool success = false;
    try {
      // Use the appropriate notifier based on the purpose
      if (widget.purpose == ServerPurpose.note) {
        final notifier = ref.read(noteServerConfigProvider.notifier);
        success = await notifier.setConfiguration(config);
      } else {
        // ServerPurpose.task
        final notifier = ref.read(taskServerConfigProvider.notifier);
        success = await notifier.setConfiguration(config);
      }
    } catch (e) {
      if (kDebugMode)
        print("[AddEditServerScreen] Error saving configuration: $e");
      success = false;
    }


    if (success && mounted) {
      Navigator.of(context).pop(); // Go back to settings screen
    } else if (!success && mounted) {
      _showResultDialog('Error', 'Failed to save configuration.', isError: true);
    }
  }

  // Helper to check if a server type is valid for the given purpose
  bool _isValidServerTypeForPurpose(ServerType type, ServerPurpose purpose) {
    if (purpose == ServerPurpose.note) {
      // Memos, Blinko are valid note servers
      return type == ServerType.memos || type == ServerType.blinko;
    } else {
      // ServerPurpose.task
      // Only Vikunja is a valid task server currently
      return type == ServerType.vikunja;
    }
  }

  // Build the segmented control options based on the purpose
  Map<ServerType, Widget> _buildServerTypeOptions() {
    Map<ServerType, Widget> options = {};
    if (widget.purpose == ServerPurpose.note) {
      // Only Memos and Blinko for Note servers
      options = {
        ServerType.memos: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Memos'),
        ),
        ServerType.blinko: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Blinko'),
        ),
      };
    } else {
      // ServerPurpose.task
      // Only Vikunja for Task servers
      options = {
        ServerType.vikunja: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Vikunja'), // Simplified label
        ),
        // Add other task server types here in the future
      };
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    const tokenLabel = 'Token';
    const tokenPlaceholder = 'Enter Access Token / API Key'; // More generic
    final String title =
        _isEditing
            ? 'Edit ${widget.purpose == ServerPurpose.note ? "Note" : "Task"} Server'
            : 'Add ${widget.purpose == ServerPurpose.note ? "Note" : "Task"} Server';

    final serverTypeOptions = _buildServerTypeOptions();

    // Ensure there are enough options for the segmented control
    // If only one option exists (e.g., only Vikunja for tasks), use a non-interactive display
    final bool showSegmentedControl = serverTypeOptions.length >= 2;

    // Helper to safely extract text from the widget map
    String getSingleOptionText() {
      final widget = serverTypeOptions.values.first;
      if (widget is Padding && widget.child is Text) {
        return (widget.child as Text).data ?? '';
      }
      return ''; // Fallback
    }

    return GestureDetector(
       onTap: () => FocusScope.of(context).unfocus(),
       child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
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
                    // Server Type Picker or Display
                    CupertinoFormRow(
                      prefix: const Text('Type'),
                      child:
                          showSegmentedControl
                              ? CupertinoSegmentedControl<ServerType>(
                                children: serverTypeOptions,
                                groupValue: _selectedServerType,
                                onValueChanged: (ServerType? newValue) {
                                  // Only allow switching to valid types for the current purpose
                                  if (newValue != null &&
                                      _isValidServerTypeForPurpose(
                                        newValue,
                                        widget.purpose,
                                      )) {
                                    setState(() {
                                      _selectedServerType = newValue;
                                      // Re-validate token if needed (e.g., different requirements per type)
                                      _validateToken(_tokenController.text);
                                    });
                                  }
                                },
                              )
                              : Padding(
                                // Display single option if only one is available
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10.0,
                                ),
                                child: Text(
                                  getSingleOptionText(), // Use helper to extract text safely
                                  style:
                                      CupertinoTheme.of(
                                        context,
                                      ).textTheme.textStyle,
                                ),
                              ),
                    ),
                    CupertinoTextFormFieldRow(
                      controller: _nameController,
                      placeholder: 'My Server (Optional)',
                      prefix: const Text('Name'),
                      textInputAction: TextInputAction.next,
                    ),
                    CupertinoTextFormFieldRow(
                      controller: _urlController,
                      placeholder: 'https://server.example.com',
                      prefix: const Text('URL'),
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      onChanged: _validateUrl,
                      validator: (value) => _urlError,
                    ),
                    if (_urlError != null)
                       Padding(
                        padding: const EdgeInsets.only(
                          left: 110,
                          top: 4,
                          bottom: 4,
                          right: 15,
                        ),
                         child: Text(
                           _urlError!,
                           style: TextStyle(color: CupertinoColors.systemRed.resolveFrom(context), fontSize: 12),
                         ),
                      ),
                    CupertinoTextFormFieldRow(
                      controller: _tokenController,
                      placeholder: tokenPlaceholder,
                      prefix: const Text(tokenLabel),
                      obscureText: true,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onChanged: _validateToken,
                      validator: (value) => _tokenError,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 110,
                        top: 0,
                        bottom: 0,
                        right: 15,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.only(right: 0),
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
                        padding: const EdgeInsets.only(
                          left: 110,
                          top: 4,
                          bottom: 4,
                          right: 15,
                        ),
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

                // Delete button is now handled in SettingsScreen
                // if (_isEditing) ...
              ],
            ),
          ),
        ),
       ),
    );
  }
}
