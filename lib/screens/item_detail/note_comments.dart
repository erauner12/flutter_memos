import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/comment_providers.dart';
// Import note_providers and use families
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/utils/comment_utils.dart';
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class NoteComments extends ConsumerWidget {
  final String noteId;
  final String serverId; // Add serverId

  const NoteComments({
    super.key,
    required this.noteId,
    required this.serverId,
  }); // Make serverId required

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use noteCommentsProviderFamily with serverId and noteId
    final commentsAsync = ref.watch(
      note_providers.noteCommentsProviderFamily((
        serverId: serverId,
        noteId: noteId,
      )),
    );
    final selectedCommentIndex = ref.watch(selectedCommentIndexProvider);
    final hiddenCommentIds = ref.watch(hiddenCommentIdsProvider);
    final isMultiSelectMode = ref.watch(commentMultiSelectModeProvider);

    return commentsAsync.when(
      data: (comments) {
        final visibleComments =
            comments
                .where((c) => !hiddenCommentIds.contains('$noteId/${c.id}')) // Use noteId
                .toList();

        // Sort comments chronologically for thread view (pinned first, then oldest to newest)
        CommentUtils.sortForThreadView(
          visibleComments,
        ); // Use thread view sort

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
            physics:
                const NeverScrollableScrollPhysics(), // Handled by parent scroll
            itemCount: visibleComments.length,
            itemBuilder: (context, index) {
              final comment = visibleComments[index];
              final isSelected =
                  !isMultiSelectMode && index == selectedCommentIndex;

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
                  // isSelected: isSelected,
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
