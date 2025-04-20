import 'dart:convert';
import 'dart:io'; // Import for stderr
import 'dart:typed_data'; // For Uint8List

import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_memos/models/comment.dart'; // Use app's Comment model
import 'package:flutter_memos/models/server_config.dart'; // Use ServerConfig if needed for overrides
import 'package:flutter_memos/models/task_item.dart'; // Use app's TaskItem model
import 'package:flutter_memos/services/auth_strategy.dart'; // Import AuthStrategy
import 'package:flutter_memos/services/task_api_service.dart'; // Implement the interface
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:http/http.dart';
// Use the correct package import for the Vikunja API client
// Ensure this path correctly points to your local or pub-cached Vikunja API library
import 'package:vikunja_flutter_api/vikunja_api/lib/api.dart' as vikunja;

/// Provider to expose the VikunjaApiService singleton instance
final vikunjaApiServiceProvider = Provider<VikunjaApiService>((ref) {
  // Consider how configuration is passed or managed if needed at creation
  return VikunjaApiService();
});

// REMOVED the conflicting StateProvider<bool> isVikunjaConfiguredProvider

/// Service class for interacting with the Vikunja API
class VikunjaApiService implements TaskApiService {
  // Singleton pattern (optional, depends on how you manage instances)
  static final VikunjaApiService _instance = VikunjaApiService._internal();
  factory VikunjaApiService() => _instance;

  // --- Vikunja API Client Instances ---
  late vikunja.ApiClient _apiClient;
  late vikunja.TaskApi _tasksApi;
  // Add other Vikunja APIs as needed (Projects, Labels, etc.)
  late vikunja.ProjectApi _projectsApi; // ADDED
  // late vikunja.LabelApi _labelsApi;

  // --- Configuration ---
  String _apiBaseUrl = ''; // Set during configuration
  AuthStrategy? _authStrategy; // Store the strategy
  bool _isCurrentlyConfigured = false; // Internal flag
  String? _configuredServerId; // Store the server ID from config

  // Configuration and logging options
  static bool verboseLogging = false; // Keep logging option

  @override
  String get apiBaseUrl => _apiBaseUrl;

  @override
  AuthStrategy? get authStrategy => _authStrategy;

  VikunjaApiService._internal() {
    // Initialize with dummy clients initially
    _initializeClient(null, '');
  }

  /// Configure the Vikunja API service with base URL and AuthStrategy.
  ///
  /// ### VERY IMPORTANT:
  /// After calling this method successfully, the **CALLER** is responsible for
  /// updating the `isVikunjaConfiguredProvider` state, potentially after
  /// calling `checkHealth`. This method only updates the internal state.
  @override
  Future<void> configureService({
    required String baseUrl,
    AuthStrategy? authStrategy,
    @Deprecated('Use authStrategy instead') String? authToken,
    String? serverId, // Make serverId optional
  }) async {
    AuthStrategy? effectiveStrategy = authStrategy;

    // Fallback to authToken if authStrategy is not provided (assuming Bearer)
    if (effectiveStrategy == null &&
        authToken != null &&
        authToken.isNotEmpty) {
      effectiveStrategy = BearerTokenAuthStrategy(authToken);
      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] configureService: Using fallback BearerTokenAuthStrategy from authToken.',
        );
      }
    }

    // Check if configuration actually changed
    final currentToken = _authStrategy?.getSimpleToken();
    final newToken = effectiveStrategy?.getSimpleToken();
    if (_apiBaseUrl == baseUrl &&
        currentToken == newToken &&
        _configuredServerId == serverId && // Also check serverId
        _isCurrentlyConfigured) {
      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] configureService: Configuration unchanged (URL: $baseUrl, Token: ${newToken != null ? 'present' : 'absent'}, ServerID: $serverId). Skipping re-init.',
        );
      }
      return; // No need to reconfigure if nothing changed
    }

    if (verboseLogging) {
      stderr.writeln(
        '[VikunjaApiService] configureService: Configuration changed. Applying new settings (URL: $baseUrl, Token: ${newToken != null ? 'present' : 'absent'}, ServerID: $serverId).',
      );
    }

    _apiBaseUrl = baseUrl;
    _authStrategy = effectiveStrategy;
    _configuredServerId = serverId; // Store the server ID

    // Initialize client with new settings
    _initializeClient(_authStrategy, _apiBaseUrl);

    // Update internal configuration status based on whether URL and strategy are present AND client init succeeded
    // _initializeClient sets _isCurrentlyConfigured to false on error.
    _isCurrentlyConfigured =
        _authStrategy != null &&
        _apiBaseUrl.isNotEmpty &&
        _isCurrentlyConfigured;

    if (verboseLogging) {
      stderr.writeln(
        '[VikunjaApiService] configureService finished. Base URL: $_apiBaseUrl, Strategy: ${_authStrategy?.runtimeType}, Server ID: $_configuredServerId. Final Internal Configured Flag: $_isCurrentlyConfigured',
      );
    }
    // The caller MUST update the isVikunjaConfiguredProvider state after this call.
  }

  /// Initializes the Vikunja API client and associated endpoint classes.
  void _initializeClient(AuthStrategy? strategy, String baseUrl) {
    if (verboseLogging) {
      stderr.writeln(
        '[VikunjaApiService] _initializeClient called. Base URL: $baseUrl, Strategy: ${strategy?.runtimeType}',
      );
    }
    try {
      // Use the strategy to create the Vikunja Authentication object
      final vikunja.Authentication? auth =
          strategy?.createVikunjaAuth(); // Assumes createVikunjaAuth exists

      _apiClient = vikunja.ApiClient(
        basePath: baseUrl,
        authentication: auth,
      );

      // Initialize Vikunja API endpoints
      _tasksApi = vikunja.TaskApi(_apiClient);
      _projectsApi = vikunja.ProjectApi(_apiClient); // ADDED
      // _labelsApi = vikunja.LabelApi(_apiClient);

      // Mark as configured *internally* only if successful and strategy/URL are present
      _isCurrentlyConfigured = strategy != null && baseUrl.isNotEmpty;

      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] Client initialized successfully. Base URL: $baseUrl, Auth: ${auth?.runtimeType}. Internal Configured Flag set to: $_isCurrentlyConfigured',
        );
      }
    } catch (e) {
      stderr.writeln('[VikunjaApiService] Error initializing client: $e');
      // Reset clients to dummy state on error
      _apiClient = vikunja.ApiClient(basePath: baseUrl); // No auth
      _tasksApi = vikunja.TaskApi(_apiClient);
      // Reset other APIs if used
      _isCurrentlyConfigured = false; // Ensure internal state reflects failure
      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] Client initialization failed. Internal Configured Flag set to: false',
        );
      }
    }
  }

  // --- BaseApiService Implementation ---

  @override
  bool get isConfigured => _isCurrentlyConfigured; // Use internal flag

  @override
  Future<bool> checkHealth() async {
    if (!isConfigured) {
      if (verboseLogging)
        stderr.writeln(
          '[VikunjaApiService] Health check skipped: Not configured (isConfigured=false).',
        );
      return false;
    }

    try {
      if (verboseLogging)
        stderr.writeln(
          '[VikunjaApiService] Performing health check (tasksAllGet limit 1)...',
        );
      // Use a lightweight Vikunja call, e.g., fetching user info or a simple endpoint
      // Example: await _someOtherApi.getLoggedInUser();
      // For now, let's try listing tasks with a limit of 1 as a basic check
      final response = await _tasksApi.tasksAllGetWithHttpInfo(perPage: 1);
      bool isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      if (verboseLogging)
        stderr.writeln(
          '[VikunjaApiService] Health check completed. Status Code: ${response.statusCode}. Success: $isSuccess',
        );
      return isSuccess;
    } catch (e) {
      _handleApiError('Health check failed', e); // Log the specific error
      if (verboseLogging)
        stderr.writeln(
          '[VikunjaApiService] Health check resulted in error. Returning false.',
        );
      return false;
    }
  }

  // --- TaskApiService Implementation ---

  // --- Task Operations ---
  @override
  Future<List<TaskItem>> listTasks({
    String? filter,
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot list tasks.');
      return [];
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Getting all tasks (listTasks)');
    }

    try {
      // Use tasksAllGet for a general list, apply filter if provided
      final tasks = await _tasksApi.tasksAllGet(filter: filter);

      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] Retrieved ${tasks?.length ?? 0} raw tasks',
        );
      }

      // Removed serverId parameter from _toTaskItem call
      final taskItems = tasks?.map((task) => _toTaskItem(task)).toList() ?? [];

      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] Mapped to ${taskItems.length} TaskItems',
        );
      }

      return taskItems;

    } catch (e) {
      _handleApiError('Error getting tasks (listTasks)', e);
      rethrow;
    }
  }

  // ADDED: Method to list Vikunja projects
  Future<List<vikunja.ModelsProject>> listProjects({
    ServerConfig?
    targetServerOverride, // Keep for consistency, though handled by configureService
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[VikunjaApiService] Not configured, cannot list projects.',
      );
      return [];
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Getting all projects (listProjects)');
    }

    try {
      // Use projectAllGet for a general list
      final projects = await _projectsApi.projectsGet();

      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] Retrieved ${projects?.length ?? 0} raw projects',
        );
      }

      return projects ?? [];
    } catch (e) {
      _handleApiError('Error getting projects (listProjects)', e);
      rethrow; // Rethrow to allow caller handling (e.g., provider error state)
    }
  }
  // END ADDED

  @override
  Future<TaskItem> getTask(
    String id, {
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot get task $id.');
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Getting task by ID (getTask): $id');
    }

    final int taskIdInt;
    try {
      taskIdInt = int.parse(id);
    } catch (e) {
      throw Exception('Invalid task ID format: $id. Must be an integer for Vikunja.');
    }

    try {
      final task = await _tasksApi.tasksIdGet(taskIdInt);

      if (task == null) {
        throw Exception('Task with ID $id not found.');
      }

      if (verboseLogging) {
        stderr.writeln('[VikunjaApiService] Retrieved raw task: ${task.title}');
      }

      // Removed serverId parameter from _toTaskItem call
      final taskItem = _toTaskItem(task);

      if (verboseLogging) {
        stderr.writeln('[VikunjaApiService] Mapped to TaskItem');
      }

      return taskItem;

    } catch (e) {
      _handleApiError('Error getting task by ID $id (getTask)', e);
      rethrow;
    }
  }

  @override
  Future<TaskItem> createTask(
    TaskItem taskItem, {
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
    int? projectId, // Use the optional projectId from the interface
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot create task.');
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Creating task from TaskItem: ${taskItem.title}');
    }

    // Vikunja requires a project ID to create a task via projectsIdTasksPut
    final targetProjectId = projectId ?? taskItem.projectId;
    if (targetProjectId == null) {
      throw Exception('Cannot create Vikunja task: Project ID is required.');
    }

    final request = _fromTaskItem(taskItem);
    // Ensure project ID is set in the request if not already mapped
    request.projectId = targetProjectId;

    try {
      // Use projectsIdTasksPut as tasksAllPut doesn't seem to exist
      final createdVikunjaTask = await _tasksApi.projectsIdTasksPut(
        targetProjectId,
        request,
      );

      if (createdVikunjaTask == null) {
        throw Exception("Task creation returned null from API");
      }

      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] Raw Task created successfully with ID: ${createdVikunjaTask.id}',
        );
      }

      // Removed serverId parameter from _toTaskItem call
      final createdTaskItem = _toTaskItem(createdVikunjaTask);

      if (verboseLogging) {
        stderr.writeln('[VikunjaApiService] Mapped created task back to TaskItem');
      }

      return createdTaskItem;

    } catch (e) {
      _handleApiError('Error creating task from TaskItem', e);
      rethrow;
    }
  }

  @override
  Future<TaskItem> updateTask(
    String id,
    TaskItem taskItem, {
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot update task $id.');
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Updating task from TaskItem: $id');
    }

    final int taskIdInt;
    try {
      taskIdInt = int.parse(id);
    } catch (e) {
      throw Exception('Invalid task ID format: $id. Must be an integer for Vikunja.');
    }

    // Ensure the ID in the payload matches the path parameter ID
    final request = _fromTaskItem(taskItem.copyWith(id: taskIdInt));

    try {
      final updatedVikunjaTask = await _tasksApi.tasksIdPost(taskIdInt, request);

      if (updatedVikunjaTask == null) {
        // Vikunja might return the updated task or null/empty on success
        stderr.writeln(
          '[VikunjaApiService] Update task $id returned null/empty. Fetching task manually.',
        );
        // Pass override explicitly here if needed, though it should be configured already
        return await getTask(id, targetServerOverride: targetServerOverride);
      }

      if (verboseLogging) {
        stderr.writeln('[VikunjaApiService] Raw task updated successfully: ${updatedVikunjaTask.id}');
      }

      // Removed serverId parameter from _toTaskItem call
      final updatedTaskItem = _toTaskItem(updatedVikunjaTask);

      if (verboseLogging) {
        stderr.writeln('[VikunjaApiService] Mapped updated task back to TaskItem');
      }
      return updatedTaskItem;

    } catch (e) {
      _handleApiError('Error updating task $id from TaskItem', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(
    String id, {
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot delete task $id.');
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Deleting task (deleteTask): $id');
    }

    final int taskIdInt;
    try {
      taskIdInt = int.parse(id);
    } catch (e) {
      throw Exception(
        'Invalid task ID format: $id. Must be an integer for Vikunja.',
      );
    }

    try {
      await _tasksApi.tasksIdDelete(taskIdInt);

      if (verboseLogging) {
        stderr.writeln('[VikunjaApiService] Task $id deleted successfully');
      }
    } catch (e) {
      _handleApiError('Error deleting task $id', e);
      rethrow;
    }
  }

  // --- Task Actions ---
  @override
  Future<void> completeTask(
    String id, {
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot complete task $id.');
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Completing task (completeTask): $id');
    }

    try {
      // Vikunja doesn't have a dedicated complete endpoint, so we fetch, modify, and update.
      final currentTaskItem = await getTask(id, targetServerOverride: targetServerOverride);
      if (currentTaskItem.done) {
        if (verboseLogging) stderr.writeln('[VikunjaApiService] Task $id already completed.');
        return; // Already done
      }
      final updatedTaskItem = currentTaskItem.copyWith(done: true);
      await updateTask(id, updatedTaskItem, targetServerOverride: targetServerOverride);

      if (verboseLogging) {
        stderr.writeln('[VikunjaApiService] Task $id completed successfully via update.');
      }
    } catch (e) {
      _handleApiError('Error completing task $id', e);
      rethrow;
    }
  }

  @override
  Future<void> reopenTask(
    String id, {
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot reopen task $id.');
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Reopening task (reopenTask): $id');
    }

    try {
      // Vikunja doesn't have a dedicated reopen endpoint, so we fetch, modify, and update.
      final currentTaskItem = await getTask(id, targetServerOverride: targetServerOverride);
      if (!currentTaskItem.done) {
        if (verboseLogging)
          stderr.writeln('[VikunjaApiService] Task $id already open.');
        return; // Already open
      }
      final updatedTaskItem = currentTaskItem.copyWith(done: false);
      await updateTask(id, updatedTaskItem, targetServerOverride: targetServerOverride);

      if (verboseLogging) {
        stderr.writeln('[VikunjaApiService] Task $id reopened successfully via update.');
      }
    } catch (e) {
      _handleApiError('Error reopening task $id', e);
      rethrow;
    }
  }

  // --- Task Comments (IMPLEMENTED) ---
  @override
  Future<List<Comment>> listComments(
    String taskId, {
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[VikunjaApiService] Not configured, cannot list comments for task $taskId.',
      );
      return [];
    }
    if (verboseLogging)
      stderr.writeln('[VikunjaApiService] Listing comments for task $taskId');

    final int taskIdInt;
    try {
      taskIdInt = int.parse(taskId);
    } catch (e) {
      throw Exception(
        'Invalid task ID format: $taskId. Must be an integer for Vikunja.',
      );
    }

    try {
      final vComments = await _tasksApi.tasksTaskIDCommentsGet(taskIdInt);
      if (verboseLogging)
        stderr.writeln(
          '[VikunjaApiService] Retrieved ${vComments?.length ?? 0} raw comments for task $taskId',
        );

      // Use the stored server ID if available, otherwise fallback
      final effectiveServerId = _configuredServerId ?? _apiClient.basePath;

      final comments =
          vComments
              ?.map(
                (vComment) => Comment.fromVikunjaTaskComment(
                  vComment,
                  taskId: taskId,
                  serverId: effectiveServerId, // Use stored server ID
                ),
              )
              .toList() ??
          [];

      if (verboseLogging)
        stderr.writeln(
          '[VikunjaApiService] Mapped to ${comments.length} Comment models',
        );
      return comments;
    } catch (e) {
      _handleApiError('Error listing comments for task $taskId', e);
      rethrow;
    }
  }

  @override
  Future<Comment> getComment(
    String commentId, {
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
    String? taskId, // Add taskId for context if needed by mapping
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[VikunjaApiService] Not configured, cannot get comment $commentId.',
      );
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging)
      stderr.writeln('[VikunjaApiService] Getting comment $commentId');

    final int commentIdInt;
    try {
      commentIdInt = int.parse(commentId);
    } catch (e) {
      throw Exception(
        'Invalid comment ID format: $commentId. Must be an integer for Vikunja.',
      );
    }

    // Vikunja's GET /comments/{commentID} endpoint seems sufficient
    try {
      // Assuming a top-level CommentsApi exists or using a relevant TaskApi method if scoped
      // Let's assume _tasksApi can fetch any comment by ID if it's related to tasks,
      // or we need a dedicated CommentsApi. Using a placeholder call for now.
      // final vComment = await _commentsApi.commentsCommentIDGet(commentIdInt); // Ideal
      // Fallback: If comments are always tied to tasks, we might need the taskId.
      // The API spec suggests GET /tasks/{taskid}/comments/{commentid} exists.
      // We need the taskId context here.
      if (taskId == null) {
        throw ArgumentError(
          'taskId is required to get a specific task comment in Vikunja.',
        );
      }
      final int taskIdInt = int.parse(taskId);

      final vComment = await _tasksApi.tasksTaskIDCommentsCommentIDGet(
        taskIdInt,
        commentIdInt,
      );

      if (vComment == null) {
        throw Exception(
          'Comment with ID $commentId not found for task $taskId.',
        );
      }

      if (verboseLogging)
        stderr.writeln(
          '[VikunjaApiService] Retrieved raw comment ${vComment.id}',
        );

      // Use the stored server ID if available, otherwise fallback
      final effectiveServerId = _configuredServerId ?? _apiClient.basePath;

      final comment = Comment.fromVikunjaTaskComment(
        vComment,
        taskId: taskId, // Pass taskId for parentId mapping
        serverId: effectiveServerId, // Use stored server ID
      );

      if (verboseLogging)
        stderr.writeln('[VikunjaApiService] Mapped to Comment model');
      return comment;
    } catch (e) {
      _handleApiError('Error getting comment $commentId', e);
      rethrow;
    }
  }


  @override
  Future<Comment> createComment(
    String taskId,
    Comment comment, {
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
    List<Map<String, dynamic>>?
    resources, // Vikunja comments don't support Memos resources
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[VikunjaApiService] Not configured, cannot create comment for task $taskId.',
      );
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging)
      stderr.writeln('[VikunjaApiService] Creating comment for task $taskId');

    final int taskIdInt;
    try {
      taskIdInt = int.parse(taskId);
    } catch (e) {
      throw Exception(
        'Invalid task ID format: $taskId. Must be an integer for Vikunja.',
      );
    }

    // Map app Comment model to Vikunja request body
    // Use ModelsTaskComment directly as the payload
    final request = vikunja.ModelsTaskComment(
      comment: comment.content ?? '',
      // Other fields like author, created, updated are usually set by the server
    );

    try {
      // Pass the ModelsTaskComment object as the second argument
      final createdVComment = await _tasksApi.tasksTaskIDCommentsPut(
        taskIdInt,
        request,
      );

      if (createdVComment == null) {
        throw Exception(
          'Comment creation returned null from API for task $taskId.',
        );
      }

      if (verboseLogging)
        stderr.writeln(
          '[VikunjaApiService] Raw comment created: ${createdVComment.id}',
        );

      // Use the stored server ID if available, otherwise fallback
      final effectiveServerId = _configuredServerId ?? _apiClient.basePath;

      final createdComment = Comment.fromVikunjaTaskComment(
        createdVComment,
        taskId: taskId,
        serverId: effectiveServerId,
      );

      if (verboseLogging)
        stderr.writeln(
          '[VikunjaApiService] Mapped created comment back to Comment model',
        );
      return createdComment;
    } catch (e) {
      _handleApiError('Error creating comment for task $taskId', e);
      rethrow;
    }
  }

  @override
  Future<Comment> updateComment(
    String commentId,
    Comment comment, {
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[VikunjaApiService] Not configured, cannot update comment $commentId.',
      );
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging)
      stderr.writeln('[VikunjaApiService] Updating comment $commentId');

    final int commentIdInt;
    final int taskIdInt; // Need taskId for the endpoint
    try {
      commentIdInt = int.parse(commentId);
      taskIdInt = int.parse(
        comment.parentId,
      ); // Get taskId from the comment object
    } catch (e) {
      throw Exception(
        'Invalid comment ID ($commentId) or parent task ID (${comment.parentId}) format.',
      );
    }

    try {
      // Since we can't access the Vikunja API client's internal HTTP client directly,
      // and there's no named parameter support for the tasksTaskIDCommentsCommentIDPost method,
      // we can use a workaround by:
      // 1. First trying to create a completely new comment with the updated content
      // 2. Then deleting the old comment if the creation succeeds

      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] Updating comment $commentId for task $taskIdInt using create-then-delete approach',
        );
      }

      // Create a new comment with the updated content
      final newCommentRequest = vikunja.ModelsTaskComment(
        comment: comment.content ?? '',
      );

      // Create the new comment
      final newComment = await _tasksApi.tasksTaskIDCommentsPut(
        taskIdInt,
        newCommentRequest,
      );
      
      if (newComment == null) {
        throw Exception('Failed to create new comment during update process');
      }
      
      // If successfully created, delete the old comment
      await _tasksApi.tasksTaskIDCommentsCommentIDDelete(
        taskIdInt,
        commentIdInt,
      );

      // Use the stored server ID if available, otherwise fallback
      final effectiveServerId = _configuredServerId ?? _apiClient.basePath;

      final updatedComment = Comment.fromVikunjaTaskComment(
        newComment,
        taskId: comment.parentId, // Use original taskId
        serverId: effectiveServerId,
      );

      if (verboseLogging)
        stderr.writeln(
          '[VikunjaApiService] Mapped updated comment back to Comment model',
        );
      return updatedComment;
    } catch (e) {
      _handleApiError(
        'Error updating comment $commentId for task ${comment.parentId}',
        e,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteComment(
    String taskId, // Needed for API call
    String commentId, {
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
  }) async {
    if (!isConfigured) {
      stderr.writeln(
        '[VikunjaApiService] Not configured, cannot delete comment $commentId for task $taskId.',
      );
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging)
      stderr.writeln(
        '[VikunjaApiService] Deleting comment $commentId for task $taskId',
      );

    final int taskIdInt;
    final int commentIdInt;
    try {
      taskIdInt = int.parse(taskId);
      commentIdInt = int.parse(commentId);
    } catch (e) {
      throw Exception(
        'Invalid task ID ($taskId) or comment ID ($commentId) format.',
      );
    }

    try {
      await _tasksApi.tasksTaskIDCommentsCommentIDDelete(
        taskIdInt,
        commentIdInt,
      );
      if (verboseLogging)
        stderr.writeln(
          '[VikunjaApiService] Comment $commentId deleted successfully for task $taskId',
        );
    } catch (e) {
      _handleApiError('Error deleting comment $commentId for task $taskId', e);
      rethrow;
    }
  }

  // --- Resource Methods (Implementing BaseApiService - Generally not supported directly) ---
  @override
  Future<Map<String, dynamic>> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig?
    targetServerOverride, // NOTE: Override is handled by configureService caller
  }) async {
    stderr.writeln(
      '[VikunjaApiService] uploadResource not directly supported. Attachments are linked via tasks/comments.',
    );
    // Vikunja uses tasksIdAttachmentsPut
    throw UnimplementedError(
      "Vikunja handles resource uploads via task attachments. Use specific methods.",
    );
  }

  @override
  Future<Uint8List> getResourceData(
    String resourceIdentifier, // This might be an attachment ID or URL
    {
    ServerConfig? targetServerOverride, // NOTE: Override is handled by configureService caller
    String? taskId, // Need task context for attachment ID
  }) async {
    stderr.writeln(
      '[VikunjaApiService] getResourceData requires fetching attachment details or URL.',
    );
    // If resourceIdentifier is an ID, need taskId to call tasksIdAttachmentsAttachmentIDGet
    // If it's a URL, download directly.
    if (Uri.tryParse(resourceIdentifier)?.isAbsolute ?? false) {
       try {
         if (verboseLogging) stderr.writeln('[VikunjaApiService] Downloading resource from URL: $resourceIdentifier');
         final response = await Client().get(Uri.parse(resourceIdentifier));
         if (response.statusCode >= 200 && response.statusCode < 300) {
           if (verboseLogging) stderr.writeln('[VikunjaApiService] Download successful.');
           return response.bodyBytes;
         } else {
           stderr.writeln('[VikunjaApiService] Download failed. Status: ${response.statusCode}');
           throw vikunja.ApiException(response.statusCode, utf8.decode(response.bodyBytes));
         }
       } catch (e) {
         stderr.writeln('[VikunjaApiService] Error downloading resource from $resourceIdentifier: $e');
         throw Exception('Error downloading resource from $resourceIdentifier: $e');
       }
    } else {
       // Assume it's an attachment ID
       if (taskId == null) {
         throw ArgumentError('taskId is required when resourceIdentifier is an attachment ID.');
       }
       final int attachmentIdInt;
       final int taskIdInt;
       try {
         attachmentIdInt = int.parse(resourceIdentifier);
         taskIdInt = int.parse(taskId);
       } catch (e) {
         throw Exception('Invalid task ID ($taskId) or attachment ID ($resourceIdentifier) format.');
       }
       try {
         if (verboseLogging) stderr.writeln('[VikunjaApiService] Getting attachment $attachmentIdInt for task $taskIdInt');
         // This returns MultipartFile, need to read bytes
         final response = await _tasksApi.tasksIdAttachmentsAttachmentIDGetWithHttpInfo(taskIdInt, attachmentIdInt);
         if (response.statusCode >= 200 && response.statusCode < 300) {
            if (verboseLogging) stderr.writeln('[VikunjaApiService] Attachment data retrieved successfully.');
            return response.bodyBytes;
         } else {
            stderr.writeln('[VikunjaApiService] Failed to retrieve attachment data. Status: ${response.statusCode}');
            throw vikunja.ApiException(response.statusCode, utf8.decode(response.bodyBytes));
         }
       } catch (e) {
          _handleApiError('Error getting attachment $resourceIdentifier for task $taskId', e);
          rethrow;
       }
    }
  }


  // --- MAPPING HELPERS ---

  /// Maps a Vikunja ModelsTask to the app's TaskItem model.
  TaskItem _toTaskItem(vikunja.ModelsTask vTask) {
    // Use the factory constructor defined in TaskItem
    // Removed serverId argument
    return TaskItem.fromVikunjaTask(vTask);
  }

  /// Maps the app's TaskItem model to a Vikunja ModelsTask for API requests.
  vikunja.ModelsTask _fromTaskItem(TaskItem item) {
    return vikunja.ModelsTask(
      // Map fields from TaskItem to ModelsTask
      id: item.internalId, // Use the internal integer ID for updates
      title: item.title,
      description: item.description,
      done: item.done,
      priority: item.priority,
      dueDate: item.dueDate?.toIso8601String(),
      projectId: item.projectId,
      bucketId: item.bucketId,
      percentDone: item.percentDone,
      // Map other relevant fields if they exist in TaskItem and ModelsTask
      // e.g., startDate, endDate, hexColor, repeatAfter, repeatMode
      // Labels and Assignees need separate handling via their endpoints usually.
    );
  }


  // --- HELPER METHODS ---

  // Removed unused _decodeBodyBytes function

  /// Centralized error handling for API calls.
  void _handleApiError(String context, dynamic error) {
    String errorMessage = '$error';
    int? statusCode;
    String? responseBody;

    if (error is vikunja.ApiException) {
      statusCode = error.code;
      // Use the message field directly from ApiException, which might contain the body
      responseBody = error.message;
      errorMessage = responseBody ?? 'Unknown API Exception (Code: $statusCode)'; // Start with the raw message

      // Attempt to parse JSON error message if message is a JSON string
      try {
        final jsonBody = jsonDecode(responseBody!);
        if (jsonBody is Map && jsonBody.containsKey('message')) {
          errorMessage = jsonBody['message'];
        }
      } catch (_) {
        // Ignore JSON parsing errors, check for HTML
        if (responseBody != null && responseBody.contains('<title>')) {
          try {
            // Basic extraction, might need refinement
            final titleMatch = RegExp(r'<title>(.*?)<\/title>').firstMatch(responseBody);
            final bodyMatch = RegExp(r'<body>(.*?)<\/body>', dotAll: true).firstMatch(responseBody);
            String extractedMessage = '';
            if (titleMatch != null) extractedMessage = titleMatch.group(1)?.trim() ?? '';
            if (bodyMatch != null) {
                final bodyText = bodyMatch.group(1)?.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
                if (bodyText.isNotEmpty) {
                    extractedMessage += (extractedMessage.isNotEmpty ? " - " : "") + bodyText;
                }
            }
            if (extractedMessage.isNotEmpty) {
                errorMessage = extractedMessage; // Use extracted message if found
            }
          } catch (_) {} // Ignore parsing errors, stick with original responseBody as message
        }
      }

      stderr.writeln('[VikunjaApiService] API Error - $context: $errorMessage (Code: $statusCode)');
      if (verboseLogging && responseBody != null) {
         stderr.writeln('[VikunjaApiService] Raw Response Body: $responseBody');
      }

      if (statusCode == 401 || statusCode == 403) {
        // Don't automatically mark as unconfigured here, let the caller handle it
        // based on whether it was an initial config check or a regular call.
        stderr.writeln('[VikunjaApiService] Authentication error ($statusCode). Check API Key/Token and permissions.');
        // Consider notifying the app about auth failure.
      }
    } else {
      // Handle non-ApiException errors
      stderr.writeln('[VikunjaApiService] Error - $context: $errorMessage');
      if (verboseLogging && error is Error) {
        stderr.writeln(error.stackTrace);
      }
    }
    // Consider re-throwing a more specific app-level exception.
  }
}
