import 'package:flutter/material.dart';
import '../services/mcp_service.dart';

class McpScreen extends StatefulWidget {
  const McpScreen({Key? key}) : super(key: key);

  @override
  State<McpScreen> createState() => _McpScreenState();
}

class _McpScreenState extends State<McpScreen> {
  bool loading = false;
  String? error;
  Map<String, dynamic>? pingResult;

  final _inputController = TextEditingController(text: "Test memo via MCP");
  Map<String, dynamic>? fetchResult;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      loading = true;
      error = null;
      pingResult = null;
    });
    try {
      final resp = await McpService.instance.pingMcpServer();
      setState(() {
        pingResult = resp;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _sendMemo() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        error = "Please enter some text first.";
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final body = {
        "creator": "users/1",
        "content": text,
        "visibility": "PUBLIC",
      };
      final resp = await McpService.instance.sendToMcp(body, target: "memos");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Memo created via MCP server!")),
      );
      setState(() {
        fetchResult = resp;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _fetchMemos() async {
    setState(() {
      loading = true;
      error = null;
      fetchResult = null;
    });
    try {
      final resp = await McpService.instance.fetchFromMcp("memos");
      setState(() {
        fetchResult = resp;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Widget _buildResultArea() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Column(
        children: [
          Text("Error: $error", style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: _testConnection, child: const Text("Retry")),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pingResult != null)
          Text("Ping: ${pingResult.toString()}", style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        if (fetchResult != null)
          Text("Fetch: ${fetchResult.toString()}", style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MCP Integration"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (pingResult == null)
                ElevatedButton(
                  onPressed: _testConnection,
                  child: const Text("Ping MCP Server"),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _inputController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Enter memo content...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _sendMemo,
                child: const Text("Send via MCP"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchMemos,
                child: const Text("Fetch Memos from MCP"),
              ),
              const SizedBox(height: 16),
              _buildResultArea(),
            ],
          ),
        ),
      ),
    );
  }
}