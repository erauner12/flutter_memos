import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/base_item.dart'; // Import BaseItem
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;

/// Enum for task status (open/completed)
enum TaskStatus { open, completed }

/// App-level model for a Todoist task
@immutable
class TaskItem implements BaseItem {
  // Implement BaseItem
  @override
  final String id; // Todoist task ID (string)
  final String serverId; // Identifier for the "Todoist integration" instance
  final String content; // Todoist task content
  @override
  final String? description; // Todoist task description
  final bool isCompleted;
  final int priority; // 1-4
  final DateTime? dueDate; // Parsed due date/datetime
  final String? dueString; // Original due string
  final bool isRecurring;
  final List<String> labels; // List of label names
  final String? projectId;
  final String? sectionId;
  final String? parentId; // For sub-tasks
  final int commentCount;
  @override
  final DateTime createdAt; // Already exists
  final String? creatorId;
  final String? assigneeId;

  const TaskItem({
    required this.id,
    required this.serverId,
    required this.content,
    this.description,
    required this.isCompleted,
    required this.priority,
    this.dueDate,
    this.dueString,
    required this.isRecurring,
    required this.labels,
    this.projectId,
    this.sectionId,
    this.parentId,
    required this.commentCount,
    required this.createdAt,
    this.creatorId,
    this.assigneeId,
  });

  // --- BaseItem Implementation ---

  // 'id' getter is implicitly provided by the final field 'id'
  // 'createdAt' getter is implicitly provided by the final field 'createdAt'
  // 'description' getter is implicitly provided by the final field 'description'

  @override
  String get title => content; // Use task content as the title

  @override
  BaseItemType get itemType => BaseItemType.task; // This is a Task

  // --- End BaseItem Implementation ---


  /// Factory to create TaskItem from a todoist.Task
  factory TaskItem.fromTodoistTask(todoist.Task task, String serverId) {
    final todoistDue = task.due; // Access TaskDue directly

    DateTime? parsedDueDate;
    if (todoistDue?.dueObject?.datetime != null) {
      try {
        // Todoist datetime includes timezone info (e.g., "2016-09-01T12:00:00Z" or "...T12:00:00")
        // DateTime.parse handles ISO 8601 format including 'Z' for UTC
        parsedDueDate = todoistDue!.dueObject!.datetime;
      } catch (e) {
        if (kDebugMode) {
          print(
            "Error parsing todoist datetime string ${todoistDue?.dueObject?.datetime}: $e",
          );
        }
      }
    } else if (todoistDue?.dueObject?.date != null) {
      // Todoist date is just YYYY-MM-DD. Parse as local date at midnight.
      try {
        parsedDueDate = todoistDue!.dueObject!.date;
      } catch (e) {
        if (kDebugMode) {
          print(
            "Error parsing todoist date string ${todoistDue?.dueObject?.date}: $e",
          );
        }
      }
    }

    DateTime parsedCreatedAt;
    try {
      // Todoist createdAt is ISO 8601 string "YYYY-MM-DDTHH:MM:SS.ssssssZ"
      parsedCreatedAt = DateTime.parse(task.createdAt ?? '');
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing todoist createdAt string ${task.createdAt}: $e");
      }
      parsedCreatedAt = DateTime.now(); // Fallback to now
    }


    return TaskItem(
      id: task.id ?? '', // Todoist Task ID is String
      serverId: serverId,
      content: task.content ?? '',
      description: task.description ?? '', // Use description field directly
      isCompleted: task.isCompleted ?? false,
      priority: task.priority ?? 1,
      dueDate: parsedDueDate,
      dueString: todoistDue?.dueObject?.string,
      isRecurring: todoistDue?.dueObject?.isRecurring ?? false,
      labels: task.labels, // Labels can't be null based on compiler message
      projectId: task.projectId,
      sectionId: task.sectionId,
      parentId: task.parentId,
      commentCount: task.commentCount ?? 0,
      createdAt: parsedCreatedAt, // Use parsed createdAt
      creatorId: task.creatorId,
      assigneeId: task.assigneeId,
    );
  }

  /// Convert to JSON for potential caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serverId': serverId,
      'content': content,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'dueString': dueString,
      'isRecurring': isRecurring,
      'labels': labels,
      'projectId': projectId,
      'sectionId': sectionId,
      'parentId': parentId,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
      'creatorId': creatorId,
      'assigneeId': assigneeId,
    };
  }

  /// Create from JSON (for potential caching)
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      serverId: json['serverId'] as String,
      content: json['content'] as String,
      description:
          json['description'] as String?, // Matches BaseItem description
      isCompleted: json['isCompleted'] as bool,
      priority: json['priority'] as int,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      dueString: json['dueString'] as String?,
      isRecurring: json['isRecurring'] as bool,
      labels: (json['labels'] as List<dynamic>).cast<String>(),
      projectId: json['projectId'] as String?,
      sectionId: json['sectionId'] as String?,
      parentId: json['parentId'] as String?,
      commentCount: json['commentCount'] as int,
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ), // Matches BaseItem createdAt
      creatorId: json['creatorId'] as String?,
      assigneeId: json['assigneeId'] as String?,
    );
  }

  TaskItem copyWith({
    String? id,
    String? serverId,
    String? content,
    // Allow description to be explicitly set to null
    ValueGetter<String?>? description,
    bool? isCompleted,
    int? priority,
    DateTime? dueDate,
    String? dueString,
    bool? isRecurring,
    List<String>? labels,
    String? projectId,
    String? sectionId,
    String? parentId,
    int? commentCount,
    DateTime? createdAt,
    String? creatorId,
    String? assigneeId,
  }) {
    return TaskItem(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      content: content ?? this.content,
      description: description != null ? description() : this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueString: dueString ?? this.dueString,
      isRecurring: isRecurring ?? this.isRecurring,
      labels: labels ?? this.labels,
      projectId: projectId ?? this.projectId,
      sectionId: sectionId ?? this.sectionId,
      parentId: parentId ?? this.parentId,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      creatorId: creatorId ?? this.creatorId,
      assigneeId: assigneeId ?? this.assigneeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          serverId == other.serverId &&
          content == other.content &&
          description == other.description &&
          isCompleted == other.isCompleted &&
          priority == other.priority &&
          dueDate == other.dueDate &&
          dueString == other.dueString &&
          isRecurring == other.isRecurring &&
          listEquals(labels, other.labels) &&
          projectId == other.projectId &&
          sectionId == other.sectionId &&
          parentId == other.parentId &&
          commentCount == other.commentCount &&
          createdAt == other.createdAt &&
          creatorId == other.creatorId &&
          assigneeId == other.assigneeId;

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    content,
    description,
    isCompleted,
    priority,
    dueDate,
    dueString,
    isRecurring,
    Object.hashAll(labels), // Use Object.hashAll for list
    projectId,
    sectionId,
    parentId,
    commentCount,
    createdAt,
    creatorId,
    assigneeId,
  );

  @override
  String toString() {
    return 'TaskItem(id: $id, isCompleted: $isCompleted, title: ${title.substring(0, (title.length > 20 ? 20 : title.length))}...)';
  }
}
