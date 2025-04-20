import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/task_comment_providers.dart'; // Use new task comment providers
import 'package:flutter_memos/providers/task_server_config_provider.dart'; // To get serverId
import 'package:flutter_memos/widgets/comment_card.dart'; // Reuse CommentCard for now
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskComments extends ConsumerWidget {
  final String taskId;

  const TaskComments({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the serverId from the task server config provider
    final serverId = ref.watch(taskServerConfigProvider)?.id;

    // Watch the task comments provider
    final commentsAsync = ref.watch(taskCommentsProvider(taskId));
    // TODO: Add providers for selection/hiding if needed for tasks, similar to notes
    // final selectedCommentIndex = ref.watch(selectedTaskCommentIndexProvider);
    // final hiddenCommentIds = ref.watch(hiddenTaskCommentIdsProvider);
    // final isMultiSelectMode = ref.watch(taskCommentMultiSelectModeProvider);

    if (serverId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: Text('Task server not configured.')),
      );
    }

    return commentsAsync.when(
      data: (comments) {
        // TODO: Implement filtering for hidden comments if needed
        final visibleComments = comments;
            // .where((c) => !hiddenCommentIds.contains('$taskId/${c.id}'))
            // .toList();

        // Sort comments (e.g., chronologically)
        // Vikunja comments don't have pinned state, so simple sort is fine
        visibleComments.sort((a, b) => a.createdTs.compareTo(b.createdTs));
        // Or use CommentUtils if pinning is implemented locally:
        // CommentUtils.sortForThreadView(visibleComments);

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

        // Add overall padding for the comment section
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Handled by parent scroll
            itemCount: visibleComments.length,
            itemBuilder: (context, index) {
              final comment = visibleComments[index];
              // TODO: Handle selection state if implemented
              // final isSelected = !isMultiSelectMode && index == selectedCommentIndex;

              // Add padding between comment cards and horizontal padding
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 16.0,
                  left: 16.0,
                  right: 16.0,
                ),
                // Use existing CommentCard - ACTIONS WILL NOT WORK CORRECTLY YET
                // Need to adapt CommentCard or create TaskCommentCard later
                child: CommentCard(
                  comment: comment,
                  memoId: taskId, // Pass taskId as memoId prop for now
                  serverId: serverId, // Pass serverId
                  // isSelected: isSelected, // Selection handled internally now
                  // Key might need adjustment if local pinning/state is added
                  key: ValueKey(comment.id),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CupertinoActivityIndicator(),
        ),
      ),
      error: (error, _) => Center(
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
