import 'dart:convert';
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
      final tasks = await _tasksApi.getActiveTasks(filter: filter);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${tasks?.length ?? 0} raw tasks',
        );
      }

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
        stderr.writeln(
          '[TodoistApiService] Error: Invalid task ID format provided: "$id"',
        );
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

      final String serverId =
          targetServerOverride?.id ?? "todoist_default"; // Example
      final taskItem = TaskItem.fromTodoistTask(task, serverId);

      if (verboseLogging) {
        stderr.writeln('[TodoistApiService] Mapped to TaskItem');
      }

      return taskItem;

    } catch (e) {
      _handleApiError('Error getting task by ID $id (getTask)', e);
      rethrow;
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

    final request = todoist.CreateTaskRequest(
      content: taskItem.content,
      description: taskItem.description,
      projectId: taskItem.projectId,
      sectionId: taskItem.sectionId,
      parentId: taskItem.parentId,
      labels: taskItem.labels,
      priority: taskItem.priority,
      dueString: taskItem.dueString,
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
      content: taskItem.content,
      description: taskItem.description,
      labels: taskItem.labels,
      priority: taskItem.priority,
      dueString: taskItem.dueString,
      assigneeId: taskItem.assigneeId,
      // Note: Project ID, Section ID, Parent ID cannot be updated via this endpoint.
    );

    try {
      // The generated updateTask expects a Task? return type based on OpenAPI spec,
      // but the actual Todoist API V2 returns 204 No Content on success.
      // We call the generated method but ignore its return value if status is 204.
      final response = await _tasksApi.updateTaskWithHttpInfo(id, request);

      if (response.statusCode == HttpStatus.noContent) {
         // API V2 Update Task returns 204 No Content on success.
         // Fetch the task again to return the updated TaskItem.
         if (verboseLogging) {
           stderr.writeln(
            '[TodoistApiService] Task $id updated successfully (204). Fetching updated task...',
           );
         }
         return await getTask(id, targetServerOverride: targetServerOverride);
      } else if (response.statusCode >= HttpStatus.ok && response.statusCode < HttpStatus.multipleChoices) {
         // If the API *did* return a body (unexpected based on spec, but handle defensively)
         stderr.writeln(
          '[TodoistApiService] Warning: updateTask API returned status ${response.statusCode} with body, expected 204. Attempting to parse.',
         );
         if (response.body.isNotEmpty) {
            final updatedTodoistTask = await _apiClient.deserializeAsync((await _decodeBodyBytes(response)) as String, 'Task') as todoist.Task?;
            if (updatedTodoistTask != null) {
               final String serverId = targetServerOverride?.id ?? "todoist_default";
               return TaskItem.fromTodoistTask(updatedTodoistTask, serverId);
            }
         }
         // Fallback: If parsing failed or body was empty despite 2xx status, fetch manually
         stderr.writeln(
          '[TodoistApiService] Fallback: Fetching task $id manually after unexpected update response.',
         );
         return await getTask(id, targetServerOverride: targetServerOverride);
      } else {
         // Handle actual API errors (>= 400)
         throw todoist.ApiException(response.statusCode, utf8.decode(await _decodeBodyBytes(response)));
      }

    } catch (e) {
      _handleApiError('Error updating task $id from TaskItem', e);
      rethrow; // Rethrow the original error
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

      final commentItems =
          comments
              ?.map(
                (c) => Comment.fromTodoistComment(
                  c,
                  taskId,
                ),
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

    todoist.CreateCommentAttachmentParameter? attachmentParam;

    try {
      final createdTodoistComment = await _commentsApi.createComment(
        comment.content ?? '',
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

      final createdCommentItem = Comment.fromTodoistComment(
        createdTodoistComment,
        taskId,
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
      final updatedTodoistComment = await _commentsApi.updateComment(
        commentId,
        comment.content ?? '',
      );

      if (updatedTodoistComment == null) {
        throw Exception("Comment update returned null unexpectedly from API");
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Raw comment updated successfully: ${updatedTodoistComment.id}',
        );
      }

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
    String taskId,
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
    stderr.writeln(
      '[TodoistApiService] uploadResource not directly supported. Attachments are linked via comments.',
    );
    throw UnimplementedError(
      "Todoist handles resource uploads differently (via comment attachments).",
    );
  }

  @override
  Future<Uint8List> getResourceData(
    String resourceIdentifier, {
    ServerConfig? targetServerOverride,
  }) async {
    stderr.writeln(
      '[TodoistApiService] getResourceData requires parsing comment attachments and fetching from URL.',
    );
    throw UnimplementedError(
      "Getting raw resource data requires fetching from attachment URL.",
    );
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

  Future<Uint8List> _decodeBodyBytes(dynamic response) async {
    // Decode bodyBytes from the response
    return response.bodyBytes;
  }

  void _handleApiError(String context, dynamic error) {
    if (error is todoist.ApiException) {
      stderr.writeln(
        '[TodoistApiService] API Error - $context: ${error.message} (Code: ${error.code})',
      );
    } else {
      stderr.writeln('[TodoistApiService] Error - $context: $error');
      if (verboseLogging && error is Error) {
        stderr.writeln(error.stackTrace);
      }
    }
  }
}
