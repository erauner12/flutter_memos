import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

@immutable
class FocusInstance {
  final String id; // UUID / CK recordName / Prefs ID
  final String name; // "Work”, "Home”, "Inbox”, …
  final DateTime createdAt;
  final bool isSystemDefault;

  static var defaultInstanceId;

  FocusInstance({
    String? id,
    required this.name,
    DateTime? createdAt,
    this.isSystemDefault = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Factory constructor for creating the default instance
  factory FocusInstance.defaultInstance() {
    return FocusInstance(
      id: 'default_focus_instance', // Use a fixed ID for the default
      name: 'Default Focus', // Or "Inbox", "General", etc.
      isSystemDefault: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0), // Ensure it sorts first if needed
    );
  }


  factory FocusInstance.fromJson(Map<String, dynamic> json) {
    return FocusInstance(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isSystemDefault: json['isSystemDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isSystemDefault': isSystemDefault,
    };
  }

  FocusInstance copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isSystemDefault,
  }) {
    return FocusInstance(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isSystemDefault: isSystemDefault ?? this.isSystemDefault,
    );
  }

  @override
  String toString() {
    return 'FocusInstance(id: $id, name: $name, createdAt: $createdAt, isSystemDefault: $isSystemDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FocusInstance &&
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
}
