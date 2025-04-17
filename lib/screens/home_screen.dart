import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_memos/screens/tasks/tasks_screen.dart'; // Import TasksScreen
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_screen.dart';
// Import ItemDetailScreen - adjust path if necessary
import 'item_detail/item_detail_screen.dart';
import 'workbench/workbench_screen.dart';

// Provider to expose the TabController
final tabControllerProvider = StateProvider<CupertinoTabController?>(
  (ref) => null,
);

// GlobalKeys for each tab's navigator state
// These are crucial for navigating within specific tabs from other parts of the app
final GlobalKey<NavigatorState> memosTabNavKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> tasksTabNavKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> workbenchTabNavKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> chatTabNavKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> settingsTabNavKey = GlobalKey<NavigatorState>();


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late CupertinoTabController _tabController; // Declare controller

  @override
  void initState() {
    super.initState();
    _tabController = CupertinoTabController(); // Initialize controller
    // Update the provider after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(tabControllerProvider) != _tabController) {
          ref.read(tabControllerProvider.notifier).state = _tabController;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose the controller
    // Optionally clear the provider state on dispose if necessary
    // Consider if this is needed based on app lifecycle
    // ref.read(tabControllerProvider.notifier).state = null;
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _tabController, // Pass the managed controller
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Memos',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.check_mark_circled),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.briefcase),
            label: 'Workbench',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
        // onTap is handled by the controller passed to CupertinoTabScaffold
        // No need for manual provider update here
      ),
      tabBuilder: (BuildContext context, int index) {
        switch (index) {
          case 0: // Memos
            return CupertinoTabView(
              navigatorKey: memosTabNavKey, // Assign key
              builder: (context) {
                return const CupertinoPageScaffold(child: ItemsScreen());
              },
              // Define routes within this tab's navigator
              routes: {
                '/':
                    (context) =>
                        const CupertinoPageScaffold(child: ItemsScreen()),
                '/item-detail': (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments
                          as Map<String, dynamic>?;
                  final itemId = args?['itemId'] as String?;
                  // Ensure ItemDetailScreen is imported
                  return CupertinoPageScaffold(
                    child: ItemDetailScreen(itemId: itemId ?? ''),
                  );
                },
                '/edit-entity': (context) {
                  // Placeholder for edit screen route
                  // TODO: Implement Edit Entity Screen
                  return const CupertinoPageScaffold(
                    child: Center(child: Text('Edit Entity Screen')),
                  );
                }
              },
            );
          case 1: // Tasks
            return CupertinoTabView(
              navigatorKey: tasksTabNavKey, // Assign key
              builder: (context) {
                return const CupertinoPageScaffold(child: TasksScreen());
              },
              routes: {
                '/':
                    (context) =>
                        const CupertinoPageScaffold(child: TasksScreen()),
                '/tasks/new':
                    (context) =>
                        const CupertinoPageScaffold(child: NewTaskScreen()),
              },
            );
          case 2: // Workbench
            return CupertinoTabView(
              navigatorKey: workbenchTabNavKey, // Assign key
              builder: (context) {
                return const CupertinoPageScaffold(child: WorkbenchScreen());
              },
              routes: {
                '/':
                    (context) =>
                        const CupertinoPageScaffold(child: WorkbenchScreen()),
              },
            );
          case 3: // Chat
            return CupertinoTabView(
              navigatorKey: chatTabNavKey, // Assign key
              builder: (context) {
                // Default builder shows the ChatScreen
                return const CupertinoPageScaffold(child: ChatScreen());
              },
              // Define the '/chat' route specifically for this tab's navigator
              routes: {
                '/':
                    (context) => const CupertinoPageScaffold(
                      child: ChatScreen(),
                    ), // Root of tab
                '/chat':
                    (context) => const CupertinoPageScaffold(
                      child: ChatScreen(),
                    ), // Route used for navigation
              },
            );
          case 4: // Settings
            return CupertinoTabView(
              navigatorKey: settingsTabNavKey, // Assign key
              builder: (context) {
                return const CupertinoPageScaffold(
                  child: SettingsScreen(isInitialSetup: false),
                );
              },
              routes: {
                '/':
                    (context) => const CupertinoPageScaffold(
                      child: SettingsScreen(isInitialSetup: false),
                    ),
              },
            );
          default:
            // Return an empty view for safety, though this shouldn't be reached
            return const SizedBox.shrink();
        }
      },
    );
  }
}
