import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/navigation_providers.dart'; // Import navigation providers
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/screens/chat_screen.dart';
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/more/more_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_memos/screens/workbench/workbench_navigator.dart'; // Import the new navigator
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to track the current tab index
// final currentTabIndexProvider = StateProvider<int>((ref) => 0); // Defined in navigation_providers.dart

// Centralized Navigation Keys for each tab's NavigatorState
// final homeTabNavKey = GlobalKey<NavigatorState>(); // Defined in navigation_providers.dart
// final workbenchTabNavKey = GlobalKey<NavigatorState>(); // Defined in navigation_providers.dart
// final chatTabNavKey = GlobalKey<NavigatorState>(); // Defined in navigation_providers.dart
// final moreTabNavKey = GlobalKey<NavigatorState>(); // Defined in navigation_providers.dart

// Map tab index to its corresponding GlobalKey
// Use providers directly instead of a list map
// final List<GlobalKey<NavigatorState>> tabNavKeys = [
//   homeTabNavKey,
//   workbenchTabNavKey,
//   chatTabNavKey,
//   moreTabNavKey,
// ];


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
    final tabController = ref.watch(
      homeTabControllerProvider,
    ); // Assuming this controls the CupertinoTabScaffold index

    // Retrieve navigation keys from providers
    final homeNavKey = ref.watch(homeNavKeyProvider);
    final workbenchNavKey = ref.watch(
      workbenchNavKeyProvider,
    ); // Key for the nested navigator
    final chatNavKey = ref.watch(chatNavKeyProvider);
    final moreNavKey = ref.watch(moreNavKeyProvider);

    // Map index to the key for the CupertinoTabView's navigator
    final Map<int, GlobalKey<NavigatorState>> tabViewNavKeys = {
      0: homeNavKey,
      1: workbenchNavKey, // Use the same key for the tab view and the nested navigator for simplicity here
      2: chatNavKey,
      3: moreNavKey,
    };


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
      controller: tabController, // Link the controller
      tabBar: CupertinoTabBar(
        items: navBarItems,
        currentIndex: currentIndex, // Use the state provider value
        onTap: (index) {
          final previousIndex = ref.read(currentTabIndexProvider);

          // Always update the current tab index state
          ref.read(currentTabIndexProvider.notifier).state = index;

          // Handle re-selection: notify provider and pop the tab's stack
          if (previousIndex == index) {
            // Notify the reselect provider so nested navigators can react
            ref.read(reselectTabProvider.notifier).state = index;

            // Pop the CupertinoTabView's navigation stack to the root
            final currentTabViewNavKey = tabViewNavKeys[index];
            currentTabViewNavKey?.currentState?.popUntil(
              (route) => route.isFirst,
            );
          }
        },
      ),
      tabBuilder: (BuildContext context, int index) {
        // Return a CupertinoTabView for each tab to manage navigation stacks
        return CupertinoTabView(
          // Assign the correct navigator key to each tab view
          navigatorKey: tabViewNavKeys[index],
          builder: (BuildContext context) {
            // Return the screen content based on the index
            switch (index) {
              case 0:
                return const ItemsScreen();
              case 1:
                // Use the new WorkbenchNavigator for the second tab
                return const WorkbenchNavigator();
              case 2:
                return const ChatScreen();
              case 3:
                return const MoreScreen();
              default:
                // Fallback, should not happen
                return const Center(child: Text('Unknown Tab'));
            }
          },
          // Optional: Define onGenerateRoute if specific routes need handling
          // within a tab's navigation stack, otherwise default behavior is fine.
        );
      },
    );
  }
}
