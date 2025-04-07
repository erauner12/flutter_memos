import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
// Removed Material imports: Colors, Icons, Theme, Dismissible, DismissDirection
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
  // Add the callback parameter
  final VoidCallback? onMoveToServer;

  const MemoListItem({
    super.key,
    required this.memo,
    required this.index,
    this.onMoveToServer, // Add to constructor
  });

  @override
  MemoListItemState createState() => MemoListItemState();
}

class MemoListItemState extends ConsumerState<MemoListItem> {
  // Add GlobalKey to access MemoCard's state
  final GlobalKey<MemoCardState> _memoCardKey = GlobalKey<MemoCardState>();

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

      // Confirmation SnackBar removed - UI change is sufficient feedback
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

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/memo-detail', arguments: {'memoId': widget.memo.id});
  }

  // Removed unused _onCopy method

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
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/edit-entity', // Use the generic route
      arguments: {
        'entityType': 'memo',
        'entityId': widget.memo.id,
      }, // Specify type and ID
    );
  }

  void _onDelete(BuildContext context) async {
    // Show confirmation dialog first
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this memo?'),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
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

        // Success SnackBar removed
      } catch (e) {
        // If deletion fails, show error and remove from hidden IDs
        ref
            .read(hiddenMemoIdsProvider.notifier)
            .update((state) => state..remove(widget.memo.id));

        if (mounted) {
          // Show Cupertino Error Dialog
          showCupertinoDialog(
            context:
                context, // Use the current context since we checked mounted
            builder:
                (ctx) => CupertinoAlertDialog(
                  title: const Text('Error'),
                  content: Text('Failed to delete memo: $e'),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: const Text('OK'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
          );
        }

        if (kDebugMode) {
          print('[MemoListItem] Error deleting memo: $e');
        }
      }
    }
  }

  // Add the missing methods
  void _onArchive(BuildContext context) {
    ref.read(archiveMemoProvider(widget.memo.id))().then((_) {
      // Success SnackBar removed
    });
  }

  void _onTogglePin(BuildContext context) {
    ref.read(togglePinMemoProvider(widget.memo.id))().then((_) {
      // Confirmation SnackBar removed
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

    // Create the main card content without adding the GlobalKey yet
    Widget buildMemoCard({bool isContextMenuChild = false}) {
      return MemoCard(
        // Only add the GlobalKey to the main instance, not the context menu copy
        key: isContextMenuChild ? null : _memoCardKey,
        id: widget.memo.id,
        content: widget.memo.content,
        pinned: widget.memo.pinned,
        updatedAt: widget.memo.updateTime,
        showTimeStamps: true,
        isSelected: isSelected && !isMultiSelectMode,
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
          } catch (e) {
            if (mounted) {
              showCupertinoDialog(
                context: context,
                builder:
                    (ctx) => CupertinoAlertDialog(
                      title: const Text('Error'),
                      content: Text(
                        'Failed to bump memo: ${e.toString().substring(0, 50)}...',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          isDefaultAction: true,
                          child: const Text('OK'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
              );
            }
          }
        },
        onMoveToServer: widget.onMoveToServer,
      );
    }

    // Use the function to create the main cardContent
    final Widget cardContent = buildMemoCard();

    // In multi-select mode, return a completely different widget structure without Slidable/Dismissible
    if (isMultiSelectMode) {
      // Add extra visual indicator for multi-selected items
      Widget finalContent = cardContent;
      if (isMultiSelected) {
        finalContent = Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: CupertinoTheme.of(context).primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: cardContent,
        );
      }

      // Return a Row directly with Checkbox instead of wrapping with Dismissible/Slidable
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0, right: 8.0),
              child: CupertinoCheckbox(
                value: isMultiSelected,
                onChanged: (value) => _toggleMultiSelection(widget.memo.id),
              ),
            ),
            Expanded(child: finalContent),
          ],
        ),
      );
    }

    return Slidable(
      key: ValueKey('slidable-${widget.memo.id}'),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _onEdit(context),
            backgroundColor: CupertinoColors.systemBlue,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.pencil,
            label: 'Edit',
            autoClose: true,
          ),
          SlidableAction(
            onPressed: (_) => _onTogglePin(context),
            backgroundColor: CupertinoColors.systemOrange,
            foregroundColor: CupertinoColors.white,
            icon:
                widget.memo.pinned
                    ? CupertinoIcons.pin_slash_fill
                    : CupertinoIcons.pin_fill,
            label: widget.memo.pinned ? 'Unpin' : 'Pin',
            autoClose: true,
          ),
          SlidableAction(
            onPressed: (_) => _toggleHideMemo(context, ref),
            backgroundColor: CupertinoColors.systemGrey,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.eye_slash_fill,
            label: 'Hide',
            autoClose: true,
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _onDelete(context),
            backgroundColor: CupertinoColors.destructiveRed,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.delete,
            label: 'Delete',
            autoClose: true,
          ),
          SlidableAction(
            onPressed: (_) => _onArchive(context),
            backgroundColor: CupertinoColors.systemPurple,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.archivebox_fill,
            label: 'Archive',
            autoClose: true,
          ),
        ],
      ),
      child: CupertinoContextMenu(
        actions: [
          CupertinoContextMenuAction(
            trailingIcon: CupertinoIcons.pencil,
            onPressed: () {
              Navigator.of(context).pop();
              _onEdit(context);
            },
            child: const Text('Edit'),
          ),
          CupertinoContextMenuAction(
            trailingIcon:
                widget.memo.pinned
                    ? CupertinoIcons.pin_slash
                    : CupertinoIcons.pin,
            onPressed: () {
              Navigator.of(context).pop();
              _onTogglePin(context);
            },
            child: Text(widget.memo.pinned ? 'Unpin' : 'Pin'),
          ),
          CupertinoContextMenuAction(
            trailingIcon: CupertinoIcons.archivebox,
            onPressed: () {
              Navigator.of(context).pop();
              _onArchive(context);
            },
            child: const Text('Archive'),
          ),
          CupertinoContextMenuAction(
            isDestructiveAction: true,
            trailingIcon: CupertinoIcons.delete,
            onPressed: () {
              Navigator.of(context).pop();
              _onDelete(context);
            },
            child: const Text('Delete'),
          ),
        ],
        // Create a new instance of the MemoCard for the context menu
        // without passing the GlobalKey to avoid conflicts
        child: buildMemoCard(isContextMenuChild: true),
      ),
    );
  }
}
