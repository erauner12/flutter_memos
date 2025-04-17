import 'package:flutter/foundation.dart';

@immutable
class WorkbenchInstance {
  final String id; // UUID / CK recordName
  final String name; // “Work”, “Home”, “Inbox”, …
  final DateTime createdAt;
  // Optional flag for special UI treatment (e.g., "Inbox")
  final bool isSystemDefault;

  const WorkbenchInstance({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isSystemDefault = false, // Default to false
  });

  // --- Constants ---
  static const String defaultInstanceId = 'default';
  static const String defaultInstanceName = 'Workbench'; // Default name if needed elsewhere

  // --- Factory for Default ---
  // Creates the synthetic default instance used during migration
  factory WorkbenchInstance.defaultInstance() {
    return WorkbenchInstance(
      id: defaultInstanceId,
      name: defaultInstanceName,
      createdAt: DateTime.now(), // Use current time for creation
      isSystemDefault: true, // Mark the default as system default
    );
  }


  // --- JSON Serialization ---
  Map<String, dynamic> toJson() {
    return {
      // Do not include 'id' here as it's the CloudKit recordName
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isSystemDefault': isSystemDefault, // Include in JSON
    };
  }

  factory WorkbenchInstance.fromJson(
    Map<String, dynamic> json,
    String recordName,
  ) {
    // Handle potential type mismatches from CloudKit's string serialization
    final dynamic nameValue = json['name'];
    final dynamic createdAtValue = json['createdAt'];
    final dynamic isSystemDefaultValue = json['isSystemDefault'];

    // Ensure required fields are present and have the correct type
    if (nameValue is! String || createdAtValue is! String) {
      throw FormatException(
        'Invalid format for WorkbenchInstance JSON: Missing or invalid required fields (name, createdAt). Received: $json',
      );
    }

    DateTime? parsedCreatedAt;
    try {
      parsedCreatedAt = DateTime.parse(createdAtValue);
    } catch (e) {
      throw FormatException(
        'Invalid format for WorkbenchInstance JSON: Could not parse createdAt timestamp. Received: $createdAtValue',
      );
    }

    // Handle boolean parsing carefully (CloudKit might store as 'true'/'false' strings or 0/1)
    bool parsedIsSystemDefault = false;
    if (isSystemDefaultValue != null) {
      if (isSystemDefaultValue is bool) {
        parsedIsSystemDefault = isSystemDefaultValue;
      } else if (isSystemDefaultValue is String) {
        parsedIsSystemDefault = isSystemDefaultValue.toLowerCase() == 'true';
      } else if (isSystemDefaultValue is int) {
        parsedIsSystemDefault = isSystemDefaultValue == 1;
      } else if (isSystemDefaultValue is num) {
        parsedIsSystemDefault = isSystemDefaultValue == 1;
      }
      // If it's none of the above, keep default false.
    }


    return WorkbenchInstance(
      id: recordName, // Use the recordName passed from CloudKitService
      name: nameValue,
      createdAt: parsedCreatedAt,
      isSystemDefault: parsedIsSystemDefault, // Use parsed value
    );
  }

  // --- CopyWith ---
  WorkbenchInstance copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isSystemDefault,
  }) {
    return WorkbenchInstance(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isSystemDefault: isSystemDefault ?? this.isSystemDefault,
    );
  }

  // --- Equality and HashCode ---
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkbenchInstance &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.isSystemDefault == isSystemDefault;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      createdAt,
      isSystemDefault,
    );
  }

  // --- toString ---
  @override
  String toString() {
    return 'WorkbenchInstance(id: $id, name: $name, createdAt: $createdAt, isSystemDefault: $isSystemDefault)';
  }
}
