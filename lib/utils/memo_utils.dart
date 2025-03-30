import 'package:flutter_memos/models/memo.dart';

/// Utility class for memo-related operations
class MemoUtils {
  /// Sort memos by update time (newest first)
  static void sortByUpdateTime(List<Memo> memos) {
    memos.sort((a, b) {
      // Handle null or invalid update times
      DateTime aTime;
      DateTime bTime;
      
      try {
        aTime =
            a.updateTime != null
                ? DateTime.parse(a.updateTime!)
                : DateTime(1970);
      } catch (_) {
        aTime = DateTime(1970);
      }
      
      try {
        bTime =
            b.updateTime != null
                ? DateTime.parse(b.updateTime!)
                : DateTime(1970);
      } catch (_) {
        bTime = DateTime(1970);
      }
      
      return bTime.compareTo(aTime); // Newest first
    });
  }

  /// Sort memos by specified field (only updateTime is used now)
  static void sortMemos(List<Memo> memos, String sortField) {
    // We always sort by updateTime now, but keeping parameter for API compatibility
    sortByUpdateTime(memos);
  }

  /// Get a human readable date string from a timestamp
  static String formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final dateTime = DateTime.parse(timestamp);
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
    } catch (e) {
      return timestamp;
    }
  }

  /// Test if two lists of memos have the same order of IDs
  static bool haveSameOrder(List<Memo> list1, List<Memo> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) {
        return false;
      }
    }

    return true;
  }
}
