import 'dart:math'; // For min

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
  // Modify the signature to accept the scaffoldContext and scaffoldMessenger
  void _showCustomContextMenu(
    BuildContext scaffoldContext,
    ScaffoldMessengerState scaffoldMessenger,
  ) {
    final isManuallyHidden = ref.read(settings_p.manuallyHiddenNoteIdsProvider).contains(widget.note.id);
    final now = DateTime.now();
    final isFutureDated = widget.note.startDate?.isAfter(now) ?? false;

    showCupertinoModalPopup<void>(
      context: scaffoldContext, // Use the passed context for the popup itself
      builder: (BuildContext popupContext) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoContextMenuAction(
            child: const Text('Edit'),
            onPressed: () {
              Navigator.pop(popupContext);
              onEdit(scaffoldContext);
            },
          ),
          if (widget.onMoveToServer != null)
            CupertinoContextMenuAction(
              child: const Text('Move to Server...'),
              onPressed: () {
                    Navigator.pop(popupContext);
                    widget.onMoveToServer!();
              },
            ),
          CupertinoContextMenuAction(
            child: Text(widget.note.pinned ? 'Unpin' : 'Pin'),
            onPressed: () {
              Navigator.pop(popupContext);
              onTogglePin(scaffoldContext);
            },
          ),
          CupertinoContextMenuAction(
            child: const Text('Archive'),
            onPressed: () {
              Navigator.pop(popupContext);
              onArchive(scaffoldContext);
            },
          ),
          CupertinoContextMenuAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(popupContext);
              onDelete(scaffoldContext);
            },
          ),
          CupertinoContextMenuAction(
            child: const Text('Copy Content'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.note.content));
              Navigator.pop(popupContext);
            },
          ),
          if (isManuallyHidden)
            CupertinoContextMenuAction(
              child: const Text('Unhide'),
              onPressed: () {
                ref.read(note_providers.unhideNoteProvider(widget.note.id))();
                Navigator.pop(popupContext);
              },
            )
          else if (!isFutureDated)
            CupertinoContextMenuAction(
              child: const Text('Hide'),
              onPressed: () {
                _toggleHideItem(scaffoldContext, ref);
                Navigator.pop(popupContext);
              },
                ),
          CupertinoContextMenuAction(
            child: const Text('Add to Workbench'),
            onPressed: () {
                  Navigator.pop(popupContext);
                  // Pass scaffoldMessenger instead of scaffoldContext
                  _addNoteToWorkbenchFromList(
                    scaffoldMessenger,
                    ref,
                    widget.note,
                  );
            },
              ),
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

  // Helper method to add note to workbench
  // Modify signature to accept ScaffoldMessengerState instead of BuildContext
  void _addNoteToWorkbenchFromList(
    ScaffoldMessengerState scaffoldMessenger, // Use ScaffoldMessengerState
    WidgetRef ref,
    NoteItem note,
  ) {
    final activeServer = ref.read(activeServerConfigProvider);
    if (activeServer == null) {
      // Use the passed scaffoldMessenger directly
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Cannot add to workbench: No active server."),
          backgroundColor: CupertinoColors.systemRed,
        ),
      );
      return;
    }

    final preview = note.content.split('\n').first;

    final reference = WorkbenchItemReference(
      id: const Uuid().v4(),
      referencedItemId: note.id,
      referencedItemType: WorkbenchItemType.note,
      serverId: activeServer.id,
      serverType: activeServer.serverType,
      serverName: activeServer.name,
      previewContent: preview.length > 100 ? '${preview.substring(0, 97)}...' : preview,
      addedTimestamp: DateTime.now(),
      parentNoteId: null,
      lastOpenedTimestamp: null, // Initialize new field as null
    );

    ref.read(workbenchProvider.notifier).addItem(reference);

    // Use the passed scaffoldMessenger directly
    // Handle potential null previewContent
    final previewText = reference.previewContent ?? 'Item';
    final snackBarContent =
        'Added "${previewText.substring(0, min(30, previewText.length))}${previewText.length > 30 ? '...' : ''}" to Workbench';

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(snackBarContent),
        duration: const Duration(seconds: 2),
        backgroundColor: CupertinoColors.systemGreen,
      ),
    );
  }
  // --- End of helper method ---

  void _toggleHideItem(BuildContext scaffoldContext, WidgetRef ref) {
    final hiddenItemIds = ref.read(settings_p.manuallyHiddenNoteIdsProvider);
    final itemIdToToggle = widget.note.id;

    if (hiddenItemIds.contains(itemIdToToggle)) {
      ref
          .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
          .remove(itemIdToToggle);
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

      ref
          .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
          .add(itemIdToToggle);

      if (nextSelectedId != currentSelectedId) {
        ref.read(ui_providers.selectedItemIdProvider.notifier).state = nextSelectedId;
      }
    }
  }

  void _navigateToItemDetail(BuildContext scaffoldContext, WidgetRef ref) {
    ref.read(ui_providers.selectedItemIdProvider.notifier).state = widget.note.id;
    Navigator.of(
      scaffoldContext,
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

  void onEdit(BuildContext scaffoldContext) {
    Navigator.of(scaffoldContext, rootNavigator: true).pushNamed(
      '/edit-entity',
      arguments: {'entityType': 'note', 'entityId': widget.note.id},
    );
  }

  void onDelete(BuildContext scaffoldContext) async {
    final confirm = await showCupertinoDialog<bool>(
      context: scaffoldContext,
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

    if (confirm == true && mounted) {
      try {
        ref
            .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
            .add(widget.note.id);

        await ref.read(note_providers.deleteNoteProvider(widget.note.id))();
      } catch (e) {
        if (mounted) {
          ref
              .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
              .remove(widget.note.id);

          showCupertinoDialog(
            context: scaffoldContext,
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

  void onArchive(BuildContext scaffoldContext) {
    ref.read(note_providers.archiveNoteProvider(widget.note.id))();
  }

  void onTogglePin(BuildContext scaffoldContext) {
    ref.read(note_providers.togglePinNoteProvider(widget.note.id))();
  }

  @override
  Widget build(BuildContext context) {
    // Capture the build context here - THIS is the reliable context
    final BuildContext scaffoldContext = context;
    // Get the ScaffoldMessengerState using the reliable context
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(
      scaffoldContext,
    );

    final selectedItemId = ref.watch(ui_providers.selectedItemIdProvider);
    final isSelected = selectedItemId == widget.note.id;

    final isMultiSelectMode = ref.watch(ui_providers.itemMultiSelectModeProvider);
    final selectedIds = ref.watch(ui_providers.selectedItemIdsForMultiSelectProvider);
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
          : () => _navigateToItemDetail(scaffoldContext, ref),
      onArchive: () => onArchive(scaffoldContext),
      onDelete: () => onDelete(scaffoldContext),
      onHide: () => _toggleHideItem(scaffoldContext, ref),
      onTogglePin: () => onTogglePin(scaffoldContext),
      onBump: () async {
        try {
          await ref.read(note_providers.bumpNoteProvider(widget.note.id))();
        } catch (e) {
          if (mounted) {
            showCupertinoDialog(
              context: scaffoldContext,
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

    final dateInfoWidget = _buildDateInfo(scaffoldContext, widget.note);

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
              color: CupertinoTheme.of(scaffoldContext).primaryColor,
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
            onPressed: (_) => onEdit(scaffoldContext),
            backgroundColor: CupertinoColors.systemBlue,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.pencil,
            label: 'Edit',
            autoClose: true,
          ),
          if (widget.onMoveToServer != null)
            SlidableAction(
              onPressed: (_) => widget.onMoveToServer!(),
              backgroundColor: CupertinoColors.systemIndigo,
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.arrow_right_arrow_left_square,
              label: 'Move',
              autoClose: true,
            ),
          SlidableAction(
            onPressed: (_) => onTogglePin(scaffoldContext),
            backgroundColor: CupertinoColors.systemOrange,
            foregroundColor: CupertinoColors.white,
            icon:
                widget.note.pinned
                    ? CupertinoIcons.pin_slash_fill
                    : CupertinoIcons.pin_fill,
            label: widget.note.pinned ? 'Unpin' : 'Pin',
            autoClose: true,
          ),
          if (widget.isInHiddenView)
            SlidableAction(
              onPressed:
                  (_) =>
                      ref.read(
                        note_providers.unhideNoteProvider(widget.note.id),
                      )(),
              backgroundColor: CupertinoColors.systemGreen,
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.eye_fill,
              label: 'Unhide',
              autoClose: true,
            )
          else
            SlidableAction(
              onPressed: (_) => _toggleHideItem(scaffoldContext, ref),
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
            onPressed: (_) => onDelete(scaffoldContext),
            backgroundColor: CupertinoColors.destructiveRed,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.delete,
            label: 'Delete',
            autoClose: true,
          ),
          SlidableAction(
            onPressed: (_) => onArchive(scaffoldContext),
            backgroundColor: CupertinoColors.systemPurple,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.archivebox_fill,
            label: 'Archive',
            autoClose: true,
          ),
        ],
      ),
      // Wrap the GestureDetector in a Builder to ensure it gets a fresh context
      child: Builder(
        builder: (builderContext) {
          // Use builderContext for any ScaffoldMessenger operations if needed
          return GestureDetector(
            onLongPress: () {
              // Continue using the reliably captured scaffoldContext and scaffoldMessenger
              _showCustomContextMenu(scaffoldContext, scaffoldMessenger);
            },
            onTap:
                isMultiSelectMode
                ? () => _toggleMultiSelection(widget.note.id)
                : () => _navigateToItemDetail(scaffoldContext, ref),
            child: Stack(
              children: [
                cardWithDateInfo,
                Positioned(
                  top: 4,
                  right: 4,
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(6),
                    minSize: 0,
                    onPressed: () => onArchive(scaffoldContext),
                    child: Icon(
                      CupertinoIcons.archivebox,
                      size: 18,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        scaffoldContext,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
