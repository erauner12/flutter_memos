import 'package:flutter/foundation.dart'; // Import Uint8List
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/services/auth_strategy.dart'; // Import AuthStrategy

/// Base interface for all API services (Memos, Blinko, Todoist, etc.).
/// Contains only methods expected to be common across *all* service types.
abstract class BaseApiService {
  // --- Configuration & Health ---
  String get apiBaseUrl; // URL used by the service (may be fixed like Todoist)
  bool
  get isConfigured; // Check if service has valid config (URL/token/strategy)
  AuthStrategy? get authStrategy; // Expose the current auth strategy

  /// Configure the service instance using an AuthStrategy or fallback token.
  ///
  /// Use [authStrategy] for pluggable authentication (preferred).
  /// Use [authToken] for direct token configuration (legacy/fallback).
  /// Some services might ignore [baseUrl] if it's fixed (like Todoist).
  Future<void> configureService({
    required String baseUrl,
    AuthStrategy? authStrategy, // New preferred way
    @Deprecated('Use authStrategy instead')
    String? authToken, // Keep for fallback
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
}

// --- Dummy Implementation ---

/// A non-functional implementation of BaseApiService for unconfigured states.
class DummyApiService implements BaseApiService {
  @override
  String get apiBaseUrl => '';
  @override
  bool get isConfigured => false;
  @override
  AuthStrategy? get authStrategy => null;

  @override
  Future<void> configureService({
    required String baseUrl,
    AuthStrategy? authStrategy,
    @Deprecated('Use authStrategy instead') String? authToken,
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
