import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class MemoDetailScreen extends StatefulWidget {
  const MemoDetailScreen({Key? key}) : super(key: key);

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  Memo? memo;
  List<MemoComment> comments = [];
  bool loading = false;
  String? error;

  final _commentController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final memoId = ModalRoute.of(context)?.settings.arguments as String?;
    if (memoId != null) {
      _fetchMemoDetail(memoId);
      _fetchComments(memoId);
    } else {
      setState(() {
        error = "No memo ID provided.";
      });
    }
  }

  void _fetchMemoDetail(String id) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final m = await ApiService.instance.getMemo(id);
      setState(() {
        memo = m;
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

  void _fetchComments(String id) async {
    setState(() {
      loading = true;
    });
    try {
      final list = await ApiService.instance.listMemoComments(id);
      setState(() {
        comments = list;
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

  void _addComment() async {
    final memoId = memo?.id;
    if (memoId == null || _commentController.text.trim().isEmpty) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await ApiService.instance.addCommentToMemo(memoId, _commentController.text.trim());
      _commentController.clear();
      _fetchComments(memoId);
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

  void _copyAll() {
    if (memo == null) return;
    final buffer = StringBuffer();
    buffer.writeln(memo!.content);
    if (comments.isNotEmpty) {
      buffer.writeln("\nComments:");
      for (int i = 0; i < comments.length; i++) {
        buffer.writeln("${i + 1}. ${comments[i].content}");
      }
    }
    Clipboard.setData(ClipboardData(text: buffer.toString())).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Memo content copied!")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final memoId = memo?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Memo Detail"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/editMemo', arguments: memoId)
                .then((_) {
                  if (memoId.isNotEmpty) {
                    _fetchMemoDetail(memoId);
                  }
                });
            },
          )
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
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              memo!.content,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _copyAll,
                                  child: const Text("Copy All"),
                                ),
                                const SizedBox(width: 10),
                                if (memo!.state == V1State.archived)
                                  const Text(
                                    "Archived",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                if (memo!.pinned)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text("Pinned", style: TextStyle(color: Colors.blue)),
                                  ),
                              ],
                            ),
                            const Divider(height: 30),
                            Text(
                              "Comments",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (comments.isEmpty)
                              const Text("No comments yet.")
                            else
                              ...comments.reversed.map(
                                (c) => Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.grey.shade200,
                                  child: Text(c.content),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: const InputDecoration(
                                      hintText: "Add a comment...",
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: _addComment,
                                ),
                              ],
                            ),
                            if (loading)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            if (error != null && !loading)
                              Text(
                                "Error: $error",
                                style: const TextStyle(color: Colors.red),
                              ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}