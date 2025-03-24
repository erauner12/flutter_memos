import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  final _authTokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasChanges = false;
  ServerConfig? _initialConfig;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
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
  }

  void _checkForChanges() {
    final currentUrl = _serverUrlController.text.trim();
    final currentToken = _authTokenController.text.trim();
    final initialConfig = _initialConfig;
    
    if (initialConfig != null) {
      setState(() {
        _hasChanges = currentUrl != initialConfig.serverUrl ||
                      currentToken != initialConfig.authToken;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isLoading = true; });
    
    try {
      final serverUrl = _serverUrlController.text.trim();
      final authToken = _authTokenController.text.trim();
      
      final newConfig = ServerConfig(
        serverUrl: serverUrl,
        authToken: authToken,
      );
      
      final success = await ref.read(serverConfigProvider.notifier)
          .saveToPreferences(newConfig);
      
      if (success && mounted) {
        // Refresh the API service to use the new configuration
        ref.invalidate(apiServiceProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
        
        setState(() {
          _hasChanges = false;
          _initialConfig = newConfig;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
  
  void _resetToDefaults() {
    setState(() {
      _serverUrlController.text = 'http://localhost:5230';
      _authTokenController.text = '';
      _checkForChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Form(
        key: _formKey,
        onChanged: _checkForChanges,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Server configuration section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SERVER CONFIGURATION',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serverUrlController,
                      decoration: InputDecoration(
                        labelText: 'Memos Server URL',
                        hintText: 'http://localhost:5230',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _serverUrlController.clear();
                            _checkForChanges();
                          },
                        ),
                      ),
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Server URL is required';
                        }
                        if (!value.startsWith('http://') &&
                            !value.startsWith('https://')) {
                          return 'URL must start with http:// or https://';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _authTokenController,
                      decoration: InputDecoration(
                        labelText: 'Authentication Token',
                        hintText: 'Enter your JWT token',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _authTokenController.clear();
                            _checkForChanges();
                          },
                        ),
                      ),
                      obscureText: true,
                      autocorrect: false,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.restore),
                          label: const Text('Reset to Defaults'),
                          onPressed: _resetToDefaults,
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.content_paste),
                          label: const Text('Paste from Clipboard'),
                          onPressed: () async {
                            final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                            if (clipboardData?.text != null && mounted) {
                              // Try to paste as token by default
                              _authTokenController.text = clipboardData!.text!;
                              _checkForChanges();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Token pasted from clipboard')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Help text
            Card(
              color: isDarkMode ? Colors.grey[850] : Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔄 Connection Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The server URL should point to your Memos server installation. '
                      'For local development, use http://localhost:5230.\n\n'
                      'The authentication token should be a valid JWT token from your Memos server. '
                      'You can usually find this in your browser\'s localStorage after logging in to Memos.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Save and Test buttons container
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          _hasChanges && !_isLoading
                              ? _saveConfiguration
                              : null,
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Save Changes'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text('Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(90, 50),
                  ),
                  onPressed: () async {
                    // We’ll force-save first if there are unsaved changes
                    if (_hasChanges &&
                        !_isLoading &&
                        _formKey.currentState!.validate()) {
                      setState(() => _isLoading = true);
                      final serverUrl = _serverUrlController.text.trim();
                      final authToken = _authTokenController.text.trim();
                      final newConfig = ServerConfig(
                        serverUrl: serverUrl,
                        authToken: authToken,
                      );

                      final success = await ref
                          .read(serverConfigProvider.notifier)
                          .saveToPreferences(newConfig);

                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to save settings'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() => _isLoading = false);
                        return;
                      }
                      ref.invalidate(apiServiceProvider); // Re-init the service
                      setState(() {
                        _hasChanges = false;
                        _initialConfig = newConfig;
                        _isLoading = false;
                      });
                    }

                    // Now test the connection
                    // For example, call listMemos or any health-check endpoint
                    final apiService = ref.read(apiServiceProvider);
                    try {
                      setState(() => _isLoading = true);
                      final testMemos = await apiService.listMemos(
                        parent: 'users/1',
                        sort: 'createTime',
                        direction: 'DESC',
                      );
                      if (mounted) {
                        setState(() => _isLoading = false);
                        final count = testMemos.length;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Success! Found $count memos.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error testing connection: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
