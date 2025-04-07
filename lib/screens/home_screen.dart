import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_memos/providers/theme_provider.dart';
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
                return CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: const Text('Settings'),
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.add),
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder:
                              (BuildContext context) => CupertinoActionSheet(
                                title: const Text('Theme'),
                                message: const Text('Select a theme'),
                                actions: <CupertinoActionSheetAction>[
                                  CupertinoActionSheetAction(
                                    child: const Text('Light'),
                                    onPressed: () {
                                      ref
                                          .read(
                                            themeModeProvider.notifier,
                                          ) // Correct usage
                                          .setTheme(ThemeMode.light);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  CupertinoActionSheetAction(
                                    child: const Text('Dark'),
                                    onPressed: () {
                                      ref
                                          .read(
                                            themeModeProvider.notifier,
                                          ) // Correct usage
                                          .setTheme(ThemeMode.dark);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  CupertinoActionSheetAction(
                                    child: const Text('System'),
                                    onPressed: () {
                                      ref
                                          .read(
                                            themeModeProvider.notifier,
                                          ) // Correct usage
                                          .setTheme(ThemeMode.system);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                                cancelButton: CupertinoActionSheetAction(
                                  isDefaultAction: true,
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ),
                        );
                      },
                    ),
                  ),
                  child: const SettingsScreen(isInitialSetup: false),
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
