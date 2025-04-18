import 'package:flutter/cupertino.dart';
// Import note_providers and use families
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import for active server
// Import settings_provider for manuallyHiddenNoteIdsProvider
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_entity_form.dart'; // Updated import
import 'edit_entity_providers.dart'; // Updated import

class EditEntityScreen extends ConsumerWidget {
  final String entityId;
  final String entityType; // 'note' or 'comment'
  // Add serverId if it's passed via route arguments, otherwise get from active
  final String? serverIdOverride;

  const EditEntityScreen({
    super.key,
    required this.entityId,
    required this.entityType,
    this.serverIdOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine the serverId to use
    final activeServerId = ref.watch(activeServerConfigProvider)?.id;
    final serverId = serverIdOverride ?? activeServerId;

    // Handle case where serverId is null (shouldn't happen if called correctly)
    if (serverId == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Error')),
        child: Center(child: Text('Cannot edit entity: Server ID not found.')),
      );
    }

    // Watch the generalized provider, passing parameters including serverId
    final entityAsync = ref.watch(
      editEntityProvider(
        EntityProviderParams(
          id: entityId,
          type: entityType,
          serverId: serverId,
        ),
      ),
    );

    return PopScope(
      // When popping the screen, ensure we refresh the relevant lists
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Always refresh the main notes list for the correct server
          ref
              .read(
                note_providers.notesNotifierProviderFamily(serverId).notifier,
              )
              .refresh();

          if (entityType == 'comment') {
            // If a comment was edited, refresh the comments list for the parent note
            final parts = entityId.split('/');
            if (parts.isNotEmpty) {
              final parentNoteId = parts[0];
              // Use noteCommentsProviderFamily with serverId and noteId
              ref.invalidate(
                note_providers.noteCommentsProviderFamily((
                  serverId: serverId,
                  noteId: parentNoteId,
                )),
              );
            }
          } else {
            // entityType == 'note'
            // If a note was edited, refresh its detail view and cache
            // Use noteDetailProviderFamily with serverId and noteId
            ref.invalidate(
              note_providers.noteDetailProviderFamily((
                serverId: serverId,
                noteId: entityId,
              )),
            );

            // Ensure the item is not hidden (using correct provider and remove method)
            ref
                .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
                .remove(entityId); // Directly remove the ID if it exists
          }
        }
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            entityType == 'comment' ? 'Edit Comment' : 'Edit Note', // Updated text
          ),
          transitionBetweenRoutes: false,
        ),
        child: SafeArea(
          child: entityAsync.when(
            data:
                (entity) => EditEntityForm( // Use renamed form
                  entity: entity,
                  entityId: entityId,
                  entityType: entityType,
                  serverId: serverId, // Pass serverId to the form
                ),
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error:
                (error, _) => Center(
                  child: Text(
                    'Error loading ${entityType == 'comment' ? 'comment' : 'note'}: $error', // Updated text
                    style: const TextStyle(color: CupertinoColors.systemRed),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
