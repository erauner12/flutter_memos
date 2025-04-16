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
import 'package:flutter_memos/utils/thread_utils.dart'; // Import the utility
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
    // Ensure context is mounted before showing dialog
    if (!mounted) return;
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

  // --- Copy Thread Content Helper ---
  Future<void> _copyThreadContentFromWorkbench(
    BuildContext buildContext,
    WidgetRef ref,
    WorkbenchItemReference itemRef,
  ) async {
    final activeServer = ref.read(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == itemRef.serverId;

    if (!isOnActiveServer) {
      _showServerSwitchRequiredDialog(
        buildContext,
        ref,
        itemRef,
      ); // Reuse existing dialog
      return;
    }

    // Show loading indicator
    showCupertinoDialog(
      context: buildContext,
      barrierDismissible: false,
      builder:
          (dialogContext) => const CupertinoAlertDialog(
            content: Row(
              children: [
                CupertinoActivityIndicator(),
                SizedBox(width: 15),
                Text('Fetching thread...'),
              ],
            ),
          ),
    );

    try {
      // Server is already confirmed to be active
      final content = await getFormattedThreadContent(
        ref,
        itemRef.referencedItemId,
        itemRef.referencedItemType,
        itemRef.serverId,
      );
      await Clipboard.setData(ClipboardData(text: content));
      if (!mounted) return;
      Navigator.pop(buildContext); // Dismiss loading
      _showAlertDialog(
        buildContext,
        'Success',
        'Thread content copied to clipboard.',
      ); // Reuse existing dialog helper
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(buildContext); // Dismiss loading
      _showAlertDialog(
        buildContext,
        'Error',
        'Failed to copy thread: $e',
      ); // Reuse existing dialog helper
    }
  }
  // --- End Copy Thread Content Helper ---

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
    // final bool isNote = itemRef.referencedItemType == WorkbenchItemType.note; // Removed unused variable

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
              // --- Copy Full Thread Action ---
              CupertinoActionSheetAction(
                child: const Text('Copy Full Thread'),
                onPressed: () {
                  Navigator.pop(popupContext);
                  _copyThreadContentFromWorkbench(
                    context,
                    ref,
                    widget.itemReference,
                  ); // Pass the whole reference
                },
              ),
              // --- End Copy Full Thread Action ---
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

    // Wrap the entire tile content (Container with Row) in a Column
    // to add a Divider below it.
    return Column(
      mainAxisSize: MainAxisSize.min, // Take minimum vertical space
      children: [
        Container(
          // Add horizontal padding to the outer container to indent the whole row slightly
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          // Adjust margin: Add bottom margin for space above the divider
          margin: const EdgeInsets.only(top: 6, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align handle to top
            children: [
              // Drag Handle
              Padding(
                padding: const EdgeInsets.only(top: 12.0, right: 6.0),
                child: ReorderableDragStartListener(
                  index: widget.index,
                  key: ValueKey('drag-handle-${widget.itemReference.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 4.0,
                    ),
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
                                          color: CupertinoColors.label
                                              .resolveFrom(context),
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
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (!isCommentItem) const SizedBox(height: 8),

                                // Comment Previews
                                // Always show comment previews, even if the main item is a comment itself (shows siblings/parent?)
                                // Let's adjust this: Only show comment previews if the main item is NOT a comment.
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
                                  )
                                // If the main item IS a comment, maybe show its content here instead?
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4.0,
                                      right: 4.0,
                                      top:
                                          4.0, // Add some top padding if it's a comment
                                    ),
                                    child: _buildSingleCommentPreview(
                                      context,
                                      ref,
                                      widget.itemReference,
                                      // Create a dummy comment object from the reference for display
                                      // This assumes previewContent holds the comment text
                                      Comment(
                                        id:
                                            widget
                                                .itemReference
                                                .referencedItemId,
                                        content:
                                            widget.itemReference.previewContent,
                                        createdTs:
                                            widget
                                                .itemReference
                                                .referencedItemUpdateTime ??
                                            widget
                                                .itemReference
                                                .addedTimestamp, // Approximate time
                                        parentId:
                                            widget.itemReference.parentNoteId ??
                                            '',
                                        serverId: widget.itemReference.serverId,
                                      ),
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
                                  color: CupertinoColors.systemGrey5
                                      .resolveFrom(context),
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
        ), // End of main content Container
        // Add a subtle divider below the content
        Padding(
          // Add horizontal padding to match content indentation
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: 0.5, // Very thin divider
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ], // End of outer Column
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
      // Don't show "No comments yet" if the main item isn't a comment itself
      // This section is only called when itemRef.referencedItemType != WorkbenchItemType.comment
      return const SizedBox.shrink();
      // return _buildSingleCommentPreview(context, ref, itemRef, null); // Old logic
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
    WorkbenchItemReference itemRef, // The workbench item reference
    Comment? comment, // The actual comment data (or null if placeholder)
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
    String commentIdToShow = ''; // ID to use for navigation highlight

    if (comment == null) {
      // This case should ideally not be reached if called from _buildCommentPreviews
      // If called because the main item is a comment, 'comment' will be non-null (dummy)
      contentWidget = Text('No comments yet.', style: italicStyle);
    } else {
      // Use comment data if available, otherwise fallback to workbench item data
      final displayContent = comment.content ?? itemRef.previewContent ?? '';
      // Use comment timestamp if available, fallback to workbench item update/add time
      DateTime commentTime =
          comment.createdTs ??
          itemRef.referencedItemUpdateTime ??
          itemRef.addedTimestamp;
      relativeTime = _formatRelativeTime(commentTime.toLocal());
      commentIdToShow = comment.id; // Use the actual comment ID

      contentWidget = Row(
         crossAxisAlignment: CrossAxisAlignment.end, // Align time to bottom
         children: [
           Expanded(
             child: Text(
              displayContent,
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

    // Make the comment preview tappable only if it represents a real comment
    // (either from previewComments or if the main item is a comment)
    final bool isTappable = comment != null;

    return GestureDetector(
      onTap:
          !isTappable
              ? null
              : () {
                // Navigate to parent item, highlighting this specific comment
                final activeServer = ref.read(activeServerConfigProvider);
                final isOnActiveServer = activeServer?.id == itemRef.serverId;
                if (isOnActiveServer) {
                  _navigateToItem(
                    context,
                    ref,
                    itemRef, // Pass the original workbench reference
                    commentIdToHighlight:
                        commentIdToShow, // Highlight the specific comment ID
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

  // Helper for actual navigation (Moved inside the State class)
  Future<void> _navigateToItem(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference itemRef,
  {
    String? commentIdToHighlight,
  }
  ) async {
    final String referencedItemId = itemRef.referencedItemId;
    final bool isRootNav = Navigator.of(context).canPop() == false;

    // Determine the actual item ID to navigate to (parent for comments)
    String targetItemId = referencedItemId;
    // If the workbench item *is* a comment, the target is its parent
    if (itemRef.referencedItemType == WorkbenchItemType.comment) {
      // We need the parent ID. Assume it's stored in parentNoteId for now.
      // TODO: This needs to be more robust if comments can belong to Tasks.
      targetItemId = itemRef.parentNoteId ?? '';
      // If navigating *from* a comment workbench item, highlight that comment ID
      commentIdToHighlight ??= referencedItemId;
    }

    if (targetItemId.isEmpty) {
      _showErrorDialog(
        context,
        'Cannot navigate: Target item ID is missing or could not be determined.',
      );
      return;
    }


    final Map<String, dynamic> arguments = {
      'itemId': targetItemId, // Navigate to the parent item
      // Pass the specific comment ID to highlight (could be the original item ID or from preview)
      if (commentIdToHighlight != null) 'commentIdToHighlight': commentIdToHighlight,
    };

    // Determine navigation target based on the *parent* item type
    // We need to know the parent type if the workbench item is a comment.
    // Assumption: Comments currently only come from Notes.
    // TODO: Make this dynamic based on parent type if Tasks support comments in workbench.
    final WorkbenchItemType effectiveNavigationType =
        (itemRef.referencedItemType == WorkbenchItemType.comment)
            ? WorkbenchItemType
                .note // Assume parent is Note
            : itemRef.referencedItemType;

    switch (effectiveNavigationType) {
      case WorkbenchItemType.note:
        Navigator.of(context, rootNavigator: isRootNav).pushNamed(
          '/item-detail', // Navigate to Note detail screen
          arguments: arguments,
        );
        break;
      case WorkbenchItemType.task:
        try {
          // Fetch the task details using the targetItemId (which is the task ID)
          final task = await ref.read(taskDetailProvider(targetItemId).future);
          if (mounted) {
            // Navigate to the task detail/edit screen
            // TODO: Create a dedicated Task Detail Screen? For now, using NewTaskScreen.
            Navigator.of(context, rootNavigator: isRootNav).push(
              CupertinoPageRoute(
                builder: (context) => NewTaskScreen(taskToEdit: task),
                // Pass commentIdToHighlight if Task screen supports it
                // settings: RouteSettings(arguments: arguments),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            _showErrorDialog(context, 'Failed to load task details: $e');
          }
        }
        break;
      case WorkbenchItemType.comment:
        // This case should not be reached due to effectiveNavigationType logic
        _showErrorDialog(
          context,
          'Internal navigation error: Unexpected item type.',
        );
        break;
    }
  }

  // Helper to show error dialog (Moved inside the State class)
  void _showErrorDialog(BuildContext context, String message) {
    if (!mounted) return;
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

  // Server Switch Dialog (Moved inside the State class)
  void _showServerSwitchRequiredDialog(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference itemRef,
  ) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Server Switch Required'),
            content: Text(
              'This item is on server "${itemRef.serverName ?? itemRef.serverId}". Switch to this server to interact with the item?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Switch Server'), // Changed text slightly
                onPressed: () async {
                  Navigator.pop(dialogContext); // Close this dialog first
                  // Show loading indicator while switching
                  showCupertinoDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (loadingCtx) => const CupertinoAlertDialog(
                          content: Row(
                            children: [
                              CupertinoActivityIndicator(),
                              SizedBox(width: 15),
                              Text('Switching server...'),
                            ],
                          ),
                        ),
                  );

                  ref
                      .read(multiServerConfigProvider.notifier)
                      .setActiveServer(itemRef.serverId);

                  // Wait for the activeServerConfigProvider to reflect the change
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

                  // Use ref.listenManual for better control over subscription lifecycle
                  sub = ref.listenManual<ServerConfig?>(
                    activeServerConfigProvider,
                    listener,
                    onError: errorHandler,
                    fireImmediately: true, // Check current state immediately
                  );


                  try {
                    // Wait for switch completion or timeout
                    await completer.future.timeout(const Duration(seconds: 5));
                    if (mounted) {
                      Navigator.pop(context); // Dismiss loading dialog
                      _showAlertDialog(
                        context,
                        'Success',
                        'Switched to server "${itemRef.serverName ?? itemRef.serverId}". You can now interact with the item.',
                      );
                      // Optionally auto-trigger the original action (e.g., view details) here
                      // _navigateToItem(context, ref, itemRef, commentIdToHighlight: null);
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context); // Dismiss loading dialog
                      _showAlertDialog(
                        context,
                        'Error',
                        'Failed to switch server or timed out. Please try switching manually from Settings.',
                      );
                    }
                  } finally {
                    // Ensure subscription is closed if it wasn't already
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
