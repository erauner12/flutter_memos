import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
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
          // Add the new Chat tab item
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
          // Add the new Workbench tab item
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.briefcase), // Or another suitable icon
            label: 'Workbench',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              // Define a default route through builder to ensure navigation stack is not empty
              builder: (context) {
                return const CupertinoPageScaffold(child: ItemsScreen(),
                );
              },
              // Routes for additional navigation
              routes: {
                '/':
                    (context) =>
                        const CupertinoPageScaffold(child: ItemsScreen()),
              },
            );
          case 1:
            return CupertinoTabView(
              // Define a default route through builder to ensure navigation stack is not empty
              builder: (context) {
                return const CupertinoPageScaffold(child: ChatScreen(),
                );
              },
              // Routes for additional navigation
              routes: {
                '/':
                    (context) =>
                        const CupertinoPageScaffold(child: ChatScreen()),
              },
            );
          case 2:
            return CupertinoTabView(
              // Define a default route through builder to ensure navigation stack is not empty
              builder: (context) {
                return const CupertinoPageScaffold(
                  child: SettingsScreen(isInitialSetup: false),
                );
              },
              // Routes for additional navigation
              routes: {
                '/':
                    (context) => const CupertinoPageScaffold(
                      child: SettingsScreen(isInitialSetup: false),
                    ),
              },
            );
          case 3: // Add case for the new Workbench tab (index 3)
            return CupertinoTabView(
              builder: (context) {
                // Import WorkbenchScreen at the top of the file
                // import 'package:flutter_memos/screens/workbench/workbench_screen.dart';
                return const CupertinoPageScaffold(child: WorkbenchScreen());
              },
              routes: {
                '/':
                    (context) =>
                        const CupertinoPageScaffold(child: WorkbenchScreen()),
              },
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
