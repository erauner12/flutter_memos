import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem model
import 'package:flutter_memos/providers/api_providers.dart';
// Import note_providers instead of memo_detail_provider and memo_providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parameter class for entity providers to ensure consistent == checks.
class EntityProviderParams {
  final String id;
  final String type; // 'note' or 'comment'

  EntityProviderParams({required this.id, required this.type});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EntityProviderParams &&
        other.id == id &&
        other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() => 'EntityProviderParams(id: $id, type: $type)';
}


// Provider to fetch the entity (note or comment) to be edited
final editEntityProvider = FutureProvider.family<dynamic, EntityProviderParams>(
  (ref, params) async {
    final apiService = ref.read(apiServiceProvider);
    final id = params.id;
    final type = params.type;

  if (kDebugMode) {
    print('[editEntityProvider] Fetching $type with ID: $id');
  }

  if (type == 'comment') {
      // Assuming commentId format is "noteId/commentId" for getNoteComment
      return apiService.getNoteComment(id); // Use getNoteComment
  } else {
      // Default 'note'
      return apiService.getNote(id); // Use getNote
  }
}, name: 'editEntityProvider'); // Optional: Add name for debugging

// Provider for saving entity (NoteItem or Comment) changes
final saveEntityProvider = Provider.family<
  Future<void> Function(dynamic),
  EntityProviderParams // Use EntityProviderParams
>((ref, params) {
  final id = params.id; // Access id from params
  final type = params.type; // Access type from params

  return (dynamic updatedEntity) async {
    final apiService = ref.read(apiServiceProvider);

    if (kDebugMode) {
      print('[saveEntityProvider] Saving $type with ID: $id');
    }

    if (type == 'comment') {
      final comment = updatedEntity as Comment;
      final parts = id.split('/');
      if (parts.length < 2) {
        throw ArgumentError('Invalid comment ID format for saving: $id');
      }
      final parentNoteId = parts[0];
      final actualCommentId = parts[1]; // Use the actual comment ID for update

      // 1. Update the comment using the actual comment ID
      await apiService.updateNoteComment(
        actualCommentId,
        comment,
      ); // Use updateNoteComment
      if (kDebugMode) {
        print(
          '[saveEntityProvider] Comment $actualCommentId updated successfully.',
        );
      }

      // 2. Bump the parent note (try-catch to avoid failing the whole save)
      try {
        if (kDebugMode) {
          print('[saveEntityProvider] Bumping parent note: $parentNoteId');
        }
        // Use bumpNoteProvider from note_providers
        await ref.read(
          note_providers.bumpNoteProvider(parentNoteId),
        )();
        if (kDebugMode) {
          print(
            '[saveEntityProvider] Parent note $parentNoteId bumped successfully.',
          );
        }
      } catch (e, s) {
        if (kDebugMode) {
          print(
            '[saveEntityProvider] Failed to bump parent note $parentNoteId: $e\n$s',
          );
        }
        // Optionally report error via error handler provider
        // ref.read(errorHandlerProvider)('Failed to bump parent note after comment update', source: 'saveEntityProvider', error: e, stackTrace: s);
      }

      // 3. Invalidate relevant providers
      ref.invalidate(
        note_providers.noteCommentsProvider(parentNoteId), // Use provider from note_providers
      ); // Refresh comments for the parent note
      await ref
          .read(
            note_providers.notesNotifierProvider.notifier, // Use provider from note_providers
          )
          .refresh(); // Refresh main note list because parent was bumped
    } else {
      // type == 'note'
      final note = updatedEntity as NoteItem; // Use NoteItem

      // Update note in the backend
      final savedNote = await apiService.updateNote(id, note); // Use updateNote
      if (kDebugMode) {
        print('[saveEntityProvider] Note $id updated successfully.');
      }

      // Update note detail cache if it exists
      if (ref.exists(note_providers.noteDetailCacheProvider)) { // Use provider from note_providers
        ref
            .read(
              note_providers.noteDetailCacheProvider.notifier, // Use provider from note_providers
            )
            .update((state) => {...state, id: savedNote}); // Update with NoteItem directly
      }

      // Refresh all related providers to ensure UI is consistent
      await ref
          .read(
            note_providers.notesNotifierProvider.notifier, // Use provider from note_providers
          )
          .refresh(); // Refresh the notes list
      ref.invalidate(
        note_providers.noteDetailProvider(id), // Use provider from note_providers
      ); // Refresh note detail

      // Clear any hidden item IDs for this note to ensure it's visible
      ref
          .read(
            note_providers.hiddenItemIdsProvider.notifier, // Use renamed provider from note_providers
          )
          .update((state) => state.contains(id) ? (state..remove(id)) : state);
    }
  };
}, name: 'saveEntityProvider'); // Optional: Add name for debugging