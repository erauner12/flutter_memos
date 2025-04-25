import 'package:flutter/cupertino.dart';
// Import note_providers and use families
import 'package:flutter_memos/providers/note_providers.dart' as note_p;
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

  const EditEntityScreen({
    super.key,
    required this.entityId,
    required this.entityType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine the serverId based on entityType - needed for PopScope logic and potentially form context
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

    // Watch the generalized provider, passing parameters (serverId removed from params)
    final entityAsync = ref.watch(
      editEntityProvider(
        EntityProviderParams(
          id: entityId,
          type: entityType,
          // serverId: serverId, // Removed: serverId is not part of EntityProviderParams
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
            // Invalidate the notes list family (broadly)
            ref.invalidate(note_p.notesNotifierFamily);
            ref.invalidate(
              note_p.noteDetailProvider(entityId),
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
              ref.invalidate(note_p.noteCommentsProvider(parentNoteId));
              // Also refresh the parent note detail as comments changed
              ref.invalidate(note_p.noteDetailProvider(parentNoteId));
              // Also invalidate the main notes list as the parent note's update time might have bumped
              ref.invalidate(note_p.notesNotifierFamily);
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
                  serverId: '',
                  // serverId: serverId, // Removed: Form likely gets serverId from provider if needed
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
