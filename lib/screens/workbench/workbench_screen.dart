import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Import Material for ReorderableListView
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/workbench/widgets/workbench_item_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Convert to ConsumerStatefulWidget to call loadItems in initState
class WorkbenchScreen extends ConsumerStatefulWidget {
  const WorkbenchScreen({super.key});

  @override
  ConsumerState<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

class _WorkbenchScreenState extends ConsumerState<WorkbenchScreen> {

  @override
  void initState() {
    super.initState();
    // Trigger initial load when the screen is initialized
    // Use addPostFrameCallback to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Check if mounted before accessing ref
        ref.read(workbenchProvider.notifier).loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final workbenchState = ref.watch(workbenchProvider);
    final items = workbenchState.items;
    // Determine if refresh can be triggered
    final bool canRefresh =
        !workbenchState.isLoading && !workbenchState.isRefreshingDetails;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Workbench'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.arrow_up_arrow_down),
          onPressed: () => ref.read(workbenchProvider.notifier).resetOrder(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed:
              canRefresh
                  ? () =>
                      ref.read(workbenchProvider.notifier).refreshItemDetails()
                  : null,
          child:
              canRefresh
                  ? const Icon(CupertinoIcons.refresh)
                  : const CupertinoActivityIndicator(radius: 10),
        ),
      ),
      child: SafeArea(
        child: Builder(
          builder: (context) {
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
              return const Center(
                child: Text(
                  'Your Workbench is empty.\nAdd items via long-press or actions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.secondaryLabel),
                ),
              );
            }

            // Use ReorderableListView with custom drag handles
            return ReorderableListView.builder(
              // Ensure this is false to use the handles inside WorkbenchItemTile
              buildDefaultDragHandles: false,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                // Return the tile directly, passing the index and using item.id for the main key.
                // The ReorderableDragStartListener is now *inside* WorkbenchItemTile.
                return WorkbenchItemTile(
                  key: ValueKey(item.id), // Key for the tile widget itself
                  itemReference: item,
                  index: index, // Pass the index down
                );
              },
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(workbenchProvider.notifier)
                    .reorderItems(oldIndex, newIndex);
              },
              // Optional: Add padding to the list view itself if needed
              // padding: EdgeInsets.symmetric(vertical: 8),
            );
          }
        ),
      ),
    );
  }
}
