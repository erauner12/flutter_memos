import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/workbench_instance.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/workbench/widgets/workbench_detail_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkbenchScreen extends ConsumerWidget {
  final String instanceId;

  const WorkbenchScreen({super.key, required this.instanceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the specific instance details to get the name for the AppBar
    final instanceAsync = ref.watch(workbenchInstanceProvider(instanceId));
    // Watch the items provider for this specific instance
    final workbenchState = ref.watch(workbenchProviderFamily(instanceId));

    final bool canRefresh = !workbenchState.isLoading && !workbenchState.isRefreshingDetails;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        // Use instance name from provider, show loading/error if needed
        middle: instanceAsync.when(
          data: (instance) => Text(instance?.name ?? 'Workbench'), // Handle null instance
          loading: () => const CupertinoActivityIndicator(radius: 10),
          error: (err, stack) => const Text("Workbench"), // Fallback title
        ),
        // Standard back button will be added by Navigator
        // Add trailing actions specific to the detail view
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.only(left: 8.0),
              onPressed: canRefresh
                  ? () => ref.read(workbenchProviderFamily(instanceId).notifier).refreshItemDetails()
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
            // Optional: Settings button if needed here
            // CupertinoButton(
            //   padding: EdgeInsets.zero,
            //   child: const Icon(CupertinoIcons.settings, size: 22),
            //   onPressed: () {
            //     Navigator.of(context, rootNavigator: true).push( // Use rootNavigator if pushing outside nested nav
            //       CupertinoPageRoute(
            //         builder: (context) => const SettingsScreen(isInitialSetup: false),
            //       ),
            //     );
            //   },
            // ),
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
              WorkbenchDetailView(instanceId: instanceId),
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
        title: const Text('Workbench Actions'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Back to Instances List'),
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
                      .read(workbenchProviderFamily(instanceId).notifier)
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
// Return AsyncValue<WorkbenchInstance?> to handle loading/error states and nullability
final workbenchInstanceProvider =
    Provider.family<AsyncValue<WorkbenchInstance?>, String>((ref, instanceId) {
  final instancesState = ref.watch(workbenchInstancesProvider);

      if (instancesState.isLoading) {
        return const AsyncValue.loading();
      }
      if (instancesState.error != null) {
        return AsyncValue.error(instancesState.error!, StackTrace.current);
      }

  try {
    // Use firstWhereOrNull from collection package for safety
    // Cast 'i' to WorkbenchInstance before accessing id
        final instance = instancesState.instances.firstWhere(
          (i) => (i).id == instanceId,
        );
        return AsyncValue.data(instance);
  } catch (e) {
        // Instance not found, return data with null
        return const AsyncValue.data(null);
  }
});
