import 'package:flutter/foundation.dart';
// Removed Todoist import
// import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;

// Import Vikunja models for the new factory
import 'package:vikunja_flutter_api/vikunja_api/lib/api.dart' as vikunja;

// Add CommentState enum
enum CommentState { normal, archived, deleted }

/// Represents a comment, adaptable for different sources (Memos, Vikunja Tasks).
@immutable
class Comment {
  final String id; // Unique comment ID (source-specific format)
  final String? creatorId; // Source-specific user ID string
  final DateTime createdTs; // Timestamp converted to DateTime
  final DateTime? updatedTs; // Timestamp converted to DateTime
  final String? content; // The actual comment text (nullable)
  final List<Map<String, dynamic>>
  resources; // Raw resource list (e.g., Memos attachments)
  final List<Map<String, dynamic>>
  relations; // Raw relation list (Memos specific)
  final String parentId; // The ID of the parent entity (Note ID or Task ID)
  final String serverId; // ID of the server config this comment belongs to
  // Removed Todoist attachment field
  // final Object? attachment;
  final bool
  pinned; // Added pinned state (Memos specific, may not apply to Vikunja)
  final CommentState state; // Added state (Memos specific)

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
    // this.attachment, // Removed
    this.pinned =
        false, // Default to false, Vikunja comments likely don't support pinning
    this.state = CommentState.normal, // Default to normal
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
      // attachment: null, // Removed
      pinned: json['pinned'] ?? false, // Parse pinned state
      state: parseState(json['state']), // Parse state
    );
  }

  /// Factory constructor from Vikunja Task Comment
  factory Comment.fromVikunjaTaskComment(
    vikunja.ModelsTaskComment vComment, {
    required String taskId, // Parent ID is the Task ID
    required String serverId, // Server ID for context
  }) {
    return Comment(
      id: vComment.id?.toString() ?? '', // Vikunja comment ID
      creatorId: vComment.author?.id?.toString(), // Vikunja author ID
      createdTs:
          (vComment.created as DateTime?) ??
          DateTime.now(), // Vikunja created timestamp
      updatedTs: DateTime.tryParse(
        vComment.updated ?? '',
      ), // Vikunja updated timestamp
      content: vComment.comment, // Vikunja comment content field
      resources:
          const [], // Vikunja comments don't have Memos-style resources directly
      relations: const [], // Not applicable to Vikunja comments
      parentId: taskId, // The task this comment belongs to
      serverId: serverId, // The server config ID
      // attachment: null, // Removed
      pinned: false, // Vikunja comments don't support pinning
      state: CommentState.normal, // Vikunja comments don't have state
    );
  }

  // Removed fromTodoistComment factory
  /*
  factory Comment.fromTodoistComment(
    todoist.Comment todoistComment,
    String? parentIdContext, {
    required String serverId,
  }) {
    // ... removed implementation ...
  }
  */


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
      // 'attachment': attachment, // Removed
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
    // ValueGetter<Object?>? attachment, // Removed
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
      // attachment: attachment != null ? attachment() : this.attachment, // Removed
      pinned: pinned ?? this.pinned, // Copy pinned
      state: state ?? this.state, // Copy state
    );
  }
}
