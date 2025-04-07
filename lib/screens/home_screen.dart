import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/memos/memos_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        switch (index) {
          case 0:
            // Memos tab
            return CupertinoTabView(
              builder: (context) => const MemosScreen(),
              // Provide routes for this tab's navigator
              routes: {'/': (context) => const MemosScreen(),
              },
              defaultTitle: 'Memos',
            );
          case 1:
            // Settings tab
            return CupertinoTabView(
              builder:
                  (context) => const CupertinoPageScaffold(
                    navigationBar: CupertinoNavigationBar(
                      middle: Text('Settings'),
                    ),
                    child: SettingsScreen(isInitialSetup: false),
                  ),
              // Provide routes for this tab's navigator
              routes: {
                '/':
                    (context) => const CupertinoPageScaffold(
                      navigationBar: CupertinoNavigationBar(
                        middle: Text('Settings'),
                      ),
                      child: SettingsScreen(isInitialSetup: false),
                    ),
              },
              defaultTitle: 'Settings',
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
