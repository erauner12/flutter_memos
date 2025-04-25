import 'dart:async'; // For Completer
import 'dart:math'; // For min

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart'; // Removed unused Material import
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart'; // Keep generic name for now, or rename if needed
import 'package:flutter_memos/models/workbench_item_type.dart'; // Keep generic name for now, or rename if needed
// import 'package:flutter_memos/main.dart'; // Import for rootNavigatorKeyProvider
import 'package:flutter_memos/providers/navigation_providers.dart';
// Import new single config provider
import 'package:flutter_memos/providers/note_server_config_provider.dart';
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/providers/workbench_provider.dart'; // Correct import: focus -> workbench
import 'package:flutter_memos/utils/note_utils.dart';
import 'package:flutter_memos/utils/thread_utils.dart';
import 'package:flutter_memos/utils/workbench_utils.dart'; // Correct import: focus -> workbench
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
  final BlinkoNoteType? type; // Add type
  // Action handlers passed down from NotesListBody
  final Future<void> Function() onArchive;
  final Future<void> Function() onDelete;
  final Future<void> Function() onTogglePin;
  final Future<void> Function() onBump;
  final Future<void> Function(DateTime?) onUpdateStartDate;
  final void Function() onToggleVisibility;
  final void Function() onUnhide;

  const NoteListItem({
    super.key,
    required this.note,
    required this.index,
    required this.isInHiddenView,
    required this.type, // Require type
    required this.onArchive,
    required this.onDelete,
    required this.onTogglePin,
    required this.onBump,
    required this.onUpdateStartDate,
    required this.onToggleVisibility,
    required this.onUnhide,
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

  // Helper to build the Blinko Type indicator
  Widget? _buildBlinkoTypeIndicator(BuildContext context, NoteItem note) {
    String? label;
    Color? color;
    IconData? icon;

    switch (note.blinkoType) {
      case BlinkoNoteType.cache:
        label = 'Cache';
        color = CupertinoColors.systemGreen.resolveFrom(context);
        icon = CupertinoIcons.archivebox; // Example icon
        break;
      case BlinkoNoteType.vault:
        label = 'Vault';
        color = CupertinoColors.systemPurple.resolveFrom(context);
        icon = CupertinoIcons.lock_shield; // Example icon
        break;
      case BlinkoNoteType.unknown:
        return null; // Don't show anything for unknown type
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color:
                  color ?? CupertinoColors.secondaryLabel.resolveFrom(context),
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
    // Get the single note server config
    final noteServerConfig = ref.read(noteServerConfigProvider);
    // Interaction is possible if a note server is configured
    final bool canInteractWithServer = noteServerConfig != null;

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
                            WorkbenchItemType
                                .note, // Assuming this enum remains generic
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
                            WorkbenchItemType
                                .note, // Assuming this enum remains generic
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
                            // Use the passed down function
                            widget.onUnhide();
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
                            // Use the passed down function
                            widget.onToggleVisibility();
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
                            // Updated method name
                            scaffoldContext,
                            ref,
                            widget.note,
                          );
                        },
                child: const Text('Add to Workbench...'), // Updated text
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
                          // Use the passed down function
                          widget.onUpdateStartDate(newStartDate);
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
                          // Use the passed down function
                          widget.onUpdateStartDate(newStartDate);
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
                            // Use the passed down function
                            widget.onUpdateStartDate(null);
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

  // --- Helper to add note to workbench --- Updated name and references
  Future<void> _addNoteToWorkbenchFromList(
    // Updated name
    BuildContext context, // Use BuildContext
    WidgetRef ref,
    NoteItem note,
  ) async {
    // Make async to await user selection
    // Use the single note server config provider
    final serverConfig = ref.read(noteServerConfigProvider);

    if (serverConfig == null) {
      _showAlertDialog(
        context,
        'Error',
        "Cannot add to workbench: Note server config not found.", // Updated text
      );
      return;
    }

    // Use the updated utility function to get the target instance
    final selectedInstance = await showWorkbenchInstancePicker(
      // Correct function call
      context,
      ref,
      title: 'Add Note To Workbench', // Updated text
    );

    // If user cancelled or no instance selected, do nothing
    if (selectedInstance == null) {
      return;
    }

    final targetInstanceId = selectedInstance.id;
    final targetInstanceName = selectedInstance.name;

    final preview = note.content.split('\n').first;

    // Assuming WorkbenchItemReference and WorkbenchItemType remain generic or are renamed elsewhere
    final reference = WorkbenchItemReference(
      id: const Uuid().v4(),
      referencedItemId: note.id,
      referencedItemType: WorkbenchItemType.note,
      serverId: serverConfig.id,
      serverType: serverConfig.serverType,
      serverName: serverConfig.name,
      previewContent:
          preview.length > 100 ? '${preview.substring(0, 97)}...' : preview,
      addedTimestamp: DateTime.now(),
      parentNoteId: null,
      instanceId: targetInstanceId,
    );

    // Use the updated provider family for the *target* instance
    ref
        .read(
          workbenchProviderFamily(
            targetInstanceId,
          ).notifier, // Correct provider family
        )
        .addItem(reference);

    final previewText = reference.previewContent ?? 'Item';
    final dialogContent =
        'Added "${previewText.substring(0, min(30, previewText.length))}${previewText.length > 30 ? '...' : ''}" to Workbench "$targetInstanceName"'; // Updated text

    _showAlertDialog(context, 'Success', dialogContent);
  }

  Future<void> _copyThreadContentFromList(
    BuildContext buildContext,
    WidgetRef ref,
    String itemId,
    WorkbenchItemType itemType, // Assuming generic type
  ) async {
    // Get serverId from the single provider
    final serverId = ref.read(noteServerConfigProvider)?.id;
    if (serverId == null) {
      _showAlertDialog(buildContext, 'Error', 'Note server not configured.');
      return;
    }
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
    WorkbenchItemType itemType, // Assuming generic type
  ) async {
    // Get serverId from the single provider
    final serverId = ref.read(noteServerConfigProvider)?.id;
    if (serverId == null) {
      _showAlertDialog(buildContext, 'Error', 'Note server not configured.');
      return;
    }
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
    WorkbenchItemType itemType, // Assuming generic type
    String serverId,
  ) {
    final chatArgs = {
      'contextString': fetchedContent,
      'parentItemId': itemId,
      'parentItemType': itemType,
      'parentServerId': serverId,
    };
    // Read the provider (now imported from navigation_providers.dart)
    final rootNavigatorKey = ref.read(
      rootNavigatorKeyProvider,
    ); // Use imported provider
    if (rootNavigatorKey.currentState != null) {
      // Assuming '/chat' route still exists or is replaced by '/studio' route
      // TODO: Update route name if chat is replaced by studio
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

  void _navigateToItemDetail(BuildContext scaffoldContext, WidgetRef ref) {
    ref.read(ui_providers.selectedItemIdProvider.notifier).state =
        widget.note.id;
    Navigator.of(scaffoldContext, rootNavigator: true).pushNamed(
      '/item-detail',
      arguments: {
        'itemId': widget.note.id,
        // serverId is no longer needed here, detail screen gets it from provider
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
        '[NoteListItem] Multi-selection toggled for note ID: $noteId',
      );
      print(
        '[NoteListItem] Current selection: ${currentSelection.join(", ")}',
      );
    }
  }

  void onEdit(BuildContext scaffoldContext) {
    Navigator.of(scaffoldContext, rootNavigator: true).pushNamed(
      '/edit-entity',
      arguments: {
        'entityType': 'note',
        'entityId': widget.note.id,
        // serverId is no longer needed here
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
        // Use the passed down function
        await widget.onDelete();
      } catch (e) {
        if (mounted) {
          _showAlertDialog(
            scaffoldContext,
            'Error',
            'Failed to delete note: ${e.toString()}',
          );
        }
      }
    }
  }

  void onArchive(BuildContext scaffoldContext) async {
    try {
      // Use the passed down function
      await widget.onArchive();
    } catch (e) {
      if (mounted) {
        _showAlertDialog(
          scaffoldContext,
          'Error',
          'Failed to archive note: ${e.toString()}',
        );
      }
    }
  }

  void onTogglePin(BuildContext scaffoldContext) async {
    try {
      // Use the passed down function
      await widget.onTogglePin();
    } catch (e) {
      if (mounted) {
        _showAlertDialog(
          scaffoldContext,
          'Error',
          'Failed to toggle pin: ${e.toString()}',
        );
      }
    }
  }

  void onBump(BuildContext scaffoldContext) async {
     try {
       // Use the passed down function
       await widget.onBump();
     } catch (e) {
       if (mounted) {
         _showAlertDialog(
           scaffoldContext,
           'Error',
           'Failed to bump note: ${e.toString()}',
         );
       }
     }
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
      onHide: widget.onToggleVisibility, // Use passed down function
      onTogglePin: () => onTogglePin(scaffoldContext),
      onBump: () => onBump(scaffoldContext), // Use passed down function
      onMoveToServer: widget.onMoveToServer,
    );

    final dateInfoWidget = _buildDateInfo(scaffoldContext, widget.note);
    final blinkoTypeIndicator = _buildBlinkoTypeIndicator(
      scaffoldContext,
      widget.note,
    );

    Widget cardWithExtras = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (blinkoTypeIndicator != null)
          blinkoTypeIndicator, // Add type indicator above card
        noteCardWidget,
        if (dateInfoWidget != null) dateInfoWidget,
      ],
    );

    if (isMultiSelectMode) {
      cardWithExtras = Container(
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
        child: cardWithExtras,
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
            Expanded(child: cardWithExtras),
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
              onPressed: (_) => widget.onUnhide(), // Use passed down function
              backgroundColor: CupertinoColors.systemGreen,
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.eye_fill,
              label: 'Unhide',
              autoClose: true,
            )
          else
            SlidableAction(
              onPressed: (_) => widget.onToggleVisibility(), // Use passed down function
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
            child: Stack(children: [cardWithExtras]),
          );
        },
      ),
    );
  }
}
