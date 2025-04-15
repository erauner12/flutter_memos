import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Import Material for ReorderableListView
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/workbench/widgets/workbench_item_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class WorkbenchScreen extends ConsumerWidget {
  const WorkbenchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workbenchState = ref.watch(workbenchProvider);
    final items = workbenchState.items;
    // Determine if refresh can be triggered
    final bool canRefresh =
        !workbenchState.isLoading && !workbenchState.isRefreshingDetails;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Workbench'),
        // Keep Reset Order button
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.arrow_up_arrow_down),
          onPressed: () => ref.read(workbenchProvider.notifier).resetOrder(),
        ),
        // Add Refresh button
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          // Disable while loading OR refreshing details
          onPressed:
              canRefresh
                  ? () =>
                      ref.read(workbenchProvider.notifier).refreshItemDetails()
                  : null,
          // Show activity indicator when busy
          child:
              canRefresh
                  ? const Icon(CupertinoIcons.refresh)
                  : const CupertinoActivityIndicator(radius: 10),
        ),
      ),
      child: SafeArea(
        child: Builder( // Use Builder to get context with theme
          builder: (context) {
            // Show loading indicator only on initial load when items are empty
            if (workbenchState.isLoading && items.isEmpty) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (workbenchState.error != null && items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle, size: 40, color: CupertinoColors.systemRed),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Error loading Workbench: ${workbenchState.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                        ),
                    ),
                    const SizedBox(height: 10),
                    CupertinoButton(
                      child: const Text('Retry'),
                      onPressed: () => ref.read(workbenchProvider.notifier).loadItems(),
                    ),
                  ],
                ),
              );
            }

            if (items.isEmpty && !workbenchState.isLoading) {
              // Ensure not loading when showing empty state
              return const Center(
                child: Text(
                  'Your Workbench is empty.\nAdd items via long-press or actions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.secondaryLabel),
                ),
              );
            }

            // Use ReorderableListView for drag-and-drop
            return ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
              ), // Add some padding
              buildDefaultDragHandles: false, // Disable the default handle
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                // IMPORTANT: Key MUST be present and unique for ReorderableListView
                // Wrap the tile in a listener to make it draggable
                return ReorderableDragStartListener(
                  index: index,
                  key: ValueKey(
                    'drag-${item.id}',
                  ), // Add a key to the listener too
                  child: WorkbenchItemTile(
                    // Pass the item reference which might contain populated details
                    key: ValueKey(
                      item.id,
                    ), // Keep key on the tile itself as well
                    itemReference: item,
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(workbenchProvider.notifier)
                    .reorderItems(oldIndex, newIndex);
              },
              // Remove the header loading indicator, use the trailing button instead
              // header: workbenchState.isLoading ? ... : null,
            );
          }
        ),
      ),
    );
  }
}
