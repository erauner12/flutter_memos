import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Needed for ScaffoldMessenger/SnackBar
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart'; // Needed for Workbench
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/server_config_provider.dart'; // Needed for activeServerConfigProvider
// Import settings_provider for manuallyHiddenNoteIdsProvider
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/providers/workbench_provider.dart'; // Needed for Workbench
import 'package:flutter_memos/utils/note_utils.dart';
import 'package:flutter_memos/widgets/note_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // Needed for Workbench item ID generation

class NoteListItem extends ConsumerStatefulWidget {
  final NoteItem note;
  final int index;
  final VoidCallback? onMoveToServer;
  final bool isInHiddenView; // Add this parameter

  const NoteListItem({
    super.key,
    required this.note,
    required this.index,
    required this.isInHiddenView, // Make it required
    this.onMoveToServer,
  });

  @override
  NoteListItemState createState() => NoteListItemState();
}

class NoteListItemState extends ConsumerState<NoteListItem> {
  final GlobalKey<NoteCardState> _noteCardKey = GlobalKey<NoteCardState>();

  // --- Moved Helper Methods ---
  // Helper widget to display start/end dates
  Widget? _buildDateInfo(BuildContext context, NoteItem note) {
    if (note.startDate == null && note.endDate == null) {
      return null; // Don't show anything if no dates are set
    }

    final now = DateTime.now();
    final bool isFutureStart = note.startDate?.isAfter(now) ?? false;
    final dateFormat = DateFormat.yMd().add_jm(); // Example format

    return Padding(
      padding: const EdgeInsets.only(
        top: 6.0,
        left: 12.0,
        right: 12.0,
        bottom: 4.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (note.startDate != null)
            Expanded(
              child: Text(
                'Start: ${dateFormat.format(note.startDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isFutureStart
                      ? CupertinoColors.systemOrange.resolveFrom(context)
                      : CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontWeight: isFutureStart ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (note.startDate != null && note.endDate != null)
            const SizedBox(width: 8),
          if (note.endDate != null)
            Expanded(
              child: Text(
                'End: ${dateFormat.format(note.endDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // Custom context menu including date actions
  void _showCustomContextMenu(BuildContext context) {
    // Check if the note is manually hidden (needed for context menu logic)
    final isManuallyHidden = ref.read(settings_p.manuallyHiddenNoteIdsProvider).contains(widget.note.id);
    final now = DateTime.now();
    final isFutureDated = widget.note.startDate?.isAfter(now) ?? false;

    showCupertinoModalPopup<void>(
      context: context,
      // The builder provides the correct context for actions *inside* the popup
      builder: (BuildContext popupContext) => CupertinoActionSheet(
        // Combine all sets of actions
        actions: <Widget>[
          // Standard Actions
          CupertinoContextMenuAction(
            child: const Text('Edit'),
            onPressed: () {
              Navigator.pop(popupContext);
              onEdit(context);
            },
          ),
          // Add Move to Server action conditionally
          if (widget.onMoveToServer != null)
            CupertinoContextMenuAction(
              child: const Text('Move to Server...'),
              onPressed: () {
                Navigator.pop(popupContext); // Close the action sheet
                widget.onMoveToServer!(); // Trigger the callback
              },
            ),
          CupertinoContextMenuAction(
            child: Text(widget.note.pinned ? 'Unpin' : 'Pin'),
            onPressed: () {
              Navigator.pop(popupContext);
              onTogglePin(context);
            },
          ),
          CupertinoContextMenuAction(
            child: const Text('Archive'),
            onPressed: () {
              Navigator.pop(popupContext);
              onArchive(context);
            },
          ),
          CupertinoContextMenuAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(popupContext);
              onDelete(context);
            },
          ),
          CupertinoContextMenuAction(
            child: const Text('Copy Content'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.note.content));
              Navigator.pop(popupContext);
            },
          ),
          // Conditional Hide/Unhide Action
          if (isManuallyHidden) // Show Unhide only if manually hidden
            CupertinoContextMenuAction(
              child: const Text('Unhide'),
              onPressed: () {
                ref.read(note_providers.unhideNoteProvider(widget.note.id))();
                Navigator.pop(popupContext);
              },
            )
          else if (!isFutureDated) // Show Hide only if not future-dated (and not manually hidden)
            CupertinoContextMenuAction(
              child: const Text('Hide'),
              onPressed: () {
                _toggleHideItem(context, ref); // Existing hide logic
                Navigator.pop(popupContext);
              },
            ),
          // --- Add this action ---
          CupertinoContextMenuAction(
            child: const Text('Add to Workbench'),
            onPressed: () {
              Navigator.pop(popupContext); // Close the action sheet first
              _addNoteToWorkbenchFromList(context, ref, widget.note); // Call helper
            },
          ),
          // --- End of added action ---
          // Date Actions
          CupertinoContextMenuAction(
            child: const Text('Kick Start +1 Day'),
            onPressed: () {
              final currentStart = widget.note.startDate ?? DateTime.now();
              final newStartDate = currentStart.add(const Duration(days: 1));
              ref
                  .read(note_providers.notesNotifierProvider.notifier)
                  .updateNoteStartDate(widget.note.id, newStartDate);
              Navigator.pop(popupContext);
            },
          ),
          CupertinoContextMenuAction(
            child: const Text('Kick Start +1 Week'),
            onPressed: () {
              final currentStart = widget.note.startDate ?? DateTime.now();
              final newStartDate = currentStart.add(const Duration(days: 7));
              ref
                  .read(note_providers.notesNotifierProvider.notifier)
                  .updateNoteStartDate(widget.note.id, newStartDate);
              Navigator.pop(popupContext);
            },
          ),
          if (widget.note.startDate != null)
            CupertinoContextMenuAction(
              isDestructiveAction: true,
              onPressed: () {
                ref
                    .read(note_providers.notesNotifierProvider.notifier)
                    .updateNoteStartDate(widget.note.id, null);
                Navigator.pop(popupContext);
              },
              child: const Text('Clear Start Date'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(popupContext);
          },
        ),
      ),
    );
  }
  // --- End Moved Helper Methods ---

  // --- Add this helper method within NoteListItemState ---
  void _addNoteToWorkbenchFromList(BuildContext context, WidgetRef ref, NoteItem note) {
    final activeServer = ref.read(activeServerConfigProvider);
    if (activeServer == null) {
      // Optionally show an error message if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot add to workbench: No active server."), backgroundColor: CupertinoColors.systemRed),
      );
      return;
    }

    final preview = note.content.split('\n').first; // Simple preview

    final reference = WorkbenchItemReference(
      id: const Uuid().v4(),
      referencedItemId: note.id,
      referencedItemType: WorkbenchItemType.note, // Explicitly note
      serverId: activeServer.id,
      serverType: activeServer.serverType,
      serverName: activeServer.name,
      previewContent: preview.length > 100 ? '${preview.substring(0, 97)}...' : preview,
      addedTimestamp: DateTime.now(),
      // parentNoteId is null for notes
    );

    ref.read(workbenchProvider.notifier).addItem(reference);

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to Workbench"), backgroundColor: CupertinoColors.systemGreen),
    );
  }
  // --- End of helper method ---

  void _toggleHideItem(BuildContext context, WidgetRef ref) {
    // Use the correct provider from settings_provider
    final hiddenItemIds = ref.read(settings_p.manuallyHiddenNoteIdsProvider);
    final itemIdToToggle = widget.note.id;

    if (hiddenItemIds.contains(itemIdToToggle)) {
      // Use the correct provider from settings_provider
      ref
          .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
          .remove(itemIdToToggle); // Use remove method
    } else {
      final currentSelectedId = ref.read(ui_providers.selectedItemIdProvider);
      final notesBeforeAction = ref.read(note_providers.filteredNotesProvider);
      final itemIdToAction = itemIdToToggle;
      String? nextSelectedId = currentSelectedId;

      if (currentSelectedId == itemIdToAction && notesBeforeAction.isNotEmpty) {
        final actionIndex = notesBeforeAction.indexWhere(
          (n) => n.id == itemIdToAction,
        );

        if (actionIndex != -1) {
          if (notesBeforeAction.length == 1) {
            nextSelectedId = null;
          } else if (actionIndex < notesBeforeAction.length - 1) {
            nextSelectedId = notesBeforeAction[actionIndex + 1].id;
          } else {
            nextSelectedId = notesBeforeAction[actionIndex - 1].id;
          }
        } else {
          nextSelectedId = null;
        }
      }

      // Use the correct provider from settings_provider
      ref
          .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
          .add(itemIdToToggle); // Use add method

      if (nextSelectedId != currentSelectedId) {
        ref.read(ui_providers.selectedItemIdProvider.notifier).state =
            nextSelectedId;
      }
    }
  }

  void _navigateToItemDetail(BuildContext context, WidgetRef ref) {
    ref.read(ui_providers.selectedItemIdProvider.notifier).state =
        widget.note.id;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/item-detail', arguments: {'itemId': widget.note.id});
  }

  void _toggleMultiSelection(String noteId) {
    final currentSelection = Set<String>.from(
      ref.read(ui_providers.selectedItemIdsForMultiSelectProvider),
    );

    if (currentSelection.contains(noteId)) {
      currentSelection.remove(noteId);
    } else {
      currentSelection.add(noteId);
    }

    ref
        .read(ui_providers.selectedItemIdsForMultiSelectProvider.notifier)
        .state = currentSelection;

    if (kDebugMode) {
      print('[NoteListItem] Multi-selection toggled for note ID: $noteId');
      print('[NoteListItem] Current selection: ${currentSelection.join(", ")}');
    }
  }

  void onEdit(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/edit-entity',
      arguments: {'entityType': 'note', 'entityId': widget.note.id},
    );
  }

  void onDelete(BuildContext context) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this note?'),
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

    // Check mounted *after* the await and *before* using context again
    if (confirm == true && mounted) {
      try {
        // Optimistically hide using the correct provider
        ref
            .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
            .add(widget.note.id); // Use add method

        // Perform deletion
        await ref.read(note_providers.deleteNoteProvider(widget.note.id))();
        // The deleteNoteProvider already removes the ID from manuallyHiddenNoteIdsProvider on success
      } catch (e) {
        // Revert optimistic hide on error using the correct provider
        if (mounted) {
          ref
              .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
              .remove(widget.note.id); // Use remove method

          // Show error dialog
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to delete note: ${e.toString()}'),
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
    }
  }

  void onArchive(BuildContext context) {
    ref.read(note_providers.archiveNoteProvider(widget.note.id))();
  }

  void onTogglePin(BuildContext context) {
    ref.read(note_providers.togglePinNoteProvider(widget.note.id))();
  }

  @override
  Widget build(BuildContext context) {
    final selectedItemId = ref.watch(ui_providers.selectedItemIdProvider);
    final isSelected = selectedItemId == widget.note.id;

    final isMultiSelectMode = ref.watch(
      ui_providers.itemMultiSelectModeProvider,
    );
    final selectedIds = ref.watch(
      ui_providers.selectedItemIdsForMultiSelectProvider,
    );
    final isMultiSelected = selectedIds.contains(widget.note.id);

    Widget noteCardWidget = NoteCard(
      key: _noteCardKey,
      id: widget.note.id,
      content: widget.note.content,
      pinned: widget.note.pinned,
      updatedAt: widget.note.updateTime.toIso8601String(),
      showTimeStamps: true,
      isSelected: isSelected && !isMultiSelectMode,
      highlightTimestamp: NoteUtils.formatTimestamp(
        widget.note.updateTime.toIso8601String(),
      ),
      timestampType: 'Updated',
      onTap: isMultiSelectMode
          ? () => _toggleMultiSelection(widget.note.id)
          : () => _navigateToItemDetail(context, ref),
      onArchive: () => onArchive(context),
      onDelete: () => onDelete(context),
      onHide: () => _toggleHideItem(context, ref),
      onTogglePin: () => onTogglePin(context),
      onBump: () async {
        try {
          await ref.read(note_providers.bumpNoteProvider(widget.note.id))();
        } catch (e) {
          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: Text(
                  'Failed to bump note: ${e.toString().length > 100 ? "${e.toString().substring(0, 100)}..." : e.toString()}',
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

    final dateInfoWidget = _buildDateInfo(context, widget.note);

    Widget cardWithDateInfo = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [noteCardWidget, if (dateInfoWidget != null) dateInfoWidget],
    );

    if (isMultiSelectMode) {
      if (isMultiSelected) {
        cardWithDateInfo = Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: CupertinoTheme.of(context).primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: cardWithDateInfo,
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0, right: 8.0),
              child: CupertinoCheckbox(
                value: isMultiSelected,
                onChanged: (value) => _toggleMultiSelection(widget.note.id),
              ),
            ),
            Expanded(child: cardWithDateInfo),
          ],
        ),
      );
    }

    return Slidable(
      key: ValueKey('slidable-${widget.note.id}'),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(context),
            backgroundColor: CupertinoColors.systemBlue,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.pencil,
            label: 'Edit',
            autoClose: true,
          ),
          // Add Move action conditionally
          if (widget.onMoveToServer != null)
            SlidableAction(
              onPressed: (_) => widget.onMoveToServer!(), // Trigger callback
              backgroundColor: CupertinoColors.systemIndigo, // Choose a color
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.arrow_right_arrow_left_square, // Choose an icon
              label: 'Move',
              autoClose: true, // Close slidable after action
            ),
          SlidableAction(
            onPressed: (_) => onTogglePin(context),
            backgroundColor: CupertinoColors.systemOrange,
            foregroundColor: CupertinoColors.white,
            icon: widget.note.pinned
                ? CupertinoIcons.pin_slash_fill
                : CupertinoIcons.pin_fill,
            label: widget.note.pinned ? 'Unpin' : 'Pin',
            autoClose: true,
          ),
          // Conditionally show Hide or Unhide
          if (widget.isInHiddenView)
            SlidableAction(
              onPressed: (_) => ref.read(note_providers.unhideNoteProvider(widget.note.id))(),
              backgroundColor: CupertinoColors.systemGreen,
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.eye_fill,
              label: 'Unhide',
              autoClose: true,
            )
          else
            SlidableAction(
              onPressed: (_) => _toggleHideItem(context, ref),
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
            onPressed: (_) => onDelete(context),
            backgroundColor: CupertinoColors.destructiveRed,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.delete,
            label: 'Delete',
            autoClose: true,
          ),
          SlidableAction(
            onPressed: (_) => onArchive(context),
            backgroundColor: CupertinoColors.systemPurple,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.archivebox_fill,
            label: 'Archive',
            autoClose: true,
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: () {
          _showCustomContextMenu(context);
        },
        child: Stack(
          children: [
            cardWithDateInfo,
            Positioned(
              top: 4,
              right: 4,
              child: CupertinoButton(
                padding: const EdgeInsets.all(6),
                minSize: 0,
                onPressed: () => onArchive(context),
                child: Icon(
                  CupertinoIcons.archivebox,
                  size: 18,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
