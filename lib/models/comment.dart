import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/user.dart';
import 'package:flutter_memos/todoist_api/lib/api.dart'
    as todoist; // Import todoist models

/// Represents a comment, adaptable for different sources (Memos, Todoist).
@immutable
class Comment {
  final String
  id; // Unique comment ID (source-specific format, e.g., "notes/1/comments/1" or Todoist ID)
  final String?
  creatorId; // Source-specific user ID string (e.g., "users/1" or null for Todoist)
  final DateTime createdTs; // Timestamp converted to DateTime
  final DateTime?
  updatedTs; // Timestamp converted to DateTime (nullable for Todoist?)
  final String? content; // The actual comment text (nullable)
  final List<Map<String, dynamic>>
  resources; // Raw resource list (source-specific format)
  final List<Map<String, dynamic>>
  relations; // Raw relation list (source-specific format)
  final User? creator; // Optional: Populated creator details (Memos concept)
  final String parentId; // The ID of the parent entity (Note ID or Task ID)
  final String serverId; // ID of the server config this comment belongs to
  final Object? attachment; // Todoist-specific attachment metadata

  const Comment({
    required this.id,
    this.creatorId,
    required this.createdTs,
    this.updatedTs,
    this.content, // Made nullable
    this.resources = const [],
    this.relations = const [],
    this.creator,
    required this.parentId,
    required this.serverId,
    this.attachment, // Added for Todoist
  });

  // Factory constructor from Memos API JSON
  factory Comment.fromMemosJson(
    Map<String, dynamic> json, {
    required String parentId, // Pass parent note ID for context
    required String serverId, // Pass server ID for context
    User? creatorDetails, // Optional pre-fetched user details
  }) {
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
      creator: creatorDetails, // Use passed-in details if available
      parentId: parentId,
      serverId: serverId,
      attachment: null, // Memos doesn't have this field directly
    );
  }

  /// Factory constructor from Todoist Comment
  factory Comment.fromTodoistComment(
    todoist.Comment todoistComment,
    String? parentIdContext,
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
      creator: null, // Not applicable
      parentId: effectiveParentId,
      serverId: defaultServerId, // Use a consistent serverId for Todoist items
      attachment:
          todoistComment.attachment, // Store the raw attachment metadata
    );
  }


  // Convert to JSON (mainly for potential caching or sending updates)
  // Note: This needs to be adapted depending on the target API if sending updates
  Map<String, dynamic> toJson() {
    // Generic representation, might need tailoring for specific API update payloads
    return {
      'id': id, // Use 'id' consistently for local storage
      'creatorId': creatorId,
      'createdTs': createdTs.toIso8601String(),
      'updatedTs': updatedTs?.toIso8601String(),
      'content': content,
      'resources': resources,
      'relations': relations,
      'parentId': parentId,
      'serverId': serverId,
      'attachment': attachment, // Include if needed for local caching
      // 'creator': creator?.toJson(), // Avoid nested objects if not needed
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
    ValueGetter<User?>? creator,
    String? parentId,
    String? serverId,
    ValueGetter<Object?>? attachment,
  }) {
    return Comment(
      id: id ?? this.id,
      creatorId: creatorId != null ? creatorId() : this.creatorId,
      createdTs: createdTs ?? this.createdTs,
      updatedTs: updatedTs != null ? updatedTs() : this.updatedTs,
      content: content != null ? content() : this.content,
      resources: resources ?? this.resources,
      relations: relations ?? this.relations,
      creator: creator != null ? creator() : this.creator,
      parentId: parentId ?? this.parentId,
      serverId: serverId ?? this.serverId,
      attachment: attachment != null ? attachment() : this.attachment,
    );
  }
}
