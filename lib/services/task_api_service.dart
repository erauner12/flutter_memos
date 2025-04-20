// Use the app's Comment model
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/services/base_api_service.dart';
// Removed todoist import


/// Interface for API services that primarily deal with Tasks (e.g., Vikunja).
abstract class TaskApiService extends BaseApiService {

  // --- Task Operations ---
  Future<List<TaskItem>> listTasks({
    String? filter, // Implementation specific filter
    ServerConfig? targetServerOverride,
  });

  Future<TaskItem> getTask(
    String id, { // Keep String ID for interface consistency, parse in implementation
    ServerConfig? targetServerOverride,
  });

  Future<TaskItem> createTask(
    TaskItem task, { // Pass app model, implementation maps to API request
    ServerConfig? targetServerOverride,
    int? projectId, // Add optional projectId if needed for creation
  });

  Future<TaskItem> updateTask(
    String id, // Keep String ID for interface consistency
    TaskItem task, { // Pass app model for updates
    ServerConfig? targetServerOverride,
  });

  Future<void> deleteTask(
    String id, { // Keep String ID for interface consistency
    ServerConfig? targetServerOverride,
  });

  // --- Task Actions ---
  Future<void> completeTask(
    String id, { // Keep String ID for interface consistency
    ServerConfig? targetServerOverride,
  });

  Future<void> reopenTask(
    String id, { // Keep String ID for interface consistency
    ServerConfig? targetServerOverride,
  });

  // --- Task Comments ---
  // These specifically interact with task comments via the underlying API.
  // Overrides BaseApiService comment methods to provide task-specific context.

  @override
  Future<List<Comment>> listComments(
    String taskId, { // parentId is the taskId here (keep String ID)
    ServerConfig? targetServerOverride,
  });

  @override
  Future<Comment> getComment(
    String commentId, { // commentId is sufficient (keep String ID)
    ServerConfig? targetServerOverride,
  });

  @override
  Future<Comment> createComment(
    String taskId, // parentId is the taskId (keep String ID)
    Comment comment, { // Use app's Comment model for input consistency
    ServerConfig? targetServerOverride,
    List<Map<String, dynamic>>? resources, // Optional attachments
  });

  @override
  Future<Comment> updateComment(
    String commentId, // commentId is sufficient (keep String ID)
    Comment comment, { // Use app's Comment model
    ServerConfig? targetServerOverride,
  });

  @override
  Future<void> deleteComment(
    String taskId, // parentId is taskId (keep String ID)
    String commentId, { // Keep String ID
    ServerConfig? targetServerOverride,
  });

  // Removed Todoist-specific methods
}
