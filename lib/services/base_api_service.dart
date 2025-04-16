import 'package:flutter/foundation.dart'; // Import Uint8List
// Note: Comment model is now defined in the app, not directly from API generation
import 'package:flutter_memos/models/comment.dart';
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


  // --- Comments (Potentially Common Concept - Interface only) ---
  // While comments exist in Memos/Blinko (Notes) and Todoist (Tasks/Projects),
  // the structure and API calls differ significantly. Defining them here
  // provides a common interface name, but implementations will vary widely.
  // Consider if these truly belong in the *base* or specific interfaces.
  // Keeping them here for now as the concept exists across types.

  /// List comments associated with a parent entity (Note or Task).
  /// Caller needs to know the type of entity `parentId` refers to.
  Future<List<Comment>> listComments(
    String parentId, {
    ServerConfig? targetServerOverride,
  });

  /// Get a single comment by its ID.
  Future<Comment> getComment(
    String commentId, {
    ServerConfig? targetServerOverride,
  });

  /// Create a comment associated with a parent entity (Note or Task).
  Future<Comment> createComment(
    String parentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
    List<Map<String, dynamic>>? resources, // Optional resources
  });

  /// Update an existing comment.
  Future<Comment> updateComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  });

  /// Delete a comment.
  Future<void> deleteComment(
    String
    parentId, // May not be needed by all APIs (e.g., if commentId is globally unique)
    String commentId, {
    ServerConfig? targetServerOverride,
  });
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

  @override
  Future<List<Comment>> listComments(
    String parentId, {
    ServerConfig? targetServerOverride,
  }) async {
    throw UnimplementedError("Service not configured (listComments)");
  }

  @override
  Future<Comment> getComment(
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    throw UnimplementedError("Service not configured (getComment)");
  }

  @override
  Future<Comment> createComment(
    String parentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
    List<Map<String, dynamic>>? resources,
  }) async {
    throw UnimplementedError("Service not configured (createComment)");
  }

  @override
  Future<Comment> updateComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  }) async {
    throw UnimplementedError("Service not configured (updateComment)");
  }

  @override
  Future<void> deleteComment(
    String parentId,
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    throw UnimplementedError("Service not configured (deleteComment)");
  }
}
