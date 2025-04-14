import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
// Removed Material imports: Colors, Icons, Theme, Dismissible, DismissDirection
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem instead of Memo
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/utils/memo_utils.dart'; // Keep for formatting utils or rename/replace
import 'package:flutter_memos/widgets/memo_card.dart'; // Keep MemoCard or rename/refactor
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Add this import for Slidable

class MemoListItem extends ConsumerStatefulWidget {
  final NoteItem memo; // Changed type to NoteItem
  final int index; // Add index for selection tracking
  // Add the callback parameter
  final VoidCallback? onMoveToServer;

  const MemoListItem({
    super.key,
    required this.memo, // Changed type to NoteItem
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
        filteredNotesProvider, // Use renamed provider
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
    // if visibleNotesListProvider reacts correctly to hiddenMemoIdsProvider changes.
    ref.read(notesNotifierProvider.notifier).refresh(); // Use renamed provider
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
        'entityType': 'note', // Changed type to 'note'
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
          content: const Text(
            'Are you sure you want to delete this note?',
          ), // Updated text
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
            '[MemoListItem] Calling deleteNoteProvider for note ID: ${widget.memo.id}', // Updated log
          );
        }

        // First, immediately add the memo to hidden IDs to remove it from UI
        ref
            .read(hiddenMemoIdsProvider.notifier)
            .update((state) => state..add(widget.memo.id));

        // Then perform the actual delete operation using renamed provider
        await ref.read(
          deleteNoteProvider(widget.memo.id),
        )(); // Use renamed provider

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
                  content: Text('Failed to delete note: $e'), // Updated text
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
          print('[MemoListItem] Error deleting note: $e'); // Updated log
        }
      }
    }
  }

  void _onArchive(BuildContext context) {
    // Use renamed provider
    ref.read(archiveNoteProvider(widget.memo.id))().then((_) {
      // Success SnackBar removed
    });
  }

  void _onTogglePin(BuildContext context) {
    // Use renamed provider
    ref.read(togglePinNoteProvider(widget.memo.id))().then((_) {
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
        '[MemoListItem] Note ID ${widget.memo.id} at index ${widget.index} is selected', // Updated log
      );
    }

    // Create the main card content
    Widget cardContent = MemoCard(
      // Keep MemoCard name or refactor later
      key: _memoCardKey, // Pass the key here
      id: widget.memo.id,
      content: widget.memo.content,
      pinned: widget.memo.pinned,
      updatedAt:
          widget.memo.updateTime
              .toIso8601String(), // Convert DateTime to String
      showTimeStamps: true,
      isSelected:
          isSelected &&
          !isMultiSelectMode, // Only show selection style if not in multi-select
      highlightTimestamp: MemoUtils.formatTimestamp(
        widget.memo.updateTime.toIso8601String(),
      ), // Pass String
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
          // Use renamed provider
          await ref.read(bumpNoteProvider(widget.memo.id))();
          // Success SnackBar removed
        } catch (e) {
          if (mounted) {
            // Show Cupertino Error Dialog
            showCupertinoDialog(
              context: context, // Use current context since we checked mounted
              builder:
                  (ctx) => CupertinoAlertDialog(
                    title: const Text('Error'),
                    content: Text(
                      'Failed to bump note: ${e.toString().substring(0, 50)}...', // Updated text
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
      // Pass the onMoveToServer callback from widget to MemoCard
      onMoveToServer: widget.onMoveToServer,
    );

    // In multi-select mode, return a completely different widget structure without Slidable/Dismissible
    if (isMultiSelectMode) {
      // Add extra visual indicator for multi-selected items
      if (isMultiSelected) {
        cardContent = Container(
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  CupertinoTheme.of(
                    context,
                  ).primaryColor, // Use Cupertino theme color
              width: 2,
            ),
            // Match MemoCard's radius if different, otherwise keep consistent
            borderRadius: BorderRadius.circular(10), // Match MemoCard radius
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
              // Use CupertinoCheckbox
              child: CupertinoCheckbox(
                value: isMultiSelected,
                onChanged: (value) => _toggleMultiSelection(widget.memo.id),
                // Optionally customize activeColor
                // activeColor: CupertinoTheme.of(context).primaryColor,
              ),
            ),
            Expanded(child: cardContent),
          ],
        ),
      );
    }

    // In normal mode, wrap ONLY with Slidable (Dismissible removed)
    return Slidable(
      key: ValueKey('slidable-${widget.memo.id}'),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        // extentRatio: 0.5, // Adjust width of the action pane
        children: [
          SlidableAction(
            onPressed: (_) => _onEdit(context),
            backgroundColor: CupertinoColors.systemBlue, // Use Cupertino color
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.pencil, // Use Cupertino icon
            label: 'Edit',
            autoClose: true,
          ),
          SlidableAction(
            onPressed: (_) => _onTogglePin(context),
            backgroundColor:
                CupertinoColors.systemOrange, // Use Cupertino color
            foregroundColor: CupertinoColors.white,
            icon:
                widget.memo.pinned
                    ? CupertinoIcons
                        .pin_slash_fill // Use Cupertino icon
                    : CupertinoIcons.pin_fill, // Use Cupertino icon
            label: widget.memo.pinned ? 'Unpin' : 'Pin',
            autoClose: true,
          ),
          // Add Hide action here if desired as a swipe action
          SlidableAction(
            onPressed: (_) => _toggleHideMemo(context, ref),
            backgroundColor: CupertinoColors.systemGrey, // Use Cupertino color
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.eye_slash_fill, // Use Cupertino icon
            label: 'Hide',
            autoClose: true,
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        // extentRatio: 0.5, // Adjust width of the action pane
        children: [
          SlidableAction(
            onPressed: (_) => _onDelete(context),
            backgroundColor:
                CupertinoColors.destructiveRed, // Use Cupertino color
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.delete, // Use Cupertino icon
            label: 'Delete',
            autoClose: true,
          ),
          SlidableAction(
            onPressed: (_) => _onArchive(context),
            backgroundColor:
                CupertinoColors.systemPurple, // Use Cupertino color
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.archivebox_fill, // Use Cupertino icon
            label: 'Archive',
            autoClose: true,
          ),
        ],
      ),
      // Wrap the Stack in a GestureDetector to handle long press for context menu
      child: GestureDetector(
        onLongPress: () {
          // Access the public showContextMenu method via the GlobalKey
          _memoCardKey.currentState?.showContextMenu();
        },
        child: Stack(
          children: [
            cardContent, // The MemoCard widget
            // Archive button positioned at top-right corner (using CupertinoButton)
            Positioned(
              top: 4,
              right: 4,
              child: CupertinoButton(
                padding: const EdgeInsets.all(6), // Slightly smaller padding
                minSize: 0,
                onPressed: () => _onArchive(context),
                child: Icon(
                  CupertinoIcons.archivebox, // Use Cupertino icon
                  size: 18, // Slightly smaller icon
                  color: CupertinoColors.secondaryLabel.resolveFrom(
                    context,
                  ), // More subtle color
                ),
              ),
            ),
          ],
        ),
      ), // Close GestureDetector
    ); // Close Slidable
  }
}
