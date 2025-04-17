import 'package:flutter/cupertino.dart'; // For IconData and CupertinoTabController

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

/// Extension for safe tab navigation on CupertinoTabController.
extension SafeTabNav on CupertinoTabController {
  /// Sets the [index] safely if in range.
  ///
  /// Requires the [map] of tabs to indices and the total number of tabs [maxTabs]
  /// because CupertinoTabController doesn't store its length.
  void safeSetIndex(HomeTab tab, Map<HomeTab, int> map, int maxTabs) {
    final i = map[tab];
    // Check if index exists and is valid for the controller's length
    if (i != null && i >= 0 && i < maxTabs) {
      // Only change index if it's different to avoid unnecessary listener triggers
      if (index != i) {
        index = i;
      }
    }
  }
}
