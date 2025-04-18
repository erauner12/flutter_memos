import 'dart:convert';
import 'dart:io'; // Import for stderr
import 'dart:typed_data'; // For Uint8List

import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_memos/models/comment.dart'; // Use app's Comment model
import 'package:flutter_memos/models/server_config.dart'; // Use ServerConfig if needed for overrides
import 'package:flutter_memos/models/task_item.dart'; // Use app's TaskItem model
import 'package:flutter_memos/services/auth_strategy.dart'; // Import AuthStrategy
import 'package:flutter_memos/services/task_api_service.dart'; // Implement the interface
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:http/http.dart';

// Provider to expose the TodoistApiService singleton instance
final todoistApiServiceProvider = Provider<TodoistApiService>((ref) {
  return TodoistApiService();
});

// StateProvider to explicitly track if the Todoist service is configured.
final isTodoistConfiguredProvider = StateProvider<bool>(
  (ref) => TodoistApiService().isConfigured,
  name: 'isTodoistConfigured',
);

/// Service class for interacting with the Todoist API (REST and Sync)
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
  late todoist.SyncApi _syncApi;

  // --- Configuration ---
  final String _restBaseUrl = 'https://api.todoist.com/rest/v2';
  final String _syncBaseUrl = 'https://api.todoist.com/sync/v9';
  AuthStrategy? _authStrategy; // Store the strategy
  bool _isCurrentlyConfigured = false; // Internal flag

  // --- Sync State ---
  String _lastSyncToken = '*'; // Start with '*' for initial full sync

  // Configuration and logging options
  static bool verboseLogging = false;

  @override
  String get apiBaseUrl => _restBaseUrl; // Keep REST as the primary

  @override
  AuthStrategy? get authStrategy => _authStrategy;

  TodoistApiService._internal() {
    // Initialize with dummy clients initially
    _initializeClient(null);
    _initializeSyncClient(null);
  }

  /// Configure the Todoist API service with an AuthStrategy or fallback token.
  /// Initializes both REST and Sync clients. Resets sync token on reconfigure.
  ///
  /// ### VERY IMPORTANT:
  /// After calling this method successfully, the **CALLER** is responsible for
  /// updating the `isTodoistConfiguredProvider` state.
  @override
  Future<void> configureService({
    required String baseUrl, // Ignored, Todoist URLs are fixed
    AuthStrategy? authStrategy,
    @Deprecated('Use authStrategy instead') String? authToken,
  }) async {
    AuthStrategy? effectiveStrategy = authStrategy;

    // Fallback to authToken if authStrategy is not provided
    if (effectiveStrategy == null &&
        authToken != null &&
        authToken.isNotEmpty) {
      // Todoist uses Bearer tokens
      effectiveStrategy = BearerTokenAuthStrategy(authToken);
      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] configureService: Using fallback BearerTokenAuthStrategy from authToken.',
        );
      }
    }

    // Check if configuration actually changed
    final currentToken = _authStrategy?.getSimpleToken();
    final newToken = effectiveStrategy?.getSimpleToken();
    if (currentToken == newToken && _isCurrentlyConfigured) {
      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] configureService: Configuration unchanged.',
        );
      }
      return;
    }

    _authStrategy = effectiveStrategy;
    _lastSyncToken = '*'; // Reset sync token on reconfigure/new strategy
    _initializeClient(_authStrategy); // Initialize REST client
    _initializeSyncClient(_authStrategy); // Initialize Sync client
    _isCurrentlyConfigured = _authStrategy != null; // Update internal flag

    if (verboseLogging) {
      stderr.writeln(
        '[TodoistApiService] Configured REST & Sync with strategy: ${_authStrategy?.runtimeType}. Sync token reset to "*". Configured: $_isCurrentlyConfigured',
      );
    }
    // The caller MUST update the isTodoistConfiguredProvider state after this call.
  }

  /// Initializes the REST API client and associated endpoint classes using AuthStrategy.
  void _initializeClient(AuthStrategy? strategy) {
    try {
      // Use the strategy to create the Authentication object
      final auth =
          strategy?.createTodoistAuth() ??
          todoist.HttpBearerAuth(); // Default to empty auth

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
          '[TodoistApiService] REST Client initialized successfully with auth: ${auth.runtimeType}',
        );
      }
    } catch (e) {
      stderr.writeln(
        '[TodoistApiService] Error initializing REST client: $e',
      );
      // Reset clients to dummy state on error
      final dummyAuth = todoist.HttpBearerAuth();
      _restApiClient = todoist.ApiClient(
        basePath: _restBaseUrl,
        authentication: dummyAuth,
      );
      _tasksApi = todoist.TasksApi(_restApiClient);
      _projectsApi = todoist.ProjectsApi(_restApiClient);
      _sectionsApi = todoist.SectionsApi(_restApiClient);
      _labelsApi = todoist.LabelsApi(_restApiClient);
      _commentsApi = todoist.CommentsApi(_restApiClient);
    }
  }

  /// Initializes the Sync API client and associated endpoint classes using AuthStrategy.
  void _initializeSyncClient(AuthStrategy? strategy) {
    try {
      // Use the strategy to create the Authentication object
      final auth =
          strategy?.createTodoistAuth() ??
          todoist.HttpBearerAuth(); // Default to empty auth

      _syncApiClient = todoist.ApiClient(
        basePath: _syncBaseUrl,
        authentication: auth,
      );

      // Initialize Sync API endpoints
      _syncApi = todoist.SyncApi(_syncApiClient);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Sync Client initialized successfully with auth: ${auth.runtimeType}',
        );
      }
    } catch (e) {
      stderr.writeln(
        '[TodoistApiService] Error initializing Sync client: $e',
      );
      // Reset client to dummy state on error
      final dummyAuth = todoist.HttpBearerAuth();
      _syncApiClient = todoist.ApiClient(
        basePath: _syncBaseUrl,
        authentication: dummyAuth,
      );
      _syncApi = todoist.SyncApi(_syncApiClient);
    }
  }

  // --- BaseApiService Implementation ---

  @override
  bool get isConfigured => _isCurrentlyConfigured; // Use internal flag

  @override
  Future<bool> checkHealth() async {
    if (!isConfigured) return false;

    try {
      // Use a lightweight REST call for the primary health check
      await _projectsApi.getAllProjects();
      return true;
    } catch (e) {
      _handleApiError('Health check failed', e); // Log the specific error
      return false;
    }
  }

  // --- TaskApiService Implementation ---

  // --- Task Operations (Using REST API) ---
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
          targetServerOverride?.id ?? "todoist_default"; // Example server ID
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
      // Convert the String ID to int before passing to the API
      final int taskId;
      try {
        taskId = int.parse(id);
      } catch (e) {
        throw Exception('Invalid task ID format: $id. Must be an integer.');
      }

      // Todoist REST API uses numeric IDs for tasks
      final task = await _tasksApi.getActiveTask(taskId);

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

    final request = todoist.UpdateTaskRequest(
      content: taskItem.content,
      description: taskItem.description,
      labels: taskItem.labels,
      priority: taskItem.priority,
      dueString: taskItem.dueString,
      assigneeId: taskItem.assigneeId,
    );

    try {
      final response = await _tasksApi.updateTaskWithHttpInfo(id, request);

      if (response.statusCode == HttpStatus.noContent) {
         if (verboseLogging) {
           stderr.writeln(
            '[TodoistApiService] Task $id updated successfully via REST (204). Fetching updated task...',
           );
        }
         return await getTask(id, targetServerOverride: targetServerOverride);
      } else if (response.statusCode >= HttpStatus.ok &&
          response.statusCode < HttpStatus.multipleChoices) {
         stderr.writeln(
          '[TodoistApiService] Warning: updateTask REST API returned status ${response.statusCode} with body, expected 204. Attempting to parse.',
         );
        if (response.body.isNotEmpty) {
            final updatedTodoistTask = await _restApiClient.deserializeAsync(utf8.decode(await _decodeBodyBytes(response)), 'Task') as todoist.Task?;
            if (updatedTodoistTask != null) {
               final String serverId = targetServerOverride?.id ?? "todoist_default";
               return TaskItem.fromTodoistTask(updatedTodoistTask, serverId);
            }
        }
         stderr.writeln(
          '[TodoistApiService] Fallback: Fetching task $id manually after unexpected update response.',
         );
         return await getTask(id, targetServerOverride: targetServerOverride);
      } else {
         throw todoist.ApiException(response.statusCode, utf8.decode(await _decodeBodyBytes(response)));
      }

    } catch (e) {
      _handleApiError('Error updating task $id via REST from TaskItem', e);
      rethrow;
    }
  }

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
      await _tasksApi.deleteTask(id as int);

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
      await _tasksApi.closeTask(id as int);

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
      await _tasksApi.reopenTask(id as int);

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
      final comments = await _commentsApi.getAllComments(taskId: taskId);

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${comments?.length ?? 0} raw comments via REST for task $taskId',
        );
      }

      final String serverId = targetServerOverride?.id ?? "todoist_default";
      final commentItems =
          comments
              ?.map(
                (c) => Comment.fromTodoistComment(
                  c,
                  taskId, // Pass taskId for context
                  serverId: serverId, // Pass serverId
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
      final todoistComment = await _commentsApi.getComment(commentId as int);

      if (todoistComment == null) {
        throw Exception('Comment with ID $commentId not found via REST.');
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved raw comment via REST: ${todoistComment.content}',
        );
      }

      final taskId = todoistComment.taskId ?? "unknown_task"; // Fallback if taskId is null
      final String serverId = targetServerOverride?.id ?? "todoist_default";
      final commentItem = Comment.fromTodoistComment(
        todoistComment,
        taskId,
        serverId: serverId,
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
    // if (resources != null && resources.isNotEmpty) { ... }

    try {
      final createdTodoistComment = await _commentsApi.createComment(
        comment.content ?? '',
        taskId: taskId,
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

      final String serverId = targetServerOverride?.id ?? "todoist_default";
      final createdCommentItem = Comment.fromTodoistComment(
        createdTodoistComment,
        taskId,
        serverId: serverId,
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
      final updatedTodoistComment = await _commentsApi.updateComment(
        commentId,
        comment.content ?? '',
      );

      if (updatedTodoistComment == null) {
        // This might happen if the API returns 204 No Content on success
        stderr.writeln(
          '[TodoistApiService] Update comment $commentId returned null/empty. Fetching comment manually.',
        );
        return await getComment(
          commentId,
          targetServerOverride: targetServerOverride,
        );
        // throw Exception("Comment update returned null unexpectedly from REST API");
      }

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Raw comment updated successfully via REST: ${updatedTodoistComment.id}',
        );
      }

      final taskId = updatedTodoistComment.taskId ?? "unknown_task"; // Fallback
      final String serverId = targetServerOverride?.id ?? "todoist_default";
      final updatedCommentItem = Comment.fromTodoistComment(
        updatedTodoistComment,
        taskId,
        serverId: serverId,
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

  @override
  Future<void> deleteComment(
    String taskId, // Kept for interface consistency
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
      await _commentsApi.deleteComment(commentId as int);

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

  // --- Resource Methods (Implementing BaseApiService - Generally not supported directly) ---
  @override
  Future<Map<String, dynamic>> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  }) async {
    stderr.writeln(
      '[TodoistApiService] uploadResource not directly supported. Attachments are linked via comments/tasks using specific upload endpoints.',
    );
    // See https://developer.todoist.com/sync/v9/#uploads or REST API equivalent if available
    throw UnimplementedError(
      "Todoist handles resource uploads differently (e.g., via comment attachments). Use specific methods if needed.",
    );
  }

  @override
  Future<Uint8List> getResourceData(
    String resourceIdentifier, // This might be a URL from an attachment
    {
    ServerConfig? targetServerOverride,
  }) async {
    stderr.writeln(
      '[TodoistApiService] getResourceData requires parsing comment/task attachments and fetching from the provided URL.',
    );
    // Need to fetch the comment/task, get the attachment URL, then download the data using an HTTP client.
    if (Uri.tryParse(resourceIdentifier)?.isAbsolute ?? false) {
      try {
        final response = await Client().get(Uri.parse(resourceIdentifier));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response.bodyBytes;
        } else {
          throw Exception('Failed to download resource from $resourceIdentifier: Status ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error downloading resource from $resourceIdentifier: $e');
      }
    } else {
      throw UnimplementedError(
        "Getting raw resource data requires a valid URL from an attachment. Identifier '$resourceIdentifier' is not a valid URL.",
      );
    }
  }

  // --- Todoist Specific Helper Methods (Using REST API) ---
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

  @override
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
      // Ensure sync client is properly initialized before use
      final result = await _syncApi.sync(
        syncToken: _lastSyncToken,
        resourceTypes: resourceTypes,
      );

      if (result != null) {
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
      rethrow;
    }
  }

  @override
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
      final syncResponse = await performSync(resourceTypes: ['activity']); // Request only activity

      final events = syncResponse?.activity ?? [];

      if (verboseLogging) {
        stderr.writeln(
          '[TodoistApiService] Retrieved ${events.length} activity events from sync.',
        );
      }
      return events;
    } catch (e) {
      _handleApiError('Error fetching activity events via sync', e);
      rethrow;
    }
  }

  // --- Old Internal Methods (DEPRECATED) ---
  @Deprecated('Use listTasks instead')
  Future<List<todoist.Task>> getActiveTasks({
    String? projectId,
    String? sectionId,
    String? label,
    String? filter,
    String? lang,
    List<String>? ids, // Changed to List<String> to match generated API
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
        ids: ids?.map(int.parse).toList(),
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
      errorMessage =
          error.message ?? 'Unknown API Exception (Code: $statusCode)';
      stderr.writeln(
        '[TodoistApiService] API Error - $context: $errorMessage',
      );
      if (statusCode == 401 || statusCode == 403) {
        final wasConfigured = _isCurrentlyConfigured;
        _isCurrentlyConfigured = false;
        _authStrategy = null; // Clear strategy
        stderr.writeln(
          '[TodoistApiService] Authentication error ($statusCode). Service marked as unconfigured internally.',
        );
        // Caller should update the isTodoistConfiguredProvider state.
      }
    } else {
      stderr.writeln('[TodoistApiService] Error - $context: $errorMessage');
      if (verboseLogging && error is Error) {
        stderr.writeln(error.stackTrace);
      }
    }
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

  Future<todoist.SyncResponse?> performSync({
    required List<String> resourceTypes,
  }) =>
      throw UnimplementedError(
        'performSync must be implemented by the concrete class',
      );

  Future<List<todoist.ActivityEvents>> getActivityEventsFromSync() =>
      throw UnimplementedError(
        'getActivityEventsFromSync must be implemented by the concrete class',
      );
}
