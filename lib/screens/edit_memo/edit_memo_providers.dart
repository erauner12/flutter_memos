import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem model
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/memo_detail_provider.dart'
    as detail_providers; // Alias detail providers
import 'package:flutter_memos/providers/memo_providers.dart'
    as list_providers; // Alias list providers
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart'
    show memoCommentsProvider; // Import memoCommentsProvider explicitly
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
        // Assuming bumpNoteProvider exists (needs renaming if not done)
        await ref.read(
          list_providers.bumpNoteProvider(parentNoteId),
        )(); // Use renamed provider
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
        memoCommentsProvider(parentNoteId),
      ); // Refresh comments for the parent note
      await ref
          .read(
            list_providers.notesNotifierProvider.notifier,
          ) // Use renamed provider
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
      if (ref.exists(detail_providers.noteDetailCacheProvider)) {
        // Use renamed provider
        ref
            .read(
              detail_providers.noteDetailCacheProvider.notifier,
            ) // Use renamed provider
            .update((state) => {...state, id: savedNote}); // Update with NoteItem directly, remove 'as Memo' cast
      }

      // Refresh all related providers to ensure UI is consistent
      await ref
          .read(
            list_providers.notesNotifierProvider.notifier,
          ) // Use renamed provider
          .refresh(); // Refresh the notes list
      ref.invalidate(
        detail_providers.memoDetailProvider(id),
      ); // Refresh note detail (keep name or rename)

      // Clear any hidden note IDs for this note to ensure it's visible
      ref
          .read(
            list_providers.hiddenMemoIdsProvider.notifier,
          ) // Use correct provider name if renamed
          .update((state) => state.contains(id) ? (state..remove(id)) : state);
    }
  };
}, name: 'saveEntityProvider'); // Optional: Add name for debugging