import 'package:flutter/material.dart';
import 'package:flutter_memos/screens/items/notes_hub_screen.dart'; // Reuse Notes Hub
import 'package:flutter_memos/screens/workbench/workbench_hub_screen.dart'; // Reuse Workbench Hub
// Import other screens you want to include in the web layout
// import 'package:flutter_memos/screens/settings_screen.dart';

/// A scaffold widget implementing the Blinko-like side navigation layout for web.
class WebLayout extends StatefulWidget {
  const WebLayout({super.key});

  @override
  State<WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<WebLayout> {
  int _selectedIndex = 0; // Tracks the selected item in the NavigationRail

  // Define the destinations for the side navigation
  final List<NavigationRailDestination> _navDestinations = [
    const NavigationRailDestination(
      icon: Icon(Icons.notes_outlined),
      selectedIcon: Icon(Icons.notes),
      label: Text('Notes'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.workspaces_outline),
      selectedIcon: Icon(Icons.workspaces),
      label: Text('Workbench'),
    ),
    // Add other destinations like Settings, Analytics etc.
    // const NavigationRailDestination(
    //   icon: Icon(Icons.settings_outlined),
    //   selectedIcon: Icon(Icons.settings),
    //   label: Text('Settings'),
    // ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all, // Show labels always
            destinations: _navDestinations,
            // Add other NavigationRail properties like leading/trailing widgets if needed
            // leading: IconButton(icon: Icon(Icons.menu), onPressed: () {}),
            // trailing: IconButton(icon: Icon(Icons.account_circle), onPressed: () {}),
            minWidth: 80, // Adjust width as needed
            groupAlignment: -0.8, // Align items towards the top
          ),
          const VerticalDivider(thickness: 1, width: 1), // Separator
          // Main Content Area
          Expanded(
            child: _buildMainContent(), // Dynamically build content based on selection
          ),
        ],
      ),
    );
  }

  /// Builds the main content widget based on the selected navigation index.
  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        // Reuse the existing NotesHubScreen (or ItemsScreen directly if preferred)
        return const NotesHubScreen();
      case 1:
        // Reuse the existing WorkbenchHubScreen
        return const WorkbenchHubScreen();
      // case 2:
      //   // Example: Reuse SettingsScreen
      //   return const SettingsScreen(isInitialSetup: false);
      default:
        // Fallback for unhandled indices
        return const Center(child: Text('Select an item'));
    }
  }
}