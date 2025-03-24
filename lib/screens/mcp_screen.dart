import 'package:flutter/material.dart';
import 'package:flutter_memos/services/mcp_service.dart';
import 'package:flutter_memos/utils/env.dart';
import 'package:flutter_memos/widgets/mcp_demo_widget.dart';

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
      print('Testing MCP connection with URL: ${Env.mcpServerUrl}');
      print('MCP key present: ${Env.mcpServerKey.isNotEmpty ? "Yes" : "No"}');
      
      if (Env.mcpServerKey.isNotEmpty) {
        print('MCP key length: ${Env.mcpServerKey.length}');
        print('MCP key trimmed length: ${Env.mcpServerKey.trim().length}');
      }

      final response = await _mcpService.pingMcpServer();
      
      setState(() {
        _pingResult = response;
        _loading = false;
      });
      
      print('MCP Server ping successful: $response');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      
      print('Error pinging MCP server: $e');
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('MCP Server Error'),
          content: Text(
            'Failed to connect to the MCP server at ${Env.mcpServerUrl}. '
            'Error: ${e.toString()}\n\n'
            'Note: If using Docker, make sure you\'re not using \'localhost\' in your URL, '
            'as Docker containers need to reference each other by service name (e.g., \'mcp-server:8080\').'
          ),
          actions: [
            TextButton(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content first')),
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
      print('MCP Memo creation successful: $response');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Memo created successfully via MCP server'),
          actions: [
            TextButton(
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
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to create memo: ${e.toString()}'),
          actions: [
            TextButton(
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

    final tokenValue = Env.mcpServerKey;
    final tokenTrimmed = tokenValue.trim();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[400]!),
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
            color: Colors.grey[300],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP Server Integration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MCP Server Integration',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 20),
            
            // Server Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Server Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    
                    // Display configuration status
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text(
                                'MCP Server URL:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Env.mcpServerUrl.isNotEmpty
                                    ? Env.mcpServerUrl
                                    : 'Not configured',
                                style: TextStyle(
                                  color: Env.mcpServerUrl.isNotEmpty
                                      ? const Color(0xFF555555)
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'MCP Server Key:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    Env.mcpServerKey.isNotEmpty
                                        ? 'Configured (length: ${Env.mcpServerKey.length}, last 4: ${Env.mcpServerKey.substring(Env.mcpServerKey.length - 4)})'
                                        : 'Not configured',
                                    style: TextStyle(
                                      color: Env.mcpServerKey.isNotEmpty
                                          ? const Color(0xFF555555)
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF0079BF),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showTokenDebug = !_showTokenDebug;
                                  });
                                },
                                child: Text(
                                  _showTokenDebug ? 'Hide Debug' : 'Debug',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    _renderTokenDebug(),
                    
                    if (_loading && _pingResult == null)
                      const Center(child: CircularProgressIndicator())
                    else if (_error != null && _pingResult == null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Error: $_error',
                              style: TextStyle(color: Colors.red[800]),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _testMcpConnection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC4C3E),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry Connection'),
                            ),
                          ],
                        ),
                      )
                    else if (_pingResult != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: 'Status: ',
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  TextSpan(
                                    text: _pingResult!['status'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: _pingResult!['status'] == 'error'
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                text: 'Message: ',
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  TextSpan(
                                    text: _pingResult!['message'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                text: 'Server Time: ',
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  TextSpan(
                                    text: _pingResult!['timestamp'] != null
                                        ? DateTime.parse(_pingResult!['timestamp']).toString()
                                        : 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
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
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Send Memo Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Send a Test Memo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Enter memo content...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                      maxLines: 5,
                      onChanged: (value) {
                        setState(() {
                          _inputText = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC4C3E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _loading ? null : _handleSendMemo,
                        child: const Text('Send via MCP'),
                      ),
                    ),
                    if (_loading && _pingResult != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Demo Component
            const McpDemoWidget(),
          ],
        ),
      ),
    );
  }
}
