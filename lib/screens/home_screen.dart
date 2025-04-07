import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/memos/memos_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart'; // Ensure this import is correct
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                return const CupertinoPageScaffold(child: MemosScreen());
              },
            );
          case 1:
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text('Settings'),
                  ),
                  child: SettingsScreen(isInitialSetup: false),
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
