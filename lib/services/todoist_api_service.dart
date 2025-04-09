import 'dart:convert'; // For potential decoding helpers

import 'package:flutter/foundation.dart'; // Import foundation for debugPrint
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;
import 'package:http/http.dart' as http; // For Response type if needed

/// Service class for interacting with the Todoist API
///
/// This class wraps the auto-generated Todoist API client
/// and provides convenient methods for common operations.
class TodoistApiService {
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
  static bool verboseLogging = true;
  String get apiBaseUrl => _baseUrl;

  TodoistApiService._internal() {
    // Initialize with empty token - will need to be configured later
    _initializeClient('');
  }

  /// Configure the Todoist API service with authentication token
  void configureService({required String authToken}) {
    if (_authToken == authToken && _authToken.isNotEmpty) {
      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Configuration unchanged.',
        ); // Use debugPrint
      }
      return;
    }

    _authToken = authToken;
    _initializeClient(_authToken);

    if (verboseLogging) {
      debugPrint(
        '[TodoistApiService] Configured with ${authToken.isNotEmpty ? 'valid' : 'empty'} token',
      ); // Use debugPrint
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
        debugPrint(
          '[TodoistApiService] Client initialized successfully',
        ); // Use debugPrint
      }
    } catch (e) {
      debugPrint(
        '[TodoistApiService] Error initializing client: $e',
      ); // Use debugPrint
      throw Exception('Failed to initialize Todoist API client: $e');
    }
  }

  // TASKS METHODS

  /// Get all active tasks, optionally filtered by parameters
  Future<List<todoist.Task>> getActiveTasks({
    String? projectId,
    String? sectionId,
    String? label,
    String? filter,
    String? lang,
    List<int>? ids,
  }) async {
    if (verboseLogging) {
      debugPrint('[TodoistApiService] Getting active tasks'); // Use debugPrint
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
        debugPrint(
          '[TodoistApiService] Retrieved ${tasks?.length ?? 0} tasks',
        ); // Use debugPrint
      }

      return tasks ?? [];
    } catch (e) {
      _handleApiError('Error getting active tasks', e);
      rethrow;
    }
  }

  /// Create a new task
  Future<todoist.Task> createTask({
    required String content,
    String? description,
    String? projectId,
    String? sectionId,
    String? parentId,
    String? orderStr, // Keep as String for input flexibility
    List<String>? labelIds,
    String? priority, // Keep as String for input flexibility
    todoist.TaskDue? due, // Use the generated TaskDue model
    todoist.TaskDuration? duration, // Use the generated TaskDuration model
    String? assigneeId,
  }) async {
    if (verboseLogging) {
      debugPrint(
        '[TodoistApiService] Creating task: $content',
      ); // Use debugPrint
    }

    // The generated CreateTaskRequest model expects specific types.
    final request = todoist.CreateTaskRequest(
      content: content,
      description: description,
      projectId: projectId,
      sectionId: sectionId,
      parentId: parentId,
      order:
          orderStr != null ? int.tryParse(orderStr) : null, // API expects int
      labels: labelIds ?? [], // API expects List<String>, ensure non-null
      priority:
          priority != null ? int.tryParse(priority) : null, // API expects int
      // Access nested properties from dueObject and durationObject
      dueString: due?.dueObject?.string,
      dueDate: due?.dueObject?.date.toIso8601String().substring(
        0,
        10,
      ), // Format as YYYY-MM-DD
      dueDatetime: due?.dueObject?.datetime?.toIso8601String(),
      dueLang:
          due
              ?.dueObject
              ?.timezone, // Assuming lang maps to timezone here, adjust if needed
      duration: duration?.durationObject?.amount,
      durationUnit: duration?.durationObject?.unit,
      assigneeId: assigneeId,
    );

    try {
      final task = await _tasksApi.createTask(request);

      if (task == null) {
        throw Exception("Task creation returned null");
      }

      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Task created successfully with ID: ${task.id}',
        ); // Use debugPrint
      }

      return task;
    } catch (e) {
      _handleApiError('Error creating task', e);
      rethrow;
    }
  }


  /// Update an existing task
  Future<void> updateTask({
    required String
    id, // Task ID is usually a string in Todoist API v2 responses
    String? content,
    String? description,
    List<String>? labelIds,
    String? priority, // Keep as String for input flexibility
    todoist.TaskDue? due, // Use the generated TaskDue model
    todoist.TaskDuration? duration, // Use the generated TaskDuration model
    String? assigneeId,
  }) async {
    if (verboseLogging) {
      debugPrint('[TodoistApiService] Updating task: $id'); // Use debugPrint
    }

    // The generated UpdateTaskRequest model expects specific types.
    final request = todoist.UpdateTaskRequest(
      content: content,
      description: description,
      labels: labelIds ?? [], // Provide default empty list
      priority:
          priority != null ? int.tryParse(priority) : null, // API expects int
      // Access nested properties from dueObject and durationObject
      dueString: due?.dueObject?.string,
      dueDate: due?.dueObject?.date.toIso8601String().substring(
        0,
        10,
      ), // Format as YYYY-MM-DD
      dueDatetime: due?.dueObject?.datetime?.toIso8601String(),
      dueLang:
          due
              ?.dueObject
              ?.timezone, // Assuming lang maps to timezone here, adjust if needed
      duration: duration?.durationObject?.amount,
      durationUnit: duration?.durationObject?.unit,
      assigneeId: assigneeId,
    );

    try {
      // The generated updateTask expects the task ID as a String
      await _tasksApi.updateTask(id, request);

      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Task updated successfully',
        ); // Use debugPrint
      }
    } catch (e) {
      _handleApiError('Error updating task', e);
      rethrow;
    }
  }


  /// Close (complete) a task
  Future<void> closeTask(String id) async {
    if (verboseLogging) {
      debugPrint('[TodoistApiService] Closing task: $id'); // Use debugPrint
    }

    try {
      // Parse String ID to int as expected by the generated API
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        throw ArgumentError('Invalid task ID format: $id');
      }
      await _tasksApi.closeTask(taskIdInt);

      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Task closed successfully',
        ); // Use debugPrint
      }
    } catch (e) {
      _handleApiError('Error closing task', e);
      rethrow;
    }
  }

  /// Reopen a task
  Future<void> reopenTask(String id) async {
    if (verboseLogging) {
      debugPrint('[TodoistApiService] Reopening task: $id'); // Use debugPrint
    }

    try {
      // Parse String ID to int as expected by the generated API
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        throw ArgumentError('Invalid task ID format: $id');
      }
      await _tasksApi.reopenTask(taskIdInt);

      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Task reopened successfully',
        ); // Use debugPrint
      }
    } catch (e) {
      _handleApiError('Error reopening task', e);
      rethrow;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    if (verboseLogging) {
      debugPrint('[TodoistApiService] Deleting task: $id'); // Use debugPrint
    }

    try {
      // Parse String ID to int as expected by the generated API
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        throw ArgumentError('Invalid task ID format: $id');
      }
      await _tasksApi.deleteTask(taskIdInt);

      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Task deleted successfully',
        ); // Use debugPrint
      }
    } catch (e) {
      _handleApiError('Error deleting task', e);
      rethrow;
    }
  }


  // PROJECT METHODS

  /// Get all projects
  Future<List<todoist.Project>> getAllProjects() async {
    if (verboseLogging) {
      debugPrint('[TodoistApiService] Getting all projects'); // Use debugPrint
    }

    try {
      final projects = await _projectsApi.getAllProjects();

      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Retrieved ${projects?.length ?? 0} projects',
        ); // Use debugPrint
      }

      return projects ?? [];
    } catch (e) {
      _handleApiError('Error getting projects', e);
      rethrow;
    }
  }

  /// Get project by ID
  Future<todoist.Project> getProject(String id) async {
    if (verboseLogging) {
      debugPrint('[TodoistApiService] Getting project: $id'); // Use debugPrint
    }

    try {
      final project = await _projectsApi.getProject(id);

      if (project == null) {
        throw Exception("Project not found: $id");
      }

      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Retrieved project: ${project.name}',
        ); // Use debugPrint
      }

      return project;
    } catch (e) {
      _handleApiError('Error getting project', e);
      rethrow;
    }
  }

  // SECTION METHODS

  /// Get all sections
  Future<List<todoist.Section>> getAllSections({String? projectId}) async {
    if (verboseLogging) {
      debugPrint(
        '[TodoistApiService] Getting all sections${projectId != null ? ' for project $projectId' : ''}',
      ); // Use debugPrint
    }

    try {
      final sections = await _sectionsApi.getAllSections(projectId: projectId);

      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Retrieved ${sections?.length ?? 0} sections',
        ); // Use debugPrint
      }

      return sections ?? [];
    } catch (e) {
      _handleApiError('Error getting sections', e);
      rethrow;
    }
  }

  // LABEL METHODS

  /// Get all personal labels
  Future<List<todoist.Label>> getAllPersonalLabels() async {
    if (verboseLogging) {
      debugPrint(
        '[TodoistApiService] Getting all personal labels',
      ); // Use debugPrint
    }

    try {
      final labels = await _labelsApi.getAllPersonalLabels();

      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Retrieved ${labels?.length ?? 0} labels',
        ); // Use debugPrint
      }

      return labels ?? [];
    } catch (e) {
      _handleApiError('Error getting labels', e);
      rethrow;
    }
  }

  // COMMENT METHODS

  /// Get task comments
  Future<List<todoist.Comment>> getAllComments({String? taskId, String? projectId}) async {
    if (verboseLogging) {
      debugPrint(
        '[TodoistApiService] Getting comments for ${taskId != null ? 'task $taskId' : 'project $projectId'}',
      ); // Use debugPrint
    }

    try {
      final comments = await _commentsApi.getAllComments(
        taskId: taskId,
        projectId: projectId,
      );

      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Retrieved ${comments?.length ?? 0} comments',
        ); // Use debugPrint
      }

      return comments ?? [];
    } catch (e) {
      _handleApiError('Error getting comments', e);
      rethrow;
    }
  }

  /// Create a comment
  Future<todoist.Comment> createComment({
    String? taskId,
    String? projectId,
    required String content,
    todoist.CreateCommentAttachmentParameter? attachment,
  }) async {
    if (verboseLogging) {
      debugPrint('[TodoistApiService] Creating comment'); // Use debugPrint
    }

    // Corrected: Pass content as positional, others as named
    try {
      final comment = await _commentsApi.createComment(
        content, // Positional argument
        taskId: taskId,
        projectId: projectId,
        attachment: attachment,
      );

      if (comment == null) {
        throw Exception("Comment creation returned null");
      }

      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Comment created successfully with ID: ${comment.id}',
        ); // Use debugPrint
      }

      return comment;
    } catch (e) {
      _handleApiError('Error creating comment', e);
      rethrow;
    }
  }


  // HELPER METHODS

  void _handleApiError(String context, dynamic error) {
    if (error is todoist.ApiException) {
      debugPrint(
        '$context: ${error.message} (Code: ${error.code})',
      ); // Use debugPrint
      // Additional error handling logic could be added here
    } else {
      debugPrint('$context: $error'); // Use debugPrint
    }
  }

  /// Check if the API service is configured with a valid token
  bool get isConfigured => _authToken.isNotEmpty;

  /// Perform a simple API call to check if the service is working
  Future<bool> checkHealth() async {
    if (!isConfigured) return false;

    try {
      // A lightweight call to check if the API is working
      await _projectsApi.getAllProjects();
      return true;
    } catch (e) {
      if (verboseLogging) {
        debugPrint(
          '[TodoistApiService] Health check failed: $e',
        ); // Use debugPrint
      }
      return false;
    }
  }

  // Helper to decode response body bytes (similar to Memos ApiService)
  Future<String> _decodeBodyBytes(http.Response response) async {
    // Handle potential gzip encoding if necessary (Todoist API might not use it)
    // if (response.headers['content-encoding'] == 'gzip') { ... }
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }
}
