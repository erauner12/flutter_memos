import 'dart:async';
import 'dart:convert'; // For jsonEncode if needed for debugging args
import 'dart:io';

// Import MCP components
import 'package:mcp_dart/mcp_dart.dart' as mcp_dart;
import 'package:mcp_dart/src/server/sse_server_manager.dart';
import 'package:mcp_dart/src/shared/protocol.dart' show RequestHandlerExtra;
// REMOVE: Imports related to flutter_memos service
// import 'package:flutter_memos/services/todoist_api_service.dart';

// ADD: Import the generated Todoist API client directly
import 'package:todoist_api/api.dart' as todoist;

// REMOVE: Global instance of the service
// final todoistService = TodoistApiService();

// ADD: Enum for transport mode
enum TransportMode { stdio, sse }

// --- Helper Functions ---

/// Creates and configures an ApiClient with the Todoist API token.
/// Returns null if the token is missing or empty.
todoist.ApiClient? _configureApiClient() {
  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    stderr.writeln(
      '[TodoistServer] Error: TODOIST_API_TOKEN environment variable not set or empty.',
    );
    return null;
  }
  final auth = todoist.HttpBearerAuth();
  auth.accessToken = apiToken;
  return todoist.ApiClient(authentication: auth);
}

/// Performs a basic health check by trying to fetch projects.
Future<bool> _checkApiHealth(todoist.ApiClient client) async {
  stderr.writeln('[TodoistServer] Performing API health check...');
  try {
    final projectsApi = todoist.ProjectsApi(client);
    await projectsApi.getAllProjects();
    stderr.writeln('[TodoistServer] API health check successful.');
    return true;
  } catch (e) {
    stderr.writeln('[TodoistServer] API health check failed: \$e');
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}',
      );
    }
    return false;
  }
}

/// Finds a single active Todoist task by its content (case-insensitive contains).
Future<todoist.Task?> _findTaskByName(
  todoist.ApiClient client,
  String taskName,
) async {
  if (taskName.trim().isEmpty) {
    stderr.writeln('[TodoistServer] _findTaskByName called with empty name.');
    return null;
  }
  stderr.writeln('[TodoistServer] Searching for task containing: "\$taskName"');
  try {
    final tasksApi = todoist.TasksApi(client);
    final allTasks = await tasksApi.getActiveTasks();
    if (allTasks == null) {
      stderr.writeln('[TodoistServer] Received null task list from API.');
      return null;
    }
    final matches = allTasks.where((task) {
      return task.content?.toLowerCase().contains(taskName.toLowerCase()) ??
          false;
    }).toList();
    if (matches.isEmpty) {
      stderr.writeln('[TodoistServer] No task found matching "\$taskName".');
      return null;
    } else if (matches.length == 1) {
      stderr.writeln(
        '[TodoistServer] Found unique task matching "\$taskName": ID \${matches.first.id}',
      );
      return matches.first;
    } else {
      stderr.writeln(
        '[TodoistServer] Warning: Found \${matches.length} tasks matching "\$taskName". Using the first one: ID \${matches.first.id}, Content: "\${matches.first.content}"',
      );
      return matches.first;
    }
  } catch (e) {
    stderr.writeln(
      '[TodoistServer] Error during _findTaskByName("\$taskName"): \$e',
    );
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}',
      );
    }
    return null;
  }
}

// --- Generic Result Helpers ---

// Generic error result helper
mcp_dart.CallToolResult _createErrorResult(String message,
    {Map<String, dynamic>? errorData}) {
  // Added errorData parameter
  final payload = {
    'status': 'error',
    'message': message,
    'result': errorData ?? {}, // Include errorData in result field
  };
  stderr.writeln(
      '[TodoistServer] Creating Error Result: \${jsonEncode(payload)}');
  return mcp_dart.CallToolResult(
    content: [mcp_dart.TextContent(text: jsonEncode(payload))],
    isError: true,
  );
}

// ADD: Generic success result helper
mcp_dart.CallToolResult _createSuccessResult(String message,
    {Map<String, dynamic>? resultData}) {
  final payload = {
    'status': 'success',
    'message': message,
    'result': resultData ?? {}, // Include resultData in result field
  };
  stderr.writeln(
      '[TodoistServer] Creating Success Result: \${jsonEncode(payload)}');
  return mcp_dart.CallToolResult(
    content: [mcp_dart.TextContent(text: jsonEncode(payload))],
  );
}

Future<void> main(List<String> args) async {
  // ADD: Determine transport mode
  var transportMode = TransportMode.stdio; // Default
  String transportArg = args.firstWhere(
    (arg) => arg.startsWith('--transport='),
    orElse: () => '',
  );
  if (transportArg == '--transport=sse') {
    transportMode = TransportMode.sse;
  } else if (transportArg.isNotEmpty && transportArg != '--transport=stdio') {
    stderr.writeln(
      '[TodoistServer] Warning: Invalid --transport value "\$transportArg". Defaulting to stdio.',
    );
  }
  stderr.writeln('[TodoistServer] Starting in \${transportMode.name} mode...');

  // 1. Create the McpServer instance (Moved before transport logic)
  final server = mcp_dart.McpServer(
    const mcp_dart.Implementation(
      name: "flutter-memos-todoist-server",
      version: "0.1.0",
    ),
    options: const mcp_dart.ServerOptions(
      capabilities: mcp_dart.ServerCapabilities(
        tools: mcp_dart.ServerCapabilitiesTools(),
      ),
    ),
  );

  // 2. Register Tools (Moved before transport logic)
  // ADD: Register create_todoist_task tool
  server.tool(
    'create_todoist_task',
    description:
        'Creates a new task in Todoist. Returns the created task details.',
    inputSchemaProperties: {
      'content': {
        'type': 'string',
        'description': 'The content of the task (required).',
      },
      'description': {
        'type': 'string',
        'description': 'Detailed description for the task (optional).',
      },
      'project_id': {
        'type': 'string',
        'description': 'ID of the project to add the task to (optional).',
      },
      'section_id': {
        'type': 'string',
        'description': 'ID of the section to add the task to (optional).',
      },
      'labels': {
        'type': 'array',
        'description': 'List of label names to attach (optional).',
        'items': {'type': 'string'},
      },
      'priority': {
        'type': 'integer',
        'description':
            'Task priority from 1 (normal) to 4 (urgent) (optional).',
      },
      'due_string': {
        'type': 'string',
        'description': 'Human-readable due date (optional).',
      },
      'due_date': {
        'type': 'string',
        'description': 'Specific due date in YYYY-MM-DD format (optional).',
      },
      'due_datetime': {
        'type': 'string',
        'description':
            'Specific due date/time in RFC3339 UTC format (optional).',
      },
      'due_lang': {
        'type': 'string',
        'description': 'Language code if due_string is not English (optional).',
      },
      'assignee_id': {
        'type': 'string',
        'description': 'ID of the user to assign the task to (optional).',
      },
      'duration': {
        'type': 'integer',
        'description':
            'A positive integer for the task duration, or null to unset. Requires duration_unit.',
      },
      'duration_unit': {
        'type': 'string',
        'description':
            "The unit for the duration ('minute' or 'day'). Requires duration.",
        'enum': ['minute', 'day'],
      },
    },
    callback: _handleCreateTodoistTask, // Use the correct handler
  );

  // Change 1: update_todoist_task with optional task_id and refined description.
  server.tool(
    'update_todoist_task',
    description:
        'Updates an existing task in Todoist. Requires either task_id or task_name. task_id takes precedence. Returns the updated task ID.',
    inputSchemaProperties: {
      'task_id': {
        'type': 'string',
        'description':
            'The specific ID of the task to update (optional, takes precedence over task_name).',
      },
      'task_name': {
        'type': 'string',
        'description':
            'The name/content of the task to search for and update (required if task_id is not provided).',
      },
      'content': {
        'type': 'string',
        'description': 'New content for the task (optional).',
      },
      'description': {
        'type': 'string',
        'description': 'New detailed description for the task (optional).',
      },
      'labels': {
        'type': 'array',
        'description':
            'New list of label names to attach (optional, replaces existing).',
        'items': {'type': 'string'},
      },
      'priority': {
        'type': 'integer',
        'description':
            'New task priority from 1 (normal) to 4 (urgent) (optional).',
      },
      'due_string': {
        'type': 'string',
        'description': 'New human-readable due date (optional).',
      },
      'due_date': {
        'type': 'string',
        'description': 'New specific due date in YYYY-MM-DD format (optional).',
      },
      'due_datetime': {
        'type': 'string',
        'description':
            'New specific due date/time in RFC3339 UTC format (optional).',
      },
      'due_lang': {
        'type': 'string',
        'description':
            'Language code if new due_string is not English (optional).',
      },
      'assignee_id': {
        'type': 'string',
        'description': 'New ID of the user to assign the task to (optional).',
      },
      'duration': {
        'type': 'integer',
        'description':
            'A positive integer for the task duration, or null to unset. Requires duration_unit.',
      },
      'duration_unit': {
        'type': 'string',
        'description':
            "The unit for the duration ('minute' or 'day'). Requires duration.",
        'enum': ['minute', 'day'],
      },
    },
    callback: _handleUpdateTodoistTask, // Direct function reference
  );

  // Change 2: todoist_delete_task with optional task_id and refined description.
  server.tool(
    'todoist_delete_task',
    description:
        'Deletes a task from Todoist. Requires either task_id or task_name. task_id takes precedence. Returns the deleted task ID.',
    inputSchemaProperties: {
      'task_id': {
        'type': 'string',
        'description':
            'The specific ID of the task to delete (optional, takes precedence over task_name).',
      },
      'task_name': {
        'type': 'string',
        'description':
            'The name/content of the task to search for and delete (required if task_id is not provided).',
      },
    },
    callback: _handleDeleteTodoistTask, // Direct function reference
  );

  // Change 3: todoist_complete_task with optional task_id and refined description.
  server.tool(
    'todoist_complete_task',
    description:
        'Marks a task as complete in Todoist. Requires either task_id or task_name. task_id takes precedence. Returns the completed task ID.',
    inputSchemaProperties: {
      'task_id': {
        'type': 'string',
        'description':
            'The specific ID of the task to complete (optional, takes precedence over task_name).',
      },
      'task_name': {
        'type': 'string',
        'description':
            'The name/content of the task to search for and complete (required if task_id is not provided).',
      },
    },
    callback: handleCompleteTodoistTask, // Direct function reference
  );

  // ADD: Register get_todoist_tasks tool
  server.tool(
    'get_todoist_tasks',
    description:
        'Retrieves active Todoist tasks based on filters. Returns a list of tasks.',
    inputSchemaProperties: {
      'task_id': {
        'type': 'string',
        'description':
            'Fetch a specific task by its ID (optional, takes precedence over filters).',
      },
      'filter': {
        'type': 'string',
        'description':
            'Todoist filter query (e.g., "today", "p1", "#Work") (optional).',
      },
      'content_contains': {
        'type': 'string',
        'description':
            'Filter tasks whose content contains this text (case-insensitive) (optional, ignored if filter is provided).',
      },
    },
    callback: _handleGetTodoistTasks, // Use the correct handler
  );

  // Change 4: refine get_todoist_task_by_id description.
  server.tool(
    'get_todoist_task_by_id',
    description:
        'Retrieves a single active Todoist task by its specific ID. Returns the full task details.',
    inputSchemaProperties: {
      'task_id': {
        'type': 'string',
        'description': 'The exact ID of the task to retrieve (required).',
      },
    },
    callback: handleGetTodoistTaskById, // Direct function reference
  );

  // Change 5: refine get_task_comments description.
  server.tool(
    'get_task_comments',
    description:
        'Retrieves all comments for a specific Todoist task ID. Returns a list of comments.',
    inputSchemaProperties: {
      'task_id': {
        'type': 'string',
        'description':
            'The exact ID of the task whose comments to retrieve (required).',
      },
    },
    callback: handleGetTaskComments, // Direct function reference
  );

  // Change 6: refine create_task_comment description.
  server.tool(
    'create_task_comment',
    description:
        'Adds a new comment to a Todoist task. Requires task_id or task_name (task_id preferred). Returns the new comment ID and task ID.',
    inputSchemaProperties: {
      'task_id': {
        'type': 'string',
        'description':
            'The specific ID of the task to add a comment to (optional, takes precedence over task_name).',
      },
      'task_name': {
        'type': 'string',
        'description':
            'The name/content of the task to search for (required if task_id is not provided).',
      },
      'content': {
        'type': 'string',
        'description': 'The text content of the comment (required).',
      },
    },
    callback: handleCreateTaskComment, // Direct function reference
  );

  stderr.writeln(
    '[TodoistServer] Registered tools: create_todoist_task, update_todoist_task, get_todoist_tasks, todoist_delete_task, todoist_complete_task, get_todoist_task_by_id, get_task_comments, create_task_comment',
  );

  // 3. Connect to the Transport based on mode
  if (transportMode == TransportMode.stdio) {
    final transport = mcp_dart.StdioServerTransport();
    ProcessSignal.sigint.watch().listen((signal) async {
      stderr
          .writeln('[TodoistServer][stdio] Received SIGINT. Shutting down...');
      await server.close();
      await transport.close();
      exit(0);
    });
    ProcessSignal.sigterm.watch().listen((signal) async {
      stderr
          .writeln('[TodoistServer][stdio] Received SIGTERM. Shutting down...');
      await server.close();
      await transport.close();
      exit(0);
    });
    try {
      await server.connect(transport);
      stderr.writeln(
          '[TodoistServer][stdio] MCP Server running on stdio, ready for connections.');
      await stdout.flush();
      stderr.writeln('[TodoistServer][stdio] Initial stdout flushed.');
    } catch (e) {
      stderr.writeln(
          '[TodoistServer][stdio] Failed to connect to transport: \$e');
      exit(1);
    }
  } else {
    final sseManager = SseServerManager(
      server,
      ssePath: '/sse',
      messagePath: '/messages',
    );
    final port = int.tryParse(Platform.environment['PORT'] ?? '9000') ?? 9000;
    HttpServer? httpServer;
    Future<void> shutdownSse() async {
      stderr.writeln("\n[TodoistServer][sse] Shutting down...");
      try {
        stderr.writeln(
            "[TodoistServer][sse] Closing \${sseManager.activeSseTransports.length} active SSE transports...");
        await Future.wait(
          sseManager.activeSseTransports.values.map((t) => t.close()),
        );
        stderr.writeln("[TodoistServer][sse] Active SSE transports closed.");
        await httpServer?.close(force: true);
        stderr.writeln("[TodoistServer][sse] HTTP server closed.");
      } catch (e) {
        stderr.writeln("[TodoistServer][sse] Error during shutdown: \$e");
      }
      stderr.writeln("[TodoistServer][sse] Exiting.");
      exit(0);
    }
    ProcessSignal.sigint.watch().listen((_) async {
      stderr.writeln("[TodoistServer][sse] SIGINT received.");
      await shutdownSse();
    });
    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((_) async {
        stderr.writeln("[TodoistServer][sse] SIGTERM received.");
        await shutdownSse();
      });
    }
    try {
      httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
      // Explicitly set idleTimeout to null (default) to prevent server-side timeouts
      httpServer.idleTimeout = null;
      stderr.writeln(
          '[TodoistServer][sse] Explicitly set HttpServer.idleTimeout to null.');
      stderr.writeln(
          '[TodoistServer][sse] Serving MCP over SSE (GET \${sseManager.ssePath}) and HTTP (POST \${sseManager.messagePath}) at http://\${httpServer.address.host}:\${httpServer.port}');
      httpServer.listen(
        (HttpRequest request) {
          stderr.writeln(
              '[TodoistServer][sse] Request: \${request.method} \${request.uri}');
          sseManager.handleRequest(request).catchError((e, s) {
            stderr.writeln(
                '[TodoistServer][sse] Error handling request \${request.uri}: \$e\n\$s');
            try {
              if (request.response.connectionInfo != null) {
                request.response.statusCode = HttpStatus.internalServerError;
                request.response.write('Internal Server Error');
                request.response.close();
              }
            } catch (_) {
              stderr.writeln(
                  '[TodoistServer][sse] Could not send error response for \${request.uri}. Connection likely closed.');
            }
          });
        },
        onError: (e, s) =>
            stderr.writeln('[TodoistServer][sse] HttpServer error: \$e\n\$s'),
        onDone: () => stderr.writeln('[TodoistServer][sse] HttpServer closed.'),
      );
      stderr.writeln("[TodoistServer][sse] Signal handlers registered.");
    } catch (e) {
      stderr.writeln(
          '[TodoistServer][sse] FATAL: Failed to bind server to port \$port: \$e');
      exit(1);
    }
  }
}

// --- Tool Handlers (Refactored) ---

Future<mcp_dart.CallToolResult> _handleCreateTodoistTask({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received create_todoist_task request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
        'Todoist API health check failed with the provided token.');
  }
  final contentText = args?['content'] as String?;
  if (contentText == null || contentText.trim().isEmpty) {
    return _createErrorResult('Task content cannot be empty.');
  }
  final description = args?['description'] as String?;
  final projectId = args?['project_id'] as String?;
  final sectionId = args?['section_id'] as String?;
  final labels = (args?['labels'] as List<dynamic>?)?.cast<String>();
  final priority = args?['priority'] as int?;
  final dueString = args?['due_string'] as String?;
  final dueDate = args?['due_date'] as String?;
  final dueDatetime = args?['due_datetime'] as String?;
  final dueLang = args?['due_lang'] as String?;
  final assigneeId = args?['assignee_id'] as String?;
  final durationAmount = args?['duration'] as int?;
  final durationUnit = args?['duration_unit'] as String?;
  final request = todoist.CreateTaskRequest(
    content: contentText,
    description: description,
    projectId: projectId,
    sectionId: sectionId,
    labels: labels ?? const [],
    priority: priority,
    dueString: dueString,
    dueDate: dueDate,
    dueDatetime: dueDatetime,
    dueLang: dueLang,
    assigneeId: assigneeId,
    duration: durationAmount,
    durationUnit: durationUnit,
  );
  try {
    stderr.writeln('[TodoistServer] Calling TasksApi.createTask...');
    final tasksApi = todoist.TasksApi(apiClient);
    final newTask = await tasksApi.createTask(request);
    if (newTask == null) {
      return _createErrorResult(
          'API returned null for the newly created task.');
    }
    final successMsg =
        'Todoist task created successfully: "\${newTask.content}"';
    stderr.writeln('[TodoistServer] \$successMsg (ID: \${newTask.id})');
    return _createSuccessResult(
      successMsg,
      resultData: {
        'taskId': newTask.id,
        'task': {
          'id': newTask.id,
          'content': newTask.content,
          'description': newTask.description,
          'priority': newTask.priority,
          'due_string': newTask.due?.dueObject?.string,
          'due_date': newTask.due?.dueObject?.date,
          'due_datetime': newTask.due?.dueObject?.datetime,
          'labels': newTask.labels,
          'project_id': newTask.projectId,
          'created_at': newTask.createdAt,
        }
      },
    );
  } catch (e) {
    var apiErrorMsg = 'Error creating Todoist task: \${e.toString()}';
    stderr.writeln('[TodoistServer] \$apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
      apiErrorMsg =
          'API Error creating task (\${e.code}): \${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> _handleUpdateTodoistTask({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received update_todoist_task request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
        'Todoist API health check failed with the provided token.');
  }
  final taskIdArg = args?['task_id'] as String?;
  final taskNameArg = args?['task_name'] as String?;
  String? resolvedTaskId;
  String taskIdentifierDescription = '';
  todoist.Task? originalTask;
  if (taskIdArg != null && taskIdArg.trim().isNotEmpty) {
    resolvedTaskId = taskIdArg;
    taskIdentifierDescription = 'ID "\$resolvedTaskId"';
    stderr.writeln('[TodoistServer] Using provided task_id: \$resolvedTaskId');
  } else if (taskNameArg != null && taskNameArg.trim().isNotEmpty) {
    taskIdentifierDescription = 'name "\$taskNameArg"';
    stderr.writeln(
        '[TodoistServer] task_id not provided, attempting to find task by name: "\$taskNameArg"');
    originalTask = await _findTaskByName(apiClient, taskNameArg);
    if (originalTask == null || originalTask.id == null) {
      return _createErrorResult(
          'Task matching name "\$taskNameArg" not found.');
    }
    resolvedTaskId = originalTask.id!;
    stderr.writeln(
        '[TodoistServer] Found task ID \$resolvedTaskId by name "\$taskNameArg".');
  } else {
    return _createErrorResult(
        'Either task_id or task_name is required for update.');
  }
  final contentText = args?['content'] as String?;
  final description = args?['description'] as String?;
  final labels = (args?['labels'] as List<dynamic>?)?.cast<String>();
  final priority = args?['priority'] as int?;
  final dueString = args?['due_string'] as String?;
  final dueDate = args?['due_date'] as String?;
  final dueDatetime = args?['due_datetime'] as String?;
  final dueLang = args?['due_lang'] as String?;
  final assigneeId = args?['assignee_id'] as String?;
  final durationAmount = args?['duration'] as int?;
  final durationUnit = args?['duration_unit'] as String?;
  final request = todoist.UpdateTaskRequest(
    content: contentText,
    description: description,
    labels: labels ?? const [],
    priority: priority,
    dueString: dueString,
    dueDate: dueDate,
    dueDatetime: dueDatetime,
    dueLang: dueLang,
    assigneeId: assigneeId,
    duration: durationAmount,
    durationUnit: durationUnit,
  );
  if (contentText == null &&
      description == null &&
      labels == null &&
      priority == null &&
      dueString == null &&
      dueDate == null &&
      dueDatetime == null &&
      dueLang == null &&
      assigneeId == null &&
      durationAmount == null &&
      durationUnit == null) {
    final taskContentForMsg =
        originalTask?.content ?? taskNameArg ?? resolvedTaskId;
    stderr.writeln(
        '[TodoistServer] Update request for task "\$taskContentForMsg" (ID: \$resolvedTaskId) has no fields to update. Skipping API call.');
    final msg =
        'No update fields provided for task "\$taskContentForMsg" (ID: \$resolvedTaskId). Task not changed.';
    return _createSuccessResult(msg, resultData: {'taskId': resolvedTaskId});
  }
  try {
    stderr.writeln(
        '[TodoistServer] Calling TasksApi.updateTask for ID: \$resolvedTaskId (Identified by: \$taskIdentifierDescription)...');
    final tasksApi = todoist.TasksApi(apiClient);
    await tasksApi.updateTask(resolvedTaskId, request);
    final taskContentForMsg =
        originalTask?.content ?? taskNameArg ?? resolvedTaskId;
    final successMsg =
        'Todoist task "\$taskContentForMsg" (ID: \$resolvedTaskId) updated successfully.';
    stderr.writeln('[TodoistServer] \$successMsg');
    return _createSuccessResult(
      successMsg,
      resultData: {'taskId': resolvedTaskId},
    );
  } catch (e) {
    final taskContentForMsg =
        originalTask?.content ?? taskNameArg ?? resolvedTaskId;
    final errorMsg =
        'Error updating Todoist task "\$taskContentForMsg" (ID: \$resolvedTaskId): \${e.toString()}';
    stderr.writeln('[TodoistServer] \$errorMsg');
    var apiErrorMsg = errorMsg;
    Map<String, dynamic>? errorData = {'taskId': resolvedTaskId};
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
      apiErrorMsg =
          'API Error updating task "\$taskContentForMsg" (\${e.code}): \${e.message ?? "Unknown API error"}';
      errorData['apiCode'] = e.code;
      errorData['apiMessage'] = e.message;
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> _handleGetTodoistTasks({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received get_todoist_tasks request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
        'Todoist API health check failed with the provided token.');
  }
  final taskIdArg = args?['task_id'] as String?;
  final filterArg = args?['filter'] as String?;
  final contentContainsArg = args?['content_contains'] as String?;
  String? effectiveFilter;
  String? specificTaskId;
  int? specificTaskIdInt;
  if (taskIdArg != null && taskIdArg.trim().isNotEmpty) {
    specificTaskId = taskIdArg;
    try {
      specificTaskIdInt = int.parse(specificTaskId);
      stderr.writeln(
          '[TodoistServer] Using specific task ID: \$specificTaskIdInt');
    } catch (formatException) {
      return _createErrorResult(
        'Invalid Task ID format: "\$specificTaskId". Expected an integer.',
        errorData: {'taskId': specificTaskId},
      );
    }
  }
  if (specificTaskIdInt == null) {
    if (filterArg != null && filterArg.trim().isNotEmpty) {
      effectiveFilter = filterArg;
      stderr.writeln(
          '[TodoistServer] Using explicit filter: "\$effectiveFilter"');
    } else if (contentContainsArg != null &&
        contentContainsArg.trim().isNotEmpty) {
      effectiveFilter = 'search: "\$contentContainsArg"';
      stderr.writeln(
          '[TodoistServer] Using filter from content_contains: "\$effectiveFilter"');
    } else {
      stderr.writeln(
          '[TodoistServer] No task_id, filter, or content_contains provided. Fetching all active tasks.');
    }
  }
  try {
    final tasksApi = todoist.TasksApi(apiClient);
    List<todoist.Task> tasks = [];
    if (specificTaskIdInt != null) {
      stderr.writeln(
          '[TodoistServer] Fetching specific task by ID: \$specificTaskIdInt');
      try {
        final task = await tasksApi.getActiveTask(specificTaskIdInt);
        if (task != null) {
          tasks.add(task);
        } else {
          stderr.writeln(
              '[TodoistServer] Task with ID \$specificTaskIdInt not found by API (returned null).');
          return _createSuccessResult(
            'Task with ID \$specificTaskIdInt not found.',
            resultData: {'tasks': []},
          );
        }
      } catch (e) {
        if (e is todoist.ApiException && e.code == 404) {
          stderr.writeln(
              '[TodoistServer] Task with ID \$specificTaskIdInt not found (404).');
          return _createSuccessResult(
            'Task with ID \$specificTaskIdInt not found.',
            resultData: {'tasks': []},
          );
        } else {
          stderr.writeln(
              '[TodoistServer] Error fetching task by ID \$specificTaskIdInt: \$e');
          if (e is todoist.ApiException) {
            stderr.writeln(
                '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
          }
          rethrow;
        }
      }
    } else {
      stderr.writeln(
          '[TodoistServer] Calling TasksApi.getActiveTasks with filter: \$effectiveFilter');
      final result = await tasksApi.getActiveTasks(filter: effectiveFilter);
      tasks = result ?? [];
    }
    if (tasks.isEmpty) {
      final msg = specificTaskIdInt != null
          ? 'Task with ID \$specificTaskIdInt not found.'
          : 'No active tasks found matching the criteria.';
      stderr.writeln('[TodoistServer] \$msg');
      return _createSuccessResult(msg, resultData: {'tasks': []});
    } else {
      final tasksForAI = tasks
          .map((task) => {
                'id': task.id,
                'content': task.content,
                'description': task.description,
                'priority': task.priority,
                'due_string': task.due?.dueObject?.string,
                'due_date': task.due?.dueObject?.date,
                'due_datetime': task.due?.dueObject?.datetime,
                'labels': task.labels,
                'project_id': task.projectId,
                'section_id': task.sectionId,
                'created_at': task.createdAt,
                'assignee_id': task.assigneeId,
                'comment_count': task.commentCount,
                'url': task.url,
                'is_completed': task.isCompleted,
                'parent_id': task.parentId,
                'order': task.order,
                'duration_amount': task.duration?.durationObject?.amount,
                'duration_unit': task.duration?.durationObject?.unit,
              })
          .toList();
      final msg = specificTaskIdInt != null
          ? 'Successfully retrieved task ID \$specificTaskIdInt.'
          : 'Found \${tasks.length} matching task(s).';
      stderr.writeln('[TodoistServer] \$msg Returning JSON list.');
      return _createSuccessResult(msg, resultData: {'tasks': tasksForAI});
    }
  } catch (e) {
    final errorMsg = 'Error getting Todoist tasks: \${e.toString()}';
    stderr.writeln('[TodoistServer] \$errorMsg');
    var apiErrorMsg = errorMsg;
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
      apiErrorMsg =
          'API Error getting tasks (\${e.code}): \${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
      if (specificTaskIdInt != null) {
        errorData['taskId'] = specificTaskId;
      }
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> _handleDeleteTodoistTask({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received delete_todoist_task request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
        'Todoist API health check failed with the provided token.');
  }
  final taskIdArg = args?['task_id'] as String?;
  final taskNameArg = args?['task_name'] as String?;
  String? resolvedTaskId;
  String taskIdentifierDescription = '';
  todoist.Task? originalTask;
  String? taskContentForMsg;
  if (taskIdArg != null && taskIdArg.trim().isNotEmpty) {
    resolvedTaskId = taskIdArg;
    taskIdentifierDescription = 'ID "\$resolvedTaskId"';
    stderr.writeln('[TodoistServer] Using provided task_id: \$resolvedTaskId');
    taskContentForMsg = resolvedTaskId;
  } else if (taskNameArg != null && taskNameArg.trim().isNotEmpty) {
    taskIdentifierDescription = 'name "\$taskNameArg"';
    stderr.writeln(
        '[TodoistServer] task_id not provided, attempting to find task by name: "\$taskNameArg"');
    originalTask = await _findTaskByName(apiClient, taskNameArg);
    if (originalTask == null || originalTask.id == null) {
      return _createErrorResult(
          'Task matching name "\$taskNameArg" not found.');
    }
    resolvedTaskId = originalTask.id!;
    taskContentForMsg = originalTask.content ?? taskNameArg;
    stderr.writeln(
        '[TodoistServer] Found task ID \$resolvedTaskId by name "\$taskNameArg".');
  } else {
    return _createErrorResult(
        'Either task_id or task_name is required for deletion.');
  }
  int? taskIdInt;
  try {
    taskIdInt = int.parse(resolvedTaskId);
  } catch (formatException) {
    return _createErrorResult(
      'Invalid Task ID format for deletion: "\$resolvedTaskId". Expected an integer.',
      errorData: {'taskId': resolvedTaskId},
    );
  }
  try {
    stderr.writeln(
        '[TodoistServer] Calling TasksApi.deleteTask for ID: \$taskIdInt (Identified by: \$taskIdentifierDescription)...');
    final tasksApi = todoist.TasksApi(apiClient);
    await tasksApi.deleteTask(taskIdInt);
    final successMsg = 'Successfully deleted task: "\$taskContentForMsg"';
    stderr.writeln('[TodoistServer] \$successMsg (ID: \$resolvedTaskId)');
    return _createSuccessResult(successMsg,
        resultData: {'taskId': resolvedTaskId});
  } catch (e) {
    final errorMsg =
        'Error deleting Todoist task "\$taskContentForMsg" (ID: \$resolvedTaskId): \${e.toString()}';
    stderr.writeln('[TodoistServer] \$errorMsg');
    var apiErrorMsg = errorMsg;
    Map<String, dynamic>? errorData = {'taskId': resolvedTaskId};
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
      if (e.code == 404) {
        apiErrorMsg =
            'API Error deleting task: Task with ID "\$resolvedTaskId" not found (404).';
      } else {
        apiErrorMsg =
            'API Error deleting task "\$taskContentForMsg" (\${e.code}): \${e.message ?? "Unknown API error"}';
      }
      errorData['apiCode'] = e.code;
      errorData['apiMessage'] = e.message;
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> handleCompleteTodoistTask({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received complete_todoist_task request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
        'Todoist API health check failed with the provided token.');
  }
  final taskIdArg = args?['task_id'] as String?;
  final taskNameArg = args?['task_name'] as String?;
  String? resolvedTaskId;
  String taskIdentifierDescription = '';
  todoist.Task? originalTask;
  String? taskContentForMsg;
  if (taskIdArg != null && taskIdArg.trim().isNotEmpty) {
    resolvedTaskId = taskIdArg;
    taskIdentifierDescription = 'ID "\$resolvedTaskId"';
    stderr.writeln('[TodoistServer] Using provided task_id: \$resolvedTaskId');
    taskContentForMsg = resolvedTaskId;
  } else if (taskNameArg != null && taskNameArg.trim().isNotEmpty) {
    taskIdentifierDescription = 'name "\$taskNameArg"';
    stderr.writeln(
        '[TodoistServer] task_id not provided, attempting to find task by name: "\$taskNameArg"');
    originalTask = await _findTaskByName(apiClient, taskNameArg);
    if (originalTask == null || originalTask.id == null) {
      return _createErrorResult(
          'Task matching name "\$taskNameArg" not found.');
    }
    resolvedTaskId = originalTask.id!;
    taskContentForMsg = originalTask.content ?? taskNameArg;
    stderr.writeln(
        '[TodoistServer] Found task ID \$resolvedTaskId by name "\$taskNameArg".');
  } else {
    return _createErrorResult(
        'Either task_id or task_name is required for completion.');
  }
  int? taskIdInt;
  try {
    taskIdInt = int.parse(resolvedTaskId);
  } catch (formatException) {
    return _createErrorResult(
      'Invalid Task ID format for completion: "\$resolvedTaskId". Expected an integer.',
      errorData: {'taskId': resolvedTaskId},
    );
  }
  try {
    stderr.writeln(
        '[TodoistServer] Calling TasksApi.closeTask for ID: \$taskIdInt (Identified by: \$taskIdentifierDescription)...');
    final tasksApi = todoist.TasksApi(apiClient);
    await tasksApi.closeTask(taskIdInt);
    final successMsg = 'Successfully completed task: "\$taskContentForMsg"';
    stderr.writeln('[TodoistServer] \$successMsg (ID: \$resolvedTaskId)');
    return _createSuccessResult(successMsg,
        resultData: {'taskId': resolvedTaskId});
  } catch (e) {
    final errorMsg =
        'Error completing Todoist task "\$taskContentForMsg" (ID: \$resolvedTaskId): \${e.toString()}';
    stderr.writeln('[TodoistServer] \$errorMsg');
    var apiErrorMsg = errorMsg;
    Map<String, dynamic>? errorData = {'taskId': resolvedTaskId};
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
      if (e.code == 404) {
        apiErrorMsg =
            'API Error completing task: Task with ID "\$resolvedTaskId" not found (404).';
      } else {
        apiErrorMsg =
            'API Error completing task "\$taskContentForMsg" (\${e.code}): \${e.message ?? "Unknown API error"}';
      }
      errorData['apiCode'] = e.code;
      errorData['apiMessage'] = e.message;
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> handleGetTodoistTaskById({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received get_todoist_task_by_id request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
        'Todoist API health check failed with the provided token.');
  }
  final taskId = args?['task_id'] as String?;
  if (taskId == null || taskId.trim().isEmpty) {
    return _createErrorResult('Task ID (`task_id`) is required.');
  }
  int? taskIdInt;
  try {
    taskIdInt = int.parse(taskId);
  } catch (formatException) {
    return _createErrorResult(
      'Invalid Task ID format: "\$taskId". Expected an integer.',
      errorData: {'taskId': taskId},
    );
  }
  try {
    stderr.writeln(
        '[TodoistServer] Calling TasksApi.getActiveTask for ID: \$taskIdInt...');
    final tasksApi = todoist.TasksApi(apiClient);
    final foundTask = await tasksApi.getActiveTask(taskIdInt);
    if (foundTask == null) {
      final msg = 'Task with ID "\$taskId" not found.';
      stderr.writeln('[TodoistServer] \$msg');
      return _createSuccessResult(msg,
          resultData: {'taskId': taskId, 'task': null});
    }
    final successMsg = 'Successfully retrieved task ID "\$taskId".';
    final taskDetails = {
      'id': foundTask.id,
      'content': foundTask.content,
      'description': foundTask.description,
      'priority': foundTask.priority,
      'due_string': foundTask.due?.dueObject?.string,
      'due_date': foundTask.due?.dueObject?.date,
      'due_datetime': foundTask.due?.dueObject?.datetime,
      'labels': foundTask.labels,
      'project_id': foundTask.projectId,
      'section_id': foundTask.sectionId,
      'created_at': foundTask.createdAt,
      'assignee_id': foundTask.assigneeId,
      'assigner_id': foundTask.assignerId,
      'comment_count': foundTask.commentCount,
      'url': foundTask.url,
      'is_completed': foundTask.isCompleted,
      'parent_id': foundTask.parentId,
      'order': foundTask.order,
      'duration_amount': foundTask.duration?.durationObject?.amount,
      'duration_unit': foundTask.duration?.durationObject?.unit,
    };
    stderr.writeln('[TodoistServer] \$successMsg');
    return _createSuccessResult(successMsg,
        resultData: {'taskId': taskId, 'task': taskDetails});
  } catch (e) {
    final errorMsg =
        'Error getting Todoist task by ID "\$taskId": \${e.toString()}';
    stderr.writeln('[TodoistServer] \$errorMsg');
    var apiErrorMsg = errorMsg;
    Map<String, dynamic>? errorData = {'taskId': taskId};
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
      if (e.code == 404) {
        apiErrorMsg =
            'API Error getting task: Task with ID "\$taskId" not found (404).';
      } else {
        apiErrorMsg =
            'API Error getting task "\$taskId" (\${e.code}): \${e.message ?? "Unknown API error"}';
      }
      errorData['apiCode'] = e.code;
      errorData['apiMessage'] = e.message;
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> handleGetTaskComments({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received get_task_comments request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
        'Todoist API health check failed with the provided token.');
  }
  final taskId = args?['task_id'] as String?;
  if (taskId == null || taskId.trim().isEmpty) {
    return _createErrorResult(
        'Task ID (`task_id`) is required to get comments.');
  }
  try {
    int.parse(taskId);
  } catch (formatException) {
    return _createErrorResult(
        'Invalid Task ID format: "\$taskId". Expected an integer.',
        errorData: {'taskId': taskId});
  }
  try {
    stderr.writeln(
        '[TodoistServer] Calling CommentsApi.getAllComments for task ID: \$taskId...');
    final commentsApi = todoist.CommentsApi(apiClient);
    final comments = await commentsApi.getAllComments(taskId: taskId);
    if (comments == null || comments.isEmpty) {
      final msg = 'No comments found for task ID "\$taskId".';
      stderr.writeln('[TodoistServer] \$msg');
      return _createSuccessResult(msg,
          resultData: {'taskId': taskId, 'comments': []});
    } else {
      final commentList = comments
          .map((c) => {
                'id': c.id,
                'content': c.content,
                'posted_at': c.postedAt?.toIso8601String(),
              })
          .toList();
      final msg =
          'Successfully retrieved \${commentList.length} comments for task ID "\$taskId".';
      stderr.writeln('[TodoistServer] \$msg');
      return _createSuccessResult(msg,
          resultData: {'taskId': taskId, 'comments': commentList});
    }
  } catch (e) {
    final errorMsg =
        'Error getting comments for task ID "\$taskId": \${e.toString()}';
    stderr.writeln('[TodoistServer] \$errorMsg');
    var apiErrorMsg = errorMsg;
    Map<String, dynamic>? errorData = {'taskId': taskId};
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
      apiErrorMsg = e.code == 404
          ? 'API Error getting comments: Task with ID "\$taskId" not found (404).'
          : 'API Error getting comments for task "\$taskId" (\${e.code}): \${e.message ?? "Unknown API error"}';
      errorData['apiCode'] = e.code;
      errorData['apiMessage'] = e.message;
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> handleCreateTaskComment({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received create_task_comment request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
        'Todoist API health check failed with the provided token.');
  }
  final taskIdArg = args?['task_id'] as String?;
  final taskNameArg = args?['task_name'] as String?;
  final contentText = args?['content'] as String?;
  String? resolvedTaskId;
  String taskIdentifierDescription = '';
  if (taskIdArg != null && taskIdArg.trim().isNotEmpty) {
    resolvedTaskId = taskIdArg;
    taskIdentifierDescription = 'ID "\$resolvedTaskId"';
    stderr.writeln('[TodoistServer] Using provided task_id: \$resolvedTaskId');
    try {
      int.parse(resolvedTaskId);
    } catch (formatException) {
      return _createErrorResult(
          'Invalid Task ID format: "\$resolvedTaskId". Expected an integer.',
          errorData: {'taskId': resolvedTaskId});
    }
  } else if (taskNameArg != null && taskNameArg.trim().isNotEmpty) {
    taskIdentifierDescription = 'name "\$taskNameArg"';
    stderr.writeln(
        '[TodoistServer] task_id not provided, attempting to find task by name: "\$taskNameArg"');
    final foundTask = await _findTaskByName(apiClient, taskNameArg);
    if (foundTask != null && foundTask.id != null) {
      resolvedTaskId = foundTask.id!;
      stderr.writeln(
          '[TodoistServer] Found task ID \$resolvedTaskId by name "\$taskNameArg".');
    } else {
      return _createErrorResult(
          'Task matching name "\$taskNameArg" not found.');
    }
  } else {
    return _createErrorResult(
        'Task ID (`task_id`) or Task Name (`task_name`) is required to create a comment.');
  }
  if (contentText == null || contentText.trim().isEmpty) {
    return _createErrorResult('Comment content (`content`) cannot be empty.');
  }
  try {
    stderr.writeln(
        '[TodoistServer] Calling CommentsApi.createComment for resolved task ID: \$resolvedTaskId (identified by \$taskIdentifierDescription)...');
    final commentsApi = todoist.CommentsApi(apiClient);
    final newComment = await commentsApi.createComment(
      contentText,
      taskId: resolvedTaskId,
    );
    if (newComment == null) {
      return _createErrorResult(
          'API returned null for the newly created comment.',
          errorData: {'taskId': resolvedTaskId});
    }
    final successMsg =
        'Comment added successfully to task ID "\$resolvedTaskId".';
    stderr.writeln(
        '[TodoistServer] \$successMsg (Comment ID: \${newComment.id})');
    return _createSuccessResult(
      successMsg,
      resultData: {
        'taskId': resolvedTaskId,
        'commentId': newComment.id,
        'comment': {
          'id': newComment.id,
          'content': newComment.content,
          'posted_at': newComment.postedAt?.toIso8601String(),
        }
      },
    );
  } catch (e) {
    final errorMsg =
        'Error creating comment for task ID "\$resolvedTaskId" (identified by \$taskIdentifierDescription): \${e.toString()}';
    stderr.writeln('[TodoistServer] \$errorMsg');
    var apiErrorMsg = errorMsg;
    Map<String, dynamic>? errorData = {'taskId': resolvedTaskId};
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
      if (e.code == 404) {
        apiErrorMsg =
            'API Error creating comment: Task with ID "\$resolvedTaskId" not found (404).';
      } else if (e.code == 400) {
        apiErrorMsg =
            'API Error creating comment: Invalid request for task "\$resolvedTaskId" (400 - check parameters). Message: \${e.message}';
      } else {
        apiErrorMsg =
            'API Error creating comment for task "\$resolvedTaskId" (\${e.code}): \${e.message ?? "Unknown API error"}';
      }
      errorData['apiCode'] = e.code;
      errorData['apiMessage'] = e.message;
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}
