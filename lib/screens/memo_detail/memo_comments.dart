import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/comment_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart';
import 'package:flutter_memos/utils/comment_utils.dart'; // Add import for comment sorting utilities
import 'package:flutter_memos/widgets/comment_card.dart'; // Import the widget directly
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

        // Always sort comments to ensure proper order after pin/unpin operations
        CommentUtils.sortByPinnedThenOldestFirst(visibleComments);

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

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CommentCard(
                comment: comment,
                memoId: memoId,
                isSelected: isSelected,
                // Adding a key based on comment ID and pin status to force rebuild when pin status changes
                key: ValueKey('${comment.id}_${comment.pinned}'),
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
