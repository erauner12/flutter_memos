import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/navigation_providers.dart'; // Import navigation providers
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/screens/chat_screen.dart';
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/more/more_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
// Import Hub and Detail screens directly for routing
import 'package:flutter_memos/screens/workbench/workbench_hub_screen.dart';
import 'package:flutter_memos/screens/workbench/workbench_screen.dart';
// Keep WorkbenchNavigator import if needed elsewhere, but not directly used in builder now
// import 'package:flutter_memos/screens/workbench/workbench_navigator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


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

  // Define the route generation logic for the Workbench tab here
  Route<dynamic>? _workbenchOnGenerateRoute(RouteSettings settings) {
    WidgetBuilder builder;
    switch (settings.name) {
      case '/': // Hub screen (initial route for the tab)
        builder = (BuildContext _) => const WorkbenchHubScreen();
        break;
      case String name when name.startsWith('/workbench/'): // Detail screen
        final instanceId = name.substring('/workbench/'.length);
        if (instanceId.isNotEmpty) {
          builder = (BuildContext _) => WorkbenchScreen(instanceId: instanceId);
        } else {
          // Handle invalid ID case, maybe redirect to hub
          builder = (BuildContext _) => const WorkbenchHubScreen();
        }
        break;
      default:
        // Handle unknown routes within this tab, maybe redirect to hub
        builder = (BuildContext _) => const WorkbenchHubScreen();
    }
    // Use CupertinoPageRoute for iOS-style transitions within this tab
    return CupertinoPageRoute(builder: builder, settings: settings);
  }


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
    ); // Key for the Workbench tab's navigator
    final chatNavKey = ref.watch(chatNavKeyProvider);
    final moreNavKey = ref.watch(moreNavKeyProvider);

    // Map index to the key for the CupertinoTabView's navigator
    final Map<int, GlobalKey<NavigatorState>> tabViewNavKeys = {
      0: homeNavKey,
      1: workbenchNavKey, // Assign the key to the Workbench tab view
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
            // (WorkbenchNavigator used to listen, now other potential nested navigators could)
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
        switch (index) {
          case 0: // Home Tab
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[index],
              builder: (BuildContext context) {
                return const ItemsScreen();
              },
            );
          case 1: // Workbench Tab
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[index], // Assign the key
              onGenerateRoute:
                  _workbenchOnGenerateRoute, // Assign route generator
              builder: (BuildContext context) {
                // The builder now just returns the initial screen for this tab's navigator
                return const WorkbenchHubScreen();
              },
            );
          case 2: // Chat Tab
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[index],
              builder: (BuildContext context) {
                return const ChatScreen();
              },
            );
          case 3: // More Tab
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[index],
              builder: (BuildContext context) {
                return const MoreScreen();
              },
            );
          default:
            // Fallback, should not happen
            return const Center(child: Text('Unknown Tab'));
        }
      },
    );
  }
}
