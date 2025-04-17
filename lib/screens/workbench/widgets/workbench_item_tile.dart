import 'dart:async';
import 'dart:math'; // For min

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/services.dart'; // Needed for Clipboard
import 'package:flutter_memos/main.dart'; // For rootNavigatorKeyProvider
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_instance.dart'; // Import WorkbenchInstance
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart'; // Import instances provider
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/home_screen.dart'; // Import for NEW providers (homeTabControllerProvider)
import 'package:flutter_memos/screens/home_tabs.dart'; // Import HomeTab enum and SafeTabNav
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_memos/utils/thread_utils.dart'; // Import the utility
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Convert to ConsumerStatefulWidget for hover state
class WorkbenchItemTile extends ConsumerStatefulWidget {
  final WorkbenchItemReference itemReference;
  final int index;

  // onTap is required by ReorderableListView.builder's itemBuilder
  final VoidCallback onTap;

  const WorkbenchItemTile({
    super.key,
    required this.itemReference,
    required this.index,
    required this.onTap, // Make onTap required
  });

  @override
  ConsumerState<WorkbenchItemTile> createState() => _WorkbenchItemTileState();
}

class _WorkbenchItemTileState extends ConsumerState<WorkbenchItemTile> {
  bool _isHovering = false;
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

  // Helper to get icon based on server type
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

  // Helper to format relative time strings
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

  // Helper to show simple alert dialogs
  void _showAlertDialog(BuildContext context, String title, String message) {
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
      context: context, // Use state's context
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Remove from Workbench?'),
            content: Text(
              'Remove "${preview.substring(0, min(30, preview.length))}${preview.length > 30 ? '...' : ''}" from this Workbench?',
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
            .read(activeWorkbenchNotifierProvider) // Use active notifier
            .removeItem(widget.itemReference.id),
      );
    }
  }

  Future<void> _handleToggleComplete() async {
    if (widget.itemReference.referencedItemType != WorkbenchItemType.task) {
      return;
    }

    final activeServer = ref.read(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == widget.itemReference.serverId;
    if (!isOnActiveServer) {
      _showServerSwitchRequiredDialog(context, ref, widget.itemReference);
      return;
    }

    _showLoadingDialog(context, 'Updating task...'); // Show loading

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
      _dismissLoadingDialog(); // Dismiss loading
      if (success && mounted) {
        _showAlertDialog(context, 'Success', 'Task $actionVerb.');
        unawaited(
          ref
              .read(activeWorkbenchNotifierProvider)
              .refreshItemDetails(), // Use active notifier
        );
        unawaited(ref.read(tasksNotifierProvider.notifier).fetchTasks());
      } else if (!success && mounted) {
        _showAlertDialog(context, 'Error', 'Failed to toggle task status.');
      }
    } catch (e) {
      _dismissLoadingDialog(); // Dismiss loading on error
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
      _showServerSwitchRequiredDialog(buildContext, ref, itemRef);
      return;
    }

    _showLoadingDialog(buildContext, 'Fetching thread...');

    try {
      // Server is already confirmed to be active
      final content = await getFormattedThreadContent(
        ref,
        itemRef.referencedItemId,
        itemRef.referencedItemType,
        itemRef.serverId,
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

  // --- Chat With Thread Helper (Workbench) ---
  Future<void> _chatWithThreadFromWorkbench(
    BuildContext buildContext,
    WidgetRef ref,
    WorkbenchItemReference itemRef,
  ) async {
    final activeServer = ref.read(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == itemRef.serverId;

    if (!isOnActiveServer) {
      _showServerSwitchRequiredDialog(buildContext, ref, itemRef);
      return;
    }

    _showLoadingDialog(buildContext, 'Fetching thread for chat...');

    try {
      // Fetch the thread content
      final content = await getFormattedThreadContent(
        ref,
        itemRef.referencedItemId,
        itemRef.referencedItemType,
        itemRef.serverId,
      );

      _dismissLoadingDialog(); // Dismiss before navigation

      if (!mounted) return;

      // Prepare arguments for navigation
      final chatArgs = {
        'contextString': content,
        'parentItemId': itemRef.referencedItemId,
        'parentItemType': itemRef.referencedItemType,
        'parentServerId': itemRef.serverId,
      };

      // 1. Try to switch tab using the safe method
      // Read the homeTabControllerProvider (defined in home_screen.dart)
      final tabController = ref.read(homeTabControllerProvider);
      final tabIndexMap = ref.read(homeTabIndexMapProvider);
      // Get the total number of tabs (needed for safeSetIndex)
      final int maxTabs = tabIndexMap.length;

      // Use the safeSetIndex extension method
      tabController.safeSetIndex(HomeTab.chat, tabIndexMap, maxTabs);

      // Check if the index actually changed to the chat tab index
      final chatTabIndex = tabIndexMap[HomeTab.chat];
      if (chatTabIndex != null && tabController.index == chatTabIndex) {
        // Index successfully set (or was already correct)
        // Navigate within the Chat tab's navigator immediately (no animation delay needed)
        if (mounted) {
          _navigateToChatScreenWithinTab(buildContext, chatArgs);
        }
      } else {
        // Fallback: Chat tab doesn't exist or index is invalid, use root navigator
        if (kDebugMode) {
          print(
            '[WorkbenchItemTile] Chat tab not found or index invalid after attempting set. Navigating via root.',
          );
        }
        final rootNavigator = ref.read(rootNavigatorKeyProvider).currentState;
        if (rootNavigator != null && mounted) {
          rootNavigator.pushNamed('/chat', arguments: chatArgs);
        } else {
          _showAlertDialog(
            buildContext,
            'Error',
            'Could not navigate to chat.',
          );
        }
      }
    } catch (e) {
      _dismissLoadingDialog();
      if (mounted) {
        _showAlertDialog(buildContext, 'Error', 'Failed to start chat: $e');
      }
    }
  }

  // Helper to navigate within the Chat tab specifically
  void _navigateToChatScreenWithinTab(
    BuildContext buildContext,
    Map<String, dynamic> chatArgs,
  ) {
    final chatNavigator = chatTabNavKey.currentState;
    if (chatNavigator != null) {
      // Pop to root of chat tab first to avoid stacking chat screens
      chatNavigator.popUntil((route) => route.isFirst);
      // Push the chat screen with arguments using the tab's navigator
      chatNavigator.pushNamed('/chat', arguments: chatArgs);
    } else {
      // Fallback or error handling if navigator key is null
      _showAlertDialog(
        buildContext,
        'Error',
        'Could not navigate within chat tab.',
      );
      if (kDebugMode) {
        print("Error: chatTabNavKey.currentState is null");
      }
    }
  }
  // --- End Chat With Thread Helper (Workbench) ---


  void _navigateToEdit() {
    final activeServer = ref.read(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == widget.itemReference.serverId;
    if (!isOnActiveServer) {
      _showServerSwitchRequiredDialog(context, ref, widget.itemReference);
      return;
    }

    final itemRef = widget.itemReference;
    // Use root navigator if workbench is potentially nested deeply
    final bool isRootNav = true; // Assume root needed from workbench

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
        _showLoadingDialog(context, 'Loading task...');
        ref
            .read(taskDetailProvider(itemRef.referencedItemId).future)
            .then((task) {
              _dismissLoadingDialog();
              if (mounted) {
                Navigator.of(context, rootNavigator: isRootNav).push(
                  CupertinoPageRoute(
                    builder: (context) => NewTaskScreen(taskToEdit: task),
                  ),
                );
              }
            })
            .catchError((e) {
              _dismissLoadingDialog();
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

  // --- Move Item Sheet ---
  void _showMoveSheet(BuildContext context) {
    // Get all instances EXCEPT the current one
    final instances = ref.read(workbenchInstancesProvider).instances
        .where((i) => i.id != widget.itemReference.instanceId)
        .toList();

    // Don't show the sheet if there are no other workbenches to move to
    if (instances.isEmpty) {
      _showAlertDialog(
        context,
        'Move Item',
        'There are no other Workbenches to move this item to.',
      );
      return;
    }

    showCupertinoModalPopup<void>(
      context: context, // Use the context passed to this method
      builder: (BuildContext sheetContext) => CupertinoActionSheet(
        title: const Text('Move to Workbench'),
        actions: [
          // Create an action for each available target workbench
          for (final wb in instances)
            CupertinoActionSheetAction(
              child: Text(wb.name),
              onPressed: () {
                Navigator.pop(sheetContext); // Close the action sheet
                // Call the moveItem method on the *source* notifier
                ref
                  .read(activeWorkbenchNotifierProvider)
                  .moveItem(
                    itemId: widget.itemReference.id,
                    targetInstanceId: wb.id,
                  );
              },
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(sheetContext); // Close the action sheet
          },
        ),
      ),
    );
  }
  // --- End Move Item Sheet ---


  // --- Context Menu ---
  void _showContextMenu(BuildContext context) {
    final itemRef = widget.itemReference;
    final bool isTask = itemRef.referencedItemType == WorkbenchItemType.task;
    final bool isComment =
        itemRef.referencedItemType == WorkbenchItemType.comment;

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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: <Widget>[
              // View Details
              CupertinoActionSheetAction(
                child: const Text('View Details'),
                onPressed: () {
                  Navigator.pop(popupContext);
                  if (isOnActiveServer) {
                    _navigateToItem(
                      context, // Use the tile's context
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
                    _navigateToEdit(); // Checks for active server inside
                  },
                ),
              // Toggle Complete (Task only)
              if (isTask)
                CupertinoActionSheetAction(
                  child: const Text('Toggle Complete'),
                  onPressed: () {
                    Navigator.pop(popupContext);
                    _handleToggleComplete(); // Checks for active server inside
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
              // Copy Full Thread Action
              CupertinoActionSheetAction(
                child: const Text('Copy Full Thread'),
                onPressed: () {
                  Navigator.pop(popupContext);
                  _copyThreadContentFromWorkbench(
                    context, // Pass the tile's context
                    ref,
                    widget.itemReference,
                  ); // Checks for active server inside
                },
              ),
              // --- Chat about Thread Action ---
              CupertinoActionSheetAction(
                child: const Text('Chat about Thread'),
                onPressed: () {
                  Navigator.pop(popupContext);
                  _chatWithThreadFromWorkbench(
                    context, // Pass the tile's context
                    ref,
                    widget.itemReference,
                  ); // Checks for active server inside
                },
              ),
              // --- End Chat about Thread Action ---

              // --- Move to Workbench Action ---
              CupertinoActionSheetAction(
                child: const Text('Move to Workbench…'),
                onPressed: () {
                  Navigator.pop(popupContext); // Close this menu first
                  _showMoveSheet(context); // Show the move target selection sheet
                },
              ),
              // --- End Move to Workbench Action ---

              // Remove from Workbench
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Remove from Workbench'),
                onPressed: () {
                  Navigator.pop(popupContext);
                  _handleRemoveItem(); // Use refactored handler
                },
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
  // --- End Context Menu ---

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final preview =
        widget.itemReference.previewContent ?? 'No preview available';
    final serverDisplayName =
        widget.itemReference.serverName ?? widget.itemReference.serverId;
    final lastActivityRelative = _formatRelativeTime(
      widget.itemReference.overallLastUpdateTime.toLocal(),
    );

    final activeServer = ref.watch(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == widget.itemReference.serverId;

    final bool isTask =
        widget.itemReference.referencedItemType == WorkbenchItemType.task;
    final bool isCommentItem =
        widget.itemReference.referencedItemType == WorkbenchItemType.comment;

    // Define action buttons for the hover bar
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
      // Toggle Complete Action (only for tasks)
      if (isTask) ...[
        CupertinoButton(
          padding: const EdgeInsets.all(4),
          minSize: 0,
          onPressed: _handleToggleComplete, // Checks active server inside
          child: Icon(
            CupertinoIcons.check_mark_circled,
            size: 18,
            color: theme.primaryColor,
          ),
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
        ),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          margin: const EdgeInsets.only(top: 6, bottom: 6),
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

              // Main Content Area
              Expanded(
                child: GestureDetector(
                  onLongPress: () => _showContextMenu(context),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHovering = true),
                    onExit: (_) => setState(() => _isHovering = false),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Use the onTap passed from the parent (WorkbenchScreen)
                      onTap: widget.onTap,
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

                                // Preview Content (only if not a comment item)
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

                                // Comment Previews or Single Comment Content
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: 4.0,
                                    right: 4.0,
                                    top: isCommentItem ? 4.0 : 0,
                                  ),
                                  child: isCommentItem
                                      ? _buildSingleCommentPreview(
                                          context,
                                          ref,
                                          widget.itemReference,
                                          // Create a dummy comment object
                                          Comment(
                                            id: widget.itemReference.referencedItemId,
                                            content: widget.itemReference.previewContent,
                                            createdTs: widget.itemReference.referencedItemUpdateTime ?? 
                                                widget.itemReference.addedTimestamp,
                                            parentId: widget.itemReference.parentNoteId ?? '',
                                            serverId: widget.itemReference.serverId,
                                          ),
                                        )
                                      : _buildCommentPreviews(
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
        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: 0.5,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ],
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
      return const SizedBox.shrink(); // Don't show anything if no comments
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
    Comment? comment, // The actual comment data
  ) {
    // This should always be called with a non-null comment now
    if (comment == null) return const SizedBox.shrink();

    final textStyle = TextStyle(
      fontSize: 14,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
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

    final displayContent = comment.content ?? '';
    // Fix null safety handling - comment.createdTs can't be null
    DateTime commentTime = comment.createdTs;
    final relativeTime = _formatRelativeTime(commentTime.toLocal());
    final commentIdToShow = comment.id;

    Widget contentWidget = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            displayContent,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          relativeTime,
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () {
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: decoration,
        child: contentWidget,
      ),
    );
  }

  // Helper for actual navigation
  Future<void> _navigateToItem(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference itemRef,
  {
    String? commentIdToHighlight,
  }
  ) async {
    final String referencedItemId = itemRef.referencedItemId;
    // Use root navigator from workbench
    final bool isRootNav = true;

    // Determine the actual item ID to navigate to (parent for comments)
    String targetItemId = referencedItemId;
    WorkbenchItemType effectiveNavigationType = itemRef.referencedItemType;

    if (itemRef.referencedItemType == WorkbenchItemType.comment) {
      // We need the parent ID. Assume it's stored in parentNoteId for now.
      // TODO: This needs to be more robust if comments can belong to Tasks.
      targetItemId = itemRef.parentNoteId ?? '';
      // If navigating *from* a comment workbench item, highlight that comment ID
      commentIdToHighlight ??= referencedItemId;
      // Assume parent is Note for now
      // TODO: Make this dynamic based on parent type if Tasks support comments in workbench.
      effectiveNavigationType = WorkbenchItemType.note;
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
      if (commentIdToHighlight != null) 'commentIdToHighlight': commentIdToHighlight,
    };

    switch (effectiveNavigationType) {
      case WorkbenchItemType.note:
        Navigator.of(context, rootNavigator: isRootNav).pushNamed(
          '/item-detail', // Navigate to Note detail screen
          arguments: arguments,
        );
        break;
      case WorkbenchItemType.task:
        _showLoadingDialog(context, 'Loading task...');
        try {
          final task = await ref.read(taskDetailProvider(targetItemId).future);
          _dismissLoadingDialog();
          if (mounted) {
            Navigator.of(context, rootNavigator: isRootNav).push(
              CupertinoPageRoute(
                builder: (context) => NewTaskScreen(taskToEdit: task),
                // Pass commentIdToHighlight if Task screen supports it
                // settings: RouteSettings(arguments: arguments),
              ),
            );
          }
        } catch (e) {
          _dismissLoadingDialog();
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

  // Helper to show error dialog
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

  // Server Switch Dialog
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
                child: const Text('Switch Server'),
                onPressed: () async {
                  Navigator.pop(dialogContext); // Close this dialog first
                  _showLoadingDialog(context, 'Switching server...');

                  // Perform the switch
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
                  sub = ref.listenManual<ServerConfig?>(
                    activeServerConfigProvider,
                    listener,
                    onError: errorHandler,
                    fireImmediately: true,
                  );

                  try {
                    await completer.future.timeout(const Duration(seconds: 5));
                    _dismissLoadingDialog();
                    if (mounted) {
                      _showAlertDialog(
                        context,
                        'Success',
                        'Switched to server "${itemRef.serverName ?? itemRef.serverId}". You can now interact with the item.',
                      );
                      // Optionally auto-trigger the original action here if needed
                    }
                  } catch (e) {
                    _dismissLoadingDialog();
                    if (mounted) {
                      _showAlertDialog(
                        context,
                        'Error',
                        'Failed to switch server or timed out. Please try switching manually from Settings.',
                      );
                    }
                  } finally {
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