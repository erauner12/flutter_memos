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
    await projectsApi.getProjects();
    stderr.writeln('[TodoistServer] API health check successful.');
    return true;
  } catch (e) {
    stderr.writeln('[TodoistServer] API health check failed: $e');
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.body}',
      );
    }
    return false;
  }
}

/// Finds a single active Todoist task by its content (case-insensitive contains).
/// Returns the first match found, or null if no match.
/// Logs a warning if multiple matches are found.
Future<todoist.Task?> _findTaskByName(
  todoist.ApiClient client,
  String taskName,
) async {
  if (taskName.trim().isEmpty) {
    stderr.writeln('[TodoistServer] _findTaskByName called with empty name.');
    return null;
  }
  stderr.writeln('[TodoistServer] Searching for task containing: "$taskName"');
  try {
    final tasksApi = todoist.TasksApi(client);
    final allTasks = await tasksApi.getTasks();
    if (allTasks == null) {
      stderr.writeln('[TodoistServer] Received null task list from API.');
      return null;
    }
    final matches =
        allTasks.where((task) {
          return task.content?.toLowerCase().contains(taskName.toLowerCase()) ??
              false;
        }).toList();
    if (matches.isEmpty) {
      stderr.writeln('[TodoistServer] No task found matching "$taskName".');
      return null;
    } else if (matches.length == 1) {
      stderr.writeln(
        '[TodoistServer] Found unique task matching "$taskName": ID ${matches.first.id}',
      );
      return matches.first;
    } else {
      stderr.writeln(
        '[TodoistServer] Warning: Found ${matches.length} tasks matching "$taskName". Using the first one: ID ${matches.first.id}, Content: "${matches.first.content}"',
      );
      return matches.first;
    }
  } catch (e) {
    stderr.writeln(
      '[TodoistServer] Error during _findTaskByName("$taskName"): $e',
    );
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.body}',
      );
    }
    return null;
  }
}

// MODIFY: Update main signature to accept args
Future<void> main(List<String> args) async {
  var transportMode = TransportMode.stdio; // Default
  String transportArg = args.firstWhere(
    (arg) => arg.startsWith('--transport='),
    orElse: () => '',
  );
  if (transportArg == '--transport=sse') {
    transportMode = TransportMode.sse;
  } else if (transportArg.isNotEmpty && transportArg != '--transport=stdio') {
    stderr.writeln(
      '[TodoistServer] Warning: Invalid --transport value "$transportArg". Defaulting to stdio.',
    );
  }
  stderr.writeln('[TodoistServer] Starting in ${transportMode.name} mode...');

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

  server.tool(
    'create_todoist_task',
    description: 'Creates a new task in Todoist using the configured API key.',
    inputSchemaProperties: {
      'content': {
        'type': 'string',
        'description': 'The content of the task (required).',
      },
      'description': {
        'type': 'string',
        'description': 'A detailed description for the task (optional).',
      },
      'project_id': {
        'type': 'string',
        'description':
            'ID of the project to add the task to (optional, defaults to Inbox).',
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
        'description':
            'Human-readable due date (e.g., "next Monday") (optional).',
      },
      'due_date': {
        'type': 'string',
        'description': 'Specific due date in YYYY-MM-DD format (optional).',
      },
      'due_datetime': {
        'type': 'string',
        'description':
            'Specific due date and time in RFC3339 UTC format (optional).',
      },
      'due_lang': {
        'type': 'string',
        'description': 'Language code if due_string is not English (optional).',
      },
      'assignee_id': {
        'type': 'string',
        'description':
            'ID of the user to assign the task to (optional, shared projects only).',
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
    callback: _handleCreateTodoistTask,
  );

  server.tool(
    'update_todoist_task',
    description:
        'Updates an existing task in Todoist by searching for it by name.',
    inputSchemaProperties: {
      'task_name': {
        'type': 'string',
        'description':
            'The name/content of the task to search for and update (required).',
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
    callback: _handleUpdateTodoistTask,
  );

  server.tool(
    'get_todoist_tasks',
    description: 'Retrieves active Todoist tasks based on criteria.',
    inputSchemaProperties: {
      'task_id': {
        'type': 'string',
        'description':
            'The specific ID of the task to retrieve. Takes precedence over filter/content_contains. Optional.',
      },
      'filter': {
        'type': 'string',
        'description':
            'Full Todoist filter query (e.g., "today & #Work", "p1", "search: keyword"). Used if task_id is not provided. Optional.',
      },
      'content_contains': {
        'type': 'string',
        'description':
            'Search for tasks whose content includes this text (used only if task_id and filter are not provided). Optional.',
      },
    },
    callback: _handleGetTodoistTasks,
  );

  server.tool(
    'todoist_delete_task',
    description: 'Deletes a task from Todoist by searching for it by name.',
    inputSchemaProperties: {
      'task_name': {
        'type': 'string',
        'description':
            'The name/content of the task to search for and delete (required).',
      },
    },
    callback: _handleDeleteTodoistTask,
  );

  server.tool(
    'todoist_complete_task',
    description:
        'Marks a task as complete in Todoist by searching for it by name.',
    inputSchemaProperties: {
      'task_name': {
        'type': 'string',
        'description':
            'The name/content of the task to search for and complete (required).',
      },
    },
    callback: _handleCompleteTodoistTask,
  );

  server.tool(
    'get_todoist_task_by_id',
    description: 'Retrieves a single active Todoist task by its specific ID.',
    inputSchemaProperties: {
      'task_id': {
        'type': 'string',
        'description': 'The exact ID of the task to retrieve (required).',
      },
    },
    callback: _handleGetTodoistTaskById,
  );

  server.tool(
    'get_task_comments',
    description: 'Retrieves all comments for a specific Todoist task ID.',
    inputSchemaProperties: {
      'task_id': {
        'type': 'string',
        'description':
            'The exact ID of the task whose comments to retrieve (required).',
      },
    },
    callback: _handleGetTaskComments,
  );

  server.tool(
    'create_task_comment',
    description: 'Adds a new comment to a Todoist task.',
    inputSchemaProperties: {
      'task_id': {
        'type': 'string',
        'description':
            'The exact ID of the task to add the comment to (optional, takes precedence over task_name).',
      },
      'task_name': {
        'type': 'string',
        'description':
            'The name/content of the task to search for (used if task_id is not provided).',
      },
      'content': {
        'type': 'string',
        'description': 'The text content of the comment (required).',
      },
    },
    callback: _handleCreateTaskComment,
  );

  stderr.writeln(
    '[TodoistServer] Registered tools: create_todoist_task, update_todoist_task, get_todoist_tasks, todoist_delete_task, todoist_complete_task, get_todoist_task_by_id, get_task_comments, create_task_comment',
  );

  if (transportMode == TransportMode.stdio) {
    final transport = mcp_dart.StdioServerTransport();

    ProcessSignal.sigint.watch().listen((signal) async {
      stderr.writeln(
        '[TodoistServer][stdio] Received SIGINT. Shutting down...',
      );
      await server.close();
      await transport.close();
      exit(0);
    });

    ProcessSignal.sigterm.watch().listen((signal) async {
      stderr.writeln(
        '[TodoistServer][stdio] Received SIGTERM. Shutting down...',
      );
      await server.close();
      await transport.close();
      exit(0);
    });

    try {
      await server.connect(transport);
      stderr.writeln(
        '[TodoistServer][stdio] MCP Server running on stdio, ready for connections.',
      );
      await stdout.flush();
      stderr.writeln('[TodoistServer][stdio] Initial stdout flushed.');
    } catch (e, s) {
      stderr.writeln(
        '[TodoistServer][stdio] Failed to connect to transport: $e\n$s',
      );
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
          "[TodoistServer][sse] Closing ${sseManager.activeSseTransports.length} active SSE transports...",
        );
        await Future.wait(
          sseManager.activeSseTransports.values.map((t) => t.close()),
        );
        stderr.writeln("[TodoistServer][sse] Active SSE transports closed.");
        await httpServer?.close(force: true);
        stderr.writeln("[TodoistServer][sse] HTTP server closed.");
      } catch (e) {
        stderr.writeln("[TodoistServer][sse] Error during shutdown: $e");
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
      stderr.writeln(
        '[TodoistServer][sse] Serving MCP over SSE (GET ${sseManager.ssePath}) and HTTP (POST ${sseManager.messagePath}) at http://${httpServer.address.host}:${httpServer.port}',
      );
      httpServer.listen(
        (HttpRequest request) {
          stderr.writeln(
            '[TodoistServer][sse] Request: ${request.method} ${request.uri}',
          );
          sseManager.handleRequest(request).catchError((e, s) {
            stderr.writeln(
              '[TodoistServer][sse] Error handling request ${request.uri}: $e\n$s',
            );
            try {
              if (request.response.connectionInfo != null) {
                request.response.statusCode = HttpStatus.internalServerError;
                request.response.write('Internal Server Error');
                request.response.close();
              }
            } catch (_) {
              stderr.writeln(
                '[TodoistServer][sse] Could not send error response for ${request.uri}. Connection likely closed.',
              );
            }
          });
        },
        onError:
            (e, s) =>
                stderr.writeln('[TodoistServer][sse] HttpServer error: $e\n$s'),
        onDone: () => stderr.writeln('[TodoistServer][sse] HttpServer closed.'),
      );
      stderr.writeln("[TodoistServer][sse] Signal handlers registered.");
    } catch (e, s) {
      stderr.writeln(
        '[TodoistServer][sse] FATAL: Failed to bind server to port $port: $e\n$s',
      );
      exit(1);
    }
  }
}

// --- Tool Handlers (Refactored) ---

mcp_dart.CallToolResult _createErrorResult(String message, {String? taskId}) {
  final payload = {'status': 'error', 'message': message};
  if (taskId != null) {
    payload['taskId'] = taskId;
  }
  return mcp_dart.CallToolResult(
    content: [mcp_dart.TextContent(text: jsonEncode(payload))],
    isError: true,
  );
}

Future<mcp_dart.CallToolResult> _handleCreateTodoistTask({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  final requestId = extra?.sessionId;
  stderr.writeln(
    '[TodoistServer] Received create_todoist_task request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
      'TODOIST_API_TOKEN environment variable not set or empty.',
    );
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
      'Todoist API health check failed with the provided token.',
    );
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
    labelIds: labels,
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
        'API returned null for the newly created task.',
      );
    }
    final successMsg =
        'Todoist task created successfully: "${newTask.content}" (ID: ${newTask.id})';
    stderr.writeln('[TodoistServer] $successMsg');
    final resultPayload = {
      'status': 'success',
      'message': successMsg,
      'taskId': newTask.id,
      'task': {
        'id': newTask.id,
        'content': newTask.content,
        'description': newTask.description,
        'priority': newTask.priority,
        'due_string': newTask.due?.string,
        'due_date': newTask.due?.date,
        'due_datetime': newTask.due?.datetime,
        'labels': newTask.labels,
        'project_id': newTask.projectId,
        'created_at': newTask.createdAt?.toIso8601String(),
      },
    };
    return mcp_dart.CallToolResult(
      content: [mcp_dart.TextContent(text: jsonEncode(resultPayload))],
    );
  } catch (e) {
    var apiErrorMsg = 'Error creating Todoist task: ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.body}',
      );
      apiErrorMsg =
          'API Error creating task (${e.code}): ${e.message ?? "Unknown API error"}';
    }
    return _createErrorResult(apiErrorMsg);
  }
}

Future<mcp_dart.CallToolResult> _handleUpdateTodoistTask({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  final requestId = extra?.sessionId;
  stderr.writeln(
    '[TodoistServer] Received update_todoist_task request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
      'TODOIST_API_TOKEN environment variable not set or empty.',
    );
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
      'Todoist API health check failed with the provided token.',
    );
  }
  final taskName = args?['task_name'] as String?;
  if (taskName == null || taskName.trim().isEmpty) {
    return _createErrorResult(
      'Task name (`task_name`) is required for updates.',
    );
  }
  final foundTask = await _findTaskByName(apiClient, taskName);
  if (foundTask == null || foundTask.id == null) {
    return _createErrorResult('Task matching "$taskName" not found.');
  }
  final taskId = foundTask.id!;
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
    labelIds: labels,
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
    stderr.writeln(
      '[TodoistServer] Update request for task "$taskName" (ID: $taskId) has no fields to update. Skipping API call.',
    );
    final msg =
        'No update fields provided for task "$taskName" (ID: $taskId). Task not changed.';
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({
            'status': 'success',
            'message': msg,
            'taskId': taskId,
          }),
        ),
      ],
    );
  }

  try {
    stderr.writeln(
      '[TodoistServer] Calling TasksApi.updateTask for found ID: $taskId (Original Name: "$taskName")...',
    );
    final tasksApi = todoist.TasksApi(apiClient);
    await tasksApi.updateTask(taskId, request);
    final successMsg =
        'Todoist task "${foundTask.content}" (ID: $taskId) updated successfully.';
    stderr.writeln('[TodoistServer] $successMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({
            'status': 'success',
            'message': successMsg,
            'taskId': taskId,
          }),
        ),
      ],
    );
  } catch (e) {
    final errorMsg =
        'Error updating Todoist task "${foundTask.content}" (ID: $taskId): ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    var apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.body}',
      );
      apiErrorMsg =
          'API Error updating task "${foundTask.content}" (${e.code}): ${e.message ?? "Unknown API error"}';
    }
    return _createErrorResult(apiErrorMsg, taskId: taskId);
  }
}

Future<mcp_dart.CallToolResult> _handleGetTodoistTasks({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  final requestId = extra?.sessionId;
  stderr.writeln(
    '[TodoistServer] Received get_todoist_tasks request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
      'TODOIST_API_TOKEN environment variable not set or empty.',
    );
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
      'Todoist API health check failed with the provided token.',
    );
  }
  final taskIdArg = args?['task_id'] as String?;
  final filterArg = args?['filter'] as String?;
  final contentContainsArg = args?['content_contains'] as String?;
  String? effectiveFilter;
  String? specificTaskId;
  if (taskIdArg != null && taskIdArg.trim().isNotEmpty) {
    specificTaskId = taskIdArg;
    stderr.writeln('[TodoistServer] Using specific task ID: $specificTaskId');
  }
  if (specificTaskId == null) {
    if (filterArg != null && filterArg.trim().isNotEmpty) {
      effectiveFilter = filterArg;
      stderr.writeln(
        '[TodoistServer] Using explicit filter: "$effectiveFilter"',
      );
    } else if (contentContainsArg != null &&
        contentContainsArg.trim().isNotEmpty) {
      effectiveFilter = 'search: "$contentContainsArg"';
      stderr.writeln(
        '[TodoistServer] Using filter from content_contains: "$effectiveFilter"',
      );
    } else {
      stderr.writeln(
        '[TodoistServer] No task_id, filter, or content_contains provided. Fetching all active tasks.',
      );
    }
  }
  try {
    final tasksApi = todoist.TasksApi(apiClient);
    List<todoist.Task> tasks = [];
    if (specificTaskId != null) {
      stderr.writeln(
        '[TodoistServer] Fetching specific task by ID: $specificTaskId',
      );
      try {
        final task = await tasksApi.getTask(specificTaskId);
        if (task != null) {
          tasks.add(task);
        } else {
          stderr.writeln(
            '[TodoistServer] Task with ID $specificTaskId not found by API.',
          );
          return mcp_dart.CallToolResult(
            content: [
              mcp_dart.TextContent(
                text: jsonEncode({
                  'status': 'success',
                  'message': 'Task with ID $specificTaskId not found.',
                  'result_list': [],
                }),
              ),
            ],
          );
        }
      } catch (e) {
        if (e is todoist.ApiException && e.code == 404) {
          stderr.writeln(
            '[TodoistServer] Task with ID $specificTaskId not found (404).',
          );
          return mcp_dart.CallToolResult(
            content: [
              mcp_dart.TextContent(
                text: jsonEncode({
                  'status': 'success',
                  'message': 'Task with ID $specificTaskId not found.',
                  'result_list': [],
                }),
              ),
            ],
          );
        } else {
          stderr.writeln(
            '[TodoistServer] Error fetching task by ID $specificTaskId: $e',
          );
          if (e is todoist.ApiException) {
            stderr.writeln(
              '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.body}',
            );
          }
          rethrow;
        }
      }
    } else {
      stderr.writeln(
        '[TodoistServer] Calling TasksApi.getTasks with filter: $effectiveFilter',
      );
      final result = await tasksApi.getTasks(filter: effectiveFilter);
      tasks = result ?? [];
    }
    if (tasks.isEmpty) {
      stderr.writeln(
        '[TodoistServer] No active tasks found matching the criteria.',
      );
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({
              'status': 'success',
              'message': 'No active tasks found matching the criteria.',
              'result_list': [],
            }),
          ),
        ],
      );
    } else {
      final tasksForAI =
          tasks
              .map(
                (task) => {
                  'id': task.id,
                  'content': task.content,
                  'description': task.description,
                  'priority': task.priority,
                  'due_string': task.due?.string,
                  'due_date': task.due?.date,
                  'due_datetime': task.due?.datetime,
                  'labels': task.labels,
                  'project_id': task.projectId,
                  'section_id': task.sectionId,
                  'created_at': task.createdAt?.toIso8601String(),
                  'assignee_id': task.assigneeId,
                  'comment_count': task.commentCount,
                  'url': task.url,
                  'is_completed': task.isCompleted,
                  'parent_id': task.parentId,
                  'order': task.order,
                  'duration_amount': task.duration?.amount,
                  'duration_unit': task.duration?.unit,
                },
              )
              .toList();
      final resultJson = jsonEncode({
        'status': 'success',
        'message': 'Found ${tasks.length} matching task(s).',
        'result_list': tasksForAI,
      });
      stderr.writeln(
        '[TodoistServer] Found ${tasks.length} task(s). Returning JSON list.',
      );
      return mcp_dart.CallToolResult(
        content: [mcp_dart.TextContent(text: resultJson)],
      );
    }
  } catch (e) {
    final errorMsg = 'Error getting Todoist tasks: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    var apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.body}',
      );
      apiErrorMsg =
          'API Error getting tasks (${e.code}): ${e.message ?? "Unknown API error"}';
    }
    return _createErrorResult(apiErrorMsg);
  }
}

Future<mcp_dart.CallToolResult> _handleDeleteTodoistTask({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  final requestId = extra?.sessionId;
  stderr.writeln(
    '[TodoistServer] Received delete_todoist_task request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
      'TODOIST_API_TOKEN environment variable not set or empty.',
    );
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
      'Todoist API health check failed with the provided token.',
    );
  }
  final taskName = args?['task_name'] as String?;
  if (taskName == null || taskName.trim().isEmpty) {
    return _createErrorResult(
      'Task name (`task_name`) is required for deletion.',
    );
  }
  final foundTask = await _findTaskByName(apiClient, taskName);
  if (foundTask == null || foundTask.id == null) {
    return _createErrorResult('Task matching "$taskName" not found.');
  }
  final taskId = foundTask.id!;
  final taskContent = foundTask.content ?? '[No Content]';
  try {
    stderr.writeln(
      '[TodoistServer] Calling TasksApi.deleteTask for ID: $taskId (Name: "$taskName")...',
    );
    final tasksApi = todoist.TasksApi(apiClient);
    await tasksApi.deleteTask(taskId);
    final successMsg = 'Successfully deleted task: "$taskContent"';
    stderr.writeln('[TodoistServer] $successMsg (ID: $taskId)');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({
            'status': 'success',
            'message': successMsg,
            'taskId': taskId,
          }),
        ),
      ],
    );
  } catch (e) {
    final errorMsg =
        'Error deleting Todoist task "$taskContent" (ID: $taskId): ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    var apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.body}',
      );
      if (e.code == 404) {
        apiErrorMsg =
            'API Error deleting task: Task with ID "$taskId" not found (404).';
      } else {
        apiErrorMsg =
            'API Error deleting task "$taskContent" (${e.code}): ${e.message ?? "Unknown API error"}';
      }
    }
    return _createErrorResult(apiErrorMsg, taskId: taskId);
  }
}

Future<mcp_dart.CallToolResult> _handleCompleteTodoistTask({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  final requestId = extra?.sessionId;
  stderr.writeln(
    '[TodoistServer] Received complete_todoist_task request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
      'TODOIST_API_TOKEN environment variable not set or empty.',
    );
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
      'Todoist API health check failed with the provided token.',
    );
  }
  final taskName = args?['task_name'] as String?;
  if (taskName == null || taskName.trim().isEmpty) {
    return _createErrorResult(
      'Task name (`task_name`) is required for completion.',
    );
  }
  final foundTask = await _findTaskByName(apiClient, taskName);
  if (foundTask == null || foundTask.id == null) {
    return _createErrorResult('Task matching "$taskName" not found.');
  }
  final taskId = foundTask.id!;
  final taskContent = foundTask.content ?? '[No Content]';
  try {
    stderr.writeln(
      '[TodoistServer] Calling TasksApi.closeTask for ID: $taskId (Name: "$taskName")...',
    );
    final tasksApi = todoist.TasksApi(apiClient);
    await tasksApi.closeTask(taskId);
    final successMsg = 'Successfully completed task: "$taskContent"';
    stderr.writeln('[TodoistServer] $successMsg (ID: $taskId)');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({
            'status': 'success',
            'message': successMsg,
            'taskId': taskId,
          }),
        ),
      ],
    );
  } catch (e) {
    final errorMsg =
        'Error completing Todoist task "$taskContent" (ID: $taskId): ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    var apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.body}',
      );
      if (e.code == 404) {
        apiErrorMsg =
            'API Error completing task: Task with ID "$taskId" not found (404).';
      } else {
        apiErrorMsg =
            'API Error completing task "$taskContent" (${e.code}): ${e.message ?? "Unknown API error"}';
      }
    }
    return _createErrorResult(apiErrorMsg, taskId: taskId);
  }
}

Future<mcp_dart.CallToolResult> _handleGetTodoistTaskById({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  final requestId = extra?.sessionId;
  stderr.writeln(
    '[TodoistServer] Received get_todoist_task_by_id request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
      'TODOIST_API_TOKEN environment variable not set or empty.',
    );
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
      'Todoist API health check failed with the provided token.',
    );
  }
  final taskId = args?['task_id'] as String?;
  if (taskId == null || taskId.trim().isEmpty) {
    return _createErrorResult('Task ID (`task_id`) is required.');
  }
  try {
    stderr.writeln(
      '[TodoistServer] Calling TasksApi.getTask for ID: $taskId...',
    );
    final tasksApi = todoist.TasksApi(apiClient);
    final foundTask = await tasksApi.getTask(taskId);
    if (foundTask == null) {
      final errorMsg = 'Task with ID "$taskId" not found.';
      stderr.writeln('[TodoistServer] $errorMsg');
      return _createErrorResult(errorMsg);
    }
    final taskDetails = {
      'id': foundTask.id,
      'content': foundTask.content,
      'description': foundTask.description,
      'priority': foundTask.priority,
      'due_string': foundTask.due?.string,
      'due_date': foundTask.due?.date,
      'due_datetime': foundTask.due?.datetime,
      'labels': foundTask.labels,
      'project_id': foundTask.projectId,
      'section_id': foundTask.sectionId,
      'created_at': foundTask.createdAt?.toIso8601String(),
      'assignee_id': foundTask.assigneeId,
      'assigner_id': foundTask.assignerId,
      'comment_count': foundTask.commentCount,
      'url': foundTask.url,
      'is_completed': foundTask.isCompleted,
      'parent_id': foundTask.parentId,
      'order': foundTask.order,
      'duration_amount': foundTask.duration?.amount,
      'duration_unit': foundTask.duration?.unit,
    };
    final successMsg =
        'Successfully retrieved task: "${foundTask.content}" (ID: ${foundTask.id})';
    stderr.writeln('[TodoistServer] $successMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({
            'status': 'success',
            'message': successMsg,
            'task': taskDetails,
          }),
        ),
      ],
    );
  } catch (e) {
    final errorMsg =
        'Error getting Todoist task by ID "$taskId": ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    var apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.body}',
      );
      if (e.code == 404) {
        apiErrorMsg =
            'API Error getting task: Task with ID "$taskId" not found (404).';
      } else {
        apiErrorMsg =
            'API Error getting task "$taskId" (${e.code}): ${e.message ?? "Unknown API error"}';
      }
    } else if (e is ArgumentError) {
      apiErrorMsg = 'Error: Invalid Task ID format provided: "$taskId".';
    }
    return _createErrorResult(apiErrorMsg);
  }
}

Future<mcp_dart.CallToolResult> _handleGetTaskComments({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  final requestId = extra?.sessionId;
  stderr.writeln(
    '[TodoistServer] Received get_task_comments request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
      'TODOIST_API_TOKEN environment variable not set or empty.',
    );
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
      'Todoist API health check failed with the provided token.',
    );
  }
  final taskId = args?['task_id'] as String?;
  if (taskId == null || taskId.trim().isEmpty) {
    return _createErrorResult(
      'Task ID (`task_id`) is required to get comments.',
    );
  }
  try {
    stderr.writeln(
      '[TodoistServer] Calling CommentsApi.getComments for task ID: $taskId...',
    );
    final commentsApi = todoist.CommentsApi(apiClient);
    final comments = await commentsApi.getComments(taskId: taskId);
    if (comments == null || comments.isEmpty) {
      final msg = 'No comments found for task ID "$taskId".';
      stderr.writeln('[TodoistServer] $msg');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({
              'status': 'success',
              'message': msg,
              'comments': [],
            }),
          ),
        ],
      );
    } else {
      final commentList =
          comments
              .map(
                (c) => {
                  'id': c.id,
                  'content': c.content,
                  'posted_at': c.postedAt?.toIso8601String(),
                },
              )
              .toList();
      final msg =
          'Successfully retrieved ${commentList.length} comments for task ID "$taskId".';
      stderr.writeln('[TodoistServer] $msg');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({
              'status': 'success',
              'message': msg,
              'comments': commentList,
            }),
          ),
        ],
      );
    }
  } catch (e) {
    final errorMsg =
        'Error getting comments for task ID "$taskId": ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    var apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.body}',
      );
      if (e.code == 404) {
        apiErrorMsg =
            'API Error getting comments: Task with ID "$taskId" not found (404).';
      } else {
        apiErrorMsg =
            'API Error getting comments for task "$taskId" (${e.code}): ${e.message ?? "Unknown API error"}';
      }
    }
    return _createErrorResult(apiErrorMsg);
  }
}

Future<mcp_dart.CallToolResult> _handleCreateTaskComment({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  final requestId = extra?.sessionId;
  stderr.writeln(
    '[TodoistServer] Received create_task_comment request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');
  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
      'TODOIST_API_TOKEN environment variable not set or empty.',
    );
  }
  if (!await _checkApiHealth(apiClient)) {
    return _createErrorResult(
      'Todoist API health check failed with the provided token.',
    );
  }
  final taskIdArg = args?['task_id'] as String?;
  final taskNameArg = args?['task_name'] as String?;
  final content = args?['content'] as String?;
  String? resolvedTaskId;
  String taskIdentifierDescription = '';
  if (taskIdArg != null && taskIdArg.trim().isNotEmpty) {
    resolvedTaskId = taskIdArg;
    taskIdentifierDescription = 'ID "$resolvedTaskId"';
    stderr.writeln('[TodoistServer] Using provided task_id: $resolvedTaskId');
  }
  if (resolvedTaskId == null &&
      taskNameArg != null &&
      taskNameArg.trim().isNotEmpty) {
    taskIdentifierDescription = 'name "$taskNameArg"';
    stderr.writeln(
      '[TodoistServer] task_id not provided, attempting to find task by name: "$taskNameArg"',
    );
    final foundTask = await _findTaskByName(apiClient, taskNameArg);
    if (foundTask != null && foundTask.id != null) {
      resolvedTaskId = foundTask.id!;
      stderr.writeln(
        '[TodoistServer] Found task ID $resolvedTaskId by name "$taskNameArg".',
      );
    } else {
      return _createErrorResult('Task matching name "$taskNameArg" not found.');
    }
  }
  if (resolvedTaskId == null) {
    return _createErrorResult(
      'Task ID (`task_id`) or Task Name (`task_name`) is required to create a comment.',
    );
  }
  if (content == null || content.trim().isEmpty) {
    return _createErrorResult('Comment content (`content`) cannot be empty.');
  }
  final request = todoist.CreateCommentRequest(
    taskId: resolvedTaskId,
    content: content,
  );
  try {
    stderr.writeln(
      '[TodoistServer] Calling CommentsApi.createComment for resolved task ID: $resolvedTaskId (identified by $taskIdentifierDescription)...',
    );
    final commentsApi = todoist.CommentsApi(apiClient);
    final newComment = await commentsApi.createComment(request);
    if (newComment == null) {
      return _createErrorResult(
        'API returned null for the newly created comment.',
        taskId: resolvedTaskId,
      );
    }
    final successMsg =
        'Comment added successfully to task ID "$resolvedTaskId".';
    stderr.writeln(
      '[TodoistServer] $successMsg (Comment ID: ${newComment.id})',
    );
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({
            'status': 'success',
            'message': successMsg,
            'taskId': resolvedTaskId,
            'commentId': newComment.id,
          }),
        ),
      ],
    );
  } catch (e) {
    final errorMsg =
        'Error creating comment for task ID "$resolvedTaskId" (identified by $taskIdentifierDescription): ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    var apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.body}',
      );
      if (e.code == 404) {
        apiErrorMsg =
            'API Error creating comment: Task with ID "$resolvedTaskId" not found (404).';
      } else if (e.code == 400) {
        apiErrorMsg =
            'API Error creating comment: Invalid request for task "$resolvedTaskId" (400 - check parameters).';
      } else {
        apiErrorMsg =
            'API Error creating comment for task "$resolvedTaskId" (${e.code}): ${e.message ?? "Unknown API error"}';
      }
    }
    return _createErrorResult(apiErrorMsg, taskId: resolvedTaskId);
  }
}
