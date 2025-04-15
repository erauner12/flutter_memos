import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/items/items_screen.dart'; // Updated import
import 'package:flutter_memos/screens/settings_screen.dart'; // Ensure this import is correct
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Remove the line below as themeMode is not used directly here
    // final themeMode = ref.watch(themeProvider);

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
              onGenerateRoute: (RouteSettings settings) {
                return CupertinoPageRoute(
                  settings: settings,
                  builder: (context) => const ItemsScreen(),
                );
              },
            );
          case 1:
            return CupertinoTabView(
              onGenerateRoute: (RouteSettings settings) {
                return CupertinoPageRoute(
                  settings: settings,
                  builder: (context) => const ChatScreen(),
                );
              },
            );
          case 2:
            return CupertinoTabView(
              onGenerateRoute: (RouteSettings settings) {
                return CupertinoPageRoute(
                  settings: settings,
                  builder:
                      (context) => const SettingsScreen(isInitialSetup: false),
                );
              },
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
