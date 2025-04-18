import 'package:flutter/cupertino.dart';

/// Enum representing the type of item referenced in the workbench.
enum WorkbenchItemType {
  note,
  task,
  comment,
  project, // Added project type
  unknown, // Added unknown type
}

/// Extension to add helper properties/methods to WorkbenchItemType.
extension WorkbenchItemTypeExtension on WorkbenchItemType {
  /// Returns the appropriate Cupertino icon for the item type.
  IconData get icon {
    switch (this) {
      case WorkbenchItemType.note:
        return CupertinoIcons.doc_text;
      case WorkbenchItemType.task:
        return CupertinoIcons.check_mark_circled;
      case WorkbenchItemType.comment:
        return CupertinoIcons.bubble_left_bubble_right;
      case WorkbenchItemType.project:
        return CupertinoIcons.folder; // Example icon for project
      case WorkbenchItemType.unknown:
      default:
        return CupertinoIcons.question_circle; // Default icon
    }
  }

  /// Returns a display name for the item type.
  String get displayName {
    switch (this) {
      case WorkbenchItemType.note:
        return 'Note';
      case WorkbenchItemType.task:
        return 'Task';
      case WorkbenchItemType.comment:
        return 'Comment';
      case WorkbenchItemType.project:
        return 'Project';
      case WorkbenchItemType.unknown:
      default:
        return 'Item';
    }
  }
}
