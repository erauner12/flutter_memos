import 'package:flutter/material.dart';
import 'package:flutter_memos/screens_web/blinko_web_home.dart';
// Import the new Settings screen
import 'package:flutter_memos/screens_web/blinko_web_settings.dart';
// Import the Workbench screen if you want it in the main nav
// import 'package:flutter_memos/screens_web/blinko_web_workbench.dart';

/// The main layout scaffold for the Blinko web application.
/// Includes AppBar, potentially a Drawer or NavigationRail, and manages the main content area.
class BlinkoWebLayout extends StatefulWidget {
  const BlinkoWebLayout({super.key});

  @override
  State<BlinkoWebLayout> createState() => _BlinkoWebLayoutState();
}

class _BlinkoWebLayoutState extends State<BlinkoWebLayout> {
  int _selectedIndex = 0; // Index for the currently selected screen

  // List of the main screens accessible from the layout
  static const List<Widget> _widgetOptions = <Widget>[
    BlinkoWebHome(),
    BlinkoWebSettings(), // Added Settings screen
    // Optionally add Workbench here if it's a main section
    // BlinkoWebWorkbench(),
  ];

  void _onItemTapped(int index) {
    // Prevent index out of bounds if Workbench isn't added yet
    if (index < _widgetOptions.length) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      // Handle tap on items beyond the main screens if necessary
      // e.g., navigate to a separate route like /workbench
      if (index == _widgetOptions.length) {
        // For the next item after the last one
         Navigator.pushNamed(context, '/workbench');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 600;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Blinko Web'),
            leading: !isLargeScreen
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    tooltip: 'Open navigation menu',
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  )
                : null, // No drawer icon on large screens with NavRail
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search',
                onPressed: () { /* Implement search */ },
              ),
              // Optional: Add Workbench button here if not in main nav
              IconButton(
                icon: const Icon(Icons.widgets_outlined),
                tooltip: 'Workbench',
                onPressed: () => Navigator.pushNamed(context, '/workbench'),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.person_outline),
                ),
              ),
            ],
          ),
          drawer: !isLargeScreen
              ? Drawer(
                  child: ListView(
                    padding: EdgeInsets.zero,
                      children: <Widget>[
                      DrawerHeader(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: Text(
                          'Blinko Navigation',
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 20),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.home_outlined),
                        title: const Text('Home'),
                        selected: _selectedIndex == 0,
                        onTap: () {
                          _onItemTapped(0);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: const Text('Resources'),
                        selected: _selectedIndex == 1,
                        onTap: () {
                          _onItemTapped(1);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Settings'),
                        selected: _selectedIndex == 2,
                        onTap: () {
                          _onItemTapped(2);
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      // Optional: Add Workbench link in drawer too
                      ListTile(
                        leading: const Icon(Icons.widgets_outlined),
                        title: const Text('Workbench'),
                        onTap: () {
                           Navigator.pop(context); // Close drawer first
                           Navigator.pushNamed(context, '/workbench');
                        },
                      ),
                    ],
                  ),
                )
              : null,
          body: Row(
            children: [
              if (isLargeScreen)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.selected,
                  // Add Settings destination
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.folder_outlined),
                      selectedIcon: Icon(Icons.folder),
                      label: Text('Resources'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                    // Optionally add Workbench here if it's a main section
                    // NavigationRailDestination(
                    //   icon: Icon(Icons.widgets_outlined),
                    //   selectedIcon: Icon(Icons.widgets),
                    //   label: Text('Workbench'),
                    // ),
                  ],
                ),
              // Main content area displays the selected widget
              Expanded(
                child: Center(
                  // Ensure index is within bounds
                  child:
                      _selectedIndex < _widgetOptions.length
                         ? _widgetOptions.elementAt(_selectedIndex)
                         : const Center(child: Text("Invalid selection")), // Fallback
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/ai'),
            tooltip: 'AI Chat',
            child: const Icon(Icons.chat_bubble_outline),
          ),
        );
      },
    );
  }
}
