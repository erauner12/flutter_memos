import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/workbench_instance.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/models/workbench_item_type.dart'; // Import the enum and extension
import 'package:flutter_memos/providers/ui_providers.dart'; // Import UI providers
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
// import 'package:flutter_memos/utils/time_utils.dart'; // For relative time formatting // TODO: Implement this utility
import 'package:flutter_riverpod/flutter_riverpod.dart';

String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return '${difference.inSeconds}s ago'; // Shorter format
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago'; // Shorter format
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago'; // Shorter format
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago'; // Shorter format
  } else {
    // Consider using intl package for better date formatting
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class WorkbenchItemTile extends ConsumerWidget {
  final WorkbenchItemReference itemReference;
  final VoidCallback onTap;
  // Removed index as it's not needed without reordering enabled via this tile's handle
  // final int index;

  const WorkbenchItemTile({
    super.key,
    required this.itemReference,
    required this.onTap,
    // required this.index,
  });

  // Helper to show move/delete actions
  void _showItemActions(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference item,
    VoidCallback originalOnTap, // Add original onTap for navigation
  ) {
    final instancesState = ref.read(workbenchInstancesProvider);
    final currentInstanceId = item.instanceId;
    final otherInstances =
        instancesState.instances
            .where((i) => i.id != currentInstanceId)
            .toList();

    List<CupertinoActionSheetAction> moveActions = [];
    if (otherInstances.isNotEmpty) {
      moveActions.add(
        CupertinoActionSheetAction(
          child: const Text('Move to...'),
          onPressed: () {
            Navigator.pop(context); // Close the first action sheet
            _showMoveDestinationSheet(context, ref, item, otherInstances);
          },
        ),
      );
    }

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(
              itemReference.previewContent ?? 'Item Actions',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              // Add Open Item action
              CupertinoActionSheetAction(
                child: const Text('Open Item'),
                onPressed: () {
                  Navigator.pop(context); // Close action sheet
                  // Clear any active comment highlight when navigating
                  ref.read(activeCommentIdProvider.notifier).state = null;
                  // Clear selection state when navigating
                  ref.read(selectedWorkbenchItemIdProvider.notifier).state =
                      null;
                  ref.read(selectedWorkbenchCommentIdProvider.notifier).state =
                      null;
                  originalOnTap(); // Execute the original navigation logic
                },
              ),
              ...moveActions, // Add move actions if available
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Remove from Workbench'),
                onPressed: () {
                  Navigator.pop(context); // Close action sheet
                  // Use the notifier for the specific instance the item belongs to
                  ref
                      .read(workbenchProviderFamily(item.instanceId).notifier)
                      .removeItem(item.id);
                  // Clear selection if the removed item was selected
                  if (ref.read(selectedWorkbenchItemIdProvider) == item.id) {
                    ref.read(selectedWorkbenchItemIdProvider.notifier).state =
                        null;
                  }
                },
              ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // Helper to show the list of destinations for moving an item
  void _showMoveDestinationSheet(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference itemToMove,
    List<WorkbenchInstance> destinations,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Move Item To'),
            actions:
                destinations.map((dest) {
                  return CupertinoActionSheetAction(
                    child: Text(dest.name),
                    onPressed: () {
                      Navigator.pop(context); // Close destination sheet
                      ref
                          .read(
                            workbenchProviderFamily(
                              itemToMove.instanceId,
                            ).notifier,
                          )
                          .moveItem(
                            itemId: itemToMove.id,
                            targetInstanceId: dest.id,
                          );
                    },
                  );
                }).toList(),
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CupertinoTheme.of(context);
    final relativeTime = formatRelativeTime(
      itemReference.overallLastUpdateTime,
    );

    // Watch the selection provider
    final selectedItemId = ref.watch(selectedWorkbenchItemIdProvider);
    final isSelected = selectedItemId == itemReference.id;

    // Determine background color based on selection
    final tileColor =
        isSelected
            ? CupertinoColors.systemGrey5.resolveFrom(
              context,
            ) // Highlight color
            : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context, // Default color
            );

    // Remove the outer GestureDetector for long-press
    // GestureDetector( ... onLongPress: ... )
    return Container(
      // Apply bubble styling
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: tileColor, // Use the determined color
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon based on type - remains the same
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              itemReference.referencedItemType.icon,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Main content column - Wrap this Expanded in a GestureDetector for SELECTION
          Expanded(
            child: GestureDetector(
              // onTap now handles SELECTION, not navigation
              onTap: () {
                // Update selection state
                final notifier = ref.read(
                  selectedWorkbenchItemIdProvider.notifier,
                );
                if (isSelected) {
                  notifier.state = null; // Toggle off if already selected
                } else {
                  notifier.state = itemReference.id; // Select this item
                  // Optionally clear comment selection when an item is selected
                  ref.read(selectedWorkbenchCommentIdProvider.notifier).state =
                      null;
                }
              },
              behavior: HitTestBehavior.opaque, // Make the content area tappable
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Server Name / Item Type Row - remains the same
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          itemReference.serverName ?? 'Unknown Server',
                          style: theme.textTheme.textStyle.copyWith(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        relativeTime,
                        style: theme.textTheme.textStyle.copyWith(
                          color: CupertinoColors.tertiaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Preview Content - remains the same
                  if (itemReference.previewContent != null &&
                      itemReference.previewContent!.isNotEmpty)
                    Text(
                      itemReference.previewContent!,
                      style: theme.textTheme.textStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  // Preview Comments - remains the same structure
                  if (itemReference.previewComments.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...itemReference.previewComments.map(
                      (comment) => _buildCommentPreview(context, ref, comment),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Ellipsis Button for item actions (including navigation now)
          CupertinoButton(
            padding: const EdgeInsets.only(
              left: 8.0,
            ), // Adjust left padding as needed, remove negative top/right
            minSize: 30, // Ensure tappable area
            // Pass the original onTap (for navigation) to the action handler
            onPressed:
                () => _showItemActions(context, ref, itemReference, onTap),
            child: const Icon(
              CupertinoIcons.ellipsis_vertical,
              size: 22,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  // Add WidgetRef ref parameter
  Widget _buildCommentPreview(
    BuildContext context,
    WidgetRef ref,
    Comment comment,
  ) {
    final theme = CupertinoTheme.of(context);
    final commentTime = formatRelativeTime(
      comment.updatedTs ?? comment.createdTs,
    );

    // Watch comment selection provider
    final selectedCommentId = ref.watch(selectedWorkbenchCommentIdProvider);
    final isCommentSelected = selectedCommentId == comment.id;

    // Determine background color based on selection
    final bubbleColor =
        isCommentSelected
            ? CupertinoColors.systemGrey5.resolveFrom(
              context,
            ) // Highlight color
            : CupertinoColors.systemGrey6.resolveFrom(context); // Default color

    // Wrap in Padding for top margin between comments
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      // Wrap the content Container in GestureDetector for SELECTION
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Update comment selection state
                final notifier = ref.read(
                  selectedWorkbenchCommentIdProvider.notifier,
                );
                if (isCommentSelected) {
                  notifier.state = null; // Toggle off
                } else {
                  notifier.state = comment.id; // Select this comment
                  // Optionally clear item selection when a comment is selected
                  ref.read(selectedWorkbenchItemIdProvider.notifier).state =
                      null;
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: bubbleColor, // Use the determined color
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Icon(
                            CupertinoIcons.bubble_left,
                            size: 16,
                            color: CupertinoColors.tertiaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Text Content
                        Expanded(
                          child: Text(
                            comment.content ?? '',
                            style: theme.textTheme.textStyle.copyWith(
                              fontSize: 14,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Ellipsis button is now outside the GestureDetector
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Timestamp
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        commentTime,
                        style: theme.textTheme.textStyle.copyWith(
                          fontSize: 12,
                          color: CupertinoColors.tertiaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Ellipsis Button for comment actions (outside the selection GestureDetector)
          CupertinoButton(
            padding: const EdgeInsets.only(
              left: 8.0,
              top: 8.0, // Add some top padding to align better
            ),
            minSize: 24, // Smaller tappable area for comment button
            onPressed: () => _showCommentPreviewActions(context, ref, comment),
            child: const Icon(
              CupertinoIcons.ellipsis_vertical,
              size: 18, // Smaller icon for comment
              color: CupertinoColors.tertiaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder for comment preview actions
  void _showCommentPreviewActions(
    BuildContext context,
    WidgetRef ref,
    Comment comment,
  ) {
    // TODO: Implement comment actions (reuse/adapt CommentCard logic?)
    // Needs serverId, parentId (memoId) etc. which might need to be passed down or accessed differently.
    // For now, just showing a basic sheet.
    // IMPORTANT: Need access to itemReference.serverId and itemReference.referencedItemId (as parentId)
    final parentId =
        itemReference.referencedItemId; // Assuming this is the memo/note ID
    final serverId = itemReference.serverId;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(
              comment.content ?? 'Comment Actions',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // message: const Text('Actions for this comment preview.'), // Optional message
            actions: [
              // Example: Edit Action (requires navigation setup)
              CupertinoActionSheetAction(
                child: const Text('Edit'), // Placeholder text
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to edit screen: Needs proper routing
                  // Example: ref.read(rootNavigatorKeyProvider).currentState?.pushNamed(...)
                  print(
                    'Edit action for comment ${comment.id} (Not Implemented)',
                  );
                },
              ),
              // Example: Pin Action (requires provider logic)
              CupertinoActionSheetAction(
                child: Text(
                  comment.pinned ? 'Unpin' : 'Pin',
                ), // Placeholder text
                onPressed: () {
                  Navigator.pop(context);
                  // Call pin/unpin logic: Needs provider setup similar to CommentCard
                  print(
                    'Pin/Unpin action for comment ${comment.id} (Not Implemented)',
                  );
                  // Example: ref.read(comment_providers.togglePinCommentProviderFamily(...))();
                },
              ),
              // Example: Delete Action (requires provider logic)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Delete'), // Placeholder text
                onPressed: () async {
                  Navigator.pop(context); // Close sheet first
                  // Confirmation Dialog recommended here
                  print(
                    'Delete action for comment ${comment.id} (Not Implemented)',
                  );
                  // Example: Call delete provider
                  // await ref.read(comment_providers.deleteCommentProviderFamily(...))();

                  // Clear selection if the deleted comment was selected
                  if (ref.read(selectedWorkbenchCommentIdProvider) ==
                      comment.id) {
                    ref
                        .read(selectedWorkbenchCommentIdProvider.notifier)
                        .state = null;
                  }
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
