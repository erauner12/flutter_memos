import 'package:flutter/cupertino.dart';
// MODIFY: Ensure the model is imported
import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// Helper class for managing Key-Value pairs in the screen state
class _EnvVarPair {
  final String id; // Unique ID for list management
  final TextEditingController keyController;
  final TextEditingController valueController;

  _EnvVarPair()
      : id = _uuid.v4(),
        keyController = TextEditingController(),
        valueController = TextEditingController();

  _EnvVarPair.fromMapEntry(MapEntry<String, String> entry)
      : id = _uuid.v4(),
        keyController = TextEditingController(text: entry.key),
        valueController = TextEditingController(text: entry.value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class AddEditMcpServerScreen extends ConsumerStatefulWidget {
  final McpServerConfig? serverToEdit; // Null when adding a new server

  const AddEditMcpServerScreen({super.key, this.serverToEdit});

  @override
  ConsumerState<AddEditMcpServerScreen> createState() =>
      _AddEditMcpServerScreenState();
}

class _AddEditMcpServerScreenState extends ConsumerState<AddEditMcpServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  // Stdio Controllers
  final _commandController = TextEditingController();
  final _argsController = TextEditingController();
  // SSE Controllers
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  // Common State
  bool _isActive = false;
  List<_EnvVarPair> _envVars = [];
  // ADD: State variable for HTTPS toggle
  bool _isSecure = false;
  // MODIFY: Use the imported McpConnectionType enum
  McpConnectionType _selectedType = McpConnectionType.stdio; // Default to stdio

  bool get _isEditing => widget.serverToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final server = widget.serverToEdit!;
      _nameController.text = server.name;
      _selectedType = server.connectionType; // Initialize type from existing server
      // Load fields based on type, handling nulls
      _hostController.text = server.host ?? ''; // Load host if available
      _portController.text = server.port?.toString() ?? ''; // Use null-aware access and toString
      _commandController.text = server.command; // Always load command
      _argsController.text = server.args; // Always load args
      _isActive = server.isActive;
      _envVars = server.customEnvironment.entries
          .map((e) => _EnvVarPair.fromMapEntry(e))
          .toList();
      // Initialize isSecure from existing server (only relevant for SSE)
      _isSecure = server.isSecure;
    } else {
      // Defaults for a new server
      _selectedType = McpConnectionType.stdio; // Default new servers to stdio
      _isActive = false;
      _envVars = [];
      // Ensure controllers for the non-default type are empty
      _hostController.clear();
      _portController.clear();
      // Also clear stdio fields if defaulting to SSE (or vice versa if default changes)
      _commandController.clear();
      _argsController.clear();
      // Default isSecure for new servers
      _isSecure = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    _hostController.dispose();
    _portController.dispose();
    for (var pair in _envVars) {
      pair.dispose();
    }
    super.dispose();
  }

  void _addEnvVar() {
    setState(() {
      _envVars.add(_EnvVarPair());
    });
  }

  void _removeEnvVar(String id) {
    setState(() {
      final pairIndex = _envVars.indexWhere((p) => p.id == id);
      if (pairIndex != -1) {
        _envVars[pairIndex].dispose(); // Dispose controllers before removing
        _envVars.removeAt(pairIndex);
      }
    });
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

  Future<void> _saveConfiguration() async {
    if (!mounted) return;
    final contextBeforeGap = context; // Capture context before async gap

    FocusScope.of(contextBeforeGap).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // --- Validation based on selected type ---
    String command = '';
    String args = '';
    String? host;
    int? port;

    if (_selectedType == McpConnectionType.stdio) {
      command = _commandController.text.trim();
      args = _argsController.text.trim();
      if (command.isEmpty) {
        _showResultDialog(
          'Validation Error',
          'Command cannot be empty for Stdio connection.',
          isError: true,
        );
        return;
      }
    } else {
      // McpConnectionType.sse
      host = _hostController.text.trim();
      final portText = _portController.text.trim();
      if (host.isEmpty) {
        _showResultDialog(
          'Validation Error',
          'Manager Host cannot be empty for SSE connection.',
          isError: true,
        );
        return;
      }
      if (portText.isEmpty) {
        _showResultDialog(
          'Validation Error',
          'Manager Port cannot be empty for SSE connection.',
          isError: true,
        );
        return;
      }
      final parsedPort = int.tryParse(portText);
      if (parsedPort == null || parsedPort <= 0 || parsedPort > 65535) {
        _showResultDialog(
          'Validation Error',
          'Manager Port must be a valid number between 1 and 65535 for SSE connection.',
          isError: true,
        );
        return;
      }
      port = parsedPort;
    }

    final name = _nameController.text.trim();

    // Process environment variables
    final Map<String, String> customEnvMap = {};
    bool envVarError = false;
    for (var pair in _envVars) {
      final key = pair.keyController.text.trim();
      final value = pair.valueController.text;
      if (key.isNotEmpty) {
        if (customEnvMap.containsKey(key)) {
          _showResultDialog('Validation Error', 'Duplicate environment key "$key"', isError: true);
          envVarError = true;
          break;
        }
        customEnvMap[key] = value;
      } else if (value.isNotEmpty) {
        _showResultDialog(
          'Validation Error',
          'Environment variable key cannot be empty if value is set.',
          isError: true,
        );
        envVarError = true;
        break;
      }
    }

    if (envVarError) return;

    // MODIFY: Create config using the corrected constructor
    final config = McpServerConfig(
      id: widget.serverToEdit?.id ?? _uuid.v4(),
      name: name,
      connectionType: _selectedType,
      command: command,
      args: args,
      host: host,
      port: port,
      isActive: _isActive,
      customEnvironment: customEnvMap,
      // Pass the isSecure flag (only relevant for SSE, but pass always)
      isSecure: _isSecure,
    );

    final settingsService = ref.read(settingsServiceProvider);
    bool success;
    String actionVerb = _isEditing ? 'updated' : 'added';

    try {
      if (_isEditing) {
        success = await settingsService.updateMcpServer(config);
      } else {
        success = await settingsService.addMcpServer(config);
      }

      if (!mounted) return;

      if (success) {
        _showResultDialog('Success', 'MCP Server "$name" $actionVerb.');
        if (mounted) Navigator.of(context).pop();
      } else {
        _showResultDialog('Error', 'Failed to $actionVerb MCP server configuration.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        'Error',
        'An error occurred while saving: ${e.toString()}',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(_isEditing ? 'Edit MCP Server' : 'Add MCP Server'),
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
              children: [
                CupertinoFormSection.insetGrouped(
                  header: const Text('SERVER DETAILS'),
                  children: [
                    CupertinoTextFormFieldRow(
                      controller: _nameController,
                      placeholder: 'My Local AI Server',
                      prefix: const Text('Name*'),
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Server Name cannot be empty'
                          : null,
                    ),
                    // --- Connection Type Selector ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 15.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connection Type',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            // MODIFY: Use McpConnectionType enum here
                            child: CupertinoSegmentedControl<McpConnectionType>(
                              children: {
                                McpConnectionType.stdio: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Text('Stdio (Local)'),
                                ),
                                McpConnectionType.sse: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Text('SSE (Manager)'),
                                ),
                              },
                              groupValue: _selectedType,
                              onValueChanged: (McpConnectionType? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedType = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- Stdio Fields (Conditional) ---
                    if (_selectedType == McpConnectionType.stdio) ...[
                      CupertinoTextFormFieldRow(
                        controller: _commandController,
                        placeholder: '/path/to/mcp_server or dart',
                        prefix: const Text('Command*'),
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        validator: (value) {
                          if (_selectedType == McpConnectionType.stdio &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Command is required for Stdio';
                          }
                          return null;
                        },
                      ),
                      CupertinoTextFormFieldRow(
                        controller: _argsController,
                        placeholder: 'run /path/to/script.dart --port 8080',
                        prefix: const Text('Arguments'),
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                      ),
                    ],
                    // --- SSE Fields (Conditional) ---
                    if (_selectedType == McpConnectionType.sse) ...[
                      CupertinoTextFormFieldRow(
                        controller: _hostController,
                        placeholder: 'manager.example.com or 10.0.0.5',
                        prefix: const Text('Manager Host*'),
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (_selectedType == McpConnectionType.sse &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Manager Host is required for SSE';
                          }
                          return null;
                        },
                      ),
                      CupertinoTextFormFieldRow(
                        controller: _portController,
                        placeholder: '8999',
                        prefix: const Text('Manager Port*'),
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: false,
                        ),
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (_selectedType == McpConnectionType.sse) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Manager Port is required for SSE';
                            }
                            final port = int.tryParse(value.trim());
                            if (port == null || port <= 0 || port > 65535) {
                              return 'Invalid Port (1-65535)';
                            }
                          }
                          return null;
                        },
                      ),
                      // ADD: HTTPS Toggle for SSE
                      CupertinoListTile(
                        padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                        title: const Text('Use HTTPS (Secure)'),
                        trailing: CupertinoSwitch(
                          value: _isSecure,
                          onChanged: (value) => setState(() => _isSecure = value),
                        ),
                      ),
                    ],
                    // --- Common Fields ---
                    CupertinoListTile(
                      padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                      title: const Text('Connect on Apply'),
                      trailing: CupertinoSwitch(
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ),
                  ],
                ),
                CupertinoFormSection.insetGrouped(
                  header: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('CUSTOM ENVIRONMENT VARIABLES'),
                      CupertinoButton(
                        padding: const EdgeInsets.only(right: 0),
                        minSize: 0,
                        onPressed: _addEnvVar,
                        child: const Icon(CupertinoIcons.add_circled, size: 22),
                      ),
                    ],
                  ),
                  footer: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15.0,
                      vertical: 4.0,
                    ),
                    child: Text(
                      'Variables passed to the underlying server process (for Stdio) or potentially used by the Manager (for SSE).',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  children: [
                    if (_envVars.isEmpty)
                      const CupertinoListTile(
                        title: Center(
                          child: Text(
                            'No custom variables defined.',
                            style: TextStyle(color: CupertinoColors.inactiveGray),
                          ),
                        ),
                      )
                    else
                      ..._envVars.map((pair) => _buildEnvVarRow(pair)),
                  ],
                ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: CupertinoButton(
                      color: CupertinoColors.destructiveRed,
                      onPressed: (_isEditing && widget.serverToEdit != null)
                          ? () async {
                              if (!mounted) return;
                              final contextBeforeDialog = context;
                              final confirmed = await showCupertinoDialog<bool>(
                                context: contextBeforeDialog,
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text('Delete MCP Server?'),
                                  content: Text(
                                    'Are you sure you want to delete "${widget.serverToEdit!.name}"?',
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
                              if (!mounted) return;
                              if (confirmed == true) {
                                final success = await ref.read(settingsServiceProvider)
                                    .deleteMcpServer(widget.serverToEdit!.id);
                                if (!mounted) return;
                                if (success) {
                                  _showResultDialog(
                                    'Deleted',
                                    'MCP Server "${widget.serverToEdit!.name}" deleted.',
                                  );
                                  if (mounted) Navigator.of(context).pop();
                                } else {
                                  _showResultDialog(
                                    'Error',
                                    'Failed to delete MCP server.',
                                    isError: true,
                                  );
                                }
                              }
                            }
                          : null,
                      child: const Text('Delete Server'),
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper to build a row for an environment variable
  Widget _buildEnvVarRow(_EnvVarPair pair) {
    return Padding(
      key: ValueKey(pair.id),
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: CupertinoTextField(
              controller: pair.keyController,
              placeholder: 'VARIABLE_NAME',
              style: const TextStyle(fontSize: 14),
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.0),
            child: Text('=', style: TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: CupertinoTextField(
              controller: pair.valueController,
              placeholder: 'Value',
              style: const TextStyle(fontSize: 14),
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(left: 8),
            minSize: 0,
            child: Icon(
              CupertinoIcons.minus_circle,
              color: CupertinoColors.systemRed.resolveFrom(context),
              size: 22,
            ),
            onPressed: () => _removeEnvVar(pair.id),
          ),
        ],
      ),
    );
  }
}
