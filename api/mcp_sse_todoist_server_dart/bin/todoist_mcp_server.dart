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

/// Finds a single active Todoist task by its content (case-insensitive contains).
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
        '[TodoistServer] Error during _findTaskByName("$taskName"): $e');
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
    }
    return null;
  }
}

/// Finds a single active Todoist task by ID (if provided) or name content.
/// ID takes precedence. Returns null if not found or on error.
Future<todoist.Task?> _findTaskByIdOrName(
  todoist.ApiClient client, {
  String? taskId,
  String? taskName,
}) async {
  final tasksApi = todoist.TasksApi(client);

  // 1. Try by ID first
  if (taskId != null && taskId.isNotEmpty) {
    stderr.writeln('[TodoistServer] Searching for task by ID: "$taskId"');
    try {
      final intId = int.tryParse(taskId);
      if (intId == null) {
        stderr.writeln(
            '[TodoistServer] Invalid task ID format: "$taskId". Must be an integer.');
        return null;
      }
      final task = await tasksApi.getActiveTask(intId);
      if (task != null) {
        stderr.writeln(
            '[TodoistServer] Found task by ID "$taskId": Content "${task.content}"');
        return task;
      } else {
        stderr.writeln('[TodoistServer] No task found with ID "$taskId".');
      }
    } catch (e) {
      stderr.writeln('[TodoistServer] Error fetching task by ID "$taskId": $e');
      if (e is todoist.ApiException && e.code == 404) {
        stderr.writeln('[TodoistServer] Task ID "$taskId" not found (404).');
      } else if (e is todoist.ApiException) {
        stderr.writeln(
            '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
        return null;
      } else {
        return null;
      }
    }
  }

  // 2. Try by Name if ID search failed or wasn't provided
  if (taskName != null && taskName.trim().isNotEmpty) {
    return await _findTaskByName(client, taskName);
  }

  stderr.writeln(
      '[TodoistServer] Could not find task: No valid ID or name provided, or search failed.');
  return null;
}

// ADD: Helper function to find a personal label by name
/// Finds a single personal label by its name (case-insensitive exact match).
Future<todoist.Label?> _findLabelByName(
  todoist.ApiClient client,
  String labelName,
) async {
  if (labelName.trim().isEmpty) {
    stderr.writeln('[TodoistServer] _findLabelByName called with empty name.');
    return null;
  }
  stderr.writeln(
      '[TodoistServer] Searching for label exactly matching: "$labelName"');
  try {
    final labelsApi = todoist.LabelsApi(client);
    final allLabels = await labelsApi.getAllPersonalLabels();
    if (allLabels == null) {
      stderr.writeln('[TodoistServer] Received null label list from API.');
      return null;
    }

    // Fix: Don't use orElse to return null, use try/catch instead
    try {
      final match = allLabels.firstWhere(
        (label) => label.name?.toLowerCase() == labelName.toLowerCase(),
      );
      stderr.writeln(
          '[TodoistServer] Found label matching "$labelName": ID ${match.id}');
      return match;
    } catch (e) {
      // This catches the StateError thrown when no element is found
      stderr.writeln('[TodoistServer] No label found matching "$labelName".');
      return null;
    }
  } catch (e) {
    stderr.writeln(
        '[TodoistServer] Error during _findLabelByName("$labelName"): $e');
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
    }
    return null;
  }
}

// ADD: Helper function to find a personal label by ID or name
/// Finds a single personal label by ID (if provided) or name.
/// ID takes precedence. Returns null if not found or on error.
Future<todoist.Label?> _findLabelByIdOrName(
  todoist.ApiClient client, {
  String? labelId,
  String? labelName,
}) async {
  final labelsApi = todoist.LabelsApi(client);

  // 1. Try by ID first
  if (labelId != null && labelId.isNotEmpty) {
    stderr.writeln('[TodoistServer] Searching for label by ID: "$labelId"');
    try {
      final intId = int.tryParse(labelId);
      if (intId == null) {
        stderr.writeln(
            '[TodoistServer] Invalid label ID format: "$labelId". Must be an integer.');
        return null;
      }
      final label = await labelsApi.getPersonalLabel(intId);
      if (label != null) {
        stderr.writeln(
            '[TodoistServer] Found label by ID "$labelId": Name "${label.name}"');
        return label;
      } else {
        stderr.writeln('[TodoistServer] No label found with ID "$labelId".');
      }
    } catch (e) {
      stderr
          .writeln('[TodoistServer] Error fetching label by ID "$labelId": $e');
      if (e is todoist.ApiException && e.code == 404) {
        stderr.writeln('[TodoistServer] Label ID "$labelId" not found (404).');
      } else if (e is todoist.ApiException) {
        stderr.writeln(
            '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
        return null;
      } else {
        return null;
      }
    }
  }

  // 2. Try by Name if ID search failed or wasn't provided
  if (labelName != null && labelName.trim().isNotEmpty) {
    return await _findLabelByName(client, labelName);
  }

  stderr.writeln(
      '[TodoistServer] Could not find label: No valid ID or name provided, or search failed.');
  return null;
}


// --- Generic Result Helpers ---

mcp_dart.CallToolResult _createErrorResult(String message,
    {Map<String, dynamic>? errorData}) {
  final payload = {
    'status': 'error',
    'message': message,
    'result': errorData ?? {},
  };
  stderr
      .writeln('[TodoistServer] Creating Error Result: ${jsonEncode(payload)}');
  return mcp_dart.CallToolResult(
    content: [mcp_dart.TextContent(text: jsonEncode(payload))],
    isError: true,
  );
}

mcp_dart.CallToolResult _createSuccessResult(String message,
    {Map<String, dynamic>? resultData}) {
  final payload = {
    'status': 'success',
    'message': message,
    'result': resultData ?? {},
  };
  stderr.writeln(
      '[TodoistServer] Creating Success Result: ${jsonEncode(payload)}');
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
      '[TodoistServer] Warning: Invalid --transport value "$transportArg". Defaulting to stdio.',
    );
  }
  stderr.writeln('[TodoistServer] Starting in ${transportMode.name} mode...');

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

  // 2. Register Tools

  // Change 1: Removed _checkApiHealth function (done above)

  // Change 2: Update create_todoist_task tool registration and add get_todoist_tasks tool
  server.tool(
    'create_todoist_task',
    description:
        'Creates one or more tasks in Todoist. Returns the created task details.',
    inputSchemaProperties: {
      'tasks': {
        'type': 'array',
        'description': 'Array of tasks to create (for batch operations)',
        'items': {
          'type': 'object',
          'properties': {
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
            'parent_id': {
              'type': 'string',
              'description': 'ID of the parent task for subtasks (optional).',
            },
            'order': {
              'type': 'integer',
              'description':
                  'Position in the project or parent task (optional).',
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
              'enum': [1, 2, 3, 4],
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
              'description':
                  '2-letter language code for deadline parsing (optional)',
            },
            'assignee_id': {
              'type': 'string',
              'description': 'ID of the user to assign the task to (optional).',
            },
            'duration': {
              'type': 'integer',
              'description':
                  'A positive integer for the task duration. Requires duration_unit.',
            },
            'duration_unit': {
              'type': 'string',
              'description':
                  "The unit for the duration ('minute' or 'day'). Requires duration.",
              'enum': ['minute', 'day'],
            },
            'deadline_date': {
              'type': 'string',
              'description': 'Deadline date in YYYY-MM-DD format (optional)',
            },
            'deadline_lang': {
              'type': 'string',
              'description':
                  '2-letter language code for deadline parsing (optional)',
            }
          },
          'required': ['content'],
        },
      },
      'content': {
        'type': 'string',
        'description':
            'The content of the task (required if "tasks" array is not provided).',
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
      'parent_id': {
        'type': 'string',
        'description': 'ID of the parent task for subtasks (optional).',
      },
      'order': {
        'type': 'integer',
        'description': 'Position in the project or parent task (optional).',
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
        'enum': [1, 2, 3, 4],
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
            'A positive integer for the task duration. Requires duration_unit.',
      },
      'duration_unit': {
        'type': 'string',
        'description':
            "The unit for the duration ('minute' or 'day'). Requires duration.",
        'enum': ['minute', 'day'],
      },
      'deadline_date': {
        'type': 'string',
        'description': 'Deadline date in YYYY-MM-DD format (optional)',
      },
      'deadline_lang': {
        'type': 'string',
        'description': '2-letter language code for deadline parsing (optional)',
      }
    },
    callback: _handleCreateTodoistTask, // Use the correct handler
  );

  // ADD: Register update_todoist_task tool
  server.tool(
    'update_todoist_task',
    description:
        'Updates one or more existing tasks in Todoist. Requires either task_id or task_name for identification. Returns the updated task details.',
    inputSchemaProperties: {
      'tasks': {
        'type': 'array',
        'description': 'Array of tasks to update (for batch operations)',
        'items': {
          'type': 'object',
          'properties': {
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
              'description':
                  'New detailed description for the task (optional).',
            },
            'labels': {
              'type': 'array',
              'description': 'New list of label names to attach (optional).',
              'items': {'type': 'string'},
            },
            'priority': {
              'type': 'integer',
              'description':
                  'New task priority from 1 (normal) to 4 (urgent) (optional).',
              'enum': [1, 2, 3, 4],
            },
            'due_string': {
              'type': 'string',
              'description': 'New human-readable due date (optional).',
            },
            'due_date': {
              'type': 'string',
              'description':
                  'New specific due date in YYYY-MM-DD format (optional).',
            },
            'due_datetime': {
              'type': 'string',
              'description':
                  'New specific due date/time in RFC3339 UTC format (optional).',
            },
            'due_lang': {
              'type': 'string',
              'description':
                  'Language code if due_string is not English (optional).',
            },
            'assignee_id': {
              'type': 'string',
              'description':
                  'New ID of the user to assign the task to (optional).',
            },
            'duration': {
              'type': 'integer',
              'description':
                  'A positive integer for the new task duration. Requires duration_unit.',
            },
            'duration_unit': {
              'type': 'string',
              'description':
                  "The unit for the new duration ('minute' or 'day'). Requires duration.",
              'enum': ['minute', 'day'],
            },
          },
          'required': [],
        },
      },
      'task_id': {
        'type': 'string',
        'description':
            'The specific ID of the task to update (optional, takes precedence over task_name).',
      },
      'task_name': {
        'type': 'string',
        'description':
            'The name/content of the task to search for and update (required if task_id is not provided and "tasks" array is not used).',
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
        'description': 'New list of label names to attach (optional).',
        'items': {'type': 'string'},
      },
      'priority': {
        'type': 'integer',
        'description':
            'New task priority from 1 (normal) to 4 (urgent) (optional).',
        'enum': [1, 2, 3, 4],
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
        'description': 'Language code if due_string is not English (optional).',
      },
      'assignee_id': {
        'type': 'string',
        'description': 'New ID of the user to assign the task to (optional).',
      },
      'duration': {
        'type': 'integer',
        'description':
            'A positive integer for the new task duration. Requires duration_unit.',
      },
      'duration_unit': {
        'type': 'string',
        'description':
            "The unit for the new duration ('minute' or 'day'). Requires duration.",
        'enum': ['minute', 'day'],
      },
    },
    callback: _handleUpdateTodoistTask, // Assign the handler
  );

  // ADD: Register get_todoist_tasks tool
  server.tool(
    'get_todoist_tasks',
    description:
        'Retrieves active Todoist tasks based on filters or IDs. Returns a list of tasks.',
    inputSchemaProperties: {
      'ids': {
        'type': 'array',
        'description': 'An array of specific task IDs to retrieve (optional).',
        'items': {'type': 'string'}
      },
      'filter': {
        'type': 'string',
        'description':
            'A Todoist filter query string (optional). See Todoist documentation for syntax.',
      },
      'project_id': {
        'type': 'string',
        'description': 'Filter tasks by project ID (optional).',
      },
      'section_id': {
        'type': 'string',
        'description': 'Filter tasks by section ID (optional).',
      },
      'label': {
        'type': 'string',
        'description': 'Filter tasks by label name (optional).',
      },
      'lang': {
        'type': 'string',
        'description':
            'Language code for filter parsing if not English (optional).',
      },
      'priority': {
        'type': 'integer',
        'description':
            'Filter tasks by priority (1-4) (optional, applied client-side if no filter string provided).',
        'enum': [1, 2, 3, 4],
      },
      'limit': {
        'type': 'integer',
        'description':
            'Maximum number of tasks to return (optional, applied client-side).',
      },
      'content_contains': {
        'type': 'string',
        'description':
            'Filter tasks where content contains this string (case-insensitive, optional, added to filter string).',
      },
    },
    callback: _handleGetTodoistTasks, // Assign the handler
  );

  // Change 1: Register todoist_create_project tool (dummy registration removed here)
  server.tool(
    'todoist_create_project',
    description: 'Creates a new project in Todoist.',
    inputSchemaProperties: {
      'name': {
        'type': 'string',
        'description': 'Name of the project (required).'
      },
      'parent_id': {
        'type': 'string',
        'description': 'Parent project ID (optional).'
      },
      'color': {
        'type': 'string',
        'description': 'Color ID or name (optional).'
      },
      'is_favorite': {
        'type': 'boolean',
        'description': 'Whether the project is a favorite (optional).'
      },
      'view_style': {
        'type': 'string',
        'description': 'Project view style ("list" or "board") (optional).',
        'enum': ['list', 'board']
      }
    },
    callback: _handleCreateProject,
  );

  // Change 2: Register todoist_update_project tool
  server.tool(
    'todoist_update_project',
    description: 'Updates an existing project in Todoist.',
    inputSchemaProperties: {
      'project_id': {
        'type': 'string',
        'description': 'ID of the project to update (required).'
      },
      'name': {
        'type': 'string',
        'description': 'New name for the project (optional).'
      },
      'color': {
        'type': 'string',
        'description': 'New color ID or name (optional).'
      },
      'is_favorite': {
        'type': 'boolean',
        'description': 'New favorite status (optional).'
      },
      'view_style': {
        'type': 'string',
        'description': 'New project view style ("list" or "board") (optional).',
        'enum': ['list', 'board']
      }
    },
    callback: _handleUpdateProject,
  );

  // Change 3: Register todoist_get_project_sections tool and todoist_create_project_section tool
  server.tool(
    'todoist_get_project_sections',
    description: 'Retrieves all sections for a given project.',
    inputSchemaProperties: {
      'project_id': {
        'type': 'string',
        'description': 'ID of the project to get sections for (required).'
      }
    },
    callback: _handleGetProjectSections,
  );

  server.tool(
    'todoist_create_project_section',
    description: 'Creates a new section within a project.',
    inputSchemaProperties: {
      'project_id': {
        'type': 'string',
        'description': 'ID of the project to add the section to (required).'
      },
      'name': {
        'type': 'string',
        'description': 'Name of the section (required).'
      },
      'order': {
        'type': 'integer',
        'description': 'Order of the section within the project (optional).'
      }
    },
    callback: _handleCreateProjectSection,
  );

  // Change 4: Register 'todoist_delete_task'
  server.tool(
    'todoist_delete_task',
    description:
        'Deletes one or more tasks from Todoist. Requires either task_id or task_name for each task. task_id takes precedence. Returns the deleted task IDs.',
    inputSchemaProperties: {
      'tasks': {
        'type': 'array',
        'description': 'Array of tasks to delete (for batch operations)',
        'items': {
          'type': 'object',
          'properties': {
            'task_id': {
              'type': 'string',
              'description':
                  'The specific ID of the task to delete (optional, takes precedence over task_name).',
            },
            'task_name': {
              'type': 'string',
              'description':
                  'The name/content of the task to search for and delete (required if task_id is not provided).',
            }
          }
        },
      },
      'task_id': {
        'type': 'string',
        'description':
            'The specific ID of the task to delete (optional, takes precedence over task_name).',
      },
      'task_name': {
        'type': 'string',
        'description':
            'The name/content of the task to search for and delete (required if task_id is not provided and "tasks" array is not used).',
      },
    },
    callback: _handleDeleteTodoistTask,
  );

  server.tool(
    'todoist_complete_task',
    description:
        'Marks one or more tasks as complete in Todoist. Requires either task_id or task_name for each task. task_id takes precedence. Returns the completed task IDs.',
    inputSchemaProperties: {
      'tasks': {
        'type': 'array',
        'description':
            'Array of tasks to mark as complete (for batch operations).',
        'items': {
          'type': 'object',
          'properties': {
            'task_id': {
              'type': 'string',
              'description':
                  'The specific ID of the task to complete (optional, takes precedence over task_name).',
            },
            'task_name': {
              'type': 'string',
              'description':
                  'The name/content of the task to search for and complete (required if task_id is not provided).',
            }
          }
        },
      },
      'task_id': {
        'type': 'string',
        'description':
            'The specific ID of the task to complete (optional, takes precedence over task_name).',
      },
      'task_name': {
        'type': 'string',
        'description':
            'The name/content of the task to search for and complete (required if task_id is not provided and "tasks" array is not used).',
      },
    },
    callback: handleCompleteTodoistTask,
  );

  // Change 3 continued: ADD: Register todoist_get_projects tool
  server.tool(
    'todoist_get_projects',
    description: 'Get all projects from Todoist.',
    inputSchemaProperties: {},
    callback: _handleGetProjects,
  );

  // ADD: Register personal label tools
  server.tool(
    'todoist_create_personal_label',
    description: 'Creates a new personal label in Todoist.',
    inputSchemaProperties: {
      'name': {
        'type': 'string',
        'description': 'Name of the label (required).'
      },
      'order': {
        'type': 'integer',
        'description': 'Label order in the list (optional).'
      },
      'color': {
        'type': 'string',
        'description': 'Color ID or name (optional).'
      },
      'is_favorite': {
        'type': 'boolean',
        'description': 'Whether the label is a favorite (optional).'
      }
    },
    callback: _handleCreatePersonalLabel,
  );

  server.tool(
    'todoist_get_personal_label',
    description: 'Retrieves a specific personal label by its ID.',
    inputSchemaProperties: {
      'label_id': {
        'type': 'string',
        'description': 'ID of the label to retrieve (required).'
      }
    },
    callback: _handleGetPersonalLabel,
  );

  server.tool(
    'todoist_update_personal_label',
    description:
        'Updates an existing personal label in Todoist. Requires label_id or label_name.',
    inputSchemaProperties: {
      'label_id': {
        'type': 'string',
        'description':
            'ID of the label to update (optional, takes precedence over label_name).'
      },
      'label_name': {
        'type': 'string',
        'description':
            'Name of the label to find and update (required if label_id is not provided).'
      },
      'name': {
        'type': 'string',
        'description': 'New name for the label (optional).'
      },
      'order': {
        'type': 'integer',
        'description': 'New label order (optional).'
      },
      'color': {
        'type': 'string',
        'description': 'New color ID or name (optional).'
      },
      'is_favorite': {
        'type': 'boolean',
        'description': 'New favorite status (optional).'
      }
    },
    callback: _handleUpdatePersonalLabel,
  );

  server.tool(
    'todoist_delete_personal_label',
    description: 'Deletes a personal label by its ID.',
    inputSchemaProperties: {
      'label_id': {
        'type': 'string',
        'description': 'ID of the label to delete (required).'
      }
    },
    callback: _handleDeletePersonalLabel,
  );

  // Change 2: Update the list of registered tools in the stderr log message
  stderr.writeln(
      '[TodoistServer] Registered tools: create_todoist_task, update_todoist_task, get_todoist_tasks, todoist_delete_task, todoist_complete_task, todoist_get_projects, todoist_create_project, todoist_update_project, todoist_get_project_sections, todoist_create_project_section, todoist_create_personal_label, todoist_get_personal_label, todoist_update_personal_label, todoist_delete_personal_label'
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
      stderr
          .writeln('[TodoistServer][stdio] Failed to connect to transport: $e');
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
            "[TodoistServer][sse] Closing ${sseManager.activeSseTransports.length} active SSE transports...");
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
      httpServer.idleTimeout = null;
      stderr.writeln(
          '[TodoistServer][sse] Explicitly set HttpServer.idleTimeout to null.');
      stderr.writeln(
          '[TodoistServer][sse] Serving MCP over SSE (GET ${sseManager.ssePath}) and HTTP (POST ${sseManager.messagePath}) at http://${httpServer.address.host}:${httpServer.port}');
      httpServer.listen(
        (HttpRequest request) {
          stderr.writeln(
              '[TodoistServer][sse] Request: ${request.method} ${request.uri}');
          sseManager.handleRequest(request).catchError((e, s) {
            stderr.writeln(
                '[TodoistServer][sse] Error handling request ${request.uri}: $e\n$s');
            try {
              if (request.response.connectionInfo != null) {
                request.response.statusCode = HttpStatus.internalServerError;
                request.response.write('Internal Server Error');
                request.response.close();
              }
            } catch (_) {
              stderr.writeln(
                  '[TodoistServer][sse] Could not send error response for ${request.uri}. Connection likely closed.');
            }
          });
        },
        onError: (e, s) =>
            stderr.writeln('[TodoistServer][sse] HttpServer error: $e\n$s'),
        onDone: () => stderr.writeln('[TodoistServer][sse] HttpServer closed.'),
      );
      stderr.writeln("[TodoistServer][sse] Signal handlers registered.");
    } catch (e) {
      stderr.writeln(
          '[TodoistServer][sse] FATAL: Failed to bind server to port $port: $e');
      exit(1);
    }
  }
}

// --- Tool Handlers (Refactored & New Stubs) ---

Future<mcp_dart.CallToolResult> _handleCreateTodoistTask({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received create_todoist_task request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }

  final tasksApi = todoist.TasksApi(apiClient);

  try {
    if (args != null && args.containsKey('tasks') && args['tasks'] is List) {
      final tasksList = (args['tasks'] as List).cast<Map<String, dynamic>>();
      stderr.writeln(
          '[TodoistServer] Processing batch task creation for ${tasksList.length} tasks.');
      final results = <Map<String, dynamic>>[];
      int successCount = 0;

      for (final taskData in tasksList) {
        try {
          final contentText = taskData['content'] as String?;
          if (contentText == null || contentText.trim().isEmpty) {
            results.add({
              'success': false,
              'error': 'Task content cannot be empty.',
              'taskData': taskData
            });
            continue;
          }
          final request = todoist.CreateTaskRequest(
            content: contentText,
            description: taskData['description'] as String?,
            projectId: taskData['project_id'] as String?,
            sectionId: taskData['section_id'] as String?,
            parentId: taskData['parent_id'] as String?,
            order: taskData['order'] as int?,
            labels:
                (taskData['labels'] as List<dynamic>?)?.cast<String>() ?? [],
            priority: taskData['priority'] as int?,
            dueString: taskData['due_string'] as String?,
            dueDate: taskData['due_date'] as String?,
            dueDatetime: taskData['due_datetime'] as String?,
            dueLang: taskData['due_lang'] as String?,
            assigneeId: taskData['assignee_id'] as String?,
            duration: taskData['duration'] as int?,
            durationUnit: taskData['duration_unit'] as String?,
          );
          final newTask = await tasksApi.createTask(request);
          if (newTask != null) {
            results.add({
              'success': true,
              'taskId': newTask.id,
              'content': newTask.content
            });
            successCount++;
          } else {
            results.add({
              'success': false,
              'error': 'API returned null task.',
              'taskData': taskData
            });
          }
        } catch (e) {
          stderr.writeln('[TodoistServer] Error creating batch task: $e');
          String errorMsg = e.toString();
          if (e is todoist.ApiException) {
            errorMsg = 'API Error (${e.code}): ${e.message ?? "Unknown"}';
          }
          results
              .add({'success': false, 'error': errorMsg, 'taskData': taskData});
        }
      }

      final summary = {
        'total': tasksList.length,
        'succeeded': successCount,
        'failed': tasksList.length - successCount,
      };
      final overallSuccess = successCount == tasksList.length;
      final message = overallSuccess
          ? 'Successfully created ${tasksList.length} tasks.'
          : 'Completed batch task creation with $successCount successes and ${tasksList.length - successCount} failures.';

      return _createSuccessResult(message,
          resultData: {'summary': summary, 'results': results});
    } else if (args != null && args.containsKey('content')) {
      final contentText = args['content'] as String?;
      if (contentText == null || contentText.trim().isEmpty) {
        return _createErrorResult('Task content cannot be empty.');
      }
      stderr.writeln('[TodoistServer] Processing single task creation.');
      final request = todoist.CreateTaskRequest(
        content: contentText,
        description: args['description'] as String?,
        projectId: args['project_id'] as String?,
        sectionId: args['section_id'] as String?,
        parentId: args['parent_id'] as String?,
        order: args['order'] as int?,
        labels: (args['labels'] as List<dynamic>?)?.cast<String>() ?? [],
        priority: args['priority'] as int?,
        dueString: args['due_string'] as String?,
        dueDate: args['due_date'] as String?,
        dueDatetime: args['due_datetime'] as String?,
        dueLang: args['due_lang'] as String?,
        assigneeId: args['assignee_id'] as String?,
        duration: args['duration'] as int?,
        durationUnit: args['duration_unit'] as String?,
      );

      final newTask = await tasksApi.createTask(request);
      if (newTask == null) {
        return _createErrorResult(
            'API returned null for the newly created task.');
      }

      final successMsg =
          'Todoist task created successfully: "${newTask.content}"';
      stderr.writeln('[TodoistServer] $successMsg (ID: ${newTask.id})');
      return _createSuccessResult(
        successMsg,
        resultData: {
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
    } else {
      return _createErrorResult(
          'Invalid arguments: Missing "content" for single task or "tasks" array for batch.');
    }
  } catch (e) {
    var apiErrorMsg = 'Error creating Todoist task: ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      apiErrorMsg =
          'API Error creating task (${e.code}): ${e.message ?? "Unknown API error"}';
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
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final tasksApi = todoist.TasksApi(apiClient);

  try {
    if (args != null && args.containsKey('tasks') && args['tasks'] is List) {
      final tasksList = (args['tasks'] as List).cast<Map<String, dynamic>>();
      stderr.writeln(
          '[TodoistServer] Processing batch task update for ${tasksList.length} tasks.');
      final results = <Map<String, dynamic>>[];
      int successCount = 0;

      for (final taskData in tasksList) {
        try {
          final taskIdArg = taskData['task_id'] as String?;
          final taskNameArg = taskData['task_name'] as String?;

          final targetTask = await _findTaskByIdOrName(apiClient,
              taskId: taskIdArg, taskName: taskNameArg);

          if (targetTask == null || targetTask.id == null) {
            results.add({
              'success': false,
              'error': 'Target task not found using provided ID/Name.',
              'taskData': taskData
            });
            continue;
          }

          final taskIdStr = targetTask.id!;

          final request = todoist.UpdateTaskRequest(
            content: taskData['content'] as String?,
            description: taskData['description'] as String?,
            labels:
                (taskData['labels'] as List<dynamic>?)?.cast<String>() ?? [],
            priority: taskData['priority'] as int?,
            dueString: taskData['due_string'] as String?,
            dueDate: taskData['due_date'] as String?,
            dueDatetime: taskData['due_datetime'] as String?,
            dueLang: taskData['due_lang'] as String?,
            assigneeId: taskData['assignee_id'] as String?,
            duration: taskData['duration'] as int?,
            durationUnit: taskData['duration_unit'] as String?,
          );

          if (request.content == null &&
              request.description == null &&
              request.labels.isEmpty &&
              request.priority == null &&
              request.dueString == null &&
              request.dueDate == null &&
              request.dueDatetime == null &&
              request.dueLang == null &&
              request.assigneeId == null &&
              request.duration == null &&
              request.durationUnit == null) {
            results.add({
              'success': false,
              'error': 'No update parameters provided for task ID $taskIdStr.',
              'taskData': taskData
            });
            continue;
          }

          await tasksApi.updateTask(taskIdStr, request);
          final updatedTask =
              await tasksApi.getActiveTask(int.parse(taskIdStr));

          results.add({
            'success': true,
            'taskId': taskIdStr,
            'originalContent': targetTask.content,
            'updatedContent':
                updatedTask?.content ?? request.content ?? targetTask.content,
          });
          successCount++;
        } catch (e) {
          stderr.writeln('[TodoistServer] Error updating batch task: $e');
          String errorMsg = e.toString();
          if (e is todoist.ApiException) {
            errorMsg = 'API Error (${e.code}): ${e.message ?? "Unknown"}';
          }
          results
              .add({'success': false, 'error': errorMsg, 'taskData': taskData});
        }
      }

      final summary = {
        'total': tasksList.length,
        'succeeded': successCount,
        'failed': tasksList.length - successCount,
      };
      final overallSuccess = successCount == tasksList.length;
      final message = overallSuccess
          ? 'Successfully updated ${tasksList.length} tasks.'
          : 'Completed batch task update with $successCount successes and ${tasksList.length - successCount} failures.';

      return _createSuccessResult(message,
          resultData: {'summary': summary, 'results': results});
    } else if (args != null &&
        (args.containsKey('task_id') || args.containsKey('task_name'))) {
      final taskIdArg = args['task_id'] as String?;
      final taskNameArg = args['task_name'] as String?;

      stderr.writeln('[TodoistServer] Processing single task update.');
      final targetTask = await _findTaskByIdOrName(apiClient,
          taskId: taskIdArg, taskName: taskNameArg);

      if (targetTask == null || targetTask.id == null) {
        return _createErrorResult(
            'Target task not found using provided ID/Name.');
      }

      final taskIdStr = targetTask.id!;

      final request = todoist.UpdateTaskRequest(
        content: args['content'] as String?,
        description: args['description'] as String?,
        labels: (args['labels'] as List<dynamic>?)?.cast<String>() ?? [],
        priority: args['priority'] as int?,
        dueString: args['due_string'] as String?,
        dueDate: args['due_date'] as String?,
        dueDatetime: args['due_datetime'] as String?,
        dueLang: args['due_lang'] as String?,
        assigneeId: args['assignee_id'] as String?,
        duration: args['duration'] as int?,
        durationUnit: args['duration_unit'] as String?,
      );

      if (request.content == null &&
          request.description == null &&
          request.priority == null &&
          request.dueString == null &&
          request.dueDate == null &&
          request.dueDatetime == null &&
          request.dueLang == null &&
          request.assigneeId == null &&
          request.duration == null &&
          request.durationUnit == null) {
        return _createErrorResult(
            'No update parameters provided for task ID $taskIdStr.');
      }

      await tasksApi.updateTask(taskIdStr, request);
      final updatedTask = await tasksApi.getActiveTask(int.parse(taskIdStr));

      if (updatedTask == null) {
        return _createErrorResult(
            'Task updated, but failed to re-fetch details for ID $taskIdStr.');
      }

      final successMsg =
          'Todoist task "${updatedTask.content}" (ID: $taskIdStr) updated successfully.';
      stderr.writeln('[TodoistServer] $successMsg');
      return _createSuccessResult(
        successMsg,
        resultData: {
          'task': {
            'id': updatedTask.id,
            'content': updatedTask.content,
            'description': updatedTask.description,
            'priority': updatedTask.priority,
            'due_string': updatedTask.due?.dueObject?.string,
            'due_date': updatedTask.due?.dueObject?.date,
            'due_datetime': updatedTask.due?.dueObject?.datetime,
            'labels': updatedTask.labels,
            'project_id': updatedTask.projectId,
            'updated_at': DateTime.now().toIso8601String(),
          }
        },
      );
    } else {
      return _createErrorResult(
          'Invalid arguments: Missing "task_id" or "task_name" for single task, or "tasks" array for batch.');
    }
  } catch (e) {
    var apiErrorMsg = 'Error updating Todoist task(s): ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      apiErrorMsg =
          'API Error updating task(s) (${e.code}): ${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> _handleGetTodoistTasks({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received get_todoist_tasks request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final tasksApi = todoist.TasksApi(apiClient);

  try {
    List<todoist.Task> fetchedTasks = [];
    final taskIdsArg = (args?['ids'] as List<dynamic>?)?.cast<String>();
    final filterArg = args?['filter'] as String?;
    final projectIdArg = args?['project_id'] as String?;
    final sectionIdArg = args?['section_id'] as String?;
    final labelArg = args?['label'] as String?;
    final langArg = args?['lang'] as String?;
    final priorityArg = args?['priority'] as int?;
    final limitArg = args?['limit'] as int?;
    final contentContainsArg = args?['content_contains'] as String?;

    if (taskIdsArg != null && taskIdsArg.isNotEmpty) {
      stderr.writeln(
          '[TodoistServer] Fetching tasks by specific IDs: $taskIdsArg');
      for (final idStr in taskIdsArg) {
        try {
          final intId = int.parse(idStr);
          final task = await tasksApi.getActiveTask(intId);
          if (task != null) {
            fetchedTasks.add(task);
          } else {
            stderr.writeln(
                '[TodoistServer] Warning: Task ID $intId not found or inactive.');
          }
        } catch (e) {
          stderr.writeln(
              '[TodoistServer] Warning: Error fetching task ID $idStr: $e');
        }
      }
    } else {
      String effectiveFilter = filterArg ?? '';
      if (effectiveFilter.isEmpty) {
        List<String> filterParts = [];
        if (projectIdArg != null) filterParts.add('#"$projectIdArg"');
        if (sectionIdArg != null) filterParts.add('/"$sectionIdArg"');
        if (labelArg != null) filterParts.add('@"$labelArg"');
        if (contentContainsArg != null) {
          filterParts.add('search: "$contentContainsArg"');
        }
        if (priorityArg != null && priorityArg >= 1 && priorityArg <= 4) {
          filterParts.add('p$priorityArg');
        }
        effectiveFilter = filterParts.join(' & ');
      }

      stderr.writeln(
          '[TodoistServer] Fetching tasks with filter: "$effectiveFilter"');
      final tasks = await tasksApi.getActiveTasks(
        projectId: projectIdArg,
        sectionId: sectionIdArg,
        label: labelArg,
        filter: effectiveFilter.isNotEmpty ? effectiveFilter : null,
        lang: langArg,
      );
      fetchedTasks = tasks ?? [];
    }

    if (filterArg == null && priorityArg != null && fetchedTasks.isNotEmpty) {
      stderr.writeln(
          '[TodoistServer] Applying client-side priority filter: p$priorityArg');
      fetchedTasks =
          fetchedTasks.where((task) => task.priority == priorityArg).toList();
    }

    if (limitArg != null && limitArg > 0 && limitArg < fetchedTasks.length) {
      stderr.writeln('[TodoistServer] Applying client-side limit: $limitArg');
      fetchedTasks = fetchedTasks.sublist(0, limitArg);
    }

    final resultTasks = fetchedTasks
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
              'parent_id': task.parentId,
              'order': task.order,
              'url': task.url,
              'comment_count': task.commentCount,
              'created_at': task.createdAt,
              'creator_id': task.creatorId,
              'assignee_id': task.assigneeId,
              'assigner_id': task.assignerId,
              'duration': task.duration?.durationObject?.amount,
              'duration_unit': task.duration?.durationObject?.unit,
              'is_completed': task.isCompleted,
            })
        .toList();

    final successMsg =
        'Successfully fetched ${resultTasks.length} Todoist tasks.';
    stderr.writeln('[TodoistServer] $successMsg');
    return _createSuccessResult(
      successMsg,
      resultData: {'tasks': resultTasks},
    );
  } catch (e) {
    stderr.writeln('[TodoistServer] Error fetching tasks: $e');
    var apiErrorMsg = 'Error getting Todoist tasks: ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      apiErrorMsg =
          'API Error getting tasks (${e.code}): ${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> _handleDeleteTodoistTask({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received delete_todoist_task request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final tasksApi = todoist.TasksApi(apiClient);

  try {
    if (args != null && args.containsKey('tasks') && args['tasks'] is List) {
      final tasksList = (args['tasks'] as List).cast<Map<String, dynamic>>();
      stderr.writeln(
          '[TodoistServer] Processing batch task deletion for ${tasksList.length} tasks.');
      final results = <Map<String, dynamic>>[];
      int successCount = 0;

      for (final taskData in tasksList) {
        String? taskIdToDelete;
        String? taskIdentifier;
        try {
          final taskIdArg = taskData['task_id'] as String?;
          final taskNameArg = taskData['task_name'] as String?;

          final targetTask = await _findTaskByIdOrName(apiClient,
              taskId: taskIdArg, taskName: taskNameArg);

          if (targetTask == null || targetTask.id == null) {
            results.add({
              'success': false,
              'error': 'Target task not found using provided ID/Name.',
              'taskData': taskData
            });
            continue;
          }

          taskIdToDelete = targetTask.id!;
          taskIdentifier = taskIdArg ?? taskNameArg;

          final intId = int.parse(taskIdToDelete);

          await tasksApi.deleteTask(intId);

          results.add({
            'success': true,
            'deletedTaskId': taskIdToDelete,
            'identifier': taskIdentifier,
          });
          successCount++;
        } catch (e) {
          stderr.writeln(
              '[TodoistServer] Error deleting batch task (ID: $taskIdToDelete, Identifier: $taskIdentifier): $e');
          String errorMsg = e.toString();
          if (e is todoist.ApiException) {
            errorMsg = 'API Error (${e.code}): ${e.message ?? "Unknown"}';
          } else if (e is FormatException) {
            errorMsg = 'Invalid Task ID format for deletion.';
          }
          results.add({
            'success': false,
            'error': errorMsg,
            'taskData': taskData,
            'attemptedTaskId': taskIdToDelete,
          });
        }
      }

      final summary = {
        'total': tasksList.length,
        'succeeded': successCount,
        'failed': tasksList.length - successCount,
      };
      final overallSuccess = successCount == tasksList.length;
      final message = overallSuccess
          ? 'Successfully deleted ${tasksList.length} tasks.'
          : 'Completed batch task deletion with $successCount successes and ${tasksList.length - successCount} failures.';

      return _createSuccessResult(message,
          resultData: {'summary': summary, 'results': results});
    } else if (args != null &&
        (args.containsKey('task_id') || args.containsKey('task_name'))) {
      final taskIdArg = args['task_id'] as String?;
      final taskNameArg = args['task_name'] as String?;

      stderr.writeln('[TodoistServer] Processing single task deletion.');
      final targetTask = await _findTaskByIdOrName(apiClient,
          taskId: taskIdArg, taskName: taskNameArg);

      if (targetTask == null || targetTask.id == null) {
        return _createErrorResult(
            'Target task not found using provided ID/Name.');
      }

      final taskIdToDelete = targetTask.id!;
      final taskIdentifier = taskIdArg ?? taskNameArg;

      final intId = int.parse(taskIdToDelete);

      await tasksApi.deleteTask(intId);

      final successMsg =
          'Todoist task (ID: $taskIdToDelete, identified by: "$taskIdentifier") deleted successfully.';
      stderr.writeln('[TodoistServer] $successMsg');
      return _createSuccessResult(
        successMsg,
        resultData: {
          'deletedTask': {
            'id': taskIdToDelete,
            'identifier': taskIdentifier,
            'originalContent': targetTask.content,
          }
        },
      );
    } else {
      return _createErrorResult(
          'Invalid arguments: Missing "task_id" or "task_name" for single task, or "tasks" array for batch.');
    }
  } catch (e) {
    var apiErrorMsg = 'Error deleting Todoist task(s): ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      apiErrorMsg =
          'API Error deleting task(s) (${e.code}): ${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    } else if (e is FormatException) {
      apiErrorMsg = 'Error parsing arguments (likely Task ID): ${e.message}';
      errorData = {'parsingError': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> handleCompleteTodoistTask({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received complete_todoist_task request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final tasksApi = todoist.TasksApi(apiClient);

  try {
    if (args != null && args.containsKey('tasks') && args['tasks'] is List) {
      final tasksList = (args['tasks'] as List).cast<Map<String, dynamic>>();
      stderr.writeln(
          '[TodoistServer] Processing batch task completion for ${tasksList.length} tasks.');
      final results = <Map<String, dynamic>>[];
      int successCount = 0;

      for (final taskData in tasksList) {
        String? taskIdToComplete;
        String? taskIdentifier;
        try {
          final taskIdArg = taskData['task_id'] as String?;
          final taskNameArg = taskData['task_name'] as String?;

          final targetTask = await _findTaskByIdOrName(apiClient,
              taskId: taskIdArg, taskName: taskNameArg);

          if (targetTask == null || targetTask.id == null) {
            results.add({
              'success': false,
              'error': 'Target task not found using provided ID/Name.',
              'taskData': taskData
            });
            continue;
          }
          if (targetTask.isCompleted == true) {
            results.add({
              'success': true,
              'message': 'Task was already completed.',
              'completedTaskId': targetTask.id!,
              'identifier': taskIdArg ?? taskNameArg,
            });
            successCount++;
            continue;
          }

          taskIdToComplete = targetTask.id!;
          taskIdentifier = taskIdArg ?? taskNameArg;

          final intId = int.parse(taskIdToComplete);

          await tasksApi.closeTask(intId);

          results.add({
            'success': true,
            'completedTaskId': taskIdToComplete,
            'identifier': taskIdentifier,
          });
          successCount++;
        } catch (e) {
          stderr.writeln(
              '[TodoistServer] Error completing batch task (ID: $taskIdToComplete, Identifier: $taskIdentifier): $e');
          String errorMsg = e.toString();
          if (e is todoist.ApiException) {
            errorMsg = 'API Error (${e.code}): ${e.message ?? "Unknown"}';
          } else if (e is FormatException) {
            errorMsg = 'Invalid Task ID format for completion.';
          }
          results.add({
            'success': false,
            'error': errorMsg,
            'taskData': taskData,
            'attemptedTaskId': taskIdToComplete,
          });
        }
      }

      final summary = {
        'total': tasksList.length,
        'succeeded': successCount,
        'failed': tasksList.length - successCount,
      };
      final overallSuccess = successCount == tasksList.length;
      final message = overallSuccess
          ? 'Successfully completed ${tasksList.length} tasks.'
          : 'Completed batch task completion with $successCount successes and ${tasksList.length - successCount} failures.';

      return _createSuccessResult(message,
          resultData: {'summary': summary, 'results': results});
    } else if (args != null &&
        (args.containsKey('task_id') || args.containsKey('task_name'))) {
      final taskIdArg = args['task_id'] as String?;
      final taskNameArg = args['task_name'] as String?;

      stderr.writeln('[TodoistServer] Processing single task completion.');
      final targetTask = await _findTaskByIdOrName(apiClient,
          taskId: taskIdArg, taskName: taskNameArg);

      if (targetTask == null || targetTask.id == null) {
        return _createErrorResult(
            'Target task not found using provided ID/Name.');
      }

      if (targetTask.isCompleted == true) {
        final msg =
            'Task (ID: ${targetTask.id}, identified by: "${taskIdArg ?? taskNameArg}") was already completed.';
        stderr.writeln('[TodoistServer] $msg');
        return _createSuccessResult(
          msg,
          resultData: {
            'completedTask': {
              'id': targetTask.id!,
              'identifier': taskIdArg ?? taskNameArg,
              'originalContent': targetTask.content,
              'alreadyCompleted': true,
            }
          },
        );
      }

      final taskIdToComplete = targetTask.id!;
      final taskIdentifier = taskIdArg ?? taskNameArg;

      final intId = int.parse(taskIdToComplete);

      await tasksApi.closeTask(intId);

      final successMsg =
          'Todoist task (ID: $taskIdToComplete, identified by: "$taskIdentifier") completed successfully.';
      stderr.writeln('[TodoistServer] $successMsg');
      return _createSuccessResult(
        successMsg,
        resultData: {
          'completedTask': {
            'id': taskIdToComplete,
            'identifier': taskIdentifier,
            'originalContent': targetTask.content,
            'alreadyCompleted': false,
          }
        },
      );
    } else {
      return _createErrorResult(
          'Invalid arguments: Missing "task_id" or "task_name" for single task, or "tasks" array for batch.');
    }
  } catch (e) {
    var apiErrorMsg = 'Error completing Todoist task(s): ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      apiErrorMsg =
          'API Error completing task(s) (${e.code}): ${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> handleGetTaskComments({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received get_task_comments request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');
  return _createErrorResult('Handler not fully implemented yet.');
}

Future<mcp_dart.CallToolResult> handleCreateTaskComment({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received create_task_comment request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');
  return _createErrorResult('Handler not fully implemented yet.');
}

// --- Stubs for New Handlers ---

Future<mcp_dart.CallToolResult> _handleGetProjects(
    {Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
  stderr.writeln('[TodoistServer] Received todoist_get_projects request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final projectsApi = todoist.ProjectsApi(apiClient);

  try {
    final projects = await projectsApi.getAllProjects();
    if (projects == null) {
      return _createErrorResult('API returned null project list.');
    }

    final resultProjects = projects
        .map((proj) => {
              'id': proj.id,
              'name': proj.name,
              'color': proj.color,
              'parent_id': proj.parentId,
              'order': proj.order,
              'comment_count': proj.commentCount,
              'is_shared': proj.isShared,
              'is_favorite': proj.isFavorite,
              'is_inbox_project': proj.isInboxProject,
              'is_team_inbox': proj.isTeamInbox,
              'view_style': proj.viewStyle,
              'url': proj.url,
            })
        .toList();

    final successMsg =
        'Successfully fetched ${resultProjects.length} Todoist projects.';
    stderr.writeln('[TodoistServer] $successMsg');
    return _createSuccessResult(
      successMsg,
      resultData: {'projects': resultProjects},
    );
  } catch (e) {
    var apiErrorMsg = 'Error getting Todoist projects: ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      apiErrorMsg =
          'API Error getting projects (${e.code}): ${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> _handleCreateProject(
    {Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
  stderr.writeln('[TodoistServer] Received todoist_create_project request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final projectsApi = todoist.ProjectsApi(apiClient);

  try {
    final name = args?['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      return _createErrorResult('Project name cannot be empty.');
    }

    final newProject = await projectsApi.createProject(
      name,
      parentId: args?['parent_id'] as String?,
      color: args?['color'] as String?,
      isFavorite: args?['is_favorite'] as bool?,
      viewStyle: args?['view_style'] as String?,
    );
    if (newProject == null) {
      return _createErrorResult('API returned null for the new project.');
    }

    final successMsg =
        'Todoist project created successfully: "${newProject.name}"';
    stderr.writeln('[TodoistServer] $successMsg (ID: ${newProject.id})');
    return _createSuccessResult(
      successMsg,
      resultData: {
        'project': {
          'id': newProject.id,
          'name': newProject.name,
          'color': newProject.color,
          'parent_id': newProject.parentId,
          'order': newProject.order,
          'comment_count': newProject.commentCount,
          'is_shared': newProject.isShared,
          'is_favorite': newProject.isFavorite,
          'is_inbox_project': newProject.isInboxProject,
          'is_team_inbox': newProject.isTeamInbox,
          'view_style': newProject.viewStyle,
          'url': newProject.url,
        }
      },
    );
  } catch (e) {
    var apiErrorMsg = 'Error creating Todoist project: ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      apiErrorMsg =
          'API Error creating project (${e.code}): ${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> _handleUpdateProject(
    {Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
  stderr.writeln('[TodoistServer] Received todoist_update_project request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final projectsApi = todoist.ProjectsApi(apiClient);

  try {
    final projectIdStr = args?['project_id'] as String?;
    if (projectIdStr == null || projectIdStr.trim().isEmpty) {
      return _createErrorResult('Project ID is required for update.');
    }

    try {
      await projectsApi.getProject(projectIdStr);
    } catch (e) {
      if (e is todoist.ApiException && e.code == 404) {
        return _createErrorResult('Project with ID "$projectIdStr" not found.');
      }
      stderr.writeln(
          '[TodoistServer] Error checking project existence for ID $projectIdStr: $e');
      return _createErrorResult(
          'Error verifying project existence: ${e.toString()}');
    }

    final request = todoist.Project(
      name: args?['name'] as String?,
      color: args?['color'] as String?,
      isFavorite: args?['is_favorite'] as bool?,
      viewStyle: args?['view_style'] as String?,
    );

    if (request.name == null &&
        request.color == null &&
        request.isFavorite == null &&
        request.viewStyle == null) {
      return _createErrorResult(
          'No update parameters provided for project ID $projectIdStr.');
    }

    await projectsApi.updateProject(projectIdStr,
        name: request.name,
        color: request.color,
        isFavorite: request.isFavorite,
        viewStyle: request.viewStyle);
    final updatedProject = await projectsApi.getProject(projectIdStr);

    if (updatedProject == null) {
      return _createErrorResult(
          'Project updated, but failed to re-fetch details for ID $projectIdStr.');
    }

    final successMsg =
        'Todoist project "${updatedProject.name}" (ID: $projectIdStr) updated successfully.';
    stderr.writeln('[TodoistServer] $successMsg');
    return _createSuccessResult(
      successMsg,
      resultData: {
        'project': {
          'id': updatedProject.id,
          'name': updatedProject.name,
          'color': updatedProject.color,
          'parent_id': updatedProject.parentId,
          'order': updatedProject.order,
          'comment_count': updatedProject.commentCount,
          'is_shared': updatedProject.isShared,
          'is_favorite': updatedProject.isFavorite,
          'is_inbox_project': updatedProject.isInboxProject,
          'is_team_inbox': updatedProject.isTeamInbox,
          'view_style': updatedProject.viewStyle,
          'url': updatedProject.url,
        }
      },
    );
  } catch (e) {
    var apiErrorMsg = 'Error updating Todoist project: ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      apiErrorMsg =
          'API Error updating project (${e.code}): ${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> _handleGetProjectSections(
    {Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
  stderr.writeln(
      '[TodoistServer] Received todoist_get_project_sections request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final sectionsApi = todoist.SectionsApi(apiClient);

  try {
    final projectIdStr = args?['project_id'] as String?;
    if (projectIdStr == null || projectIdStr.trim().isEmpty) {
      return _createErrorResult('Project ID is required to get sections.');
    }

    var sections = await sectionsApi.getAllSections(projectId: projectIdStr);
    if (sections == null) {
      stderr.writeln(
          '[TodoistServer] API returned null section list for project ID $projectIdStr. Assuming empty.');
      sections = [];
    }

    final resultSections = sections
        .map((sec) => {
              'id': sec.id,
              'project_id': sec.projectId,
              'order': sec.order,
              'name': sec.name,
            })
        .toList();

    final successMsg =
        'Successfully fetched ${resultSections.length} sections for project ID $projectIdStr.';
    stderr.writeln('[TodoistServer] $successMsg');
    return _createSuccessResult(
      successMsg,
      resultData: {'sections': resultSections},
    );
  } catch (e) {
    var apiErrorMsg =
        'Error getting Todoist project sections: ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      apiErrorMsg =
          'API Error getting project sections (${e.code}): ${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

Future<mcp_dart.CallToolResult> _handleCreateProjectSection(
    {Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
  stderr.writeln(
      '[TodoistServer] Received todoist_create_project_section request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final sectionsApi = todoist.SectionsApi(apiClient);

  try {
    final projectIdStr = args?['project_id'] as String?;
    final name = args?['name'] as String?;

    if (projectIdStr == null || projectIdStr.trim().isEmpty) {
      return _createErrorResult('Project ID is required to create a section.');
    }
    if (name == null || name.trim().isEmpty) {
      return _createErrorResult('Section name cannot be empty.');
    }

    final newSection = await sectionsApi.createSection(
      projectIdStr,
      name,
      order: args?['order'] as int?,
    );
    if (newSection == null) {
      return _createErrorResult('API returned null for the new section.');
    }

    final successMsg =
        'Todoist section created successfully: "${newSection.name}" in project $projectIdStr';
    stderr.writeln('[TodoistServer] $successMsg (ID: ${newSection.id})');
    return _createSuccessResult(
      successMsg,
      resultData: {
        'section': {
          'id': newSection.id,
          'project_id': newSection.projectId,
          'order': newSection.order,
          'name': newSection.name,
        }
      },
    );
  } catch (e) {
    var apiErrorMsg = 'Error creating Todoist project section: ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      apiErrorMsg =
          'API Error creating project section (${e.code}): ${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

// ADD: Handler for creating personal labels
Future<mcp_dart.CallToolResult> _handleCreatePersonalLabel(
    {Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
  stderr.writeln(
      '[TodoistServer] Received todoist_create_personal_label request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final labelsApi = todoist.LabelsApi(apiClient);

  try {
    final name = args?['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      return _createErrorResult('Label name cannot be empty.');
    }

    final existingLabel = await _findLabelByName(apiClient, name);
    if (existingLabel != null) {
      return _createErrorResult(
          'Label with name "$name" already exists (ID: ${existingLabel.id}).');
    }

    final newLabel = await labelsApi.createPersonalLabel(
      name,
      order: args?['order'] as int?,
      color: args?['color'] as String?,
      isFavorite: args?['is_favorite'] as bool?,
    );
    if (newLabel == null) {
      return _createErrorResult('API returned null for the new label.');
    }

    final successMsg =
        'Todoist personal label created successfully: "${newLabel.name}"';
    stderr.writeln('[TodoistServer] $successMsg (ID: ${newLabel.id})');
    return _createSuccessResult(
      successMsg,
      resultData: {
        'label': {
          'id': newLabel.id,
          'name': newLabel.name,
          'color': newLabel.color,
          'order': newLabel.order,
          'is_favorite': newLabel.isFavorite,
        }
      },
    );
  } catch (e) {
    var apiErrorMsg = 'Error creating Todoist personal label: ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      apiErrorMsg =
          'API Error creating label (${e.code}): ${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

// ADD: Handler for getting a specific personal label
Future<mcp_dart.CallToolResult> _handleGetPersonalLabel(
    {Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
  stderr
      .writeln('[TodoistServer] Received todoist_get_personal_label request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final labelsApi = todoist.LabelsApi(apiClient);

  try {
    final labelIdStr = args?['label_id'] as String?;
    if (labelIdStr == null || labelIdStr.trim().isEmpty) {
      return _createErrorResult('Label ID is required.');
    }

    final intId = int.tryParse(labelIdStr);
    if (intId == null) {
      return _createErrorResult(
          'Invalid label ID format: "$labelIdStr". Must be an integer.');
    }

    final label = await labelsApi.getPersonalLabel(intId);
    if (label == null) {
      return _createErrorResult('Label with ID $intId not found.');
    }

    final successMsg =
        'Successfully fetched personal label: "${label.name}" (ID: ${label.id})';
    stderr.writeln('[TodoistServer] $successMsg');
    return _createSuccessResult(
      successMsg,
      resultData: {
        'label': {
          'id': label.id,
          'name': label.name,
          'color': label.color,
          'order': label.order,
          'is_favorite': label.isFavorite,
        }
      },
    );
  } catch (e) {
    var apiErrorMsg = 'Error getting Todoist personal label: ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      if (e.code == 404) {
        apiErrorMsg = 'Label with ID "${args?['label_id']}" not found.';
      } else {
        apiErrorMsg =
            'API Error getting label (${e.code}): ${e.message ?? "Unknown API error"}';
      }
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    } else if (e is FormatException) {
      apiErrorMsg =
          'Invalid label ID format: "${args?['label_id']}". Must be an integer.';
      errorData = {'parsingError': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

// ADD: Handler for updating personal labels
Future<mcp_dart.CallToolResult> _handleUpdatePersonalLabel(
    {Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
  stderr.writeln(
      '[TodoistServer] Received todoist_update_personal_label request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final labelsApi = todoist.LabelsApi(apiClient);

  try {
    final labelIdArg = args?['label_id'] as String?;
    final labelNameArg = args?['label_name'] as String?;

    if ((labelIdArg == null || labelIdArg.trim().isEmpty) &&
        (labelNameArg == null || labelNameArg.trim().isEmpty)) {
      return _createErrorResult(
          'Either label_id or label_name is required for update.');
    }

    final targetLabel = await _findLabelByIdOrName(apiClient,
        labelId: labelIdArg, labelName: labelNameArg);

    if (targetLabel == null || targetLabel.id == null) {
      return _createErrorResult(
          'Target label not found using provided ID/Name.');
    }

    final labelIdToUpdate = targetLabel.id!;

    final newName = args?['name'] as String?;
    final newOrder = args?['order'] as int?;
    final newColor = args?['color'] as String?;
    final newIsFavorite = args?['is_favorite'] as bool?;

    if (newName == null &&
        newOrder == null &&
        newColor == null &&
        newIsFavorite == null) {
      return _createErrorResult(
          'No update parameters provided for label ID $labelIdToUpdate.');
    }

    if (newName != null &&
        newName.toLowerCase() != targetLabel.name?.toLowerCase()) {
      final conflictingLabel = await _findLabelByName(apiClient, newName);
      if (conflictingLabel != null && conflictingLabel.id != labelIdToUpdate) {
        return _createErrorResult(
            'Another label with the name "$newName" already exists (ID: ${conflictingLabel.id}). Cannot update.');
      }
    }

    await labelsApi.updatePersonalLabel(
      labelIdToUpdate,
      name: newName,
      order: newOrder,
      color: newColor,
      isFavorite: newIsFavorite,
    );

    final updatedLabel =
        await labelsApi.getPersonalLabel(int.parse(labelIdToUpdate));
    if (updatedLabel == null) {
      return _createErrorResult(
          'Label updated, but failed to re-fetch details for ID $labelIdToUpdate.');
    }

    final successMsg =
        'Todoist personal label "${updatedLabel.name}" (ID: $labelIdToUpdate) updated successfully.';
    stderr.writeln('[TodoistServer] $successMsg');
    return _createSuccessResult(
      successMsg,
      resultData: {
        'label': {
          'id': updatedLabel.id,
          'name': updatedLabel.name,
          'color': updatedLabel.color,
          'order': updatedLabel.order,
          'is_favorite': updatedLabel.isFavorite,
        }
      },
    );
  } catch (e) {
    var apiErrorMsg = 'Error updating Todoist personal label: ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      if (e.code == 404) {
        apiErrorMsg =
            'Label to update not found using ID "${args?['label_id']}" or name "${args?['label_name']}".';
      } else {
        apiErrorMsg =
            'API Error updating label (${e.code}): ${e.message ?? "Unknown API error"}';
      }
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    } else if (e is FormatException) {
      apiErrorMsg =
          'Invalid label ID format provided: "${args?['label_id']}". Must be an integer.';
      errorData = {'parsingError': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

// ADD: Handler for deleting personal labels
Future<mcp_dart.CallToolResult> _handleDeletePersonalLabel(
    {Map<String, dynamic>? args, RequestHandlerExtra? extra}) async {
  stderr.writeln(
      '[TodoistServer] Received todoist_delete_personal_label request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}');

  final apiClient = _configureApiClient();
  if (apiClient == null) {
    return _createErrorResult(
        'TODOIST_API_TOKEN environment variable not set or empty.');
  }
  final labelsApi = todoist.LabelsApi(apiClient);

  try {
    final labelIdStr = args?['label_id'] as String?;
    if (labelIdStr == null || labelIdStr.trim().isEmpty) {
      return _createErrorResult('Label ID is required for deletion.');
    }

    final intId = int.tryParse(labelIdStr);
    if (intId == null) {
      return _createErrorResult(
          'Invalid label ID format: "$labelIdStr". Must be an integer.');
    }

    String? labelNameBeforeDelete;
    try {
      final label = await labelsApi.getPersonalLabel(intId);
      labelNameBeforeDelete = label?.name;
    } catch (e) {
      if (e is todoist.ApiException && e.code == 404) {
        return _createErrorResult(
            'Label with ID $intId not found. Cannot delete.');
      }
    }

    await labelsApi.deletePersonalLabel(intId);

    final successMsg =
        'Todoist personal label (ID: $intId${labelNameBeforeDelete != null ? ', Name: "$labelNameBeforeDelete"' : ''}) deleted successfully.';
    stderr.writeln('[TodoistServer] $successMsg');
    return _createSuccessResult(
      successMsg,
      resultData: {
        'deletedLabelId': intId,
        'originalName': labelNameBeforeDelete,
      },
    );
  } catch (e) {
    var apiErrorMsg = 'Error deleting Todoist personal label: ${e.toString()}';
    stderr.writeln('[TodoistServer] $apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}');
      if (e.code == 404) {
        apiErrorMsg =
            'Label with ID "${args?['label_id']}" not found (or already deleted).';
      } else {
        apiErrorMsg =
            'API Error deleting label (${e.code}): ${e.message ?? "Unknown API error"}';
      }
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    } else if (e is FormatException) {
      apiErrorMsg =
          'Invalid label ID format: "${args?['label_id']}". Must be an integer.';
      errorData = {'parsingError': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}
