import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/base_item.dart'; // Import BaseItem
// Use the correct package import for the Vikunja API client
// import 'package:vikunja_flutter_api/api.dart' as vikunja; // Incorrect path
import 'package:vikunja_flutter_api/vikunja_api/lib/api.dart' as vikunja;

/// Enum for task status (open/completed)
enum TaskStatus { open, completed } // Keep this enum for now, might be useful

/// App-level model for a Vikunja task
@immutable
class TaskItem implements BaseItem {
  // Implement BaseItem
  // final String id; // Todoist task ID (string) - REMOVED
  // @override
  // final int id; // Vikunja task ID (int) - CHANGED // Original field
  final int _id; // Internal Vikunja task ID (int)
  @override
  String get id => _id.toString(); // String getter for BaseItem compatibility
  int get internalId => _id; // Getter for the actual int ID when needed

  // final String serverId; // Identifier for the "Todoist integration" instance - REMOVED
  // final String content; // Todoist task content - REMOVED
  @override
  final String title; // Vikunja task title - RENAMED from content
  @override
  final String? description; // Vikunja task description - KEPT
  // final bool isCompleted; - REMOVED
  final bool done; // Vikunja task done status - RENAMED from isCompleted
  final int?
      priority; // Vikunja priority (optional, keep for now) - KEPT (type check?)
  final DateTime? dueDate; // Parsed due date/datetime - KEPT
  // final String? dueString; // Original due string - REMOVED
  // final bool isRecurring; - REMOVED (Vikunja has repeatAfter/repeatMode)
  // final List<String> labels; // List of label names - REMOVED (handle via Vikunja labels later)
  // final String? projectId; - REMOVED (handle via Vikunja projects later)
  // final String? sectionId; - REMOVED (handle via Vikunja buckets/sections later)
  // final String? parentId; // For sub-tasks - REMOVED (handle via Vikunja relations later)
  // final int commentCount; - REMOVED (can derive if needed)
  @override
  final DateTime createdAt; // Already exists - KEPT
  // final String? creatorId; - REMOVED (handle via Vikunja createdBy later)
  // final String? assigneeId; - REMOVED (handle via Vikunja assignees later)
  final DateTime? updatedAt; // Add Vikunja updated timestamp
  final int? projectId; // Add Vikunja project ID
  final int? bucketId; // Add Vikunja bucket ID
  final num? percentDone; // Add Vikunja percent done

  const TaskItem({
    required int id, // Keep accepting 'id' externally for simplicity
    // serverId removed
    required this.title, // RENAMED from content
    this.description,
    required this.done, // RENAMED from isCompleted
    this.priority,
    this.dueDate,
    // dueString removed
    // isRecurring removed
    // labels removed
    // projectId removed (now added as int?)
    // sectionId removed
    // parentId removed
    // commentCount removed
    required this.createdAt,
    // creatorId removed
    // assigneeId removed
    this.updatedAt, // ADDED
    this.projectId, // ADDED
    this.bucketId, // ADDED
    this.percentDone, // ADDED
  }) : _id = id; // Initialize internal _id

  // --- BaseItem Implementation ---

  // 'id' getter is implicitly provided by the final field 'id' (type checked against BaseItem)

  // 'createdAt' getter is implicitly provided by the final field 'createdAt'
  // 'description' getter is implicitly provided by the final field 'description'

  // title getter removed as 'title' is now a direct field

  @override
  BaseItemType get itemType => BaseItemType.task; // This is a Task

  // --- End BaseItem Implementation ---

  /// Factory to create TaskItem from a vikunja.ModelsTask
  /// This will typically be called within the VikunjaApiService
  factory TaskItem.fromVikunjaTask(
    vikunja.ModelsTask vTask,
    String serverId, // Use correct type
    // String serverId /* Keep serverId for multi-server support */, // Removed serverId parameter
  ) {
    DateTime? parsedDueDate;
    // Vikunja uses String for dates, parse them safely
    if (vTask.dueDate != null && vTask.dueDate!.isNotEmpty) {
      try {
        // Attempt to parse ISO8601 format
        parsedDueDate = DateTime.parse(vTask.dueDate!);
      } catch (e) {
        if (kDebugMode) {
          print("Error parsing Vikunja dueDate string ${vTask.dueDate}: $e");
        }
        // Optionally try other formats if needed
      }
    }

    DateTime? parsedCreatedAt;
    if (vTask.created != null && vTask.created!.isNotEmpty) {
      try {
        parsedCreatedAt = DateTime.parse(vTask.created!);
      } catch (e) {
        if (kDebugMode) {
          print("Error parsing Vikunja created string ${vTask.created}: $e");
        }
        // Fallback or handle error
      }
    }

    DateTime? parsedUpdatedAt;
    if (vTask.updated != null && vTask.updated!.isNotEmpty) {
      try {
        parsedUpdatedAt = DateTime.parse(vTask.updated!);
      } catch (e) {
        if (kDebugMode) {
          print("Error parsing Vikunja updated string ${vTask.updated}: $e");
        }
      }
    }

    return TaskItem(
      id: vTask.id ?? 0, // Vikunja Task ID is int, provide default
      // serverId: serverId, // Removed
      title: vTask.title ?? '',
      description: vTask.description,
      done: vTask.done ?? false,
      priority: vTask.priority,
      dueDate: parsedDueDate,
      createdAt: parsedCreatedAt ?? DateTime.now(), // Provide a fallback if parsing fails
      updatedAt: parsedUpdatedAt,
      projectId: vTask.projectId,
      bucketId: vTask.bucketId,
      percentDone: vTask.percentDone,
      // Map other fields as needed: labels, assignees, etc.
    );
  }

  // Remove the old fromTodoistTask factory
  /*
  factory TaskItem.fromTodoistTask(todoist.Task task, String serverId) {
    // ... existing implementation ...
  }
  */

  /// Convert to JSON for potential caching (adjust fields)
  Map<String, dynamic> toJson() {
    return {
      'id': _id, // Use internal int _id
      // serverId removed
      'title': title, // RENAMED
      'description': description,
      'done': done, // RENAMED
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      // dueString removed
      // isRecurring removed
      // labels removed
      // projectId removed (now added as int?)
      // sectionId removed
      // parentId removed
      // commentCount removed
      'createdAt': createdAt.toIso8601String(),
      // creatorId removed
      // assigneeId removed
      'updatedAt': updatedAt?.toIso8601String(), // ADDED
      'projectId': projectId, // ADDED
      'bucketId': bucketId, // ADDED
      'percentDone': percentDone, // ADDED
    };
  }

  /// Create from JSON (for potential caching - adjust fields)
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as int, // Read int id
      // serverId removed
      title: json['title'] as String, // RENAMED
      description: json['description'] as String?,
      done: json['done'] as bool, // RENAMED
      priority: json['priority'] as int?, // Allow null
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'])
          : null, // Use tryParse
      // dueString removed
      // isRecurring removed
      // labels removed
      // projectId removed (now added as int?)
      // sectionId removed
      // parentId removed
      // commentCount removed
      createdAt: DateTime.parse(json['createdAt'] as String), // Assume valid format
      // creatorId removed
      // assigneeId removed
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) // Use tryParse
          : null, // ADDED
      projectId: json['projectId'] as int?, // ADDED
      bucketId: json['bucketId'] as int?, // ADDED
      percentDone: json['percentDone'] as num?, // ADDED
    );
  }

  TaskItem copyWith({
    int? id, // Accept int id
    // serverId removed
    String? title, // RENAMED
    ValueGetter<String?>? description,
    bool? done, // RENAMED
    int? priority,
    DateTime? dueDate,
    // dueString removed
    // isRecurring removed
    // labels removed
    // projectId removed (now added as int?)
    // sectionId removed
    // parentId removed
    // commentCount removed
    DateTime? createdAt,
    // creatorId removed
    // assigneeId removed
    DateTime? updatedAt, // ADDED
    int? projectId, // ADDED
    int? bucketId, // ADDED
    num? percentDone, // ADDED
  }) {
    return TaskItem(
      id: id ?? _id, // Use provided id or existing _id
      // serverId removed
      title: title ?? this.title, // RENAMED
      description: description != null ? description() : this.description,
      done: done ?? this.done, // RENAMED
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      // dueString removed
      // isRecurring removed
      // labels removed
      // projectId removed (now added as int?)
      // sectionId removed
      // parentId removed
      // commentCount removed
      createdAt: createdAt ?? this.createdAt,
      // creatorId removed
      // assigneeId removed
      updatedAt: updatedAt ?? this.updatedAt, // ADDED
      projectId: projectId ?? this.projectId, // ADDED
      bucketId: bucketId ?? this.bucketId, // ADDED
      percentDone: percentDone ?? this.percentDone, // ADDED
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItem &&
          runtimeType == other.runtimeType &&
          _id == other._id && // Use internal _id for comparison
          // serverId removed
          title == other.title && // RENAMED
          description == other.description &&
          done == other.done && // RENAMED
          priority == other.priority &&
          dueDate == other.dueDate &&
          // dueString removed
          // isRecurring removed
          // listEquals(labels, other.labels) removed
          // projectId removed (now added as int?)
          // sectionId removed
          // parentId removed
          // commentCount removed
          createdAt == other.createdAt &&
          // creatorId removed
          // assigneeId removed
          updatedAt == other.updatedAt && // ADDED
          projectId == other.projectId && // ADDED
          bucketId == other.bucketId && // ADDED
          percentDone == other.percentDone; // ADDED

  @override
  int get hashCode => Object.hash(
    _id, // Use internal _id
    // serverId removed
    title, // RENAMED
    description,
    done, // RENAMED
    priority,
    dueDate,
    // dueString removed
    // isRecurring removed
    // Object.hashAll(labels) removed
    // projectId removed (now added as int?)
    // sectionId removed
    // parentId removed
    // commentCount removed
    createdAt,
    // creatorId removed
    // assigneeId removed
    updatedAt, // ADDED
    projectId, // ADDED
    bucketId, // ADDED
    percentDone, // ADDED
  );

  @override
  String toString() {
    // Use 'done' instead of 'isCompleted'
    final titlePreview = title.length > 20 ? '${title.substring(0, 20)}...' : title;
    // Use the public String id getter here for display consistency if needed,
    // or keep using _id if int representation is preferred for debugging.
    return 'TaskItem(id: $id, done: $done, title: $titlePreview)';
  }
}
