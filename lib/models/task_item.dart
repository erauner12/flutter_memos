import 'package:flutter/foundation.dart';
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;

/// Enum for task status (open/completed)
enum TaskStatus { open, completed }

/// App-level model for a Todoist task
@immutable
class TaskItem {
  final String id; // Todoist task ID (string)
  final String serverId; // Identifier for the "Todoist integration" instance
  final String content; // Todoist task content
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
  final DateTime createdAt;
  final String? creatorId;
  final String? assigneeId;

  // Add other relevant fields as needed

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

  /// Factory to create TaskItem from a todoist.Task
  factory TaskItem.fromTodoistTask(todoist.Task task, String serverId) {
    // Prefer datetime if available, else date, else null
    DateTime? dueDate;
    if (task.due?.dueObject?.datetime != null) {
      dueDate = task.due!.dueObject!.datetime;
    } else if (task.due?.dueObject?.date != null) {
      dueDate = task.due!.dueObject!.date;
    }

    return TaskItem(
      id: task.id?.toString() ?? '',
      serverId: serverId,
      content: task.content ?? '',
      description: task.description,
      isCompleted: task.isCompleted ?? false,
      priority: task.priority ?? 1,
      dueDate: dueDate,
      dueString: task.due?.dueObject?.string,
      isRecurring: task.due?.dueObject?.isRecurring ?? false,
      labels: task.labels,
      projectId: task.projectId,
      sectionId: task.sectionId,
      parentId: task.parentId,
      commentCount: task.commentCount ?? 0,
      createdAt: DateTime.tryParse(task.createdAt ?? '') ?? DateTime.now(),
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
      description: json['description'] as String?,
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
      createdAt: DateTime.parse(json['createdAt'] as String),
      creatorId: json['creatorId'] as String?,
      assigneeId: json['assigneeId'] as String?,
    );
  }

  TaskItem copyWith({
    String? id,
    String? serverId,
    String? content,
    String? description,
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
      description: description ?? this.description,
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
}
