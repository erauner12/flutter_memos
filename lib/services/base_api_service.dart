import 'package:flutter/foundation.dart'; // Import Uint8List
// Keep ServerConfig import
import 'package:flutter_memos/models/server_config.dart';

/// Base interface for all API services (Memos, Blinko, Todoist, etc.).
/// Contains only methods expected to be common across *all* service types.
abstract class BaseApiService {
  // --- Configuration & Health ---
  String get apiBaseUrl; // URL used by the service (may be fixed like Todoist)
  bool get isConfigured; // Check if service has valid config (URL/token)

  /// Configure the service instance, typically with base URL and auth token.
  /// Some services might ignore the baseUrl if it's fixed (like Todoist).
  Future<void> configureService({
    required String baseUrl,
    required String authToken,
  });

  /// Check the health/reachability of the configured API service.
  Future<bool> checkHealth();

  // --- Resources (Common Concept) ---
  /// Uploads raw file bytes as a resource.
  /// Returns a map containing resource metadata (e.g., ID, name) needed for linking.
  /// Implementation details (endpoint, response format) will vary.
  Future<Map<String, dynamic>> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  });

  /// Fetches the raw byte data for a given resource identifier (ID, name, or path).
  /// The exact identifier depends on the API implementation.
  Future<Uint8List> getResourceData(
    String resourceIdentifier, {
    ServerConfig? targetServerOverride,
  });

  // --- Note Operations (Moved to NoteApiService) ---
  // Future<ListNotesResponse> listNotes(...);
  // Future<NoteItem> getNote(...);
  // Future<NoteItem> createNote(...);
  // Future<NoteItem> updateNote(...);
  // Future<void> deleteNote(...);
  // Future<NoteItem> archiveNote(...);
  // Future<NoteItem> togglePinNote(...);
  // Future<void> setNoteRelations(...);

  // --- Comment Operations (Moved to NoteApiService / TaskApiService) ---
  // Future<List<Comment>> listComments(...);
  // Future<Comment> getComment(...);
  // Future<Comment> createComment(...);
  // Future<Comment> updateComment(...);
  // Future<void> deleteComment(...);
}

// --- Dummy Implementation ---

/// A non-functional implementation of BaseApiService for unconfigured states.
class DummyApiService implements BaseApiService {
  @override
  String get apiBaseUrl => '';
  @override
  bool get isConfigured => false;

  @override
  Future<void> configureService({
    required String baseUrl,
    required String authToken,
  }) async {
    // No-op
  }

  @override
  Future<bool> checkHealth() async => false;

  @override
  Future<Map<String, dynamic>> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  }) async {
    throw UnimplementedError("Service not configured (uploadResource)");
  }

  @override
  Future<Uint8List> getResourceData(
    String resourceIdentifier, {
    ServerConfig? targetServerOverride,
  }) async {
    throw UnimplementedError("Service not configured (getResourceData)");
  }
}
