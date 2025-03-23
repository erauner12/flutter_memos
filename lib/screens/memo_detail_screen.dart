import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for memo details
final memoDetailProvider = FutureProvider.family<Memo, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMemo(id);
});

// Provider for memo comments
final memoCommentsProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  memoId,
) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.listMemoComments(memoId);
});

// Provider for adding a comment
final addCommentProvider =
    Provider.family<Future<void> Function(Comment), String>((ref, memoId) {
      return (Comment comment) async {
        final apiService = ref.read(apiServiceProvider);
        await apiService.createMemoComment(memoId, comment);
        ref.invalidate(memoCommentsProvider(memoId)); // Refresh comments
      };
    });

class MemoDetailScreen extends ConsumerStatefulWidget {
  final String memoId;

  const MemoDetailScreen({
    super.key,
    required this.memoId,
  });

  @override
  ConsumerState<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends ConsumerState<MemoDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  
  // Keep these fields for proper state management
  Memo? _memo;
  List<Comment> _comments = [];
  bool _submittingComment = false;

  @override
  void initState() {
    super.initState();
    // No need to fetch explicitly - Riverpod will handle this
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  // We'll use the providers to fetch data instead of these methods

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
      
      // Use the provider to add a comment
      await ref.read(addCommentProvider(widget.memoId))(newComment);
      
      _commentController.clear();
      _commentFocusNode.unfocus(); // Clear focus after posting
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingComment = false;
        });
      }
    }
  }

  void _copyToClipboard(Memo memo, List<Comment> comments) {
    // Build clipboard content
    String clipboardContent = '${memo.content}\n\n';

    // Add comments in chronological order
    if (comments.isNotEmpty) {
      clipboardContent += 'Comments:\n';
      for (int i = 0; i < comments.length; i++) {
        final comment = comments[i];
        final timestamp = comment.createTime != null
            ? DateTime.fromMillisecondsSinceEpoch(comment.createTime!).toString()
            : 'Unknown time';
        clipboardContent += '${i + 1}. ${comment.content} ($timestamp)\n';
      }
    }

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: clipboardContent)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memo content and comments copied to clipboard'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memo Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit-memo',
                arguments: {'memoId': widget.memoId},
              ).then((_) {
                // Refresh data when returning from edit screen
                ref.invalidate(memoDetailProvider(widget.memoId));
                ref.invalidate(memoCommentsProvider(widget.memoId));
              });
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final memoAsync = ref.watch(memoDetailProvider(widget.memoId));
    final commentsAsync = ref.watch(memoCommentsProvider(widget.memoId));
    
    // First make sure the memo is loaded
    return memoAsync.when(
      data: (memo) {
        // Store the memo in state for any local UI that might need it
        if (_memo == null || _memo!.id != memo.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _memo = memo;
              });
            }
          });
        }
        
        // We have the memo data, now check comments
        return commentsAsync.when(
          data: (comments) {
            // Update comments in state if needed
            if (!listEquals(_comments, comments)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _comments = comments;
                  });
                }
              });
            }
            
            // We have both memo and comments
            return _buildContent(memo, comments);
          },
          loading: () => _buildContent(memo, _comments.isEmpty ? [] : _comments), // Use cached comments if we have them
          error:
              (error, __) => _buildContent(
                memo,
                _comments.isEmpty ? [] : _comments,
              ), // Use cached comments if we have them
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
  
  Widget _buildContent(Memo memo, List<Comment> comments) {
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
                  memo.content,
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
                    onPressed: () => _copyToClipboard(memo, comments),
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
            '${memo.state == MemoState.archived ? "Archived" : "Active"} | Visibility: ${memo.visibility}',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        
        if (memo.pinned)
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
        
        if (comments.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'No comments yet.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),

        // Comments List
        ...comments.reversed.map(
          (comment) => Card(
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
                        ? DateTime.fromMillisecondsSinceEpoch(
                          comment.createTime!,
                        ).toString()
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
                  focusNode: _commentFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
                  maxLines: 3,
                  onSubmitted: (_) {
                    if (!_submittingComment && _commentController.text.trim().isNotEmpty) {
                      _handleAddComment();
                    }
                  },
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
