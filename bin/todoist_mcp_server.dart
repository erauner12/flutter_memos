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
        'description': 'Specific due date and time in RFC3339 UTC format (optional).',
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
    callback: _handleCreateTodoistTask,
  );

  // Register the 'update_todoist_task' tool with updated description and schema
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
    },
    callback: _handleUpdateTodoistTask,
  );

  // Register the 'get_todoist_tasks' tool with updated description and schema
  server.tool(
    'get_todoist_tasks',
    description: '''Retrieves active Todoist tasks based on criteria.
Use EITHER `task_id`, `filter`, OR `content_contains`. `task_id` takes precedence, then `filter`.

**Parameters:**
- `task_id`: Retrieve a specific task by its ID.
- `filter`: Use a full Todoist filter query (e.g., "today & #Work", "p1", "search: keyword"). See Filter Syntax Guide below.
- `content_contains`: Simple search for tasks containing specific text (ignored if `task_id` or `filter` is provided).

**Filter Syntax Guide:**
- **Dates:**
  - `due: date` (e.g., `due: today`, `due: tomorrow`, `due: May 5`, `due: next Monday`)
  - `due before: date` (e.g., `due before: next week`, `due before: +4 hours`)
  - `due after: date` (e.g., `due after: June 20`, `due after: in 3 days`)
  - `no date` or `no due date`: Tasks without a due date.
  - `overdue` or `od`: Tasks that are overdue.
  - `recurring`: Tasks with recurring due dates.
  - **IMPORTANT:** To find tasks *created* on a specific date, use `created: date` (e.g., `created: today`, `created: Jan 3`, `created before: -365 days`, `created after: -7 days`).
- **Priorities:**
  - `p1`, `p2`, `p3`: Filter by priority 1, 2, or 3.
  - `no priority`: Tasks with priority 4 (no specific priority set).
  - `!no priority`: Tasks with p1, p2, or p3.
- **Projects & Sections:**
  - `#ProjectName`: Tasks in a specific project (e.g., `#Work`).
  - `##ProjectName`: Tasks in a project and its sub-projects (e.g., `##Work`).
  - `/SectionName`: Tasks in a specific section across all projects (e.g., `/Meetings`).
  - `!/*`: Tasks not assigned to any section.
- **Labels:**
  - `@labelname`: Tasks with a specific label (e.g., `@waiting`, `@email`).
  - `no labels`: Tasks without any labels.
  - `!no labels`: Tasks that have at least one label.
- **Assignments:**
  - `assigned to: name or email` (e.g., `assigned to: John Doe`)
  - `assigned by: me`
  - `shared & !assigned`: Tasks in shared projects not assigned to anyone.
- **Structure:**
  - `subtask`: Show only sub-tasks.
  - `!subtask`: Show only parent tasks (tasks that are not sub-tasks).
- **Keywords:**
  - `search: keyword`: Find tasks containing the keyword (e.g., `search: email`). Use `content_contains` argument for simpler keyword searches.
- **Combining Queries:**
  - `&` (AND): e.g., `today & #Work`
  - `|` (OR): e.g., `@work | @office`
  - `!` (NOT): e.g., `today & !#Work`
  - `()` (Grouping): e.g., `(today | overdue) & #Work`
  - `,` (Multiple Sections): e.g., `p1 & overdue , p4 & today` (shows two separate lists in the result)

**Examples:**
- Find task with ID 12345: `task_id: "12345"`
- Find tasks due today in the Work project: `filter: "today & #Work"`
- Find tasks created in the last 7 days: `filter: "created after: -7 days"`
- Find overdue priority 1 tasks OR tasks due today labeled @urgent: `filter: "(p1 & overdue) | (today & @urgent)"`
- Find tasks containing "report" but not in the Archive project: `filter: "search: report & !#Archive"`
- Find tasks without a due date: `filter: "no date"`
- Find tasks assigned to me: `filter: "assigned to: me"`
''',
    inputSchemaProperties: {
      'task_id': {
        'type': 'string',
        'description': 'The specific ID of the task to retrieve. Takes precedence over filter/content_contains. Optional.',
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

  // Register the 'todoist_delete_task' tool
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

  // Register the 'todoist_complete_task' tool
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
      '[TodoistServer] Registered tools: create_todoist_task, update_todoist_task, get_todoist_tasks, delete_todoist_task, complete_todoist_task'
    );
  } catch (e) {
    stderr.writeln('[TodoistServer] Failed to connect to transport: $e');
    exit(1);
  }
}

// Handler function for the 'update_todoist_task' tool
Future<mcp_dart.CallToolResult> _handleUpdateTodoistTask({
  Map<String, dynamic>? args,
  dynamic extra,
}) async {
  stderr.writeln('[TodoistServer] Received update_todoist_task request.');
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
        ),
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
          ),
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
        ),
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
        ),
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
        ),
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
  dynamic extra,
}) async {
  stderr.writeln('[TodoistServer] Received get_todoist_tasks request.');
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
        ),
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
          ),
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
        ),
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
          ),
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
          ),
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
        ),
      ],
    );
  }
}

// Handler function for the 'delete_todoist_task' tool
Future<mcp_dart.CallToolResult> _handleDeleteTodoistTask({
  Map<String, dynamic>? args,
  dynamic extra,
}) async {
  stderr.writeln('[TodoistServer] Received delete_todoist_task request.');
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
        ),
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
          ),
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
        ),
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
        ),
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
        ),
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
        ),
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
        ),
      ],
    );
  }
}

// Handler function for the 'complete_todoist_task' tool
Future<mcp_dart.CallToolResult> _handleCompleteTodoistTask({
  Map<String, dynamic>? args,
  dynamic extra,
}) async {
  stderr.writeln('[TodoistServer] Received complete_todoist_task request.');
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
        ),
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
          ),
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
        ),
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
        ),
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
        ),
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
        ),
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
        ),
      ],
    );
  }
}

// Handler function for the 'create_todoist_task' tool
Future<mcp_dart.CallToolResult> _handleCreateTodoistTask({
  Map<String, dynamic>? args,
  dynamic extra,
}) async {
  stderr.writeln('[TodoistServer] Received create_todoist_task request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    final errorMsg = 'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        ),
      ],
    );
  }

  stderr.writeln('[TodoistServer] Configuring TodoistApiService with provided token.');
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
      final errorMsg =
          'Error: Todoist API health check failed with the provided token.';
      stderr.writeln('[TodoistServer] $errorMsg');
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(
            text: jsonEncode({'status': 'error', 'message': errorMsg}),
          ),
        ],
      );
    }
    stderr.writeln('[TodoistServer] TodoistApiService configured and health check passed.');
  } catch (e) {
    final errorMsg = 'Error configuring TodoistApiService: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        ),
      ],
    );
  }

  final content = args?['content'] as String?;
  if (content == null || content.trim().isEmpty) {
    const errorMsg = 'Error: Task content cannot be empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        ),
      ],
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
        'Todoist task created successfully: "${newTask.content}"';
    stderr.writeln('[TodoistServer] $successMsg (ID: ${newTask.id})');
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({
            'status': 'success',
            'message': successMsg,
            'taskId': newTask.id,
          }),
        )
      ],
    );
  } catch (e) {
    final errorMsg = 'Error creating Todoist task: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    String apiErrorMsg = errorMsg;
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.innerException}',
      );
      apiErrorMsg = 'API Error creating task (${e.code}): ${e.message}';
    }
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': apiErrorMsg}),
        ),
      ],
    );
  }
}
