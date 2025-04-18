import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/tasks/tasks_screen.dart'; // Import the TasksScreen

/// A screen that displays a list of additional app features/sections.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('More'),
        // Prevent the back button on the root screen of the tab
        // If MoreScreen pushes other screens, they will get a back button automatically.
        automaticallyImplyLeading: false,
      ),
      child: SafeArea(
        // Use ListView.builder for potentially longer lists in the future
        child: ListView(
          children: [
            // --- Tasks Entry ---
            // Using a Container + CupertinoButton for a tappable list item feel
            Container(
              color: CupertinoTheme.of(context).barBackgroundColor, // Match nav bar bg
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                onPressed: () {
                  // Navigate to the TasksScreen within the 'More' tab's navigator
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      title: 'Tasks', // Set title for the pushed screen's nav bar
                      builder: (_) => const TasksScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Tasks',
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                    ),
                    Icon(
                      CupertinoIcons.forward,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ],
                ),
              ),
            ),
            // Add a separator
            Container(height: 1, color: CupertinoColors.separator.resolveFrom(context)),

            // --- Add more items here in the future ---
            // Example: Settings (if moved here)
            // Container(
            //   color: CupertinoTheme.of(context).barBackgroundColor,
            //   child: CupertinoButton(
            //     padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            //     onPressed: () {
            //       // Navigate to SettingsScreen
            //     },
            //     child: Row( ... ),
            //   ),
            // ),
            // Container(height: 1, color: CupertinoColors.separator.resolveFrom(context)),
          ],
        ),
      ),
    );
  }
}
