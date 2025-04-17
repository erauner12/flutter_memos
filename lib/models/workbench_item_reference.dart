import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/models/server_config.dart'; // For ServerType enum (including todoist)
import 'package:uuid/uuid.dart';

// Ensure this includes task
enum WorkbenchItemType { note, comment, task }

@immutable
class WorkbenchItemReference {
  final String id; // Unique UUID for this reference itself
  final String
  referencedItemId; // ID of the original NoteItem, Comment, or Task
  final WorkbenchItemType referencedItemType; // 'note', 'comment', or 'task'
  final String
  serverId; // ServerConfig.id (for Memos/Blinko) or constant ID (for Todoist)
  // ServerType from server_config.dart (includes memos, blinko, todoist)
  final ServerType serverType;
  final String?
  serverName; // Optional server name at time of adding (or constant for Todoist)
  final String? previewContent; // Optional content snippet
  final DateTime addedTimestamp; // When the item was added
  final String?
  parentNoteId; // Optional: ID of the parent note (useful for comments)

  // Transient fields (populated by WorkbenchNotifier, not persisted)
  final List<Comment> previewComments; // Store latest 1 or 2 comments
  final DateTime?
  referencedItemUpdateTime; // To store the update time of the referenced NoteItem/Task
  final DateTime overallLastUpdateTime; // Calculated dynamically

  const WorkbenchItemReference({
    required this.id,
    required this.referencedItemId,
    required this.referencedItemType,
    required this.serverId,
    required this.serverType, // Can be memos, blinko, or todoist
    this.serverName,
    this.previewContent,
    required this.addedTimestamp,
    this.parentNoteId,
    // Transient fields
    this.previewComments = const [], // Default to empty list
    this.referencedItemUpdateTime,
    DateTime? overallLastUpdateTime,
    required String instanceId, // Allow passing calculated time
  }) : overallLastUpdateTime =
           overallLastUpdateTime ??
           addedTimestamp; // Use passed value or default to added

  // Helper to get the timestamp of the latest comment in the preview list
  DateTime? get _latestPreviewCommentTimestamp {
    if (previewComments.isEmpty) return null;
    // Assuming previewComments are sorted newest first
    final latestComment = previewComments.first;
    // Handle different comment models (Memos vs Todoist)
    return latestComment.updatedTs ?? latestComment.createdTs; // Memos/Blinko
    // Add Todoist logic if needed, e.g. latestComment.postedAt
  }

  /// First (most-recent) preview comment, or `null` if none.
  Comment? get latestComment =>
      previewComments.isNotEmpty ? previewComments.first : null;

  WorkbenchItemReference copyWith({
    String? id,
    String? referencedItemId,
    WorkbenchItemType? referencedItemType,
    String? serverId,
    ServerType? serverType,
    String? serverName,
    String? previewContent,
    DateTime? addedTimestamp,
    String? parentNoteId,
    // Pass the list directly, null means keep existing
    List<Comment>? previewComments,
    // Use ValueGetter for explicit null setting of single nullable fields
    ValueGetter<DateTime?>? referencedItemUpdateTime,
    // Allow explicitly passing the new calculated time, otherwise use existing
    DateTime? overallLastUpdateTime,
  }) {
    // Determine the values for transient fields
    final List<Comment> newPreviewComments =
        previewComments ?? this.previewComments;
    final DateTime? newReferencedItemUpdateTime =
        referencedItemUpdateTime != null
            ? referencedItemUpdateTime()
            : this.referencedItemUpdateTime;
    final DateTime newAddedTimestamp = addedTimestamp ?? this.addedTimestamp;

    // Calculate the new overallLastUpdateTime if not explicitly provided
    DateTime calculatedUpdateTime;
    if (overallLastUpdateTime != null) {
      calculatedUpdateTime = overallLastUpdateTime;
    } else {
      // Recalculate based on potentially updated components
      calculatedUpdateTime = newAddedTimestamp; // Start with added time

      if (newReferencedItemUpdateTime != null &&
          newReferencedItemUpdateTime.isAfter(calculatedUpdateTime)) {
        calculatedUpdateTime = newReferencedItemUpdateTime;
      }

      // Get timestamp of the latest comment *in the new list*
      DateTime? latestCommentTime;
      if (newPreviewComments.isNotEmpty) {
        final latestComment =
            newPreviewComments.first; // Assuming sorted newest first
        latestCommentTime = latestComment.updatedTs ?? latestComment.createdTs;
        // Add Todoist logic: latestCommentTime = latestComment.postedAt;
      }

      if (latestCommentTime != null &&
          latestCommentTime.isAfter(calculatedUpdateTime)) {
        calculatedUpdateTime = latestCommentTime;
      }

      // If the original overall time was later than any component, keep it
      // (This case might be less relevant now if overallLastUpdateTime is always recalculated)
      // if (this.overallLastUpdateTime.isAfter(calculatedUpdateTime)) {
      //   calculatedUpdateTime = this.overallLastUpdateTime;
      // }
    }

    return WorkbenchItemReference(
      id: id ?? this.id,
      referencedItemId: referencedItemId ?? this.referencedItemId,
      referencedItemType: referencedItemType ?? this.referencedItemType,
      serverId: serverId ?? this.serverId,
      serverType:
          serverType ?? this.serverType, // Can be memos, blinko, or todoist
      serverName: serverName ?? this.serverName,
      previewContent: previewContent ?? this.previewContent,
      addedTimestamp: newAddedTimestamp,
      parentNoteId: parentNoteId ?? this.parentNoteId,
      // Assign potentially updated transient fields
      previewComments: newPreviewComments,
      referencedItemUpdateTime: newReferencedItemUpdateTime,
      // Assign the final calculated or provided overallLastUpdateTime
      overallLastUpdateTime: calculatedUpdateTime,
      instanceId: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referencedItemId': referencedItemId,
      'referencedItemType':
          referencedItemType.name, // Supports 'note', 'comment', 'task'
      'serverId': serverId,
      'serverType': serverType.name, // Supports 'memos', 'blinko', 'todoist'
      'serverName': serverName,
      'previewContent': previewContent,
      'addedTimestamp': addedTimestamp.toIso8601String(),
      'parentNoteId': parentNoteId,
      // DO NOT include transient fields (previewComments, referencedItemUpdateTime)
    };
  }

  factory WorkbenchItemReference.fromJson(
    Map<String, dynamic> json,
    String recordName,
  ) {
    // Helper to parse enums safely
    T? tryParseEnum<T>(List<T> enumValues, String? name) {
      if (name == null) return null;
      try {
        // Ensure this comparison works for enums where T is the enum type itself
        return enumValues.firstWhere((e) => (e as dynamic).name == name);
      } catch (_) {
        if (kDebugMode) {
          print(
            '[WorkbenchItemReference.fromJson] Warning: Enum value "$name" not found in ${T.toString()}.',
          );
        }
        return null; // Return null if name doesn't match any enum value
      }
    }

    // Parse ServerType - crucial that it handles 'todoist' correctly
    final parsedServerType = tryParseEnum(
      ServerType.values,
      json['serverType'] as String?,
    );

    return WorkbenchItemReference(
      id: json['id'] as String? ?? const Uuid().v4(),
      referencedItemId: json['referencedItemId'] as String? ?? '',
      referencedItemType:
          tryParseEnum(
            WorkbenchItemType.values,
            json['referencedItemType'] as String?,
          ) ??
          WorkbenchItemType.note, // Default to note
      serverId: json['serverId'] as String? ?? '',
      // Use parsed ServerType, default to memos if parsing failed or was null
      serverType: parsedServerType ?? ServerType.memos,
      serverName: json['serverName'] as String?,
      previewContent: json['previewContent'] as String?,
      addedTimestamp: DateTime.tryParse(json['addedTimestamp'] as String? ?? '') ?? DateTime.now(), // Default to now
      parentNoteId: json['parentNoteId'] as String?,
      instanceId: '',
      // DO NOT parse transient fields from JSON. They default to empty/null/addedTimestamp in constructor.
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkbenchItemReference &&
        other.id == id &&
        other.referencedItemId == referencedItemId &&
        other.referencedItemType == referencedItemType &&
        other.serverId == serverId &&
        other.serverType == serverType &&
        other.serverName == serverName &&
        other.previewContent == previewContent &&
        other.addedTimestamp == addedTimestamp &&
        other.parentNoteId == parentNoteId &&
        // Compare calculated time, but not the comment list or referencedItemUpdateTime itself
        other.overallLastUpdateTime == overallLastUpdateTime &&
        // Compare preview comments list (important for UI updates)
        listEquals(other.previewComments, previewComments);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      referencedItemId,
      referencedItemType,
      serverId,
      serverType,
      serverName,
      previewContent,
      addedTimestamp,
      parentNoteId,
      // Hash calculated time
      overallLastUpdateTime,
      // Hash the preview comments list
      Object.hashAll(previewComments),
      // DO NOT hash referencedItemUpdateTime
    );
  }

  get instanceId => null;

  @override
  String toString() {
    // Include transient fields for debugging
    final commentIds = previewComments.map((c) => c.id).join(', ');
    return 'WorkbenchItemReference(id: $id, refId: $referencedItemId, type: ${referencedItemType.name}, serverId: $serverId, serverType: ${serverType.name}, parentId: $parentNoteId, added: $addedTimestamp, lastActivity: $overallLastUpdateTime, comments: [$commentIds], refUpdate: $referencedItemUpdateTime)';
  }
}
