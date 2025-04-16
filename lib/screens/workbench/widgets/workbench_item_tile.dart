import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/task_item.dart'; // Import TaskItem
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/server_config_provider.dart'; // Add this import for activeServerConfigProvider and multiServerConfigProvider
import 'package:flutter_memos/providers/task_providers.dart'; // Import task providers for actions
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/tasks/new_task_screen.dart'; // Import task edit screen
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:uuid/uuid.dart'; // For generating UUIDs

class WorkbenchItemTile extends ConsumerWidget {
  final WorkbenchItemReference itemReference;

  const WorkbenchItemTile({super.key, required this.itemReference});

  // Helper to get icon based on type
  IconData _getItemTypeIcon(WorkbenchItemType type) {
    switch (type) {
      case WorkbenchItemType.note:
        return CupertinoIcons.doc_text;
      case WorkbenchItemType.comment:
        return CupertinoIcons.chat_bubble_text;
      case WorkbenchItemType.task:
        return CupertinoIcons.check_mark_circled; // Updated icon for task
    }
  }

  // Helper to get icon based on server type
  IconData _getServerTypeIcon(ServerType type) {
    switch (type) {
      case ServerType.memos:
        return CupertinoIcons.bolt_horizontal_circle_fill; // Example icon
      case ServerType.blinko:
        return CupertinoIcons.sparkles; // Example icon
      case ServerType.todoist:
        return CupertinoIcons
            .check_mark_circled; // Use same icon as item type for consistency
    }
  }

  // Add this helper to the class, below the icon helpers:
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
      // Fallback to date string if older than a week
      return DateFormat.yMd().format(dateTime.toLocal()); // Ensure local time
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

  // Helper to show snackbar messages
  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isError ? CupertinoColors.destructiveRed : null,
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CupertinoTheme.of(context);
    final preview = itemReference.previewContent ?? 'No preview available';
    final serverDisplayName =
        itemReference.serverName ?? itemReference.serverId;
    // Format times using helper, ensure they are local
    final addedRelative = _formatRelativeTime(
      itemReference.addedTimestamp.toLocal(),
    );
    final lastActivityRelative = _formatRelativeTime(
      itemReference.overallLastUpdateTime.toLocal(),
    );

    // Get the current active serverId
    final activeServer = ref.watch(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == itemReference.serverId;

    return CupertinoContextMenu(
      actions: <Widget>[
        // Action to navigate (always shown, logic handled onTap)
        CupertinoContextMenuAction(
          child: const Text('View Details'),
          onPressed: () {
            Navigator.pop(context); // Close context menu
            if (isOnActiveServer) {
              _navigateToItem(context, ref, itemReference);
            } else {
              _showServerSwitchRequiredDialog(context, ref, itemReference);
            }
          },
        ),
        // Conditional actions for Tasks
        if (itemReference.referencedItemType == WorkbenchItemType.task &&
            isOnActiveServer)
        ...[
          CupertinoContextMenuAction(
            child: const Text('Toggle Complete'), // Simplistic label
            onPressed: () async {
              Navigator.pop(context); // Close menu first
              try {
                final task = await ref.read(
                  taskDetailProvider(itemReference.referencedItemId).future,
                );
                bool success;
                if (task.isCompleted) {
                  success = await ref
                      .read(tasksNotifierProvider.notifier)
                      .reopenTask(task.id);
                  if (success && context.mounted) {
                    _showSnackBar(context, 'Task reopened.');
                  }
                } else {
                  success = await ref
                      .read(tasksNotifierProvider.notifier)
                      .completeTask(task.id);
                  if (success && context.mounted) {
                    _showSnackBar(context, 'Task completed.');
                  }
                }
                if (!success && context.mounted) {
                  _showSnackBar(
                    context,
                    'Failed to toggle task status.',
                    isError: true,
                  );
                }
                ref.read(workbenchProvider.notifier).refreshItemDetails();
              } catch (e) {
                if (context.mounted) {
                  _showSnackBar(
                    context,
                    'Error getting task status: $e',
                    isError: true,
                  );
                }
              }
            },
          ),
        ],

        // Remove from Workbench action
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          child: const Text('Remove from Workbench'),
          onPressed: () {
            Navigator.pop(context); // Close context menu
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
                          Navigator.pop(
                            dialogContext,
                          ); // Close confirmation dialog
                          unawaited(
                            ref
                                .read(workbenchProvider.notifier)
                                .removeItem(itemReference.id),
                          );
                          _showSnackBar(
                            context,
                            'Item removed from Workbench.',
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
        behavior: HitTestBehavior.opaque, // Ensure empty areas are tappable
        onTap: () {
          if (isOnActiveServer) {
            _navigateToItem(context, ref, itemReference);
          } else {
            _showServerSwitchRequiredDialog(context, ref, itemReference);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 12,
          ), // Reduced vertical margin
          padding: const EdgeInsets.all(14), // Reduced padding
          decoration: BoxDecoration(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12), // Slightly smaller radius
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5, // Thinner border
            ),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withAlpha((0.03 * 255).toInt()),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
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
                      _getItemTypeIcon(itemReference.referencedItemType),
                      color: theme.primaryColor,
                      size: 22, // Slightly smaller icon
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preview,
                          maxLines: 3, // Keep max lines
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16, // Keep font size
                            fontWeight: FontWeight.w500, // Slightly less bold
                          ),
                        ),
                        const SizedBox(height: 5), // Adjust spacing
                        Text(
                          'Server: $serverDisplayName • Added: $addedRelative',
                          style: TextStyle(
                            fontSize: 12, // Smaller font size
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Last activity: $lastActivityRelative',
                          style: TextStyle(
                            fontSize: 12, // Smaller font size
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
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
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
              if (itemReference.referencedItemType != WorkbenchItemType.comment)
                _buildCommentPreview(context, itemReference.latestComment),
            ],
          ),
        ),
      ),
    );
  }

  // Add helper widget for comment preview
  Widget _buildCommentPreview(BuildContext context, Comment? comment) {
    final textStyle = TextStyle(
      fontSize: 13, // Slightly smaller
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );
    final italicStyle = textStyle.copyWith(fontStyle: FontStyle.italic);

    if (comment == null) {
      return Container(
        margin: const EdgeInsets.only(top: 10), // Reduced margin
        padding: const EdgeInsets.only(
          left: 14,
          top: 6,
          bottom: 6,
          right: 6,
        ), // Reduced padding
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          border: Border(
            left: BorderSide(
              color: CupertinoColors.systemGrey4.resolveFrom(context),
              width: 2.5, // Slightly thinner border
            ),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ), // Rounded corners
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
        comment.content ?? '', // Handle null content
        maxLines: 2, // Limit preview lines
        overflow: TextOverflow.ellipsis,
        style: textStyle, // No italic for actual comment preview
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
    final bool isRootNav =
        Navigator.of(context).canPop() ==
        false; // Check if it's the root of the tab

    switch (itemRef.referencedItemType) {
      case WorkbenchItemType.note:
        Navigator.of(
          context,
          rootNavigator: isRootNav,
        ).pushNamed(
          '/item-detail',
          arguments: {'itemId': itemId},
        );
        break;
      case WorkbenchItemType.comment:
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
                  Navigator.pop(dialogContext); // Close the dialog first
                  ref
                      .read(multiServerConfigProvider.notifier)
                      .setActiveServer(itemRef.serverId);

                  final completer = Completer<void>();
                  ProviderSubscription<ServerConfig?>? sub;
                  sub = ref.listen<ServerConfig?>(
                    activeServerConfigProvider,
                    (previous, next) {
                      if (sub != null &&
                          next?.id == itemRef.serverId &&
                          !completer.isCompleted) {
                        completer.complete();
                        sub?.close();
                        sub = null;
                      }
                    },
                    onError: (error, stackTrace) {
                      if (!completer.isCompleted) {
                        completer.completeError(error, stackTrace);
                        sub?.close();
                        sub = null;
                      }
                    },
                  );

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
