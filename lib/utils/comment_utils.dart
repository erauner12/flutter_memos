import 'package:flutter_memos/models/comment.dart';

/// Utility class for comment-related operations
class CommentUtils {
  /// Sort comments by pinned status first, then by creation time
  static void sortByPinnedThenCreateTime(List<Comment> comments) {
    comments.sort((a, b) {
      // 1) Pinned comments first
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;

      // 2) Then compare creation time (newest first)
      return b.createTime.compareTo(a.createTime);
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
      return a.createTime.compareTo(b.createTime);
    });
  }

  /// Sort comments by pinned status first, then by update time (newest first)
  static void sortByPinnedThenUpdateTime(List<Comment> comments) {
    comments.sort((a, b) {
      // 1) Pinned comments first
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;

      // 2) Then compare update time (newest first)
      // Treat null updateTime as older than non-null
      final updateTimeA =
          a.updateTime ?? 0; // Use 0 or a very small number for null
      final updateTimeB = b.updateTime ?? 0;
      return updateTimeB.compareTo(updateTimeA);
    });
  }
}
