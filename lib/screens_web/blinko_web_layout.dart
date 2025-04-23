import 'package:flutter/material.dart';
import 'package:flutter_memos/screens_web/blinko_web_home.dart';
import 'package:flutter_memos/screens_web/blinko_web_resources.dart';
// Import other web screens as needed

/// The main layout scaffold for the Blinko web application.
/// Includes AppBar, potentially a Drawer or NavigationRail, and manages the main content area.
class BlinkoWebLayout extends StatefulWidget {
  const BlinkoWebLayout({Key? key}) : super(key: key);

  @override
  _BlinkoWebLayoutState createState() => _BlinkoWebLayoutState();
}

class _BlinkoWebLayoutState extends State<BlinkoWebLayout> {
  int _selectedIndex = 0; // Index for the currently selected screen

  // List of the main screens accessible from the layout
  static const List<Widget> _widgetOptions = <Widget>[
    BlinkoWebHome(),
    BlinkoWebResources(),
    // Add other screens like Settings, Analytics here
    // Example: BlinkoWebSettings(),
    Center(child: Text('Settings Placeholder')), // Placeholder for Settings
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to adapt layout based on screen width
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 600; // Example breakpoint

        return Scaffold(
          appBar: AppBar(
            title: const Text('Blinko Web'),
            // Optionally hide menu icon on large screens if using NavigationRail
            // leading: isLargeScreen ? null : IconButton(icon: Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
            actions: [
              // Add actions like search, user profile, etc.
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () { /* Implement search */ },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  // Replace with actual user avatar logic
                  child: const Icon(Icons.person),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ),
            ],
          ),
          // Use Drawer for smaller screens
          drawer: !isLargeScreen
              ? Drawer(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      const DrawerHeader(
                        decoration: BoxDecoration(
                          color: Colors.blue, // Customize header
                        ),
                        child: Text('Navigation'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.home),
                        title: const Text('Home'),
                        selected: _selectedIndex == 0,
                        onTap: () {
                          _onItemTapped(0);
                          Navigator.pop(context); // Close the drawer
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.folder),
                        title: const Text('Resources'),
                        selected: _selectedIndex == 1,
                        onTap: () {
                          _onItemTapped(1);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        selected: _selectedIndex == 2,
                        onTap: () {
                          _onItemTapped(2);
                          Navigator.pop(context);
                        },
                      ),
                      // Add other navigation items
                    ],
                  ),
                )
              : null, // No drawer on large screens if using NavigationRail
          body: Row(
            children: [
              // Use NavigationRail for larger screens
              if (isLargeScreen)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.selected, // Show labels when selected
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
                    // Add other destinations
                  ],
                  // Add leading/trailing widgets if needed (e.g., FAB, logo)
                  // leading: FloatingActionButton(onPressed: () {}, child: Icon(Icons.add)),
                ),
              // Main content area
              Expanded(
                child: Center(
                  child: _widgetOptions.elementAt(_selectedIndex),
                ),
              ),
            ],
          ),
          // Floating Action Button for quick actions (e.g., navigate to AI)
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
