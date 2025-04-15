import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/server_config_provider.dart'; // &lt;-- Add this import for activeServerConfigProvider and multiServerConfigProvider
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting

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
    }
  }

  // Helper to get icon based on server type
  IconData _getServerTypeIcon(ServerType type) {
    switch (type) {
      case ServerType.memos:
        return CupertinoIcons.bolt_horizontal_circle_fill; // Example icon
      case ServerType.blinko:
        return CupertinoIcons.sparkles; // Example icon
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
      return DateFormat.yMd().format(dateTime);
    }
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

    // Get the current active serverId
    final activeServer = ref.watch(activeServerConfigProvider);
    final isOnActiveServer = activeServer?.id == itemReference.serverId;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isOnActiveServer) {
          _navigateToItem(context, ref, itemReference);
        } else {
          _showServerSwitchRequiredDialog(context, ref, itemReference);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withAlpha((0.04 * 255).toInt()),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                    size: 24,
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Server: $serverDisplayName • Added: $addedRelative',
                        style: TextStyle(
                          fontSize: 12.5,
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
                          fontSize: 12.5,
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
                // Trailing actions
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      _getServerTypeIcon(itemReference.serverType),
                      size: 18,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                    const SizedBox(height: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.all(4.0),
                      minSize: 0,
                      child: const Icon(
                        CupertinoIcons.clear_circled,
                        size: 20,
                        color: CupertinoColors.systemGrey,
                      ),
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
                                    onPressed:
                                        () => Navigator.pop(dialogContext),
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
                ),
              ],
            ),
            // Threaded comment preview
            _buildCommentPreview(context, itemReference.latestComment),
          ],
        ),
      ),
    );
  }

  // Add helper widget for comment preview
  Widget _buildCommentPreview(BuildContext context, Comment? comment) {
    final textStyle = TextStyle(
      fontSize: 13.5,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );
    final italicStyle = textStyle.copyWith(fontStyle: FontStyle.italic);

    // If no comment and the item is a comment itself, show nothing
    if (comment == null) {
      if (itemReference.referencedItemType == WorkbenchItemType.comment) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.only(left: 18, top: 8, bottom: 8, right: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          border: Border(
            left: BorderSide(
              color: CupertinoColors.systemGrey4.resolveFrom(context),
              width: 3,
            ),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('No comments yet.', style: italicStyle),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.only(left: 18, top: 8, bottom: 8, right: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        border: Border(
          left: BorderSide(
            color: CupertinoColors.systemGrey4.resolveFrom(context),
            width: 3,
          ),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        comment.content,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: textStyle.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }

  // Helper for actual navigation (call AFTER server switch if needed)
  void _navigateToItem(
    BuildContext context,
    WidgetRef ref,
    WorkbenchItemReference itemRef,
  ) {
    switch (itemRef.referencedItemType) {
      case WorkbenchItemType.note:
        Navigator.of(context, rootNavigator: true).pushNamed(
          '/item-detail',
          arguments: {'itemId': itemRef.referencedItemId},
        );
        break;
      case WorkbenchItemType.comment:
        // Navigate to the parent note, potentially highlighting the comment
        final parentId =
            itemRef.parentNoteId ??
            itemRef.referencedItemId; // Fallback if parentId is missing
        if (parentId.isNotEmpty) {
          Navigator.of(context, rootNavigator: true).pushNamed(
            '/item-detail',
            arguments: {
              'itemId': parentId,
              'commentIdToHighlight':
                  itemRef.referencedItemId, // Pass comment ID for highlighting
            },
          );
        } else {
          // Show alert if navigation is not possible
          showCupertinoDialog(
            context: context,
            builder:
                (ctx) => CupertinoAlertDialog(
                  title: const Text('Navigation Error'),
                  content: const Text(
                    'Cannot navigate to comment: Parent note ID is missing.',
                  ),
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
        break;
    }
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
                  // --- Actual Switch Logic ---
                  ref
                      .read(multiServerConfigProvider.notifier)
                      .setActiveServer(itemRef.serverId);
                  final completer = Completer<void>();
                  ProviderSubscription<ServerConfig?>? sub;
                  ref.listen<ServerConfig?>(
                    activeServerConfigProvider,
                    (prev, next, subscription) {
                          sub = subscription;
                          if (next?.id == itemRef.serverId &&
                              !completer.isCompleted) {
                            completer.complete();
                          }
                        }
                        as void Function(
                          ServerConfig? previous,
                          ServerConfig? next,
                        ),
                  );
                  try {
                    await completer.future.timeout(const Duration(seconds: 3));
                    if (context.mounted) {
                      _navigateToItem(context, ref, itemRef);
                    }
                  } catch (e) {
                    // Optionally show an error message to the user
                  } finally {
                    sub?.close();
                  }
                  // --- End Switch Logic ---
                },
              ),
            ],
          ),
    );
  }
}
