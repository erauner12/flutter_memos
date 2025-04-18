import 'package:flutter/foundation.dart';
import 'package:flutter_memos/todoist_api/lib/api.dart'
    as todoist; // Import todoist models

// Add CommentState enum
enum CommentState { normal, archived, deleted }

/// Represents a comment, adaptable for different sources (Memos, Todoist).
@immutable
class Comment {
  final String id; // Unique comment ID (source-specific format)
  final String? creatorId; // Source-specific user ID string
  final DateTime createdTs; // Timestamp converted to DateTime
  final DateTime? updatedTs; // Timestamp converted to DateTime
  final String? content; // The actual comment text (nullable)
  final List<Map<String, dynamic>> resources; // Raw resource list
  final List<Map<String, dynamic>> relations; // Raw relation list
  final String parentId; // The ID of the parent entity (Note ID or Task ID)
  final String serverId; // ID of the server config this comment belongs to
  final Object? attachment; // Todoist-specific attachment metadata
  final bool pinned; // Added pinned state
  final CommentState state; // Added state

  const Comment({
    required this.id,
    this.creatorId,
    required this.createdTs,
    this.updatedTs,
    this.content, // Nullable content
    this.resources = const [],
    this.relations = const [],
    required this.parentId,
    required this.serverId,
    this.attachment,
    this.pinned = false,
    this.state = CommentState.normal,
  });

  // Factory constructor from Memos API JSON
  factory Comment.fromMemosJson(
    Map<String, dynamic> json, {
    required String parentId, // Pass parent note ID for context
    required String serverId, // Pass server ID for context
  }) {
    // Helper function to parse state safely
    CommentState parseState(String? stateStr) {
      switch (stateStr?.toUpperCase()) {
        case 'ARCHIVED':
          return CommentState.archived;
        case 'NORMAL':
        default:
          return CommentState.normal;
      }
    }

    return Comment(
      id:
          json['name'] ??
          '', // Assuming 'name' is the unique identifier for Memos comment
      creatorId: json['creator'] ?? '',
      createdTs: DateTime.tryParse(json['createTime'] ?? '') ?? DateTime.now(),
      updatedTs: DateTime.tryParse(json['updateTime'] ?? '') ?? DateTime.now(),
      content: json['content'], // Keep potentially null
      resources: List<Map<String, dynamic>>.from(json['resources'] ?? []),
      relations: List<Map<String, dynamic>>.from(json['relations'] ?? []),
      parentId: parentId,
      serverId: serverId,
      attachment: null, // Memos doesn't have this field directly
      pinned: json['pinned'] ?? false, // Parse pinned state
      state: parseState(json['state']), // Parse state
    );
  }

  /// Factory constructor from Todoist Comment
  factory Comment.fromTodoistComment(
    todoist.Comment todoistComment,
    String? parentIdContext, {required String serverId},
  ) {
    // Determine the parentId: Use context first, then task ID, then project ID from comment
    final String effectiveParentId =
        parentIdContext ??
        todoistComment.taskId ??
        todoistComment.projectId ??
        '';
    // Use a default serverId or determine dynamically if needed
    const String defaultServerId = 'todoist_default';

    return Comment(
      id: todoistComment.id ?? '', // Ensure non-null ID
      creatorId:
          null, // Todoist API doesn't provide creator ID directly in comment object
      createdTs:
          todoistComment.postedAt ??
          DateTime.now(), // Ensure non-null creation time
      updatedTs:
          null, // Todoist comment object doesn't have an update timestamp
      content: todoistComment.content, // Keep potentially null
      resources: const [], // Map attachment if needed, structure differs
      relations: const [], // Not applicable to Todoist comments
      parentId: effectiveParentId,
      serverId: defaultServerId, // Use a consistent serverId for Todoist items
      attachment:
          todoistComment.attachment, // Store the raw attachment metadata
      pinned: false, // Todoist comments don't have a pinned state
      state: CommentState.normal, // Todoist comments don't have a state
    );
  }


  // Convert to JSON (mainly for potential caching or sending updates)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorId': creatorId,
      'createdTs': createdTs.toIso8601String(), // Use createdTs
      'updatedTs': updatedTs?.toIso8601String(), // Use updatedTs
      'content': content,
      'resources': resources,
      'relations': relations,
      'parentId': parentId,
      'serverId': serverId,
      'attachment': attachment,
      'pinned': pinned,
      'state': state.name,
    };
  }

  // copyWith method
  Comment copyWith({
    String? id,
    ValueGetter<String?>? creatorId, // Use ValueGetter for nullable fields
    DateTime? createdTs,
    ValueGetter<DateTime?>? updatedTs,
    ValueGetter<String?>? content, // Use ValueGetter
    List<Map<String, dynamic>>? resources,
    List<Map<String, dynamic>>? relations,
    String? parentId,
    String? serverId,
    ValueGetter<Object?>? attachment,
    bool? pinned, // Add pinned
    CommentState? state, // Add state
  }) {
    return Comment(
      id: id ?? this.id,
      creatorId: creatorId != null ? creatorId() : this.creatorId,
      createdTs: createdTs ?? this.createdTs,
      updatedTs: updatedTs != null ? updatedTs() : this.updatedTs,
      content: content != null ? content() : this.content,
      resources: resources ?? this.resources,
      relations: relations ?? this.relations,
      parentId: parentId ?? this.parentId,
      serverId: serverId ?? this.serverId,
      attachment: attachment != null ? attachment() : this.attachment,
      pinned: pinned ?? this.pinned, // Copy pinned
      state: state ?? this.state, // Copy state
    );
  }
}
