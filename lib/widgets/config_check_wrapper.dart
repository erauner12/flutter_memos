import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/screens/chat_screen.dart';
import 'package:flutter_memos/screens/home_tabs.dart'; // Import HomeTab enum
import 'package:flutter_memos/screens/items/items_screen.dart'; // Keep for route generation
import 'package:flutter_memos/screens/items/notes_hub_screen.dart'; // Import Notes Hub
// Removed MoreScreen import
import 'package:flutter_memos/screens/settings_screen.dart';
// Import Hub and Detail screens directly for routing
import 'package:flutter_memos/screens/workbench/workbench_hub_screen.dart';
import 'package:flutter_memos/screens/workbench/workbench_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Keep for ConfigCheckWrapper


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

// Convert MainAppTabs to StatefulWidget
class MainAppTabs extends StatefulWidget {
  const MainAppTabs({super.key});

  @override
  State<MainAppTabs> createState() => _MainAppTabsState();
}

class _MainAppTabsState extends State<MainAppTabs> {
  late CupertinoTabController _controller;

  // Each tab has its own nav key, managed locally
  final Map<int, GlobalKey<NavigatorState>> tabViewNavKeys = {
    HomeTab.chat.index: GlobalKey<NavigatorState>(), // 0
    HomeTab.workbench.index: GlobalKey<NavigatorState>(), // 1
    HomeTab.notes.index: GlobalKey<NavigatorState>(), // 2
  };

  @override
  void initState() {
    super.initState();
    // Initialize the controller, defaulting to the first tab (Chat)
    _controller = CupertinoTabController(initialIndex: HomeTab.chat.index);
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller
    super.dispose();
  }

  // Define the route generation logic for the Notes tab (Index 2)
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
  Widget build(BuildContext context) {
    // Remove ref parameter and Riverpod watches for tab index/controller/keys

    // Define the BottomNavigationBarItems DIRECTLY from HomeTab enum order
    final List<BottomNavigationBarItem> navBarItems =
        HomeTab.values
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon), // Use icon from enum
                label: tab.label, // Use label from enum
              ),
            )
            .toList();

    return CupertinoTabScaffold(
      controller: _controller, // Use the local controller
      tabBar: CupertinoTabBar(
        items: navBarItems, // Use the generated list based on HomeTab enum
        currentIndex: _controller.index, // Use the local controller's index
        onTap: (tappedIndex) {
          // Use setState for local state management
          setState(() {
            // Handle re-selection logic locally
            if (_controller.index == tappedIndex) {
              // Pop the CupertinoTabView's navigation stack to the root
              final currentTabViewNavKey = tabViewNavKeys[tappedIndex];
              currentTabViewNavKey?.currentState?.popUntil(
                (route) => route.isFirst,
              );
            } else {
              // Switch tab
              _controller.index = tappedIndex;
            }
          });
          // Optional: Add listener logic here if persistence/analytics needed
          // _controller.addListener(() { ... }); // Add outside onTap if needed once
        },
      ),
      tabBuilder: (BuildContext context, int index) {
        // Return a CupertinoTabView for each tab based on the index,
        // matching the HomeTab enum order.
        final HomeTab currentTab = HomeTab.values[index];
        switch (currentTab) {
          // Switch on the enum value directly
          case HomeTab.chat: // Index 0
            return CupertinoTabView(
              navigatorKey:
                  tabViewNavKeys[HomeTab.chat.index], // Use local key
              builder: (BuildContext context) {
                return const ChatScreen();
              },
            );
          case HomeTab.workbench: // Index 1
            return CupertinoTabView(
              navigatorKey:
                  tabViewNavKeys[HomeTab.workbench.index], // Use local key
              onGenerateRoute: _workbenchOnGenerateRoute, // Use local method
              builder: (BuildContext context) {
                return const WorkbenchHubScreen();
              },
            );
          case HomeTab.notes: // Index 2
            return CupertinoTabView(
              navigatorKey:
                  tabViewNavKeys[HomeTab.notes.index], // Use local key
              onGenerateRoute: _notesOnGenerateRoute, // Use local method
              builder: (BuildContext context) {
                return const NotesHubScreen();
              },
            );
          // No default needed as HomeTab covers all cases
        }
      },
    );
  }
}
