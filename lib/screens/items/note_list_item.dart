import 'dart:async'; // For Completer
import 'dart:math'; // For min

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
// Remove Material import if Tooltip or other Material widgets are not used here
// import 'package:flutter/material.dart'; // Needed for ScaffoldMessenger/SnackBar
import 'package:flutter/services.dart';
// Add import for the provider
import 'package:flutter_memos/main.dart'; // Adjust path if main.dart is elsewhere
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart'; // Needed for Workbench
import 'package:flutter_memos/models/workbench_item_type.dart'; // Import the unified enum
import 'package:flutter_memos/providers/chat_overlay_providers.dart';
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/server_config_provider.dart'; // Needed for activeServerConfigProvider
// Import settings_provider for manuallyHiddenNoteIdsProvider
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/providers/workbench_instances_provider.dart'; // <-- ADD THIS
import 'package:flutter_memos/providers/workbench_provider.dart'; // Needed for Workbench
import 'package:flutter_memos/utils/note_utils.dart';
import 'package:flutter_memos/utils/thread_utils.dart'; // Import the utility
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
  BuildContext?
  _loadingDialogContext; // To store the context of the loading dialog

  @override
  void dispose() {
    _dismissLoadingDialog(); // Ensure dialog is dismissed
    super.dispose();
  }

  // Helper to dismiss loading dialog safely
  void _dismissLoadingDialog() {
    if (_loadingDialogContext != null) {
      try {
        if (Navigator.of(_loadingDialogContext!).canPop()) {
          Navigator.of(_loadingDialogContext!).pop();
        }
      } catch (_) {
        // Ignore errors if context is already invalid or cannot pop
      }
      _loadingDialogContext = null;
    }
  }

  // Helper to show loading dialog safely
  void _showLoadingDialog(BuildContext buildContext, String message) {
    // Dismiss any existing dialog first
    _dismissLoadingDialog();
    if (!mounted) return;
    showCupertinoDialog(
      context: buildContext, // Use the passed context
      barrierDismissible: false,
      builder: (dialogContext) {
        _loadingDialogContext = dialogContext; // Store the dialog's context
        return CupertinoAlertDialog(
          content: Row(
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(width: 15),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  // Helper to show simple alert dialogs
  void _showAlertDialog(BuildContext context, String title, String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

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
  void _showCustomContextMenu(BuildContext scaffoldContext) {
    final isManuallyHidden = ref
        .read(settings_p.manuallyHiddenNoteIdsProvider)
        .contains(widget.note.id);
    final now = DateTime.now();
    final isFutureDated = widget.note.startDate?.isAfter(now) ?? false;
    // List items are assumed to be on the active server
    final bool canInteractWithServer =
        ref.read(activeServerConfigProvider) != null;

    showCupertinoModalPopup<void>(
      context: scaffoldContext,
      builder:
          (BuildContext popupContext) => CupertinoActionSheet(
            actions: <Widget>[
              CupertinoContextMenuAction(
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
                          Navigator.pop(popupContext);
                          onEdit(scaffoldContext);
                        },
                child: const Text('Edit'),
              ),
              if (widget.onMoveToServer != null)
                CupertinoContextMenuAction(
                  child: const Text('Move to Server...'),
                  onPressed: () {
                    // Moving might not require active server check here
                    Navigator.pop(popupContext);
                    widget.onMoveToServer!();
                  },
                ),
              CupertinoContextMenuAction(
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
                          Navigator.pop(popupContext);
                          onTogglePin(scaffoldContext);
                        },
                child: Text(widget.note.pinned ? 'Unpin' : 'Pin'),
              ),
              CupertinoContextMenuAction(
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
                          Navigator.pop(popupContext);
                          onArchive(scaffoldContext);
                        },
                child: const Text('Archive'),
              ),
              CupertinoContextMenuAction(
                isDestructiveAction: true,
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
                          Navigator.pop(popupContext);
                          onDelete(scaffoldContext);
                        },
                child: const Text('Delete'),
              ),
              CupertinoContextMenuAction(
                child: const Text('Copy Content'),
                onPressed: () {
                  // Copying content doesn't require server interaction
                  Clipboard.setData(ClipboardData(text: widget.note.content));
                  Navigator.pop(popupContext);
                },
              ),
              // Copy Full Thread Action
              CupertinoContextMenuAction(
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
                          Navigator.pop(popupContext);
                          _copyThreadContentFromList(
                            scaffoldContext,
                            ref,
                            widget.note.id,
                            WorkbenchItemType.note, // USES IMPORTED ENUM
                          );
                        },
                child: const Text('Copy Full Thread'),
              ),
              // Chat about Thread Action
              CupertinoContextMenuAction(
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
                          Navigator.pop(popupContext);
                          _chatWithThreadFromList(
                            scaffoldContext, // Pass the build context
                            ref,
                            widget.note.id,
                            WorkbenchItemType.note, // USES IMPORTED ENUM
                          );
                        },
                child: const Text('Chat about Thread'),
              ),
              // End Chat about Thread Action
              if (isManuallyHidden)
                CupertinoContextMenuAction(
                  onPressed:
                      !canInteractWithServer
                          ? null
                          : () {
                            ref.read(
                              note_providers.unhideNoteProvider(widget.note.id),
                            )();
                            Navigator.pop(popupContext);
                          },
                  child: const Text('Unhide'),
                )
              else if (!isFutureDated)
                CupertinoContextMenuAction(
                  onPressed:
                      !canInteractWithServer
                          ? null
                          : () {
                            _toggleHideItem(scaffoldContext, ref);
                            Navigator.pop(popupContext);
                          },
                  child: const Text('Hide'),
                ),
              CupertinoContextMenuAction(
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
                          Navigator.pop(popupContext);
                          _addNoteToWorkbenchFromList(
                            scaffoldContext,
                            ref,
                            widget.note,
                          );
                        },
                child: const Text('Add to Workbench'),
              ),
              CupertinoContextMenuAction(
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
                          final currentStart =
                              widget.note.startDate ?? DateTime.now();
                          final newStartDate = currentStart.add(
                            const Duration(days: 1),
                          );
                          ref
                              .read(
                                note_providers.notesNotifierProvider.notifier,
                              )
                              .updateNoteStartDate(
                                widget.note.id,
                                newStartDate,
                              );
                          Navigator.pop(popupContext);
                        },
                child: const Text('Kick Start +1 Day'),
              ),
              CupertinoContextMenuAction(
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
                          final currentStart =
                              widget.note.startDate ?? DateTime.now();
                          final newStartDate = currentStart.add(
                            const Duration(days: 7),
                          );
                          ref
                              .read(
                                note_providers.notesNotifierProvider.notifier,
                              )
                              .updateNoteStartDate(
                                widget.note.id,
                                newStartDate,
                              );
                          Navigator.pop(popupContext);
                        },
                child: const Text('Kick Start +1 Week'),
              ),
              if (widget.note.startDate != null)
                CupertinoContextMenuAction(
                  isDestructiveAction: true,
                  onPressed:
                      !canInteractWithServer
                          ? null
                          : () {
                            ref
                                .read(
                                  note_providers.notesNotifierProvider.notifier,
                                )
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

  // --- Helper to add note to workbench ---
  void _addNoteToWorkbenchFromList(
    BuildContext context, // Use BuildContext
    WidgetRef ref,
    NoteItem note,
  ) {
    final activeServer = ref.read(activeServerConfigProvider);
    if (activeServer == null) {
      _showAlertDialog(
        context,
        'Error',
        "Cannot add to workbench: No active server.",
      );
      return;
    }

    // Fetch the active instance ID
    final instanceId = ref.read(
      workbenchInstancesProvider.select((s) => s.activeInstanceId),
    );

    final preview = note.content.split('\n').first;

    final reference = WorkbenchItemReference(
      id: const Uuid().v4(),
      referencedItemId: note.id,
      referencedItemType: WorkbenchItemType.note, // USES IMPORTED ENUM
      serverId: activeServer.id,
      serverType: activeServer.serverType,
      serverName: activeServer.name,
      previewContent:
          preview.length > 100 ? '${preview.substring(0, 97)}...' : preview,
      addedTimestamp: DateTime.now(),
      parentNoteId: null,
      instanceId: instanceId, // <-- PASS instanceId
    );

    // FIX: Use activeWorkbenchNotifierProvider
    ref.read(activeWorkbenchNotifierProvider).addItem(reference);

    final previewText = reference.previewContent ?? 'Item';
    final dialogContent =
        'Added "${previewText.substring(0, min(30, previewText.length))}${previewText.length > 30 ? '...' : ''}" to Workbench';

    _showAlertDialog(context, 'Success', dialogContent);
  }
  // --- End of helper method ---

  // --- Copy Thread Content Helper ---
  Future<void> _copyThreadContentFromList(
    BuildContext buildContext,
    WidgetRef ref,
    String itemId,
    WorkbenchItemType itemType, // USES IMPORTED ENUM
  ) async {
    final activeServerId = ref.read(activeServerConfigProvider)?.id;
    if (activeServerId == null) {
      _showAlertDialog(
        buildContext,
        'Error',
        'Cannot copy thread: No active server.',
      );
      return;
    }

    _showLoadingDialog(buildContext, 'Fetching thread...');

    try {
      // Assuming list items are always from the active server
      final content = await getFormattedThreadContent(
        ref,
        itemId,
        itemType, // Pass imported enum
        activeServerId,
      );
      await Clipboard.setData(ClipboardData(text: content));

      _dismissLoadingDialog();
      if (mounted) {
        _showAlertDialog(
          buildContext,
          'Success',
          'Thread content copied to clipboard.',
        );
      }
    } catch (e) {
      _dismissLoadingDialog();
      if (mounted) {
        _showAlertDialog(buildContext, 'Error', 'Failed to copy thread: $e');
      }
    }
  }
  // --- End Copy Thread Content Helper ---

  // --- Chat With Thread Helper (List Item) ---
  Future<void> _chatWithThreadFromList(
    BuildContext buildContext,
    WidgetRef ref,
    String itemId,
    WorkbenchItemType itemType, // USES IMPORTED ENUM
  ) async {
    final activeServer = ref.read(activeServerConfigProvider);
    if (activeServer == null) {
      _showAlertDialog(
        buildContext,
        'Error',
        'Cannot start chat: No active server.',
      );
      return;
    }
    final activeServerId = activeServer.id;

    _showLoadingDialog(buildContext, 'Fetching thread for chat...');

    try {
      // Fetch the thread content
      final content = await getFormattedThreadContent(
        ref,
        itemId,
        itemType, // Pass imported enum
        activeServerId,
      );

      _dismissLoadingDialog(); // Dismiss before overlay

      // Show chat overlay instead of tab switch
      ref.read(chatOverlayVisibleProvider.notifier).state = true;
      if (!mounted) return;
      _navigateToChatScreen(
        buildContext,
        content,
        itemId,
        itemType, // Pass imported enum
        activeServerId,
      );

    } catch (e) {
      _dismissLoadingDialog();
      if (mounted) {
        _showAlertDialog(buildContext, 'Error', 'Failed to start chat: $e');
      }
    }
  }

  // Helper to perform the actual navigation to chat screen (copied from ItemDetailScreen)
  void _navigateToChatScreen(
    BuildContext buildContext,
    String fetchedContent,
    String itemId,
    WorkbenchItemType itemType, // USES IMPORTED ENUM
    String activeServerId,
  ) {
    final chatArgs = {
      'contextString': fetchedContent,
      'parentItemId': itemId,
      'parentItemType': itemType, // Pass imported enum
      'parentServerId': activeServerId,
    };

    // Push via root navigator only
    final rootNavigatorKey = ref.read(rootNavigatorKeyProvider);
    if (rootNavigatorKey.currentState != null) {
      rootNavigatorKey.currentState!.pushNamed('/chat', arguments: chatArgs);
    } else {
      _showAlertDialog(
        buildContext,
        'Error',
        'Could not access root navigator.',
      );
      if (kDebugMode) {
        print("Error: rootNavigatorKey.currentState is null");
      }
    }
  }
  // --- End Chat With Thread Helper (List Item) ---

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
        ref.read(ui_providers.selectedItemIdProvider.notifier).state =
            nextSelectedId;
      }
    }
  }

  void _navigateToItemDetail(BuildContext scaffoldContext, WidgetRef ref) {
    ref.read(ui_providers.selectedItemIdProvider.notifier).state =
        widget.note.id;
    Navigator.of(
      scaffoldContext,
      rootNavigator: true, // Use root navigator to push detail screen over tabs
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
        // Hide first to remove from list immediately
        ref
            .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
            .add(widget.note.id);

        await ref.read(note_providers.deleteNoteProvider(widget.note.id))();
        // No need to unhide on success
      } catch (e) {
        // Unhide if delete failed
        if (mounted) {
          ref
              .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
              .remove(widget.note.id);
          _showAlertDialog(
            scaffoldContext,
            'Error',
            'Failed to delete note: ${e.toString()}',
          );
        }
      }
    }
  }

  void onArchive(BuildContext scaffoldContext) {
    // Hide first to remove from list immediately
    ref
        .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
        .add(widget.note.id);
    // Attempt archive
    ref.read(note_providers.archiveNoteProvider(widget.note.id))().catchError((
      e,
    ) {
      // Unhide if archive failed
      if (mounted) {
        ref
            .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
            .remove(widget.note.id);
        _showAlertDialog(
          scaffoldContext,
          'Error',
          'Failed to archive note: ${e.toString()}',
        );
      }
    });
  }

  void onTogglePin(BuildContext scaffoldContext) {
    ref.read(note_providers.togglePinNoteProvider(widget.note.id))().catchError(
      (e) {
        if (mounted) {
          _showAlertDialog(
            scaffoldContext,
            'Error',
            'Failed to toggle pin: ${e.toString()}',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final BuildContext scaffoldContext = context;
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
            _showAlertDialog(
              scaffoldContext,
              'Error',
              'Failed to bump note: ${e.toString()}',
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
      cardWithDateInfo = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isMultiSelected
                    ? CupertinoTheme.of(scaffoldContext).primaryColor
                    : CupertinoColors.separator.resolveFrom(
                      scaffoldContext,
                    ), // Subtle border if not selected
            width: isMultiSelected ? 2 : 0.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: cardWithDateInfo,
      );

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
        extentRatio: 0.6, // Adjust width if needed
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
        extentRatio: 0.4, // Adjust width if needed
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
      child: Builder(
        builder: (builderContext) {
          return GestureDetector(
            onLongPress: () {
              _showCustomContextMenu(scaffoldContext);
            },
            onTap:
                isMultiSelectMode
                    ? () => _toggleMultiSelection(widget.note.id)
                    : () => _navigateToItemDetail(scaffoldContext, ref),
            child: Stack(children: [cardWithDateInfo]),
          );
        },
      ),
    );
  }
}
