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

    // Watch the active item ID provider
    final activeItemId = ref.watch(activeWorkbenchItemIdProvider);
    final isActive = activeItemId == itemReference.id;

    // Determine background color based on active state
    final tileColor =
        isActive
            ? CupertinoColors.systemGrey5.resolveFrom(
              context,
            ) // Highlight color
            : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            ); // Default bubble background

    return GestureDetector(
      onTap: () {
        // Set this item as active when tapped
        // Optionally, toggle: if (isActive) { ref.read(activeWorkbenchItemIdProvider.notifier).state = null; } else { ... }
        ref.read(activeWorkbenchItemIdProvider.notifier).state =
            itemReference.id;
        // Also clear active comment when tapping parent item
        ref.read(activeCommentIdProvider.notifier).state = null;
        onTap(); // Call original onTap for navigation etc.
      },
      onLongPress: () => _showItemActions(context, ref, itemReference),
      behavior: HitTestBehavior.opaque, // Ensure whole area is tappable
      child: Container(
        // Apply bubble styling with conditional color
        padding: const EdgeInsets.all(16.0), // Increased internal padding
        decoration: BoxDecoration(
          color: tileColor, // Use the determined color
          borderRadius: BorderRadius.circular(8.0), // Rounded corners
        ),
        // Removed color: theme.barBackgroundColor
        // padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Replaced by EdgeInsets.all(16.0)
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon based on type - Use the extension getter .icon
            Padding(
              padding: const EdgeInsets.only(top: 2.0), // Align icon slightly
              child: Icon(
                itemReference
                    .referencedItemType
                    .icon, // Use the extension getter
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Main content column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Server Name / Item Type Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        // Allow server name to take space but truncate
                        child: Text(
                          itemReference.serverName ?? 'Unknown Server',
                          style: theme.textTheme.textStyle.copyWith(
                            // Use captionTextStyle
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8), // Add spacing
                      Text(
                        relativeTime, // Show relative time
                        style: theme.textTheme.textStyle.copyWith(
                          // Use captionTextStyle
                          color: CupertinoColors.tertiaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Preview Content
                  if (itemReference.previewContent != null &&
                      itemReference.previewContent!.isNotEmpty)
                    Text(
                      itemReference.previewContent!,
                      style: theme.textTheme.textStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  // Preview Comments
                  if (itemReference.previewComments.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...itemReference.previewComments.map(
                      // Pass ref down to the comment preview builder
                      (comment) => _buildCommentPreview(context, ref, comment),
                    ),
                  ],
                ],
              ),
            ),
            // Reorder handle (conditionally shown or removed)
            // Removed ReorderableDragStartListener as reordering is disabled
            // Padding(
            //   padding: const EdgeInsets.only(left: 12.0, top: 0),
            //   child: ReorderableDragStartListener(
            //     index: index,
            //     child: const Icon(
            //       CupertinoIcons.bars,
            //       color: CupertinoColors.tertiaryLabel,
            //       size: 20,
            //     ),
            //   ),
            // ),
          ],
        ),
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

    // Watch the active comment ID provider
    final activeCommentId = ref.watch(activeCommentIdProvider);
    final isCommentActive = activeCommentId == comment.id;

    // Determine background color based on active state
    final bubbleColor =
        isCommentActive
            ? CupertinoColors.systemGrey5.resolveFrom(
              context,
            ) // Highlight color
            : CupertinoColors.systemGrey6.resolveFrom(
              context,
            ); // Default bubble background

    // Wrap in Padding for top margin between comments
    return Padding(
      padding: const EdgeInsets.only(top: 8.0), // Increased top margin
      // Wrap the comment bubble in GestureDetector for interaction
      child: GestureDetector(
        onTap: () {
          // Set this comment as active when tapped
          ref.read(activeCommentIdProvider.notifier).state = comment.id;
          // Also clear active parent item when tapping a comment
          ref.read(activeWorkbenchItemIdProvider.notifier).state = null;
        },
        onLongPress: () {
          // Show comment-specific actions
          _showCommentPreviewActions(context, ref, comment);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          // Add horizontal margin if needed, or rely on parent padding
          // margin: const EdgeInsets.symmetric(horizontal: 16.0), // Optional horizontal margin
          decoration: BoxDecoration(
            color: bubbleColor, // Use the determined color
            borderRadius: BorderRadius.circular(8.0), // Rounded corners
          ),
          padding: const EdgeInsets.all(
            12.0,
          ), // Internal padding for the bubble
          // Removed the old Container with left border and its padding
          // child: Container( ... decoration: BoxDecoration(border: Border(left...)) ... )
          child: Column(
            // Use Column for better layout control inside bubble
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                // Row for icon and text content
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    // Keep icon padding consistent
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Icon(
                      CupertinoIcons.bubble_left, // Keep comment icon
                      size: 16, // Adjusted size for bubble context
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(width: 8), // Space between icon and text
                  Expanded(
                    child: Text(
                      comment.content ?? '',
                      style: theme.textTheme.textStyle.copyWith(
                        fontSize: 14, // Slightly larger font for preview bubble
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                      maxLines: 2, // Allow more lines in bubble
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4), // Space between text and timestamp
              Align(
                // Align timestamp to the right or keep left
                alignment: Alignment.centerRight, // Example: align right
                child: Text(
                  commentTime,
                  style: theme.textTheme.textStyle.copyWith(
                    fontSize: 12, // Smaller font for timestamp
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(
              comment.content ?? 'Comment Actions',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            message: const Text('Actions for this comment preview.'),
            actions: [
              CupertinoActionSheetAction(
                child: const Text('Edit (Not Implemented)'),
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to edit screen with comment context
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Pin (Not Implemented)'),
                onPressed: () {
                  Navigator.pop((context));
                  // Call pin/unpin logic
                },
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Delete (Not Implemented)'),
                onPressed: () {
                  Navigator.pop(context);
                  // Call delete logic
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
