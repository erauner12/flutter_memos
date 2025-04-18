import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/item_detail/item_detail_screen.dart';
import 'package:flutter_memos/screens/workbench/widgets/workbench_item_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkbenchDetailView extends ConsumerWidget {
  const WorkbenchDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the activeWorkbenchProvider which automatically tracks the active instance
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
                // Use activeWorkbenchNotifierProvider to retry loading for the active instance
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

    // Item List using standard SliverList
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 50.0), // Padding for FAB/bottom bar space
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return WorkbenchItemTile(
            key: ValueKey(item.id), // Use unique item ID for key
            itemReference: item,
            // Removed index parameter as reordering is disabled for now
            // index: index,
            onTap: () {
              // Update last opened item for the *currently active* instance
              ref
                  .read(workbenchInstancesProvider.notifier)
                  .setLastOpenedItem(activeInstanceId, item.id);
              // Navigate using the context from the builder, which should be within the nested navigator
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder:
                      (_) => ItemDetailScreen(itemId: item.referencedItemId),
                ),
              );
            },
          );
        },
          childCount: items.length),
      ),
    );
  }
}

// Removed SliverReorderableList helper class as it's no longer used.
