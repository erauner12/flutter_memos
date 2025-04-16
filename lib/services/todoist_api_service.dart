import 'dart:io'; // Import for stderr
import 'dart:typed_data'; // For Uint8List

import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_memos/models/comment.dart'; // Use app's Comment model
import 'package:flutter_memos/models/server_config.dart'; // Use ServerConfig if needed for overrides (though likely not for Todoist)
import 'package:flutter_memos/models/task_item.dart'; // Use app's TaskItem model
import 'package:flutter_memos/services/task_api_service.dart'; // Implement the interface
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;

/// Service class for interacting with the Todoist API
///
/// This class wraps the auto-generated Todoist API client
/// and provides convenient methods for common operations,
/// implementing the TaskApiService interface.
class TodoistApiService implements TaskApiService {
  // Singleton pattern
  static final TodoistApiService _instance = TodoistApiService._internal();
  factory TodoistApiService() => _instance;

  // API client instances
  late todoist.ApiClient _apiClient;
  late todoist.TasksApi _tasksApi;
  late todoist.ProjectsApi _projectsApi;
  late todoist.SectionsApi _sectionsApi;
  late todoist.LabelsApi _labelsApi;
  late todoist.CommentsApi _commentsApi;

  // Configuration
  final String _baseUrl = 'https://api.todoist.com/rest/v2';
  String _authToken = '';

  // Configuration and logging options
  // Disable verbose logging by default to avoid MCP stdio issues
  static bool verboseLogging =
      false; // Cannot use kDebugMode in non-Flutter env
  @override
  String get apiBaseUrl => _baseUrl;

  TodoistApiService._internal() {
    // Initialize with empty token - will need to be configured later
    _initializeClient('');
  }

  /// Configure the Todoist API service with authentication token.
  /// Implements BaseApiService.configureService. The baseUrl is ignored for Todoist.
  @override
  Future<void> configureService({
    required String baseUrl, // Ignored, Todoist URL is fixed
    required String authToken,
  }) async {
    // Make async to match Future<void> return type
    if (_authToken == authToken && _authToken.isNotEmpty) {
      if (verboseLogging) {
        // Use stderr.writeln for server-side logging
        stderr.writeln(
          '[TodoistApiService] Configuration unchanged.',
        );
      }
      return;
    }

    _authToken = authToken;
    _initializeClient(_authToken);

    if (verboseLogging) {
      // Use stderr.writeln for server-side logging
      stderr.writeln(
        '[TodoistApiService] Configured with ${authToken.isNotEmpty ? 'valid' : 'empty'} token',
      );
    }
  }

  void _initializeClient(String token) {
    try {
      _apiClient = todoist.ApiClient(
        basePath: _baseUrl,
        authentication: todoist.HttpBearerAuth()..accessToken = token,
      );

      // Initialize API endpoints
      _tasksApi = todoist.TasksApi(_apiClient);
      _projectsApi = todoist.ProjectsApi(_apiClient);
      _sectionsApi = todoist.SectionsApi(_apiClient);
      _labelsApi = todoist.LabelsApi(_apiClient);
      _commentsApi = todoist.CommentsApi(_apiClient);

      if (verboseLogging) {
        // Use stderr.writeln for server-side logging
        stderr.writeln(
          '[TodoistApiService] Client initialized successfully',
        );
      }
    } catch (e) {
      // Use stderr.writeln for errors
      stderr.writeln(
        '[TodoistApiService] Error initializing client: $e',
      );
      throw Exception('Failed to initialize Todoist API client: $e');
    }
  }


  // --- BaseApiService Implementation ---

  // apiBaseUrl is already defined as a class property getter

  @override
  bool get isConfigured => _authToken.isNotEmpty;

  // configureService is already implemented above.

  @override
  Future<bool> checkHealth() async {
    if (!isConfigured) return false;

    try {
      // A lightweight call to check if the API is working and token is valid
      await _projectsApi.getAllProjects();
      return true;
    } catch (e) {
      if (verboseLogging) {
        // Use stderr.writeln for server-side logging
        stderr.writeln('[TodoistApiService] Health check failed: $e');
      }
      return false;
    }
  }

  // --- TaskApiService Implementation ---

  // --- Task Operations ---

  /// Get all active tasks, mapped to TaskItem
  @override
  Future<List<TaskItem>> listTasks({
    String? filter,
    ServerConfig? targetServerOverride, // Ignored for Todoist global key
  }) async {
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Getting active tasks (listTasks)');
    }

    try {
      // Use the underlying _tasksApi.getActiveTasks
      // Currently, the direct method takes specific filters, not a generic string.
      // We might need to enhance this if complex filtering is required.
      // For now, let's assume the 'filter' param isn't directly mappable
      // or pass it if the generated API supports it.
      // The generated getActiveTasks takes projectId, sectionId, label, filter, lang, ids.
      final tasks = await _tasksApi.getActiveTasks(filter: filter);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${tasks?.length ?? 0} raw tasks',
        );
      }

      // Map todoist.Task to TaskItem, providing a dummy serverId for now
      // TODO: Decide how to handle serverId for Todoist tasks if needed later
      final String serverId =
          targetServerOverride?.id ?? "todoist_default"; // Example
      final taskItems =
          tasks
              ?.map((task) => TaskItem.fromTodoistTask(task, serverId))
              .toList() ??
          [];

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Mapped to ${taskItems.length} TaskItems',
        );
      }

      return taskItems;

    } catch (e) {
      _handleApiError('Error getting active tasks (listTasks)', e);
      rethrow;
    }
  }


  /// Get a single active task by its ID, mapped to TaskItem
  @override
  Future<TaskItem> getTask(
    String id, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Getting active task by ID (getTask): $id',
      );
    }

    try {
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        stderr.writeln('[TodoistApiService] Error: Invalid task ID format provided: "$id"');
        throw ArgumentError('Invalid task ID format: $id');
      }
      final task = await _tasksApi.getActiveTask(taskIdInt);

      if (task == null) {
        throw Exception('Task with ID $id not found.');
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved raw task: ${task.content}',
        );
      }

      // Map to TaskItem
      final String serverId =
          targetServerOverride?.id ?? "todoist_default"; // Example
      final taskItem = TaskItem.fromTodoistTask(task, serverId);

      if (verboseLogging) {
        stderr.writeln('[TodoistApiService] Mapped to TaskItem');
      }

      return taskItem;

    } catch (e) {
      _handleApiError('Error getting task by ID $id (getTask)', e);
      rethrow; // Rethrow to signal failure
    }
  }


  /// Create a new task from a TaskItem model
  @override
  Future<TaskItem> createTask(
    TaskItem taskItem, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Creating task from TaskItem: ${taskItem.content}',
      );
    }

    // Map TaskItem back to the structure expected by todoist.CreateTaskRequest
    final request = todoist.CreateTaskRequest(
      content: taskItem.content,
      description: taskItem.description,
      projectId: taskItem.projectId,
      sectionId: taskItem.sectionId,
      parentId: taskItem.parentId,
      // order: taskItem.order, // TaskItem doesn't have order yet
      labels: taskItem.labels,
      priority: taskItem.priority,
      // Map TaskItem due date/string back to Todoist format if needed
      // This requires careful mapping based on how due info is stored in TaskItem
      dueString: taskItem.dueString, // Simplest mapping if string is stored
      // dueDate: taskItem.dueDate?.toIso8601String().substring(0, 10), // If only date
      // dueDatetime: taskItem.dueDate?.toIso8601String(), // If datetime
      // duration: taskItem.durationAmount, // If duration info is added to TaskItem
      // durationUnit: taskItem.durationUnit,
      assigneeId: taskItem.assigneeId,
    );


    try {
      final createdTodoistTask = await _tasksApi.createTask(request);

      if (createdTodoistTask == null) {
        throw Exception("Task creation returned null from API");
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Raw Task created successfully with ID: ${createdTodoistTask.id}',
        );
      }

      // Map the result back to TaskItem
      final String serverId = targetServerOverride?.id ?? "todoist_default";
      final createdTaskItem = TaskItem.fromTodoistTask(
        createdTodoistTask,
        serverId,
      );

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Mapped created task back to TaskItem',
        );
      }

      return createdTaskItem;

    } catch (e) {
      _handleApiError('Error creating task from TaskItem', e);
      rethrow;
    }
  }


  /// Update an existing task using a TaskItem model
  @override
  Future<TaskItem> updateTask(
    String id,
    TaskItem taskItem, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Updating task from TaskItem: $id');
    }

    // Map TaskItem fields to todoist.UpdateTaskRequest
    final request = todoist.UpdateTaskRequest(
      content:
          taskItem
              .content, // Only include fields that were actually changed? API likely handles partial updates.
      description: taskItem.description,
      labels: taskItem.labels,
      priority: taskItem.priority,
      dueString: taskItem.dueString,
      // dueDate: taskItem.dueDate?.toIso8601String().substring(0, 10),
      // dueDatetime: taskItem.dueDate?.toIso8601String(),
      // duration: taskItem.durationAmount,
      // durationUnit: taskItem.durationUnit,
      assigneeId: taskItem.assigneeId,
    );

    try {
      // The generated updateTask returns the updated Task object
      final updatedTodoistTask = await _tasksApi.updateTask(id, request);

      if (updatedTodoistTask == null) {
        // API V2 Update Task returns 204 No Content on success, not the task object.
        // So, we need to fetch the task again to return the updated TaskItem.
        if (verboseLogging) {
          stderr.writeln(
            '[TodoistApiService] Task $id updated successfully (204). Fetching updated task...',
          );
        }
        return await getTask(id); // Fetch the updated task data
      } else {
        // Should not happen based on API V2 spec for POST /tasks/{taskId}
        stderr.writeln(
          '[TodoistApiService] Warning: updateTask API returned unexpected Task object.',
        );
        final String serverId = targetServerOverride?.id ?? "todoist_default";
        return TaskItem.fromTodoistTask(updatedTodoistTask, serverId);
      }

    } catch (e) {
      _handleApiError('Error updating task $id from TaskItem', e);
      rethrow;
    }
  }


  /// Delete a task
  @override
  Future<void> deleteTask(
    String id, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Deleting task (deleteTask): $id');
    }

    try {
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        throw ArgumentError('Invalid task ID format: $id');
      }
      await _tasksApi.deleteTask(taskIdInt);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Task $id deleted successfully',
        );
      }
    } catch (e) {
      _handleApiError('Error deleting task $id', e);
      rethrow;
    }
  }


  // --- Task Actions ---

  /// Close (complete) a task
  @override
  Future<void> completeTask(
    String id, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Closing task (completeTask): $id');
    }

    try {
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        throw ArgumentError('Invalid task ID format: $id');
      }
      await _tasksApi.closeTask(taskIdInt);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Task $id closed successfully',
        );
      }
    } catch (e) {
      _handleApiError('Error closing task $id', e);
      rethrow;
    }
  }


  /// Reopen a task
  @override
  Future<void> reopenTask(
    String id, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Reopening task (reopenTask): $id');
    }

    try {
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        throw ArgumentError('Invalid task ID format: $id');
      }
      await _tasksApi.reopenTask(taskIdInt);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Task $id reopened successfully',
        );
      }
    } catch (e) {
      _handleApiError('Error reopening task $id', e);
      rethrow;
    }
  }


  // --- Task Comments (Implementing BaseApiService/TaskApiService Comment Methods) ---

  /// List comments for a specific task
  @override
  Future<List<Comment>> listComments(
    String taskId, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Getting comments for task $taskId (listComments)',
      );
    }

    try {
      final comments = await _commentsApi.getAllComments(taskId: taskId);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${comments?.length ?? 0} raw comments for task $taskId',
        );
      }

      // Map todoist.Comment to app's Comment model
      final commentItems =
          comments
              ?.map(
                (c) => Comment.fromTodoistComment(
                  c,
                  taskId,
                ), // Pass taskId as context
              )
              .toList() ??
          [];

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Mapped to ${commentItems.length} Comment models',
        );
      }

      return commentItems;
    } catch (e) {
      _handleApiError('Error getting comments for task $taskId', e);
      rethrow;
    }
  }

  /// Get a single comment by its ID
  @override
  Future<Comment> getComment(
    String commentId, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Getting comment by ID (getComment): $commentId',
      );
    }
    try {
      final commentIdInt = int.tryParse(commentId);
      if (commentIdInt == null) {
        throw ArgumentError('Invalid comment ID format: $commentId');
      }
      final todoistComment = await _commentsApi.getComment(commentIdInt);

      if (todoistComment == null) {
        throw Exception('Comment with ID $commentId not found.');
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved raw comment: ${todoistComment.content}',
        );
      }

      // Map to app's Comment model
      // Pass the taskId from the fetched comment as context
      final commentItem = Comment.fromTodoistComment(
        todoistComment,
        todoistComment.taskId,
      );

      if (verboseLogging) {
        stderr.writeln('[TodoistApiService] Mapped comment to Comment model');
      }

      return commentItem;
    } catch (e) {
      _handleApiError('Error getting comment by ID $commentId', e);
      rethrow;
    }
  }


  /// Create a comment for a task
  @override
  Future<Comment> createComment(
    String taskId,
    Comment comment, {
    ServerConfig? targetServerOverride /* Ignored */,
    List<Map<String, dynamic>>? resources /* TODO: Handle attachments */,
  }) async {
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Creating comment for task $taskId');
    }

    // TODO: Handle attachment mapping from 'resources' map to todoist.CreateCommentAttachmentParameter
    todoist.CreateCommentAttachmentParameter? attachmentParam;
    // if (resources != null && resources.isNotEmpty) {
    //   // Logic to upload resource first if needed by Todoist, or map existing resource info
    //   // This depends heavily on how attachments are handled (upload via separate endpoint?)
    //   stderr.writeln('[TodoistApiService] Warning: Comment attachments not yet implemented.');
    // }

    try {
      // Call the underlying API method
      final createdTodoistComment = await _commentsApi.createComment(
        comment.content ?? '', // Pass empty string if content is null
        taskId: taskId,
        attachment: attachmentParam,
      );

      if (createdTodoistComment == null) {
        throw Exception("Comment creation returned null from API");
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Raw comment created successfully with ID: ${createdTodoistComment.id}',
        );
      }

      // Map back to app's Comment model
      final createdCommentItem = Comment.fromTodoistComment(
        createdTodoistComment,
        taskId, // Provide taskId context
      );

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Mapped created comment back to Comment model',
        );
      }

      return createdCommentItem;

    } catch (e) {
      _handleApiError('Error creating comment for task $taskId', e);
      rethrow;
    }
  }


  /// Update an existing comment
  @override
  Future<Comment> updateComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Updating comment $commentId');
    }

    try {
      // Call the underlying API. Note: Todoist API uses POST for update here.
      final updatedTodoistComment = await _commentsApi.updateComment(
        commentId,
        comment.content ?? '', // Pass empty string if content is null
      );

      if (updatedTodoistComment == null) {
        // If the API returns 204 No Content or similar successful non-body response
        // We need to fetch the updated comment details.
        // However, the Todoist V2 spec says POST /comments/{id} *returns* the updated comment object.
        // Let's assume the spec is correct and it returns the object.
        // If testing reveals it returns 204, we'd need to call getComment here.
        throw Exception("Comment update returned null unexpectedly from API");
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Raw comment updated successfully: ${updatedTodoistComment.id}',
        );
      }

      // Map back to app's Comment model
      // Pass taskId from the updated comment object as context
      final updatedCommentItem = Comment.fromTodoistComment(
        updatedTodoistComment,
        updatedTodoistComment.taskId,
      );

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Mapped updated comment back to Comment model',
        );
      }

      return updatedCommentItem;
    } catch (e) {
      _handleApiError('Error updating comment $commentId', e);
      rethrow;
    }
  }


  /// Delete a comment
  @override
  Future<void> deleteComment(
    String taskId, // parentId is taskId - may not be needed by API call itself
    String commentId, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Deleting comment $commentId (task $taskId)',
      );
    }

    try {
      final commentIdInt = int.tryParse(commentId);
      if (commentIdInt == null) {
        throw ArgumentError('Invalid comment ID format: $commentId');
      }
      // The API call only needs the comment ID
      await _commentsApi.deleteComment(commentIdInt);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Comment $commentId deleted successfully',
        );
      }
    } catch (e) {
      _handleApiError('Error deleting comment $commentId', e);
      rethrow;
    }
  }


  // --- Resource Methods (Implementing BaseApiService) ---

  @override
  Future<Map<String, dynamic>> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  }) async {
    // Todoist handles attachments via the comment creation/update calls,
    // often requiring the resource to be uploaded elsewhere first (or using their specific upload mechanism if available).
    // This base method might not be directly applicable or needs significant adaptation.
    stderr.writeln(
      '[TodoistApiService] uploadResource not directly supported. Attachments are linked via comments.',
    );
    throw UnimplementedError(
      "Todoist handles resource uploads differently (via comment attachments).",
    );
    // If Todoist had a separate resource upload endpoint, implement it here.
  }

  @override
  Future<Uint8List> getResourceData(
    String resourceIdentifier, {
    ServerConfig? targetServerOverride,
  }) async {
    // Fetching raw resource data might involve parsing comment attachments
    // and retrieving the file from the `file_url` provided in the attachment metadata.
    stderr.writeln(
      '[TodoistApiService] getResourceData requires parsing comment attachments and fetching from URL.',
    );
    throw UnimplementedError(
      "Getting raw resource data requires fetching from attachment URL.",
    );
    // Implementation would involve:
    // 1. Finding the comment/attachment associated with resourceIdentifier.
    // 2. Getting the file_url from the attachment metadata.
    // 3. Making an HTTP GET request to that URL (potentially needing auth headers).
    // 4. Returning response.bodyBytes.
  }

  // --- Todoist Specific Helper Methods ---

  /// Get all projects (needed for UI pickers, etc.)
  @override
  Future<List<todoist.Project>> listProjects() async {
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Getting all projects (listProjects)');
    }
    try {
      final projects = await _projectsApi.getAllProjects();
      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${projects?.length ?? 0} projects',
        );
      }
      return projects ?? [];
    } catch (e) {
      _handleApiError('Error getting projects', e);
      rethrow;
    }
  }

  /// Get all personal labels (needed for UI pickers, etc.)
  @override
  Future<List<todoist.Label>> listLabels() async {
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Getting all personal labels (listLabels)',
      );
    }
    try {
      final labels = await _labelsApi.getAllPersonalLabels();
      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${labels?.length ?? 0} labels',
        );
      }
      return labels ?? [];
    } catch (e) {
      _handleApiError('Error getting labels', e);
      rethrow;
    }
  }

  /// Get all sections, optionally filtered by project (needed for UI pickers, etc.)
  @override
  Future<List<todoist.Section>> listSections({String? projectId}) async {
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Getting all sections${projectId != null ? ' for project $projectId' : ''} (listSections)',
      );
    }
    try {
      final sections = await _sectionsApi.getAllSections(projectId: projectId);
      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${sections?.length ?? 0} sections',
        );
      }
      return sections ?? [];
    } catch (e) {
      _handleApiError('Error getting sections', e);
      rethrow;
    }
  }


  // --- Old Internal Methods (Review and keep/remove as needed) ---
  // These seem like duplicates of the TaskApiService methods now.

  /// Get all active tasks, optionally filtered by parameters - DEPRECATED by listTasks
  Future<List<todoist.Task>> getActiveTasks({
    String? projectId,
    String? sectionId,
    String? label,
    String? filter,
    String? lang,
    List<int>? ids,
  }) async {
    if (verboseLogging) {
      // Use stderr.writeln for server-side logging
      stderr.writeln('[TodoistApiService] Getting active tasks');
    }

    try {
      final tasks = await _tasksApi.getActiveTasks(
        projectId: projectId,
        sectionId: sectionId,
        label: label,
        filter: filter,
        lang: lang,
        ids: ids,
      );

      if (verboseLogging) {
        // Use stderr.writeln for server-side logging
        stderr.writeln(
          '[TodoistApiService] Retrieved ${tasks?.length ?? 0} tasks',
        );
      }

      return tasks ?? [];
    } catch (e) {
      _handleApiError('Error getting active tasks', e);
      rethrow;
    }
  }


  // HELPER METHODS

  void _handleApiError(String context, dynamic error) {
    // Use stderr.writeln for errors
    if (error is todoist.ApiException) {
      // Access the message property for the error description
      stderr.writeln(
        '[TodoistApiService] API Error - $context: ${error.message} (Code: ${error.code})',
      );
      // Optionally log the response body if available and needed for debugging
      // stderr.writeln('[TodoistApiService] Response Body: ${error.body}'); // If error.body existed
    } else {
      stderr.writeln('[TodoistApiService] Error - $context: $error');
      // Consider logging stack trace in verbose mode
      if (verboseLogging && error is Error) {
        stderr.writeln(error.stackTrace);
      }
    }
  }

  // isConfigured and checkHealth are now implemented as part of BaseApiService


  // You can uncomment and use this helper method when needed
  // Future<String> _decodeBodyBytes(http.Response response) async {
  //   // Handle potential gzip encoding if necessary (Todoist API might not use it)
  //   // if (response.headers['content-encoding'] == 'gzip') { ... }
  //   return utf8.decode(response.bodyBytes, allowMalformed: true);
  // }
}
