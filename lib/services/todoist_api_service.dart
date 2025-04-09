import 'dart:convert';

import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;
import 'package:http/http.dart' as http;

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
        print('[TodoistApiService] Configuration unchanged.');
      }
      return;
    }

    _authToken = authToken;
    _initializeClient(_authToken);
    
    if (verboseLogging) {
      print('[TodoistApiService] Configured with ${authToken.isNotEmpty ? 'valid' : 'empty'} token');
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
        print('[TodoistApiService] Client initialized successfully');
      }
    } catch (e) {
      print('[TodoistApiService] Error initializing client: $e');
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
      print('[TodoistApiService] Getting active tasks');
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
        print('[TodoistApiService] Retrieved ${tasks?.length ?? 0} tasks');
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
    String? orderStr,
    List<String>? labelIds,
    String? priority,
    todoist.TaskDue? due,
    todoist.TaskDuration? duration,
    String? assigneeId,
  }) async {
    if (verboseLogging) {
      print('[TodoistApiService] Creating task: $content');
    }

    final request = todoist.CreateTaskRequest(
      content: content,
      description: description,
      projectId: projectId,
      sectionId: sectionId,
      parentId: parentId,
      order: orderStr != null ? int.tryParse(orderStr) : null,
      labels: labelIds ?? [],
      priority: priority != null ? int.tryParse(priority) : null,
      dueString: due?.date,
      dueLang: due?.lang,
      assigneeId: assigneeId,
    );

    try {
      final task = await _tasksApi.createTask(request);
      
      if (verboseLogging) {
        print('[TodoistApiService] Task created successfully with ID: ${task?.id}');
      }
      
      return task!;
    } catch (e) {
      _handleApiError('Error creating task', e);
      rethrow;
    }
  }

  /// Update an existing task
  Future<void> updateTask({
    required String id,
    String? content,
    String? description,
    List<String>? labelIds,
    String? priority,
    todoist.TaskDue? due,
    todoist.TaskDuration? duration,
    String? assigneeId,
  }) async {
    if (verboseLogging) {
      print('[TodoistApiService] Updating task: $id');
    }

    final request = todoist.UpdateTaskRequest(
      content: content,
      description: description,
      labels: labelIds,
      priority: priority != null ? int.tryParse(priority) : null,
      dueString: due?.string,
      dueDate: due?.date,
      dueLang: due?.lang,
    );

    try {
      await _tasksApi.updateTask(id, request);
      
      if (verboseLogging) {
        print('[TodoistApiService] Task updated successfully');
      }
    } catch (e) {
      _handleApiError('Error updating task', e);
      rethrow;
    }
  }

  /// Close (complete) a task
  Future<void> closeTask(String id) async {
    if (verboseLogging) {
      print('[TodoistApiService] Closing task: $id');
    }

    try {
      await _tasksApi.closeTask(int.parse(id));

      if (verboseLogging) {
        print('[TodoistApiService] Task closed successfully');
      }
    } catch (e) {
      _handleApiError('Error closing task', e);
      rethrow;
    }
  }

  /// Reopen a task
  Future<void> reopenTask(String id) async {
    if (verboseLogging) {
      print('[TodoistApiService] Reopening task: $id');
    }

    try {
      await _tasksApi.reopenTask(int.parse(id));

      if (verboseLogging) {
        print('[TodoistApiService] Task reopened successfully');
      }
    } catch (e) {
      _handleApiError('Error reopening task', e);
      rethrow;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    if (verboseLogging) {
      print('[TodoistApiService] Deleting task: $id');
    }

    try {
      await _tasksApi.deleteTask(int.parse(id));

      if (verboseLogging) {
        print('[TodoistApiService] Task deleted successfully');
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
      print('[TodoistApiService] Getting all projects');
    }

    try {
      final projects = await _projectsApi.getAllProjects();
      
      if (verboseLogging) {
        print('[TodoistApiService] Retrieved ${projects?.length ?? 0} projects');
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
      print('[TodoistApiService] Getting project: $id');
    }

    try {
      final project = await _projectsApi.getProject(id);
      
      if (verboseLogging) {
        print('[TodoistApiService] Retrieved project: ${project?.name}');
      }
      
      return project!;
    } catch (e) {
      _handleApiError('Error getting project', e);
      rethrow;
    }
  }

  // SECTION METHODS

  /// Get all sections
  Future<List<todoist.Section>> getAllSections({String? projectId}) async {
    if (verboseLogging) {
      print('[TodoistApiService] Getting all sections${projectId != null ? ' for project $projectId' : ''}');
    }

    try {
      final sections = await _sectionsApi.getAllSections(projectId: projectId);
      
      if (verboseLogging) {
        print('[TodoistApiService] Retrieved ${sections?.length ?? 0} sections');
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
      print('[TodoistApiService] Getting all personal labels');
    }

    try {
      final labels = await _labelsApi.getAllPersonalLabels();
      
      if (verboseLogging) {
        print('[TodoistApiService] Retrieved ${labels?.length ?? 0} labels');
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
      print('[TodoistApiService] Getting comments for ${taskId != null ? 'task $taskId' : 'project $projectId'}');
    }

    try {
      final comments = await _commentsApi.getAllComments(
        taskId: taskId,
        projectId: projectId,
      );
      
      if (verboseLogging) {
        print('[TodoistApiService] Retrieved ${comments?.length ?? 0} comments');
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
      print('[TodoistApiService] Creating comment');
    }

    final request = todoist.CreateCommentRequest(
      content: content,
      projectId: projectId,
      taskId: taskId,
      attachment: attachment,
    );

    try {
      final comment = await _commentsApi.createComment(request);
      
      if (verboseLogging) {
        print('[TodoistApiService] Comment created successfully with ID: ${comment?.id}');
      }
      
      return comment!;
    } catch (e) {
      _handleApiError('Error creating comment', e);
      rethrow;
    }
  }

  // HELPER METHODS

  void _handleApiError(String context, dynamic error) {
    if (error is todoist.ApiException) {
      print('$context: ${error.message} (Code: ${error.code})');
      // Additional error handling logic could be added here
    } else {
      print('$context: $error');
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
        print('[TodoistApiService] Health check failed: $e');
      }
      return false;
    }
  }
}
