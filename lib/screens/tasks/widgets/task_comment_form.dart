import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/task_comment_providers.dart'; // Use task comment providers
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskCommentForm extends ConsumerStatefulWidget {
  final String taskId;

  const TaskCommentForm({super.key, required this.taskId});

  @override
  ConsumerState<TaskCommentForm> createState() => _TaskCommentFormState();
}

class _TaskCommentFormState extends ConsumerState<TaskCommentForm> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isPosting) {
      return;
    }

    setState(() {
      _isPosting = true;
    });

    final newComment = Comment(
      id: '', // ID will be assigned by the backend
      content: content,
      parentId: widget.taskId,
      serverId: '', // Server ID context comes from the provider/API service
      createdTs: DateTime.now(), // Placeholder, backend sets actual time
      // Other fields like creatorId, pinned, state are not set on creation
    );

    try {
      // Use the createTaskCommentProvider
      await ref.read(createTaskCommentProvider((taskId: widget.taskId)))(newComment);
      _controller.clear();
      _focusNode.unfocus(); // Hide keyboard after successful post
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to post comment: $e'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 8.0 + bottomPadding, // Adjust for keyboard
      ),
      decoration: BoxDecoration(
        color: theme.barBackgroundColor,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _controller,
              focusNode: _focusNode,
              placeholder: 'Add a comment...',
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline, // Allows multiline input
              keyboardType: TextInputType.multiline,
              onSubmitted: (_) => _submitComment(), // Allow submitting with keyboard action
              style: theme.textTheme.textStyle,
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: CupertinoColors.systemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            onPressed: _isPosting ? null : _submitComment,
            child: _isPosting
                ? const CupertinoActivityIndicator(radius: 12)
                : const Text('Post'),
          ),
        ],
      ),
    );
  }
}
