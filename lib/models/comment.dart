import 'package:flutter_memos/api/lib/api.dart'; // Import V1Resource
import 'package:flutter_memos/utils/deep_equality.dart'; // Import for deep equality check

/// Enum for comment states
enum CommentState { normal, archived, deleted }

/// Model class for memo comments
class Comment {
  final String id;
  final String content;
  final String? creatorId;
  final int createTime; // Milliseconds since epoch
  final int? updateTime; // Milliseconds since epoch
  final CommentState state;
  final bool pinned;
  final List<V1Resource>? resources; // Add resources field

  Comment({
    required this.id,
    required this.content,
    this.creatorId,
    required this.createTime,
    this.updateTime,
    this.state = CommentState.normal,
    this.pinned = false,
    this.resources, // Add to constructor
  });

  /// Create a copy of this comment with some fields replaced
  Comment copyWith({
    String? id, // Allow copying ID as well
    String? content,
    String? creatorId, // Allow copying creatorId
    int? createTime, // Allow copying createTime
    int? updateTime, 
    CommentState? state,
    bool? pinned,
    List<V1Resource>? resources, // Add resources parameter
    bool clearUpdateTime = false, // Helper to explicitly nullify updateTime
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      creatorId: creatorId ?? this.creatorId,
      createTime: createTime ?? this.createTime,
      updateTime: clearUpdateTime ? null : (updateTime ?? this.updateTime),
      state: state ?? this.state,
      pinned: pinned ?? this.pinned,
      resources: resources ?? this.resources, // Assign resources
    );
  }

  /// Convert from JSON representation (assuming API conversion happens elsewhere)
  factory Comment.fromJson(Map<String, dynamic> json) {
    // This factory might not be directly used if conversion happens in ApiService,
    // but it's good practice to have it.
    return Comment(
      id: json['id'] as String,
      content: json['content'] as String,
      creatorId: json['creatorId'] as String?,
      createTime: json['createTime'] as int,
      updateTime: json['updateTime'] as int?,
      state: _parseState(json['state']),
      pinned: json['pinned'] as bool? ?? false,
      // Assuming resources are decoded elsewhere or handled during API conversion
      resources:
          json['resources'] != null
              ? (json['resources'] as List)
                  .map((r) => V1Resource.fromJson(r)!)
                  .toList()
              : null,
    );
  }

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'creatorId': creatorId,
      'createTime': createTime,
      'updateTime': updateTime,
      'state':
          state.toString().split('.').last, // Use simple string representation
      'pinned': pinned,
      // Serialize resources if needed (convert V1Resource list to JSON)
      'resources': resources?.map((r) => r.toJson()).toList(),
    };
  }

  /// Helper method to parse state from JSON
  static CommentState _parseState(dynamic stateValue) {
    if (stateValue == null) return CommentState.normal;

    if (stateValue is String) {
      switch (stateValue.toUpperCase()) {
        case 'ARCHIVED':
          return CommentState.archived;
        case 'DELETED': // Handle DELETED if needed, mapping to archived for now
          return CommentState.archived;
        case 'NORMAL':
        default:
          return CommentState.normal;
      }
    }

    // Handle potential enum values if API changes
    if (stateValue is CommentState) {
      return stateValue;
    }

    return CommentState.normal;
  }

  @override
  String toString() {
    return 'Comment(id: $id, content: "$content", creatorId: $creatorId, createTime: $createTime, updateTime: $updateTime, state: $state, pinned: $pinned, resources: ${resources?.length ?? 0})';
  }

  // Add deep equality check
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          creatorId == other.creatorId &&
          createTime == other.createTime &&
          updateTime == other.updateTime &&
          state == other.state &&
          pinned == other.pinned &&
          deepEquality.equals(resources, other.resources); // Use deep equality for lists

  @override
  int get hashCode => Object.hash(
    id,
    content,
    creatorId,
    createTime,
    updateTime,
    state,
    pinned,
    Object.hashAll(resources ?? []), // Hash list content
  );
}
