import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/utils/memo_utils.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Add this import for Slidable

class MemoListItem extends ConsumerStatefulWidget {
  final Memo memo;
  final int index; // Add index for selection tracking

  const MemoListItem({super.key, required this.memo, required this.index});

  @override
  _MemoListItemState createState() => _MemoListItemState();
}

class _MemoListItemState extends ConsumerState<MemoListItem> {
  void _toggleHideMemo(BuildContext context, WidgetRef ref) {
    final hiddenMemoIds = ref.read(hiddenMemoIdsProvider);
    final memoIdToToggle = widget.memo.id; // Use local variable for clarity

    if (hiddenMemoIds.contains(memoIdToToggle)) {
      // Unhide memo - Selection doesn't need adjustment here
      ref
          .read(hiddenMemoIdsProvider.notifier)
          .update((state) => state..remove(memoIdToToggle));
    } else {
      // --- New Selection Update Logic (Downward Preference) ---
      final currentSelectedId = ref.read(ui_providers.selectedMemoIdProvider);
      final memosBeforeAction = ref.read(
        filteredMemosProvider,
      ); // Read list BEFORE action
      final memoIdToAction =
          memoIdToToggle; // ID of the memo being removed/hidden
      String? nextSelectedId = currentSelectedId; // Default to no change

      // Only adjust selection if the item being actioned is currently selected
      if (currentSelectedId == memoIdToAction && memosBeforeAction.isNotEmpty) {
        final actionIndex = memosBeforeAction.indexWhere(
          (m) => m.id == memoIdToAction,
        );

        if (actionIndex != -1) {
          // Ensure the item was found
          if (memosBeforeAction.length == 1) {
            // List will be empty after action
            nextSelectedId = null;
          } else if (actionIndex < memosBeforeAction.length - 1) {
            // If NOT the last item, select the item originally *after* it.
            nextSelectedId = memosBeforeAction[actionIndex + 1].id;
          } else {
            // If it IS the last item, select the item originally *before* it (the new last item).
            nextSelectedId = memosBeforeAction[actionIndex - 1].id;
          }
        } else {
          // Memo to action wasn't found in the list? Clear selection.
          nextSelectedId = null;
        }
      }
      // --- End New Selection Update Logic ---

      // Hide memo (optimistic UI update via provider state change)
      ref
          .read(hiddenMemoIdsProvider.notifier)
          .update((state) => state..add(memoIdToToggle));

      // Update selection state *after* optimistic update
      // Check if the selection actually needs changing before updating the state
      if (nextSelectedId != currentSelectedId) {
        ref.read(ui_providers.selectedMemoIdProvider.notifier).state =
            nextSelectedId;
      }

      // Show a confirmation that the memo was hidden
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memo hidden'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Force UI refresh to update visibility - Keep this for now, might be removable
    // if visibleMemosListProvider reacts correctly to hiddenMemoIdsProvider changes.
    ref.read(memosNotifierProvider.notifier).refresh();
  }

  void _navigateToMemoDetail(BuildContext context, WidgetRef ref) {
    // Set selected memo ID when navigating to detail
    // This line is crucial - ensure it runs before navigation
    ref.read(ui_providers.selectedMemoIdProvider.notifier).state =
        widget.memo.id;

    Navigator.pushNamed(
      context,
      '/memo-detail',
      arguments: {'memoId': widget.memo.id},
    );
  }

  Future<void> _onCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.memo.content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memo content copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Toggle selection of a memo in multi-select mode
  void _toggleMultiSelection(String memoId) {
    final currentSelection = Set<String>.from(
      ref.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
    );

    if (currentSelection.contains(memoId)) {
      currentSelection.remove(memoId);
    } else {
      currentSelection.add(memoId);
    }

    ref
        .read(ui_providers.selectedMemoIdsForMultiSelectProvider.notifier)
        .state = currentSelection;

    if (kDebugMode) {
      print('[MemoListItem] Multi-selection toggled for memo ID: $memoId');
      print('[MemoListItem] Current selection: ${currentSelection.join(', ')}');
    }
  }

  void _onEdit(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/edit-entity', // Use the generic route
      arguments: {
        'entityType': 'memo',
        'entityId': widget.memo.id,
      }, // Specify type and ID
    );
  }

  void _onDelete(BuildContext context) async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this memo?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      try {
        if (kDebugMode) {
          print(
            '[MemoListItem] Calling deleteMemoProvider for memo ID: ${widget.memo.id}',
          );
        }

        // First, immediately add the memo to hidden IDs to remove it from UI
        ref
            .read(hiddenMemoIdsProvider.notifier)
            .update((state) => state..add(widget.memo.id));

        // Then perform the actual delete operation
        await ref.read(deleteMemoProvider(widget.memo.id))();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Memo deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // If deletion fails, show error and remove from hidden IDs
        ref
            .read(hiddenMemoIdsProvider.notifier)
            .update((state) => state..remove(widget.memo.id));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting memo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (kDebugMode) {
          print('[MemoListItem] Error deleting memo: $e');
        }
      }
    }
  }

  void _onArchive(BuildContext context) {
    ref.read(archiveMemoProvider(widget.memo.id))().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memo archived successfully'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _onTogglePin(BuildContext context) {
    ref.read(togglePinMemoProvider(widget.memo.id))().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.memo.pinned ? 'Memo unpinned' : 'Memo pinned'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for selected memo ID instead of index
    final selectedMemoId = ref.watch(ui_providers.selectedMemoIdProvider);
    final isSelected = selectedMemoId == widget.memo.id;

    // Watch for multi-select mode
    final isMultiSelectMode = ref.watch(
      ui_providers.memoMultiSelectModeProvider,
    );
    final selectedIds = ref.watch(
      ui_providers.selectedMemoIdsForMultiSelectProvider,
    );
    final isMultiSelected = selectedIds.contains(widget.memo.id);

    if (isSelected && kDebugMode) {
      print(
        '[MemoListItem] Memo ID ${widget.memo.id} at index ${widget.index} is selected',
      );
    }

    // Create the main card content
    Widget cardContent = MemoCard(
      id: widget.memo.id,
      content: widget.memo.content,
      pinned: widget.memo.pinned,
      updatedAt: widget.memo.updateTime,
      showTimeStamps: true,
      isSelected: isSelected, // Use ID-based selection
      highlightTimestamp: MemoUtils.formatTimestamp(widget.memo.updateTime),
      timestampType: 'Updated', // Always 'Updated'
      onTap:
          isMultiSelectMode
              ? () => _toggleMultiSelection(widget.memo.id)
              : () => _navigateToMemoDetail(context, ref),
      onArchive: () => _onArchive(context),
      onDelete: () => _onDelete(context),
      onHide: () => _toggleHideMemo(context, ref),
      onTogglePin: () => _onTogglePin(context),
      onBump: () async {
        try {
          await ref.read(bumpMemoProvider(widget.memo.id))();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Memo bumped!'),
                duration: Duration(seconds: 1),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to bump memo: ${e.toString().substring(0, 50)}...',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );

    // In multi-select mode, add a checkbox and adjust the card
    if (isMultiSelectMode) {
      // Add extra visual indicator for multi-selected items
      if (isMultiSelected) {
        cardContent = Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: cardContent,
        );
      }

      // Return a Row directly with Checkbox instead of wrapping with Dismissible/Slidable
      return Row(
        children: [
          Checkbox(
            value: isMultiSelected,
            onChanged: (value) => _toggleMultiSelection(widget.memo.id),
          ),
          Expanded(child: cardContent),
        ],
      );
    }

    // In normal mode, use Dismissible and Slidable
    return Dismissible(
      key: ValueKey('dismissible-${widget.memo.id}'),
      background: Container(
        color: Colors.orange,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16.0),
        child: const Row(
          children: [
            SizedBox(width: 16),
            Icon(Icons.visibility_off, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Hide',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Text(
          'Delete',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // First, immediately add the memo to hidden IDs to remove it from UI
          ref
              .read(hiddenMemoIdsProvider.notifier)
              .update((state) => state..add(widget.memo.id));

          // Then trigger the API delete operation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(deleteMemoProvider(widget.memo.id))().then((_) {
              // Use a post-frame callback for UI updates to avoid build phase issues
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // These operations are safe even if the widget is no longer mounted
                ref.read(memosNotifierProvider.notifier).refresh();
                ref
                    .read(hiddenMemoIdsProvider.notifier)
                    .update((state) => state..remove(widget.memo.id));
              });
            });
          });
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Hide memo
          _toggleHideMemo(context, ref);
          return false; // Don't remove from list
        } else if (direction == DismissDirection.endToStart) {
          // Delete memo
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Delete'),
                content: const Text(
                  'Are you sure you want to delete this memo?',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );
        }
        return false;
      },
      child: Slidable(
        key: ValueKey('slidable-${widget.memo.id}'),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _onEdit(context),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
              autoClose: true,
            ),
            SlidableAction(
              onPressed: (_) => _onTogglePin(context),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              icon:
                  widget.memo.pinned ? Icons.push_pin_outlined : Icons.push_pin,
              label: widget.memo.pinned ? 'Unpin' : 'Pin',
              autoClose: true,
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _onDelete(context),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              autoClose: true,
            ),
            SlidableAction(
              onPressed: (_) => _onArchive(context),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              icon: Icons.archive,
              label: 'Archive',
              autoClose: true,
            ),
          ],
        ),
        child: Stack(
          children: [
            cardContent,
            // Archive button positioned at top-right corner
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.archive_outlined, size: 20),
                tooltip: 'Archive',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                color: Colors.grey,
                onPressed: () => _onArchive(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}