import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/items/items_screen.dart'; // Import ItemsScreen
import 'package:flutter_riverpod/flutter_riverpod.dart';

// HomeScreen is now just a simple wrapper around ItemsScreen for the first tab.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Directly return the content for the "Home" tab.
    // The CupertinoPageScaffold might be added by the CupertinoTabView builder
    // in MainAppTabs, or can be added here if needed for specific nav bar/background.
    // For simplicity, let's assume ItemsScreen handles its own scaffold if necessary,
    // or return it directly.
    return const ItemsScreen();

    // If ItemsScreen doesn't include a Scaffold, you might need one:
    // return const CupertinoPageScaffold(
    //   child: ItemsScreen(),
    // );
  }
}

// Removed _HomeScreenState, homeTabControllerProvider, homeTabIndexMapProvider,
// and global navigation keys as they are now managed in config_check_wrapper.dart
