import 'dart:async';
import 'dart:convert'; // For jsonEncode if needed for debugging args
import 'dart:io';

import 'package:flutter_memos/services/todoist_api_service.dart';
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;
import 'package:mcp_dart/mcp_dart.dart' as mcp_dart;

// Global instance of the service
final todoistService = TodoistApiService();

/// Finds a single active Todoist task by its content (case-insensitive contains).
/// Returns the first match found, or null if no match.
/// Logs a warning if multiple matches are found.
Future<todoist.Task?> _findTaskByName(String taskName) async {
  if (taskName.trim().isEmpty) {
    stderr.writeln('[TodoistServer] _findTaskByName called with empty name.');
    return null;
  }
  stderr.writeln('[TodoistServer] Searching for task containing: "$taskName"');
  try {
    // Fetch all active tasks - consider adding a filter if performance becomes an issue
    final allTasks = await todoistService.getActiveTasks();
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
    return null;
  }
}

void main() async {
  // Configure verbose logging for the service if desired (matches app setting)
  TodoistApiService.verboseLogging = true;

  // 1. Create the McpServer instance
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

  // 2. Register Tools
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
        'items': {'type': 'string'}
      },
      'priority': {
        'type': 'integer',
        'description': 'Task priority from 1 (normal) to 4 (urgent) (optional).',
      },
      'due_string': {
        'type': 'string',
        'description': 'Human-readable due date (e.g., "next Monday") (optional).',
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
        'description': 'ID of the user to assign the task to (optional, shared projects only).',
      },
    },
    callback:
        (args, extra) => _handleCreateTodoistTask(args: args, extra: extra),
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
    callback:
        (args, extra) => _handleUpdateTodoistTask(args: args, extra: extra),
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
    callback: (args, extra) => _handleGetTodoistTasks(args: args, extra: extra),
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
    callback:
        (args, extra) => _handleDeleteTodoistTask(args: args, extra: extra),
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
    callback:
        (args, extra) => _handleCompleteTodoistTask(args: args, extra: extra),
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
    callback:
        (args, extra) => _handleGetTodoistTaskById(args: args, extra: extra),
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
    callback: (args, extra) => _handleGetTaskComments(args: args, extra: extra),
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
    callback:
        (args, extra) => _handleCreateTaskComment(args: args, extra: extra),
  );

  // 3. Connect to the Transport
  final transport = mcp_dart.StdioServerTransport();

  // Handle signals for graceful shutdown
  ProcessSignal.sigint.watch().listen((signal) async {
    stderr.writeln('[TodoistServer] Received SIGINT. Shutting down...');
    await server.close();
    await transport.close();
    exit(0);
  });

  ProcessSignal.sigterm.watch().listen((signal) async {
    stderr.writeln('[TodoistServer] Received SIGTERM. Shutting down...');
    await server.close();
    await transport.close();
    exit(0);
  });

  try {
    await server.connect(transport);
    stderr.writeln('[TodoistServer] MCP Server running on stdio, ready for connections.');
    stderr.writeln(
      '[TodoistServer] Registered tools: create_todoist_task, update_todoist_task, get_todoist_tasks, todoist_delete_task, todoist_complete_task, get_todoist_task_by_id, get_task_comments, create_task_comment',
    );
    // Explicitly flush stdout to ensure the initial message is sent immediately.
    stdout.flush();
    // Add a small delay and flush again in case initialization takes time.
    await Future.delayed(const Duration(milliseconds: 100));
    stdout.flush();
    stderr.writeln('[TodoistServer] Initial stdout flushed.');
  } catch (e, s) {
    stderr.writeln('[TodoistServer] Failed to connect to transport: $e\n$s');
    exit(1);
  }
  // Keep the main isolate running. The server runs in background listeners.
  // We don't need an infinite loop here if the server keeps the isolate alive.
}

// Handler function for the 'create_todoist_task' tool
Future<mcp_dart.CallToolResult> _handleCreateTodoistTask({
  Map<String, dynamic>? args,
  mcp_dart.RequestHandlerExtra? extra, // Explicitly typed extra
}) async {
  final requestId = extra?.request.id; // Extract request ID
  stderr.writeln(
    '[TodoistServer] Received create_todoist_task request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    final errorMsg =
        'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');

    // Manually write error JSON-RPC response
    final errorPayload = {
      'code': -32000,
      'message': 'Environment token error',
      'data': errorMsg,
    };
    final responsePayload = {
      'jsonrpc': '2.0',
      'id': requestId,
      'error': errorPayload,
    };
    final responseJson = jsonEncode(responsePayload);
    stderr.writeln(
      '[TodoistServer] Manually writing error to stdout: $responseJson',
    );
    stdout.writeln(responseJson);
    await stdout.flush();

    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        ),
      ],
      isError: true,
    );
  }

  stderr.writeln(
    '[TodoistServer] Configuring TodoistApiService with provided token.',
  );
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
      final errorMsg =
          'Error: Todoist API health check failed with the provided token.';
      stderr.writeln('[TodoistServer] $errorMsg');

      final errorPayload = {
        'code': -32000,
        'message': 'Health check failed',
        'data': errorMsg,
      };
      final responsePayload = {
        'jsonrpc': '2.0',
        'id': requestId,
        'error': errorPayload,
      };
      final responseJson = jsonEncode(responsePayload);
      stderr.writeln(
        '[TodoistServer] Manually writing error to stdout: $responseJson',
      );
      stdout.writeln(responseJson);
      await stdout.flush();

      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({'status': 'error', 'message': errorMsg}),
          ),
        ],
        isError: true,
      );
    }
    stderr.writeln(
      '[TodoistServer] TodoistApiService configured and health check passed.',
    );
  } catch (e) {
    final errorMsg = 'Error configuring TodoistApiService: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');

    final errorPayload = {
      'code': -32000,
      'message': 'Configuration error',
      'data': errorMsg,
    };
    final responsePayload = {
      'jsonrpc': '2.0',
      'id': requestId,
      'error': errorPayload,
    };
    final responseJson = jsonEncode(responsePayload);
    stderr.writeln(
      '[TodoistServer] Manually writing error to stdout: $responseJson',
    );
    stdout.writeln(responseJson);
    await stdout.flush();

    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        ),
      ],
      isError: true,
    );
  }

  final content = args?['content'] as String?;
  if (content == null || content.trim().isEmpty) {
    const errorMsg = 'Error: Task content cannot be empty.';
    stderr.writeln('[TodoistServer] $errorMsg');

    final errorPayload = {
      'code': -32000,
      'message': 'Empty task content',
      'data': errorMsg,
    };
    final responsePayload = {
      'jsonrpc': '2.0',
      'id': requestId,
      'error': errorPayload,
    };
    final responseJson = jsonEncode(responsePayload);
    stderr.writeln(
      '[TodoistServer] Manually writing error to stdout: $responseJson',
    );
    stdout.writeln(responseJson);
    await stdout.flush();

    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        ),
      ],
      isError: true,
    );
  }

  final description = args?['description'] as String?;
  final projectId = args?['project_id'] as String?;
  final sectionId = args?['section_id'] as String?;
  final labels = (args?['labels'] as List<dynamic>?)?.cast<String>();
  final priorityStr = args?['priority']?.toString();
  final dueString = args?['due_string'] as String?;
  final dueDate = args?['due_date'] as String?;
  final dueDatetime = args?['due_datetime'] as String?;
  final dueLang = args?['due_lang'] as String?;
  final assigneeId = args?['assignee_id'] as String?;

  todoist.TaskDue? due;
  if (dueString != null || dueDate != null || dueDatetime != null) {
    DateTime? parsedDueDate;
    DateTime? parsedDueDateTime;
    try {
      if (dueDate != null) parsedDueDate = DateTime.parse(dueDate);
      if (dueDatetime != null) parsedDueDateTime = DateTime.parse(dueDatetime);
    } catch (e) {
      stderr.writeln(
        '[TodoistServer] Warning: Could not parse due date/datetime: $e',
      );
    }
    due = todoist.TaskDue(
      dueObject: todoist.Due(
        string: dueString ?? '',
        date: parsedDueDate ?? DateTime.now(),
        datetime: parsedDueDateTime,
        isRecurring: false,
        timezone: dueLang,
      ),
    );
  }

  try {
    stderr.writeln('[TodoistServer] Calling todoistService.createTask...');
    final newTask = await todoistService.createTask(
      content: content,
      description: description,
      projectId: projectId,
      sectionId: sectionId,
      labelIds: labels,
      priority: priorityStr,
      due: due,
      assigneeId: assigneeId,
    );

    final successMsg =
        'Todoist task created successfully: "${newTask.content}" (ID: ${newTask.id})';
    stderr.writeln('[TodoistServer] $successMsg');

    // --- Manually write JSON-RPC success response ---
    final resultPayload = {
      'status': 'success',
      'message': successMsg,
      'taskId': newTask.id,
    };
    final responsePayload = {
      'jsonrpc': '2.0',
      'id': requestId,
      'result': {
        'content': [
          {'text': jsonEncode(resultPayload)},
        ],
      },
    };
    final responseJson = jsonEncode(responsePayload);
    stderr.writeln(
      '[TodoistServer] Manually writing success to stdout: $responseJson',
    );
    stdout.writeln(responseJson);
    await stdout.flush();
    // --- End Manual Write ---

    return mcp_dart.CallToolResult(
      content: [mcp_dart.TextContent(text: jsonEncode(resultPayload))],
    );
  } catch (e) {
    final errorMsg = 'Error creating Todoist task: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');

    // --- Manually write JSON-RPC error response ---
    final errorPayload = {
      'code': -32000,
      'message': 'Server error during task creation',
      'data': errorMsg,
    };
    final responsePayload = {
      'jsonrpc': '2.0',
      'id': requestId,
      'error': errorPayload,
    };
    final responseJson = jsonEncode(responsePayload);
    stderr.writeln(
      '[TodoistServer] Manually writing error to stdout: $responseJson',
    );
    stdout.writeln(responseJson);
    await stdout.flush();
    // --- End Manual Write ---

    return mcp_dart.CallToolResult(
      isError: true,
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        ),
      ],
    );
  }
}

// Handler function for the 'update_todoist_task' tool
Future<mcp_dart.CallToolResult> _handleUpdateTodoistTask({
  Map<String, dynamic>? args,
  mcp_dart.RequestHandlerExtra? extra, // Explicitly typed extra
}) async {
  final requestId = extra?.request.id;
  stderr.writeln(
    '[TodoistServer] Received update_todoist_task request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  // 1. Retrieve API Token
  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    const errorMsg =
        'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  // 2. Configure the Todoist Service
  stderr.writeln(
    '[TodoistServer] Configuring TodoistApiService with provided token.',
  );
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
      const errorMsg =
          'Error: Todoist API health check failed with the provided token.';
      stderr.writeln('[TodoistServer] $errorMsg');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({'status': 'error', 'message': errorMsg}),
          )
        ],
      );
    }
    stderr.writeln(
      '[TodoistServer] TodoistApiService configured and health check passed.',
    );
  } catch (e) {
    final errorMsg = 'Error configuring TodoistApiService: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  // 3. Parse Arguments - task_name is required
  final taskName = args?['task_name'] as String?;
  if (taskName == null || taskName.trim().isEmpty) {
    const errorMsg = 'Error: Task name (`task_name`) is required for updates.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  // Find the task first
  final foundTask = await _findTaskByName(taskName);
  if (foundTask == null) {
    final errorMsg = 'Error: Task matching "$taskName" not found.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }
  final taskId = foundTask.id!;

  // Parse optional arguments for the update
  final content = args?['content'] as String?;
  final description = args?['description'] as String?;
  final labels = (args?['labels'] as List<dynamic>?)?.cast<String>();
  final priorityStr = args?['priority']?.toString();
  final dueString = args?['due_string'] as String?;
  final dueDate = args?['due_date'] as String?;
  final dueDatetime = args?['due_datetime'] as String?;
  final dueLang = args?['due_lang'] as String?;
  final assigneeId = args?['assignee_id'] as String?;
  final durationAmount = args?['duration'] as int?;
  final durationUnit = args?['duration_unit'] as String?;

  // Construct Due object
  todoist.TaskDue? due;
  if (dueString != null || dueDate != null || dueDatetime != null) {
    DateTime? parsedDueDate;
    DateTime? parsedDueDateTime;
    try {
      if (dueDate != null) parsedDueDate = DateTime.parse(dueDate);
      if (dueDatetime != null) parsedDueDateTime = DateTime.parse(dueDatetime);
    } catch (e) {
      stderr.writeln(
        '[TodoistServer] Warning: Could not parse due date/datetime for update: $e',
      );
    }
    due = todoist.TaskDue(
      dueObject: todoist.Due(
        string: dueString ?? '',
        date: parsedDueDate ?? DateTime.now(),
        datetime: parsedDueDateTime,
        isRecurring: false,
        timezone: dueLang,
      ),
    );
  }

  // Construct Duration object
  todoist.TaskDuration? duration;
  if (durationAmount != null && durationUnit != null) {
    if ((durationUnit == 'minute' || durationUnit == 'day') &&
        durationAmount > 0) {
      duration = todoist.TaskDuration(
        durationObject: todoist.Duration(
          amount: durationAmount,
          unit: durationUnit,
        ),
      );
    } else {
      stderr.writeln(
        '[TodoistServer] Warning: Invalid duration amount ($durationAmount) or unit ($durationUnit) provided for update. Ignoring duration.',
      );
    }
  } else if (durationAmount != null || durationUnit != null) {
    stderr.writeln(
      '[TodoistServer] Warning: Both duration amount and unit must be provided for update. Ignoring duration.',
    );
  }

  // 4. Call Todoist API Update Method using the found ID
  try {
    stderr.writeln(
      '[TodoistServer] Calling todoistService.updateTask for found ID: $taskId (Original Name: "$taskName")...',
    );
    await todoistService.updateTask(
      id: taskId,
      content: content,
      description: description,
      labelIds: labels,
      priority: priorityStr,
      due: due,
      duration: duration,
      assigneeId: assigneeId,
    );

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
        )
      ],
    );
  } catch (e) {
    final errorMsg =
        'Error updating Todoist task "${foundTask.content}" (ID: $taskId): ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    String apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.innerException}',
      );
      apiErrorMsg =
          'API Error updating task "${foundTask.content}" (${e.code}): ${e.message}';
    }
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({
            'status': 'error',
            'message': apiErrorMsg,
            'taskId': taskId,
          }),
        )
      ],
    );
  }
}

// Handler function for the 'get_todoist_tasks' tool with modifications for task_id handling
Future<mcp_dart.CallToolResult> _handleGetTodoistTasks({
  Map<String, dynamic>? args,
  mcp_dart.RequestHandlerExtra? extra, // Explicitly typed extra
}) async {
  final requestId = extra?.request.id;
  stderr.writeln(
    '[TodoistServer] Received get_todoist_tasks request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    const errorMsg =
        'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  stderr.writeln('[TodoistServer] Configuring TodoistApiService...');
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
      const errorMsg = 'Error: Todoist API health check failed.';
      stderr.writeln('[TodoistServer] $errorMsg');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({'status': 'error', 'message': errorMsg}),
          )
        ],
      );
    }
    stderr.writeln(
      '[TodoistServer] TodoistApiService configured and health check passed.',
    );
  } catch (e) {
    final errorMsg = 'Error configuring TodoistApiService: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  final taskIdArg = args?['task_id'] as String?;
  final filterArg = args?['filter'] as String?;
  final contentContainsArg = args?['content_contains'] as String?;
  String? effectiveFilter;
  List<int>? taskIdsToFetch;

  if (taskIdArg != null && taskIdArg.trim().isNotEmpty) {
    final parsedId = int.tryParse(taskIdArg);
    if (parsedId != null) {
      taskIdsToFetch = [parsedId];
      stderr.writeln('[TodoistServer] Using specific task ID: $parsedId');
    } else {
      stderr.writeln(
        '[TodoistServer] Warning: Invalid task_id format provided: "$taskIdArg". Ignoring.',
      );
    }
  }

  if (taskIdsToFetch == null) {
    if (filterArg != null && filterArg.trim().isNotEmpty) {
      effectiveFilter = filterArg;
      stderr.writeln(
        '[TodoistServer] Using explicit filter: "$effectiveFilter"',
      );
    } else if (contentContainsArg != null &&
        contentContainsArg.trim().isNotEmpty) {
      effectiveFilter = 'search: $contentContainsArg';
      stderr.writeln(
        '[TodoistServer] Using constructed filter from content_contains: "$effectiveFilter"',
      );
    } else {
      stderr.writeln(
        '[TodoistServer] No task_id, filter, or content_contains provided. Fetching all active tasks.',
      );
    }
  }

  try {
    List<todoist.Task> tasks = [];
    if (taskIdsToFetch != null && taskIdsToFetch.isNotEmpty) {
      stderr.writeln(
        '[TodoistServer] Fetching specific task by ID: ${taskIdsToFetch.first}',
      );
      tasks = await todoistService.getActiveTasks(ids: taskIdsToFetch);
    } else {
      stderr.writeln(
        '[TodoistServer] Calling todoistService.getActiveTasks with filter: $effectiveFilter',
      );
      tasks = await todoistService.getActiveTasks(filter: effectiveFilter);
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
          )
        ],
      );
    } else if (tasks.length == 1) {
      final singleTask = tasks.first;
      final taskId = singleTask.id;
      final taskContent = singleTask.content ?? '[No Content]';
      final successMsg = 'Found single matching task: "$taskContent"';
      stderr.writeln('[TodoistServer] $successMsg (ID: $taskId)');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({
              'status': 'success',
              'message': successMsg,
              'taskId': taskId,
              'content': taskContent,
            }),
          )
        ],
      );
    } else {
      final tasksForAI = tasks.map((task) => {
        'id': task.id,
        'content': task.content,
                  'created_at':
                      task.createdAt != null
                          ? DateTime.parse(task.createdAt!).toIso8601String()
                          : null,
      }).toList();

      final resultJson = jsonEncode({
        'status': 'success',
        'message': 'Found ${tasks.length} matching tasks.',
        'result_list': tasksForAI,
      });
      stderr.writeln(
        '[TodoistServer] Found ${tasks.length} tasks. Returning JSON list.',
      );
      return mcp_dart.CallToolResult(
        content: [mcp_dart.TextContent(text: resultJson)],
      );
    }
  } catch (e) {
    final errorMsg = 'Error getting Todoist tasks: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    String apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.innerException}',
      );
      apiErrorMsg = 'API Error getting tasks (${e.code}): ${e.message}';
    }
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': apiErrorMsg}),
        )
      ],
    );
  }
}

// Handler function for the 'delete_todoist_task' tool
Future<mcp_dart.CallToolResult> _handleDeleteTodoistTask({
  Map<String, dynamic>? args,
  mcp_dart.RequestHandlerExtra? extra, // Explicitly typed extra
}) async {
  final requestId = extra?.request.id;
  stderr.writeln(
    '[TodoistServer] Received delete_todoist_task request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    const errorMsg =
        'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  stderr.writeln('[TodoistServer] Configuring TodoistApiService...');
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
      const errorMsg = 'Error: Todoist API health check failed.';
      stderr.writeln('[TodoistServer] $errorMsg');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({'status': 'error', 'message': errorMsg}),
          )
        ],
      );
    }
    stderr.writeln(
      '[TodoistServer] TodoistApiService configured and health check passed.',
    );
  } catch (e) {
    final errorMsg = 'Error configuring TodoistApiService: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  final taskName = args?['task_name'] as String?;
  if (taskName == null || taskName.trim().isEmpty) {
    const errorMsg = 'Error: Task name (`task_name`) is required for deletion.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  final foundTask = await _findTaskByName(taskName);
  if (foundTask == null) {
    final errorMsg = 'Error: Task matching "$taskName" not found.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }
  final taskId = foundTask.id!;
  final taskContent = foundTask.content ?? '[No Content]';

  try {
    stderr.writeln(
      '[TodoistServer] Calling todoistService.deleteTask for ID: $taskId (Name: "$taskName")...',
    );
    await todoistService.deleteTask(taskId);
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
        )
      ],
    );
  } catch (e) {
    final errorMsg =
        'Error deleting Todoist task "$taskContent" (ID: $taskId): ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    String apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.innerException}',
      );
      apiErrorMsg =
          'API Error deleting task "$taskContent" (${e.code}): ${e.message}';
    }
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({
            'status': 'error',
            'message': apiErrorMsg,
            'taskId': taskId,
          }),
        )
      ],
    );
  }
}

// Handler function for the 'complete_todoist_task' tool
Future<mcp_dart.CallToolResult> _handleCompleteTodoistTask({
  Map<String, dynamic>? args,
  mcp_dart.RequestHandlerExtra? extra, // Explicitly typed extra
}) async {
  final requestId = extra?.request.id;
  stderr.writeln(
    '[TodoistServer] Received complete_todoist_task request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    const errorMsg =
        'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  stderr.writeln('[TodoistServer] Configuring TodoistApiService...');
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
      const errorMsg = 'Error: Todoist API health check failed.';
      stderr.writeln('[TodoistServer] $errorMsg');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({'status': 'error', 'message': errorMsg}),
          )
        ],
      );
    }
    stderr.writeln(
      '[TodoistServer] TodoistApiService configured and health check passed.',
    );
  } catch (e) {
    final errorMsg = 'Error configuring TodoistApiService: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  final taskName = args?['task_name'] as String?;
  if (taskName == null || taskName.trim().isEmpty) {
    const errorMsg =
        'Error: Task name (`task_name`) is required for completion.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  final foundTask = await _findTaskByName(taskName);
  if (foundTask == null) {
    final errorMsg = 'Error: Task matching "$taskName" not found.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }
  final taskId = foundTask.id!;
  final taskContent = foundTask.content ?? '[No Content]';

  try {
    stderr.writeln(
      '[TodoistServer] Calling todoistService.closeTask for ID: $taskId (Name: "$taskName")...',
    );
    await todoistService.closeTask(taskId);
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
        )
      ],
    );
  } catch (e) {
    final errorMsg =
        'Error completing Todoist task "$taskContent" (ID: $taskId): ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    String apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.innerException}',
      );
      apiErrorMsg =
          'API Error completing task "$taskContent" (${e.code}): ${e.message}';
    }
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({
            'status': 'error',
            'message': apiErrorMsg,
            'taskId': taskId,
          }),
        )
      ],
    );
  }
}

// Handler function for the 'get_todoist_task_by_id' tool
Future<mcp_dart.CallToolResult> _handleGetTodoistTaskById({
  Map<String, dynamic>? args,
  mcp_dart.RequestHandlerExtra? extra, // Explicitly typed extra
}) async {
  final requestId = extra?.request.id;
  stderr.writeln(
    '[TodoistServer] Received get_todoist_task_by_id request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  // 1. API Token Check & Service Configuration
  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    const errorMsg =
        'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  stderr.writeln('[TodoistServer] Configuring TodoistApiService...');
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
      const errorMsg = 'Error: Todoist API health check failed.';
      stderr.writeln('[TodoistServer] $errorMsg');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({'status': 'error', 'message': errorMsg}),
          )
        ],
      );
    }
    stderr.writeln(
      '[TodoistServer] TodoistApiService configured and health check passed.',
    );
  } catch (e) {
    final errorMsg = 'Error configuring TodoistApiService: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  // 2. Parse Arguments
  final taskId = args?['task_id'] as String?;
  if (taskId == null || taskId.trim().isEmpty) {
    const errorMsg = 'Error: Task ID (`task_id`) is required.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  // 3. Call Service Method
  try {
    stderr.writeln(
      '[TodoistServer] Calling todoistService.getActiveTaskById for ID: $taskId...',
    );
    final foundTask = await todoistService.getActiveTaskById(taskId);

    if (foundTask == null) {
      final errorMsg = 'Task with ID "$taskId" not found or an error occurred.';
      stderr.writeln('[TodoistServer] $errorMsg');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({'status': 'error', 'message': errorMsg}),
          )
        ],
      );
    }

    // 4. Format Success Response
    final taskDetails = {
      'id': foundTask.id,
      'content': foundTask.content,
      'description': foundTask.description,
      'priority': foundTask.priority,
      'due_string': foundTask.due?.dueObject?.string,
      'due_date': foundTask.due?.dueObject?.date.toIso8601String().substring(
        0,
        10,
      ),
      'due_datetime': foundTask.due?.dueObject?.datetime?.toIso8601String(),
      'labels': foundTask.labels,
      'project_id': foundTask.projectId,
      'section_id': foundTask.sectionId,
      'created_at':
          foundTask.createdAt != null
              ? DateTime.parse(foundTask.createdAt!).toIso8601String()
              : null,
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
        )
      ],
    );
  } catch (e) {
    final errorMsg =
        'Error getting Todoist task by ID "$taskId": ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    String apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.innerException}',
      );
      apiErrorMsg =
          'API Error getting task "$taskId" (${e.code}): ${e.message}';
    } else if (e is ArgumentError) {
      apiErrorMsg = 'Error: Invalid Task ID format provided: "$taskId".';
    }
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': apiErrorMsg}),
        )
      ],
    );
  }
}

// Handler function for the 'get_task_comments' tool
Future<mcp_dart.CallToolResult> _handleGetTaskComments({
  Map<String, dynamic>? args,
  mcp_dart.RequestHandlerExtra? extra, // Explicitly typed extra
}) async {
  final requestId = extra?.request.id;
  stderr.writeln(
    '[TodoistServer] Received get_task_comments request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  // 1. API Token Check & Service Configuration (Standard Setup)
  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    const errorMsg =
        'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }
  stderr.writeln('[TodoistServer] Configuring TodoistApiService...');
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
      const errorMsg = 'Error: Todoist API health check failed.';
      stderr.writeln('[TodoistServer] $errorMsg');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({'status': 'error', 'message': errorMsg}),
          )
        ],
      );
    }
    stderr.writeln(
      '[TodoistServer] TodoistApiService configured and health check passed.',
    );
  } catch (e) {
    final errorMsg = 'Error configuring TodoistApiService: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  // 2. Parse Arguments
  final taskId = args?['task_id'] as String?;
  if (taskId == null || taskId.trim().isEmpty) {
    const errorMsg = 'Error: Task ID (`task_id`) is required to get comments.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  // 3. Call Service Method
  try {
    stderr.writeln(
      '[TodoistServer] Calling todoistService.getAllComments for task ID: $taskId...',
    );
    final comments = await todoistService.getAllComments(taskId: taskId);

    // 4. Format Response
    if (comments.isEmpty) {
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
          )
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
          )
        ],
      );
    }
  } catch (e) {
    final errorMsg =
        'Error getting comments for task ID "$taskId": ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    String apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.innerException}',
      );
      apiErrorMsg =
          'API Error getting comments for task "$taskId" (${e.code}): ${e.message}';
    }
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': apiErrorMsg}),
        )
      ],
    );
  }
}

// Handler function for the 'create_task_comment' tool
Future<mcp_dart.CallToolResult> _handleCreateTaskComment({
  Map<String, dynamic>? args,
  mcp_dart.RequestHandlerExtra? extra, // Explicitly typed extra
}) async {
  final requestId = extra?.request.id;
  stderr.writeln(
    '[TodoistServer] Received create_task_comment request ID: $requestId.',
  );
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  // 1. API Token Check & Service Configuration (Standard Setup)
  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    const errorMsg =
        'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }
  stderr.writeln('[TodoistServer] Configuring TodoistApiService...');
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
      const errorMsg = 'Error: Todoist API health check failed.';
      stderr.writeln('[TodoistServer] $errorMsg');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({'status': 'error', 'message': errorMsg}),
          )
        ],
      );
    }
    stderr.writeln(
      '[TodoistServer] TodoistApiService configured and health check passed.',
    );
  } catch (e) {
    final errorMsg = 'Error configuring TodoistApiService: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  // 2. Parse Arguments and Resolve Task ID
  final taskIdArg = args?['task_id'] as String?;
  final taskNameArg = args?['task_name'] as String?;
  final content = args?['content'] as String?;
  String? resolvedTaskId;
  String taskIdentifierDescription = ''; // For logging/error messages

  if (taskIdArg != null && taskIdArg.trim().isNotEmpty) {
    if (int.tryParse(taskIdArg) != null) {
      resolvedTaskId = taskIdArg;
      taskIdentifierDescription = 'ID "$resolvedTaskId"';
      stderr.writeln('[TodoistServer] Using provided task_id: $resolvedTaskId');
    } else {
      stderr.writeln(
        '[TodoistServer] Warning: Provided task_id "$taskIdArg" is not a valid number. Ignoring.',
      );
    }
  }

  if (resolvedTaskId == null &&
      taskNameArg != null &&
      taskNameArg.trim().isNotEmpty) {
    taskIdentifierDescription = 'name "$taskNameArg"';
    stderr.writeln(
      '[TodoistServer] task_id not provided or invalid, attempting to find task by name: "$taskNameArg"',
    );
    final foundTask = await _findTaskByName(taskNameArg);
    if (foundTask != null) {
      resolvedTaskId = foundTask.id;
      stderr.writeln(
        '[TodoistServer] Found task ID $resolvedTaskId by name "$taskNameArg".',
      );
    } else {
      final errorMsg = 'Error: Task matching name "$taskNameArg" not found.';
      stderr.writeln('[TodoistServer] $errorMsg');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({'status': 'error', 'message': errorMsg}),
          )
        ],
      );
    }
  }

  if (resolvedTaskId == null) {
    const errorMsg =
        'Error: Task ID (`task_id`) or Task Name (`task_name`) is required to create a comment.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }

  if (content == null || content.trim().isEmpty) {
    const errorMsg = 'Error: Comment content (`content`) cannot be empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        )
      ],
    );
  }
  // 3. Call Service Method using the resolved Task ID
  try {
    stderr.writeln(
      '[TodoistServer] Calling todoistService.createComment for resolved task ID: $resolvedTaskId (identified by $taskIdentifierDescription)...',
    );
    final newComment = await todoistService.createComment(
      taskId: resolvedTaskId,
      content: content,
    );

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
        )
      ],
    );
  } catch (e) {
    final errorMsg =
        'Error creating comment for task ID "$resolvedTaskId" (identified by $taskIdentifierDescription): ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    String apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.innerException}',
      );
      if (e.code == 404 || e.code == 400) {
        apiErrorMsg =
            'API Error creating comment: Task with ID "$resolvedTaskId" not found or invalid request (${e.code}).';
      } else {
        apiErrorMsg =
            'API Error creating comment for task "$resolvedTaskId" (${e.code}): ${e.message}';
      }
    }
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({
            'status': 'error',
            'message': apiErrorMsg,
            'taskId': resolvedTaskId,
          }),
        )
      ],
    );
  }
}
