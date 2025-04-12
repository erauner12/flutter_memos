import 'package:flutter/cupertino.dart';
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

class _AddEditMcpServerScreenState
    extends ConsumerState<AddEditMcpServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commandController = TextEditingController();
  final _argsController = TextEditingController();
  // New controllers for TCP
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  bool _isActive = false; // Default for new servers
  List<_EnvVarPair> _envVars = [];

  bool get _isEditing => widget.serverToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final server = widget.serverToEdit!;
      _nameController.text = server.name;
      // Always load host and port regardless of type
      _hostController.text =
          server.host; // Direct assignment, host is non-nullable
      _portController.text = server.port.toString();
      _commandController.text =
          server.command; // Always load, might be hidden later
      _argsController.text = server.args; // Always load, might be hidden later
      _isActive = server.isActive;
      _envVars = server.customEnvironment.entries
          .map((e) => _EnvVarPair.fromMapEntry(e))
          .toList();
    } else {
      // Set defaults for new server if needed (e.g., _isActive = false)
      _isActive = false;
      _envVars = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    // Dispose new controllers
    _hostController.dispose();
    _portController.dispose();
    // Dispose environment variable controllers
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
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return; // Validation failed
    }

    // Simplified validation: always use Manager Host and Manager Port
    final host = _hostController.text.trim();
    final portText = _portController.text.trim();
    if (host.isEmpty) {
      _showResultDialog(
        'Validation Error',
        'Manager Host cannot be empty.',
        isError: true,
      );
      return;
    }
    if (portText.isEmpty) {
      _showResultDialog(
        'Validation Error',
        'Manager Port cannot be empty.',
        isError: true,
      );
      return;
    }
    final parsedPort = int.tryParse(portText);
    if (parsedPort == null || parsedPort <= 0 || parsedPort > 65535) {
      _showResultDialog(
        'Validation Error',
        'Manager Port must be a valid number between 1 and 65535.',
        isError: true,
      );
      return;
    }

    final name = _nameController.text.trim();

    // Process environment variables
    final Map<String, String> customEnvMap = {};
    bool envVarError = false;
    for (var pair in _envVars) {
      final key = pair.keyController.text.trim();
      final value = pair.valueController.text; // Keep value as is
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

    // Simplified config creation
    final config = McpServerConfig(
      id: widget.serverToEdit?.id ?? _uuid.v4(), // Use existing ID or generate new
      name: name,
      host: host,
      port: parsedPort,
      command: _commandController.text.trim(), // Pass value even if hidden
      args: _argsController.text.trim(), // Pass value even if hidden
      isActive: _isActive, // Use the state variable
      customEnvironment: customEnvMap,
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

      // Check mounted before using context
      if (!mounted) return;

      if (success) {
        _showResultDialog('Success', 'MCP Server "$name" $actionVerb.');
        // Check mounted again before popping
        if (mounted) Navigator.of(context).pop(); // Go back to settings screen
      } else {
        _showResultDialog('Error', 'Failed to $actionVerb MCP server configuration.', isError: true);
      }
    } catch (e) {
      // Check mounted before using context
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
                    CupertinoTextFormFieldRow(
                      controller: _hostController,
                      placeholder: 'manager.example.com or 10.0.0.5',
                      prefix: const Text('Manager Host*'),
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      validator:
                          (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Manager Host is required'
                                  : null,
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
                        if (value == null || value.trim().isEmpty) {
                          return 'Manager Port is required';
                        }
                        final port = int.tryParse(value.trim());
                        if (port == null || port <= 0 || port > 65535) {
                          return 'Invalid Port (1-65535)';
                        }
                        return null;
                      },
                    ),
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
                      'Variables passed by the MCP Manager to the underlying server process (if supported by the manager).',
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
                      onPressed:
                          (_isEditing && widget.serverToEdit != null)
                              ? () async {
                                final confirmed = await showCupertinoDialog<
                                  bool
                                >(
                                  context: context,
                                  builder:
                                      (context) => CupertinoAlertDialog(
                                        title: const Text('Delete MCP Server?'),
                                        content: Text(
                                          'Are you sure you want to delete "${widget.serverToEdit!.name}"?',
                                        ),
                                        actions: [
                                          CupertinoDialogAction(
                                            child: const Text('Cancel'),
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                          ),
                                          CupertinoDialogAction(
                                            isDestructiveAction: true,
                                            child: const Text('Delete'),
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirmed == true) {
                                  final success = await ref
                                      .read(settingsServiceProvider)
                                      .deleteMcpServer(widget.serverToEdit!.id);

                                  // Check mounted before using context
                                  if (!mounted) return;

                                  if (success) {
                                    _showResultDialog(
                                      'Deleted',
                                      'MCP Server "${widget.serverToEdit!.name}" deleted.',
                                    );
                                    // Check mounted again before popping
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
