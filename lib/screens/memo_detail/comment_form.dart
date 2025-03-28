import 'package:flutter/material.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memo_detail_providers.dart';

class CommentForm extends ConsumerStatefulWidget {
  final String memoId;

  const CommentForm({
    super.key,
    required this.memoId,
  });

  @override
  ConsumerState<CommentForm> createState() => _CommentFormState();
}

class _CommentFormState extends ConsumerState<CommentForm> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _submittingComment = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _showMarkdownHelp() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Markdown Syntax'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHelpRow('**Bold**', 'Bold'),
                  _buildHelpRow('*Italic*', 'Italic'),
                  _buildHelpRow('[Link](url)', 'Link'),
                  _buildHelpRow('# Heading', 'Heading'),
                  _buildHelpRow('- List item', 'List item'),
                  _buildHelpRow('1. Numbered', 'Numbered list'),
                  _buildHelpRow('> Quote', 'Blockquote'),
                  _buildHelpRow('`Code`', 'Code'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildHelpRow(String syntax, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            syntax,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Text('→ $description'),
        ],
      ),
    );
  }

  Future<void> _handleAddComment() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _submittingComment = true;
    });

    try {
      final newComment = Comment(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        content: _controller.text.trim(),
        creatorId: '1', // Default user ID
        createTime: DateTime.now().millisecondsSinceEpoch,
      );
      
      // Use the provider to add a comment
      await ref.read(addCommentProvider(widget.memoId))(newComment);
      
      if (mounted) {
        _controller.clear();
        _focusNode.unfocus(); // Clear focus after posting
      }
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(10),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.text_format),
                  tooltip: 'Markdown formatting',
                  onPressed: _showMarkdownHelp,
                ),
              ),
              maxLines: 3,
              onSubmitted: (_) {
                if (!_submittingComment && _controller.text.trim().isNotEmpty) {
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
    );
  }
}
