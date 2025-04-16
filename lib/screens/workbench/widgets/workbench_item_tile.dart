import 'dart:async';

import 'package:flutter/cupertino.dart';
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

  // Helper to get icon based on type (remains the same)
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

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final preview = widget.itemReference.previewContent ?? 'No preview available';
    final serverDisplayName =
        widget.itemReference.serverName ?? widget.itemReference.serverId;
    // Use last activity time for the header timestamp
    final lastActivityRelative = _formatRelativeTime(
      widget.itemReference.overallLastUpdateTime.toLocal(),
    );

    final activeServer = ref.watch(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == widget.itemReference.serverId;

    final bool isTask = widget.itemReference.referencedItemType == WorkbenchItemType.task;
    final bool isCommentItem =
        widget.itemReference.referencedItemType == WorkbenchItemType.comment;

    // Define action buttons for the hover bar
    final List<Widget> actions = [
      // View Details / Navigate Action
      CupertinoButton(
        padding: const EdgeInsets.all(4),
        minSize: 0,
        tooltip: 'View Details',
        child: Icon(CupertinoIcons.eye, size: 18, color: theme.primaryColor),
        onPressed: () {
          if (isOnActiveServer) {
            // Navigate to parent item, don't highlight specific comment from main action bar
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
          tooltip: 'Toggle Complete',
          child: Icon(CupertinoIcons.check_mark_circled, size: 18, color: theme.primaryColor),
          onPressed: () async {
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
                if (success && context.mounted) {
                  _showAlertDialog(context, 'Success', 'Task $actionVerb.');
                  unawaited(
                    ref.read(workbenchProvider.notifier).refreshItemDetails(),
                  );
                  unawaited(
                    ref.read(tasksNotifierProvider.notifier).fetchTasks(),
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
        const SizedBox(width: 6),
      ],
      // Remove Action
      CupertinoButton(
        padding: const EdgeInsets.all(4),
        minSize: 0,
        tooltip: 'Remove from Workbench',
        child: const Icon(CupertinoIcons.trash, size: 18, color: CupertinoColors.systemRed),
        onPressed: () {
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
                                .removeItem(widget.itemReference.id),
                          );
                        },
                      ),
                    ],
                  ),
            );
        },
      ),
    ];

    return Container(
      // Add horizontal padding to the outer container to indent the whole row slightly
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      margin: const EdgeInsets.symmetric(vertical: 4), // Reduced vertical margin
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align handle to top
        children: [
          // Drag Handle - Reduced Padding
          Padding(
            // Add padding top to align better with content row
            padding: const EdgeInsets.only(top: 12.0, right: 6.0),
            child: ReorderableDragStartListener(
              index: widget.index,
              key: ValueKey('drag-handle-${widget.itemReference.id}'),
              child: Padding(
                // Reduced horizontal padding
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                child: Icon(
                  CupertinoIcons.bars,
                  color: CupertinoColors.systemGrey2.resolveFrom(context),
                  size: 20, // Slightly smaller handle
                ),
              ),
            ),
          ),

          // Main Content Area (Expanded + Stack for hover actions)
          Expanded(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: GestureDetector(
                 behavior: HitTestBehavior.opaque, // Ensures taps are caught over the whole area
                 onTap: () {
                   if (isOnActiveServer) {
                    // Navigate to parent item, don't highlight specific comment from main tap
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
                child: Stack(
                  children: [
                    // Main Content Column
                    Padding(
                      // Padding around the main content block
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: Server Icon + Name + Timestamp
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                _getServerTypeIcon(widget.itemReference.serverType),
                                size: 16,
                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  serverDisplayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.label.resolveFrom(context),
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
                                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Preview Content
                          if (!isCommentItem) // Don't show main preview if the item *is* a comment
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4.0,
                                right: 4.0,
                              ), // Indent slightly
                              child: Text(
                                preview,
                                style: TextStyle(
                                  fontSize: 15, // Slightly smaller main text
                                  color: CupertinoColors.label.resolveFrom(
                                    context,
                                  ),
                                ),
                                maxLines: 5, // Allow more lines for preview
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (!isCommentItem)
                            const SizedBox(
                              height: 8,
                            ), // Spacing only if preview exists

                          // Comment Previews (if applicable)
                          // Don't show comment previews if the item itself is a comment
                          if (!isCommentItem)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0, right: 4.0), // Indent slightly
                              child: _buildCommentPreviews(
                                context,
                                ref,
                                widget.itemReference,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Hover Action Bar (Top Right)
                    if (_isHovering)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey5.resolveFrom(context),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ]
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
      // Show "No comments yet" only if the item is not a comment itself
      if (itemRef.referencedItemType != WorkbenchItemType.comment) {
        return _buildSingleCommentPreview(
          context,
          ref,
          itemRef,
          null,
        ); // Pass null to show placeholder
      } else {
        return const SizedBox.shrink(); // Don't show anything if item is comment and no previews
      }
    }

    // Build previews for the available comments (max 2)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(comments.length, (index) {
        final comment = comments[index];
        // Add spacing between comment previews
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

  // Builds a single comment preview widget (or placeholder if comment is null)
  Widget _buildSingleCommentPreview(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference itemRef,
    Comment? comment,
  ) {
    final textStyle = TextStyle(
      fontSize: 14, // Slightly larger comment font
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

    Widget content;
    if (comment == null) {
      content = Text('No comments yet.', style: italicStyle);
    } else {
      content = Text(
        comment.content ?? '',
        maxLines: 3, // Allow up to 3 lines
        overflow: TextOverflow.ellipsis,
        style: textStyle,
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
        child: content,
      ),
    );
  }


  // Helper for actual navigation (call AFTER server switch if needed)
  // Added optional commentIdToHighlight parameter
  Future<void> _navigateToItem(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference itemRef,
  { String? commentIdToHighlight } // Optional parameter
  ) async {
    final String itemId = itemRef.referencedItemId;
    final bool isRootNav = Navigator.of(context).canPop() == false;

    // Determine the ID to navigate to (parent note/task ID)
    String targetItemId = itemId;
    // If the workbench item *is* a comment, use its parentNoteId for navigation
    if (itemRef.referencedItemType == WorkbenchItemType.comment) {
       targetItemId = itemRef.parentNoteId ?? itemId; // Fallback to itemId if parentNoteId is null
       // Ensure the comment being tapped (if any) or the item itself is highlighted
       commentIdToHighlight ??= itemId;
    }

    // Prepare arguments, including the comment to highlight
    final Map<String, dynamic> arguments = {
      'itemId': targetItemId,
      if (commentIdToHighlight != null) 'commentIdToHighlight': commentIdToHighlight,
    };


    switch (itemRef.referencedItemType) {
      case WorkbenchItemType.note:
      case WorkbenchItemType.comment: // Comments navigate to their parent note detail
        if (targetItemId.isNotEmpty) {
           Navigator.of(context, rootNavigator: isRootNav).pushNamed(
            '/item-detail', // Assuming this screen handles notes and their comments
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
        // Task navigation might not support comment highlighting directly in NewTaskScreen
        // For now, just navigate to the task edit screen.
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

  // Server Switch Dialog (remains the same)
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
                      // After switching, navigate again (don't highlight comment on switch)
                      _navigateToItem(context, ref, itemRef, commentIdToHighlight: null);
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
