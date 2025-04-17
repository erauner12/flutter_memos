import 'package:flutter/cupertino.dart'; // For IconData

/// Enum representing the primary tabs in the HomeScreen.
/// The order defined here determines the visual order in the TabBar.
enum HomeTab {
  chat,
  workbench,
  tasks,
  notes, // Renamed from 'home'/'memos' for clarity
  // settings, // Settings tab is removed for now
}

/// Extension providing helper methods for HomeTab.
extension HomeTabX on HomeTab {
  /// Gets the user-visible label for the tab.
  String get label => switch (this) {
        HomeTab.chat => 'Chat',
        HomeTab.workbench => 'Workbench',
        HomeTab.tasks => 'Tasks',
        HomeTab.notes => 'Notes', // Updated label
        // HomeTab.settings => 'Settings',
      };

  /// Gets the icon for the tab.
  IconData get icon => switch (this) {
        HomeTab.chat => CupertinoIcons.chat_bubble,
        HomeTab.workbench => CupertinoIcons.briefcase,
        HomeTab.tasks => CupertinoIcons.check_mark_circled,
        HomeTab.notes => CupertinoIcons.home, // Keep home icon for Notes
        // HomeTab.settings => CupertinoIcons.settings,
      };
}

/// Optional: Extension for safe tab navigation on TabController.
extension SafeTabNav on TabController {
  /// Animates to the given [tab] if it exists in the [map] and is within bounds.
  void safeAnimateTo(HomeTab tab, Map<HomeTab, int> map) {
    final i = map[tab];
    // Check if index exists and is valid for the controller's length
    if (i != null && i >= 0 && i < length) {
      animateTo(i);
    }
  }
}
