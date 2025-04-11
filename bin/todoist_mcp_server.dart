import 'dart:async';
import 'dart:convert'; // For jsonEncode if needed for debugging args
import 'dart:io';

import 'package:flutter_memos/services/todoist_api_service.dart';
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;
import 'package:mcp_dart/mcp_dart.dart' as mcp_dart;

// Global instance of the service
final todoistService = TodoistApiService();

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
        tools: mcp_dart.ServerCapabilitiesTools(), // Indicate tool support
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
        'type': 'integer', // Use integer for schema, parse from string/int later
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
      // Add duration fields if needed
    },
    // Define required fields if using full JSON Schema validation (optional here)
    // required: ['content'], // Optional: Define required fields
    callback: _handleCreateTodoistTask, // Use a separate handler function
  );

  // Register the 'update_todoist_task' tool
  server.tool(
    'update_todoist_task',
    description: 'Updates an existing task in Todoist.',
    inputSchemaProperties: {
      'id': {
        // Task ID is required for updates
        'type': 'string',
        'description': 'The ID of the task to update (required).',
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
      // Add duration fields if needed
    },
    // Note: Field requirement is enforced within the handler function below.
    // The 'required' parameter is not part of the mcp_dart server.tool() signature.
    callback: _handleUpdateTodoistTask, // Use a separate handler function
  );

  // Register the 'get_todoist_tasks' tool
  server.tool(
    'get_todoist_tasks',
    description: '''
Retrieves a list of active Todoist tasks (including their IDs and content) based on filter criteria.
Use EITHER `filter` OR `content_contains`. `filter` takes precedence.

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
- Find tasks due today in the Work project: `filter: "today & #Work"`
- Find tasks created in the last 7 days: `filter: "created after: -7 days"`
- Find overdue priority 1 tasks OR tasks due today labeled @urgent: `filter: "(p1 & overdue) | (today & @urgent)"`
- Find tasks containing "report" but not in the Archive project: `filter: "search: report & !#Archive"`
- Find tasks without a due date: `filter: "no date"`
- Find tasks assigned to me: `filter: "assigned to: me"`
''',
    inputSchemaProperties: {
      'filter': {
        'type': 'string',
        'description':
            'Full Todoist filter query (e.g., "today & #Work", "p1", "search: keyword"). Takes precedence over content_contains. Optional.',
      },
      'content_contains': {
        'type': 'string',
        'description':
            'Search for tasks whose content includes this text (ignored if `filter` is provided). Optional.',
      },
      // Add other potential direct filter fields if desired (e.g., project_id, label)
      // 'project_id': {'type': 'string', 'description': 'Filter by project ID (optional).'},
      // 'label': {'type': 'string', 'description': 'Filter by label name (optional).'},
    },
    callback: _handleGetTodoistTasks, // Use a separate handler function
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
      '[TodoistServer] Registered tools: create_todoist_task, update_todoist_task, get_todoist_tasks',
    );
  } catch (e) {
    stderr.writeln('[TodoistServer] Failed to connect to transport: $e');
    exit(1);
  }
}


// Handler function for the 'update_todoist_task' tool
Future<mcp_dart.CallToolResult> _handleUpdateTodoistTask({
  Map<String, dynamic>? args,
  dynamic extra, // Not used here, but part of the signature
}) async {
  stderr.writeln('[TodoistServer] Received update_todoist_task request.');
  stderr.writeln(
    '[TodoistServer] Args: ${jsonEncode(args)}',
  ); // Log received args

  // 1. Retrieve API Token (existing code)
  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    const errorMsg =
        'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    // Return JSON error
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        ),
      ],
    );
  }

  // 2. Configure the Todoist Service (existing code)
  stderr.writeln(
    '[TodoistServer] Configuring TodoistApiService with provided token.',
  );
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
      const errorMsg =
          'Error: Todoist API health check failed with the provided token.';
      stderr.writeln('[TodoistServer] $errorMsg');
      // Return JSON error
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
    // Return JSON error
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        ),
      ],
    );
  }

  // 3. Parse Arguments - ID is required (existing code)
  final taskId = args?['id'] as String?;
  if (taskId == null || taskId.trim().isEmpty) {
    const errorMsg = 'Error: Task ID (`id`) is required for updates.';
    stderr.writeln('[TodoistServer] $errorMsg');
    // Return JSON error
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        ),
      ],
    );
  }

  // Parse optional arguments (existing code)
  final content = args?['content'] as String?;
  final description = args?['description'] as String?;
  final labels = (args?['labels'] as List<dynamic>?)?.cast<String>();
  final priorityStr =
      args?['priority']?.toString(); // Handle int or string input
  final dueString = args?['due_string'] as String?;
  final dueDate = args?['due_date'] as String?;
  final dueDatetime = args?['due_datetime'] as String?;
  final dueLang = args?['due_lang'] as String?;
  final assigneeId = args?['assignee_id'] as String?;

  // Construct Due object (existing code)
  todoist.TaskDue? due;
  // ... (existing due object construction logic) ...
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
        date:
            parsedDueDate ??
            DateTime.now(), // API might require date even if only string/datetime provided
        datetime: parsedDueDateTime,
        isRecurring:
            false, // Update logic might need to handle recurring tasks differently
        timezone: dueLang,
      ),
    );
  }


  // 4. Call Todoist API Update Method (existing code)
  try {
    stderr.writeln(
      '[TodoistServer] Calling todoistService.updateTask for ID: $taskId...',
    );
    await todoistService.updateTask(
      id: taskId, // Pass the required ID
      content: content, // Pass optional fields
      description: description,
      labelIds: labels,
      priority: priorityStr,
      due: due,
      // duration: duration, // Add if needed
      assigneeId: assigneeId,
    );

    final successMsg = 'Todoist task (ID: $taskId) updated successfully.';
    stderr.writeln('[TodoistServer] $successMsg');
    // Return JSON success
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
        'Error updating Todoist task (ID: $taskId): ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    String apiErrorMsg = errorMsg; // Default error message

    // Provide specific API error details if available (existing code)
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.innerException}',
      );
      apiErrorMsg =
          'API Error updating task (${e.code}): ${e.message}'; // More specific message
      // Decode body if possible (existing code)
      // ...
    }
    // Return JSON error
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


// Handler function for the 'get_todoist_tasks' tool
Future<mcp_dart.CallToolResult> _handleGetTodoistTasks({
  Map<String, dynamic>? args,
  dynamic extra,
}) async {
  stderr.writeln('[TodoistServer] Received get_todoist_tasks request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  // 1. Retrieve API Token
  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    const errorMsg =
        'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return const mcp_dart.CallToolResult(
      content: [mcp_dart.TextContent(text: errorMsg)],
    );
  }

  // 2. Configure Service & Health Check
  stderr.writeln('[TodoistServer] Configuring TodoistApiService...');
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
      const errorMsg = 'Error: Todoist API health check failed.';
      stderr.writeln('[TodoistServer] $errorMsg');
      return const mcp_dart.CallToolResult(
        content: [mcp_dart.TextContent(text: errorMsg)],
      );
    }
    stderr.writeln(
      '[TodoistServer] TodoistApiService configured and health check passed.',
    );
  } catch (e) {
    final errorMsg = 'Error configuring TodoistApiService: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [mcp_dart.TextContent(text: errorMsg)],
    );
  }

  // 3. Parse Arguments
  final filterArg = args?['filter'] as String?;
  final contentContainsArg = args?['content_contains'] as String?;
  // Parse other direct filter args if added to schema (e.g., projectId, label)

  // Determine the actual filter to use
  String? effectiveFilter;
  if (filterArg != null && filterArg.trim().isNotEmpty) {
    effectiveFilter = filterArg; // Use explicit filter if provided
    stderr.writeln('[TodoistServer] Using explicit filter: "$effectiveFilter"');
  } else if (contentContainsArg != null &&
      contentContainsArg.trim().isNotEmpty) {
    effectiveFilter = 'search: $contentContainsArg'; // Construct search filter
    stderr.writeln(
      '[TodoistServer] Using constructed filter from content_contains: "$effectiveFilter"',
    );
  } else {
    stderr.writeln(
      '[TodoistServer] No filter or content_contains provided. Fetching all active tasks.',
    );
  }


  // 4. Call Todoist API Service
  try {
    stderr.writeln(
      '[TodoistServer] Calling todoistService.getActiveTasks (using filter: $effectiveFilter)...',
    );
    final tasks = await todoistService.getActiveTasks(
      filter: effectiveFilter, // Pass the determined filter
      // Pass other parsed filters here if implemented
    );

    if (tasks.isEmpty) {
      stderr.writeln(
        '[TodoistServer] No active tasks found matching the criteria.',
      );
      return const mcp_dart.CallToolResult(
        content: [mcp_dart.TextContent(text: 'No active tasks found.')],
      );
    }

    // 5. Serialize Task Data for AI
    // Return a simplified list containing ID, content, and creation time.
    final tasksForAI =
        tasks
            .map(
              (task) => {
                'id': task.id,
                'content': task.content,
                'created_at':
                    task.createdAt != null
                        ? DateTime.parse(task.createdAt!).toIso8601String()
                        : null, // Add timestamp
                // Add other fields ONLY if absolutely necessary for the AI's core function
              },
            )
            .toList();

    final resultJson = jsonEncode(tasksForAI);
    stderr.writeln(
      '[TodoistServer] Found ${tasks.length} tasks. Returning JSON.',
    );
    // Optionally log the JSON if debugging, but can be large:
    // stderr.writeln('[TodoistServer] Result JSON: $resultJson');

    return mcp_dart.CallToolResult(
      content: [mcp_dart.TextContent(text: resultJson)],
    );
  } catch (e) {
    final errorMsg = 'Error getting Todoist tasks: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.innerException}',
      );
      // Decode body if possible
      return mcp_dart.CallToolResult(
        content: [
          mcp_dart.TextContent(text: 'API Error (${e.code}): ${e.message}'),
        ],
      );
    }
    return mcp_dart.CallToolResult(
      content: [mcp_dart.TextContent(text: errorMsg)],
    );
  }
}


// Handler function for the 'create_todoist_task' tool
Future<mcp_dart.CallToolResult> _handleCreateTodoistTask({
  Map<String, dynamic>? args,
  dynamic extra, // Not used here, but part of the signature
}) async {
  stderr.writeln('[TodoistServer] Received create_todoist_task request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}'); // Log received args

  // 1. Retrieve API Token (existing code)
  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    final errorMsg = 'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    // Return JSON error
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        ),
      ],
    );
  }

  // 2. Configure the Todoist Service (existing code)
  stderr.writeln('[TodoistServer] Configuring TodoistApiService with provided token.');
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
       final errorMsg = 'Error: Todoist API health check failed with the provided token.';
       stderr.writeln('[TodoistServer] $errorMsg');
      // Return JSON error
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
    // Return JSON error
     return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': errorMsg}),
        ),
      ],
     );
  }

  // 3. Parse Arguments (existing code)
  final content = args?['content'] as String?;
  if (content == null || content.trim().isEmpty) {
    const errorMsg = 'Error: Task content cannot be empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    // Return JSON error
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
  final priorityStr = args?['priority']?.toString(); // Handle int or string input
  final dueString = args?['due_string'] as String?;
  final dueDate = args?['due_date'] as String?;
  final dueDatetime = args?['due_datetime'] as String?;
  final dueLang = args?['due_lang'] as String?;
  final assigneeId = args?['assignee_id'] as String?;

  // Construct Due object (existing code)
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
        string: dueString ?? '', // API expects non-null string
        date: parsedDueDate ?? DateTime.now(), // API expects non-null date
        datetime: parsedDueDateTime,
        isRecurring: false, // Assume false unless explicitly passed
        timezone: dueLang, // Map lang to timezone if appropriate
      ),
    );
  }

  // 4. Call Todoist API (existing code)
  try {
    stderr.writeln('[TodoistServer] Calling todoistService.createTask...');
    final newTask = await todoistService.createTask(
      content: content,
      description: description,
      projectId: projectId,
      sectionId: sectionId,
      labelIds: labels,
      priority: priorityStr, // Pass string, service handles parsing
      due: due,
      // duration: duration, // Add if needed
      assigneeId: assigneeId,
    );

    final successMsg =
        'Todoist task created successfully: "${newTask.content}"';
    stderr.writeln('[TodoistServer] $successMsg (ID: ${newTask.id})');
    // Return JSON success
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({
            'status': 'success',
            'message': successMsg,
            'taskId': newTask.id, // Include the new task ID
          }),
        ),
      ],
    );
  } catch (e) {
    final errorMsg = 'Error creating Todoist task: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    String apiErrorMsg = errorMsg; // Default error message

    // Consider checking for specific API errors (existing code)
    if (e is todoist.ApiException) {
       stderr.writeln('[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.innerException}');
      apiErrorMsg =
          'API Error creating task (${e.code}): ${e.message}'; // More specific message
      // Try to decode body if available (existing code)
      // ...
    }
    // Return JSON error
    return mcp_dart.CallToolResult(
      content: [
        mcp_dart.TextContent(
          text: jsonEncode({'status': 'error', 'message': apiErrorMsg}),
        ),
      ],
    );
  }
}
