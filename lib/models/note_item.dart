import 'package:collection/collection.dart'; // For listEquals
import 'package:flutter/foundation.dart';

// Enums matching Memos structure for simplicity, adapt if Blinko differs significantly
enum NoteState { normal, archived }
enum NoteVisibility { public, private, protected }

@immutable
class NoteItem {
  final String id; // Server-assigned ID (string format for consistency)
  final String content;
  final bool pinned;
  final NoteState state;
  final NoteVisibility visibility;
  final DateTime createTime;
  final DateTime updateTime;
  final DateTime displayTime;
  final List<String> tags; // Assuming tags are simple strings for now
  final List<dynamic> resources; // Placeholder - needs specific mapping
  final List<dynamic> relations; // Placeholder - needs specific mapping
  final String? creatorId; // String ID of the creator user
  final String? parentId; // String ID of the parent memo/note

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
  });

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
    List<dynamic>? resources,
    List<dynamic>? relations,
    String? creatorId,
    String? parentId,
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
        other.parentId == parentId;
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
      );
  }

  @override
  String toString() {
    return 'NoteItem(id: $id, state: ${state.name}, pinned: $pinned, content: ${content.substring(0, (content.length > 20 ? 20 : content.length))}...)';
  }
}
