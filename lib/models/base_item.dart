import 'package:flutter/foundation.dart';

/// Enum to represent the type of a base item.
enum BaseItemType {
  note,
  task,
  // Potentially add more types like event, link, etc. in the future
}

/// Abstract class representing a generic item (Note, Task, etc.)
/// Provides a common interface for UI and logic layers.
@immutable
abstract class BaseItem {
  /// Unique identifier of the item within its source system.
  String get id;

  /// A concise title or summary of the item.
  /// For notes, might be the first line or derived title.
  /// For tasks, usually the task content itself.
  String get title;

  /// An optional longer description or body text.
  /// For notes, this might be the rest of the content or null.
  /// For tasks, this maps to the task's description field.
  String? get description;

  /// The creation timestamp of the item.
  DateTime get createdAt;

  /// The type of the item (e.g., note, task).
  BaseItemType get itemType;

  // Consider adding other potentially universal fields:
  // DateTime? get updatedAt;
  // String? get sourceServerId; // Identifier of the server/integration it came from
  // List<String>? get tags;
}
