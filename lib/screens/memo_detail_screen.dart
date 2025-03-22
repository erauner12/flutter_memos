import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';

class MemoDetailScreen extends StatefulWidget {
  final String memoId;

  const MemoDetailScreen({
    super.key,
    required this.memoId,
  });

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  
  Memo? _memo;
  List<Comment> _comments = [];
  bool _loading = false;
  bool _submittingComment = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMemo();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchMemo() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final memo = await _apiService.getMemo(widget.memoId);
      setState(() {
        _memo = memo;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load memo: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await _apiService.listMemoComments(widget.memoId);
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load comments: ${e.toString()}';
      });
    }
  }

  Future<void> _handleAddComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _submittingComment = true;
    });

    try {
      final newComment = Comment(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        content: _commentController.text.trim(),
        creatorId: '1', // Default user ID
      );
      
      await _apiService.createMemoComment(widget.memoId, newComment);
      _commentController.clear();
      await _fetchComments(); // Refresh comments
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _submittingComment = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_memo == null) return;

    // Build clipboard content
    String clipboardContent = '${_memo!.content}\n\n';

    // Add comments in chronological order
    if (_comments.isNotEmpty) {
      clipboardContent += 'Comments:\n';
      for (int i = 0; i < _comments.length; i++) {
        final comment = _comments[i];
        final timestamp = comment.createTime != null
            ? DateTime.fromMillisecondsSinceEpoch(comment.createTime!).toString()
            : 'Unknown time';
        clipboardContent += '${i + 1}. ${comment.content} ($timestamp)\n';
      }
    }

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: clipboardContent)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memo content and comments copied to clipboard')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memo Detail'),
        actions: [
          if (_memo != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/edit-memo',
                  arguments: {'memoId': widget.memoId},
                ).then((_) {
                  // Refresh data when returning from edit screen
                  _fetchMemo();
                  _fetchComments();
                });
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _memo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _memo == null) {
      return Center(
        child: Text(
          '$_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_memo == null) {
      return const Center(
        child: Text('No memo found.'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Memo Content
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _memo!.content,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy All'),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Memo Info
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '${_memo!.state == MemoState.archived ? "Archived" : "Active"} | Visibility: ${_memo!.visibility}',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        
        if (_memo!.pinned)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Pinned',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        
        // Divider
        const Divider(),
        
        // Comments Section
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Comments',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        
        if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'No comments yet.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),

        // Comments List
        ..._comments.reversed.map((comment) => Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.content),
                const SizedBox(height: 4),
                Text(
                  comment.createTime != null
                      ? DateTime.fromMillisecondsSinceEpoch(comment.createTime!).toString()
                      : 'Unknown time',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ),
        ),
        
        // Add Comment Section
        Card(
          margin: const EdgeInsets.only(top: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submittingComment ? null : _handleAddComment,
                    child: _submittingComment
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Post'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
