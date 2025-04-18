import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/workbench_instance.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/models/workbench_item_type.dart'; // Import the enum and extension
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

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showItemActions(context, ref, itemReference),
      behavior: HitTestBehavior.opaque, // Ensure whole area is tappable
      child: Container(
        // Apply bubble styling
        padding: const EdgeInsets.all(16.0), // Increased internal padding
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ), // Bubble background
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
                      (comment) => _buildCommentPreview(context, comment),
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

  Widget _buildCommentPreview(BuildContext context, Comment comment) {
    final theme = CupertinoTheme.of(context);
    final commentTime = formatRelativeTime(
      comment.updatedTs ?? comment.createdTs,
    );
    // Wrap in Padding for indentation and Container for left border
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 16.0), // Indent left
      child: Container(
        padding: const EdgeInsets.only(left: 8.0), // Padding inside the border
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 2.0,
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              // Add padding around icon
              padding: const EdgeInsets.only(top: 2.0),
              child: Icon(
                CupertinoIcons.bubble_left,
                size: 14,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                comment.content ?? '',
                style: theme.textTheme.textStyle.copyWith(
                  // Use captionTextStyle
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              commentTime,
              style: theme.textTheme.textStyle.copyWith(
                // Use captionTextStyle
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
