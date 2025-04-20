import 'package:flutter/cupertino.dart';

/// Enum representing the main tabs in the HomeScreen's CupertinoTabScaffold.
enum HomeTab {
  chat,
  workbench,
  notes,
  tasks, // NEW
}

extension HomeTabExtension on HomeTab {
  String get label {
    switch (this) {
      case HomeTab.chat:
        return 'Chat';
      case HomeTab.workbench:
        return 'Workbench';
      case HomeTab.notes:
        return 'Notes';
      case HomeTab.tasks:
        return 'Tasks'; // NEW
    }
  }

  IconData get icon {
    switch (this) {
      case HomeTab.chat:
        return CupertinoIcons.chat_bubble_2_fill;
      case HomeTab.workbench:
        return CupertinoIcons.briefcase_fill; // Changed from wrench
      case HomeTab.notes:
        return CupertinoIcons.news_solid; // Changed from doc_text_fill
      case HomeTab.tasks:
        return CupertinoIcons.check_mark_circled_solid; // NEW
    }
  }
}
