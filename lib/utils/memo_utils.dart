import 'package:flutter_memos/models/memo.dart';

/// Utility class for memo-related operations
class MemoUtils {
  /// Sort memos by update time (newest first)
  static void sortByUpdateTime(List<Memo> memos) {
    memos.sort((a, b) {
      final dateA = a.updateTime != null ? DateTime.parse(a.updateTime!) : null;
      final dateB = b.updateTime != null ? DateTime.parse(b.updateTime!) : null;
      
      // If either time is null, fall back to displayTime
      if (dateA == null || dateB == null) {
        final displayDateA = a.displayTime != null ? DateTime.parse(a.displayTime!) : null;
        final displayDateB = b.displayTime != null ? DateTime.parse(b.displayTime!) : null;
        
        if (displayDateA == null && displayDateB == null) return 0;
        if (displayDateA == null) return 1;
        if (displayDateB == null) return -1;
        
        return displayDateB.compareTo(displayDateA);
      }
      
      // Sort in descending order (newest first)
      return dateB.compareTo(dateA);
    });
  }

  /// Sort memos by creation time (newest first)
  static void sortByCreateTime(List<Memo> memos) {
    memos.sort((a, b) {
      final dateA = a.createTime != null ? DateTime.parse(a.createTime!) : null;
      final dateB = b.createTime != null ? DateTime.parse(b.createTime!) : null;
      
      // If either time is null, fall back to displayTime
      if (dateA == null || dateB == null) {
        final displayDateA = a.displayTime != null ? DateTime.parse(a.displayTime!) : null;
        final displayDateB = b.displayTime != null ? DateTime.parse(b.displayTime!) : null;
        
        if (displayDateA == null && displayDateB == null) return 0;
        if (displayDateA == null) return 1;
        if (displayDateB == null) return -1;
        
        return displayDateB.compareTo(displayDateA);
      }
      
      // Sort in descending order (newest first)
      return dateB.compareTo(dateA);
    });
  }

  /// Sort memos by the specified field (newest first)
  static void sortMemos(List<Memo> memos, String sortField) {
    if (sortField == 'updateTime') {
      sortByUpdateTime(memos);
    } else if (sortField == 'createTime') {
      sortByCreateTime(memos);
    } else {
      // Default to sort by displayTime
      memos.sort((a, b) {
        final dateA = a.displayTime != null ? DateTime.parse(a.displayTime!) : null;
        final dateB = b.displayTime != null ? DateTime.parse(b.displayTime!) : null;
        
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        
        return dateB.compareTo(dateA);
      });
    }
  }
  
  /// Get a human readable date string from a timestamp
  static String formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        // Today, show hours and minutes
        return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        // Yesterday
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        // This week
        return '${difference.inDays} days ago';
      } else {
        // Older
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
