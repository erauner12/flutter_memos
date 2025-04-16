import 'package:flutter_memos/models/comment.dart';

/// Utility class for comment-related operations
class CommentUtils {
  /// Sort comments by pinned status first, then by creation time (newest first)
  static void sortByPinnedThenCreateTime(List<Comment> comments) {
    comments.sort((a, b) {
      // 1) Pinned comments first
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;

      // 2) Then compare creation time (newest first)
      return b.createdTs.compareTo(a.createdTs); // Use createdTs
    });
  }

  /// Sort comments in reverse order (pinned first, oldest first)
  /// This is useful for showing comments in chronological order
  static void sortByPinnedThenOldestFirst(List<Comment> comments) {
    comments.sort((a, b) {
      // 1) Pinned comments first
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;

      // 2) Then compare creation time (oldest first)
      return a.createdTs.compareTo(b.createdTs); // Use createdTs
    });
  }

  /// Sort comments by pinned status first, then by update time (newest first)
  static void sortByPinnedThenUpdateTime(List<Comment> comments) {
    comments.sort((a, b) {
      // 1) Pinned comments first
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;

      // 2) Then compare update time (newest first)
      // Use updatedTs (nullable DateTime) or fallback to createdTs
      final updateTimeA = a.updatedTs ?? a.createdTs;
      final updateTimeB = b.updatedTs ?? b.createdTs;
      return updateTimeB.compareTo(updateTimeA);
    });
  }
}