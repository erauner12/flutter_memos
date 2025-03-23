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
}
