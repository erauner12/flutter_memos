import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NewMemoScreen extends StatefulWidget {
  const NewMemoScreen({Key? key}) : super(key: key);

  @override
  State<NewMemoScreen> createState() => _NewMemoScreenState();
}

class _NewMemoScreenState extends State<NewMemoScreen> {
  final _controller = TextEditingController();
  bool loading = false;
  String? error;

  void _createMemo() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      setState(() {
        error = "Please enter some content.";
      });
      return;
    }

    setState(() {
      error = null;
      loading = true;
    });

    try {
      await ApiService.instance.createMemo(content);
      if (!mounted) return;
      Navigator.pop(context); // go back to the memos list
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Memo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: "Enter your memo content...",
              ),
            ),
            const SizedBox(height: 12),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createMemo,
                    child: const Text("Create Memo"),
                  ),
          ],
        ),
      ),
    );
  }
}