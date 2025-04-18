import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem model
// Import note_providers and use families
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
// Import settings_provider for manuallyHiddenNoteIdsProvider
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parameter class for entity providers to ensure consistent == checks.
class EntityProviderParams {
  final String id;
  final String type; // 'note' or 'comment'
  // Add serverId, assuming it's needed to fetch the entity
  final String serverId;

  EntityProviderParams({
    required this.id,
    required this.type,
    required this.serverId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EntityProviderParams &&
        other.id == id &&
        other.type == type &&
        other.serverId == serverId;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode ^ serverId.hashCode;

  @override
  String toString() =>
      'EntityProviderParams(id: $id, type: $type, serverId: $serverId)';
}


// Provider to fetch the entity (note or comment) to be edited
final editEntityProvider = FutureProvider.family<dynamic, EntityProviderParams>(
  (ref, params) async {
    // Use the helper to get the API service for the specific server
    final NoteApiService apiService = note_providers
        .getNoteApiServiceForServer(
      ref,
      params.serverId,
    ); // Use public helper

    final id = params.id;
    final type = params.type;

  if (kDebugMode) {
      print(
        '[editEntityProvider(${params.serverId})] Fetching $type with ID: $id',
      );
  }

  if (type == 'comment') {
      // Assuming commentId format is "noteId/commentId" for getNoteComment
      // The getNoteComment expects the actual comment ID, not the combined one.
      final parts = id.split('/');
      final actualCommentId = parts.length > 1 ? parts.last : id;
      return apiService.getNoteComment(
        actualCommentId,
      ); // Use getNoteComment with actual ID
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
  final serverId = params.serverId; // Access serverId from params

  return (dynamic updatedEntity) async {
    // Use the helper to get the API service for the specific server
    final NoteApiService apiService = note_providers
        .getNoteApiServiceForServer(
      ref,
      serverId,
    ); // Use public helper

    if (kDebugMode) {
      print(
        '[saveEntityProvider(${params.serverId})] Saving $type with ID: $id',
      );
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
          '[saveEntityProvider(${params.serverId})] Comment $actualCommentId updated successfully.',
        );
      }

      // 2. Bump the parent note (try-catch to avoid failing the whole save)
      try {
        if (kDebugMode) {
          print(
            '[saveEntityProvider(${params.serverId})] Bumping parent note: $parentNoteId',
          );
        }
        // Use bumpNoteProviderFamily with serverId and noteId
        await ref.read(
          note_providers.bumpNoteProviderFamily((
            serverId: serverId,
            noteId: parentNoteId,
          )),
        )();
        if (kDebugMode) {
          print(
            '[saveEntityProvider(${params.serverId})] Parent note $parentNoteId bumped successfully.',
          );
        }
      } catch (e, s) {
        if (kDebugMode) {
          print(
            '[saveEntityProvider(${params.serverId})] Failed to bump parent note $parentNoteId: $e\n$s',
          );
        }
        // Optionally report error via error handler provider
        // ref.read(errorHandlerProvider)('Failed to bump parent note after comment update', source: 'saveEntityProvider', error: e, stackTrace: s);
      }

      // 3. Invalidate relevant providers
      ref.invalidate(
        // Use noteCommentsProviderFamily with serverId and noteId
        note_providers.noteCommentsProviderFamily((
          serverId: serverId,
          noteId: parentNoteId,
        )),
      ); // Refresh comments for the parent note
      await ref
          .read(
            // Use notesNotifierProviderFamily with serverId
            note_providers.notesNotifierProviderFamily(serverId).notifier,
          )
          .refresh(); // Refresh main note list because parent was bumped
    } else {
      // type == 'note'
      final note = updatedEntity as NoteItem; // Use NoteItem

      // Update note in the backend
      final savedNote = await apiService.updateNote(id, note); // Use updateNote
      if (kDebugMode) {
        print(
          '[saveEntityProvider(${params.serverId})] Note $id updated successfully.',
        );
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
            // Use notesNotifierProviderFamily with serverId
            note_providers.notesNotifierProviderFamily(serverId).notifier,
          )
          .refresh(); // Refresh the notes list
      ref.invalidate(
        // Use noteDetailProviderFamily with serverId and noteId
        note_providers.noteDetailProviderFamily((
          serverId: serverId,
          noteId: id,
        )),
      ); // Refresh note detail

      // Clear any hidden item IDs for this note to ensure it's visible
      // Use the correct provider from settings_provider and its remove method
      ref
          .read(
            settings_p.manuallyHiddenNoteIdsProvider.notifier,
          )
          .remove(id); // Directly remove the ID if it exists
    }
  };
}, name: 'saveEntityProvider'); // Optional: Add name for debugging
