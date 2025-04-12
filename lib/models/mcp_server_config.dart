import 'dart:convert'; // Import dart:convert for jsonEncode/Decode

import 'package:collection/collection.dart'; // For MapEquality
import 'package:flutter/foundation.dart';

@immutable
class McpServerConfig {
  final String id; // Unique ID
  final String name;
  // Informational fields (ignored by connection logic)
  final String command;
  final String args;
  // Connection fields (now mandatory)
  final String host; // Host of the MCP Manager service (non-nullable)
  final int port; // Port of the MCP Manager service (non-nullable)
  // State field
  final bool isActive; // Whether the user wants this server to be connected
  final Map<String, String> customEnvironment;

  const McpServerConfig({
    required this.id,
    required this.name,
    this.command = '', // Default to empty string
    this.args = '', // Default to empty string
    required this.host, // MAKE host required
    required this.port, // MAKE port required
    this.isActive = false,
    this.customEnvironment = const {}, // Default to empty map
  });

  McpServerConfig copyWith({
    String? id,
    String? name,
    String? command,
    String? args,
    String? host, // Keep nullable for signature, but handle below
    int? port, // Keep nullable for signature, but handle below
    bool? isActive,
    Map<String, String>? customEnvironment,
  }) {
    return McpServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      args: args ?? this.args,
      host: host ?? this.host, // Use directly
      port: port ?? this.port, // Use directly
      isActive: isActive ?? this.isActive,
      customEnvironment: customEnvironment ?? this.customEnvironment,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'command': command,
    'args': args,
    'host': host, // Store non-nullable string
    'port': port, // Store non-nullable int
    'isActive': isActive,
    'customEnvironment': jsonEncode(customEnvironment),
  };

  factory McpServerConfig.fromJson(Map<String, dynamic> json) {
    // Safely parse the custom environment map (expecting a JSON string or a Map)
    Map<String, String> environment = {};
    if (json['customEnvironment'] is String) {
      try {
        final decodedMap = jsonDecode(json['customEnvironment'] as String);
        if (decodedMap is Map) {
          environment = Map<String, String>.from(
            decodedMap.map((k, v) => MapEntry(k.toString(), v.toString())),
          );
        }
      } catch (e) {
        debugPrint(
          "Error parsing customEnvironment JSON string for server ${json['id']}: $e",
        );
      }
    } else if (json['customEnvironment'] is Map) {
      try {
        environment = Map<String, String>.from(
          (json['customEnvironment'] as Map).map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ),
        );
      } catch (e) {
        debugPrint(
          "Error parsing legacy customEnvironment map for server ${json['id']}: $e",
        );
      }
    }

    // Parse port safely, providing a default
    int parsedPort = 0; // Default port if missing or invalid
    if (json['port'] != null) {
      if (json['port'] is int) {
        parsedPort = json['port'] as int;
      } else if (json['port'] is String) {
        parsedPort = int.tryParse(json['port'] as String) ?? 0;
      }
    }

    // Parse host safely, providing a default
    String parsedHost =
        json['host'] as String? ?? ''; // Default host if missing/null

    return McpServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      command: json['command'] as String? ?? '',
      args: json['args'] as String? ?? '',
      host: parsedHost, // Use non-nullable host with default
      port: parsedPort, // Use non-nullable port with default
      isActive: json['isActive'] as bool? ?? false,
      customEnvironment: environment,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McpServerConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          command == other.command &&
          args == other.args &&
          host == other.host && // Compare non-nullable host
          port == other.port && // Compare non-nullable port
          isActive == other.isActive &&
          const MapEquality().equals(
            customEnvironment,
            other.customEnvironment,
          );

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      command.hashCode ^
      args.hashCode ^
      host.hashCode ^ // Include non-nullable host hash
      port.hashCode ^ // Include non-nullable port hash
      isActive.hashCode ^
      const MapEquality().hash(customEnvironment);

  @override
  String toString() {
    return 'McpServerConfig{id: $id, name: $name, command: $command, args: $args, host: $host, port: $port, isActive: $isActive, customEnvironment: $customEnvironment}';
  }
}
