import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/models/server_config.dart'; // For ServerType enum
import 'package:uuid/uuid.dart';

enum WorkbenchItemType { note, comment, task }

@immutable
class WorkbenchItemReference {
  final String id; // Unique UUID for this reference itself
  final String referencedItemId; // ID of the original NoteItem or Comment
  final WorkbenchItemType referencedItemType; // 'note' or 'comment'
  final String serverId; // ServerConfig.id of the server this item belongs to
  final ServerType serverType; // Memos or Blinko
  final String? serverName; // Optional server name at time of adding
  final String? previewContent; // Optional content snippet
  final DateTime addedTimestamp; // When the item was added
  final String?
  parentNoteId; // Optional: ID of the parent note (useful for comments)

  // Transient fields (populated by WorkbenchNotifier, not persisted)
  final Comment? latestComment;
  final DateTime?
  referencedItemUpdateTime; // To store the update time of the referenced NoteItem
  final DateTime overallLastUpdateTime; // Calculated dynamically

  const WorkbenchItemReference({
    required this.id,
    required this.referencedItemId,
    required this.referencedItemType,
    required this.serverId,
    required this.serverType,
    this.serverName,
    this.previewContent,
    required this.addedTimestamp,
    this.parentNoteId,
    // Transient fields
    this.latestComment,
    this.referencedItemUpdateTime,
    DateTime? overallLastUpdateTime, // Allow passing calculated time
  }) : overallLastUpdateTime =
           overallLastUpdateTime ??
           addedTimestamp; // Use passed value or default to added

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
    // Use ValueGetter for explicit null setting of transient fields
    ValueGetter<Comment?>? latestComment,
    ValueGetter<DateTime?>? referencedItemUpdateTime,
    // Allow explicitly passing the new calculated time, otherwise use existing
    DateTime? overallLastUpdateTime,
  }) {
    // Determine the values for transient fields
    final Comment? newLatestComment =
        latestComment != null ? latestComment() : this.latestComment;
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
      // Use createdTs and updatedTs from Comment model
      final DateTime? commentTime =
          newLatestComment?.updatedTs ?? newLatestComment?.createdTs;
      if (commentTime != null) {
        // No need to convert from milliseconds, it's already DateTime
        if (commentTime.isAfter(calculatedUpdateTime)) {
          calculatedUpdateTime = commentTime;
        }
      }
      // If the original overall time was later than any component, keep it (e.g., if manually set)
      // Check against this.overallLastUpdateTime only if overallLastUpdateTime parameter was null
      if (this.overallLastUpdateTime.isAfter(calculatedUpdateTime)) {
        calculatedUpdateTime = this.overallLastUpdateTime;
      }
    }


    return WorkbenchItemReference(
      id: id ?? this.id,
      referencedItemId: referencedItemId ?? this.referencedItemId,
      referencedItemType: referencedItemType ?? this.referencedItemType,
      serverId: serverId ?? this.serverId,
      serverType: serverType ?? this.serverType,
      serverName: serverName ?? this.serverName,
      previewContent: previewContent ?? this.previewContent,
      addedTimestamp:
          newAddedTimestamp, // Use potentially updated addedTimestamp
      parentNoteId: parentNoteId ?? this.parentNoteId,
      // Assign potentially updated transient fields
      latestComment: newLatestComment,
      referencedItemUpdateTime: newReferencedItemUpdateTime,
      // Assign the final calculated or provided overallLastUpdateTime
      overallLastUpdateTime: calculatedUpdateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referencedItemId': referencedItemId,
      'referencedItemType':
          referencedItemType
              .name, // Store enum name as string, now supports 'task'
      'serverId': serverId,
      'serverType': serverType.name, // Store enum name as string
      'serverName': serverName,
      'previewContent': previewContent,
      'addedTimestamp': addedTimestamp.toIso8601String(), // Store DateTime as ISO string
      'parentNoteId': parentNoteId,
      // DO NOT include transient fields: latestComment, referencedItemUpdateTime, overallLastUpdateTime
    };
  }

  factory WorkbenchItemReference.fromJson(Map<String, dynamic> json) {
    // Helper to parse enums safely
    T? tryParseEnum<T>(List<T> enumValues, String? name) {
      if (name == null) return null;
      try {
        return enumValues.firstWhere((e) => (e as dynamic).name == name);
      } catch (_) {
        return null; // Return null if name doesn't match any enum value
      }
    }

    return WorkbenchItemReference(
      id: json['id'] as String? ?? const Uuid().v4(), // Generate ID if missing
      referencedItemId: json['referencedItemId'] as String? ?? '',
      referencedItemType:
          tryParseEnum(
            WorkbenchItemType.values,
            json['referencedItemType'] as String?,
          ) ??
          WorkbenchItemType.note, // Now supports 'task'
      serverId: json['serverId'] as String? ?? '',
      serverType: tryParseEnum(ServerType.values, json['serverType'] as String?) ?? ServerType.memos, // Default to memos
      serverName: json['serverName'] as String?,
      previewContent: json['previewContent'] as String?,
      addedTimestamp: DateTime.tryParse(json['addedTimestamp'] as String? ?? '') ?? DateTime.now(), // Default to now
      parentNoteId: json['parentNoteId'] as String?,
      // DO NOT parse transient fields from JSON. They default to null/addedTimestamp in constructor.
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
        // Compare calculated time, but not the comment object or referencedItemUpdateTime itself
        other.overallLastUpdateTime == overallLastUpdateTime;
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
      // DO NOT hash latestComment or referencedItemUpdateTime
    );
  }

  @override
  String toString() {
    // Include transient fields for debugging
    return 'WorkbenchItemReference(id: $id, refId: $referencedItemId, type: ${referencedItemType.name}, serverId: $serverId, serverType: ${serverType.name}, parentId: $parentNoteId, added: $addedTimestamp, lastActivity: $overallLastUpdateTime, comment: ${latestComment != null ? latestComment!.id : 'none'}, noteUpdate: $referencedItemUpdateTime)';
  }
}
