// Use the app's Comment model
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/services/base_api_service.dart';
// Import todoist API models specifically for comment return types if needed,
// or rely on the app's Comment model if sufficient mapping exists.
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;


/// Interface for API services that primarily deal with Tasks (e.g., Todoist).
abstract class TaskApiService extends BaseApiService {

  // --- Task Operations ---
  Future<List<TaskItem>> listTasks({
    String? filter, // Implementation specific filter
    ServerConfig? targetServerOverride, // Likely not needed for Todoist global key
  });

  Future<TaskItem> getTask(
    String id, {
    ServerConfig? targetServerOverride,
  });

  Future<TaskItem> createTask(
    TaskItem task, { // Pass app model, implementation maps to API request
    ServerConfig? targetServerOverride,
  });

  Future<TaskItem> updateTask(
    String id,
    TaskItem task, { // Pass app model for updates
    ServerConfig? targetServerOverride,
  });

  Future<void> deleteTask(
    String id, {
    ServerConfig? targetServerOverride,
  });

  // --- Task Actions ---
  Future<void> completeTask(
    String id, {
    ServerConfig? targetServerOverride,
  });

  Future<void> reopenTask(
    String id, {
    ServerConfig? targetServerOverride,
  });

  // --- Task Comments ---
  // These specifically interact with task comments via the underlying API.
  // Overrides BaseApiService comment methods to provide task-specific context.

  @override
  Future<List<Comment>> listComments(
    String taskId, { // parentId is the taskId here
    ServerConfig? targetServerOverride,
  });

  @override
  Future<Comment> getComment(
    String commentId, { // commentId is sufficient
    ServerConfig? targetServerOverride,
  });

  @override
  Future<Comment> createComment(
    String taskId, // parentId is the taskId
    Comment comment, { // Use app's Comment model for input consistency
    ServerConfig? targetServerOverride,
    List<Map<String, dynamic>>? resources, // Optional attachments
  });

  @override
  Future<Comment> updateComment(
    String commentId, // commentId is sufficient
    Comment comment, { // Use app's Comment model
    ServerConfig? targetServerOverride,
  });

  @override
  Future<void> deleteComment(
    String taskId, // parentId is taskId, maybe needed for context/permissions?
    String commentId, {
    ServerConfig? targetServerOverride,
  });

  // Add other task-specific methods as needed (e.g., listProjects, listLabels)
  // These might not fit BaseApiService but are needed by the task UI.
  Future<List<todoist.Project>> listProjects();
  Future<List<todoist.Label>> listLabels();
  Future<List<todoist.Section>> listSections({String? projectId});
}
