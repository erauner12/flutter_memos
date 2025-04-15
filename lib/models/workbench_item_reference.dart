import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart'; // For ServerType enum
import 'package:uuid/uuid.dart';

enum WorkbenchItemType { note, comment }

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
  final DateTime?
  lastOpenedTimestamp; // Optional: When the item was last opened via Workbench

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
    this.lastOpenedTimestamp, // Add to constructor
  });

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
    DateTime? lastOpenedTimestamp, // Add lastOpenedTimestamp
    bool clearLastOpenedTimestamp = false, // Helper to explicitly nullify
  }) {
    return WorkbenchItemReference(
      id: id ?? this.id,
      referencedItemId: referencedItemId ?? this.referencedItemId,
      referencedItemType: referencedItemType ?? this.referencedItemType,
      serverId: serverId ?? this.serverId,
      serverType: serverType ?? this.serverType,
      serverName: serverName ?? this.serverName,
      previewContent: previewContent ?? this.previewContent,
      addedTimestamp: addedTimestamp ?? this.addedTimestamp,
      parentNoteId: parentNoteId ?? this.parentNoteId,
      // Handle copying/clearing lastOpenedTimestamp
      lastOpenedTimestamp:
          clearLastOpenedTimestamp
              ? null
              : (lastOpenedTimestamp ?? this.lastOpenedTimestamp),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referencedItemId': referencedItemId,
      'referencedItemType': referencedItemType.name, // Store enum name as string
      'serverId': serverId,
      'serverType': serverType.name, // Store enum name as string
      'serverName': serverName,
      'previewContent': previewContent,
      'addedTimestamp': addedTimestamp.toIso8601String(), // Store DateTime as ISO string
      'parentNoteId': parentNoteId,
      // Add lastOpenedTimestamp, store as ISO string or null
      'lastOpenedTimestamp': lastOpenedTimestamp?.toIso8601String(),
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
      referencedItemType: tryParseEnum(WorkbenchItemType.values, json['referencedItemType'] as String?) ?? WorkbenchItemType.note, // Default to note
      serverId: json['serverId'] as String? ?? '',
      serverType: tryParseEnum(ServerType.values, json['serverType'] as String?) ?? ServerType.memos, // Default to memos
      serverName: json['serverName'] as String?,
      previewContent: json['previewContent'] as String?,
      addedTimestamp: DateTime.tryParse(json['addedTimestamp'] as String? ?? '') ?? DateTime.now(), // Default to now
      parentNoteId: json['parentNoteId'] as String?,
      // Parse lastOpenedTimestamp from ISO string or null
      lastOpenedTimestamp: DateTime.tryParse(
        json['lastOpenedTimestamp'] as String? ?? '',
      ),
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
        other.lastOpenedTimestamp ==
            lastOpenedTimestamp; // Add lastOpenedTimestamp check
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
      lastOpenedTimestamp, // Add lastOpenedTimestamp
    );
  }

  @override
  String toString() {
    // Include lastOpenedTimestamp in toString
    return 'WorkbenchItemReference(id: $id, refId: $referencedItemId, type: ${referencedItemType.name}, serverId: $serverId, serverType: ${serverType.name}, parentId: $parentNoteId, added: $addedTimestamp, lastOpened: $lastOpenedTimestamp)';
  }
}
