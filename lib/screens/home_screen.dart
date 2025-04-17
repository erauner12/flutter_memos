import 'package:flutter/cupertino.dart'
    show
        BottomNavigationBarItem,
        BuildContext,
        ConsumerState,
        ConsumerStatefulWidget,
        CupertinoAlertDialog,
        CupertinoPageRoute,
        CupertinoPageScaffold,
        CupertinoTabBar,
        CupertinoTabController, // Added
        CupertinoTabScaffold, // Added
        CupertinoTabView, // Added
        GlobalKey,
        Icon,
        NavigatorState,
        State,
        StatefulWidget,
        Widget;
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_memos/screens/home_tabs.dart'; // Import the new enum
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_memos/screens/tasks/tasks_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_screen.dart';
import 'item_detail/item_detail_screen.dart';
import 'workbench/workbench_screen.dart';

// --- New Providers ---

/// Provider exposing the primary CupertinoTabController for the HomeScreen.
/// Managed within _HomeScreenState.
final homeTabControllerProvider = Provider<CupertinoTabController>(
  // Changed type
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

// --- Global Keys (Unchanged) ---
final GlobalKey<NavigatorState> memosTabNavKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> tasksTabNavKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> workbenchTabNavKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> chatTabNavKey = GlobalKey<NavigatorState>();

// --- HomeScreen Widget ---

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// Removed SingleTickerProviderStateMixin
class _HomeScreenState extends ConsumerState<HomeScreen> {
  late CupertinoTabController _tabController; // Changed type
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
      // Changed instantiation
      initialIndex: _tabIndexes[HomeTab.notes] ?? 0, // Default to Notes tab
    );

    // Optional: Add listener for debugging or state changes if needed
    _tabController.addListener(() {
      if (kDebugMode) {
        // print('[HomeScreen] Tab changed to: ${_tabs[_tabController.index].name}');
      }
      // If you need to update other providers based on tab index, do it here.
    });
  }

  @override
  void dispose() {
    // _tabController.dispose(); // CupertinoTabController does not have dispose()
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Override the providers with the actual controller and map for this instance
    return ProviderScope(
      overrides: [
        homeTabControllerProvider.overrideWithValue(
          _tabController,
        ), // Type matches now
        homeTabIndexMapProvider.overrideWithValue(_tabIndexes),
      ],
      child: CupertinoTabScaffold(
        controller: _tabController, // Use the CupertinoTabController
        tabBar: CupertinoTabBar(
          items: [
            // Generate BottomNavigationBarItems from the _tabs list
            for (final tab in _tabs)
              BottomNavigationBarItem(
                icon: Icon(tab.icon), label: tab.label),
          ],
          // onTap is handled by the controller passed to CupertinoTabScaffold
        ),
        tabBuilder: (BuildContext context, int index) {
          // Get the corresponding HomeTab enum value for the index
          final currentTab = _tabs[index];

          // Return the correct CupertinoTabView based on the enum value
          switch (currentTab) {
            case HomeTab.chat:
              return CupertinoTabView(
                navigatorKey: chatTabNavKey,
                // Define routes for the Chat tab's navigator
                onGenerateRoute: (settings) {
                  Widget page;
                  switch (settings.name) {
                    case '/':
                    case '/chat': // Handle both root and explicit '/chat'
                    default:
                      page = const ChatScreen();
                  }
                  return CupertinoPageRoute(
                    builder: (_) => CupertinoPageScaffold(child: page),
                    settings: settings, // Pass settings for arguments
                  );
                },
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
