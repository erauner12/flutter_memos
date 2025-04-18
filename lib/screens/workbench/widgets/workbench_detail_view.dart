import 'package:flutter/cupertino.dart';
// Keep for ReorderableListView
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/item_detail/item_detail_screen.dart';
import 'package:flutter_memos/screens/workbench/widgets/workbench_item_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkbenchDetailView extends ConsumerWidget {
  const WorkbenchDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workbenchState = ref.watch(activeWorkbenchProvider);
    final activeInstanceId = ref.watch(
      workbenchInstancesProvider.select((s) => s.activeInstanceId),
    );
    final items = workbenchState.items;

    // Loading/Error states for active workbench items
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
                onPressed:
                    () => ref.read(activeWorkbenchNotifierProvider).loadItems(),
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

    // Item List (Uses ReorderableListView which is now imported)
    // Wrap ReorderableListView.builder in a SliverToBoxAdapter or similar if needed,
    // but ReorderableListView itself isn't a sliver.
    // For direct use in CustomScrollView, we need a SliverReorderableList.
    // Let's use SliverList for now and handle reordering later if needed,
    // or keep ReorderableListView inside SliverToBoxAdapter.
    // Using SliverToBoxAdapter to contain the ReorderableListView.
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 50.0), // Padding for FAB/bottom bar space
      sliver: SliverReorderableList(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return WorkbenchItemTile(
            key: ValueKey(item.id), // Use unique item ID for key
            itemReference: item,
            index: index, // Pass index for reorder handle
            onTap: () {
              // Update last opened item for the *currently active* instance
              ref
                  .read(workbenchInstancesProvider.notifier)
                  .setLastOpenedItem(activeInstanceId, item.id);
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder:
                      (_) => ItemDetailScreen(itemId: item.referencedItemId),
                ),
              );
            },
          );
        },
        onReorder: (oldIndex, newIndex) {
          ref
              .read(activeWorkbenchNotifierProvider)
              .reorderItems(oldIndex, newIndex);
        },
      ),
    );
  }
}

// Helper SliverReorderableList (if not using a package)
// For simplicity, let's assume a package or implement basic SliverList first.
// Using SliverList for now, reordering needs SliverReorderableList implementation.

class SliverReorderableList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final void Function(int, int) onReorder;

  const SliverReorderableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    // This requires the Material ReorderableListView logic adapted for Slivers.
    // For now, returning a basic SliverList and noting reordering won't work visually
    // without a proper SliverReorderableList implementation or package.
    // Consider using `flutter_reorderable_list` package or similar if needed.

    // Placeholder using SliverList - Drag handles won't work correctly here.
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Wrap the item with ReorderableDragStartListener and potentially IndexTrackingContainer
          // This is complex to implement correctly from scratch.
          // Let's just build the item for now.
          return ReorderableDragStartListener(
             index: index,
             child: itemBuilder(context, index),
          );
        },
        childCount: itemCount,
      ),
    );

    /* // Correct approach would involve Material ReorderableList adapted:
    return SliverToBoxAdapter(
      child: ReorderableListView.builder(
         buildDefaultDragHandles: false, // Use handles in WorkbenchItemTile
         itemCount: itemCount,
         itemBuilder: itemBuilder,
         onReorder: onReorder,
         shrinkWrap: true, // Important for nesting in scroll views
         physics: const NeverScrollableScrollPhysics(), // Prevent internal scrolling
      )
    );
    */
  }
}
