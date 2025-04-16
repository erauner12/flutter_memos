import 'dart:async';

import 'package:flutter/cupertino.dart';
// Import Material for Icons.drag_handle if needed, but CupertinoIcons.bars is used here.
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WorkbenchItemTile extends ConsumerWidget {
  final WorkbenchItemReference itemReference;
  final int index; // Add index parameter

  const WorkbenchItemTile({
    super.key, // Key is now passed from WorkbenchScreen
    required this.itemReference,
    required this.index, // Make index required
  });

  // Helper to get icon based on type
  IconData _getItemTypeIcon(WorkbenchItemType type) {
    switch (type) {
      case WorkbenchItemType.note:
        return CupertinoIcons.doc_text;
      case WorkbenchItemType.comment:
        return CupertinoIcons.chat_bubble_text;
      case WorkbenchItemType.task:
        return CupertinoIcons.check_mark_circled;
    }
  }

  // Helper to get icon based on server type
  IconData _getServerTypeIcon(ServerType type) {
    switch (type) {
      case ServerType.memos:
        return CupertinoIcons.bolt_horizontal_circle_fill;
      case ServerType.blinko:
        return CupertinoIcons.sparkles;
      case ServerType.todoist:
        return CupertinoIcons.check_mark_circled;
    }
  }

  // Helper to format relative time strings
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat.yMd().format(dateTime.toLocal());
    }
  }

  // Helper to show simple alert dialogs
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CupertinoTheme.of(context);
    final preview = itemReference.previewContent ?? 'No preview available';
    final serverDisplayName =
        itemReference.serverName ?? itemReference.serverId;
    final addedRelative = _formatRelativeTime(
      itemReference.addedTimestamp.toLocal(),
    );
    final lastActivityRelative = _formatRelativeTime(
      itemReference.overallLastUpdateTime.toLocal(),
    );

    final activeServer = ref.watch(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == itemReference.serverId;

    // Apply vertical margin to the Row to space out items in the list
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 0,
      ), // Adjust vertical spacing
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Vertically center handle and content
        children: [
          // Drag Handle
          ReorderableDragStartListener(
            index: index, // Use the passed index
            key: ValueKey(
              'drag-handle-${itemReference.id}',
            ), // Unique key for the handle listener
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 12.0,
                top: 14.0,
                bottom: 14.0,
              ), // Adjust padding for tap area and alignment
              child: Icon(
                CupertinoIcons.bars, // Drag handle icon
                color: CupertinoColors.systemGrey.resolveFrom(context),
                size: 24, // Adjust size as needed
              ),
            ),
          ),

          // Original Tile Content (Wrapped in Expanded)
          Expanded(
            child: CupertinoContextMenu(
              actions: <Widget>[
                // Action to navigate (always shown, logic handled onTap)
                CupertinoContextMenuAction(
                  child: const Text('View Details'),
                  onPressed: () {
                    Navigator.pop(context);
                    if (isOnActiveServer) {
                      _navigateToItem(context, ref, itemReference);
                    } else {
                      _showServerSwitchRequiredDialog(
                        context,
                        ref,
                        itemReference,
                      );
                    }
                  },
                ),
                // --- Add Conditional actions for Tasks ---
                if (itemReference.referencedItemType ==
                        WorkbenchItemType.task &&
                    isOnActiveServer) ...[
                  CupertinoContextMenuAction(
                    child: const Text('Toggle Complete'),
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        final task = await ref.read(
                          taskDetailProvider(
                            itemReference.referencedItemId,
                          ).future,
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
                        if (success && context.mounted) {
                          _showAlertDialog(
                            context,
                            'Success',
                            'Task $actionVerb.',
                          );
                          unawaited(
                            ref
                                .read(workbenchProvider.notifier)
                                .refreshItemDetails(),
                          );
                          unawaited(
                            ref
                                .read(tasksNotifierProvider.notifier)
                                .fetchTasks(),
                          );
                        } else if (!success && context.mounted) {
                          _showAlertDialog(
                            context,
                            'Error',
                            'Failed to toggle task status.',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          _showAlertDialog(
                            context,
                            'Error',
                            'Could not toggle task: $e',
                          );
                        }
                      }
                    },
                  ),
                ],
                // --- End Task Actions ---
                CupertinoContextMenuAction(
                  isDestructiveAction: true,
                  child: const Text('Remove from Workbench'),
                  onPressed: () {
                    Navigator.pop(context);
                    showCupertinoDialog(
                      context: context,
                      builder:
                          (dialogContext) => CupertinoAlertDialog(
                            title: const Text('Remove from Workbench?'),
                            content: Text(
                              'Remove "${preview.substring(0, preview.length > 30 ? 30 : preview.length)}..." from your Workbench?',
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(dialogContext),
                              ),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                child: const Text('Remove'),
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  unawaited(
                                    ref
                                        .read(workbenchProvider.notifier)
                                        .removeItem(itemReference.id),
                                  );
                                },
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ],
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // Ensures taps are caught
                onTap: () {
                  if (isOnActiveServer) {
                    _navigateToItem(context, ref, itemReference);
                  } else {
                    _showServerSwitchRequiredDialog(
                      context,
                      ref,
                      itemReference,
                    );
                  }
                },
                child: Container(
                  // margin was removed from here
                  padding: const EdgeInsets.only(
                    top: 14,
                    bottom: 14,
                    left: 0,
                    right: 12,
                  ), // Adjusted padding (removed left, reduced right)
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGroupedBackground.resolveFrom(
                      context,
                    ),
                    // No border or shadow needed if it's part of the row visually
                    // If a card-like appearance is desired, apply decoration here or to the outer Container
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0, right: 10),
                            child: Icon(
                              _getItemTypeIcon(
                                itemReference.referencedItemType,
                              ),
                              color: theme.primaryColor,
                              size: 22,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preview,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Server: $serverDisplayName • Added: $addedRelative',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Last activity: $lastActivityRelative',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                            child: Icon(
                              _getServerTypeIcon(itemReference.serverType),
                              size: 18,
                              color: CupertinoColors.tertiaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (itemReference.referencedItemType !=
                          WorkbenchItemType.comment)
                        _buildCommentPreview(
                          context,
                          itemReference.latestComment,
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

  // Add helper widget for comment preview
  Widget _buildCommentPreview(BuildContext context, Comment? comment) {
    final textStyle = TextStyle(
      fontSize: 13,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );
    final italicStyle = textStyle.copyWith(fontStyle: FontStyle.italic);

    if (comment == null) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.only(left: 14, top: 6, bottom: 6, right: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          border: Border(
            left: BorderSide(
              color: CupertinoColors.systemGrey4.resolveFrom(context),
              width: 2.5,
            ),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Text('No comments yet.', style: italicStyle),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(left: 14, top: 6, bottom: 6, right: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        border: Border(
          left: BorderSide(
            color: CupertinoColors.systemGrey4.resolveFrom(context),
            width: 2.5,
          ),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      child: Text(
        comment.content ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
    );
  }

  // Helper for actual navigation (call AFTER server switch if needed)
  Future<void> _navigateToItem(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference itemRef,
  ) async {
    final String itemId = itemRef.referencedItemId;
    // Check if the current context's navigator is the root navigator of the tab.
    final bool isRootNav = Navigator.of(context).canPop() == false;

    switch (itemRef.referencedItemType) {
      case WorkbenchItemType.note:
        // Navigate to note detail screen
        Navigator.of(
          context,
          rootNavigator: isRootNav,
        ).pushNamed(
          '/item-detail',
          arguments: {'itemId': itemId},
        );
        break;
      case WorkbenchItemType.comment:
        // Navigate to parent note detail, highlighting the comment
        final parentId = itemRef.parentNoteId ?? itemId;
        if (parentId.isNotEmpty) {
          Navigator.of(context, rootNavigator: isRootNav).pushNamed(
            '/item-detail',
            arguments: {
              'itemId': parentId,
              'commentIdToHighlight': itemId,
            },
          );
        } else {
          _showErrorDialog(
            context,
            'Cannot navigate to comment: Parent note ID is missing.',
          );
        }
        break;
      case WorkbenchItemType.task:
        // Navigate to the task edit/detail screen
        try {
          final task = await ref.read(taskDetailProvider(itemId).future);
          if (context.mounted) {
            Navigator.of(context, rootNavigator: isRootNav).push(
              CupertinoPageRoute(
                builder: (context) => NewTaskScreen(taskToEdit: task),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
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

  // Add this method back below _navigateToItem:
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
                    if (context.mounted) {
                      _navigateToItem(context, ref, itemRef);
                    }
                  } catch (e) {
                    if (context.mounted) {
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
