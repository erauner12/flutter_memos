import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/workbench_instance.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/models/workbench_item_type.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return '${difference.inSeconds}s ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class WorkbenchItemTile extends ConsumerWidget {
  final WorkbenchItemReference itemReference;
  final VoidCallback onTap;
  // Add index back - needed for ReorderableDragStartListener
  final int index;

  const WorkbenchItemTile({
    super.key,
    required this.itemReference,
    required this.onTap,
    required this.index, // Make index required again
  });

  void _showItemActions(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference item,
    VoidCallback originalOnTap,
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
            Navigator.pop(context);
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
              CupertinoActionSheetAction(
                child: const Text('Open Item'),
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(activeCommentIdProvider.notifier).state = null;
                  ref.read(selectedWorkbenchItemIdProvider.notifier).state =
                      null;
                  ref.read(selectedWorkbenchCommentIdProvider.notifier).state =
                      null;
                  originalOnTap();
                },
              ),
              ...moveActions,
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Remove from Workbench'),
                onPressed: () {
                  Navigator.pop(context);
                  ref
                      .read(workbenchProviderFamily(item.instanceId).notifier)
                      .removeItem(item.id);
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
                      Navigator.pop(context);
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

    final selectedItemId = ref.watch(selectedWorkbenchItemIdProvider);
    final isSelected = selectedItemId == itemReference.id;

    final tileColor =
        isSelected
            ? CupertinoColors.systemGrey5.resolveFrom(context)
            : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              itemReference.referencedItemType.icon,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                final notifier = ref.read(
                  selectedWorkbenchItemIdProvider.notifier,
                );
                if (isSelected) {
                  notifier.state = null;
                } else {
                  notifier.state = itemReference.id;
                  ref.read(selectedWorkbenchCommentIdProvider.notifier).state =
                      null;
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  if (itemReference.previewContent != null &&
                      itemReference.previewContent!.isNotEmpty)
                    Text(
                      itemReference.previewContent!,
                      style: theme.textTheme.textStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
          // Action Buttons Column (Ellipsis and Drag Handle)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.only(left: 8.0,
                  bottom: 4.0),
                minSize: 30,
                onPressed:
                    () => _showItemActions(context, ref, itemReference, onTap),
                child: const Icon(
                  CupertinoIcons.ellipsis_vertical,
                  size: 22,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: CupertinoButton(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  minSize: 30,
                  onPressed: () {},
                  child: const Icon(
                    CupertinoIcons.line_horizontal_3,
                    size: 22,
                    color: CupertinoColors.tertiaryLabel,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentPreview(
    BuildContext context,
    WidgetRef ref,
    Comment comment,
  ) {
    final theme = CupertinoTheme.of(context);
    final commentTime = formatRelativeTime(
      comment.updatedTs ?? comment.createdTs,
    );

    final selectedCommentId = ref.watch(selectedWorkbenchCommentIdProvider);
    final isCommentSelected = selectedCommentId == comment.id;

    final bubbleColor =
        isCommentSelected
            ? CupertinoColors.systemGrey5.resolveFrom(context)
            : CupertinoColors.systemGrey6.resolveFrom(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final notifier = ref.read(
                  selectedWorkbenchCommentIdProvider.notifier,
                );
                if (isCommentSelected) {
                  notifier.state = null;
                } else {
                  notifier.state = comment.id;
                  ref.read(selectedWorkbenchItemIdProvider.notifier).state =
                      null;
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                    const SizedBox(height: 4),
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
          CupertinoButton(
            padding: const EdgeInsets.only(left: 8.0, top: 8.0),
            minSize: 24,
            onPressed: () => _showCommentPreviewActions(context, ref, comment),
            child: const Icon(
              CupertinoIcons.ellipsis_vertical,
              size: 18,
              color: CupertinoColors.tertiaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentPreviewActions(
    BuildContext context,
    WidgetRef ref,
    Comment comment,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(
              comment.content ?? 'Comment Actions',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              CupertinoActionSheetAction(
                child: const Text('Edit'),
                onPressed: () {
                  Navigator.pop(context);
                  print(
                    'Edit action for comment ${comment.id} (Not Implemented)',
                  );
                },
              ),
              CupertinoActionSheetAction(
                child: Text(comment.pinned ? 'Unpin' : 'Pin'),
                onPressed: () {
                  Navigator.pop(context);
                  print(
                    'Pin/Unpin action for comment ${comment.id} (Not Implemented)',
                  );
                },
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () {
                  Navigator.pop(context);
                  print(
                    'Delete action for comment ${comment.id} (Not Implemented)',
                  );
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
