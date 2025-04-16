import 'dart:async';
import 'dart:math'; // For min

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // Needed for Clipboard
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Convert to ConsumerStatefulWidget for hover state
class WorkbenchItemTile extends ConsumerStatefulWidget {
  final WorkbenchItemReference itemReference;
  final int index;

  const WorkbenchItemTile({
    super.key,
    required this.itemReference,
    required this.index,
  });

  @override
  ConsumerState<WorkbenchItemTile> createState() => _WorkbenchItemTileState();
}

class _WorkbenchItemTileState extends ConsumerState<WorkbenchItemTile> {
  bool _isHovering = false;

  // Helper to get icon based on server type (remains the same)
  IconData _getServerTypeIcon(ServerType type) {
    switch (type) {
      case ServerType.memos:
        return CupertinoIcons.bolt_horizontal_circle_fill;
      case ServerType.blinko:
        return CupertinoIcons.sparkles;
      case ServerType.todoist:
        return CupertinoIcons.cloud; // Using cloud for Todoist server
    }
  }

  // Helper to format relative time strings (remains the same)
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m'; // Shorter format
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h'; // Shorter format
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d'; // Shorter format
    } else {
      return DateFormat.yMd().format(dateTime.toLocal()); // Keep full date for older items
    }
  }

  // Helper to show simple alert dialogs (remains the same)
  void _showAlertDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
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

  // --- Refactored Action Handlers ---

  Future<void> _handleRemoveItem() async {
    final preview = widget.itemReference.previewContent ?? 'Item';
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Remove from Workbench?'),
            content: Text(
              'Remove "${preview.substring(0, min(30, preview.length))}${preview.length > 30 ? '...' : ''}" from your Workbench?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(dialogContext, false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Remove'),
                onPressed: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      unawaited(
        ref
            .read(workbenchProvider.notifier)
            .removeItem(widget.itemReference.id),
      );
    }
  }

  Future<void> _handleToggleComplete() async {
    if (widget.itemReference.referencedItemType != WorkbenchItemType.task)
      return;

    final activeServer = ref.read(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == widget.itemReference.serverId;
    if (!isOnActiveServer) {
      _showServerSwitchRequiredDialog(context, ref, widget.itemReference);
      return;
    }

    try {
      final task = await ref.read(
        taskDetailProvider(widget.itemReference.referencedItemId).future,
      );
      bool success;
      String actionVerb;
      if (task.isCompleted) {
        actionVerb = 'reopened';
        success = await ref
            .read(tasksNotifierProvider.notifier)
            .reopenTask(task.id);
      } else {
        actionVerb = 'completed';
        success = await ref
            .read(tasksNotifierProvider.notifier)
            .completeTask(task.id);
      }
      if (success && mounted) {
        _showAlertDialog(context, 'Success', 'Task $actionVerb.');
        unawaited(ref.read(workbenchProvider.notifier).refreshItemDetails());
        unawaited(ref.read(tasksNotifierProvider.notifier).fetchTasks());
      } else if (!success && mounted) {
        _showAlertDialog(context, 'Error', 'Failed to toggle task status.');
      }
    } catch (e) {
      if (mounted) {
        _showAlertDialog(context, 'Error', 'Could not toggle task: $e');
      }
    }
  }

  void _copyContent() {
    final contentToCopy = widget.itemReference.previewContent ?? '';
    if (contentToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: contentToCopy));
      _showAlertDialog(context, 'Success', 'Content copied to clipboard.');
    } else {
      _showAlertDialog(context, 'Info', 'No content available to copy.');
    }
  }

  void _navigateToEdit() {
    final activeServer = ref.read(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == widget.itemReference.serverId;
    if (!isOnActiveServer) {
      _showServerSwitchRequiredDialog(context, ref, widget.itemReference);
      return;
    }

    final itemRef = widget.itemReference;
    final bool isRootNav = Navigator.of(context).canPop() == false;

    switch (itemRef.referencedItemType) {
      case WorkbenchItemType.note:
        Navigator.of(context, rootNavigator: isRootNav).pushNamed(
          '/edit-entity',
          arguments: {
            'entityType': 'note',
            'entityId': itemRef.referencedItemId,
          },
        );
        break;
      case WorkbenchItemType.task:
        // Fetch task details before navigating to edit screen
        ref
            .read(taskDetailProvider(itemRef.referencedItemId).future)
            .then((task) {
              if (mounted) {
                Navigator.of(context, rootNavigator: isRootNav).push(
                  CupertinoPageRoute(
                    builder: (context) => NewTaskScreen(taskToEdit: task),
                  ),
                );
              }
            })
            .catchError((e) {
              if (mounted) {
                _showErrorDialog(
                  context,
                  'Failed to load task details for editing: $e',
                );
              }
            });
        break;
      case WorkbenchItemType.comment:
        _showAlertDialog(
          context,
          'Info',
          'Comments cannot be edited directly.',
        );
        break;
    }
  }

  // --- End Refactored Action Handlers ---

  // --- Context Menu ---
  void _showContextMenu(BuildContext context) {
    final itemRef = widget.itemReference;
    final bool isTask = itemRef.referencedItemType == WorkbenchItemType.task;
    final bool isComment =
        itemRef.referencedItemType == WorkbenchItemType.comment;
    final bool isNote = itemRef.referencedItemType == WorkbenchItemType.note;

    final activeServer = ref.read(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == itemRef.serverId;

    showCupertinoModalPopup<void>(
      context: context, // Use the context passed to this method
      builder:
          (BuildContext popupContext) => CupertinoActionSheet(
            title: Text(
              itemRef.previewContent?.substring(
                    0,
                    min(30, itemRef.previewContent?.length ?? 0),
                  ) ??
                  'Item Options',
            ),
            actions: <Widget>[
              // View Details
              CupertinoActionSheetAction(
                child: const Text('View Details'),
                onPressed: () {
                  Navigator.pop(popupContext);
                  if (isOnActiveServer) {
                    _navigateToItem(
                      context,
                      ref,
                      itemRef,
                      commentIdToHighlight: null,
                    );
                  } else {
                    _showServerSwitchRequiredDialog(context, ref, itemRef);
                  }
                },
              ),
              // Edit (Note/Task only)
              if (!isComment)
                CupertinoActionSheetAction(
                  child: const Text('Edit'),
                  onPressed: () {
                    Navigator.pop(popupContext);
                    _navigateToEdit();
                  },
                ),
              // Toggle Complete (Task only)
              if (isTask)
                CupertinoActionSheetAction(
                  child: const Text('Toggle Complete'),
                  onPressed: () {
                    Navigator.pop(popupContext);
                    _handleToggleComplete();
                  },
                ),
              // Copy Content
              CupertinoActionSheetAction(
                child: const Text('Copy Content'),
                onPressed: () {
                  Navigator.pop(popupContext);
                  _copyContent();
                },
              ),
              // Remove from Workbench
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Remove from Workbench'),
                onPressed: () {
                  Navigator.pop(popupContext);
                  _handleRemoveItem(); // Use refactored handler
                },
              ),
              // Add other relevant actions here later (Pin, Archive, Dates etc.)
              // These might require fetching full item details first.
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
  // --- End Context Menu ---

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final preview =
        widget.itemReference.previewContent ?? 'No preview available';
    final serverDisplayName =
        widget.itemReference.serverName ?? widget.itemReference.serverId;
    // Use last activity time for the header timestamp
    final lastActivityRelative = _formatRelativeTime(
      widget.itemReference.overallLastUpdateTime.toLocal(),
    );

    final activeServer = ref.watch(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == widget.itemReference.serverId;

    final bool isTask =
        widget.itemReference.referencedItemType == WorkbenchItemType.task;
    final bool isCommentItem =
        widget.itemReference.referencedItemType == WorkbenchItemType.comment;

    // Define action buttons for the hover bar, now using refactored handlers
    final List<Widget> actions = [
      // View Details / Navigate Action
      CupertinoButton(
        padding: const EdgeInsets.all(4),
        minSize: 0,
        child: Icon(CupertinoIcons.eye, size: 18, color: theme.primaryColor),
        onPressed: () {
          if (isOnActiveServer) {
            _navigateToItem(
              context,
              ref,
              widget.itemReference,
              commentIdToHighlight: null,
            );
          } else {
            _showServerSwitchRequiredDialog(context, ref, widget.itemReference);
          }
        },
      ),
      const SizedBox(width: 6),
      // Toggle Complete Action (only for tasks on active server)
      if (isTask && isOnActiveServer) ...[
        CupertinoButton(
          padding: const EdgeInsets.all(4),
          minSize: 0,
          onPressed: _handleToggleComplete,
          child: Icon(
            CupertinoIcons.check_mark_circled,
            size: 18,
            color: theme.primaryColor,
          ), // Use refactored handler
        ),
        const SizedBox(width: 6),
      ],
      // Remove Action
      CupertinoButton(
        padding: const EdgeInsets.all(4),
        minSize: 0,
        onPressed: _handleRemoveItem,
        child: const Icon(
          CupertinoIcons.trash,
          size: 18,
          color: CupertinoColors.systemRed,
        ), // Use refactored handler
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Padding(
            padding: const EdgeInsets.only(top: 12.0, right: 6.0),
            child: ReorderableDragStartListener(
              index: widget.index,
              key: ValueKey('drag-handle-${widget.itemReference.id}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                child: Icon(
                  CupertinoIcons.bars,
                  color: CupertinoColors.systemGrey2.resolveFrom(context),
                  size: 20,
                ),
              ),
            ),
          ),

          // Main Content Area (Wrapped in GestureDetector for long-press)
          Expanded(
            child: GestureDetector(
              // Outer GestureDetector for long-press
              onLongPress: () => _showContextMenu(context),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                child: GestureDetector(
                  // Inner GestureDetector for tap
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (isOnActiveServer) {
                      _navigateToItem(
                        context,
                        ref,
                        widget.itemReference,
                        commentIdToHighlight: null,
                      );
                    } else {
                      _showServerSwitchRequiredDialog(
                        context,
                        ref,
                        widget.itemReference,
                      );
                    }
                  },
                  child: Stack(
                    children: [
                      // Main Content Column
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  _getServerTypeIcon(
                                    widget.itemReference.serverType,
                                  ),
                                  size: 16,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    serverDisplayName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.label.resolveFrom(
                                        context,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  lastActivityRelative,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.tertiaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Preview Content
                            if (!isCommentItem)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4.0,
                                  right: 4.0,
                                ),
                                child: Text(
                                  preview,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                  ),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (!isCommentItem) const SizedBox(height: 8),

                            // Comment Previews
                            if (!isCommentItem)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4.0,
                                  right: 4.0,
                                ),
                                child: _buildCommentPreviews(
                                  context,
                                  ref,
                                  widget.itemReference,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Hover Action Bar
                      if (_isHovering)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5.resolveFrom(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withAlpha(
                                    (255 * 0.1).round(),
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: actions,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the list of comment previews
  Widget _buildCommentPreviews(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference itemRef,
  ) {
    final comments = itemRef.previewComments;
    if (comments.isEmpty) {
      if (itemRef.referencedItemType != WorkbenchItemType.comment) {
        return _buildSingleCommentPreview(context, ref, itemRef, null);
      } else {
        return const SizedBox.shrink();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(comments.length, (index) {
        final comment = comments[index];
        final spacing =
            (index > 0) ? const SizedBox(height: 6) : const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            spacing,
            _buildSingleCommentPreview(context, ref, itemRef, comment),
          ],
        );
      }),
    );
  }

  // Builds a single comment preview widget
  Widget _buildSingleCommentPreview(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference itemRef,
    Comment? comment,
  ) {
    final textStyle = TextStyle(
      fontSize: 14,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );
    final italicStyle = textStyle.copyWith(
      fontStyle: FontStyle.italic,
      fontSize: 13,
    );

    final BoxDecoration decoration = BoxDecoration(
      color: CupertinoColors.systemGrey6.resolveFrom(context),
      border: Border(
        left: BorderSide(
          color: CupertinoColors.systemGrey3.resolveFrom(context),
          width: 3,
        ),
      ),
    );

    Widget contentWidget;
    String relativeTime = '';

    if (comment == null) {
      contentWidget = Text('No comments yet.', style: italicStyle);
    } else {
      // Get timestamp (using similar logic as in notifier, adapt if needed)
      DateTime commentTime;
      if (comment.updatedTs != null || comment.createdTs != null) {
         commentTime = comment.updatedTs ?? comment.createdTs;
      } else if (comment.postedAt != null) {
         commentTime = comment.postedAt!;
      } else {
         commentTime = DateTime.fromMillisecondsSinceEpoch(0); // Fallback
      }
      relativeTime = _formatRelativeTime(commentTime.toLocal());

      contentWidget = Row(
         crossAxisAlignment: CrossAxisAlignment.end, // Align time to bottom
         children: [
           Expanded(
             child: Text(
               comment.content ?? '',
               maxLines: 3, // Allow up to 3 lines
               overflow: TextOverflow.ellipsis,
               style: textStyle,
             ),
           ),
           const SizedBox(width: 8), // Space between text and time
           Text(
             relativeTime,
             style: TextStyle(
               fontSize: 11, // Smaller font for time
               color: CupertinoColors.tertiaryLabel.resolveFrom(context),
             ),
           ),
         ],
       );
    }

    // Make the comment preview tappable only if it's a real comment
    return GestureDetector(
      onTap:
          (comment == null)
              ? null
              : () {
                // Navigate to parent item, highlighting this specific comment
                final activeServer = ref.read(activeServerConfigProvider);
                final isOnActiveServer = activeServer?.id == itemRef.serverId;
                if (isOnActiveServer) {
                  _navigateToItem(
                    context,
                    ref,
                    itemRef,
                    commentIdToHighlight: comment.id,
                  );
                } else {
                  _showServerSwitchRequiredDialog(context, ref, itemRef);
                }
              },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ), // More vertical padding
        decoration: decoration,
        child: contentWidget, // Use the Row widget here
      ),
    );
  }
    @override
  WidgetRef ref,
    WorkbenchItemReference itemRef,
  {
    String? commentIdToHighlight,
  }
  ) async {
    final String itemId = itemRef.referencedItemId;
    final bool isRootNav = Navigator.of(context).canPop() == false;

    String targetItemId = itemId;
    if (itemRef.referencedItemType == WorkbenchItemType.comment) {
      targetItemId = itemRef.parentNoteId ?? itemId;
       commentIdToHighlight ??= itemId;
    }

    final Map<String, dynamic> arguments = {
      'itemId': targetItemId,
      if (commentIdToHighlight != null) 'commentIdToHighlight': commentIdToHighlight,
    };

    switch (itemRef.referencedItemType) {
      case WorkbenchItemType.note:
      case WorkbenchItemType.comment:
        if (targetItemId.isNotEmpty) {
           Navigator.of(context, rootNavigator: isRootNav).pushNamed(
            '/item-detail',
            arguments: arguments,
          );
        } else {
          _showErrorDialog(
            context,
            'Cannot navigate: Parent item ID is missing.',
          );
        }
        break;
      case WorkbenchItemType.task:
        try {
          final task = await ref.read(taskDetailProvider(itemId).future);
          if (mounted) {
            Navigator.of(context, rootNavigator: isRootNav).push(
              CupertinoPageRoute(
                builder: (context) => NewTaskScreen(taskToEdit: task),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            _showErrorDialog(context, 'Failed to load task details: $e');
          }
        }
        break;
    }
  }

  // Helper to show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Navigation Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
    );
  }

  // Server Switch Dialog
  void _showServerSwitchRequiredDialog(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference itemRef,
  ) {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Server Switch Required'),
            content: Text(
              'This item is on server "${itemRef.serverName ?? itemRef.serverId}". Switch to this server to view the item?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Switch & View'),
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  ref
                      .read(multiServerConfigProvider.notifier)
                      .setActiveServer(itemRef.serverId);

                  final completer = Completer<void>();
                  ProviderSubscription<ServerConfig?>? sub;

                  void listener(ServerConfig? previous, ServerConfig? next) {
                    if (sub != null &&
                        next?.id == itemRef.serverId &&
                        !completer.isCompleted) {
                      completer.complete();
                      sub!.close();
                      sub = null;
                    }
                  }

                  void errorHandler(Object error, StackTrace stackTrace) {
                    if (!completer.isCompleted) {
                      completer.completeError(error, stackTrace);
                      sub?.close();
                      sub = null;
                    }
                  }

                  final tempSub = ref.listen<ServerConfig?>(
                    activeServerConfigProvider,
                    listener,
                    onError: errorHandler,
                  );
                  sub = tempSub as ProviderSubscription<ServerConfig?>?;

                  final currentState = ref.read(activeServerConfigProvider);
                  if (currentState?.id == itemRef.serverId &&
                      !completer.isCompleted) {
                    completer.complete();
                    sub?.close();
                    sub = null;
                  }

                  try {
                    await completer.future.timeout(const Duration(seconds: 5));
                    if (mounted) {
                      _navigateToItem(context, ref, itemRef, commentIdToHighlight: null);
                    }
                  } catch (e) {
                    if (mounted) {
                      _showAlertDialog(
                        context,
                        'Error',
                        'Failed to switch server or timed out.',
                      );
                    }
                    sub?.close();
                    sub = null;
                  }
                },
              ),
            ],
          ),
    );
  }
}
