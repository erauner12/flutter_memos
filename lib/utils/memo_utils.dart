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

  /// Sort memos by creation time (newest first)
  static void sortByCreateTime(List<Memo> memos) {
    memos.sort((a, b) {
      // Handle null or invalid create times
      DateTime aTime;
      DateTime bTime;

      try {
        aTime =
            a.createTime != null
                ? DateTime.parse(a.createTime!)
                : DateTime(1970);
      } catch (_) {
        aTime = DateTime(1970);
      }

      try {
        bTime =
            b.createTime != null
                ? DateTime.parse(b.createTime!)
                : DateTime(1970);
      } catch (_) {
        bTime = DateTime(1970);
      }

      return bTime.compareTo(aTime); // Newest first
    });
  }

  /// Helper method to safely parse date strings
  static DateTime safeParseDateTime(String? isoTime) {
    if (isoTime == null) return DateTime.fromMillisecondsSinceEpoch(0);
    try {
      return DateTime.parse(isoTime);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  /// Sort memos by pinned status first, then by update time
  static void sortByPinnedThenUpdateTime(List<Memo> memos) {
    memos.sort((a, b) {
      // 1) Pinned items first
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;

      // 2) Then compare updateTime descending
      final aTime = safeParseDateTime(a.updateTime);
      final bTime = safeParseDateTime(b.updateTime);
      return bTime.compareTo(aTime); // Newest first
    });
  }

  /// Sort memos by specified field (updateTime or pinned-first)
  static void sortMemos(List<Memo> memos, String sortField) {
    // Use the new pinned-first sorting by default
    sortByPinnedThenUpdateTime(memos);
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
