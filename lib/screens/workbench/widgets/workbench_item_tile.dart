import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CupertinoTheme.of(context);
    final preview = itemReference.previewContent ?? 'No preview available';
    final serverDisplayName = itemReference.serverName ?? itemReference.serverId;
    // Format date more concisely
    final formattedDate = DateFormat.yMd().add_jm().format(itemReference.addedTimestamp.toLocal());

    return CupertinoListTile(
      leadingSize: 24, // Adjust leading icon size
      leading: Icon(
        _getItemTypeIcon(itemReference.referencedItemType),
        color: theme.primaryColor,
        size: 22, // Match leadingSize approximately
      ),
      title: Text(
        preview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
      ),
      subtitle: Text(
        'Server: $serverDisplayName • Added: $formattedDate',
        style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getServerTypeIcon(itemReference.serverType),
            size: 18,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.all(4.0),
            minSize: 0,
            child: const Icon(CupertinoIcons.clear_circled, size: 20, color: CupertinoColors.systemGrey),
            onPressed: () {
              // Show confirmation dialog before removing
              showCupertinoDialog(
                context: context,
                builder: (dialogContext) => CupertinoAlertDialog(
                  title: const Text('Remove from Workbench?'),
                  content: Text('Remove "${preview.substring(0, preview.length > 30 ? 30 : preview.length)}..." from your Workbench?'),
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
                        ref.read(workbenchProvider.notifier).removeItem(itemReference.id);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      onTap: () {
        // --- Mark Item Opened FIRST ---
        ref.read(workbenchProvider.notifier).markItemOpened(itemReference.id);
        // --- End Mark Item Opened ---

        // --- Navigation Logic ---
        final currentActiveServerId = ref.read(multiServerConfigProvider).activeServerId;

        if (itemReference.serverId == currentActiveServerId) {
          // Navigate directly
          _navigateToItem(context, ref, itemReference);
        } else {
          // Needs server switch
          _showServerSwitchRequiredDialog(context, ref, itemReference);
        }
      },
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
        // TODO: Need parent note ID to navigate correctly.
        // For now, maybe just navigate to the note detail screen without highlighting.
        // Or show a message "Comment navigation not fully supported yet".
         // Attempt navigation assuming referencedItemId might be the note ID for now
         // This needs refinement based on how comment references are stored/handled.
         // A better approach might be to store parentNoteId in the reference.
         /*
         Navigator.of(context, rootNavigator: true).pushNamed(
           '/item-detail',
           arguments: {
             'itemId': parentNoteId, // Need parentNoteId here
             'commentIdToHighlight': itemRef.referencedItemId
           },
         );
         */
         // Placeholder: Show alert
         showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(
           title: const Text('Navigation Incomplete'),
           content: const Text('Navigation to specific comments from the Workbench is not yet fully implemented.'),
           actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.pop(ctx))],
         ));
        break;
    }
  }

  // Placeholder dialog for server switch requirement
  void _showServerSwitchRequiredDialog(BuildContext context, WidgetRef ref, WorkbenchItemReference itemRef) {
     showCupertinoDialog(
       context: context,
       builder: (dialogContext) => CupertinoAlertDialog(
         title: const Text('Server Switch Required'),
         content: Text('This item is on server "${itemRef.serverName ?? itemRef.serverId}". Switch to this server to view the item?'),
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
                  // --- Actual Switch Logic (Needs Refinement) ---
               ref.read(multiServerConfigProvider.notifier).setActiveServer(itemRef.serverId);
               // FIXME: This delay is NOT robust. Need a better way to wait for state propagation.
               // Consider listening to activeServerConfigProvider or using a FutureProvider
               // that resolves when the API service is ready for the target server.
                  await Future.delayed(const Duration(milliseconds: 500));
               if (context.mounted) { // Check if context is still valid after delay
                 _navigateToItem(context, ref, itemRef);
               }
               // --- End Switch Logic ---
             },
           ),
         ],
       ),
     );
  }
}
