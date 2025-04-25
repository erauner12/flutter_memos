import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/models/focus_instance.dart'; // Correct import
import 'package:flutter_memos/models/server_config.dart'; // For ServerType enum (including todoist)
import 'package:flutter_memos/models/workbench_item_type.dart'; // Import the unified enum
import 'package:flutter_memos/utils/enum_utils.dart'; // Import the new helper
import 'package:uuid/uuid.dart'; // Import Uuid

// REMOVED local enum definition:
// enum WorkbenchItemType { note, comment, task }

@immutable
class WorkbenchItemReference {
  final String id; // Unique UUID for this reference itself
  final String
  referencedItemId; // ID of the original NoteItem, Comment, or Task
  final WorkbenchItemType
  referencedItemType; // 'note', 'comment', or 'task' - USES IMPORTED ENUM
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
  final String instanceId; // <-- Field is present
  final int sortOrder; // <-- New field for ordering

  // Transient fields (populated by WorkbenchNotifier, not persisted)
  final List<Comment> previewComments; // Store latest 1 or 2 comments
  final DateTime?
  referencedItemUpdateTime; // To store the update time of the referenced NoteItem/Task
  final DateTime overallLastUpdateTime; // Calculated dynamically

  const WorkbenchItemReference({
    required this.id,
    required this.referencedItemId,
    required this.referencedItemType, // USES IMPORTED ENUM
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
    required this.instanceId, // Ensure this is required and assigned
    this.sortOrder = 0, // Default sortOrder to 0 if not provided
  }) : overallLastUpdateTime =
           overallLastUpdateTime ??
           addedTimestamp; // Use passed value or default to added

  /// First (most-recent) preview comment, or `null` if none.
  Comment? get latestComment =>
      previewComments.isNotEmpty ? previewComments.first : null;

  WorkbenchItemReference copyWith({
    String? id,
    String? referencedItemId,
    WorkbenchItemType? referencedItemType, // USES IMPORTED ENUM
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
    String? instanceId, // <-- ADD instanceId parameter
    int? sortOrder, // <-- ADD sortOrder parameter
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
    }

    return WorkbenchItemReference(
      id: id ?? this.id,
      referencedItemId: referencedItemId ?? this.referencedItemId,
      referencedItemType:
          referencedItemType ?? this.referencedItemType, // USES IMPORTED ENUM
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
      instanceId: instanceId ?? this.instanceId, // <-- ASSIGN instanceId
      sortOrder: sortOrder ?? this.sortOrder, // <-- ASSIGN sortOrder
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Include 'id' for saving to SharedPreferences
      'id': id,
      'referencedItemId': referencedItemId,
      // Use describeEnum for consistent serialization
      // ignore: deprecated_member_use
      'referencedItemType': describeEnum(
        referencedItemType,
      ), // USES IMPORTED ENUM
      'serverId': serverId,
      'serverType': describeEnum(serverType),
      'serverName': serverName,
      'previewContent': previewContent,
      'addedTimestamp': addedTimestamp.toIso8601String(),
      'parentNoteId': parentNoteId,
      // DO NOT include transient fields (previewComments, referencedItemUpdateTime)
      'instanceId': instanceId, // <-- ADD instanceId to JSON
      'sortOrder': sortOrder, // <-- ADD sortOrder to JSON
    };
  }

  // Updated factory for loading from JSON (e.g., SharedPreferences)
  // recordName is now optional, primarily for CloudKit compatibility if ever needed again.
  factory WorkbenchItemReference.fromJson(
    Map<String, dynamic> json, [
    String? recordName, // Make recordName optional
  ]) {
    // Determine the ID: use json['id'], fallback to recordName, fallback to generating a new one?
    // For prefs loading, json['id'] should exist.
    String finalId = recordName ?? (json['id'] as String? ?? '');
    if (finalId.isEmpty) {
      // This case should ideally not happen if saved correctly with toJson()
      if (kDebugMode)
        print(
          '[WorkbenchItemReference.fromJson] Warning: Missing ID in JSON and no recordName provided. Generating new ID.',
        );
      finalId = const Uuid().v4(); // Or throw error?
    }

    // Use the new case-insensitive helper for enums
    // It returns the default value if parsing fails
    final parsedReferencedItemType = enumFromString<WorkbenchItemType>(
      WorkbenchItemType.values, // Use the imported enum's values
      json['referencedItemType'] as String?,
      defaultValue:
          WorkbenchItemType.unknown, // Default to unknown if parse fails
    );

    // Explicitly provide generic type <ServerType> and correct defaultValue type
    final parsedServerType = enumFromString<ServerType>(
      ServerType.values,
      json['serverType'] as String?,
      defaultValue: ServerType.memos, // Default to memos if parse fails
    );

    // Read instanceId from JSON, provide default for migration if missing/empty
    String instanceId = json['instanceId'] as String? ?? '';
    if (instanceId.isEmpty) {
      if (kDebugMode) {
        print(
          '[WorkbenchItemReference.fromJson] Warning: Missing or empty instanceId in record $finalId. Assigning default: ${FocusInstance.defaultInstanceId}.', // Use FocusInstance
        );
      }
      instanceId =
          FocusInstance.defaultInstanceId; // Assign default using FocusInstance
    }

    // Read sortOrder from JSON, default to 0 for migration if missing/invalid
    int sortOrder = 0; // Default value
    if (json['sortOrder'] != null) {
      sortOrder = int.tryParse(json['sortOrder'].toString()) ?? 0;
    } else {
      if (kDebugMode) {
        print(
          '[WorkbenchItemReference.fromJson] Warning: Missing sortOrder in record $finalId. Assigning default: 0.',
        );
      }
    }


    return WorkbenchItemReference(
      // Use the determined ID
      id: finalId,
      referencedItemId: json['referencedItemId'] as String? ?? '',
      referencedItemType:
          parsedReferencedItemType, // Use result from helper (imported enum)
      serverId: json['serverId'] as String? ?? '',
      serverType:
          parsedServerType, // Use result from helper (now correctly typed)
      serverName: json['serverName'] as String?,
      previewContent: json['previewContent'] as String?,
      addedTimestamp: DateTime.tryParse(json['addedTimestamp'] as String? ?? '') ?? DateTime.now(), // Default to now
      parentNoteId: json['parentNoteId'] as String?,
      instanceId: instanceId, // <-- ASSIGN instanceId (potentially defaulted)
      // DO NOT parse transient fields from JSON. They default to empty/null/addedTimestamp in constructor.
      sortOrder: sortOrder, // <-- ASSIGN sortOrder (potentially defaulted)
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkbenchItemReference &&
        other.id == id &&
        other.referencedItemId == referencedItemId &&
        other.referencedItemType == referencedItemType && // USES IMPORTED ENUM
        other.serverId == serverId &&
        other.serverType == serverType &&
        other.serverName == serverName &&
        other.previewContent == previewContent &&
        other.addedTimestamp == addedTimestamp &&
        other.parentNoteId == parentNoteId &&
        // Compare calculated time, but not the comment list or referencedItemUpdateTime itself
        other.overallLastUpdateTime == overallLastUpdateTime &&
        // Compare preview comments list (important for UI updates)
        listEquals(other.previewComments, previewComments) &&
        other.instanceId == instanceId && // <-- COMPARE instanceId
        other.sortOrder == sortOrder; // <-- COMPARE sortOrder
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      referencedItemId,
      referencedItemType, // USES IMPORTED ENUM
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
      instanceId, // <-- HASH instanceId
      sortOrder, // <-- HASH sortOrder
    );
  }

  @override
  String toString() {
    // Include transient fields for debugging
    final commentIds = previewComments.map((c) => c.id).join(', ');
    // <-- INCLUDE instanceId in toString
    // Use describeEnum for enums
    // <-- INCLUDE sortOrder in toString
    return 'WorkbenchItemReference(id: $id, instanceId: $instanceId, sortOrder: $sortOrder, refId: $referencedItemId, type: ${describeEnum(referencedItemType)}, serverId: $serverId, serverType: ${describeEnum(serverType)}, parentId: $parentNoteId, added: $addedTimestamp, lastActivity: $overallLastUpdateTime, comments: [$commentIds], refUpdate: $referencedItemUpdateTime)';
  }

  static void empty() {}
}
