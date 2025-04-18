import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/screens/chat_screen.dart';
import 'package:flutter_memos/screens/items/items_screen.dart'; // Import ItemsScreen
import 'package:flutter_memos/screens/more/more_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_memos/screens/workbench/workbench_main_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to track the current tab index
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

// Centralized Navigation Keys for each tab's NavigatorState
final homeTabNavKey = GlobalKey<NavigatorState>();
final workbenchTabNavKey = GlobalKey<NavigatorState>();
final chatTabNavKey = GlobalKey<NavigatorState>();
final moreTabNavKey = GlobalKey<NavigatorState>();

// Map tab index to its corresponding GlobalKey
final List<GlobalKey<NavigatorState>> tabNavKeys = [
  homeTabNavKey,
  workbenchTabNavKey,
  chatTabNavKey,
  moreTabNavKey,
];


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

    // Define the screens for each tab
    // IMPORTANT: Use ItemsScreen for the first tab, not HomeScreen
    final List<Widget> screens = [
      const ItemsScreen(), // Content for Home tab
      const WorkbenchMainScreen(),
      const ChatScreen(),
      const MoreScreen(),
    ];

    // Define the BottomNavigationBarItems
    const List<BottomNavigationBarItem> navBarItems = [
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Home'),
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.square_list), // Or briefcase icon?
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
    ];

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: navBarItems,
        currentIndex: currentIndex,
        onTap: (index) {
          final previousIndex = ref.read(currentTabIndexProvider);
          ref.read(currentTabIndexProvider.notifier).state = index;

          // If tapping the *same* tab again, pop its navigation stack to root
          if (previousIndex == index) {
            // Get the correct key based on the index
            final currentNavKey = tabNavKeys[index];
            currentNavKey.currentState?.popUntil((route) => route.isFirst);
          }
        },
      ),
      tabBuilder: (BuildContext context, int index) {
        // Return a CupertinoTabView for each tab to manage navigation stacks
        return CupertinoTabView(
          // Assign the correct navigator key to each tab view
          navigatorKey: tabNavKeys[index],
          builder: (BuildContext context) {
            // Return the screen content. Add a scaffold if the screen itself doesn't have one.
            // Most screens likely manage their own scaffold (like WorkbenchMainScreen).
            // ItemsScreen might need one depending on its implementation.
            // Assuming screens provide their own necessary scaffold/navbar.
            return screens[index];
          },
          // Optional: Define onGenerateRoute if specific routes need handling
          // within a tab's navigation stack, otherwise default behavior is fine.
        );
      },
    );
  }
}
