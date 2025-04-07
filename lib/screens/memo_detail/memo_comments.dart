import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/providers/comment_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart'; // Added import
import 'package:flutter_memos/widgets/comment_card.dart';
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

    // Use CupertinoTheme for styling (variable removed as it wasn't used)
    // final theme = CupertinoTheme.of(context);

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

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CommentCard(
                comment: comment,
                memoId: memoId,
                isSelected: isSelected,
              ),
            );
          },
        );
      },
      // Replace CircularProgressIndicator with CupertinoActivityIndicator
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
                // Use Cupertino color for error text
                style: TextStyle(
                  color: CupertinoColors.systemRed.resolveFrom(context),
                ),
              ),
            ),
          ),
    );
  }
}
