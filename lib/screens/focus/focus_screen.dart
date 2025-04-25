import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/focus_instance.dart'; // Correct import
import 'package:flutter_memos/providers/focus_instances_provider.dart'; // Correct import
import 'package:flutter_memos/providers/focus_provider.dart'; // Correct import
// Use package import for widget within lib/screens
import 'package:flutter_memos/screens/focus/widgets/focus_detail_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Renamed from WorkbenchScreen
class FocusScreen extends ConsumerWidget {
  final String instanceId;

  const FocusScreen({super.key, required this.instanceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the specific instance details to get the name for the AppBar
    // Use the existing focusInstanceProvider defined below
    final instanceAsync = ref.watch(focusInstanceProvider(instanceId));
    // Watch the items provider for this specific instance
    final focusState = ref.watch(focusProviderFamily(instanceId)); // Use focus provider family

    // Check if focusState itself indicates loading or error for item details refresh
    final bool isRefreshing =
        focusState.isLoading; // Assuming isLoading covers refresh
    final bool canRefresh = !isRefreshing;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        // Use instance name from provider, show loading/error if needed
        // Use .when on the AsyncValue
        middle: instanceAsync.when(
          data:
              (instance) =>
                  Text(instance?.name ?? 'Focus Board'), // Handle null instance
                  loading: () => const CupertinoActivityIndicator(radius: 10),
          error: (err, stack) => const Text("Focus Board"), // Fallback title
        ),
        // Standard back button will be added by Navigator
        // Add trailing actions specific to the detail view
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.only(left: 8.0),
              onPressed: canRefresh
                  ? () => ref.read(focusProviderFamily(instanceId).notifier).refreshItemDetails() // Use focus provider family
                  : null,
              child: canRefresh
                  ? const Icon(CupertinoIcons.refresh)
                  : const CupertinoActivityIndicator(radius: 10),
            ),
            // Example: Overflow menu for "Back to instances"
            CupertinoButton(
              padding: const EdgeInsets.only(left: 8.0),
              child: const Icon(CupertinoIcons.ellipsis_vertical),
              onPressed: () => _showDetailActions(context, ref),
            ),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false, // Allow content to scroll to bottom edge
        // Add horizontal padding to the SafeArea
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0), // Added padding
          // Use CustomScrollView to host the detail view which is expected to return slivers
          child: CustomScrollView(
            slivers: [
              // Pass the instanceId to the detail view
              // Ensure FocusDetailView exists and is imported correctly
              FocusDetailView(instanceId: instanceId),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailActions(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Focus Board Actions'), // Updated text
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Back to Focus List'), // Updated text
            onPressed: () {
              Navigator.pop(context); // Close action sheet
              // Pop the current detail screen from the nested navigator
              Navigator.of(context).pop();
            },
          ),
          // Add other instance-specific actions here if needed
              CupertinoActionSheetAction(
                child: const Text('Reset Item Order'),
                onPressed: () {
                  Navigator.pop(context); // Close action sheet
                  // Call resetOrder on the notifier for the current instance
                  ref
                      .read(focusProviderFamily(instanceId).notifier) // Use focus provider family
                      .resetOrder();
                },
              ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

// Helper provider to watch a single instance by ID (useful for AppBar title)
// Return AsyncValue<FocusInstance?> to handle loading/error states and nullability
// NOTE: This duplicates the provider in focus_instances_provider.dart.
// Consider removing this and importing/using the one from focus_instances_provider.dart
// For now, keeping it to minimize changes, but it should be consolidated.
final focusInstanceProvider =
    Provider.family<AsyncValue<FocusInstance?>, String>((ref, instanceId) {
  final instancesState = ref.watch(focusInstancesProvider); // Use focus provider

      if (instancesState.isLoading) {
        return const AsyncValue.loading();
      }
      if (instancesState.error != null) {
        return AsyncValue.error(instancesState.error!, StackTrace.current);
      }

  try {
    // Use firstWhereOrNull from collection package for safety
    // Cast 'i' to FocusInstance before accessing id
        final instance = instancesState.instances.firstWhere(
          (i) => (i).id == instanceId,
        );
        return AsyncValue.data(instance);
  } catch (e) {
        // Instance not found, return data with null
        return const AsyncValue.data(null);
  }
});


// Add missing isRefreshingDetails to FocusState if needed
extension FocusStateExtension on FocusState {
  // Assuming isRefreshingDetails is not part of the state, return false or implement logic
  bool get isRefreshingDetails => false; // Placeholder
}

// Add missing refreshItemDetails to FocusNotifier if needed
extension FocusNotifierExtension on FocusNotifier {
  Future<void> refreshItemDetails() async {
    // Placeholder: Implement logic to refresh details of items in the focus board
    print("Placeholder: Refreshing item details for instance $instanceId");
    // Example: await _loadItems(); // If _loadItems also refreshes details
  }
  Future<void> resetOrder() async {
    // Placeholder: Implement logic to reset item order
    print("Placeholder: Resetting item order for instance $instanceId");
    // Example: await _saveItemsToPrefs(state.items..sort(...)); // Re-save with default sort
  }
}
