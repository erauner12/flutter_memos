import 'package:flutter/foundation.dart'; // Import Uint8List
import 'package:flutter_memos/api/lib/api.dart'
    as memos_api; // Import for V1Resource and MemoRelation
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/list_notes_response.dart';
import 'package:flutter_memos/models/memo_relation.dart'; // Import MemoRelation model
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/server_config.dart';

abstract class BaseApiService {
  // Configuration
  String get apiBaseUrl;
  bool get isConfigured; // Check if service has valid config (URL/token)
  Future<void> configureService({required String baseUrl, required String authToken});

  // Core Note Operations
  Future<ListNotesResponse> listNotes({
    int? pageSize,
    String? pageToken,
    String? filter, // Generic filter string (implementation specific)
    String? state, // e.g., 'NORMAL', 'ARCHIVED'
    String? sort, // e.g., 'updateTime'
    String? direction, // e.g., 'DESC'
    ServerConfig? targetServerOverride,
  });

  Future<NoteItem> getNote(
     String id, {
     ServerConfig? targetServerOverride,
  });

  Future<NoteItem> createNote(
     NoteItem note, {
     ServerConfig? targetServerOverride,
  });

  Future<NoteItem> updateNote(
     String id,
     NoteItem note, {
     ServerConfig? targetServerOverride,
  });

  Future<void> deleteNote(
     String id, {
     ServerConfig? targetServerOverride,
  });

  // Common Actions (Optional - implement if both support similarly)
  Future<NoteItem> archiveNote(String id, { ServerConfig? targetServerOverride });
  Future<NoteItem> togglePinNote(String id, { ServerConfig? targetServerOverride });

  // Comments (Optional - implement if both support similarly)
  Future<List<Comment>> listNoteComments(String noteId, { ServerConfig? targetServerOverride });
  Future<Comment> getNoteComment(
    String commentId, {
    ServerConfig? targetServerOverride,
  }); // Added getNoteComment
  Future<Comment> createNoteComment(
    String noteId,
    Comment comment, {
    ServerConfig? targetServerOverride,
    List<memos_api.V1Resource>? resources,
  }); // Added resources param
  Future<Comment> updateNoteComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  }); // Changed signature
  Future<void> deleteNoteComment(String noteId, String commentId, { ServerConfig? targetServerOverride });

  // Relations (Added)
  Future<void> setNoteRelations(
    String noteId,
    List<MemoRelation> relations, {
    ServerConfig? targetServerOverride,
  });

  // Resources (Added)
  Future<memos_api.V1Resource> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  });

  // Health Check
  Future<bool> checkHealth();

  // Add other common methods as needed (e.g., tags)
}

// Dummy implementation for unconfigured state
class DummyApiService implements BaseApiService {
  @override
  String get apiBaseUrl => '';
  @override
  bool get isConfigured => false;

  @override
  Future<void> configureService({required String baseUrl, required String authToken}) async {}

  @override
  Future<ListNotesResponse> listNotes({int? pageSize, String? pageToken, String? filter, String? state, String? sort, String? direction, ServerConfig? targetServerOverride}) async {
    throw UnimplementedError("Service not configured");
  }
  @override
  Future<NoteItem> getNote(String id, {ServerConfig? targetServerOverride}) async {
    throw UnimplementedError("Service not configured");
  }
  @override
  Future<NoteItem> createNote(NoteItem note, {ServerConfig? targetServerOverride}) async {
    throw UnimplementedError("Service not configured");
  }
  @override
  Future<NoteItem> updateNote(String id, NoteItem note, {ServerConfig? targetServerOverride}) async {
    throw UnimplementedError("Service not configured");
  }
  @override
  Future<void> deleteNote(String id, {ServerConfig? targetServerOverride}) async {
    throw UnimplementedError("Service not configured");
  }
  @override
  Future<NoteItem> archiveNote(String id, {ServerConfig? targetServerOverride}) async {
    throw UnimplementedError("Service not configured");
  }
  @override
  Future<NoteItem> togglePinNote(String id, {ServerConfig? targetServerOverride}) async {
    throw UnimplementedError("Service not configured");
  }
  @override
  Future<List<Comment>> listNoteComments(String noteId, {ServerConfig? targetServerOverride}) async {
    throw UnimplementedError("Service not configured");
  }
  @override
  Future<Comment> getNoteComment(
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    // Added dummy implementation
    throw UnimplementedError("Service not configured");
  }
  @override
  Future<Comment> createNoteComment(
    String noteId,
    Comment comment, {
    ServerConfig? targetServerOverride,
    List<memos_api.V1Resource>? resources,
  }) async {
    // Added dummy implementation
    throw UnimplementedError("Service not configured");
  }

  @override
  Future<Comment> updateNoteComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  }) async {
    // Changed signature
    throw UnimplementedError("Service not configured");
  }
  @override
  Future<void> deleteNoteComment(String noteId, String commentId, {ServerConfig? targetServerOverride}) async {
    throw UnimplementedError("Service not configured");
  }
  @override
  Future<void> setNoteRelations(
    String noteId,
    List<MemoRelation> relations, {
    ServerConfig? targetServerOverride,
  }) async {
    // Added dummy implementation
    throw UnimplementedError("Service not configured");
  }

  @override
  Future<memos_api.V1Resource> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  }) async {
    // Added dummy implementation
    throw UnimplementedError("Service not configured");
  }

  @override
  Future<bool> checkHealth() async => false;
}
