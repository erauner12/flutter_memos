import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem

/// Utility class for note-related operations
class NoteUtils { // Renamed class
  /// Sort notes by creation time (descending - newest first)
  static void sortByCreateTime(List<NoteItem> notes) { // Use NoteItem
    notes.sort((a, b) {
      // Note: This version doesn't prioritize pinned status.
      // If createTime sort should also prioritize pinned, add the pinned check here too.

      // Use DateTime directly
      final aTime = a.createTime;
      final bTime = b.createTime;

      // Ensure descending order: Newest (larger DateTime) comes first
      return bTime.compareTo(aTime);
    });
  }

  /// Sort notes by pinned status first, then by update time (descending)
  static void sortByPinnedThenUpdateTime(List<NoteItem> notes) { // Use NoteItem
    notes.sort((a, b) {
      // 1) Pinned items first
      if (a.pinned && !b.pinned) return -1; // a comes first
      if (!a.pinned && b.pinned) return 1; // b comes first

      // 2) If pinning is the same, compare updateTime descending
      // Use DateTime directly
      final aTime = a.updateTime;
      final bTime = b.updateTime;

      // Ensure descending order: Newest (larger DateTime) comes first
      return bTime.compareTo(aTime);
    });
  }

  /// Sort notes by specified field (updateTime, createTime, or pinned-first)
  static void sortNotes(List<NoteItem> notes, String sortField) { // Use NoteItem, renamed method
    switch (sortField.toLowerCase()) {
      case 'updatetime':
      case 'pinned':
        sortByPinnedThenUpdateTime(notes);
        break;
      case 'createtime':
        sortByCreateTime(notes);
        break;
      default:
        print(
          '[NoteUtils] Unknown sortField "$sortField", defaulting to pinned then updateTime.', // Updated log identifier
        );
        sortByPinnedThenUpdateTime(notes);
        break;
    }
  }

  /// Get a human readable date string from a timestamp string
  static String formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return timestamp; // Return original string if parsing fails
    }
  }

  /// Test if two lists of notes have the same order of IDs
  static bool haveSameOrder(List<NoteItem> list1, List<NoteItem> list2) { // Use NoteItem
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) {
        return false;
      }
    }

    return true;
  }
}