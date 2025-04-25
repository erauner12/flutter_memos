import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/note_server_config_provider.dart'; // Import Note provider
import 'package:flutter_memos/providers/server_config_provider.dart'; // Keep for loadServerConfigProvider
import 'package:flutter_memos/screens/cache/cache_notes_screen.dart'; // Import Cache screen
import 'package:flutter_memos/screens/focus/focus_hub_screen.dart'; // Import Focus Hub screen
import 'package:flutter_memos/screens/home_tabs.dart'; // Import HomeTab enum and extension
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_memos/screens/studio/studio_screen.dart'; // Import Studio screen
import 'package:flutter_memos/screens/vault/vault_notes_screen.dart'; // Import Vault screen
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
    // TODO: Adjust this logic if Task server is no longer relevant or required
    final noteServerConfig = ref.watch(noteServerConfigProvider);
    // final taskServerConfig = ref.watch(taskServerConfigProvider); // If you had other entity types, would load them here
    // Consider setup needed if BOTH are null. Adjust if only one is required.
    // For now, assuming only Note server config matters for initial setup.
    final bool needsSetup = noteServerConfig == null;

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

class MainAppTabs extends StatefulWidget {
  const MainAppTabs({super.key});

  @override
  State<MainAppTabs> createState() => _MainAppTabsState();
}

class _MainAppTabsState extends State<MainAppTabs> {
  late CupertinoTabController _controller;

  // Updated map to use new HomeTab enum values
  final Map<int, GlobalKey<NavigatorState>> tabViewNavKeys = {
    HomeTab.vault.index: GlobalKey<NavigatorState>(),
    HomeTab.cache.index: GlobalKey<NavigatorState>(),
    HomeTab.focus.index: GlobalKey<NavigatorState>(),
    HomeTab.studio.index: GlobalKey<NavigatorState>(),
  };

  @override
  void initState() {
    super.initState();
    // Set initial tab to one of the new tabs, e.g., Vault
    _controller = CupertinoTabController(initialIndex: HomeTab.vault.index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Removed _notesOnGenerateRoute and _workbenchOnGenerateRoute as they are no longer needed

  @override
  Widget build(BuildContext context) {
    // Generate BottomNavigationBarItems from the new HomeTab enum
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
          // Standard pop-to-root or switch tab logic
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
      // Updated tabBuilder to use new HomeTab enum and screens
      tabBuilder: (BuildContext context, int index) {
        final HomeTab currentTab = HomeTab.values[index];
        switch (currentTab) {
          case HomeTab.vault:
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[HomeTab.vault.index],
              // Removed onGenerateRoute
              builder: (BuildContext context) => const VaultNotesScreen(),
            );
          case HomeTab.cache:
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[HomeTab.cache.index],
              // Removed onGenerateRoute
              builder: (BuildContext context) => const CacheNotesScreen(),
            );
          case HomeTab.focus:
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[HomeTab.focus.index],
              // Removed onGenerateRoute
              builder: (BuildContext context) => const FocusHubScreen(),
            );
          case HomeTab.studio:
            return CupertinoTabView(
              navigatorKey: tabViewNavKeys[HomeTab.studio.index],
              // Removed onGenerateRoute
              builder: (BuildContext context) => const StudioScreen(),
            );
        }
      },
    );
  }
}
