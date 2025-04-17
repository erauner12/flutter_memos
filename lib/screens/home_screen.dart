import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_memos/screens/tasks/tasks_screen.dart'; // Import TasksScreen
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_screen.dart';
import 'workbench/workbench_screen.dart';

// Provider to expose the TabController from the GlobalKey
final tabControllerProvider = StateProvider<CupertinoTabController?>(
  (ref) => null,
);

// GlobalKey to access CupertinoTabScaffold state (no explicit type needed)
final GlobalKey tabScaffoldKey = GlobalKey();
// GlobalKeys for each tab's navigator
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
  CupertinoTabController? _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize the controller and update the provider after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Access controller via the key's currentState
      final scaffoldState = tabScaffoldKey.currentState;
      if (mounted && scaffoldState is CupertinoTabScaffoldState) {
        _tabController = scaffoldState.controller;
        // Update the provider if the controller is not null
        if (_tabController != null &&
            ref.read(tabControllerProvider) != _tabController) {
          ref.read(tabControllerProvider.notifier).state = _tabController;
        }
      }
    });
  }

  @override
  void dispose() {
    // Optionally clear the provider state on dispose
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //    if (!mounted) { // Check if it's actually disposed
    //       ref.read(tabControllerProvider.notifier).state = null;
    //    }
    // });
    // Don't dispose the controller here, it's managed by CupertinoTabScaffold
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // Listen to the provider to potentially update the local controller if needed elsewhere
    // final externalController = ref.watch(tabControllerProvider);
    // if (_tabController != externalController) {
    //    // Handle potential external changes if necessary
    // }

    return CupertinoTabScaffold(
      key: tabScaffoldKey, // Assign the key
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
        // If using the provider, ensure the controller is updated on change
        onTap: (index) {
          // Update provider state if controller exists
          final scaffoldState = tabScaffoldKey.currentState;
          if (scaffoldState is CupertinoTabScaffoldState) {
            final currentController = scaffoldState.controller;
            if (currentController != null &&
                ref.read(tabControllerProvider) != currentController) {
              ref.read(tabControllerProvider.notifier).state =
                  currentController;
            }
          }
        },
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
                // Add other memo-related routes here if needed
                '/item-detail': (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments
                          as Map<String, dynamic>?;
                  final itemId = args?['itemId'] as String?;
                  // Import ItemDetailScreen if not already done
                  // return CupertinoPageScaffold(child: ItemDetailScreen(itemId: itemId ?? ''));
                  // Placeholder until ItemDetailScreen is imported/available
                  return CupertinoPageScaffold(
                    child: Center(
                      child: Text('Item Detail: ${itemId ?? 'Error'}'),
                    ),
                  );
                },
                '/edit-entity': (context) {
                  // Placeholder for edit screen route
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
