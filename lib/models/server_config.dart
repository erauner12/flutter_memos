import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart'; // Add uuid import

// Add ServerType enum
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
  }) : id = id ?? const Uuid().v4(); // Generate UUID if id is null

  /// Create a copy of this configuration with some fields replaced
  ServerConfig copyWith({
    String? id,
    String? name, // Add name
    String? serverUrl,
    String? authToken,
    ServerType? serverType, // Add serverType
  }) {
    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name, // Copy name
      serverUrl: serverUrl ?? this.serverUrl,
      authToken: authToken ?? this.authToken,
      serverType: serverType ?? this.serverType, // Copy serverType
    );
  }

  /// Convert to a map for storage
  Map<String, dynamic> toJson() {
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
    ServerType type = ServerType.memos; // Default
    final rawServerType = json['serverType']; // Get raw value
    if (kDebugMode) {
      // Log the raw input value and its type
      print(
        '[ServerConfig.fromJson] Parsing server ID: ${json['id']}. Raw serverType from JSON: "$rawServerType" (Type: ${rawServerType?.runtimeType})',
      );
    }
    if (rawServerType is String) {
      type = ServerType.values.firstWhere(
        (e) => e.name == rawServerType,
        orElse: () {
          if (kDebugMode) {
            print(
              '[ServerConfig.fromJson] Warning: serverType string "$rawServerType" did not match any enum value. Defaulting to memos.',
            );
          }
          return ServerType.memos; // Fallback if string doesn't match
        },
      );
    } else if (rawServerType != null) {
      if (kDebugMode) {
        print(
          '[ServerConfig.fromJson] Warning: serverType field was present but not a String. Defaulting to memos.',
        );
      }
    }
    // No else needed, default is already memos

    if (kDebugMode) {
      // Log the final determined type
      print(
        '[ServerConfig.fromJson] Determined serverType: ${type.name} for server ID: ${json['id']}',
      );
    }

    return ServerConfig(
      id:
          json['id'] as String? ??
          const Uuid().v4(), // Handle missing ID for migration
      name: json['name'] as String?, // Handle optional name
      serverUrl: json['serverUrl'] as String? ?? '',
      authToken: json['authToken'] as String? ?? '',
      serverType: type, // Assign determined or default type
    );
  }

  /// Default configuration (no longer used directly, but keep for reference/tests)
  static ServerConfig get defaultConfig =>
      ServerConfig(
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
    return 'ServerConfig(id: $id, name: $name, type: ${serverType.name}, serverUrl: $serverUrl, authToken: ${authToken.isNotEmpty ? "****" : "empty"})'; // Include id, name, and type
  }
}
