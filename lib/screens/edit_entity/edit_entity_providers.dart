import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem model
import 'package:flutter_memos/providers/api_providers.dart'
    as api_p; // Import for noteApiServiceProvider
// Import note_providers and use new family/API providers
import 'package:flutter_memos/providers/note_providers.dart' as note_p;
// Import settings_provider for manuallyHiddenNoteIdsProvider
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parameter class for entity providers to ensure consistent == checks.
class EntityProviderParams {
  final String id;
  final String type; // 'note' or 'comment'

  EntityProviderParams({
    required this.id,
    required this.type,
  });

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
    // Use the api_p provider directly
    final NoteApiService apiService = ref.read(api_p.noteApiServiceProvider);
    final id = params.id;
    final type = params.type;

    if (kDebugMode) print('[editEntityProvider] Fetching $type with ID: $id');

    if (type == 'comment') {
      final parts = id.split('/');
      final actualCommentId = parts.length > 1 ? parts.last : id;
      return apiService.getNoteComment(actualCommentId);
    } else {
      // Default 'note'
      return apiService.getNote(id);
    }
  },
  name: 'editEntityProvider',
);

// Provider for saving entity (NoteItem or Comment) changes
final saveEntityProvider = Provider.family<
  Future<void> Function(dynamic),
  EntityProviderParams
>((ref, params) {
  final id = params.id;
  final type = params.type;

  return (dynamic updatedEntity) async {
    // Use the api_p provider directly
    final NoteApiService apiService = ref.read(api_p.noteApiServiceProvider);
    if (kDebugMode) print('[saveEntityProvider] Saving $type with ID: $id');

    if (type == 'comment') {
      final comment = updatedEntity as Comment;
      final parts = id.split('/');
      if (parts.length < 2)
        throw ArgumentError('Invalid comment ID format for saving: $id');
      final parentNoteId = parts[0];
      final actualCommentId = parts[1];

      await apiService.updateNoteComment(actualCommentId, comment);
      if (kDebugMode)
        print(
          '[saveEntityProvider] Comment $actualCommentId updated successfully.',
        );

      try {
        if (kDebugMode)
          print('[saveEntityProvider] Bumping parent note: $parentNoteId');
        // Use bumpNoteApiProvider which returns a callable function
        await ref.read(
          note_p.bumpNoteApiProvider(parentNoteId))();
        if (kDebugMode)
          print(
            '[saveEntityProvider] Parent note $parentNoteId bumped successfully.',
          );
      } catch (e, s) {
        if (kDebugMode)
          print(
            '[saveEntityProvider] Failed to bump parent note $parentNoteId: $e\n$s',
          );
      }

      ref.invalidate(
        note_p.noteCommentsProvider(parentNoteId),
      ); // Use noteCommentsProvider family
      // Invalidate the notes list family (broadly)
      ref.invalidate(note_p.notesNotifierFamily);

    } else {
      // type == 'note'
      final note = updatedEntity as NoteItem;
      final savedNote = await apiService.updateNote(id, note);
      if (kDebugMode)
        print('[saveEntityProvider] Note $id updated successfully.');

      if (ref.exists(note_p.noteDetailCacheProvider)) {
        ref
            .read(note_p.noteDetailCacheProvider.notifier)
            .update((state) => {...state, id: savedNote});
      }

      // Invalidate the notes list family (broadly)
      ref.invalidate(note_p.notesNotifierFamily);
      ref.invalidate(
        note_p.noteDetailProvider(id),
      ); // Use noteDetailProvider family
      ref.read(settings_p.manuallyHiddenNoteIdsProvider.notifier).remove(id);
    }
  };
}, name: 'saveEntityProvider');
