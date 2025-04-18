import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/task_filter.dart'; // Import the filter enum
import 'package:flutter_memos/screens/more/activity_events_screen.dart'; // Import the new screen
import 'package:flutter_memos/screens/tasks/tasks_screen.dart'; // Import the TasksScreen

/// A screen that displays a list of additional app features/sections.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  // Helper widget to build consistent menu items
  Widget _buildMenuItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      color: CupertinoTheme.of(context).barBackgroundColor, // Match nav bar bg
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(
              icon,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
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
    );
  }

  // Helper to navigate to a filtered TasksScreen
  void _navigateToTasks(BuildContext context, TaskFilter filter) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        title: filter.title, // Use title from enum extension
        builder: (_) => TasksScreen(filter: filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define separator widget for reuse
    final separator = Container(
      height: 1,
      color: CupertinoColors.separator.resolveFrom(context),
      margin: const EdgeInsets.only(left: 54), // Indent separator like iOS Mail
    );
    // Define full width separator
    final fullSeparator = Container(
      height: 1,
      color: CupertinoColors.separator.resolveFrom(context),
    );

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('More'),
        // Prevent the back button on the root screen of the tab
        automaticallyImplyLeading: false,
      ),
      child: SafeArea(
        // Use ListView for potentially longer lists in the future
        child: ListView(
          children: [
            // --- Tasks Section ---
            _buildMenuItem(
              context: context,
              label: TaskFilter.all.title, // 'All Tasks'
              icon: CupertinoIcons.check_mark_circled_solid,
              onPressed: () => _navigateToTasks(context, TaskFilter.all),
            ),
            separator,
            _buildMenuItem(
              context: context,
              label: TaskFilter.notRecurring.title, // 'Non-Recurring Tasks'
              icon: CupertinoIcons.arrow_right_circle_fill, // Example icon
              onPressed:
                  () => _navigateToTasks(context, TaskFilter.notRecurring),
            ),
            separator,
            _buildMenuItem(
              context: context,
              label: TaskFilter.recurring.title, // 'Recurring Tasks'
              icon: CupertinoIcons.refresh_circled_solid, // Example icon
              onPressed: () => _navigateToTasks(context, TaskFilter.recurring),
            ),
            separator,
            _buildMenuItem(
              context: context,
              label: TaskFilter.dueToday.title, // 'Tasks Due Today'
              icon: CupertinoIcons.calendar_today, // Example icon
              onPressed: () => _navigateToTasks(context, TaskFilter.dueToday),
            ),
            fullSeparator, // Use full separator after the section
            // --- Activity Log Section ---
            _buildMenuItem(
              context: context,
              label: 'Activity Log', // New menu item
              icon: CupertinoIcons.list_bullet_indent, // Example icon
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder:
                        (_) =>
                            const ActivityEventsScreen(), // Navigate to new screen
                  ),
                );
              },
            ),
            fullSeparator, // Use full separator after the section

            // --- Add more items here in the future ---
            // Example: Settings (if moved here)
            // _buildMenuItem(
            //   context: context,
            //   label: 'Settings',
            //   icon: CupertinoIcons.settings,
            //   onPressed: () {
            //     // Navigate to SettingsScreen
            //   },
            // ),
            // fullSeparator,
          ],
        ),
      ),
    );
  }
}
