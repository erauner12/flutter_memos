import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/screens/chat_screen.dart'; // Keep ChatScreen import
import 'package:flutter_memos/screens/home_screen.dart';
import 'package:flutter_memos/screens/more/more_screen.dart'; // Keep MoreScreen import
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_memos/screens/workbench/workbench_main_screen.dart'; // Import the new main screen
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to track the current tab index
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

class ConfigCheckWrapper extends ConsumerWidget {
  const ConfigCheckWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverConfigState = ref.watch(multiServerConfigProvider);
    final activeServerId = ref.watch(activeServerConfigProvider)?.id;

    // Determine if initial setup is needed
    final bool needsSetup =
        serverConfigState.servers.isEmpty || activeServerId == null;

    if (needsSetup) {
      // Show SettingsScreen for initial setup
      return const SettingsScreen(isInitialSetup: true);
    } else {
      // Show the main app UI with tabs
      return const MainAppTabs();
    }
  }
}

class MainAppTabs extends ConsumerWidget {
  const MainAppTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabIndexProvider);

    // Define the tabs and their corresponding screens
    final List<Widget> screens = [
      const HomeScreen(),
      const WorkbenchMainScreen(), // Use the new WorkbenchMainScreen
      const ChatScreen(), // Keep ChatScreen
      const MoreScreen(), // Keep MoreScreen
    ];

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_list), // Updated icon maybe?
            label: 'Workbench',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_2),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.ellipsis_circle),
            label: 'More',
          ),
        ],
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(currentTabIndexProvider.notifier).state = index;
        },
      ),
      tabBuilder: (BuildContext context, int index) {
        // Return a CupertinoTabView for each tab to manage navigation stacks
        return CupertinoTabView(
          // Use rootNavigatorKey from main.dart if global navigation is needed
          // navigatorKey: ref.read(rootNavigatorKeyProvider), // Optional: if needed
          builder: (BuildContext context) {
            return screens[index];
          },
        );
      },
    );
  }
}
