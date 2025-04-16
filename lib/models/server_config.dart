import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart'; // Add uuid import

// Keep ServerType.todoist defined for WorkbenchItemReference use,
// but ServerConfig instances should never have this type.
enum ServerType { memos, blinko, todoist }

/// Server configuration model for device-level storage
class ServerConfig {
  final String id; // Add unique ID
  final String? name; // Add optional user-friendly name
  final String serverUrl;
  final String authToken;
  final ServerType serverType; // Add serverType field

  // Update constructor to accept id and name, generate ID if not provided
  ServerConfig({
    String? id, // Make id optional in constructor
    this.name,
    required this.serverUrl,
    required this.authToken,
    required this.serverType, // Require serverType
    // Ensure Todoist type is never passed here for ServerConfig instances
  }) : id = id ?? const Uuid().v4() {
    // Add runtime check to prevent creating ServerConfig with Todoist type
    // This helps catch programming errors, though fromJson handles legacy data.
    assert(
      serverType != ServerType.todoist,
      'ServerConfig instances should not have ServerType.todoist',
    );
  }


  /// Create a copy of this configuration with some fields replaced
  ServerConfig copyWith({
    String? id,
    String? name, // Add name
    String? serverUrl,
    String? authToken,
    ServerType? serverType, // Add serverType
  }) {
    // Ensure the copied type is not Todoist
    final finalServerType = serverType ?? this.serverType;
    assert(
      finalServerType != ServerType.todoist,
      'copyWith should not result in ServerType.todoist',
    );

    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name, // Copy name
      serverUrl: serverUrl ?? this.serverUrl,
      authToken: authToken ?? this.authToken,
      serverType:
          finalServerType, // Copy serverType (already asserted non-Todoist)
    );
  }

  /// Convert to a map for storage
  Map<String, dynamic> toJson() {
    // Ensure we don't serialize Todoist type from a ServerConfig instance
    assert(
      serverType != ServerType.todoist,
      'toJson should not serialize ServerType.todoist for ServerConfig',
    );
    return {
      'id': id, // Add id
      'name': name, // Add name
      'serverUrl': serverUrl,
      'authToken': authToken,
      'serverType': serverType.name, // Store enum name as string
    };
  }

  /// Create from a map (from storage)
  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    // Determine serverType, default to memos for backward compatibility
    // Explicitly handle legacy 'todoist' string by defaulting to memos.
    ServerType type = ServerType.memos; // Default
    final rawServerType = json['serverType']; // Get raw value
    if (kDebugMode) {
      print(
        '[ServerConfig.fromJson] Parsing server ID: ${json['id']}. Raw serverType from JSON: "$rawServerType" (Type: ${rawServerType?.runtimeType})',
      );
    }
    if (rawServerType is String) {
      if (rawServerType == ServerType.todoist.name) {
        // Found a legacy Todoist config - log and default to memos.
        // It should be filtered out by the notifier later.
        if (kDebugMode) {
          print(
            '[ServerConfig.fromJson] Warning: Encountered legacy serverType "todoist" for ID ${json['id']}. Defaulting to "memos" for this ServerConfig instance. It should be filtered by the notifier.',
          );
        }
        type = ServerType.memos; // Default to memos
      } else {
        // Try parsing other known types (memos, blinko)
        type = ServerType.values.firstWhere(
          (e) =>
              e.name == rawServerType &&
              e != ServerType.todoist, // Ensure we don't match todoist here
          orElse: () {
            if (kDebugMode) {
              print(
                '[ServerConfig.fromJson] Warning: serverType string "$rawServerType" did not match known enum values (memos, blinko). Defaulting to memos.',
              );
            }
            return ServerType
                .memos; // Fallback if string doesn't match memos or blinko
          },
        );
      }
    } else if (rawServerType != null) {
      if (kDebugMode) {
        print(
          '[ServerConfig.fromJson] Warning: serverType field was present but not a String. Defaulting to memos.',
        );
      }
      // type remains ServerType.memos (default)
    }
    // No else needed, default is already memos

    if (kDebugMode) {
      // Log the final determined type for the ServerConfig instance
      print(
        '[ServerConfig.fromJson] Determined serverType for ServerConfig instance: ${type.name} for server ID: ${json['id']}',
      );
    }

    return ServerConfig(
      id:
          json['id'] as String? ??
          const Uuid().v4(), // Handle missing ID for migration
      name: json['name'] as String?, // Handle optional name
      serverUrl: json['serverUrl'] as String? ?? '',
      authToken: json['authToken'] as String? ?? '',
      serverType: type, // Assign determined (and validated non-Todoist) type
    );
  }


  /// Default configuration (no longer used directly, but keep for reference/tests)
  static ServerConfig get defaultConfig => ServerConfig(
        serverUrl: '',
        authToken: '',
    serverType: ServerType.memos, // Default type
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerConfig &&
        other.id == id && // Compare id
        other.name == name && // Compare name
        other.serverUrl == serverUrl &&
        other.authToken == authToken &&
        other.serverType == serverType; // Compare serverType
  }

  @override
  int get hashCode => Object.hash(id, name, serverUrl, authToken, serverType); // Hash id, name, and serverType

  @override
  String toString() {
    // Ensure we don't log Todoist type from a ServerConfig instance
    assert(
      serverType != ServerType.todoist,
      'toString should not be called on a ServerConfig with ServerType.todoist',
    );
    return 'ServerConfig(id: $id, name: $name, type: ${serverType.name}, serverUrl: $serverUrl, authToken: ${authToken.isNotEmpty ? "****" : "empty"})'; // Include id, name, and type
  }
}
