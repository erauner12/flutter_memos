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
              builder: (context) {
                // MemosScreen likely needs its own Scaffold/NavBar if it manages its own title etc.
                // Keep this structure for MemosScreen for now.
                return const CupertinoPageScaffold(
                  child: ItemsScreen(),
                ); // Use ItemsScreen
              },
            );
          case 1: // New index for Chat tab
            return CupertinoTabView(
              builder: (context) {
                // Wrap ChatScreen in CupertinoPageScaffold to ensure Navigator has a route
                return const CupertinoPageScaffold(child: ChatScreen());
              },
            );
          case 2: // Updated index for Settings tab
            // Simplify the Settings tab - remove nested Scaffold/NavBar
            return CupertinoTabView(
              builder: (context) {
                // Wrap SettingsScreen in CupertinoPageScaffold to ensure Navigator has a route
                return const CupertinoPageScaffold(
                  child: SettingsScreen(isInitialSetup: false),
                );
              },
            );
          default:
            // Should not happen with 3 tabs, but good practice
            return const SizedBox.shrink();
        }
      },
    );
  }
}
