import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/utils/note_utils.dart';
import 'package:flutter_memos/widgets/note_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class NoteListItem extends ConsumerStatefulWidget {
  final NoteItem note;
  final int index;
  final VoidCallback? onMoveToServer;

  const NoteListItem({
    super.key,
    required this.note,
    required this.index,
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
                  color:
                      isFutureStart
                          ? CupertinoColors.systemOrange.resolveFrom(context)
                          : CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontWeight:
                      isFutureStart ? FontWeight.w600 : FontWeight.normal,
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
    final standardActions = <Widget>[
      CupertinoContextMenuAction(
        child: const Text('Copy Content'),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: widget.note.content));
          // Use the builder context to pop the modal
          Navigator.pop(context);
        },
      ),
    ];

    final dateActions = <Widget>[
      CupertinoContextMenuAction(
        child: const Text('Kick Start +1 Day'),
        onPressed: () {
          final currentStart = widget.note.startDate ?? DateTime.now();
          final newStartDate = currentStart.add(const Duration(days: 1));
          ref
              .read(note_providers.notesNotifierProvider.notifier)
              .updateNoteStartDate(widget.note.id, newStartDate);
          // Use the builder context to pop the modal
          Navigator.pop(context);
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
          // Use the builder context to pop the modal
          Navigator.pop(context);
        },
      ),
      if (widget.note.startDate != null)
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          onPressed: () {
            ref
                .read(note_providers.notesNotifierProvider.notifier)
                .updateNoteStartDate(widget.note.id, null);
            // Use the builder context to pop the modal
            Navigator.pop(context);
          },
          child: const Text('Clear Start Date'),
        ),
    ];

    showCupertinoModalPopup<void>(
      context: context, // This context is fine for showing the popup
      // The builder provides the correct context for actions *inside* the popup
      builder:
          (BuildContext builderContext) => CupertinoActionSheet(
            // Combine both sets of actions
            actions: <Widget>[...standardActions, ...dateActions],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () {
                // Use the builder context to pop the modal
                Navigator.pop(builderContext);
              },
            ),
          ),
    );
  }
  // --- End Moved Helper Methods ---

  void _toggleHideItem(BuildContext context, WidgetRef ref) {
    final hiddenItemIds = ref.read(note_providers.hiddenItemIdsProvider);
    final itemIdToToggle = widget.note.id;

    if (hiddenItemIds.contains(itemIdToToggle)) {
      ref
          .read(note_providers.hiddenItemIdsProvider.notifier)
          .update((state) => state..remove(itemIdToToggle));
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
          .read(note_providers.hiddenItemIdsProvider.notifier)
          .update((state) => state..add(itemIdToToggle));

      if (nextSelectedId != currentSelectedId) {
        ref.read(ui_providers.selectedItemIdProvider.notifier).state =
            nextSelectedId;
      }
    }

    ref.read(note_providers.notesNotifierProvider.notifier).refresh();
  }

  void _navigateToItemDetail(BuildContext context, WidgetRef ref) {
    ref.read(ui_providers.selectedItemIdProvider.notifier).state =
        widget.note.id;
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/item-detail',
      arguments: {'itemId': widget.note.id},
    );
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
      print('[NoteListItem] Current selection: ${currentSelection.join(', ')}');
    }
  }

  void _onEdit(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/edit-entity',
      arguments: {
        'entityType': 'note',
        'entityId': widget.note.id,
      },
    );
  }

  void _onDelete(BuildContext context) async {
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
        // Optimistically hide
        ref
            .read(note_providers.hiddenItemIdsProvider.notifier)
            .update((state) => state..add(widget.note.id));

        // Perform deletion
        await ref.read(note_providers.deleteNoteProvider(widget.note.id))();
        // No need to remove from hidden on success, it's gone
      } catch (e) {
        // Revert optimistic hide on error
        ref
            .read(note_providers.hiddenItemIdsProvider.notifier)
            .update((state) => state..remove(widget.note.id));

        // Check mounted again before showing the dialog
        if (mounted) {
          showCupertinoDialog(
            context: context, // Use the original context passed to _onDelete
            builder:
                (ctx) => CupertinoAlertDialog(
                  title: const Text('Error'),
                  content: Text('Failed to delete note: $e'),
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

  void _onArchive(BuildContext context) {
    ref.read(note_providers.archiveNoteProvider(widget.note.id))();
  }

  void _onTogglePin(BuildContext context) {
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
      onTap:
          isMultiSelectMode
              ? () => _toggleMultiSelection(widget.note.id)
              : () => _navigateToItemDetail(context, ref),
      onArchive: () => _onArchive(context),
      onDelete: () => _onDelete(context),
      onHide: () => _toggleHideItem(context, ref),
      onTogglePin: () => _onTogglePin(context),
      onBump: () async {
        try {
          await ref.read(note_providers.bumpNoteProvider(widget.note.id))();
        } catch (e) {
          // Check mounted *after* the await and *before* using context
          if (mounted) {
            showCupertinoDialog(
              context: context, // Use the build context
              builder:
                  (ctx) => CupertinoAlertDialog(
                    title: const Text('Error'),
                    content: Text(
                      'Failed to bump note: ${e.toString().substring(0, 50)}...',
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
                widget.note.pinned
                    ? CupertinoIcons.pin_slash_fill
                    : CupertinoIcons.pin_fill,
            label: widget.note.pinned ? 'Unpin' : 'Pin',
            autoClose: true,
          ),
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
                onPressed: () => _onArchive(context),
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
