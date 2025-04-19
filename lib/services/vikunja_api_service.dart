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
import 'package:vikunja_api/api.dart' as vikunja; // Corrected path

/// Provider to expose the VikunjaApiService singleton instance
final vikunjaApiServiceProvider = Provider<VikunjaApiService>((ref) {
  return VikunjaApiService();
});

/// StateProvider to explicitly track if the Vikunja service is configured.
final isVikunjaConfiguredProvider = StateProvider<bool>(
  (ref) => VikunjaApiService().isConfigured,
  name: 'isVikunjaConfigured',
);

/// Service class for interacting with the Vikunja API
class VikunjaApiService implements TaskApiService {
  // Singleton pattern
  static final VikunjaApiService _instance = VikunjaApiService._internal();
  factory VikunjaApiService() => _instance;

  // --- Vikunja API Client Instances ---
  late vikunja.ApiClient _apiClient;
  late vikunja.TaskApi _tasksApi;
  // Add other Vikunja APIs as needed (Projects, Labels, etc.)
  // late vikunja.ProjectApi _projectsApi;
  // late vikunja.LabelApi _labelsApi;

  // --- Configuration ---
  String _apiBaseUrl = '';
  AuthStrategy? _authStrategy;
  bool _isCurrentlyConfigured = false;

  // Configuration and logging options
  static bool verboseLogging = false;

  @override
  String get apiBaseUrl => _apiBaseUrl;

  @override
  AuthStrategy? get authStrategy => _authStrategy;

  VikunjaApiService._internal() {
    // Initialize with dummy clients initially
    _initializeClient(null, '');
  }

  /// Configure the Vikunja API service with base URL and AuthStrategy.
  @override
  Future<void> configureService({
    required String baseUrl,
    AuthStrategy? authStrategy,
    @Deprecated('Use authStrategy instead') String? authToken,
  }) async {
    AuthStrategy? effectiveStrategy = authStrategy;
    if (effectiveStrategy == null && authToken != null && authToken.isNotEmpty) {
      effectiveStrategy = BearerTokenAuthStrategy(authToken);
      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] configureService: Using fallback BearerTokenAuthStrategy from authToken.',
        );
      }
    }

    final currentToken = _authStrategy?.getSimpleToken();
    final newToken = effectiveStrategy?.getSimpleToken();
    if (_apiBaseUrl == baseUrl && currentToken == newToken && _isCurrentlyConfigured) {
      if (verboseLogging) {
        stderr.writeln('[VikunjaApiService] configureService: Configuration unchanged.');
      }
      return;
    }

    _apiBaseUrl = baseUrl;
    _authStrategy = effectiveStrategy;
    _initializeClient(_authStrategy, _apiBaseUrl);
    _isCurrentlyConfigured = _authStrategy != null && _apiBaseUrl.isNotEmpty;

    if (verboseLogging) {
      stderr.writeln(
        '[VikunjaApiService] Configured with Base URL: $_apiBaseUrl, Strategy: ${_authStrategy?.runtimeType}. Configured: $_isCurrentlyConfigured',
      );
    }
  }

  /// Initializes the Vikunja API client and associated endpoint classes.
  void _initializeClient(AuthStrategy? strategy, String baseUrl) {
    try {
      // Use the strategy to create the Vikunja Authentication object
      final vikunja.Authentication? auth =
          strategy?.createVikunjaAuth(); // Use the new method

      _apiClient = vikunja.ApiClient(
        // Use correct type
        basePath: baseUrl,
        authentication: auth,
      );

      // Initialize Vikunja API endpoints
      _tasksApi = vikunja.TaskApi(_apiClient); // Use correct type
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
      _apiClient = vikunja.ApiClient(basePath: baseUrl); // Use correct type
      _tasksApi = vikunja.TaskApi(_apiClient); // Use correct type
    }
  }

  // --- BaseApiService Implementation ---

  @override
  bool get isConfigured => _isCurrentlyConfigured;

  @override
  Future<bool> checkHealth() async {
    if (!isConfigured) return false;
    try {
      await _tasksApi.tasksAllGet(perPage: 1);
      return true;
    } catch (e) {
      _handleApiError('Health check failed', e);
      return false;
    }
  }

  // --- TaskApiService Implementation ---

  @override
  Future<List<TaskItem>> listTasks({
    String? filter,
    ServerConfig? targetServerOverride,
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot list tasks.');
      return [];
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Getting all tasks (listTasks)');
    }
    try {
      final tasks = await _tasksApi.tasksAllGet(filter: filter);
      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] Retrieved ${tasks?.length ?? 0} raw tasks',
        );
      }
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
    ServerConfig? targetServerOverride,
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot get task $id.');
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Getting task by ID (getTask): $id');
    }
    late int taskIdInt;
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
    ServerConfig? targetServerOverride,
    int? projectId,
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot create task.');
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Creating task from TaskItem: ${taskItem.title}');
    }
    final targetProjectId = projectId ?? taskItem.projectId;
    if (targetProjectId == null) {
      throw Exception('Cannot create Vikunja task: Project ID is required.');
    }
    final request = _fromTaskItem(taskItem);
    request.projectId = targetProjectId;
    try {
      final createdVikunjaTask =
          await _tasksApi.projectsIdTasksPut(targetProjectId, request);
      if (createdVikunjaTask == null) {
        throw Exception("Task creation returned null from API");
      }
      if (verboseLogging) {
        stderr.writeln(
          '[VikunjaApiService] Raw Task created successfully with ID: ${createdVikunjaTask.id}',
        );
      }
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
    ServerConfig? targetServerOverride,
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot update task $id.');
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Updating task from TaskItem: $id');
    }
    late int taskIdInt;
    try {
      taskIdInt = int.parse(id);
    } catch (e) {
      throw Exception('Invalid task ID format: $id. Must be an integer for Vikunja.');
    }
    final request = _fromTaskItem(taskItem.copyWith(id: taskIdInt));
    try {
      final updatedVikunjaTask = await _tasksApi.tasksIdPost(taskIdInt, request);
      if (updatedVikunjaTask == null) {
        stderr.writeln('[VikunjaApiService] Update task $id returned null/empty. Fetching task manually.');
        return await getTask(id, targetServerOverride: targetServerOverride);
      }
      if (verboseLogging) {
        stderr.writeln('[VikunjaApiService] Raw task updated successfully: ${updatedVikunjaTask.id}');
      }
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
    ServerConfig? targetServerOverride,
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot delete task $id.');
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Deleting task (deleteTask): $id');
    }
    late int taskIdInt;
    try {
      taskIdInt = int.parse(id);
    } catch (e) {
      throw Exception('Invalid task ID format: $id. Must be an integer for Vikunja.');
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

  @override
  Future<void> completeTask(
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot complete task $id.');
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Completing task (completeTask): $id');
    }
    try {
      final currentTaskItem = await getTask(id, targetServerOverride: targetServerOverride);
      if (currentTaskItem.done) {
        if (verboseLogging) stderr.writeln('[VikunjaApiService] Task $id already completed.');
        return;
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
    ServerConfig? targetServerOverride,
  }) async {
    if (!isConfigured) {
      stderr.writeln('[VikunjaApiService] Not configured, cannot reopen task $id.');
      throw Exception('Vikunja API Service not configured.');
    }
    if (verboseLogging) {
      stderr.writeln('[VikunjaApiService] Reopening task (reopenTask): $id');
    }
    try {
      final currentTaskItem = await getTask(id, targetServerOverride: targetServerOverride);
      if (!currentTaskItem.done) {
        if (verboseLogging) stderr.writeln('[VikunjaApiService] Task $id already open.');
        return;
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

  // --- Task Comments (STUBBED) ---

  @override
  Future<List<Comment>> listComments(
    String taskId, {
    ServerConfig? targetServerOverride,
  }) async {
    if (!isConfigured) return [];
    stderr.writeln('[VikunjaApiService] listComments for task $taskId - STUBBED');
    throw UnimplementedError('listComments not implemented for Vikunja yet.');
  }

  @override
  Future<Comment> getComment(
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    if (!isConfigured) throw Exception('Vikunja API Service not configured.');
    stderr.writeln('[VikunjaApiService] getComment $commentId - STUBBED');
    throw UnimplementedError('getComment not implemented for Vikunja yet.');
  }

  @override
  Future<Comment> createComment(
    String taskId,
    Comment comment, {
    ServerConfig? targetServerOverride,
    List<Map<String, dynamic>>? resources,
  }) async {
    if (!isConfigured) throw Exception('Vikunja API Service not configured.');
    stderr.writeln('[VikunjaApiService] createComment for task $taskId - STUBBED');
    throw UnimplementedError('createComment not implemented for Vikunja yet.');
  }

  @override
  Future<Comment> updateComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  }) async {
    if (!isConfigured) throw Exception('Vikunja API Service not configured.');
    stderr.writeln('[VikunjaApiService] updateComment $commentId - STUBBED');
    throw UnimplementedError('updateComment not implemented for Vikunja yet.');
  }

  @override
  Future<void> deleteComment(
    String taskId,
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    if (!isConfigured) throw Exception('Vikunja API Service not configured.');
    stderr.writeln('[VikunjaApiService] deleteComment $commentId for task $taskId - STUBBED');
    throw UnimplementedError('deleteComment not implemented for Vikunja yet.');
  }

  // --- Resource Methods ---

  @override
  Future<Map<String, dynamic>> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  }) async {
    stderr.writeln(
      '[VikunjaApiService] uploadResource not directly supported. Attachments are linked via tasks/comments.',
    );
    throw UnimplementedError(
      "Vikunja handles resource uploads via task attachments. Use specific methods.",
    );
  }

  @override
  Future<Uint8List> getResourceData(
    String resourceIdentifier, {
    ServerConfig? targetServerOverride,
    String? taskId,
  }) async {
    stderr.writeln(
      '[VikunjaApiService] getResourceData requires fetching attachment details or URL.',
    );
    if (Uri.tryParse(resourceIdentifier)?.isAbsolute ?? false) {
      try {
        final response = await Client().get(Uri.parse(resourceIdentifier));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response.bodyBytes;
        } else {
          // Use the correct ApiException type from the imported package
          throw vikunja.ApiException(response.statusCode, utf8.decode(response.bodyBytes));
        }
      } catch (e) {
        throw Exception('Error downloading resource from $resourceIdentifier: $e');
      }
    } else {
      if (taskId == null) {
        throw ArgumentError('taskId is required when resourceIdentifier is an attachment ID.');
      }
      late int attachmentIdInt;
      late int taskIdInt;
      try {
        attachmentIdInt = int.parse(resourceIdentifier);
        taskIdInt = int.parse(taskId);
      } catch (e) {
        throw Exception('Invalid task ID or attachment ID format.');
      }
      try {
        final response =
            await _tasksApi.tasksIdAttachmentsAttachmentIDGetWithHttpInfo(taskIdInt, attachmentIdInt);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response.bodyBytes;
        } else {
          // Use the correct ApiException type from the imported package
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
    // Removed unused serverId parameter
    // Use the factory constructor defined in TaskItem
    return TaskItem.fromVikunjaTask(vTask);
  }

  /// Maps the app's TaskItem model to a Vikunja ModelsTask for API requests.
  vikunja.ModelsTask _fromTaskItem(TaskItem item) {
    // Use correct type
    return vikunja.ModelsTask(
      id: item.internalId, // Use the internal integer ID
      title: item.title,
      description: item.description,
      done: item.done,
      priority: item.priority,
      dueDate: item.dueDate?.toIso8601String(),
      projectId: item.projectId,
      bucketId: item.bucketId,
      percentDone: item.percentDone,
      // Map other relevant fields if needed
    );
  }

  // --- HELPER METHODS ---

  /// Helper to decode response body bytes safely.
  Future<Uint8List> _decodeBodyBytes(dynamic response) async {
    if (response is Response) {
      return response.bodyBytes;
    }
    return Uint8List(0);
  }

  /// Centralized error handling for API calls.
  void _handleApiError(String context, dynamic error) {
    String errorMessage = '$error';
    int? statusCode;

    // Use the correct ApiException type from the imported package
    if (error is vikunja.ApiException) {
      // Check for vikunja.ApiException
      statusCode = error.code;
      String? rawMessage = error.message;
      errorMessage = rawMessage ?? 'Unknown API Exception (Code: $statusCode)';

      // Try to extract HTML title/body if present
      if (rawMessage.contains('<title>')) {
        try {
          final titleMatch = RegExp(r'<title>(.*?)<\/title>').firstMatch(rawMessage);
          final bodyMatch =
              RegExp(r'<body>(.*?)<\/body>', dotAll: true).firstMatch(rawMessage);
          if (titleMatch != null) {
            errorMessage = titleMatch.group(1) ?? errorMessage;
          }
          if (bodyMatch != null) {
            final bodyText =
                bodyMatch.group(1)?.replaceAll(RegExp(r'<[^>]*>'), ' ').trim() ?? '';
            if (bodyText.isNotEmpty) {
              errorMessage += "\n$bodyText";
            }
          }
        } catch (_) {}
      }

      stderr.writeln(
          '[VikunjaApiService] API Error - $context: $errorMessage (Code: $statusCode)');

      if (statusCode == 401 || statusCode == 403) {
        stderr.writeln('[VikunjaApiService] Authentication error ($statusCode).');
      }
    } else {
      stderr.writeln('[VikunjaApiService] Error - $context: $errorMessage');
      if (verboseLogging && error is Error) {
        stderr.writeln(error.stackTrace);
      }
    }
  }
}
