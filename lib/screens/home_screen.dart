import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_screen.dart';

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
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
