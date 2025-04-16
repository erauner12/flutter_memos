import 'package:flutter_memos/models/list_notes_response.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/services/base_api_service.dart';

/// Interface for API services that primarily deal with Notes (e.g., Memos, Blinko).
abstract class NoteApiService extends BaseApiService {
  // --- Note Operations ---
  Future<ListNotesResponse> listNotes({
    int? pageSize,
    String? pageToken,
    String? filter, // Implementation specific filter string
    String? state, // e.g., 'NORMAL', 'ARCHIVED'
    String? sort, // e.g., 'updateTime'
    String? direction, // e.g., 'DESC'
    ServerConfig? targetServerOverride,
  });

  Future<NoteItem> getNote(String id, {ServerConfig? targetServerOverride});

  Future<NoteItem> createNote(
    NoteItem note, {
    ServerConfig? targetServerOverride,
  });

  Future<NoteItem> updateNote(
    String id,
    NoteItem note, {
    ServerConfig? targetServerOverride,
  });

  Future<void> deleteNote(String id, {ServerConfig? targetServerOverride});

  // --- Note Actions ---
  Future<NoteItem> archiveNote(String id, {ServerConfig? targetServerOverride});
  Future<NoteItem> togglePinNote(
    String id, {
    ServerConfig? targetServerOverride,
  });

  // --- Note Relations ---
  Future<void> setNoteRelations(
    String noteId,
    List<Map<String, dynamic>> relations, // Type specific to Memos/Blinko
    {ServerConfig? targetServerOverride}
  );

  // --- Note Comments (Potentially override BaseApiService behavior if needed) ---
  // Default implementations from BaseApiService might suffice, but can be overridden
  // if Note comments behave differently. For now, we assume base is sufficient.
  // Future<List<Comment>> listNoteComments(...); // Renamed for clarity?
  // Future<Comment> createNoteComment(...);
  // etc.
}
