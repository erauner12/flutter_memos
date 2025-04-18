import 'package:flutter/cupertino.dart';
// Removed workbench_instances_provider import
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/workbench/widgets/workbench_item_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkbenchDetailView extends ConsumerWidget {
  final String instanceId; // Add instanceId parameter

  const WorkbenchDetailView({
    super.key,
    required this.instanceId, // Make it required
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the workbenchProviderFamily with the passed instanceId
    final workbenchState = ref.watch(workbenchProviderFamily(instanceId));
    // Removed activeInstanceId watch
    final items = workbenchState.items;

    // Loading/Error states for this specific instance's items
    if (workbenchState.isLoading && items.isEmpty) {
      return const SliverFillRemaining( // Use SliverFillRemaining for sliver context
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (workbenchState.error != null && items.isEmpty) {
      return SliverFillRemaining( // Use SliverFillRemaining for sliver context
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 40,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Error loading items: ${workbenchState.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              CupertinoButton(
                child: const Text('Retry'),
                // Use workbenchProviderFamily with instanceId to retry loading
                onPressed:
                    () =>
                        ref
                            .read(workbenchProviderFamily(instanceId).notifier)
                            .loadItems(),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state message
    if (items.isEmpty && !workbenchState.isLoading) {
      return const SliverFillRemaining( // Use SliverFillRemaining for sliver context
        child: Center(
          child: Text(
            'This Workbench is empty.\nAdd items via long-press or actions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.secondaryLabel),
          ),
        ),
      );
    }

    // Item List using SliverReorderableList with padding
    return SliverPadding(
      // Ensure consistent side margins and vertical padding
      padding: const EdgeInsets.only(
        left: 16.0, // Consistent side margin
        right: 16.0, // Consistent side margin
        top: 12.0,
        bottom: 50.0, // Keep bottom padding for scroll buffer
      ),
      // Use SliverReorderableList instead of SliverList
      sliver: SliverReorderableList(
        itemCount: items.length,
        // Callback when an item is dropped in a new position
        onReorder: (oldIndex, newIndex) {
          // Call the reorder method on the notifier for this specific instance
          ref
              .read(workbenchProviderFamily(instanceId).notifier)
              .reorderItems(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final item = items[index];
          // Add Padding wrapper for vertical spacing between items
          // IMPORTANT: The direct child of SliverReorderableList's itemBuilder
          // MUST have a Key. We apply it to the Padding here.
          return Padding(
            key: ValueKey(
              item.id,
            ), // Use unique item ID for the key required by ReorderableList
            padding: const EdgeInsets.only(
              bottom: 12.0,
            ), // Add space below each item
            // WorkbenchItemTile itself doesn't need the key now
            child: WorkbenchItemTile(
              itemReference: item,
              onTap: () {
                // Handle item tap for navigation/selection (existing logic)
                // Example: Navigate to item detail
                // ref.read(rootNavigatorKeyProvider).currentState?.pushNamed(...);
                print("Tapped on item: ${item.id}"); // Placeholder tap action
              },
              // Pass the index for the ReorderableDragStartListener inside the tile
              index: index,
            ),
          );
        },
      ),
    );
  }
}
