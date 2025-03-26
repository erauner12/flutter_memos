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
  /// This is used for reliable client-side sorting
  static void sortMemos(List<Memo> memos, String sortField) {
    switch (sortField) {
      case 'updateTime':
        print('[SORT] Client-side sorting by updateTime (newest first)');
        sortByUpdateTime(memos);
        break;
      case 'createTime':
        print('[SORT] Client-side sorting by createTime (newest first)');
        sortByCreateTime(memos);
        break;
      case 'displayTime':
        print('[SORT] Client-side sorting by displayTime (newest first)');
        memos.sort((a, b) {
          final dateA =
              a.displayTime != null ? DateTime.parse(a.displayTime!) : null;
          final dateB =
              b.displayTime != null ? DateTime.parse(b.displayTime!) : null;

          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateB.compareTo(dateA);
        });
        break;
      default:
        print(
          '[SORT] Client-side sorting by unknown field "$sortField", defaulting to updateTime',
        );
        sortByUpdateTime(memos);
    }

    // Verify the sort results for the first few items (debugging)
    if (memos.isNotEmpty) {
      final count = memos.length > 3 ? 3 : memos.length;
      String fieldLabel = sortField;

      print(
        '\n[SORT] First $count memos after client-side sorting by $fieldLabel:',
      );
      for (int i = 0; i < count; i++) {
        String value = "N/A";
        switch (sortField) {
          case 'updateTime':
            value = memos[i].updateTime ?? "null";
            break;
          case 'createTime':
            value = memos[i].createTime ?? "null";
            break;
          case 'displayTime':
            value = memos[i].displayTime ?? "null";
            break;
        }
        print('  [${i + 1}] ID: ${memos[i].id}, $fieldLabel: $value');
      }
      print('');
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
