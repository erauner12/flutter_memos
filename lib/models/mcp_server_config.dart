import 'dart:convert'; // Import dart:convert for jsonEncode/Decode

import 'package:collection/collection.dart'; // For MapEquality
import 'package:flutter/foundation.dart';

// ADD: Define the connection type enum
enum McpConnectionType { stdio, sse }

@immutable
class McpServerConfig {
  final String id; // Unique ID
  final String name;
  // ADD: Connection type field
  final McpConnectionType connectionType;
  // Stdio specific (can be empty for SSE)
  final String command;
  final String args;
  // SSE specific (nullable for Stdio)
  final String? host; // Nullable: Host of the MCP Manager service
  final int? port; // Nullable: Port of the MCP Manager service
  // State field
  final bool isActive; // Whether the user wants this server to be connected
  // ADD: isSecure field for SSE connections
  final bool isSecure; // Whether to use HTTPS for SSE connection
  final Map<String, String> customEnvironment;

  // MODIFY: Update constructor
  const McpServerConfig({
    required this.id,
    required this.name,
    required this.connectionType, // Make connectionType required
    this.command = '', // Keep defaults
    this.args = '', // Keep defaults
    this.host, // Make host nullable
    this.port, // Make port nullable
    this.isActive = false,
    this.isSecure = false, // Default to false
    this.customEnvironment = const {}, // Default to empty map
  });

  // MODIFY: Update copyWith
  McpServerConfig copyWith({
    String? id,
    String? name,
    McpConnectionType? connectionType, // Add connectionType
    String? command,
    String? args,
    String? host, // Keep nullable
    int? port, // Keep nullable
    bool? isActive,
    Map<String, String>? customEnvironment,
    bool? isSecure, // Add isSecure
    bool setHostToNull = false, // Flag to explicitly nullify host
    bool setPortToNull = false, // Flag to explicitly nullify port
  }) {
    return McpServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType:
          connectionType ?? this.connectionType, // Add connectionType
      command: command ?? this.command,
      args: args ?? this.args,
      host: setHostToNull ? null : (host ?? this.host), // Handle nullability
      port: setPortToNull ? null : (port ?? this.port), // Handle nullability
      isActive: isActive ?? this.isActive,
      isSecure: isSecure ?? this.isSecure, // Add isSecure
      customEnvironment: customEnvironment ?? this.customEnvironment,
    );
  }

  // MODIFY: Update toJson
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'connectionType': connectionType.name, // Store enum name as string
    'command': command,
    'args': args,
    'host': host, // Store nullable string
    'port': port, // Store nullable int
    'isActive': isActive,
    'isSecure': isSecure, // Add isSecure
    'customEnvironment': jsonEncode(customEnvironment), // Keep as JSON string
  };

  // MODIFY: Update fromJson factory
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

    // Parse connectionType safely, defaulting to stdio if missing/invalid
    McpConnectionType parsedConnectionType = McpConnectionType.stdio; // Default
    final typeString = json['connectionType'] as String?;
    if (typeString != null) {
      try {
        parsedConnectionType = McpConnectionType.values.byName(typeString);
      } catch (_) {
        debugPrint(
          "Invalid connectionType '$typeString' found for server ${json['id']}, defaulting to stdio.",
        );
        // Keep default stdio
      }
    } else {
      debugPrint(
        "Missing connectionType for server ${json['id']}, defaulting to stdio.",
      );
      // Apply heuristic for old data: if host/port look valid, assume SSE
      final potentialHost = json['host'] as String?;
      final potentialPort = json['port']; // Could be int or string
      int? parsedPotentialPort;
      if (potentialPort is int) {
        parsedPotentialPort = potentialPort;
      } else if (potentialPort is String && potentialPort.isNotEmpty) {
        parsedPotentialPort = int.tryParse(potentialPort);
      }

      if (potentialHost != null &&
          potentialHost.isNotEmpty &&
          parsedPotentialPort != null &&
          parsedPotentialPort > 0 &&
          parsedPotentialPort <= 65535) {
        // Add port range check here too
        debugPrint(
          "Applying heuristic: Assuming SSE type due to valid host/port for server ${json['id']}.",
        );
        parsedConnectionType = McpConnectionType.sse;
      }
    }

    // Parse host safely (nullable)
    String? parsedHost = json['host'] as String?;
    if (parsedHost != null && parsedHost.isEmpty) {
      parsedHost = null; // Treat empty string as null
    }

    // Parse port safely (nullable)
    int? parsedPort; // Default to null
    final portValue = json['port'];
    if (portValue is int) {
      parsedPort = portValue;
    } else if (portValue is String && portValue.isNotEmpty) {
      parsedPort = int.tryParse(portValue);
    }
    // Validate port range if not null
    if (parsedPort != null && (parsedPort <= 0 || parsedPort > 65535)) {
      debugPrint(
        "Invalid port value '$parsedPort' found for server ${json['id']}, setting port to null.",
      );
      parsedPort = null;
    }


    return McpServerConfig(
      id: json['id'] as String,
      name: json['name'] as String? ?? '', // Handle potential null name
      connectionType: parsedConnectionType, // Use parsed type
      command: json['command'] as String? ?? '',
      args: json['args'] as String? ?? '',
      host: parsedHost, // Use nullable host
      port: parsedPort, // Use nullable port
      isActive: json['isActive'] as bool? ?? false,
      customEnvironment: environment,
      isSecure:
          json['isSecure'] as bool? ?? false, // Parse isSecure, default false
    );
  }

  // MODIFY: Update == operator
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McpServerConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          connectionType == other.connectionType && // Add connectionType
          command == other.command &&
          args == other.args &&
          host == other.host && // Compare nullable host
          port == other.port && // Compare nullable port
          isActive == other.isActive &&
          isSecure == other.isSecure && // Add isSecure comparison
          const MapEquality().equals(
            customEnvironment,
            other.customEnvironment,
          );

  // MODIFY: Update hashCode
  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      connectionType.hashCode ^ // Add connectionType
      command.hashCode ^
      args.hashCode ^
      host.hashCode ^ // Include nullable host hash
      port.hashCode ^ // Include nullable port hash
      isActive.hashCode ^
      isSecure.hashCode ^ // Add isSecure hash
      const MapEquality().hash(customEnvironment);

  // MODIFY: Update toString
  @override
  String toString() {
    return 'McpServerConfig{id: $id, name: $name, connectionType: ${connectionType.name}, command: $command, args: $args, host: $host, port: $port, isActive: $isActive, isSecure: $isSecure, customEnvironment: $customEnvironment}';
  }
}
