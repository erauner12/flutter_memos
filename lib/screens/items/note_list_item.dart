import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
// Import note_providers instead of memo_providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
// Import note_utils instead of memo_utils
import 'package:flutter_memos/utils/note_utils.dart';
// Import note_card instead of memo_card
import 'package:flutter_memos/widgets/note_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class NoteListItem extends ConsumerStatefulWidget { // Renamed class
  final NoteItem note; // Changed type to NoteItem, renamed from memo
  final int index;
  final VoidCallback? onMoveToServer;

  const NoteListItem({ // Renamed constructor
    super.key,
    required this.note, // Renamed parameter
    required this.index,
    this.onMoveToServer,
  });

  @override
  NoteListItemState createState() => NoteListItemState(); // Renamed class
}

class NoteListItemState extends ConsumerState<NoteListItem> { // Renamed class
  // Use NoteCardState
  final GlobalKey<NoteCardState> _noteCardKey = GlobalKey<NoteCardState>(); // Renamed key type and variable

  void _toggleHideItem(BuildContext context, WidgetRef ref) { // Renamed method
    // Use renamed provider
    final hiddenItemIds = ref.read(note_providers.hiddenItemIdsProvider);
    final itemIdToToggle = widget.note.id; // Use note.id, renamed variable

    if (hiddenItemIds.contains(itemIdToToggle)) {
      // Unhide item
      ref
          .read(note_providers.hiddenItemIdsProvider.notifier) // Use renamed provider
          .update((state) => state..remove(itemIdToToggle));
    } else {
      // --- Selection Update Logic ---
      final currentSelectedId = ref.read(ui_providers.selectedItemIdProvider); // Use renamed provider
      final notesBeforeAction = ref.read(
        note_providers.filteredNotesProvider, // Use provider from note_providers
      );
      final itemIdToAction = itemIdToToggle; // Renamed variable
      String? nextSelectedId = currentSelectedId;

      if (currentSelectedId == itemIdToAction && notesBeforeAction.isNotEmpty) {
        final actionIndex = notesBeforeAction.indexWhere(
          (n) => n.id == itemIdToAction, // Use n for note
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
      // --- End Selection Update Logic ---

      // Hide item
      ref
          .read(note_providers.hiddenItemIdsProvider.notifier) // Use renamed provider
          .update((state) => state..add(itemIdToToggle));

      if (nextSelectedId != currentSelectedId) {
        ref.read(ui_providers.selectedItemIdProvider.notifier).state = // Use renamed provider
            nextSelectedId;
      }
    }

    // Force UI refresh (consider if still needed)
    ref.read(note_providers.notesNotifierProvider.notifier).refresh(); // Use provider from note_providers
  }

  void _navigateToItemDetail(BuildContext context, WidgetRef ref) { // Renamed method
    // Set selected item ID
    ref.read(ui_providers.selectedItemIdProvider.notifier).state = // Use renamed provider
        widget.note.id; // Use note.id

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/item-detail', arguments: {'itemId': widget.note.id}); // Use new route and argument name
  }

  // Toggle selection of a note in multi-select mode
  void _toggleMultiSelection(String noteId) { // Keep noteId here as it's specific
    final currentSelection = Set<String>.from(
      ref.read(ui_providers.selectedItemIdsForMultiSelectProvider), // Use renamed provider
    );

    if (currentSelection.contains(noteId)) {
      currentSelection.remove(noteId);
    } else {
      currentSelection.add(noteId);
    }

    ref
        .read(ui_providers.selectedItemIdsForMultiSelectProvider.notifier) // Use renamed provider
        .state = currentSelection;

    if (kDebugMode) {
      print('[NoteListItem] Multi-selection toggled for note ID: $noteId'); // Updated log identifier
      print('[NoteListItem] Current selection: ${currentSelection.join(', ')}'); // Updated log identifier
    }
  }

  void _onEdit(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/edit-entity',
      arguments: {
        'entityType': 'note',
        'entityId': widget.note.id, // Use note.id
      },
    );
  }

  void _onDelete(BuildContext context) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
            'Are you sure you want to delete this note?',
          ),
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
            '[NoteListItem] Calling deleteNoteProvider for note ID: ${widget.note.id}', // Updated log identifier
          );
        }

        // Immediately add the item to hidden IDs
        ref
            .read(note_providers.hiddenItemIdsProvider.notifier) // Use renamed provider
            .update((state) => state..add(widget.note.id)); // Use note.id

        // Perform actual delete using provider from note_providers
        await ref.read(
          note_providers.deleteNoteProvider(widget.note.id), // Use note.id
        )();

      } catch (e) {
        // If deletion fails, remove from hidden IDs
        ref
            .read(note_providers.hiddenItemIdsProvider.notifier) // Use renamed provider
            .update((state) => state..remove(widget.note.id)); // Use note.id

        if (mounted) {
          showCupertinoDialog(
            context: context,
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

        if (kDebugMode) {
          print('[NoteListItem] Error deleting note: $e'); // Updated log identifier
        }
      }
    }
  }

  void _onArchive(BuildContext context) {
    // Use provider from note_providers
    ref.read(note_providers.archiveNoteProvider(widget.note.id))(); // Use note.id
  }

  void _onTogglePin(BuildContext context) {
    // Use provider from note_providers
    ref.read(note_providers.togglePinNoteProvider(widget.note.id))(); // Use note.id
  }

  @override
  Widget build(BuildContext context) {
    // Watch for selected item ID
    final selectedItemId = ref.watch(ui_providers.selectedItemIdProvider); // Use renamed provider
    final isSelected = selectedItemId == widget.note.id; // Use note.id

    // Watch for multi-select mode
    final isMultiSelectMode = ref.watch(
      ui_providers.itemMultiSelectModeProvider, // Use renamed provider
    );
    final selectedIds = ref.watch(
      ui_providers.selectedItemIdsForMultiSelectProvider, // Use renamed provider
    );
    final isMultiSelected = selectedIds.contains(widget.note.id); // Use note.id

    if (isSelected && kDebugMode) {
      print(
        '[NoteListItem] Note ID ${widget.note.id} at index ${widget.index} is selected', // Updated log identifier
      );
    }

    // Create the main card content using NoteCard
    Widget cardContent = NoteCard( // Use renamed widget
      key: _noteCardKey, // Pass the key
      id: widget.note.id, // Use note.id
      content: widget.note.content, // Use note.content
      pinned: widget.note.pinned, // Use note.pinned
      updatedAt: widget.note.updateTime.toIso8601String(), // Use note.updateTime
      showTimeStamps: true,
      isSelected: isSelected && !isMultiSelectMode,
      highlightTimestamp: NoteUtils.formatTimestamp( // Use renamed util class
        widget.note.updateTime.toIso8601String(), // Use note.updateTime
      ),
      timestampType: 'Updated',
      onTap: isMultiSelectMode
          ? () => _toggleMultiSelection(widget.note.id) // Use note.id
          : () => _navigateToItemDetail(context, ref), // Use renamed method
      onArchive: () => _onArchive(context),
      onDelete: () => _onDelete(context),
      onHide: () => _toggleHideItem(context, ref), // Use renamed method
      onTogglePin: () => _onTogglePin(context),
      onBump: () async {
        try {
          // Use provider from note_providers
          await ref.read(note_providers.bumpNoteProvider(widget.note.id))(); // Use note.id
        } catch (e) {
          if (mounted) {
            showCupertinoDialog(
              context: context,
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

    if (isMultiSelectMode) {
      if (isMultiSelected) {
        cardContent = Container(
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

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0, right: 8.0),
              child: CupertinoCheckbox(
                value: isMultiSelected,
                onChanged: (value) => _toggleMultiSelection(widget.note.id), // Use note.id
              ),
            ),
            Expanded(child: cardContent),
          ],
        ),
      );
    }

    return Slidable(
      key: ValueKey('slidable-${widget.note.id}'), // Use note.id
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
            icon: widget.note.pinned // Use note.pinned
                ? CupertinoIcons.pin_slash_fill
                : CupertinoIcons.pin_fill,
            label: widget.note.pinned ? 'Unpin' : 'Pin', // Use note.pinned
            autoClose: true,
          ),
          SlidableAction(
            onPressed: (_) => _toggleHideItem(context, ref), // Use renamed method
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
          // Access public method via GlobalKey
          _noteCardKey.currentState?.showContextMenu(); // Use renamed key
        },
        child: Stack(
          children: [
            cardContent, // The NoteCard widget
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