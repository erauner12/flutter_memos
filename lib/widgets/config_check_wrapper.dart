import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/navigation_providers.dart'; // Import navigation providers
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/screens/chat_screen.dart';
import 'package:flutter_memos/screens/items/items_screen.dart'; // Keep for route generation
import 'package:flutter_memos/screens/items/notes_hub_screen.dart'; // Import Notes Hub
import 'package:flutter_memos/screens/more/more_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
// Import Hub and Detail screens directly for routing
import 'package:flutter_memos/screens/workbench/workbench_hub_screen.dart';
import 'package:flutter_memos/screens/workbench/workbench_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class ConfigCheckWrapper extends ConsumerWidget {
  const ConfigCheckWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider that indicates loading is complete
    final configLoadState = ref.watch(loadServerConfigProvider);
    final serverConfigState = ref.watch(multiServerConfigProvider);

    // Show loading indicator until the initial config load is done
    if (configLoadState.isLoading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    // Determine if initial setup is needed (no servers configured)
    // Check serverConfigState *after* loading is complete
    final bool needsSetup = serverConfigState.servers.isEmpty;

    if (needsSetup) {
      // Show SettingsScreen for initial setup
      // Use a Navigator to allow pushing routes from Settings if needed
      return const CupertinoApp(
        // Use a minimal theme for the setup screen
        theme: CupertinoThemeData(brightness: Brightness.light),
        home: SettingsScreen(isInitialSetup: true),
        debugShowCheckedModeBanner: false,
      );
    } else {
      // Show the main app UI with tabs
      return const MainAppTabs();
    }
  }
}

class MainAppTabs extends ConsumerWidget {
  const MainAppTabs({super.key});

  // Define the route generation logic for the Notes tab (Index 0)
  Route<dynamic>? _notesOnGenerateRoute(RouteSettings settings) {
    WidgetBuilder builder;
    switch (settings.name) {
      case '/': // Hub screen (initial route for the tab)
        builder = (BuildContext _) => const NotesHubScreen();
        break;
      case String name when name.startsWith('/notes/'): // Notes list screen
        final serverId = name.substring('/notes/'.length);
        if (serverId.isNotEmpty) {
          builder = (BuildContext _) => ItemsScreen(serverId: serverId);
        } else {
          // Handle invalid ID case, redirect to hub
          builder = (BuildContext _) => const NotesHubScreen();
        }
        break;
      default:
        // Handle unknown routes within this tab, redirect to hub
        builder = (BuildContext _) => const NotesHubScreen();
    }
    // Use CupertinoPageRoute for iOS-style transitions within this tab
    return CupertinoPageRoute(builder: builder, settings: settings);
  }

  // Define the route generation logic for the Workbench tab (Index 1)
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
    final notesNavKey = ref.watch(
      homeNavKeyProvider,
    ); // Reuse homeNavKey for Notes (index 0)
    final workbenchNavKey = ref.watch(
      workbenchNavKeyProvider,
    ); // Key for the Workbench tab's navigator
    final chatNavKey = ref.watch(chatNavKeyProvider);
    final moreNavKey = ref.watch(moreNavKeyProvider);

    // Map index to the key for the CupertinoTabView's navigator
    final Map<int, GlobalKey<NavigatorState>> tabViewNavKeys = {
      0: notesNavKey, // Assign key to Notes tab view (index 0)
      1: workbenchNavKey, // Assign key to Workbench tab view (index 1)
      2: chatNavKey, // Assign key to Chat tab view (index 2)
      3: moreNavKey, // Assign key to More tab view (index 3)
    };


    // Define the BottomNavigationBarItems - Update Index 0 for Notes
    const List<BottomNavigationBarItem> navBarItems = [
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.news_solid), // Notes Icon
        label: 'Notes', // Notes Label
      ),
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.square_list), // Workbench Icon
        label: 'Workbench',
      ),
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.chat_bubble_2), // Chat Icon
        label: 'Chat',
      ),
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.ellipsis_circle), // More Icon
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
        switch (index) {
          case 0: // Notes Tab (Index 0)
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[index], // Assign the key
              onGenerateRoute: _notesOnGenerateRoute, // Assign route generator
              builder: (BuildContext context) {
                // The builder now returns the initial screen (Hub) for this tab's navigator
                return const NotesHubScreen();
              },
            );
          case 1: // Workbench Tab (Index 1)
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[index], // Assign the key
              onGenerateRoute:
                  _workbenchOnGenerateRoute, // Assign route generator
              builder: (BuildContext context) {
                return const WorkbenchHubScreen();
              },
            );
          case 2: // Chat Tab (Index 2)
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[index],
              builder: (BuildContext context) {
                return const ChatScreen();
              },
            );
          case 3: // More Tab (Index 3)
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
