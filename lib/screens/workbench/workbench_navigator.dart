import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/workbench/workbench_hub_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed imports for navigation_providers and workbench_screen as they are no longer needed here

// This widget now primarily serves as the root content widget for the Workbench tab.
// Navigation within this tab is handled by the CupertinoTabView in config_check_wrapper.dart
class WorkbenchNavigator extends ConsumerWidget {
  const WorkbenchNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No longer needs to watch the key or listen for reselect here.
    // The CupertinoTabView handles the navigation stack.

    // Return the initial screen for the Workbench tab.
    return const WorkbenchHubScreen();
  }
}
