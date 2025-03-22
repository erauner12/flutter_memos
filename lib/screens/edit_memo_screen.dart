import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditMemoScreen extends StatefulWidget {
  const EditMemoScreen({Key? key}) : super(key: key);

  @override
  State<EditMemoScreen> createState() => _EditMemoScreenState();
}

class _EditMemoScreenState extends State<EditMemoScreen> {
  Memo? memo;
  bool loading = false;
  String? error;

  final _contentController = TextEditingController();
  bool archived = false;
  bool pinned = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final memoId = ModalRoute.of(context)?.settings.arguments as String?;
    if (memoId != null) {
      _fetchMemo(memoId);
    } else {
      setState(() {
        error = "No memo ID provided.";
      });
    }
  }

  void _fetchMemo(String id) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final m = await ApiService.instance.getMemo(id);
      setState(() {
        memo = m;
        _contentController.text = m.content;
        archived = (m.state == V1State.archived);
        pinned = m.pinned;
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

  void _handleSave() async {
    if (memo == null) return;
    setState(() {
      loading = true;
    });
    try {
      await ApiService.instance.updateMemo(
        memo!.id,
        content: _contentController.text.trim(),
        state: archived ? V1State.archived : V1State.normal,
        pinned: pinned,
      );
      if (!mounted) return;
      Navigator.pop(context);
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
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memoId = memo?.id ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Memo"),
        actions: [
          IconButton(
            onPressed: _handleSave,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: loading && memo == null
          ? const Center(child: CircularProgressIndicator())
          : error != null && memo == null
              ? Center(
                  child: Text(
                    "Error: $error",
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : memo == null
                  ? const Center(child: Text("No memo found."))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (error != null)
                              Text(
                                "Error: $error",
                                style: const TextStyle(color: Colors.red),
                              ),
                            TextField(
                              controller: _contentController,
                              maxLines: 8,
                              decoration: const InputDecoration(
                                labelText: "Content",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text("Pinned"),
                              value: pinned,
                              onChanged: (v) => setState(() => pinned = v),
                            ),
                            SwitchListTile(
                              title: const Text("Archived"),
                              value: archived,
                              onChanged: (v) => setState(() => archived = v),
                            ),
                            if (loading)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}