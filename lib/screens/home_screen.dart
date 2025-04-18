import 'package:flutter/cupertino.dart'
    show
        BottomNavigationBarItem,
        BuildContext,
        CupertinoPageRoute,
        CupertinoPageScaffold,
        CupertinoTabBar,
        CupertinoTabController,
        CupertinoTabScaffold,
        CupertinoTabView,
        // Removed GestureDetector, HitTestBehavior
        GlobalKey,
        Icon,
        NavigatorState,
        Widget;
// Removed chat overlay provider import
import 'package:flutter_memos/screens/chat_screen.dart'; // Import ChatScreen
import 'package:flutter_memos/screens/home_tabs.dart'; // Import the new enum
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_memos/screens/tasks/tasks_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'item_detail/item_detail_screen.dart';
import 'workbench/workbench_screen.dart';

// --- New Providers ---

/// Provider exposing the primary CupertinoTabController for the HomeScreen.
/// Managed within _HomeScreenState.
final homeTabControllerProvider = Provider<CupertinoTabController>(
  (ref) =>
      throw UnimplementedError(
        'homeTabControllerProvider must be overridden in _HomeScreenState',
      ),
  name: 'homeTabControllerProvider',
);

/// Provider exposing the mapping from HomeTab enum to its current index.
/// Managed within _HomeScreenState.
final homeTabIndexMapProvider = Provider<Map<HomeTab, int>>(
  (ref) =>
      throw UnimplementedError(
        'homeTabIndexMapProvider must be overridden in _HomeScreenState',
      ),
  name: 'homeTabIndexMapProvider',
);

// --- Global Keys (Added chat key back) ---
final GlobalKey<NavigatorState> chatTabNavKey =
    GlobalKey<NavigatorState>(); // Added chat key
final GlobalKey<NavigatorState> memosTabNavKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> tasksTabNavKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> workbenchTabNavKey =
    GlobalKey<NavigatorState>();


// --- HomeScreen Widget ---

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late CupertinoTabController _tabController;
  late Map<HomeTab, int> _tabIndexes;

  // Define the tabs dynamically based on the enum order
  final List<HomeTab> _tabs = HomeTab.values.toList();

  @override
  void initState() {
    super.initState();

    // Create the index map based on the current order of _tabs
    _tabIndexes = {for (int i = 0; i < _tabs.length; i++) _tabs[i]: i};

    // Initialize the CupertinoTabController
    _tabController = CupertinoTabController(
      initialIndex: _tabIndexes[HomeTab.notes] ?? 0, // Default to Notes tab
    );

    _tabController.addListener(() {
      // Optional: Add listener logic if needed
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Override the providers with the actual controller and map for this instance
    return ProviderScope(
      overrides: [
        homeTabControllerProvider.overrideWithValue(_tabController),
        homeTabIndexMapProvider.overrideWithValue(_tabIndexes),
      ],
      // Removed GestureDetector wrapper
      child: CupertinoTabScaffold(
        controller: _tabController,
        tabBar: CupertinoTabBar(
          items: [
            // Generate BottomNavigationBarItems from the _tabs list
            for (final tab in _tabs)
              BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
          ],
        ),
        tabBuilder: (BuildContext context, int index) {
          // Get the corresponding HomeTab enum value for the index
          final currentTab = _tabs[index];

          // Return the correct CupertinoTabView based on the enum value
          switch (currentTab) {
            case HomeTab.chat: // Added Chat case
              return CupertinoTabView(
                navigatorKey: chatTabNavKey,
                // Define routes for the chat tab if needed, otherwise just the screen
                onGenerateRoute:
                    (settings) => CupertinoPageRoute(
                      builder:
                          (_) => const CupertinoPageScaffold(
                            // ChatScreen now likely needs its own Scaffold/NavBar
                            child: ChatScreen(),
                          ),
                      settings: settings,
                    ),
              );
            case HomeTab.workbench:
              return CupertinoTabView(
                navigatorKey: workbenchTabNavKey,
                onGenerateRoute:
                    (settings) => CupertinoPageRoute(
                      builder:
                          (_) => const CupertinoPageScaffold(
                            child: WorkbenchScreen(),
                          ),
                      settings: settings,
                    ),
              );
            case HomeTab.tasks:
              return CupertinoTabView(
                navigatorKey: tasksTabNavKey,
                onGenerateRoute: (settings) {
                  Widget page;
                  switch (settings.name) {
                    case '/tasks/new':
                      page = const NewTaskScreen();
                      break;
                    case '/':
                    default:
                      page = const TasksScreen();
                  }
                  return CupertinoPageRoute(
                    builder: (_) => CupertinoPageScaffold(child: page),
                    settings: settings,
                  );
                },
              );
            case HomeTab.notes:
              return CupertinoTabView(
                navigatorKey: memosTabNavKey,
                onGenerateRoute: (settings) {
                  Widget page;
                  switch (settings.name) {
                    case '/item-detail':
                      final args = settings.arguments as Map<String, dynamic>?;
                      final itemId = args?['itemId'] as String?;
                      page = ItemDetailScreen(itemId: itemId ?? '');
                      break;
                    // Add other routes like /edit-entity if needed within this tab
                    case '/':
                    default:
                      page = const ItemsScreen();
                  }
                  return CupertinoPageRoute(
                    builder: (_) => CupertinoPageScaffold(child: page),
                    settings: settings,
                  );
                },
              );
          }
        },
      ),
    );
  }
}
