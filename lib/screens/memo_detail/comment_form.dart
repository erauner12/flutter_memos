import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/comment_providers.dart'
    as comment_providers; // Add this import
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // Replace showDialog with showCupertinoDialog
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            // Use CupertinoAlertDialog
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
              // Replace TextButton with CupertinoDialogAction
              CupertinoDialogAction(
                isDefaultAction: true,
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
      
      // Use the new createCommentProvider to add a comment (which will also bump the parent memo)
      await ref.read(comment_providers.createCommentProvider(widget.memoId))(
        newComment,
      );
      
      if (mounted) {
        _controller.clear();
        _focusNode.unfocus(); // Clear focus after posting
      }
    } catch (e) {
      if (mounted) {
        // Replace SnackBar with CupertinoAlertDialog
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: Text('Failed to add comment: ${e.toString()}'),
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
    // Replace Card with styled Container
    return Container(
      margin: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      child: Column(
          children: [
          // Replace TextField with CupertinoTextField
          CupertinoTextField(
              controller: _controller,
              focusNode: _focusNode,
            placeholder: 'Add a comment...',
            placeholderStyle: TextStyle(
              color: CupertinoColors.placeholderText.resolveFrom(context),
            ),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CupertinoColors.systemFill.resolveFrom(context),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            // Add suffix for Markdown help button
            suffix: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              minSize: 0,
              onPressed: _showMarkdownHelp,
              child: Icon(
                CupertinoIcons.textformat_alt, // Use Cupertino icon
                size: 20,
                color: CupertinoTheme.of(context).primaryColor,
                ),
              ),
              maxLines: 3,
            keyboardType: TextInputType.multiline, // Ensure multiline keyboard
              onSubmitted: (_) {
                if (!_submittingComment && _controller.text.trim().isNotEmpty) {
                  _handleAddComment();
                }
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
            // Replace ElevatedButton with CupertinoButton.filled
            child: CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ), // Adjust padding
                onPressed: _submittingComment ? null : _handleAddComment,
                child: _submittingComment
                      // Replace CircularProgressIndicator with CupertinoActivityIndicator
                      ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white, // Ensure contrast
                        radius: 10, // Adjust size
                      )
                    : const Text('Post'),
              ),
            ),
        ],
      ),
    );
  }
}
