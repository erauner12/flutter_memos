import 'dart:convert';
import 'dart:io'; // Import for stderr
import 'dart:typed_data'; // For Uint8List

import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_memos/models/comment.dart'; // Use app's Comment model
import 'package:flutter_memos/models/server_config.dart'; // Use ServerConfig if needed for overrides (though likely not for Todoist)
import 'package:flutter_memos/models/task_item.dart'; // Use app's TaskItem model
import 'package:flutter_memos/services/task_api_service.dart'; // Implement the interface
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:http/http.dart';

// Provider to expose the TodoistApiService singleton instance
final todoistApiServiceProvider = Provider<TodoistApiService>((ref) {
  // Returns the existing singleton instance.
  // Configuration is handled separately.
  return TodoistApiService();
});

// StateProvider to explicitly track if the Todoist service is configured.
// This allows other providers/widgets to react to configuration changes.
final isTodoistConfiguredProvider = StateProvider<bool>(
  (ref) => TodoistApiService().isConfigured, // Initial state based on singleton
  name: 'isTodoistConfigured',
);


/// Service class for interacting with the Todoist API (REST and Sync)
///
/// This class wraps the auto-generated Todoist API client
/// and provides convenient methods for common operations,
/// implementing the TaskApiService interface.
class TodoistApiService implements TaskApiService {
  // Singleton pattern
  static final TodoistApiService _instance = TodoistApiService._internal();
  factory TodoistApiService() => _instance;

  // --- REST API Client Instances ---
  late todoist.ApiClient _restApiClient;
  late todoist.TasksApi _tasksApi;
  late todoist.ProjectsApi _projectsApi;
  late todoist.SectionsApi _sectionsApi;
  late todoist.LabelsApi _labelsApi;
  late todoist.CommentsApi _commentsApi;

  // --- Sync API Client Instances ---
  late todoist.ApiClient _syncApiClient;
  late todoist.SyncApi _syncApi; // Assumes SyncApi exists in generated code

  // --- Configuration ---
  final String _restBaseUrl = 'https://api.todoist.com/rest/v2';
  final String _syncBaseUrl = 'https://api.todoist.com/sync/v9'; // Adjust version if needed
  String _authToken = '';
  bool _isCurrentlyConfigured = false; // Internal flag

  // --- Sync State ---
  String _lastSyncToken = '*'; // Start with '*' for initial full sync

  // Configuration and logging options
  static bool verboseLogging =
      false; // Cannot use kDebugMode in non-Flutter env

  @override
  String get apiBaseUrl => _restBaseUrl; // Keep REST as the primary for now

  TodoistApiService._internal() {
    // Initialize with empty token - will need to be configured later
    _initializeClient('');
    _initializeSyncClient(''); // Initialize sync client as well
  }

  /// Configure the Todoist API service with authentication token.
  /// Initializes both REST and Sync clients. Resets sync token on reconfigure.
  ///
  /// ### VERY IMPORTANT:
  /// After calling this method successfully, the **CALLER** is responsible for
  /// updating the `isTodoistConfiguredProvider` state to reflect the new
  /// configuration status (`_isCurrentlyConfigured`).
  ///
  /// Example:
  /// ```dart
  /// // Assuming 'ref' is available (e.g., inside another provider or ConsumerWidget)
  /// await todoistApiService.configureService(authToken: '...');
  /// ref.read(isTodoistConfiguredProvider.notifier).state = todoistApiService.isConfigured;
  /// ```
  @override
  Future<void> configureService({
    required String baseUrl, // Ignored, Todoist URLs are fixed
    required String authToken,
  }) async {
    // Make async to match Future<void> return type
    if (_authToken == authToken &&
        _authToken.isNotEmpty &&
        _isCurrentlyConfigured) {
      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Configuration unchanged.',
        );
      }
      return;
    }

    _authToken = authToken;
    _lastSyncToken = '*'; // Reset sync token on reconfigure/new token
    _initializeClient(_authToken); // Initialize REST client
    _initializeSyncClient(_authToken); // Initialize Sync client
    _isCurrentlyConfigured = _authToken.isNotEmpty; // Update internal flag

    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Configured REST & Sync with ${authToken.isNotEmpty ? 'valid' : 'empty'} token. Sync token reset to "*". Configured: $_isCurrentlyConfigured',
      );
    }
    // The caller MUST update the isTodoistConfiguredProvider state after this call.
  }

  /// Initializes the REST API client and associated endpoint classes.
  void _initializeClient(String token) {
    try {
      final auth = todoist.HttpBearerAuth()..accessToken = token;
      _restApiClient = todoist.ApiClient(
        basePath: _restBaseUrl,
        authentication: auth,
      );

      // Initialize REST API endpoints
      _tasksApi = todoist.TasksApi(_restApiClient);
      _projectsApi = todoist.ProjectsApi(_restApiClient);
      _sectionsApi = todoist.SectionsApi(_restApiClient);
      _labelsApi = todoist.LabelsApi(_restApiClient);
      _commentsApi = todoist.CommentsApi(_restApiClient);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] REST Client initialized successfully',
        );
      }
    } catch (e) {
      stderr.writeln(
        '[TodoistApiService] Error initializing REST client: $e',
      );
      // Don't throw here, allow partial initialization if one fails
    }
  }

  /// Initializes the Sync API client and associated endpoint classes.
  void _initializeSyncClient(String token) {
    try {
      final auth = todoist.HttpBearerAuth()..accessToken = token;
      _syncApiClient = todoist.ApiClient(
        basePath: _syncBaseUrl,
        authentication: auth,
      );

      // Initialize Sync API endpoints (assuming SyncApi exists)
      _syncApi = todoist.SyncApi(_syncApiClient);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Sync Client initialized successfully',
        );
      }
    } catch (e) {
      stderr.writeln(
        '[TodoistApiService] Error initializing Sync client: $e',
      );
      // Don't throw here, allow partial initialization if one fails
    }
  }


  // --- BaseApiService Implementation ---

  // apiBaseUrl is already defined as a class property getter

  @override
  bool get isConfigured => _isCurrentlyConfigured; // Use internal flag

  // configureService is already implemented above.

  @override
  Future<bool> checkHealth() async {
    if (!isConfigured) return false;

    try {
      // Use a lightweight REST call for the primary health check
      await _projectsApi.getAllProjects();
      // Optionally, perform an initial sync check if desired, but REST is usually sufficient
      // await performSync(resourceTypes: ['user']); // Example: sync only user info
      return true;
    } catch (e) {
      _handleApiError('Health check failed', e); // Log the specific error
      return false;
    }
  }

  // --- TaskApiService Implementation ---

  // --- Task Operations (Using REST API) ---
  // [Existing REST methods for listTasks, getTask, createTask, updateTask, deleteTask remain unchanged]
  // ... (Code for REST methods omitted for brevity, they are the same as previous version) ...
  /// Get all active tasks via REST API, mapped to TaskItem
  @override
  Future<List<TaskItem>> listTasks({
    String? filter,
    ServerConfig? targetServerOverride, // Ignored for Todoist global key
  }) async {
    if (!isConfigured) {
      stderr.writeln('[TodoistApiService] Not configured, cannot list tasks.');
      return [];
    }
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Getting active tasks via REST (listTasks)');
    }

    try {
      final tasks = await _tasksApi.getActiveTasks(filter: filter);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${tasks?.length ?? 0} raw tasks via REST',
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
      _handleApiError('Error getting active tasks via REST (listTasks)', e);
      rethrow;
    }
  }


  /// Get a single active task by its ID via REST API, mapped to TaskItem
  @override
  Future<TaskItem> getTask(
    String id, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot get task $id.',
      );
      throw Exception('Todoist API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Getting active task by ID via REST (getTask): $id',
      );
    }

    try {
      // Todoist REST API uses numeric IDs for tasks
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        stderr.writeln(
          '[TodoistApiService] Error: Invalid task ID format provided for REST API: "$id"',
        );
        throw ArgumentError('Invalid task ID format for REST API: $id');
      }
      final task = await _tasksApi.getActiveTask(taskIdInt);

      if (task == null) {
        throw Exception('Task with ID $id not found via REST.');
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved raw task via REST: ${task.content}',
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
      _handleApiError('Error getting task by ID $id via REST (getTask)', e);
      rethrow;
    }
  }


  /// Create a new task via REST API from a TaskItem model
  @override
  Future<TaskItem> createTask(
    TaskItem taskItem, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (!isConfigured) {
      stderr.writeln('[TodoistApiService] Not configured, cannot create task.');
      throw Exception('Todoist API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Creating task via REST from TaskItem: ${taskItem.content}',
      );
    }

    // Map TaskItem fields to todoist.CreateTaskRequest
    // Note: Ensure TaskItem has necessary fields or handle nulls appropriately
    final request = todoist.CreateTaskRequest(
      content: taskItem.content,
      description: taskItem.description,
      projectId: taskItem.projectId,
      sectionId: taskItem.sectionId,
      parentId: taskItem.parentId,
      labels: taskItem.labels,
      priority: taskItem.priority,
      dueString: taskItem.dueString,
      // dueDate: taskItem.dueDate, // Map if available
      // dueDatetime: taskItem.dueDatetime, // Map if available
      // dueLang: taskItem.dueLang, // Map if available
      assigneeId: taskItem.assigneeId,
      // duration: taskItem.duration, // Map if available
      // durationUnit: taskItem.durationUnit, // Map if available
    );

    try {
      final createdTodoistTask = await _tasksApi.createTask(request);

      if (createdTodoistTask == null) {
        throw Exception("Task creation returned null from REST API");
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Raw Task created successfully via REST with ID: ${createdTodoistTask.id}',
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
      _handleApiError('Error creating task via REST from TaskItem', e);
      rethrow;
    }
  }


  /// Update an existing task via REST API using a TaskItem model
  @override
  Future<TaskItem> updateTask(
    String id,
    TaskItem taskItem, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot update task $id.',
      );
      throw Exception('Todoist API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Updating task via REST from TaskItem: $id');
    }

    // Map TaskItem fields to todoist.UpdateTaskRequest
    final request = todoist.UpdateTaskRequest(
      content: taskItem.content, // Only update if not null? Or always send?
      description: taskItem.description,
      labels: taskItem.labels,
      priority: taskItem.priority,
      dueString: taskItem.dueString,
      // dueDate: taskItem.dueDate,
      // dueDatetime: taskItem.dueDatetime,
      // dueLang: taskItem.dueLang,
      assigneeId: taskItem.assigneeId,
      // duration: taskItem.duration,
      // durationUnit: taskItem.durationUnit,
      // Note: Project ID, Section ID, Parent ID cannot be updated via this endpoint.
    );

    try {
      // The generated updateTask expects a Task? return type based on OpenAPI spec,
      // but the actual Todoist API V2 returns 204 No Content on success.
      // We call the generated method but ignore its return value if status is 204.
      // Need to use the WithHttpInfo version to check status code.
      final response = await _tasksApi.updateTaskWithHttpInfo(id, request);

      if (response.statusCode == HttpStatus.noContent) {
         // API V2 Update Task returns 204 No Content on success.
         // Fetch the task again to return the updated TaskItem.
         if (verboseLogging) {
           stderr.writeln(
            '[TodoistApiService] Task $id updated successfully via REST (204). Fetching updated task...',
           );
         }
         // Use the existing getTask method which uses REST
         return await getTask(id, targetServerOverride: targetServerOverride);
      } else if (response.statusCode >= HttpStatus.ok && response.statusCode < HttpStatus.multipleChoices) {
         // If the API *did* return a body (unexpected based on spec, but handle defensively)
         stderr.writeln(
          '[TodoistApiService] Warning: updateTask REST API returned status ${response.statusCode} with body, expected 204. Attempting to parse.',
         );
         if (response.body.isNotEmpty) {
            // Use the REST client's deserializer
            final updatedTodoistTask = await _restApiClient.deserializeAsync(utf8.decode(await _decodeBodyBytes(response)), 'Task') as todoist.Task?;
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
      _handleApiError('Error updating task $id via REST from TaskItem', e);
      rethrow; // Rethrow the original error
    }
  }


  /// Delete a task via REST API
  @override
  Future<void> deleteTask(
    String id, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot delete task $id.',
      );
      throw Exception('Todoist API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Deleting task via REST (deleteTask): $id');
    }

    try {
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        throw ArgumentError('Invalid task ID format for REST API: $id');
      }
      await _tasksApi.deleteTask(taskIdInt);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Task $id deleted successfully via REST',
        );
      }
    } catch (e) {
      _handleApiError('Error deleting task $id via REST', e);
      rethrow;
    }
  }


  // --- Task Actions (Using REST API) ---
  // [Existing REST methods for completeTask, reopenTask remain unchanged]
  // ... (Code for REST methods omitted for brevity, they are the same as previous version) ...
  /// Close (complete) a task via REST API
  @override
  Future<void> completeTask(
    String id, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot complete task $id.',
      );
      throw Exception('Todoist API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Closing task via REST (completeTask): $id');
    }

    try {
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        throw ArgumentError('Invalid task ID format for REST API: $id');
      }
      await _tasksApi.closeTask(taskIdInt);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Task $id closed successfully via REST',
        );
      }
    } catch (e) {
      _handleApiError('Error closing task $id via REST', e);
      rethrow;
    }
  }


  /// Reopen a task via REST API
  @override
  Future<void> reopenTask(
    String id, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot reopen task $id.',
      );
      throw Exception('Todoist API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Reopening task via REST (reopenTask): $id');
    }

    try {
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        throw ArgumentError('Invalid task ID format for REST API: $id');
      }
      await _tasksApi.reopenTask(taskIdInt);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Task $id reopened successfully via REST',
        );
      }
    } catch (e) {
      _handleApiError('Error reopening task $id via REST', e);
      rethrow;
    }
  }


  // --- Task Comments (Using REST API) ---
  // [Existing REST methods for listComments, getComment, createComment, updateComment, deleteComment remain unchanged]
  // ... (Code for REST methods omitted for brevity, they are the same as previous version) ...
  /// List comments for a specific task via REST API
  @override
  Future<List<Comment>> listComments(
    String taskId, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot list comments for task $taskId.',
      );
      return [];
    }
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Getting comments for task $taskId via REST (listComments)',
      );
    }

    try {
      // REST API requires task_id for comments
      final comments = await _commentsApi.getAllComments(taskId: taskId);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${comments?.length ?? 0} raw comments via REST for task $taskId',
        );
      }

      final commentItems =
          comments
              ?.map(
                (c) => Comment.fromTodoistComment(
                  c,
                  taskId, // Pass taskId since it's required by the model mapping
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
      _handleApiError('Error getting comments for task $taskId via REST', e);
      rethrow;
    }
  }

  /// Get a single comment by its ID via REST API
  @override
  Future<Comment> getComment(
    String commentId, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot get comment $commentId.',
      );
      throw Exception('Todoist API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Getting comment by ID via REST (getComment): $commentId',
      );
    }
    try {
      final commentIdInt = int.tryParse(commentId);
      if (commentIdInt == null) {
        throw ArgumentError('Invalid comment ID format for REST API: $commentId');
      }
      final todoistComment = await _commentsApi.getComment(commentIdInt);

      if (todoistComment == null) {
        throw Exception('Comment with ID $commentId not found via REST.');
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved raw comment via REST: ${todoistComment.content}',
        );
      }

      // Ensure taskId is available from the comment object itself if possible
      final taskId = todoistComment.taskId ?? "unknown_task"; // Fallback if taskId is null
      final commentItem = Comment.fromTodoistComment(
        todoistComment,
        taskId,
      );

      if (verboseLogging) {
        stderr.writeln('[TodoistApiService] Mapped comment to Comment model');
      }

      return commentItem;
    } catch (e) {
      _handleApiError('Error getting comment by ID $commentId via REST', e);
      rethrow;
    }
  }


  /// Create a comment for a task via REST API
  @override
  Future<Comment> createComment(
    String taskId,
    Comment comment, {
    ServerConfig? targetServerOverride /* Ignored */,
    List<Map<String, dynamic>>? resources /* TODO: Handle attachments via REST if supported */,
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot create comment for task $taskId.',
      );
      throw Exception('Todoist API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Creating comment via REST for task $taskId');
    }

    // TODO: Handle attachment mapping if REST API supports it differently
    todoist.CreateCommentAttachmentParameter? attachmentParam;
    // if (resources != null && resources.isNotEmpty) {
    //   // Map resources to attachmentParam based on REST API spec
    // }

    try {
      final createdTodoistComment = await _commentsApi.createComment(
        comment.content ?? '',
        taskId: taskId, // REST API requires taskId here
        attachment: attachmentParam,
      );

      if (createdTodoistComment == null) {
        throw Exception("Comment creation returned null from REST API");
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Raw comment created successfully via REST with ID: ${createdTodoistComment.id}',
        );
      }

      final createdCommentItem = Comment.fromTodoistComment(
        createdTodoistComment,
        taskId, // Use the provided taskId
      );

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Mapped created comment back to Comment model',
        );
      }

      return createdCommentItem;

    } catch (e) {
      _handleApiError('Error creating comment via REST for task $taskId', e);
      rethrow;
    }
  }


  /// Update an existing comment via REST API
  @override
  Future<Comment> updateComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot update comment $commentId.',
      );
      throw Exception('Todoist API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Updating comment $commentId via REST');
    }

    try {
      // REST API update takes commentId as path param and content as query param
      final updatedTodoistComment = await _commentsApi.updateComment(
        commentId, // Pass ID as string here as per generated method signature
        comment.content ?? '',
      );

      if (updatedTodoistComment == null) {
        throw Exception("Comment update returned null unexpectedly from REST API");
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Raw comment updated successfully via REST: ${updatedTodoistComment.id}',
        );
      }

      final taskId = updatedTodoistComment.taskId ?? "unknown_task"; // Fallback
      final updatedCommentItem = Comment.fromTodoistComment(
        updatedTodoistComment,
        taskId,
      );

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Mapped updated comment back to Comment model',
        );
      }

      return updatedCommentItem;
    } catch (e) {
      _handleApiError('Error updating comment $commentId via REST', e);
      rethrow;
    }
  }


  /// Delete a comment via REST API
  @override
  Future<void> deleteComment(
    String taskId, // taskId might not be needed for REST delete, but kept for interface consistency
    String commentId, {
    ServerConfig? targetServerOverride /* Ignored */,
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot delete comment $commentId.',
      );
      throw Exception('Todoist API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Deleting comment $commentId via REST (task $taskId)',
      );
    }

    try {
      final commentIdInt = int.tryParse(commentId);
      if (commentIdInt == null) {
        throw ArgumentError('Invalid comment ID format for REST API: $commentId');
      }
      // REST API delete uses the comment ID
      await _commentsApi.deleteComment(commentIdInt);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Comment $commentId deleted successfully via REST',
        );
      }
    } catch (e) {
      _handleApiError('Error deleting comment $commentId via REST', e);
      rethrow;
    }
  }


  // --- Resource Methods (Implementing BaseApiService - Generally not supported by Todoist REST/Sync directly) ---
  // [Existing Resource methods uploadResource, getResourceData remain unchanged]
  // ... (Code for Resource methods omitted for brevity, they are the same as previous version) ...
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
    // Todoist REST API might have an upload endpoint, but it's usually tied to comments/tasks.
    // See https://developer.todoist.com/sync/v9/#uploads
    // This requires a different flow than the generic uploadResource.
    throw UnimplementedError(
      "Todoist handles resource uploads differently (via comment attachments or dedicated upload endpoints).",
    );
  }

  @override
  Future<Uint8List> getResourceData(
    String resourceIdentifier, { // This might be a URL from an attachment
    ServerConfig? targetServerOverride,
  }) async {
    stderr.writeln(
      '[TodoistApiService] getResourceData requires parsing comment attachments and fetching from URL.',
    );
    // Need to fetch the comment/task, get the attachment URL, then download the data.
    throw UnimplementedError(
      "Getting raw resource data requires fetching the attachment URL first.",
    );
  }


  // --- Todoist Specific Helper Methods (Using REST API) ---
  // [Existing REST methods for listProjects, listLabels, listSections remain unchanged]
  // ... (Code for REST methods omitted for brevity, they are the same as previous version) ...
  /// Get all projects via REST API
  @override
  Future<List<todoist.Project>> listProjects() async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot list projects.',
      );
      return [];
    }
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Getting all projects via REST (listProjects)');
    }
    try {
      final projects = await _projectsApi.getAllProjects();
      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${projects?.length ?? 0} projects via REST',
        );
      }
      return projects ?? [];
    } catch (e) {
      _handleApiError('Error getting projects via REST', e);
      rethrow;
    }
  }

  /// Get all personal labels via REST API
  @override
  Future<List<todoist.Label>> listLabels() async {
    if (!isConfigured) {
      stderr.writeln('[TodoistApiService] Not configured, cannot list labels.');
      return [];
    }
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Getting all personal labels via REST (listLabels)',
      );
    }
    try {
      final labels = await _labelsApi.getAllPersonalLabels();
      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${labels?.length ?? 0} labels via REST',
        );
      }
      return labels ?? [];
    } catch (e) {
      _handleApiError('Error getting labels via REST', e);
      rethrow;
    }
  }

  /// Get all sections via REST API, optionally filtered by project
  @override
  Future<List<todoist.Section>> listSections({String? projectId}) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot list sections.',
      );
      return [];
    }
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Getting all sections via REST${projectId != null ? ' for project $projectId' : ''} (listSections)',
      );
    }
    try {
      final sections = await _sectionsApi.getAllSections(projectId: projectId);
      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${sections?.length ?? 0} sections via REST',
        );
      }
      return sections ?? [];
    } catch (e) {
      _handleApiError('Error getting sections via REST', e);
      rethrow;
    }
  }


  // --- Sync API Methods ---

  /// Performs a sync operation using the Todoist Sync API.
  ///
  /// Fetches updates since the last sync or performs a full sync if necessary.
  /// Updates the internal `_lastSyncToken` for subsequent incremental syncs.
  ///
  /// [resourceTypes] specifies which data types to fetch (e.g., ['all'], ['items', 'projects']).
  /// Defaults to ['all'].
  Future<todoist.SyncResponse?> performSync({
    List<String> resourceTypes = const ['all'],
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Cannot perform sync: Service not configured.',
      );
      return null;
    }
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Performing sync with token: $_lastSyncToken, types: $resourceTypes',
      );
    }
    try {
      final result = await _syncApi.sync(
        syncToken: _lastSyncToken,
        resourceTypes: resourceTypes,
      );

      if (result != null) {
        // Update the sync token for the next incremental sync
        if (result.syncToken != null && result.syncToken!.isNotEmpty) {
          _lastSyncToken = result.syncToken!;
          if (verboseLogging) {
            stderr.writeln(
              '[TodoistApiService] Sync successful. Updated sync token to: $_lastSyncToken',
            );
          }
        } else {
          stderr.writeln(
            '[TodoistApiService] Warning: Sync response did not contain a new sync_token.',
          );
        }
      } else {
        stderr.writeln(
          '[TodoistApiService] Warning: Sync call returned null response.',
        );
      }
      return result;
    } catch (e) {
      _handleApiError('Error performing sync', e);
      // Should we reset the sync token on error? Maybe only on specific errors?
      // For now, keep the old token and retry later.
      // If it's an auth error (401/403), configureService should reset it.
      rethrow;
    }
  }

  /// Fetches activity events using the Sync API.
  ///
  /// This performs a sync requesting ['all'] resource types to ensure a standard
  /// response structure, then extracts the activity events.
  /// Note: This uses the current `_lastSyncToken`. For a full history,
  /// you might need to manage the sync token differently or use REST API if available.
  /// Pagination is not directly handled here; the Sync API returns events since the last sync.
  Future<List<todoist.ActivityEvents>> getActivityEventsFromSync() async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot fetch activity events.',
      );
      return [];
    }
    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Fetching activity events via sync (requesting "all")...',
      );
    }
    try {
      // Perform a sync requesting 'all' resource types for robustness
      final syncResponse = await performSync(resourceTypes: ['all']);

      // Extract the activity events from the response
      final events = syncResponse?.activity ?? [];

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${events.length} activity events from sync.',
        );
      }
      return events;
    } catch (e) {
      _handleApiError('Error fetching activity events via sync', e);
      rethrow; // Rethrow the error to be handled by the caller
    }
  }


  // --- Old Internal Methods (Review and keep/remove as needed) ---
  // [Existing DEPRECATED getActiveTasks method remains unchanged]
  // ... (Code omitted for brevity) ...
  /// Get all active tasks, optionally filtered by parameters - DEPRECATED by listTasks
  /// Kept for reference, uses REST API.
  Future<List<todoist.Task>> getActiveTasks({
    String? projectId,
    String? sectionId,
    String? label,
    String? filter,
    String? lang,
    List<int>? ids,
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[TodoistApiService] Not configured, cannot get active tasks (DEPRECATED).',
      );
      return [];
    }
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Getting active tasks via REST (DEPRECATED getActiveTasks)');
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
          '[TodoistApiService] Retrieved ${tasks?.length ?? 0} tasks via REST (DEPRECATED)',
        );
      }

      return tasks ?? [];
    } catch (e) {
      _handleApiError('Error getting active tasks via REST (DEPRECATED)', e);
      rethrow;
    }
  }


  // --- HELPER METHODS ---

  /// Helper to decode response body bytes safely.
  Future<Uint8List> _decodeBodyBytes(dynamic response) async {
    // Assuming response is http.Response or similar with bodyBytes
    if (response is Response) {
        return response.bodyBytes;
    }
    // Add handling for other response types if necessary
    return Uint8List(0);
  }

  /// Centralized error handling for API calls.
  void _handleApiError(String context, dynamic error) {
    String errorMessage = '$error';
    int? statusCode;

    if (error is todoist.ApiException) {
      statusCode = error.code;
      // Use the message directly as it might contain decoded JSON error details
      errorMessage =
          error.message ?? 'Unknown API Exception (Code: $statusCode)';
      stderr.writeln(
        '[TodoistApiService] API Error - $context: $errorMessage', // Already includes code if available
      );
      // If auth error, mark service as unconfigured internally
      if (statusCode == 401 || statusCode == 403) {
        final wasConfigured = _isCurrentlyConfigured;
        _isCurrentlyConfigured = false;
        _authToken = ''; // Clear token
        stderr.writeln(
          '[TodoistApiService] Authentication error ($statusCode). Service marked as unconfigured internally.',
        );
        // --- IMPORTANT ---
        // The code *catching* this specific ApiException should update the
        // isTodoistConfiguredProvider state if it has access to a Ref/ProviderContainer.
        // Example (in calling code):
        // } catch (e) {
        //   if (e is ApiException && (e.code == 401 || e.code == 403)) {
        //     ref.read(isTodoistConfiguredProvider.notifier).state = false;
        //   }
        //   // Handle other errors...
        // }
        // --- IMPORTANT ---
      }
    } else {
      stderr.writeln('[TodoistApiService] Error - $context: $errorMessage');
      if (verboseLogging && error is Error) {
        stderr.writeln(error.stackTrace);
      }
    }
    // Consider mapping specific status codes (404, 5xx) to specific app exceptions if needed
  }
}

// Helper interface extension for TaskApiService to include Todoist-specific methods
// This keeps the core interface clean but allows access to raw Todoist models if needed.
extension TodoistSpecificMethods on TaskApiService {
  Future<List<todoist.Project>> listProjects() =>
      throw UnimplementedError('listProjects must be implemented by the concrete class');
  Future<List<todoist.Label>> listLabels() =>
      throw UnimplementedError('listLabels must be implemented by the concrete class');
  Future<List<todoist.Section>> listSections({String? projectId}) =>
      throw UnimplementedError('listSections must be implemented by the concrete class');

  // Add Sync specific methods here if needed outside the main class
  Future<todoist.SyncResponse?> performSync({
    required List<String> resourceTypes,
  }) =>
      throw UnimplementedError(
        'performSync must be implemented by the concrete class',
      );

  // Add the new activity event method to the extension
  Future<List<todoist.ActivityEvents>> getActivityEventsFromSync() =>
      throw UnimplementedError(
        'getActivityEventsFromSync must be implemented by the concrete class',
      );

  // Remove old sync method placeholders
  // Future<todoist.GetDataV2Response?> getAllSyncData() =>
  //     throw UnimplementedError('getAllSyncData must be implemented by the concrete class');
  // Future<List<todoist.ActivityEvents>> listActivityEvents({String? since, String? until, int? limit, String? cursor}) =>
  //     throw UnimplementedError('listActivityEvents must be implemented by the concrete class');
}
