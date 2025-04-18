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
        GlobalKey,
        Icon,
        NavigatorState,
        Widget;
import 'package:flutter_memos/screens/chat_screen.dart'; // Import ChatScreen
import 'package:flutter_memos/screens/home_tabs.dart'; // Import the updated enum
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/more/more_screen.dart'; // Import the new MoreScreen
// Removed tasks screen imports as it's now navigated to from MoreScreen
// import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
// import 'package:flutter_memos/screens/tasks/tasks_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'item_detail/item_detail_screen.dart';
import 'workbench/workbench_main_screen.dart'; // Import the new main screen

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

// --- Global Keys (Removed tasks key, added more key) ---
final GlobalKey<NavigatorState> chatTabNavKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> memosTabNavKey = GlobalKey<NavigatorState>();
// final GlobalKey<NavigatorState> tasksTabNavKey = GlobalKey<NavigatorState>(); // Removed tasks key
final GlobalKey<NavigatorState> workbenchTabNavKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> moreTabNavKey =
    GlobalKey<NavigatorState>(); // Added more key


// --- HomeScreen Widget ---

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late CupertinoTabController _tabController;
  late Map<HomeTab, int> _tabIndexes;

  // Define the tabs dynamically based on the enum order (now Workbench, Chat, Notes, More)
  final List<HomeTab> _tabs = HomeTab.values.toList();

  @override
  void initState() {
    super.initState();

    // Create the index map based on the current order of _tabs
    _tabIndexes = {for (int i = 0; i < _tabs.length; i++) _tabs[i]: i};

    // Initialize the CupertinoTabController
    // Default to Notes tab (index might change based on new order)
    _tabController = CupertinoTabController(
      initialIndex: _tabIndexes[HomeTab.notes] ?? 0,
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
      child: CupertinoTabScaffold(
        controller: _tabController,
        tabBar: CupertinoTabBar(
          items: [
            // Generate BottomNavigationBarItems from the _tabs list
            for (final tab in _tabs)
              BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
          ],
          onTap: (int newIndex) {
            final currentIndex = _tabController.index;

            // If user taps the same tab that is currently active
            if (currentIndex == newIndex) {
              final currentTab = _tabs[newIndex];
              switch (currentTab) {
                case HomeTab.more:
                  // Pop the “More” tab’s stack to root
                  moreTabNavKey.currentState?.popUntil(
                    (route) => route.isFirst,
                  );
                  break;
                // Optional: do the same for other tabs (common iOS pattern).
                case HomeTab.notes:
                  memosTabNavKey.currentState?.popUntil(
                    (route) => route.isFirst,
                  );
                  break;
                case HomeTab.workbench:
                  workbenchTabNavKey.currentState?.popUntil(
                    (route) => route.isFirst,
                  );
                  break;
                case HomeTab.chat:
                  chatTabNavKey.currentState?.popUntil(
                    (route) => route.isFirst,
                  );
                  break;
                // No default needed as all enum cases are handled
              }
            } else {
              // If it's a different tab, simply switch the tab controller index
              // This triggers the tabBuilder to rebuild with the new index
              setState(() {
                _tabController.index = newIndex;
              });
            }
          },
        ),
        tabBuilder: (BuildContext context, int index) {
          // Get the corresponding HomeTab enum value for the index
          final currentTab = _tabs[index];

          // Return the correct CupertinoTabView based on the enum value
          switch (currentTab) {
            case HomeTab.workbench: // Index 0
              return CupertinoTabView(
                navigatorKey: workbenchTabNavKey,
                onGenerateRoute:
                    (settings) => CupertinoPageRoute(
                      builder:
                          (_) => const CupertinoPageScaffold(
                            // Use WorkbenchMainScreen here
                            child: WorkbenchMainScreen(),
                          ),
                      settings: settings,
                    ),
              );
            case HomeTab.chat: // Index 1
              return CupertinoTabView(
                navigatorKey: chatTabNavKey,
                onGenerateRoute:
                    (settings) => CupertinoPageRoute(
                      builder:
                          (_) => const CupertinoPageScaffold(
                            child: ChatScreen(),
                          ),
                      settings: settings,
                    ),
              );
            case HomeTab.notes: // Index 2
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
            // case HomeTab.tasks: // Removed Tasks case
            //   // ... (old tasks tab view code removed)
            case HomeTab.more: // Index 3 - New More tab
              return CupertinoTabView(
                navigatorKey: moreTabNavKey, // Use the new key
                // The MoreScreen itself will handle navigation to TasksScreen etc.
                onGenerateRoute: (settings) {
                  // The base route for this tab is the MoreScreen
                  return CupertinoPageRoute(
                    builder: (_) => const MoreScreen(),
                    settings: settings,
                  );
                  // If MoreScreen needs its own sub-routes later, handle them here
                  // e.g., if (settings.name == '/more/settings') ...
                },
              );
          }
        },
      ),
    );
  }
}
