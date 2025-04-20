import 'package:flutter/cupertino.dart';
// Import note_providers and use families
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
// Import new single config providers
import 'package:flutter_memos/providers/note_server_config_provider.dart';
// Import settings_provider for manuallyHiddenNoteIdsProvider
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/providers/task_server_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_entity_form.dart'; // Updated import
import 'edit_entity_providers.dart'; // Updated import

class EditEntityScreen extends ConsumerWidget {
  final String entityId;
  final String entityType; // 'note' or 'comment' or 'task'
  // serverIdOverride is no longer needed as context comes from note/task providers
  // final String? serverIdOverride;

  const EditEntityScreen({
    super.key,
    required this.entityId,
    required this.entityType,
    // this.serverIdOverride, // Removed
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine the serverId based on entityType
    String? serverId;
    if (entityType == 'note' || entityType == 'comment') {
      serverId = ref.watch(noteServerConfigProvider)?.id;
    } else if (entityType == 'task') {
      serverId = ref.watch(taskServerConfigProvider)?.id;
    }

    // Handle case where serverId is null (no server configured for this type)
    if (serverId == null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Error')),
        child: Center(
          child: Text('Cannot edit $entityType: Server not configured.'),
        ),
      );
    }

    // Watch the generalized provider, passing parameters including serverId
    final entityAsync = ref.watch(
      editEntityProvider(
        EntityProviderParams(
          id: entityId,
          type: entityType,
          serverId: serverId, // Pass the determined serverId
        ),
      ),
    );

    return PopScope(
      // When popping the screen, ensure we refresh the relevant lists
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && serverId != null) {
          // Check serverId again
          // Refresh based on entity type
          if (entityType == 'note') {
            ref.invalidate(
              note_providers.notesNotifierProvider,
            ); // Refresh main list
            ref.invalidate(
              note_providers.noteDetailProvider(entityId),
            ); // Refresh detail
            ref
                .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
                .remove(entityId); // Unhide
          } else if (entityType == 'comment') {
            // If a comment was edited, refresh the comments list for the parent note
            final parts = entityId.split(
              '/',
            ); // Assuming format "noteId/commentId"
            if (parts.length >= 2) {
              final parentNoteId = parts[0];
              ref.invalidate(note_providers.noteCommentsProvider(parentNoteId));
              // Also refresh the parent note detail as comments changed
              ref.invalidate(note_providers.noteDetailProvider(parentNoteId));
            }
          } else if (entityType == 'task') {
            // TODO: Refresh task list and detail if task editing is implemented
            // ref.invalidate(taskNotifierProvider);
            // ref.invalidate(taskDetailProvider(entityId));
          }
        }
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            entityType == 'comment'
                ? 'Edit Comment'
                : (entityType == 'task' ? 'Edit Task' : 'Edit Note'),
          ),
          transitionBetweenRoutes: false,
        ),
        child: SafeArea(
          child: entityAsync.when(
            data:
                (entity) => EditEntityForm(
                  // Use renamed form
                  entity: entity,
                  entityId: entityId,
                  entityType: entityType,
                  serverId:
                      serverId ?? '', // Pass determined serverId to the form
                ),
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error:
                (error, _) => Center(
                  child: Text(
                    'Error loading $entityType: $error',
                    style: const TextStyle(color: CupertinoColors.systemRed),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
