import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode
// Import material for ScaffoldMessenger/SnackBar OR use CupertinoDialogs exclusively
// import 'package:flutter/material.dart'; // Option 1: Import Material
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/providers/api_providers.dart'; // Import api providers
import 'package:flutter_memos/providers/comment_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart';
import 'package:flutter_memos/todoist_api/lib/api.dart'
    as todoist; // For error types
import 'package:flutter_memos/widgets/comment_card.dart'
    as BaseCard; // Use alias to avoid name clash
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemoComments extends ConsumerWidget {
  final String memoId;

  const MemoComments({super.key, required this.memoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(memoCommentsProvider(memoId));
    final selectedCommentIndex = ref.watch(selectedCommentIndexProvider);
    final hiddenCommentIds = ref.watch(hiddenCommentIdsProvider);
    final isMultiSelectMode = ref.watch(commentMultiSelectModeProvider);

    return commentsAsync.when(
      data: (comments) {
        final visibleComments =
            comments
                .where((c) => !hiddenCommentIds.contains('$memoId/${c.id}'))
                .toList();

        if (visibleComments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                'No comments yet.',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // Handled by parent scroll
          itemCount: visibleComments.length,
          itemBuilder: (context, index) {
            final comment = visibleComments[index];
            final isSelected =
                !isMultiSelectMode && index == selectedCommentIndex;

            // Pass ref down to CommentCard if it needs it for actions
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CommentCard(
                // Use the new CommentCard widget
                comment: comment,
                memoId: memoId,
                isSelected: isSelected,
              ),
            );
          },
        );
      },
      loading:
          () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CupertinoActivityIndicator(),
            ),
          ),
      error:
          (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Error loading comments: $error',
                style: TextStyle(
                  color: CupertinoColors.systemRed.resolveFrom(context),
                ),
              ),
            ),
          ),
    );
  }
}

// --- Make CommentCard a ConsumerStatefulWidget to handle its own state/actions ---
class CommentCard extends ConsumerStatefulWidget {
  final Comment comment;
  final String memoId;
  final bool isSelected;

  const CommentCard({
    super.key,
    required this.comment,
    required this.memoId,
    required this.isSelected,
  });

  @override
  ConsumerState<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends ConsumerState<CommentCard> {
  bool _isSendingToTodoist = false; // State for loading indicator

  // Helper to show dialogs safely after async gaps
  void _showDialog(String title, String content, {bool isError = false}) {
    if (!mounted) return; // Check mounted BEFORE using context
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(content),
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

  Future<void> _sendCommentToTodoist(Comment comment) async {
    final todoistService = ref.read(todoistApiServiceProvider);
    // final scaffoldMessenger = ScaffoldMessenger.of(context); // Removed - using dialogs

    // 1. Check if configured
    if (!todoistService.isConfigured) {
      _showDialog(
        'Todoist Not Configured',
        'Please add your Todoist API key in Settings > Integrations.',
        isError: true,
      );
      return;
    }

    // 2. Parse content
    final fullContent = comment.content.trim();
    if (fullContent.isEmpty) {
      _showDialog(
        'Empty Comment',
        'Cannot send empty comment to Todoist',
        isError: true,
      );
      return;
    }

    String taskContent;
    String? taskDescription;
    final newlineIndex = fullContent.indexOf('\n');

    if (newlineIndex != -1) {
      taskContent = fullContent.substring(0, newlineIndex).trim();
      taskDescription = fullContent.substring(newlineIndex + 1).trim();
      if (taskDescription.isEmpty) {
        taskDescription = null; // Ensure empty description is null
      }
    } else {
      taskContent = fullContent;
      taskDescription = null;
    }

    if (taskContent.isEmpty) {
      _showDialog(
        'Empty Title',
        'Cannot create Todoist task with empty title',
        isError: true,
      );
      return;
    }

    // 3. Show loading
    setState(() => _isSendingToTodoist = true);

    // 4. Call API
    try {
      if (kDebugMode) {
        print(
          '[Todoist Send] Creating task: "$taskContent" / Desc: "$taskDescription"',
        );
      }
      final createdTask = await todoistService.createTask(
        content: taskContent,
        description: taskDescription,
        // Add other default parameters if desired (e.g., projectId, labels)
      );

      if (kDebugMode) {
        print('[Todoist Send] Success! Task ID: ${createdTask.id}');
      }

      // 5. Show Success using dialog
      _showDialog(
        'Success',
        'Sent to Todoist: "${createdTask.content ?? 'Task'}"',
      );
    } on todoist.ApiException catch (e) {
      if (kDebugMode) {
        print('[Todoist Send] API Error: ${e.message} (Code: ${e.code})');
      }
      _showDialog(
        'Todoist Error',
        'Failed to create task.\n\nAPI Error ${e.code}: ${e.message ?? 'Unknown error'}',
        isError: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[Todoist Send] General Error: $e');
      }
      _showDialog(
        'Error',
        'An unexpected error occurred: ${e.toString()}',
        isError: true,
      );
    } finally {
      // Hide loading
      if (mounted) {
        setState(() => _isSendingToTodoist = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the imported BaseCommentCard for layout and common features
    return BaseCard.CommentCard(
      comment: widget.comment,
      memoId: widget.memoId,
      isSelected: widget.isSelected,
      actions: [
        // Add the action button here
        if (_isSendingToTodoist)
          const CupertinoActivityIndicator(radius: 10)
        else
          CupertinoButton(
            padding: const EdgeInsets.all(4), // Add some padding
            minSize: 0,
            child: Icon(
              CupertinoIcons.paperplane,
              size: 18,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            onPressed: () => _sendCommentToTodoist(widget.comment),
          ),
        // Add other existing actions like edit/delete here...
        // Example: Assuming BaseCommentCard handles edit/delete internally or via callbacks
      ],
      // Pass other necessary parameters to BaseCommentCard if needed
    );
  }
}
