import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  // Add flag to indicate if this is the initial setup screen
  final bool isInitialSetup;

  const SettingsScreen({super.key, this.isInitialSetup = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  final _authTokenController = TextEditingController();
  // final _formKey = GlobalKey<FormState>(); // Removed unused form key
  bool _isLoading = false;
  bool _isTesting = false;
  bool _hasChanges = false;
  ServerConfig? _initialConfig;
  String? _serverUrlError;
  String? _tokenError; // Optional: for token validation feedback

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFormValues();
    });
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _authTokenController.dispose();
    super.dispose();
  }

  void _initializeFormValues() {
    final config = ref.read(serverConfigProvider);
    _serverUrlController.text = config.serverUrl;
    _authTokenController.text = config.authToken;
    _initialConfig = config;
    _serverUrlController.addListener(_checkForChanges);
    _authTokenController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final currentUrl = _serverUrlController.text.trim();
    final currentToken = _authTokenController.text.trim();
    final initialConfig = _initialConfig;

    if (initialConfig != null) {
      final changed =
          currentUrl != initialConfig.serverUrl ||
                      currentToken != initialConfig.authToken;
      if (changed != _hasChanges) {
        setState(() {
          _hasChanges = changed;
        });
      }
    }
    _validateUrl(currentUrl); // Re-validate URL on change
  }

  bool _validateUrl(String value) {
    if (value.isEmpty) {
      setState(() => _serverUrlError = 'Server URL is required');
      return false;
    }
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      setState(
        () => _serverUrlError = 'URL must start with http:// or https://',
      );
      return false;
    }
    setState(() => _serverUrlError = null);
    return true;
  }

  Future<void> _saveConfiguration() async {
    FocusScope.of(context).unfocus(); // Dismiss keyboard
    final url = _serverUrlController.text.trim();
    if (!_validateUrl(url)) return; // Validate before saving

    setState(() { _isLoading = true; });

    try {
      final authToken = _authTokenController.text.trim();
      final newConfig = ServerConfig(serverUrl: url, authToken: authToken);
      final success = await ref
          .read(serverConfigProvider.notifier)
          .saveToPreferences(newConfig);

      if (success && mounted) {
        ref.invalidate(apiServiceProvider); // Refresh API service
        setState(() {
          _hasChanges = false;
          _initialConfig = newConfig;
        });
        _showResultDialog('Success', 'Settings saved successfully.');
      } else if (mounted) {
        _showResultDialog('Error', 'Failed to save settings.', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog(
          'Error',
          'Failed to save settings: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _testConnection() async {
    FocusScope.of(context).unfocus();
    final url = _serverUrlController.text.trim();
    if (!_validateUrl(url)) return; // Validate before testing

    // Force save if there are changes
    if (_hasChanges && !_isLoading) {
      setState(() {
        _isLoading = true;
      }); // Show loading indicator for save+test
      final authToken = _authTokenController.text.trim();
      final newConfig = ServerConfig(serverUrl: url, authToken: authToken);
      final saveSuccess = await ref
          .read(serverConfigProvider.notifier)
          .saveToPreferences(newConfig);

      if (!saveSuccess && mounted) {
        _showResultDialog(
          'Error',
          'Failed to save settings before testing.',
          isError: true,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      ref.invalidate(apiServiceProvider); // Re-init the service
      setState(() {
        _hasChanges = false;
        _initialConfig = newConfig;
        // Keep isLoading = true for the test phase
      });
    }

    // Now test the connection
    setState(() {
      _isTesting = true;
      _isLoading = true;
    }); // Use _isTesting specifically
    final apiService = ref.read(apiServiceProvider);
    
    try {
      // Use a lightweight API call, like fetching user status or workspace setting
      // Replace getAuthStatus with a known working call, limited to 1 result
      await apiService.listMemos(pageSize: 1, parent: 'users/1');

      if (mounted) {
        _showResultDialog('Success', 'Connection successful!');
      }
    } catch (e) {
      if (kDebugMode) {
        print("[SettingsScreen] Test Connection Error: $e");
      }
      if (mounted) {
        _showResultDialog(
          'Connection Failed',
          'Could not connect to the server. Please check the URL and token.\n\nError: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _isLoading = false;
        });
      }
    }
  }

  void _resetToDefaults() {
    setState(() {
      _serverUrlController.text = 'http://localhost:5230';
      _authTokenController.text = '';
      _checkForChanges(); // This will also re-validate
    });
  }

  Future<void> _pasteTokenFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null && mounted) {
      _authTokenController.text = clipboardData!.text!;
      _checkForChanges();
      _showResultDialog('Pasted', 'Token pasted from clipboard.');
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

  @override
  Widget build(BuildContext context) {
    // Use CupertinoTheme for brightness check if needed, or rely on resolveFrom
    // final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    // Determine if the back button should be automatically implied
    // It should NOT be implied if this is the initial setup screen
    final bool automaticallyImplyLeading = !widget.isInitialSetup;

    return GestureDetector(
      // Dismiss keyboard on tap outside fields
      onTap: () => FocusScope.of(context).unfocus(),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.isInitialSetup ? 'Server Setup' : 'Settings'),
          // Conditionally hide the default back button during initial setup
          automaticallyImplyLeading: automaticallyImplyLeading,
          // Add Save button to nav bar, enabled only when changes exist or initial setup
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed:
                (_hasChanges || widget.isInitialSetup) && !_isLoading
                    ? _saveConfiguration
                    : null,
            child:
                _isLoading && !_isTesting
                    ? const CupertinoActivityIndicator()
                    : Text(widget.isInitialSetup ? 'Connect' : 'Save'),
          ),
        ),
        child: SafeArea(
          child: ListView(
            // Use ListView directly for scrolling content
            padding: const EdgeInsets.only(top: 16.0), // Add padding at the top
            children: [
              // Show a prompt during initial setup
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
                            'Please enter your Memos server details to get started.',
                            style: TextStyle(color: CupertinoColors.systemBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Server Configuration Section
              CupertinoFormSection.insetGrouped(
                header: const Text('SERVER CONFIGURATION'),
                children: [
                  CupertinoFormRow(
                    prefix: const Text('Server URL'),
                    child: CupertinoTextField(
                      controller: _serverUrlController,
                      placeholder: 'http://localhost:5230',
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      textInputAction: TextInputAction.next,
                      // onChanged: (value) => _validateUrl(value), // Validate on change
                    ),
                  ),
                  if (_serverUrlError != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 15.0,
                        right: 15.0,
                        top: 4.0,
                        bottom: 4.0,
                      ),
                      child: Text(
                        _serverUrlError!,
                        style: TextStyle(
                          color: CupertinoColors.systemRed.resolveFrom(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  CupertinoFormRow(
                    prefix: const Text('Auth Token'),
                    child: CupertinoTextField(
                      controller: _authTokenController,
                      placeholder: 'Enter access token',
                      obscureText: true,
                      autocorrect: false,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      textInputAction: TextInputAction.done,
                      onSubmitted:
                          (_) => _hasChanges ? _saveConfiguration() : null,
                    ),
                  ),
                  if (_tokenError !=
                      null) // Optional: Add error display for token if needed
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 15.0,
                        right: 15.0,
                        top: 4.0,
                        bottom: 4.0,
                      ),
                      child: Text(
                        _tokenError!,
                        style: TextStyle(
                          color: CupertinoColors.systemRed.resolveFrom(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),

              // Action Buttons Section - Conditionally show based on initial setup
              if (!widget.isInitialSetup)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _resetToDefaults,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.restart, size: 18),
                            SizedBox(width: 4),
                            Text('Reset Defaults'),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _pasteTokenFromClipboard,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.doc_on_clipboard, size: 18),
                            SizedBox(width: 4),
                            Text('Paste Token'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Add Paste Token button separately for initial setup if desired
              if (widget.isInitialSetup)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 0.0,
                  ), // Reduced vertical padding
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _pasteTokenFromClipboard,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.doc_on_clipboard, size: 18),
                          SizedBox(width: 4),
                          Text('Paste Token'),
                        ],
                      ),
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
                            'Connection Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The server URL should point to your Memos server installation. '
                        'For local development, use http://localhost:5230.\n\n'
                        'The authentication token (Access Token) can be created in your Memos server under Settings > My Account.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Test Connection Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: _isLoading ? null : _testConnection,
                  child:
                      _isLoading && _isTesting
                          ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                          : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.link),
                              SizedBox(width: 8),
                              Text('Test Connection'),
                            ],
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
