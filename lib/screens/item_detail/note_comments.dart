import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/comment_providers.dart';
// Import note_providers and use non-family providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/ui_providers.dart';
// import 'package:flutter_memos/utils/comment_utils.dart'; // No longer needed for sorting here
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class NoteComments extends ConsumerWidget {
  final String noteId;
  final String serverId; // Keep serverId for CommentCard

  const NoteComments({
    super.key,
    required this.noteId,
    required this.serverId,
  }); // Make serverId required

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use non-family noteCommentsProvider with noteId
    final commentsAsync = ref.watch(
      note_providers.noteCommentsProvider(noteId),
    );
    final selectedCommentIndex = ref.watch(selectedCommentIndexProvider);
    final hiddenCommentIds = ref.watch(hiddenCommentIdsProvider);
    final isMultiSelectMode = ref.watch(commentMultiSelectModeProvider);

    return commentsAsync.when(
      data: (comments) {
        final visibleCommentsRaw =
            comments
                .where((c) => !hiddenCommentIds.contains('$noteId/${c.id}')) // Use noteId
                .toList();

        // --- New Sorting Logic: Pinned first (newest to oldest), then Non-pinned (newest to oldest) ---
        final pinnedComments =
            visibleCommentsRaw.where((c) => c.pinned).toList();
        final nonPinnedComments =
            visibleCommentsRaw.where((c) => !c.pinned).toList();

        // Sort pinned comments descending by creation date
        pinnedComments.sort((a, b) => b.createdTs.compareTo(a.createdTs));

        // Sort non-pinned comments descending by creation date
        nonPinnedComments.sort((a, b) => b.createdTs.compareTo(a.createdTs));

        // Combine the lists
        final sortedVisibleComments = [...pinnedComments, ...nonPinnedComments];
        // --- End New Sorting Logic ---

        // Old sorting logic (removed):
        // CommentUtils.sortForThreadView(
        //   visibleComments,
        // ); // Use thread view sort

        if (sortedVisibleComments.isEmpty) {
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
            physics:
                const NeverScrollableScrollPhysics(), // Handled by parent scroll
            itemCount: sortedVisibleComments.length,
            itemBuilder: (context, index) {
              final comment = sortedVisibleComments[index];
              // Note: selectedCommentIndex might need adjustment if its logic
              // relied on the previous sort order. Assuming it's independent for now.

              // Add padding between comment cards and horizontal padding
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 16.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: CommentCard(
                  // Pass required parameters
                  comment: comment,
                  memoId: noteId, // Pass noteId as memoId prop
                  serverId: serverId, // Pass serverId
                  // isSelected: isSelected, // Selection handled internally now
                  // Adding a key based on comment ID and pin status to force rebuild when pin status changes
                  key: ValueKey('${comment.id}_${comment.pinned}'),
                ),
              );
            },
          ),
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
