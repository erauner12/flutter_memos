import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/services/mcp_service.dart';
import 'package:flutter_memos/utils/env.dart';
import 'package:flutter_memos/widgets/mcp_demo_widget.dart'; // Assuming this is also migrated

class McpScreen extends StatefulWidget {
  const McpScreen({super.key});

  @override
  State<McpScreen> createState() => _McpScreenState();
}

class _McpScreenState extends State<McpScreen> {
  final McpService _mcpService = McpService();
  final TextEditingController _inputController = TextEditingController();

  Map<String, dynamic>? _pingResult;
  bool _loading = false;
  String? _error;
  String _inputText = 'Test memo via MCP';
  bool _showTokenDebug = false;

  @override
  void initState() {
    super.initState();
    _testMcpConnection();
    _inputController.text = _inputText;
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _testMcpConnection() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _mcpService.pingMcpServer();

      setState(() {
        _pingResult = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });

      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
          title: const Text('MCP Server Error'),
          content: Text(
                'Failed to connect to the MCP server at ${Env.apiBaseUrl}. '
            'Error: ${e.toString()}\n\n'
            'Note: If using Docker, make sure you\'re not using \'localhost\' in your URL, '
                'as Docker containers need to reference each other by service name (e.g., \'mcp-server:8080\').',
          ),
          actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleSendMemo() async {
    if (_inputController.text.trim().isEmpty) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Input Required'),
              content: const Text('Please enter some content first.'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final memoData = {
        'creator': 'users/1', // Default Memos user
        'content': _inputController.text.trim(),
        'visibility': 'PUBLIC',
      };

      final response = await _mcpService.sendToMcp(memoData, target: 'memos');

      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
          title: const Text('Success'),
          content: const Text('Memo created successfully via MCP server'),
          actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                _inputController.clear();
                setState(() {
                  _inputText = '';
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });

      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Failed to create memo: ${e.toString()}'),
          actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _renderTokenDebug() {
    if (!_showTokenDebug) return const SizedBox.shrink();

    final tokenValue = Env.memosApiKey;
    final tokenTrimmed = tokenValue.trim();

    final Color backgroundColor = CupertinoColors.secondarySystemFill
        .resolveFrom(context);
    final Color borderColor = CupertinoColors.separator.resolveFrom(context);
    final Color codeBackgroundColor = CupertinoColors.tertiarySystemFill
        .resolveFrom(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Token Debug Info',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text('Raw length: ${tokenValue.length}'),
          Text('Trimmed length: ${tokenTrimmed.length}'),
          Text('First char code: ${tokenValue.isNotEmpty ? tokenValue.codeUnitAt(0) : "N/A"}'),
          Text('Last char code: ${tokenValue.isNotEmpty ? tokenValue.codeUnitAt(tokenValue.length - 1) : "N/A"}'),
          Text('Has whitespace: ${tokenValue != tokenTrimmed ? "Yes" : "No"}'),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            color: codeBackgroundColor,
            child: Text(
              tokenValue.split('').map((c) => c == ' ' ? '␣' : c).join(''),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('MCP Server Integration'),
        transitionBetweenRoutes: false,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: Text(
                'MCP Server Integration',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.label,
                ),
              ),
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('SERVER STATUS'),
              children: [
                CupertinoListTile(
                  title: const Text('MCP Server URL'),
                  subtitle: Text(
                    Env.apiBaseUrl.isNotEmpty
                        ? Env.apiBaseUrl
                        : 'Not configured',
                    style: TextStyle(
                      color:
                          Env.apiBaseUrl.isNotEmpty
                              ? CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              )
                              : CupertinoColors.systemRed.resolveFrom(context),
                    ),
                  ),
                ),
                CupertinoListTile(
                  title: const Text('MCP Server Key'),
                  subtitle: Text(
                    Env.memosApiKey.isNotEmpty
                        ? 'Configured (length: ${Env.memosApiKey.length}, last 4: ${Env.memosApiKey.substring(Env.memosApiKey.length - 4)})'
                        : 'Not configured',
                    style: TextStyle(
                      color:
                          Env.memosApiKey.isNotEmpty
                              ? CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              )
                              : CupertinoColors.systemRed.resolveFrom(context),
                    ),
                  ),
                  trailing: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minSize: 0,
                    color: CupertinoTheme.of(context).primaryColor,
                    onPressed: () {
                      setState(() {
                        _showTokenDebug = !_showTokenDebug;
                      });
                    },
                    child: Text(
                      _showTokenDebug ? 'Hide Debug' : 'Debug',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (_showTokenDebug)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15.0,
                      vertical: 8.0,
                    ),
                    child: _renderTokenDebug(),
                  ),
                if (_loading && _pingResult == null)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else if (_error != null && _pingResult == null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed
                          .resolveFrom(context)
                          .withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Error: $_error',
                          style: TextStyle(
                            color: CupertinoColors.systemRed.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        CupertinoButton.filled(
                          onPressed: _testMcpConnection,
                          child: const Text('Retry Connection'),
                        ),
                      ],
                    ),
                  )
                else if (_pingResult != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: 'Status: ',
                            style: TextStyle(
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                            children: [
                              TextSpan(
                                text: _pingResult!['status'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color:
                                      _pingResult!['status'] == 'error'
                                          ? CupertinoColors.systemRed
                                              .resolveFrom(context)
                                          : CupertinoColors.label.resolveFrom(
                                            context,
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            text: 'Message: ',
                            style: TextStyle(
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                            children: [
                              TextSpan(
                                text: _pingResult!['message'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.label.resolveFrom(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            text: 'Server Time: ',
                            style: TextStyle(
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                            children: [
                              TextSpan(
                                text:
                                    _pingResult!['timestamp'] != null
                                        ? DateTime.parse(
                                          _pingResult!['timestamp'],
                                        ).toString()
                                        : 'N/A',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.label.resolveFrom(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoListSection.insetGrouped(
              header: const Text('SEND A TEST MEMO'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 10.0,
                  ),
                  child: CupertinoTextField(
                    controller: _inputController,
                    placeholder: 'Enter memo content...',
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemFill.resolveFrom(context),
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    maxLines: 5,
                    minLines: 3,
                    keyboardType: TextInputType.multiline,
                    onChanged: (value) {
                      setState(() {
                        _inputText = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 10.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: _loading ? null : _handleSendMemo,
                      child: const Text('Send via MCP'),
                    ),
                  ),
                ),
                if (_loading && _pingResult != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 16),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const McpDemoWidget(),
          ],
        ),
      ),
    );
  }
}
