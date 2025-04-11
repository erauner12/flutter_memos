import 'dart:io'; // Import for stderr

import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;

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
  // Disable verbose logging by default to avoid MCP stdio issues
  static bool verboseLogging =
      false; // Cannot use kDebugMode in non-Flutter env
  String get apiBaseUrl => _baseUrl;

  TodoistApiService._internal() {
    // Initialize with empty token - will need to be configured later
    _initializeClient('');
  }

  /// Configure the Todoist API service with authentication token
  void configureService({required String authToken}) {
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

  /// Get a single active task by its ID
  Future<todoist.Task?> getActiveTaskById(String id) async {
    if (verboseLogging) {
      stderr.writeln('[TodoistApiService] Getting active task by ID: $id');
    }

    try {
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        stderr.writeln('[TodoistApiService] Error: Invalid task ID format provided: "$id"');
        throw ArgumentError('Invalid task ID format: $id');
      }
      final task = await _tasksApi.getActiveTask(taskIdInt);

      if (verboseLogging) {
        if (task != null) {
          stderr.writeln('[TodoistApiService] Retrieved task: ${task.content}');
        } else {
          stderr.writeln('[TodoistApiService] Task with ID $id not found.');
        }
      }
      return task;
    } catch (e) {
      _handleApiError('Error getting task by ID $id', e);
      // Return null or rethrow depending on desired error handling for callers
      // Returning null here to match the return type, caller should check.
      return null;
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
      // Use stderr.writeln for server-side logging
      stderr.writeln(
        '[TodoistApiService] Creating task: $content',
      );
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
      ), // Format as YYYY-MM-DD, handle potential null date
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
        // Use stderr.writeln for server-side logging
        stderr.writeln(
          '[TodoistApiService] Task created successfully with ID: ${task.id}',
        );
      }

      return task;
    } catch (e) {
      _handleApiError('Error creating task', e);
      rethrow;
    }
  }

  /// Update an existing task
  Future<void> updateTask({
    required String id, // Task ID is usually a string in Todoist API v2 responses
    String? content,
    String? description,
    List<String>? labelIds,
    String? priority, // Keep as String for input flexibility
    todoist.TaskDue? due, // Use the generated TaskDue model
    todoist.TaskDuration? duration, // Use the generated TaskDuration model
    String? assigneeId,
  }) async {
    if (verboseLogging) {
      // Use stderr.writeln for server-side logging
      stderr.writeln('[TodoistApiService] Updating task: $id');
    }

    // The generated UpdateTaskRequest model expects specific types.
    final request = todoist.UpdateTaskRequest(
      content: content,
      description: description,
      labels: labelIds ?? [], // Provide empty list if null
      priority:
          priority != null ? int.tryParse(priority) : null, // API expects int
      // Access nested properties from dueObject and durationObject
      dueString: due?.dueObject?.string,
      dueDate: due?.dueObject?.date.toIso8601String().substring(
        0,
        10,
      ), // Format as YYYY-MM-DD, handle potential null date
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
        // Use stderr.writeln for server-side logging
        stderr.writeln(
          '[TodoistApiService] Task updated successfully',
        );
      }
    } catch (e) {
      _handleApiError('Error updating task', e);
      rethrow;
    }
  }

  /// Close (complete) a task
  Future<void> closeTask(String id) async {
    if (verboseLogging) {
      // Use stderr.writeln for server-side logging
      stderr.writeln('[TodoistApiService] Closing task: $id');
    }

    try {
      // Parse String ID to int as expected by the generated API
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        throw ArgumentError('Invalid task ID format: $id');
      }
      await _tasksApi.closeTask(taskIdInt);

      if (verboseLogging) {
        // Use stderr.writeln for server-side logging
        stderr.writeln(
          '[TodoistApiService] Task closed successfully',
        );
      }
    } catch (e) {
      _handleApiError('Error closing task', e);
      rethrow;
    }
  }

  /// Reopen a task
  Future<void> reopenTask(String id) async {
    if (verboseLogging) {
      // Use stderr.writeln for server-side logging
      stderr.writeln('[TodoistApiService] Reopening task: $id');
    }

    try {
      // Parse String ID to int as expected by the generated API
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        throw ArgumentError('Invalid task ID format: $id');
      }
      await _tasksApi.reopenTask(taskIdInt);

      if (verboseLogging) {
        // Use stderr.writeln for server-side logging
        stderr.writeln(
          '[TodoistApiService] Task reopened successfully',
        );
      }
    } catch (e) {
      _handleApiError('Error reopening task', e);
      rethrow;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    if (verboseLogging) {
      // Use stderr.writeln for server-side logging
      stderr.writeln('[TodoistApiService] Deleting task: $id');
    }

    try {
      // Parse String ID to int as expected by the generated API
      final taskIdInt = int.tryParse(id);
      if (taskIdInt == null) {
        throw ArgumentError('Invalid task ID format: $id');
      }
      await _tasksApi.deleteTask(taskIdInt);

      if (verboseLogging) {
        // Use stderr.writeln for server-side logging
        stderr.writeln(
          '[TodoistApiService] Task deleted successfully',
        );
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
      // Use stderr.writeln for server-side logging
      stderr.writeln('[TodoistApiService] Getting all projects');
    }

    try {
      final projects = await _projectsApi.getAllProjects();

      if (verboseLogging) {
        // Use stderr.writeln for server-side logging
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

  /// Get project by ID
  Future<todoist.Project> getProject(String id) async {
    if (verboseLogging) {
      // Use stderr.writeln for server-side logging
      stderr.writeln('[TodoistApiService] Getting project: $id');
    }

    try {
      final project = await _projectsApi.getProject(id);

      if (project == null) {
        throw Exception("Project not found: $id");
      }

      if (verboseLogging) {
        // Use stderr.writeln for server-side logging
        stderr.writeln(
          '[TodoistApiService] Retrieved project: ${project.name}',
        );
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
      // Use stderr.writeln for server-side logging
      stderr.writeln(
        '[TodoistApiService] Getting all sections${projectId != null ? ' for project $projectId' : ''}',
      );
    }

    try {
      final sections = await _sectionsApi.getAllSections(projectId: projectId);

      if (verboseLogging) {
        // Use stderr.writeln for server-side logging
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

  // LABEL METHODS

  /// Get all personal labels
  Future<List<todoist.Label>> getAllPersonalLabels() async {
    if (verboseLogging) {
      // Use stderr.writeln for server-side logging
      stderr.writeln(
        '[TodoistApiService] Getting all personal labels',
      );
    }

    try {
      final labels = await _labelsApi.getAllPersonalLabels();

      if (verboseLogging) {
        // Use stderr.writeln for server-side logging
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

  // COMMENT METHODS

  /// Get task comments
  Future<List<todoist.Comment>> getAllComments({String? taskId, String? projectId}) async {
    if (verboseLogging) {
      // Use stderr.writeln for server-side logging
      stderr.writeln(
        '[TodoistApiService] Getting comments for ${taskId != null ? 'task $taskId' : 'project $projectId'}',
      );
    }

    try {
      final comments = await _commentsApi.getAllComments(
        taskId: taskId,
        projectId: projectId,
      );

      if (verboseLogging) {
        // Use stderr.writeln for server-side logging
        stderr.writeln(
          '[TodoistApiService] Retrieved ${comments?.length ?? 0} comments',
        );
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
      // Use stderr.writeln for server-side logging
      stderr.writeln('[TodoistApiService] Creating comment');
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
        // Use stderr.writeln for server-side logging
        stderr.writeln(
          '[TodoistApiService] Comment created successfully with ID: ${comment.id}',
        );
      }

      return comment;
    } catch (e) {
      _handleApiError('Error creating comment', e);
      rethrow;
    }
  }

  // HELPER METHODS

  void _handleApiError(String context, dynamic error) {
    // Use stderr.writeln for errors
    if (error is todoist.ApiException) {
      stderr.writeln(
        '[TodoistApiService] API Error - $context: ${error.message} (Code: ${error.code})',
      );
      // Additional error handling logic could be added here
    } else {
      stderr.writeln('[TodoistApiService] Error - $context: $error');
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
        // Use stderr.writeln for server-side logging
        stderr.writeln(
          '[TodoistApiService] Health check failed: $e',
        );
      }
      return false;
    }
  }

  // You can uncomment and use this helper method when needed
  // Future<String> _decodeBodyBytes(http.Response response) async {
  //   // Handle potential gzip encoding if necessary (Todoist API might not use it)
  //   // if (response.headers['content-encoding'] == 'gzip') { ... }
  //   return utf8.decode(response.bodyBytes, allowMalformed: true);
  // }
}
