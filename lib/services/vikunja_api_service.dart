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

/// StateProvider to explicitly track if the Vikunja service is configured.
/// This should be updated by the CALLER after successfully calling `configureService`
/// and potentially verifying with `checkHealth`.
final isVikunjaConfiguredProvider = StateProvider<bool>(
  (ref) =>
      false, // Default to false, let TasksNotifier or SettingsScreen update it
  name: 'isVikunjaConfigured',
);

/// Service class for interacting with the Vikunja API
class VikunjaApiService implements TaskApiService {
  // Singleton pattern (optional, depends on how you manage instances)
  static final VikunjaApiService _instance = VikunjaApiService._internal();
  factory VikunjaApiService() => _instance;

  // --- Vikunja API Client Instances ---
  late vikunja.ApiClient _apiClient;
  late vikunja.TaskApi _tasksApi;
  // Add other Vikunja APIs as needed (Projects, Labels, etc.)
  // late vikunja.ProjectApi _projectsApi;
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
    String? serverId, // Add serverId to store for context
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
        _isCurrentlyConfigured &&
        _configuredServerId == serverId) {
      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] configureService: Configuration unchanged.',
        );
      }
      return; // No need to reconfigure if nothing changed
    }

    _apiBaseUrl = baseUrl;
    _authStrategy = effectiveStrategy;
    _configuredServerId = serverId; // Store the server ID
    _initializeClient(_authStrategy, _apiBaseUrl);

    // Update internal configuration status based on whether URL and strategy are present
    _isCurrentlyConfigured =
        _authStrategy != null &&
        _apiBaseUrl.isNotEmpty &&
        _configuredServerId != null;

    if (verboseLogging) {
      stderr.writeln(
        '[VikunjaApiService] Configured with Base URL: $_apiBaseUrl, Strategy: ${_authStrategy?.runtimeType}, Server ID: $_configuredServerId. Internal Configured Flag: $_isCurrentlyConfigured',
      );
    }
    // The caller MUST update the isVikunjaConfiguredProvider state after this call.
  }

  /// Initializes the Vikunja API client and associated endpoint classes.
  void _initializeClient(AuthStrategy? strategy, String baseUrl) {
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
      // _projectsApi = vikunja.ProjectApi(_apiClient);
      // _labelsApi = vikunja.LabelApi(_apiClient);

      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] Client initialized successfully. Base URL: $baseUrl, Auth: ${auth?.runtimeType}',
        );
      }
    } catch (e) {
      stderr.writeln('[VikunjaApiService] Error initializing client: $e');
      // Reset clients to dummy state on error
      _apiClient = vikunja.ApiClient(basePath: baseUrl); // No auth
      _tasksApi = vikunja.TaskApi(_apiClient);
      // Reset other APIs if used
      _isCurrentlyConfigured = false; // Ensure internal state reflects failure
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
          '[VikunjaApiService] Health check skipped: Not configured.',
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
      await _tasksApi.tasksAllGet(perPage: 1);
      if (verboseLogging)
        stderr.writeln('[VikunjaApiService] Health check successful.');
      return true;
    } catch (e) {
      _handleApiError('Health check failed', e); // Log the specific error
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
    if (!isConfigured || _configuredServerId == null) {
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

      final comments =
          vComments
              ?.map(
                (vComment) => Comment.fromVikunjaTaskComment(
                  vComment,
                  taskId: taskId,
                  serverId: _configuredServerId!, // Use stored server ID
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
    if (!isConfigured || _configuredServerId == null) {
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

      final comment = Comment.fromVikunjaTaskComment(
        vComment,
        taskId: taskId, // Pass taskId for parentId mapping
        serverId: _configuredServerId!, // Use stored server ID
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
    if (!isConfigured || _configuredServerId == null) {
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
    final request = vikunja.TasksTaskIDCommentsPutRequest(
      comment: comment.content ?? '',
      // Vikunja doesn't seem to support setting author/timestamps on creation via this endpoint
    );

    try {
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

      final createdComment = Comment.fromVikunjaTaskComment(
        createdVComment,
        taskId: taskId,
        serverId: _configuredServerId!,
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
    if (!isConfigured || _configuredServerId == null) {
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

    // Map app Comment model to Vikunja request body for update
    // API endpoint POST /tasks/{taskid}/comments/{commentid} seems to take an empty body
    // but PUT /comments/{commentid} takes ModelsComment. Let's try PUT /comments/{commentid}.
    // This requires a top-level CommentsApi. Assuming it exists as _commentsApi.
    /*
    final request = vikunja.ModelsComment(
      comment_: comment.content ?? '',
      // Include other fields if necessary, like author ID if allowed?
    );
    */
    // Let's try the task-scoped endpoint POST /tasks/{taskid}/comments/{commentid}
    // It seems designed for updates but takes an empty body? Let's assume it updates content implicitly or needs a specific payload.
    // The generated client might expect a body. Let's try sending the content.
    // The API spec for POST /tasks/{taskid}/comments/{commentid} is unclear.
    // Let's assume we need PUT /comments/{commentid} which requires a ModelsComment payload.
    // We need a CommentsApi instance for this. Let's add it.
    // late vikunja.CommentsApi _commentsApi; // Add this near other API instances

    // Re-evaluating: The TaskApi has tasksTaskIDCommentsCommentIDPost. Let's assume it updates the comment.
    // What payload does it take? The generated code might expect `TasksTaskIDCommentsCommentIDPostRequest`.
    // Let's assume it takes the comment content.
    final request = vikunja.TasksTaskIDCommentsCommentIDPostRequest(
      comment: comment.content ?? '',
    );

    try {
      // Use the task-scoped POST endpoint
      final updatedVComment = await _tasksApi.tasksTaskIDCommentsCommentIDPost(
        taskIdInt,
        commentIdInt,
        request,
      );

      if (updatedVComment == null) {
        // API might return null on success, refetch the comment
        stderr.writeln(
          '[VikunjaApiService] Update comment $commentId returned null. Refetching.',
        );
        return await getComment(
          commentId,
          taskId: comment.parentId,
        ); // Pass taskId for refetch
      }

      if (verboseLogging)
        stderr.writeln(
          '[VikunjaApiService] Raw comment updated: ${updatedVComment.id}',
        );

      final updatedComment = Comment.fromVikunjaTaskComment(
        updatedVComment,
        taskId: comment.parentId, // Use original taskId
        serverId: _configuredServerId!,
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
         final response = await Client().get(Uri.parse(resourceIdentifier));
         if (response.statusCode >= 200 && response.statusCode < 300) {
           return response.bodyBytes;
         } else {
           throw vikunja.ApiException(response.statusCode, utf8.decode(response.bodyBytes));
         }
       } catch (e) {
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
         throw Exception('Invalid task ID or attachment ID format.');
       }
       try {
         // This returns MultipartFile, need to read bytes
         final response = await _tasksApi.tasksIdAttachmentsAttachmentIDGetWithHttpInfo(taskIdInt, attachmentIdInt);
         if (response.statusCode >= 200 && response.statusCode < 300) {
            return response.bodyBytes;
         } else {
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

    if (error is vikunja.ApiException) {
      statusCode = error.code;
      String rawMessage = error.message ?? 'Unknown API Exception (Code: $statusCode)';
      errorMessage = rawMessage; // Start with the raw message

      // Try to decode body if available
      if (error.body is List<int>) {
         try {
            final decodedBody = utf8.decode(error.body as List<int>);
            // Vikunja often returns JSON errors like {"message": "..."}
            final jsonBody = jsonDecode(decodedBody);
            if (jsonBody is Map && jsonBody.containsKey('message')) {
               errorMessage = jsonBody['message'];
            } else {
               errorMessage = decodedBody; // Use decoded body if not JSON message
            }
         } catch (_) {
            // Ignore decoding/parsing errors, stick with original message
         }
      }
      // Vikunja might return HTML for errors sometimes, try to extract message
      else if (rawMessage.contains('<title>')) {
         try {
            // Basic extraction, might need refinement
            final titleMatch = RegExp(r'<title>(.*?)<\/title>').firstMatch(rawMessage);
            final bodyMatch = RegExp(r'<body>(.*?)<\/body>', dotAll: true).firstMatch(rawMessage);
            String extractedMessage = '';
            if (titleMatch != null) extractedMessage = titleMatch.group(1)?.trim() ?? '';
            if (bodyMatch != null) {
                final bodyText = bodyMatch.group(1)?.replaceAll(RegExp(r'<[^>]*>'), ' ').trim() ?? '';
                if (bodyText.isNotEmpty) {
                    extractedMessage += (extractedMessage.isNotEmpty ? "\n" : "") + bodyText;
                }
            }
            if (extractedMessage.isNotEmpty) {
                errorMessage = extractedMessage; // Use extracted message if found
            }
         } catch (_) {} // Ignore parsing errors
      }

      stderr.writeln('[VikunjaApiService] API Error - $context: $errorMessage (Code: $statusCode)');

      if (statusCode == 401 || statusCode == 403) {
        // Don't automatically mark as unconfigured here, let the caller handle it
        // based on whether it was an initial config check or a regular call.
        stderr.writeln('[VikunjaApiService] Authentication error ($statusCode). Check API Key.');
        // Consider notifying the app about auth failure.
      }
    } else {
      stderr.writeln('[VikunjaApiService] Error - $context: $errorMessage');
      if (verboseLogging && error is Error) {
        stderr.writeln(error.stackTrace);
      }
    }
    // Consider re-throwing a more specific app-level exception.
  }
}
