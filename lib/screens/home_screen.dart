import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_memos/screens/tasks/tasks_screen.dart'; // Import TasksScreen
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_screen.dart';
import 'workbench/workbench_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Memos',
          ),
          // Add the Tasks tab item
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.check_mark_circled),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.briefcase), // Or another suitable icon
            label: 'Workbench',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        switch (index) {
          case 0: // Memos
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(child: ItemsScreen());
              },
              routes: {
                '/':
                    (context) =>
                        const CupertinoPageScaffold(child: ItemsScreen()),
              },
            );
          case 1: // Tasks (New)
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(child: TasksScreen());
              },
              routes: {
                '/':
                    (context) =>
                        const CupertinoPageScaffold(child: TasksScreen()),
                // Add routes for task detail/edit if needed within this tab's navigator
                '/tasks/new':
                    (context) =>
                        const CupertinoPageScaffold(child: NewTaskScreen()),
                // '/tasks/edit': (context) => CupertinoPageScaffold(child: EditTaskScreen(...)), // Placeholder
              },
            );
          case 2: // Workbench
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(child: WorkbenchScreen());
              },
              routes: {
                '/':
                    (context) =>
                        const CupertinoPageScaffold(child: WorkbenchScreen()),
              },
            );
          case 3: // Chat
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(child: ChatScreen());
              },
              routes: {
                '/':
                    (context) =>
                        const CupertinoPageScaffold(child: ChatScreen()),
              },
            );
          case 4: // Settings
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  child: SettingsScreen(isInitialSetup: false),
                );
              },
              routes: {
                '/':
                    (context) => const CupertinoPageScaffold(
                      child: SettingsScreen(isInitialSetup: false),
                    ),
              },
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
