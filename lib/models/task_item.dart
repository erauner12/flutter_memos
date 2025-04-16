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
    // Access the nested Due object within TaskDue
    final todoistDue = task.due?.dueObject;

    // Prefer datetime if available, else date, else null
    DateTime? parsedDueDate;
    if (todoistDue?.datetime != null) {
      parsedDueDate = todoistDue!.datetime;
    } else if (todoistDue?.date != null) {
      // Todoist date is just YYYY-MM-DD, parse it as such.
      // DateTime.tryParse might require time components, use specific format parsing if needed
      // For simplicity, assuming DateTime.tryParse handles 'YYYY-MM-DD' correctly,
      // or consider using a date formatting library if issues arise.
      // Let's ensure it parses correctly, assuming local timezone for date-only values.
      try {
        parsedDueDate = DateTime.parse(
          todoistDue!.date.toIso8601String().substring(0, 10),
        );
      } catch (e) {
        if (kDebugMode) {
          print("Error parsing todoist date string ${todoistDue!.date}: $e");
        }
        // Fallback or leave null
      }
    }

    return TaskItem(
      // Ensure ID is treated as String consistently
      id: task.id ?? '', // Todoist Task ID is String
      serverId: serverId,
      content: task.content ?? '',
      description: task.description ?? '', // Default to empty string if null
      isCompleted: task.isCompleted ?? false,
      priority: task.priority ?? 1,
      dueDate: parsedDueDate,
      dueString: todoistDue?.string,
      isRecurring: todoistDue?.isRecurring ?? false,
      labels: task.labels, // Ensure labels list is not null
      projectId: task.projectId,
      sectionId: task.sectionId,
      parentId: task.parentId,
      commentCount: task.commentCount ?? 0,
      createdAt:
          DateTime.tryParse(task.createdAt ?? '') ??
          DateTime.now(), // API provides string date
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
