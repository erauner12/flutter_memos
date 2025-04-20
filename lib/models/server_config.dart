import 'package:flutter/foundation.dart';
import 'package:flutter_memos/utils/enum_utils.dart'; // Import the new helper
import 'package:uuid/uuid.dart';

// Ensure all required types are present.
enum ServerType { memos, blinko, todoist, vikunja }

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
    // Add ValueGetter for nullable fields like name
    ValueGetter<String?>? nameGetter,
  }) {
    // Ensure the copied type is not Todoist
    final finalServerType = serverType ?? this.serverType;
    assert(
      finalServerType != ServerType.todoist,
      'copyWith should not result in ServerType.todoist',
    );

    return ServerConfig(
      id: id ?? this.id,
      name:
          nameGetter != null
              ? nameGetter()
              : (name ?? this.name), // Handle nullable name copy
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
      // Use describeEnum for consistent serialization (matches helper)
      'serverType': describeEnum(serverType),
    };
  }

  /// Create from a map (from storage)
  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    final rawServerType = json['serverType'] as String?;
    if (kDebugMode) {
      print(
        '[ServerConfig.fromJson] Parsing server ID: ${json['id']}. Raw serverType from JSON: "$rawServerType" (Type: ${rawServerType?.runtimeType})',
      );
    }

    // Use the case-insensitive helper, providing the required defaultValue
    final ServerType parsedType = enumFromString<ServerType>(
      ServerType.values,
      rawServerType,
      defaultValue: ServerType.memos, // Provide the default value here
    );

    // Handle legacy 'todoist' or unknown types specifically for ServerConfig
    // Note: enumFromString now handles null/unknown by returning defaultValue,
    // so we only need to check specifically for the 'todoist' case here.
    ServerType finalType;
    if (parsedType == ServerType.todoist) {
      if (kDebugMode) {
        print(
          '[ServerConfig.fromJson] Warning: Encountered serverType "todoist" for ID ${json['id']}. Defaulting to "memos" for this ServerConfig instance. It should be filtered by the notifier.',
        );
      }
      finalType =
          ServerType
              .memos; // Default to memos for ServerConfig if parsed as Todoist
    } else {
      // Use the parsed type (which will be memos/blinko/vikunja, or memos if raw was null/invalid)
      finalType = parsedType;
    }


    if (kDebugMode) {
      // Log the final determined type for the ServerConfig instance
      print(
        '[ServerConfig.fromJson] Determined serverType for ServerConfig instance: ${describeEnum(finalType)} for server ID: ${json['id']}',
      );
    }

    return ServerConfig(
      id:
          json['id'] as String? ??
          const Uuid().v4(), // Handle missing ID for migration
      name: json['name'] as String?, // Handle optional name
      serverUrl: json['serverUrl'] as String? ?? '',
      authToken: json['authToken'] as String? ?? '',
      serverType:
          finalType, // Assign determined (and validated non-Todoist) type
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
    // Use describeEnum for consistency
    return 'ServerConfig(id: $id, name: $name, type: ${describeEnum(serverType)}, serverUrl: $serverUrl, authToken: ${authToken.isNotEmpty ? "****" : "empty"})'; // Include id, name, and type
  }

  // Corrected static empty method to return a ServerConfig
  static ServerConfig empty() {
    return ServerConfig(
      serverUrl: '',
      authToken: '',
      serverType: ServerType.memos, // Or another appropriate default
    );
  }
}
