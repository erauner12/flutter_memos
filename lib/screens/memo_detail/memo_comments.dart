import 'package:flutter/material.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memo_detail_providers.dart';

class MemoComments extends ConsumerWidget {
  final String memoId;

  const MemoComments({
    super.key,
    required this.memoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(memoCommentsProvider(memoId));
    
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
                    if (comments.isNotEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${comments.length}',
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
              if (comments.isEmpty) {
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
                          'No comments yet.',
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
              
              return Column(
                children: comments.reversed.map(
                  (comment) => _buildCommentCard(comment, context),
                ).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Error loading comments: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          
          // Comment form removed as we're now using CaptureUtility
        ],
      ),
    );
  }
  
  Widget _buildCommentCard(Comment comment, [BuildContext? context]) {
    // Use the provided context or null if not provided
    final buildContext = context!;
    final isDarkMode = Theme.of(buildContext).brightness == Brightness.dark;

    // Format the timestamp in a more readable way
    final DateTime commentDate = DateTime.fromMillisecondsSinceEpoch(
      comment.createTime,
    );
    final String formattedDate = _formatCommentDate(commentDate);
    
    return Card(
      elevation: isDarkMode ? 0 : 1,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side:
            isDarkMode
                ? BorderSide(color: Colors.grey[850]!, width: 0.5)
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment content with proper styling
            Text(
              comment.content,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[100] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),

            // Timestamp with better formatting
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to format comment date in a human-readable format
  String _formatCommentDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    // For very recent content (less than 1 hour)
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
    // For content from today (less than 24 hours)
    else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    }
    // Yesterday
    else if (difference.inDays == 1) {
      return 'Yesterday';
    }
    // Recent days
    else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    // Older content
    else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}
