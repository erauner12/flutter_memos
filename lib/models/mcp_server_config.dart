import 'dart:convert'; // Import dart:convert for jsonEncode/Decode

import 'package:collection/collection.dart'; // For MapEquality
import 'package:flutter/foundation.dart';

// Define the connection type enum
enum McpConnectionType { stdio, tcp }

@immutable
class McpServerConfig {
  // ... existing properties ...
  final String id; // Unique ID
  final String name;
  final String command; // Keep for stdio, potentially empty for tcp
  final String args; // Keep for stdio, potentially empty for tcp
  final bool isActive; // Whether the user wants this server to be connected
  final Map<String, String> customEnvironment;

  // New fields for connection type and network details
  final McpConnectionType connectionType;
  final String? host; // Nullable, only used for tcp
  final int? port; // Nullable, only used for tcp


  // ... existing constructor ...
  const McpServerConfig({
    required this.id,
    required this.name,
    this.connectionType = McpConnectionType.stdio, // Default to stdio
    this.command = '', // Default to empty string
    this.args = '', // Default to empty string
    this.host, // Nullable, no default needed
    this.port, // Nullable, no default needed
    this.isActive = false,
    this.customEnvironment = const {}, // Default to empty map
  }) : // Add validation if needed, e.g., host/port required if type is tcp
       assert(
         connectionType == McpConnectionType.tcp
             ? (host != null && port != null)
             : true,
         'Host and Port must be provided for TCP connection type.',
       );

  // ... existing copyWith ...
  McpServerConfig copyWith({
    String? id,
    String? name,
    McpConnectionType? connectionType, // Add connectionType
    String? command,
    String? args,
    String? host, // Add host
    int? port, // Add port
    bool? isActive,
    Map<String, String>? customEnvironment, // Allow updating environment
  }) {
    // Handle potential null assignment for host/port if connection type changes
    final effectiveHost =
        (connectionType ?? this.connectionType) == McpConnectionType.tcp
            ? (host ?? this.host)
            : null;
    final effectivePort =
        (connectionType ?? this.connectionType) == McpConnectionType.tcp
            ? (port ?? this.port)
            : null;

    return McpServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      command: command ?? this.command,
      args: args ?? this.args,
      host: effectiveHost,
      port: effectivePort,
      isActive: isActive ?? this.isActive,
      customEnvironment:
          customEnvironment ?? this.customEnvironment, // Update env
    );
  }


  // For saving/loading from SharedPreferences via JSON OR CloudKit (as JSON string)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'connectionType': connectionType.name, // Store enum name as string
    'command': command,
    'args': args,
    'host': host, // Store nullable string
    'port': port, // Store nullable int
    'isActive': isActive,
    // Encode the map as a JSON string for easier storage
    'customEnvironment': jsonEncode(customEnvironment),
  };

  // ... fromJson remains the same for SharedPreferences, but CloudKit will use _mapToMcpServerConfig ...

  factory McpServerConfig.fromJson(Map<String, dynamic> json) {
    // Safely parse the custom environment map (expecting a JSON string or a Map)
    Map<String, String> environment = {};
    if (json['customEnvironment'] is String) {
      try {
        // Decode the JSON string back into a Map
        final decodedMap = jsonDecode(json['customEnvironment'] as String);
        if (decodedMap is Map) {
          // Ensure keys and values are strings
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
      // Handle legacy format if needed
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

    // Parse connection type from string, default to stdio if invalid/missing
    final connectionTypeName = json['connectionType'] as String?;
    final connectionType = McpConnectionType.values.firstWhere(
      (e) => e.name == connectionTypeName,
      orElse: () => McpConnectionType.stdio, // Default to stdio
    );

    // Parse port safely
    int? port;
    if (json['port'] != null) {
      if (json['port'] is int) {
        port = json['port'] as int;
      } else if (json['port'] is String) {
        port = int.tryParse(json['port'] as String);
      }
    }


    return McpServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      connectionType: connectionType,
      command:
          json['command'] as String? ?? '', // Handle potential null command
      args: json['args'] as String? ?? '', // Handle potential null args
      host: json['host'] as String?, // Host is nullable
      port: port, // Use safely parsed port
      isActive: json['isActive'] as bool? ?? false,
      customEnvironment: environment, // Use parsed map
    );
  }

  // ... operator ==, hashCode, toString remain the same ...
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McpServerConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          connectionType == other.connectionType && // Compare connectionType
          command == other.command &&
          args == other.args &&
          host == other.host && // Compare host
          port == other.port && // Compare port
          isActive == other.isActive &&
          // Compare environment maps
          const MapEquality().equals(
            customEnvironment,
            other.customEnvironment,
          );

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      connectionType.hashCode ^ // Include connectionType hash
      command.hashCode ^
      args.hashCode ^
      host.hashCode ^ // Include host hash
      port.hashCode ^ // Include port hash
      isActive.hashCode ^
      // Include environment map hash
      const MapEquality().hash(customEnvironment);

  @override
  String toString() {
    return 'McpServerConfig{id: $id, name: $name, type: ${connectionType.name}, command: $command, args: $args, host: $host, port: $port, isActive: $isActive, customEnvironment: $customEnvironment}';
  }
}
