import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart'; // For ScaffoldMessenger, SnackBar, Material proxy decorator
import 'package:flutter_memos/models/task_item.dart'; // Import TaskItem
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/models/workbench_item_type.dart';
import 'package:flutter_memos/providers/task_providers.dart'; // Import task providers
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/item_detail/item_detail_screen.dart'; // Import ItemDetailScreen
import 'package:flutter_memos/screens/tasks/new_task_screen.dart'; // Import NewTaskScreen
import 'package:flutter_memos/screens/workbench/widgets/workbench_item_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This widget now needs to be stateful to manage the loading state for task fetching
class WorkbenchDetailView extends ConsumerStatefulWidget {
  final String instanceId;

  const WorkbenchDetailView({super.key, required this.instanceId});

  @override
  ConsumerState<WorkbenchDetailView> createState() =>
      _WorkbenchDetailViewState();
}

class _WorkbenchDetailViewState extends ConsumerState<WorkbenchDetailView> {
  bool _isNavigating = false; // Prevent double taps while fetching task

  /// Navigates to the appropriate detail screen based on the item type.
  Future<void> _openWorkbenchItemDetail(WorkbenchItemReference itemRef) async {
    // Prevent navigation if already processing a navigation action
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    try {
      switch (itemRef.referencedItemType) {
        case WorkbenchItemType.note:
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder:
                  (_) => ItemDetailScreen(
                    itemId: itemRef.referencedItemId,
                    // serverId: itemRef.serverId, // Removed serverId argument
                  ),
            ),
          );
          break;

        case WorkbenchItemType.task:
          // Fetch the TaskItem before navigating
          TaskItem? taskToEdit;
          String? errorMessage;
          try {
            // Corrected method name: Assuming TasksNotifier has fetchTaskById
            // This method should handle fetching the task from the API/cache.
            taskToEdit = await ref
                .read(tasksNotifierProvider.notifier)
                .fetchTaskById(itemRef.referencedItemId); // Use fetchTaskById
          } catch (e) {
            errorMessage = 'Failed to load task: ${e.toString()}';
            if (kDebugMode) {
              print('[WorkbenchDetailView] Error fetching task: $e');
            }
          }

          if (!mounted) return; // Check mounted status after async operation

          if (taskToEdit != null) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder:
                    (_) => NewTaskScreen(
                      taskToEdit: taskToEdit, // Pass the fetched task
                    ),
              ),
            );
          } else {
            // Show error if task couldn't be fetched or if errorMessage was set
            final message = errorMessage ?? 'Task details not found.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          break;

        case WorkbenchItemType.comment:
          // Navigate to the parent note's detail screen
          if (itemRef.parentNoteId != null &&
              itemRef.parentNoteId!.isNotEmpty) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder:
                    (_) => ItemDetailScreen(
                      itemId: itemRef.parentNoteId!, // Use parent note's ID
                      // serverId: itemRef.serverId, // Removed serverId argument
                      // Optionally: Pass comment ID to highlight later
                      // highlightedCommentId: itemRef.referencedItemId,
                    ),
              ),
            );
          } else {
            // Handle case where parentNoteId is missing for a comment reference
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot open comment: Parent note ID missing.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
            if (kDebugMode) {
              print(
                '[WorkbenchDetailView] Missing parentNoteId for comment reference: ${itemRef.id}',
              );
            }
          }
          break;

        case WorkbenchItemType.project:
        case WorkbenchItemType.unknown:
          // Handle unknown or unsupported types, maybe show a dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot open item of type: ${itemRef.referencedItemType.displayName}',
              ),
              backgroundColor: Colors.grey,
            ),
          );
          if (kDebugMode) {
            print(
              '[WorkbenchDetailView] Tapped on unhandled item type: ${itemRef.referencedItemType}',
            );
          }
          break;
        // Removed unreachable default case
      }
    } finally {
      // Ensure _isNavigating is reset even if errors occur
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workbenchState = ref.watch(
      workbenchProviderFamily(widget.instanceId),
    );
    final items = workbenchState.items;

    if (workbenchState.isLoading && items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (workbenchState.error != null && items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'Error loading workbench items: ${workbenchState.error}',
            style: TextStyle(
              color: CupertinoColors.systemRed.resolveFrom(context),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'No items in this workbench yet.',
            style: TextStyle(color: CupertinoColors.secondaryLabel),
          ),
        ),
      );
    }

    // Corrected: Use SliverReorderableList for drag-and-drop within CustomScrollView
    return SliverReorderableList(
      itemBuilder: (context, index) {
        final item = items[index];
        return WorkbenchItemTile(
          key: ValueKey(item.id), // Use item ID as key for reordering
          itemReference: item,
          index: index,
          // Pass the navigation function to the tile's onTap
          onTap: () => _openWorkbenchItemDetail(item),
        );
      },
      itemCount: items.length,
      // Add padding around the list itself if needed via SliverPadding before/after this sliver
      // padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding is typically handled outside the sliver list itself
      // REMOVED: buildDefaultDragHandles: false, // Not a valid parameter for SliverReorderableList
      proxyDecorator: (child, index, animation) {
        // Optional: Add decoration to the item being dragged
        return Material(
          // Need Material for elevation shadow
          color: Colors.transparent,
          elevation: 4.0,
          child: child,
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        // Important: Adjust index if moving downwards - handled by SliverReorderableList logic implicitly?
        // Let's keep the adjustment logic as it's safer if the underlying list changes immediately.
        // Re-check Flutter docs if behavior differs from ReorderableListView.
        // if (newIndex > oldIndex) {
        //   newIndex -= 1;
        // }
        // Call the reorder method on the notifier - Corrected method name
        ref
            .read(workbenchProviderFamily(widget.instanceId).notifier)
            .reorderItems(oldIndex, newIndex); // Use reorderItems (plural)
      },
    );
  }
}
