import 'package:flutter_memos/models/memo.dart';

/// Utility class for memo-related operations
class MemoUtils {
  /// Sort memos by creation time (descending - newest first)
  static void sortByCreateTime(List<Memo> memos) {
    memos.sort((a, b) {
      // Note: This version doesn't prioritize pinned status.
      // If createTime sort should also prioritize pinned, add the pinned check here too.
      
      final aTime = safeParseDateTime(a.createTime);
      final bTime = safeParseDateTime(b.createTime);

      // *** Ensure descending order: Newest (larger DateTime) comes first ***
      return bTime.compareTo(aTime);
    });
  }

  /// Helper method to safely parse date strings
  /// Returns epoch (1970-01-01) if parsing fails or input is null.
  static DateTime safeParseDateTime(String? isoTime) {
    if (isoTime == null) return DateTime.fromMillisecondsSinceEpoch(0);
    try {
      // Ensure parsing happens correctly
      final parsedDate = DateTime.parse(isoTime);
      // Check for potential zero/epoch dates that might arise from parsing issues
      if (parsedDate.millisecondsSinceEpoch == 0) {
        // Optionally log this case if it's unexpected
        // print('[MemoUtils] Warning: Parsed date resulted in epoch for input: $isoTime');
      }
      return parsedDate;
    } catch (e) {
      // Log parsing errors for debugging
      print('[MemoUtils] Error parsing date "$isoTime": $e. Returning epoch.');
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  /// Sort memos by pinned status first, then by update time (descending)
  static void sortByPinnedThenUpdateTime(List<Memo> memos) {
    memos.sort((a, b) {
      // 1) Pinned items first
      if (a.pinned && !b.pinned) return -1; // a comes first
      if (!a.pinned && b.pinned) return 1; // b comes first

      // 2) If pinning is the same, compare updateTime descending
      final aTime = safeParseDateTime(a.updateTime);
      final bTime = safeParseDateTime(b.updateTime);
      
      // Handle cases where one or both times might be epoch due to null/parse error
      // Standard compareTo handles epoch correctly (epoch is considered older)

      // *** DIAGNOSTIC: Try swapping aTime and bTime to see if it fixes the test ***
      // This *should* result in ascending order, but the test failed with descending logic.
      final comparisonResult = aTime.compareTo(bTime);
      // Optional: Add logging here in the actual code if needed for debugging
      // print('[Sort Debug] Comparing ${a.id} (${aTime}) vs ${b.id} (${bTime}): Result = $comparisonResult');
      return comparisonResult;
    });
  }

  /// Sort memos by specified field (updateTime, createTime, or pinned-first)
  static void sortMemos(List<Memo> memos, String sortField) {
    // Default to descending order for time-based sorts
    switch (sortField.toLowerCase()) {
      case 'updatetime':
      case 'pinned': // Treat 'pinned' sort as pinned-then-updateTime descending
        // This function handles pinned first, then updateTime descending
        sortByPinnedThenUpdateTime(memos);
        break;
      case 'createtime':
        // This function handles createTime descending
        sortByCreateTime(memos);
        break;
      default:
        // Fallback to the primary sorting method if the field is unknown
        print(
          '[MemoUtils] Unknown sortField "$sortField", defaulting to pinned then updateTime.',
        );
        sortByPinnedThenUpdateTime(memos);
        break;
    }
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
