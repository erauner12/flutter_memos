import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/note_server_config_provider.dart'; // Import Note provider
import 'package:flutter_memos/providers/server_config_provider.dart'; // Keep for loadServerConfigProvider
import 'package:flutter_memos/providers/task_server_config_provider.dart'; // Import Task provider
import 'package:flutter_memos/screens/chat_screen.dart'; // Import ChatScreen
import 'package:flutter_memos/screens/home_tabs.dart'; // Import HomeTab enum and extension
import 'package:flutter_memos/screens/items/items_screen.dart'; // Keep for route generation
import 'package:flutter_memos/screens/items/notes_hub_screen.dart'; // Import Notes Hub
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_memos/screens/tasks/tasks_screen.dart'; // Import TasksScreen
import 'package:flutter_memos/screens/workbench/workbench_hub_screen.dart';
import 'package:flutter_memos/screens/workbench/workbench_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Keep for ConfigCheckWrapper

class ConfigCheckWrapper extends ConsumerWidget {
  const ConfigCheckWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider that indicates loading is complete
    final configLoadState = ref.watch(loadServerConfigProvider);

    // Show loading indicator until the initial config load is done
    if (configLoadState.isLoading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    // After loading, check if at least one server (Note or Task) is configured
    final noteServerConfig = ref.watch(noteServerConfigProvider);
    final taskServerConfig = ref.watch(taskServerConfigProvider);
    // Consider setup needed if BOTH are null. Adjust if only one is required.
    final bool needsSetup =
        noteServerConfig == null && taskServerConfig == null;

    if (needsSetup) {
      // Show SettingsScreen for initial setup
      return const CupertinoApp(
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

// MainAppTabs remains the same as in the previous response
class MainAppTabs extends StatefulWidget {
  const MainAppTabs({super.key});

  @override
  State<MainAppTabs> createState() => _MainAppTabsState();
}

class _MainAppTabsState extends State<MainAppTabs> {
  late CupertinoTabController _controller;

  final Map<int, GlobalKey<NavigatorState>> tabViewNavKeys = {
    HomeTab.chat.index: GlobalKey<NavigatorState>(),
    HomeTab.workbench.index: GlobalKey<NavigatorState>(),
    HomeTab.notes.index: GlobalKey<NavigatorState>(),
    HomeTab.tasks.index: GlobalKey<NavigatorState>(),
  };

  @override
  void initState() {
    super.initState();
    _controller = CupertinoTabController(initialIndex: HomeTab.chat.index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Route<dynamic>? _notesOnGenerateRoute(RouteSettings settings) {
    WidgetBuilder builder;
    switch (settings.name) {
      case '/':
        builder = (BuildContext _) => const NotesHubScreen();
        break;
      case String name
          when name.startsWith(
            '/notes/',
          ): // Keep for potential deep link structure
        // final serverId = name.substring('/notes/'.length); // No longer needed
        // ItemsScreen now gets context from provider
        builder =
            (BuildContext _) => const ItemsScreen(); // Remove serverId arg
        break;
      default:
        builder = (BuildContext _) => const NotesHubScreen();
    }
    return CupertinoPageRoute(builder: builder, settings: settings);
  }

  Route<dynamic>? _workbenchOnGenerateRoute(RouteSettings settings) {
    WidgetBuilder builder;
    switch (settings.name) {
      case '/':
        builder = (BuildContext _) => const WorkbenchHubScreen();
        break;
      case String name when name.startsWith('/workbench/'):
        final instanceId = name.substring('/workbench/'.length);
        if (instanceId.isNotEmpty) {
          builder = (BuildContext _) => WorkbenchScreen(instanceId: instanceId);
        } else {
          builder = (BuildContext _) => const WorkbenchHubScreen();
        }
        break;
      default:
        builder = (BuildContext _) => const WorkbenchHubScreen();
    }
    return CupertinoPageRoute(builder: builder, settings: settings);
  }

  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> navBarItems =
        HomeTab.values
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList();

    return CupertinoTabScaffold(
      controller: _controller,
      tabBar: CupertinoTabBar(
        items: navBarItems,
        currentIndex: _controller.index,
        onTap: (tappedIndex) {
          setState(() {
            if (_controller.index == tappedIndex) {
              final currentTabViewNavKey = tabViewNavKeys[tappedIndex];
              currentTabViewNavKey?.currentState?.popUntil(
                (route) => route.isFirst,
              );
            } else {
              _controller.index = tappedIndex;
            }
          });
        },
      ),
      tabBuilder: (BuildContext context, int index) {
        final HomeTab currentTab = HomeTab.values[index];
        switch (currentTab) {
          case HomeTab.chat:
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[HomeTab.chat.index],
              builder: (BuildContext context) => const ChatScreen(),
            );
          case HomeTab.workbench:
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[HomeTab.workbench.index],
              onGenerateRoute: _workbenchOnGenerateRoute,
              builder: (BuildContext context) => const WorkbenchHubScreen(),
            );
          case HomeTab.notes:
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[HomeTab.notes.index],
              onGenerateRoute: _notesOnGenerateRoute,
              builder: (BuildContext context) => const NotesHubScreen(),
            );
          case HomeTab.tasks:
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[HomeTab.tasks.index],
              builder: (BuildContext context) => const TasksScreen(),
            );
        }
      },
    );
  }
}
