import 'package:flutter/cupertino.dart';

/// Enum representing the main tabs in the app's CupertinoTabScaffold.
enum HomeTab {
  vault,
  cache,
  focus, // Renamed from workbench
  studio, // New tab, replacing chat/tasks
}

extension HomeTabExtension on HomeTab {
  String get label {
    switch (this) {
      case HomeTab.vault:
        return 'Vault';
      case HomeTab.cache:
        return 'Cache';
      case HomeTab.focus:
        return 'Focus';
      case HomeTab.studio:
        return 'Studio';
    }
  }

  IconData get icon {
    switch (this) {
      case HomeTab.vault:
        return CupertinoIcons.folder_fill;
      case HomeTab.cache:
        return CupertinoIcons.tray_fill;
      case HomeTab.focus:
        // Using eye icon for Focus, previously briefcase for Workbench
        return CupertinoIcons.eye_solid;
      case HomeTab.studio:
        // Using a placeholder icon, previously chat bubble
        return CupertinoIcons.square_grid_2x2_fill; // Example icon
    }
  }
}
