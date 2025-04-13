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
        '[TodoistServer] Error during _findTaskByName("\$taskName"): \$e');
    if (e is todoist.ApiException) {
      stderr.writeln(
        '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}',
      );
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
    stderr.writeln('[TodoistServer] Searching for task by ID: "\$taskId"');
    try {
      // getActiveTask expects an integer ID
      final intId = int.tryParse(taskId);
      if (intId == null) {
        stderr.writeln(
            '[TodoistServer] Invalid task ID format: "\$taskId". Must be an integer.');
        return null;
      }
      final task = await tasksApi.getActiveTask(intId);
      if (task != null) {
        stderr.writeln(
            '[TodoistServer] Found task by ID "\$taskId": Content "\${task.content}"');
        return task;
      } else {
        stderr.writeln('[TodoistServer] No task found with ID "\$taskId".');
        // Fall through to search by name if provided
      }
    } catch (e) {
      stderr
          .writeln('[TodoistServer] Error fetching task by ID "\$taskId": \$e');
      if (e is todoist.ApiException && e.code == 404) {
        stderr.writeln('[TodoistServer] Task ID "\$taskId" not found (404).');
        // Fall through to search by name if provided
      } else if (e is todoist.ApiException) {
        stderr.writeln(
            '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
        // Don\'t fall through on other API errors
        return null;
      } else {
        // Don\'t fall through on non-API errors
        return null;
      }
    }
  }

  // 2. Try by Name if ID search failed or wasn\'t provided
  if (taskName != null && taskName.trim().isNotEmpty) {
    return await _findTaskByName(client, taskName);
  }

  // 3. If neither ID nor name provided or search failed
  stderr.writeln(
      '[TodoistServer] Could not find task: No valid ID or name provided, or search failed.');
  return null;
}

// --- Generic Result Helpers ---

// Generic error result helper
mcp_dart.CallToolResult _createErrorResult(String message,
    {Map<String, dynamic>? errorData}) {
  final payload = {
    'status': 'error',
    'message': message,
    'result': errorData ?? {},
  };
  stderr.writeln('[TodoistServer] Creating Error Result: \${jsonEncode(payload)}');
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
    'result': resultData ?? {},
  };
  stderr.writeln('[TodoistServer] Creating Success Result: \${jsonEncode(payload)}');
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

  // 2. Register Tools

  // Change 1: Remove commented-out anyOf from create_todoist_task tool registration
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
              'description': '2-letter language code for deadline parsing (optional)',
            }
          },
          'required': ['content'],
        },
      },
      'content': {
        'type': 'string',
        'description': 'The content of the task (required if "tasks" array is not provided).',
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

  // Change 2: Remove commented-out anyOf from update_todoist_task tool registration
  server.tool(
    'update_todoist_task',
    description:
        'Updates one or more existing tasks in Todoist. Requires either task_id or task_name for each task. task_id takes precedence. Returns the updated task details.',
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
              'description': 'New detailed description for the task (optional).',
            },
            'project_id': {
              'type': 'string',
              'description': 'Move task to this project ID (optional).',
            },
            'section_id': {
              'type': 'string',
              'description': 'Move task to this section ID (optional).',
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
            'deadline_date': {
              'type': 'string',
              'description': 'New deadline date in YYYY-MM-DD format (optional)',
            },
            'deadline_lang': {
              'type': 'string',
              'description': 'New 2-letter language code for deadline parsing (optional)',
            }
          }
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
      'project_id': {
        'type': 'string',
        'description': 'Move task to this project ID (optional).',
      },
      'section_id': {
        'type': 'string',
        'description': 'Move task to this section ID (optional).',
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
      'deadline_date': {
        'type': 'string',
        'description': 'New deadline date in YYYY-MM-DD format (optional)',
      },
      'deadline_lang': {
        'type': 'string',
        'description': 'New 2-letter language code for deadline parsing (optional)',
      }
    },
    callback: _handleUpdateTodoistTask, // Direct function reference
  );

  // Change 3: Remove commented-out anyOf from todoist_delete_task tool registration
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
    callback: _handleDeleteTodoistTask, // Direct function reference
  );

  // Change 4: Remove commented-out anyOf from todoist_complete_task tool registration
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
    callback: handleCompleteTodoistTask, // Direct function reference
  );

  // Change 5: Remove commented-out anyOf from todoist_create_project tool registration
  server.tool(
    'todoist_create_project',
    description: 'Create one or more projects with support for nested hierarchies.',
    inputSchemaProperties: {
      'projects': {
        'type': 'array',
        'description': 'Array of projects to create (for batch operations).',
        'items': {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'Name of the project.'
            },
            'parent_id': {
              'type': 'string',
              'description': 'Parent project ID (optional).'
            },
            'parent_name': {
              'type': 'string',
              'description': 'Name of the parent project (will be created or found automatically, optional).'
            },
            'color': {
              'type': 'string',
              'description': 'Color of the project (optional).'
            },
            'favorite': {
              'type': 'boolean',
              'description': 'Whether the project is a favorite (optional).'
            },
            'view_style': {
              'type': 'string',
              'description': 'View style of the project (optional).',
              'enum': ['list', 'board']
            },
            'sections': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Sections to create within this project (optional).'
            }
          },
          'required': ['name']
        },
      },
      'name': {
        'type': 'string',
        'description': 'Name of the project (for single project creation).'
      },
      'parent_id': {
        'type': 'string',
        'description': 'Parent project ID (optional).'
      },
      'color': {
        'type': 'string',
        'description': 'Color of the project (optional).',
      },
      'favorite': {
        'type': 'boolean',
        'description': 'Whether the project is a favorite (optional).'
      },
      'view_style': {
        'type': 'string',
        'description': 'View style of the project (optional).',
        'enum': ['list', 'board']
      }
    },
    callback: _handleCreateProject, // Placeholder for new handler
  );

  // Change 6: Remove commented-out anyOf from todoist_update_project tool registration
  server.tool(
    'todoist_update_project',
    description: 'Update one or more projects in Todoist.',
    inputSchemaProperties: {
      'projects': {
        'type': 'array',
        'description': 'Array of projects to update (for batch operations).',
        'items': {
          'type': 'object',
          'properties': {
            'project_id': {
              'type': 'string',
              'description': 'ID of the project to update (preferred).'
            },
            'project_name': {
              'type': 'string',
              'description': 'Name of the project to update (if ID not provided).'
            },
            'name': {
              'type': 'string',
              'description': 'New name for the project (optional).'
            },
            'color': {
              'type': 'string',
              'description': 'New color for the project (optional).',
            },
            'favorite': {
              'type': 'boolean',
              'description': 'Whether the project should be a favorite (optional).'
            },
            'view_style': {
              'type': 'string',
              'description': 'View style of the project (optional).',
              'enum': ['list', 'board']
            }
          }
        },
      },
      'project_id': {
        'type': 'string',
        'description': 'ID of the project to update (required if "projects" array is not used).'
      },
      'name': {
        'type': 'string',
        'description': 'New name for the project (optional).'
      },
      'color': {
        'type': 'string',
        'description': 'New color for the project (optional).',
      },
      'favorite': {
        'type': 'boolean',
        'description': 'Whether the project should be a favorite (optional).'
      },
      'view_style': {
        'type': 'string',
        'description': 'View style of the project (optional).',
        'enum': ['list', 'board']
      }
    },
    callback: _handleUpdateProject, // Placeholder for new handler
  );

  // Change 7: Remove commented-out anyOf from todoist_get_project_sections tool registration
  server.tool(
    'todoist_get_project_sections',
    description: 'Get sections from one or more projects in Todoist.',
    inputSchemaProperties: {
      'projects': {
        'type': 'array',
        'description': 'Array of projects to get sections from (for batch operations).',
        'items': {
          'type': 'object',
          'properties': {
            'project_id': {
              'type': 'string',
              'description': 'ID of the project to get sections from (preferred).'
            },
            'project_name': {
              'type': 'string',
              'description': 'Name of the project to get sections from (if ID not provided).'
            }
          }
        },
      },
      'project_id': {
        'type': 'string',
        'description': 'ID of the project to get sections from (required if "projects" array is not used).'
      },
      'project_name': {
        'type': 'string',
        'description': 'Name of the project to get sections from (if ID not provided).'
      },
      'include_empty': {
        'type': 'boolean',
        'description': 'Whether to include sections with no tasks (client-side filtering may be needed).',
        'default': true
      }
    },
    callback: _handleGetProjectSections, // Placeholder for new handler
  );

  // Change 8: Remove commented-out anyOf from todoist_create_project_section tool registration
  server.tool(
    'todoist_create_project_section',
    description: 'Create one or more sections in Todoist projects.',
    inputSchemaProperties: {
      'sections': {
        'type': 'array',
        'description': 'Array of sections to create (for batch operations).',
        'items': {
          'type': 'object',
          'properties': {
            'project_id': {
              'type': 'string',
              'description': 'ID of the project to create the section in (preferred).'
            },
            'project_name': {
              'type': 'string',
              'description': 'Name of the project to create the section in (if ID not provided).'
            },
            'name': {
              'type': 'string',
              'description': 'Name of the section.'
            },
            'order': {
              'type': 'integer',
              'description': 'Order of the section (optional).'
            }
          },
          'required': ['name']
        },
      },
      'project_id': {
        'type': 'string',
        'description': 'ID of the project (required if "sections" array is not used).'
      },
      'name': {
        'type': 'string',
        'description': 'Name of the section (required if "sections" array is not used).'
      },
      'order': {
        'type': 'integer',
        'description': 'Order of the section (optional).'
      }
    },
    callback: _handleCreateProjectSection, // Placeholder for new handler
  );

  // Personal Label Tools (No top-level anyOf to remove here)
  server.tool(
    'todoist_get_personal_labels',
    description: 'Get all personal labels from Todoist.',
    inputSchemaProperties: {},
    callback: _handleGetPersonalLabels,
  );

  // Change 9: Remove commented-out anyOf from todoist_create_personal_label tool registration
  server.tool(
    'todoist_create_personal_label',
    description: 'Create one or more personal labels in Todoist.',
    inputSchemaProperties: {
      'labels': {
        'type': 'array',
        'description': 'Array of labels to create (for batch operations).',
        'items': {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'Name of the label.'
            },
            'color': {
              'type': 'string',
              'description': 'Color of the label (optional).',
            },
            'order': {
              'type': 'integer',
              'description': 'Order of the label (optional).'
            },
            'is_favorite': {
              'type': 'boolean',
              'description': 'Whether the label is a favorite (optional).'
            }
          },
          'required': ['name']
        },
      },
      'name': {
        'type': 'string',
        'description': 'Name of the label (required if "labels" array is not used).'
      },
      'color': {
        'type': 'string',
        'description': 'Color of the label (optional).',
      },
      'order': {
        'type': 'integer',
        'description': 'Order of the label (optional).'
      },
      'is_favorite': {
        'type': 'boolean',
        'description': 'Whether the label is a favorite (optional).'
      }
    },
    callback: _handleCreatePersonalLabel, // Placeholder for new handler
  );

  server.tool(
    'todoist_get_personal_label',
    description: 'Get a personal label by ID.',
    inputSchemaProperties: {
      'label_id': {
        'type': 'string',
        'description': 'ID of the label to retrieve.'
      }
    },
    callback: _handleGetPersonalLabel, // Placeholder for new handler
  );

  // Change 10: Remove commented-out anyOf from todoist_update_personal_label tool registration
  server.tool(
    'todoist_update_personal_label',
    description: 'Update one or more existing personal labels in Todoist.',
    inputSchemaProperties: {
      'labels': {
        'type': 'array',
        'description': 'Array of labels to update (for batch operations).',
        'items': {
          'type': 'object',
          'properties': {
            'label_id': {
              'type': 'string',
              'description': 'ID of the label to update (preferred).'
            },
            'label_name': {
              'type': 'string',
              'description': 'Name of the label to search for and update (if ID not provided).'
            },
            'name': {
              'type': 'string',
              'description': 'New name for the label (optional).'
            },
            'color': {
              'type': 'string',
              'description': 'New color for the label (optional).',
            },
            'order': {
              'type': 'integer',
              'description': 'New order for the label (optional).'
            },
            'is_favorite': {
              'type': 'boolean',
              'description': 'Whether the label is a favorite (optional).'
            }
          }
        }
      },
      'label_id': {
        'type': 'string',
        'description': 'ID of the label to update (required if "labels" array is not used).'
      },
      'label_name': {
        'type': 'string',
        'description': 'Name of the label to search for and update (if ID not provided).'
      },
      'name': {
        'type': 'string',
        'description': 'New name for the label (optional).'
      },
      'color': {
        'type': 'string',
        'description': 'New color for the label (optional).',
      },
      'order': {
        'type': 'integer',
        'description': 'New order for the label (optional).'
      },
      'is_favorite': {
        'type': 'boolean',
        'description': 'Whether the label is a favorite (optional).'
      }
    },
    callback: _handleUpdatePersonalLabel, // Placeholder for new handler
  );

  server.tool(
    'todoist_delete_personal_label',
    description: 'Delete a personal label from Todoist.',
    inputSchemaProperties: {
      'label_id': {
        'type': 'string',
        'description': 'ID of the label to delete.'
      }
    },
    callback: _handleDeletePersonalLabel, // Placeholder for new handler
  );

  // Shared Label Tools (No top-level anyOf to remove here)
  server.tool(
    'todoist_get_shared_labels',
    description: 'Get all shared labels from Todoist.',
    inputSchemaProperties: {
      'omit_personal': {
        'type': 'boolean',
        'description': 'Whether to exclude the names of the user\'s personal labels from the results (default: false).'
      }
    },
    callback: _handleGetSharedLabels,
  );

  // Change 11: Remove commented-out anyOf from todoist_rename_shared_labels tool registration
  server.tool(
    'todoist_rename_shared_labels',
    description: 'Rename one or more shared labels in Todoist.',
    inputSchemaProperties: {
      'labels': {
        'type': 'array',
        'description': 'Array of label rename operations (for batch operations).',
        'items': {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'The name of the existing label to rename.'
            },
            'new_name': {
              'type': 'string',
              'description': 'The new name for the label.'
            }
          },
          'required': ['name', 'new_name']
        }
      },
      'name': {
        'type': 'string',
        'description': 'The name of the existing label to rename (required if "labels" array is not used).'
      },
      'new_name': {
        'type': 'string',
        'description': 'The new name for the label (required if "labels" array is not used).'
      }
    },
    callback: _handleRenameSharedLabels, // Placeholder for new handler
  );

  // Change 12: Remove commented-out anyOf from todoist_remove_shared_labels tool registration
  server.tool(
    'todoist_remove_shared_labels',
    description: 'Remove one or more shared labels from Todoist tasks.',
    inputSchemaProperties: {
      'labels': {
        'type': 'array',
        'description': 'Array of shared label names to remove (for batch operations).',
        'items': {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'The name of the label to remove.'
            }
          },
          'required': ['name']
        }
      },
      'name': {
        'type': 'string',
        'description': 'The name of the label to remove (required if "labels" array is not used).'
      }
    },
    callback: _handleRemoveSharedLabels, // Placeholder for new handler
  );

  // Change 13: Remove commented-out anyOf from todoist_update_task_labels tool registration
  server.tool(
    'todoist_update_task_labels',
    description: 'Update the labels of one or more tasks in Todoist.',
    inputSchemaProperties: {
      'tasks': {
        'type': 'array',
        'description': 'Array of tasks to update labels for (for batch operations).',
        'items': {
          'type': 'object',
          'properties': {
            'task_id': {
              'type': 'string',
              'description': 'ID of the task to update labels for (preferred).'
            },
            'task_name': {
              'type': 'string',
              'description': 'Name/content of the task to search for and update labels (if ID not provided).'
            },
            'labels': {
              'type': 'array',
              'items': {'type': 'string'},
              'description':
                  'Array of label names to set for the task (required if "tasks" array is not used).'
            }
          },
          'required': ['labels']
        }
      },
      'task_id': {
        'type': 'string',
        'description': 'ID of the task to update labels for (preferred).'
      },
      'task_name': {
        'type': 'string',
        'description': 'Name/content of the task to search for and update labels (if ID not provided).'
      },
      'labels': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Array of label names to set for the task (required if "tasks" array is not used).'
      }
    },
    callback: _handleUpdateTaskLabels, // Placeholder for new handler
  );

  stderr.writeln(
    '[TodoistServer] Registered tools: create_todoist_task, update_todoist_task, get_todoist_tasks, todoist_delete_task, todoist_complete_task, get_task_comments, create_task_comment, todoist_get_projects, todoist_create_project, todoist_update_project, todoist_get_project_sections, todoist_create_project_section, todoist_get_personal_labels, todoist_create_personal_label, todoist_get_personal_label, todoist_update_personal_label, todoist_delete_personal_label, todoist_get_shared_labels, todoist_rename_shared_labels, todoist_remove_shared_labels, todoist_update_task_labels',
  );

  // 3. Connect to the Transport based on mode
  if (transportMode == TransportMode.stdio) {
    final transport = mcp_dart.StdioServerTransport();
    ProcessSignal.sigint.watch().listen((signal) async {
      stderr.writeln('[TodoistServer][stdio] Received SIGINT. Shutting down...');
      await server.close();
      await transport.close();
      exit(0);
    });
    ProcessSignal.sigterm.watch().listen((signal) async {
      stderr.writeln('[TodoistServer][stdio] Received SIGTERM. Shutting down...');
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
      stderr.writeln('[TodoistServer][stdio] Failed to connect to transport: \$e');
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
        stderr.writeln("[TodoistServer][sse] Closing \${sseManager.activeSseTransports.length} active SSE transports...");
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
      httpServer.idleTimeout = null;
      stderr.writeln('[TodoistServer][sse] Explicitly set HttpServer.idleTimeout to null.');
      stderr.writeln('[TodoistServer][sse] Serving MCP over SSE (GET \${sseManager.ssePath}) and HTTP (POST \${sseManager.messagePath}) at http://\${httpServer.address.host}:\${httpServer.port}');
      httpServer.listen(
        (HttpRequest request) {
          stderr.writeln('[TodoistServer][sse] Request: \${request.method} \${request.uri}');
          sseManager.handleRequest(request).catchError((e, s) {
            stderr.writeln('[TodoistServer][sse] Error handling request \${request.uri}: \$e\n\$s');
            try {
              if (request.response.connectionInfo != null) {
                request.response.statusCode = HttpStatus.internalServerError;
                request.response.write('Internal Server Error');
                request.response.close();
              }
            } catch (_) {
              stderr.writeln('[TodoistServer][sse] Could not send error response for \${request.uri}. Connection likely closed.');
            }
          });
        },
        onError: (e, s) => stderr.writeln('[TodoistServer][sse] HttpServer error: \$e\n\$s'),
        onDone: () => stderr.writeln('[TodoistServer][sse] HttpServer closed.'),
      );
      stderr.writeln("[TodoistServer][sse] Signal handlers registered.");
    } catch (e) {
      stderr.writeln('[TodoistServer][sse] FATAL: Failed to bind server to port \$port: \$e');
      exit(1);
    }
  }
}

// --- Tool Handlers (Refactored & New Stubs) ---

// Change 14: Implement _handleCreateTodoistTask handler
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
  // Optional: Add health check if desired, though might slow down requests
  // if (!await _checkApiHealth(apiClient)) {
  //   return _createErrorResult('Todoist API health check failed.');
  // }

  final tasksApi = todoist.TasksApi(apiClient);

  try {
    // --- Check for Batch Operation ---
    if (args != null && args.containsKey('tasks') && args['tasks'] is List) {
      final tasksList = (args['tasks'] as List).cast<Map<String, dynamic>>();
      stderr.writeln(
          '[TodoistServer] Processing batch task creation for \${tasksList.length} tasks.');
      final results = <Map<String, dynamic>>[];
      int successCount = 0;

      // Consider Future.wait for parallelism, but be mindful of rate limits
      for (final taskData in tasksList) {
        try {
          final contentText = taskData['content'] as String?;
          if (contentText == null || contentText.trim().isEmpty) {
            results.add({
              'success': false,
              'error': 'Task content cannot be empty.',
              'taskData': taskData
            });
            continue; // Skip this task
          }
          // Parse other fields from taskData map...
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
          stderr.writeln('[TodoistServer] Error creating batch task: \$e');
          String errorMsg = e.toString();
          if (e is todoist.ApiException) {
            errorMsg = 'API Error (\${e.code}): \${e.message ?? "Unknown"}';
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
          ? 'Successfully created \${tasksList.length} tasks.'
          : 'Completed batch task creation with \$successCount successes and \${tasksList.length - successCount} failures.';

      return _createSuccessResult(message,
          resultData: {'summary': summary, 'results': results});
    }
    // --- Single Task Operation ---
    else if (args != null && args.containsKey('content')) {
      final contentText = args['content'] as String?;
      if (contentText == null || contentText.trim().isEmpty) {
        return _createErrorResult('Task content cannot be empty.');
      }
      stderr.writeln('[TodoistServer] Processing single task creation.');
      // Parse other fields from args map...
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
          'Todoist task created successfully: "\${newTask.content}"';
      stderr.writeln('[TodoistServer] \$successMsg (ID: \${newTask.id})');
      // Return relevant task details
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

// Change 2: Implement _handleUpdateTodoistTask handler
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
  final tasksApi = todoist.TasksApi(apiClient);

  try {
    // --- Batch Operation ---
    if (args != null && args.containsKey('tasks') && args['tasks'] is List) {
      final tasksList = (args['tasks'] as List).cast<Map<String, dynamic>>();
      stderr.writeln(
          '[TodoistServer] Processing batch task update for \${tasksList.length} tasks.');
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

          // updateTask expects String taskId
          final taskIdStr = targetTask.id!;

          // Build the update request - only include fields present in taskData
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

          // Check if any update fields were actually provided
          if (request.content == null &&
              request.description == null &&
              request.labels == null &&
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
              'error': 'No update parameters provided for task ID \$taskIdStr.',
              'taskData': taskData
            });
            continue;
          }

          await tasksApi.updateTask(taskIdStr, request);
          // Re-fetch the task to confirm changes (optional but good practice)
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
          stderr.writeln('[TodoistServer] Error updating batch task: \$e');
          String errorMsg = e.toString();
          if (e is todoist.ApiException) {
            errorMsg = 'API Error (\${e.code}): \${e.message ?? "Unknown"}';
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
          ? 'Successfully updated \${tasksList.length} tasks.'
          : 'Completed batch task update with \$successCount successes and \${tasksList.length - successCount} failures.';

      return _createSuccessResult(message,
          resultData: {'summary': summary, 'results': results});
    }
    // --- Single Task Operation ---
    else if (args != null &&
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

      // Check if any update fields were actually provided
      if (request.content == null &&
          request.description == null &&
          request.labels == null &&
          request.priority == null &&
          request.dueString == null &&
          request.dueDate == null &&
          request.dueDatetime == null &&
          request.dueLang == null &&
          request.assigneeId == null &&
          request.duration == null &&
          request.durationUnit == null) {
        return _createErrorResult(
            'No update parameters provided for task ID \$taskIdStr.');
      }

      await tasksApi.updateTask(taskIdStr, request);
      // Re-fetch the task to confirm changes
      final updatedTask = await tasksApi.getActiveTask(int.parse(taskIdStr));

      if (updatedTask == null) {
        return _createErrorResult(
            'Task updated, but failed to re-fetch details for ID \$taskIdStr.');
      }

      final successMsg =
          'Todoist task "\${updatedTask.content}" (ID: \$taskIdStr) updated successfully.';
      stderr.writeln('[TodoistServer] \$successMsg');
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
    var apiErrorMsg = 'Error updating Todoist task(s): \${e.toString()}';
    stderr.writeln('[TodoistServer] \$apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
      apiErrorMsg =
          'API Error updating task(s) (\${e.code}): \${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

// Change 3: Implement _handleGetTodoistTasks handler
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

    // --- Fetching Logic ---
    if (taskIdsArg != null && taskIdsArg.isNotEmpty) {
      stderr.writeln(
          '[TodoistServer] Fetching tasks by specific IDs: \$taskIdsArg');
      for (final idStr in taskIdsArg) {
        try {
          final intId = int.parse(idStr);
          final task = await tasksApi.getActiveTask(intId);
          if (task != null) {
            fetchedTasks.add(task);
          } else {
            stderr.writeln(
                '[TodoistServer] Warning: Task ID \$intId not found or inactive.');
          }
        } catch (e) {
          stderr.writeln(
              '[TodoistServer] Warning: Error fetching task ID \$idStr: \$e');
        }
      }
    } else {
      String effectiveFilter = filterArg ?? '';
      if (effectiveFilter.isEmpty) {
        List<String> filterParts = [];
        if (projectIdArg != null) filterParts.add('#"\$projectIdArg"');
        if (sectionIdArg != null) filterParts.add('/"\$sectionIdArg"');
        if (labelArg != null) filterParts.add('@"\$labelArg"');
        if (contentContainsArg != null)
          filterParts.add('search: "\$contentContainsArg"');
        if (priorityArg != null && priorityArg >= 1 && priorityArg <= 4) {
          filterParts.add('p\$priorityArg');
        }
        effectiveFilter = filterParts.join(' & ');
      }

      stderr.writeln(
          '[TodoistServer] Fetching tasks with filter: "\$effectiveFilter"');
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
          '[TodoistServer] Applying client-side priority filter: p\$priorityArg');
      fetchedTasks =
          fetchedTasks.where((task) => task.priority == priorityArg).toList();
    }

    int finalLimit = fetchedTasks.length;
    if (limitArg != null && limitArg > 0 && limitArg < fetchedTasks.length) {
      stderr.writeln('[TodoistServer] Applying client-side limit: \$limitArg');
      fetchedTasks = fetchedTasks.sublist(0, limitArg);
      finalLimit = limitArg;
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
        'Successfully fetched \${resultTasks.length} Todoist tasks (limited to \$finalLimit).';
    stderr.writeln('[TodoistServer] \$successMsg');
    return _createSuccessResult(
      successMsg,
      resultData: {'tasks': resultTasks},
    );
  } catch (e) {
    var apiErrorMsg = 'Error getting Todoist tasks: \${e.toString()}';
    stderr.writeln('[TodoistServer] \$apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
      apiErrorMsg =
          'API Error getting tasks (\${e.code}): \${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    } else if (e is FormatException) {
      apiErrorMsg = 'Error parsing arguments (likely Task ID): \${e.message}';
      errorData = {'parsingError': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

// Change 4: Implement _handleDeleteTodoistTask handler
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
  final tasksApi = todoist.TasksApi(apiClient);

  try {
    // --- Batch Operation ---
    if (args != null && args.containsKey('tasks') && args['tasks'] is List) {
      final tasksList = (args['tasks'] as List).cast<Map<String, dynamic>>();
      stderr.writeln(
          '[TodoistServer] Processing batch task deletion for \${tasksList.length} tasks.');
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
              '[TodoistServer] Error deleting batch task (ID: \$taskIdToDelete, Identifier: \$taskIdentifier): \$e');
          String errorMsg = e.toString();
          if (e is todoist.ApiException) {
            errorMsg = 'API Error (\${e.code}): \${e.message ?? "Unknown"}';
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
          ? 'Successfully deleted \${tasksList.length} tasks.'
          : 'Completed batch task deletion with \$successCount successes and \${tasksList.length - successCount} failures.';

      return _createSuccessResult(message,
          resultData: {'summary': summary, 'results': results});
    }
    // --- Single Task Operation ---
    else if (args != null &&
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
          'Todoist task (ID: \$taskIdToDelete, identified by: "\$taskIdentifier") deleted successfully.';
      stderr.writeln('[TodoistServer] \$successMsg');
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
    var apiErrorMsg = 'Error deleting Todoist task(s): \${e.toString()}';
    stderr.writeln('[TodoistServer] \$apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
      apiErrorMsg =
          'API Error deleting task(s) (\${e.code}): \${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    } else if (e is FormatException) {
      apiErrorMsg = 'Error parsing arguments (likely Task ID): \${e.message}';
      errorData = {'parsingError': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

// Change 5: Implement handleCompleteTodoistTask handler
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
  final tasksApi = todoist.TasksApi(apiClient);

  try {
    // --- Batch Operation ---
    if (args != null && args.containsKey('tasks') && args['tasks'] is List) {
      final tasksList = (args['tasks'] as List).cast<Map<String, dynamic>>();
      stderr.writeln(
          '[TodoistServer] Processing batch task completion for \${tasksList.length} tasks.');
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
              '[TodoistServer] Error completing batch task (ID: \$taskIdToComplete, Identifier: \$taskIdentifier): \$e');
          String errorMsg = e.toString();
          if (e is todoist.ApiException) {
            errorMsg = 'API Error (\${e.code}): \${e.message ?? "Unknown"}';
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
          ? 'Successfully completed \${tasksList.length} tasks.'
          : 'Completed batch task completion with \$successCount successes and \${tasksList.length - successCount} failures.';

      return _createSuccessResult(message,
          resultData: {'summary': summary, 'results': results});
    }
    // --- Single Task Operation ---
    else if (args != null &&
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
            'Task (ID: \${targetTask.id}, identified by: "\${taskIdArg ?? taskNameArg}") was already completed.';
        stderr.writeln('[TodoistServer] \$msg');
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
          'Todoist task (ID: \$taskIdToComplete, identified by: "\$taskIdentifier") completed successfully.';
      stderr.writeln('[TodoistServer] \$successMsg');
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
    var apiErrorMsg = 'Error completing Todoist task(s): \${e.toString()}';
    stderr.writeln('[TodoistServer] \$apiErrorMsg');
    Map<String, dynamic>? errorData;
    if (e is todoist.ApiException) {
      stderr.writeln(
          '[TodoistServer] API Exception Details: Code=\${e.code}, Message=\${e.message}');
      apiErrorMsg =
          'API Error completing task(s) (\${e.code}): \${e.message ?? "Unknown API error"}';
      errorData = {'apiCode': e.code, 'apiMessage': e.message};
    } else if (e is FormatException) {
      apiErrorMsg = 'Error parsing arguments (likely Task ID): \${e.message}';
      errorData = {'parsingError': e.message};
    }
    return _createErrorResult(apiErrorMsg, errorData: errorData);
  }
}

// Existing Comment Handlers
Future<mcp_dart.CallToolResult> handleGetTaskComments({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received get_task_comments request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not fully implemented yet.');
}

Future<mcp_dart.CallToolResult> handleCreateTaskComment({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra,
}) async {
  stderr.writeln('[TodoistServer] Received create_task_comment request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not fully implemented yet.');
}

// --- Stubs for New Handlers ---

// Project Handlers
Future<mcp_dart.CallToolResult> _handleGetProjects({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_get_projects request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

Future<mcp_dart.CallToolResult> _handleCreateProject({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_create_project request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

Future<mcp_dart.CallToolResult> _handleUpdateProject({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_update_project request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

Future<mcp_dart.CallToolResult> _handleGetProjectSections({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_get_project_sections request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

Future<mcp_dart.CallToolResult> _handleCreateProjectSection({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_create_project_section request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

// Personal Label Handlers
Future<mcp_dart.CallToolResult> _handleGetPersonalLabels({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_get_personal_labels request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

Future<mcp_dart.CallToolResult> _handleCreatePersonalLabel({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_create_personal_label request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

Future<mcp_dart.CallToolResult> _handleGetPersonalLabel({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_get_personal_label request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

Future<mcp_dart.CallToolResult> _handleUpdatePersonalLabel({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_update_personal_label request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

Future<mcp_dart.CallToolResult> _handleDeletePersonalLabel({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_delete_personal_label request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

// Shared Label Handlers
Future<mcp_dart.CallToolResult> _handleGetSharedLabels({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_get_shared_labels request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

Future<mcp_dart.CallToolResult> _handleRenameSharedLabels({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_rename_shared_labels request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

Future<mcp_dart.CallToolResult> _handleRemoveSharedLabels({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_remove_shared_labels request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}

// Task Label Handler
Future<mcp_dart.CallToolResult> _handleUpdateTaskLabels({ Map<String, dynamic>? args, RequestHandlerExtra? extra, }) async {
  stderr.writeln('[TodoistServer] Received todoist_update_task_labels request.');
  stderr.writeln('[TodoistServer] Args: \${jsonEncode(args)}');
  return _createErrorResult('Handler not implemented yet.');
}
