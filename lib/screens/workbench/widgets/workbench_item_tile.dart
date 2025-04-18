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

    // Remove watching activeWorkbenchItemIdProvider as highlight is removed
    // final activeItemId = ref.watch(activeWorkbenchItemIdProvider);
    // final isActive = activeItemId == itemReference.id;

    // Default background color (no active highlight)
    final tileColor = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
      context,
    );

    // Remove the outer GestureDetector for long-press
    // GestureDetector( ... onLongPress: ... )
    return Container(
      // Apply bubble styling
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: tileColor, // Use the default color
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
          // Main content column - Wrap this Expanded in a GestureDetector for onTap navigation
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Clear any active comment highlight when navigating
                ref.read(activeCommentIdProvider.notifier).state = null;
                onTap(); // Call original onTap for navigation etc.
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
          // Add Ellipsis Button for item actions
          // Remove the Padding widget wrapping the CupertinoButton
          // Padding(
          //   padding: const EdgeInsets.only(left: 8.0, top: -8.0, right: -8.0), // Adjust padding to position top-right
          //   child: CupertinoButton(
          //     padding: EdgeInsets.zero,
          //     minSize: 30, // Ensure tappable area
          //     onPressed: () => _showItemActions(context, ref, itemReference),
          //     child: const Icon(
          //       CupertinoIcons.ellipsis_vertical,
          //       size: 22,
          //       color: CupertinoColors.secondaryLabel,
          //     ),
          //   ),
          // ),
          // Place the CupertinoButton directly
          CupertinoButton(
            padding: const EdgeInsets.only(
              left: 8.0,
            ), // Adjust left padding as needed, remove negative top/right
            minSize: 30, // Ensure tappable area
            onPressed: () => _showItemActions(context, ref, itemReference),
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

    // Remove watching activeCommentIdProvider as highlight is removed
    // final activeCommentId = ref.watch(activeCommentIdProvider);
    // final isCommentActive = activeCommentId == comment.id;

    // Default background color (no active highlight)
    final bubbleColor = CupertinoColors.systemGrey6.resolveFrom(
      context,
    );

    // Wrap in Padding for top margin between comments
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      // Remove the GestureDetector wrapping the comment bubble
      // GestureDetector( ... onTap: ... onLongPress: ... )
      child: Container(
        decoration: BoxDecoration(
          color: bubbleColor, // Use the default color
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
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
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
                // Add Ellipsis Button for comment actions
                // Remove the Padding widget wrapping the CupertinoButton
                // Padding(
                //   padding: const EdgeInsets.only(left: 8.0, top: -4.0, bottom: -4.0), // Adjust padding
                //   child: CupertinoButton(
                //     padding: EdgeInsets.zero,
                //     minSize: 24, // Smaller tappable area for comment button
                //     onPressed: () => _showCommentPreviewActions(context, ref, comment),
                //     child: const Icon(
                //       CupertinoIcons.ellipsis_vertical,
                //       size: 18, // Smaller icon for comment
                //       color: CupertinoColors.tertiaryLabel,
                //     ),
                //   ),
                // ),
                // Place the CupertinoButton directly
                CupertinoButton(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                  ), // Adjust left padding as needed, remove negative top/bottom
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
            const SizedBox(height: 4),
            // Timestamp
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                commentTime,
                style: theme.textTheme.textStyle.copyWith(
                  fontSize: 12,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ],
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
