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
  bool _isActive = false; // Default for new servers
  List<_EnvVarPair> _envVars = [];

  bool get _isEditing => widget.serverToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final server = widget.serverToEdit!;
      _nameController.text = server.name;
      _commandController.text = server.command;
      _argsController.text = server.args;
      _isActive = server.isActive;
      _envVars = server.customEnvironment.entries
          .map((e) => _EnvVarPair.fromMapEntry(e))
          .toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _argsController.dispose();
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

    final name = _nameController.text.trim();
    final command = _commandController.text.trim();
    final args = _argsController.text.trim();

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
        // Allow empty key only if value is also empty (effectively ignoring the row)
         _showResultDialog('Validation Error', 'Environment variable key cannot be empty if value is set.', isError: true);
         envVarError = true;
         break;
      }
    }

    if (envVarError) return;

    final config = McpServerConfig(
      id: widget.serverToEdit?.id ?? _uuid.v4(), // Use existing ID or generate new
      name: name,
      command: command,
      args: args,
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

      if (success && mounted) {
        _showResultDialog('Success', 'MCP Server "$name" $actionVerb.');
        Navigator.of(context).pop(); // Go back to settings screen
      } else if (!success && mounted) {
        _showResultDialog('Error', 'Failed to $actionVerb MCP server configuration.', isError: true);
      }
    } catch (e) {
       if (mounted) {
         _showResultDialog('Error', 'An error occurred while saving: ${e.toString()}', isError: true);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(_isEditing ? 'Edit MCP Server' : 'Add MCP Server'),
          // leading: Automatically implied back button
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
                      controller: _commandController,
                      placeholder: r'/path/to/server or C:\path\server.exe',
                      prefix: const Text('Command*'),
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Server Command cannot be empty'
                          : null,
                    ),
                    CupertinoTextFormFieldRow(
                      controller: _argsController,
                      placeholder: '--port 1234 --verbose (Optional)',
                      prefix: const Text('Arguments'),
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                    ),
                     CupertinoListTile(
                       padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
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
                        padding: const EdgeInsets.only(right: 0), // Align add button
                        minSize: 0,
                        onPressed: _addEnvVar,
                        child: const Icon(CupertinoIcons.add_circled, size: 22),
                      ),
                    ],
                  ),
                  footer: const Padding(
                     padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 4.0),
                     child: Text(
                       'Variables passed to the server process. Overrides system variables if names conflict.',
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
                      // Build rows for existing env vars
                      ..._envVars.map((pair) => _buildEnvVarRow(pair)),
                  ],
                ),
                // Add Delete button only when editing
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: CupertinoButton(
                      color: CupertinoColors.destructiveRed,
                      onPressed: () async {
                        final confirmed = await showCupertinoDialog<bool>(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('Delete MCP Server?'),
                            content: Text(
                                'Are you sure you want to delete "${widget.serverToEdit!.name}"?'),
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
                          final success = await ref
                              .read(settingsServiceProvider)
                              .deleteMcpServer(widget.serverToEdit!.id);
                          if (success && mounted) {
                             _showResultDialog('Deleted', 'MCP Server "${widget.serverToEdit!.name}" deleted.');
                            Navigator.of(context).pop(); // Pop back to settings
                          } else if (!success && mounted) {
                            _showResultDialog('Error', 'Failed to delete MCP server.', isError: true);
                          }
                        }
                      },
                      child: const Text('Delete Server'),
                    ),
                  ),
                 const SizedBox(height: 30), // Bottom padding
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
      key: ValueKey(pair.id), // Important for stateful updates in list
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
