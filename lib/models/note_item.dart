import 'package:collection/collection.dart'; // For listEquals
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/base_item.dart'; // Import BaseItem

// Enums matching Memos structure for simplicity
enum NoteState { normal, archived }

enum NoteVisibility { public, private, protected }

// Optional: Add NoteKind if differentiating Cache/Vault in the model
// enum NoteKind { cache, vault, other }

@immutable
class NoteItem implements BaseItem {
  // Implement BaseItem
  @override
  final String id; // Server-assigned ID (string format for consistency)
  final String content;
  final bool pinned;
  final NoteState state;
  final NoteVisibility visibility;
  final DateTime createTime;
  final DateTime updateTime;
  final DateTime displayTime;
  final List<String> tags;
  final List<Map<String, dynamic>>? resources;
  final List<Map<String, dynamic>>? relations;
  final String? creatorId;
  final String? parentId;
  final DateTime? startDate;
  final DateTime? endDate;
  // final NoteKind kind; // Add if using model-based differentiation

  const NoteItem({
    required this.id,
    required this.content,
    required this.pinned,
    required this.state,
    required this.visibility,
    required this.createTime,
    required this.updateTime,
    required this.displayTime,
    this.tags = const [],
    this.resources = const [],
    this.relations = const [],
    this.creatorId,
    this.parentId,
    this.startDate,
    this.endDate,
    // this.kind = NoteKind.other, // Default kind if added
  });

  // --- BaseItem Implementation ---

  @override
  String get title {
    // Use the first non-empty line as title, fallback to first 50 chars
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
    if (lines.isNotEmpty) {
      return lines.first.trim();
    }
    // Fallback if content is empty or only whitespace lines
    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }

  @override
  String? get description {
    // Return null for description for now, or potentially the rest of the content?
    // Let's return null for simplicity, UI can show full content if needed.
    return null;
    // Alternative: return content excluding the first line if it exists
    // final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    // if (lines.length > 1) {
    //   return lines.skip(1).join('\n').trim();
    // }
    // return null;
  }

  @override
  DateTime get createdAt => createTime; // Map createTime to createdAt

  @override
  BaseItemType get itemType => BaseItemType.note; // This is a Note

  // --- End BaseItem Implementation ---


  NoteItem copyWith({
    String? id,
    String? content,
    bool? pinned,
    NoteState? state,
    NoteVisibility? visibility,
    DateTime? createTime,
    DateTime? updateTime,
    DateTime? displayTime,
    List<String>? tags,
    List<Map<String, dynamic>>? resources,
    List<Map<String, dynamic>>? relations,
    String? creatorId,
    String? parentId,
    DateTime? startDate,
    DateTime? endDate,
    // NoteKind? kind, // Add if using model-based differentiation
  }) {
    return NoteItem(
      id: id ?? this.id,
      content: content ?? this.content,
      pinned: pinned ?? this.pinned,
      state: state ?? this.state,
      visibility: visibility ?? this.visibility,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      displayTime: displayTime ?? this.displayTime,
      tags: tags ?? this.tags,
      resources: resources ?? this.resources,
      relations: relations ?? this.relations,
      creatorId: creatorId ?? this.creatorId,
      parentId: parentId ?? this.parentId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      // kind: kind ?? this.kind, // Add if using model-based differentiation
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is NoteItem &&
        other.id == id &&
        other.content == content &&
        other.pinned == pinned &&
        other.state == state &&
        other.visibility == visibility &&
        other.createTime == createTime &&
        other.updateTime == updateTime &&
        other.displayTime == displayTime &&
        listEquals(other.tags, tags) &&
        listEquals(other.resources, resources) &&
        listEquals(other.relations, relations) &&
        other.creatorId == creatorId &&
        other.parentId == parentId &&
        other.startDate == startDate &&
        other.endDate == endDate;
        // && other.kind == kind; // Add if using model-based differentiation
  }

  @override
  int get hashCode {
    final listEquality = const DeepCollectionEquality();
    return Object.hash(
      id,
      content,
      pinned,
      state,
      visibility,
      createTime,
      updateTime,
      displayTime,
      listEquality.hash(tags),
      listEquality.hash(resources),
      listEquality.hash(relations),
      creatorId,
      parentId,
      startDate,
      endDate,
      // kind, // Add if using model-based differentiation
    );
  }

  @override
  String toString() {
    return 'NoteItem(id: $id, state: ${state.name}, pinned: $pinned, startDate: $startDate, title: ${title.substring(0, (title.length > 20 ? 20 : title.length))}...)';
  }
}
