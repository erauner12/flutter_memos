import 'dart:convert'; // Import dart:convert for jsonEncode/Decode

import 'package:collection/collection.dart'; // For MapEquality
import 'package:flutter/foundation.dart';

@immutable
class McpServerConfig {
  // ... existing properties ...
  final String id; // Unique ID
  final String name;
  final String command;
  final String args;
  final bool isActive; // Whether the user wants this server to be connected
  final Map<String, String> customEnvironment;

  // ... existing constructor ...
  const McpServerConfig({
    required this.id,
    required this.name,
    required this.command,
    required this.args,
    this.isActive = false,
    this.customEnvironment = const {}, // Default to empty map
  });

  // ... existing copyWith ...
  McpServerConfig copyWith({
    String? id,
    String? name,
    String? command,
    String? args,
    bool? isActive,
    Map<String, String>? customEnvironment, // Allow updating environment
  }) {
    return McpServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      args: args ?? this.args,
      isActive: isActive ?? this.isActive,
      customEnvironment:
          customEnvironment ?? this.customEnvironment, // Update env
    );
  }


  // For saving/loading from SharedPreferences via JSON OR CloudKit (as JSON string)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'command': command,
    'args': args,
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

    return McpServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      command: json['command'] as String,
      args: json['args'] as String? ?? '', // Handle potential null args
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
          command == other.command &&
          args == other.args &&
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
      command.hashCode ^
      args.hashCode ^
      isActive.hashCode ^
      // Include environment map hash
      const MapEquality().hash(customEnvironment);

  @override
  String toString() {
    return 'McpServerConfig{id: $id, name: $name, command: $command, args: $args, isActive: $isActive, customEnvironment: $customEnvironment}';
  }
}
