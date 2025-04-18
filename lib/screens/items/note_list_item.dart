import 'dart:async'; // For Completer
import 'dart:math'; // For min

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart'; // Removed unused Material import
import 'package:flutter/services.dart';
import 'package:flutter_memos/main.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/models/workbench_item_type.dart';
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/utils/note_utils.dart';
import 'package:flutter_memos/utils/thread_utils.dart';
import 'package:flutter_memos/utils/workbench_utils.dart'; // Import the new utility
import 'package:flutter_memos/widgets/note_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class NoteListItem extends ConsumerStatefulWidget {
  final NoteItem note;
  final int index;
  final VoidCallback? onMoveToServer;
  final bool isInHiddenView;
  final String serverId;

  const NoteListItem({
    super.key,
    required this.note,
    required this.index,
    required this.isInHiddenView,
    required this.serverId,
    this.onMoveToServer,
  });

  @override
  NoteListItemState createState() => NoteListItemState();
}

class NoteListItemState extends ConsumerState<NoteListItem> {
  final GlobalKey<NoteCardState> _noteCardKey = GlobalKey<NoteCardState>();
  BuildContext? _loadingDialogContext;

  @override
  void dispose() {
    _dismissLoadingDialog();
    super.dispose();
  }

  void _dismissLoadingDialog() {
    if (_loadingDialogContext != null) {
      try {
        if (Navigator.of(_loadingDialogContext!).canPop()) {
          Navigator.of(_loadingDialogContext!).pop();
        }
      } catch (_) {}
      _loadingDialogContext = null;
    }
  }

  void _showLoadingDialog(BuildContext buildContext, String message) {
    _dismissLoadingDialog();
    if (!mounted) return;
    showCupertinoDialog(
      context: buildContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        _loadingDialogContext = dialogContext;
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

  Widget? _buildDateInfo(BuildContext context, NoteItem note) {
    if (note.startDate == null && note.endDate == null) {
      return null;
    }
    final now = DateTime.now();
    final bool isFutureStart = note.startDate?.isAfter(now) ?? false;
    final dateFormat = DateFormat.yMd().add_jm();
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

  void _showCustomContextMenu(BuildContext scaffoldContext) {
    final isManuallyHidden = ref
        .read(settings_p.manuallyHiddenNoteIdsProvider)
        .contains(widget.note.id);
    final now = DateTime.now();
    final isFutureDated = widget.note.startDate?.isAfter(now) ?? false;
    final activeServerId = ref.read(activeServerConfigProvider)?.id;
    final bool canInteractWithServer = widget.serverId == activeServerId;

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
                  Clipboard.setData(ClipboardData(text: widget.note.content));
                  Navigator.pop(popupContext);
                },
              ),
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
                            WorkbenchItemType.note,
                          );
                        },
                child: const Text('Copy Full Thread'),
              ),
              CupertinoContextMenuAction(
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
                          Navigator.pop(popupContext);
                          _chatWithThreadFromList(
                            scaffoldContext,
                            ref,
                            widget.note.id,
                            WorkbenchItemType.note,
                          );
                        },
                child: const Text('Chat about Thread'),
              ),
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
                child: const Text('Add to Workbench...'),
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
                                note_providers
                                    .notesNotifierProviderFamily(
                                      widget.serverId,
                                    )
                                    .notifier,
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
                                note_providers
                                    .notesNotifierProviderFamily(
                                      widget.serverId,
                                    )
                                    .notifier,
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
                                  note_providers
                                      .notesNotifierProviderFamily(
                                        widget.serverId,
                                      )
                                      .notifier,
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
  Future<void> _addNoteToWorkbenchFromList(
    BuildContext context, // Use BuildContext
    WidgetRef ref,
    NoteItem note,
  ) async {
    // Make async to await user selection
    // Use the serverId from the widget
    final serverConfig = ref
        .read(multiServerConfigProvider)
        .servers
        .firstWhereOrNull((s) => s.id == widget.serverId);

    if (serverConfig == null) {
      _showAlertDialog(
        context,
        'Error',
        "Cannot add to workbench: Server config not found.",
      );
      return;
    }

    // Use the utility function to get the target instance
    final selectedInstance = await showWorkbenchInstancePicker(
      context,
      ref,
      title: 'Add Note To Workbench',
    );

    // If user cancelled or no instance selected, do nothing
    if (selectedInstance == null) {
      return;
    }

    final targetInstanceId = selectedInstance.id;
    final targetInstanceName = selectedInstance.name;

    final preview = note.content.split('\n').first;

    final reference = WorkbenchItemReference(
      id: const Uuid().v4(),
      referencedItemId: note.id,
      referencedItemType: WorkbenchItemType.note, // USES IMPORTED ENUM
      serverId: serverConfig.id, // Use the note's serverId
      serverType: serverConfig.serverType,
      serverName: serverConfig.name,
      previewContent:
          preview.length > 100 ? '${preview.substring(0, 97)}...' : preview,
      addedTimestamp: DateTime.now(),
      parentNoteId: null,
      instanceId: targetInstanceId, // <-- PASS SELECTED instanceId
    );

    // Use the notifier for the *target* instance
    ref
        .read(workbenchProviderFamily(targetInstanceId).notifier)
        .addItem(reference);

    final previewText = reference.previewContent ?? 'Item';
    final dialogContent =
        'Added "${previewText.substring(0, min(30, previewText.length))}${previewText.length > 30 ? '...' : ''}" to Workbench "$targetInstanceName"';

    _showAlertDialog(context, 'Success', dialogContent);
  }

  Future<void> _copyThreadContentFromList(
    BuildContext buildContext,
    WidgetRef ref,
    String itemId,
    WorkbenchItemType itemType,
  ) async {
    final serverId = widget.serverId;
    _showLoadingDialog(buildContext, 'Fetching thread...');
    try {
      final content = await getFormattedThreadContent(
        ref,
        itemId,
        itemType,
        serverId,
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

  Future<void> _chatWithThreadFromList(
    BuildContext buildContext,
    WidgetRef ref,
    String itemId,
    WorkbenchItemType itemType,
  ) async {
    final serverId = widget.serverId;
    _showLoadingDialog(buildContext, 'Fetching thread for chat...');
    try {
      final content = await getFormattedThreadContent(
        ref,
        itemId,
        itemType,
        serverId,
      );
      _dismissLoadingDialog();
      if (!mounted) return;
      _navigateToChatScreen(buildContext, content, itemId, itemType, serverId);
    } catch (e) {
      _dismissLoadingDialog();
      if (mounted) {
        _showAlertDialog(buildContext, 'Error', 'Failed to start chat: $e');
      }
    }
  }

  void _navigateToChatScreen(
    BuildContext buildContext,
    String fetchedContent,
    String itemId,
    WorkbenchItemType itemType,
    String serverId,
  ) {
    final chatArgs = {
      'contextString': fetchedContent,
      'parentItemId': itemId,
      'parentItemType': itemType,
      'parentServerId': serverId,
    };
    final rootNavigatorKey = ref.read(rootNavigatorKeyProvider);
    if (rootNavigatorKey.currentState != null) {
      rootNavigatorKey.currentState!.pushNamed('/chat', arguments: chatArgs);
    } else {
      _showAlertDialog(
        buildContext,
        'Error',
        'Could not access root navigator.',
      );
      if (kDebugMode) print("Error: rootNavigatorKey.currentState is null");
    }
  }

  void _toggleHideItem(BuildContext scaffoldContext, WidgetRef ref) {
    final hiddenItemIds = ref.read(settings_p.manuallyHiddenNoteIdsProvider);
    final itemIdToToggle = widget.note.id;
    if (hiddenItemIds.contains(itemIdToToggle)) {
      ref
          .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
          .remove(itemIdToToggle);
    } else {
      final currentSelectedId = ref.read(ui_providers.selectedItemIdProvider);
      final notesBeforeAction = ref.read(
        note_providers.filteredNotesProviderFamily(widget.serverId),
      );
      String? nextSelectedId = currentSelectedId;
      if (currentSelectedId == itemIdToToggle && notesBeforeAction.isNotEmpty) {
        final actionIndex = notesBeforeAction.indexWhere(
          (n) => n.id == itemIdToToggle,
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
    Navigator.of(scaffoldContext, rootNavigator: true).pushNamed(
      '/item-detail',
      arguments: {
        'itemId': widget.note.id,
        'serverId': widget.serverId,
      },
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
      print(
        '[NoteListItem(${widget.serverId})] Multi-selection toggled for note ID: $noteId',
      );
      print(
        '[NoteListItem(${widget.serverId})] Current selection: ${currentSelection.join(", ")}',
      );
    }
  }

  void onEdit(BuildContext scaffoldContext) {
    Navigator.of(scaffoldContext, rootNavigator: true).pushNamed(
      '/edit-entity',
      arguments: {
        'entityType': 'note',
        'entityId': widget.note.id,
        'serverId': widget.serverId,
      },
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
        await ref.read(
          note_providers.deleteNoteProviderFamily((
            serverId: widget.serverId,
            noteId: widget.note.id,
          )),
        )();
      } catch (e) {
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
    ref
        .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
        .add(widget.note.id);
    ref
        .read(
          note_providers.archiveNoteProviderFamily((
            serverId: widget.serverId,
            noteId: widget.note.id,
          )),
        )()
        .catchError((e) {
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
    ref
        .read(
          note_providers.togglePinNoteProviderFamily((
            serverId: widget.serverId,
            noteId: widget.note.id,
          )),
        )()
        .catchError((e) {
          if (mounted) {
            _showAlertDialog(
              scaffoldContext,
              'Error',
              'Failed to toggle pin: ${e.toString()}',
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldContext = context;
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
          await ref.read(
            note_providers.bumpNoteProviderFamily((
              serverId: widget.serverId,
              noteId: widget.note.id,
            )),
          )();
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
                    : CupertinoColors.separator.resolveFrom(scaffoldContext),
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
        extentRatio: 0.6,
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
        extentRatio: 0.4,
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
