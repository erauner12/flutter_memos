import 'package:flutter/material.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/comment_providers.dart'
    as comment_providers;
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/utils/comment_utils.dart';
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memo_detail_providers.dart';

class MemoComments extends ConsumerWidget {
  final String memoId;

  const MemoComments({super.key, required this.memoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(memoCommentsProvider(memoId));
    // Watch hidePinned to filter out pinned comments if needed
    final hidePinned = ref.watch(hidePinnedProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comments header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                // Optional comment counter
                commentsAsync.maybeWhen(
                  data: (comments) {
                    // Filter out pinned comments if hidePinned is true
                    final visibleComments =
                        hidePinned
                            ? comments
                                .where((comment) => !comment.pinned)
                                .toList()
                            : comments;

                    if (visibleComments.isNotEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${visibleComments.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Comments list or placeholder
          commentsAsync.when(
            data: (comments) {
              // Filter out pinned comments if hidePinned is true
              final filteredComments =
                  hidePinned
                      ? comments.where((comment) => !comment.pinned).toList()
                      : comments;

              // Sort comments with pinned first
              CommentUtils.sortByPinnedThenCreateTime(filteredComments);

              if (filteredComments.isEmpty) {
                final isDarkMode =
                    Theme.of(context).brightness == Brightness.dark;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 10),
                        Text(
                          hidePinned && comments.isNotEmpty
                              ? 'No unpinned comments yet.'
                              : 'No comments yet.',
                          style: TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Use the filtered and sorted comments
              return Column(
                children:
                    filteredComments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final comment = entry.value;
                      return _buildCommentCard(comment, context, ref, index);
                    }).toList(),
              );
            },
            loading:
                () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
            error:
                (error, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Error loading comments: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(
    Comment comment,
    BuildContext context,
    WidgetRef ref,
    int index,
  ) {
    // Get hidden comment IDs
    final hiddenCommentIds = ref.watch(
      comment_providers.hiddenCommentIdsProvider,
    );
    final fullId = '$memoId/${comment.id}';

    // If this comment is hidden, don't render it
    if (hiddenCommentIds.contains(fullId)) {
      return const SizedBox.shrink();
    }

    // Get the selected comment index
    final selectedIndex = ref.watch(selectedCommentIndexProvider);

    // Check if multi-select mode is active
    final isMultiSelectMode = ref.watch(commentMultiSelectModeProvider);

    // Use CommentCard instead of a basic Card
    return GestureDetector(
      // Ensure tapping comment cards doesn't steal focus from main screen
      onTap: () {
        if (!isMultiSelectMode) {
          final focusScope = FocusScope.of(context);
          if (!focusScope.hasPrimaryFocus) {
            focusScope.unfocus();
          }
        }
      },
      child: CommentCard(
        comment: comment,
        memoId: memoId,
        isSelected: index == selectedIndex,
      ),
    );
  }
}
