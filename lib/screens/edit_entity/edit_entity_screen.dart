import 'package:flutter/cupertino.dart';
// Import note_providers instead of memo_detail_provider and memo_providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
// Import settings_provider for manuallyHiddenNoteIdsProvider
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_entity_form.dart'; // Updated import
import 'edit_entity_providers.dart'; // Updated import

class EditEntityScreen extends ConsumerWidget { // Renamed class
  final String entityId;
  final String entityType; // 'note' or 'comment'

  const EditEntityScreen({ // Renamed constructor
    super.key,
    required this.entityId,
    required this.entityType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the generalized provider, passing parameters as EntityProviderParams
    final entityAsync = ref.watch(
      editEntityProvider(EntityProviderParams(id: entityId, type: entityType)),
    );

    return PopScope(
      // When popping the screen, ensure we refresh the relevant lists
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Always refresh the main notes list (parent note might have been bumped)
          ref
              .read(note_providers.notesNotifierProvider.notifier) // Use provider from note_providers
              .refresh();

          if (entityType == 'comment') {
            // If a comment was edited, refresh the comments list for the parent note
            final parts = entityId.split('/');
            if (parts.isNotEmpty) {
              final parentNoteId = parts[0]; // Renamed from parentMemoId
              // Ensure this uses the imported provider from note_providers
              ref.invalidate(note_providers.noteCommentsProvider(parentNoteId));
            }
          } else {
            // entityType == 'note'
            // If a note was edited, refresh its detail view and cache
            if (ref.exists(note_providers.noteDetailCacheProvider)) { // Use provider from note_providers
              ref.invalidate(note_providers.noteDetailProvider(entityId)); // Use provider from note_providers
            }
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
