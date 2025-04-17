import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/items/items_screen.dart';
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
// REMOVED: final GlobalKey<NavigatorState> settingsTabNavKey = GlobalKey<NavigatorState>();


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
          // Index 0: Chat
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble),
            label: 'Chat',
          ),
          // Index 1: Workbench
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.briefcase),
            label: 'Workbench',
          ),
          // Index 2: Tasks
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.check_mark_circled),
            label: 'Tasks',
          ),
          // Index 3: Memos (Home)
          BottomNavigationBarItem(
            icon: Icon(
              CupertinoIcons.home,
            ), // Or appropriate icon for Memos/Items
            label: 'Home', // Change label to 'Home' as requested
          ),
          // REMOVED Settings Item
        ],
        // onTap is handled by the controller passed to CupertinoTabScaffold
        // No need for manual provider update here
      ),
      tabBuilder: (BuildContext context, int index) {
        switch (index) {
          case 0: // Chat
            return CupertinoTabView(
              navigatorKey: chatTabNavKey, // Keep key with content
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
              },
            );
          case 1: // Workbench
            return CupertinoTabView(
              navigatorKey: workbenchTabNavKey, // Keep key with content
              builder: (context) {
                return const CupertinoPageScaffold(child: WorkbenchScreen());
              },
              routes: {
                '/':
                    (context) =>
                        const CupertinoPageScaffold(child: WorkbenchScreen()),
              },
            );
          case 2: // Tasks
            return CupertinoTabView(
              navigatorKey: tasksTabNavKey, // Keep key with content
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
          case 3: // Memos (Home)
            return CupertinoTabView(
              navigatorKey: memosTabNavKey, // Keep key with content
              builder: (context) {
                return const CupertinoPageScaffold(
                  child: ItemsScreen(),
                ); // Assuming ItemsScreen is 'Home'
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
          // REMOVED case 4 (Settings)
          default:
            // Return an empty view for safety, though this shouldn't be reached
            return const SizedBox.shrink();
        }
      },
    );
  }
}
