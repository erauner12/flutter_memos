import 'package:flutter_memos/models/comment.dart';
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
    String? filter,
    String? state,
    String? sort,
    String? direction,
    ServerConfig? targetServerOverride,
    BlinkoNoteType? blinkoType,
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

  Future<NoteItem> archiveNote(String id, {ServerConfig? targetServerOverride});

  Future<NoteItem> togglePinNote(
    String id, {
    ServerConfig? targetServerOverride,
  });

  Future<void> setNoteRelations(
    String noteId,
    List<Map<String, dynamic>> relations, {
    ServerConfig? targetServerOverride,
  });

  // --- Note Comment Operations ---
  // These specifically interact with note comments via the underlying API.
  // These override the generic comment methods from BaseApiService if they existed,
  // or simply define the expected interface for note-based services.

  Future<List<Comment>> listNoteComments(
    String noteId, {
    ServerConfig? targetServerOverride,
  });

  Future<Comment> getNoteComment(
    String commentId, {
    ServerConfig? targetServerOverride,
  });

  Future<Comment> createNoteComment(
    String noteId,
    Comment comment, {
    ServerConfig? targetServerOverride,
    List<Map<String, dynamic>>? resources, // Optional resources
  });

  Future<Comment> updateNoteComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  });

  Future<void> deleteNoteComment(
    String noteId, // May need noteId for context/permissions
    String commentId, {
    ServerConfig? targetServerOverride,
  });
}
