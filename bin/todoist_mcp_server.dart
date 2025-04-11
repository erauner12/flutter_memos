import 'dart:async';
import 'dart:convert'; // For jsonEncode if needed for debugging args
import 'dart:io';

import 'package:flutter_memos/services/todoist_api_service.dart';
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;
// Add import for http package
import 'package:http/http.dart' as http;
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
    // required: ['content'],
    callback: _handleCreateTodoistTask, // Use a separate handler function
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
    stderr.writeln('[TodoistServer] Registered tools: create_todoist_task');
  } catch (e) {
    stderr.writeln('[TodoistServer] Failed to connect to transport: $e');
    exit(1);
  }
}

// Handler function for the 'create_todoist_task' tool
Future<mcp_dart.CallToolResult> _handleCreateTodoistTask({
  Map<String, dynamic>? args,
  dynamic extra, // Not used here, but part of the signature
}) async {
  stderr.writeln('[TodoistServer] Received create_todoist_task request.');
  stderr.writeln('[TodoistServer] Args: ${jsonEncode(args)}'); // Log received args

  // 1. Retrieve API Token from environment
  final apiToken = Platform.environment['TODOIST_API_TOKEN'];

  if (apiToken == null || apiToken.isEmpty) {
    final errorMsg = 'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(
      content: [mcp_dart.TextContent(text: errorMsg)],
    );
  }

  // 2. Configure the Todoist Service
  // Check if already configured with the same token to avoid redundant initialization
  // Note: Accessing the actual token stored in the service isn't directly possible here.
  // We rely on the configureService method being idempotent or cheap to call repeatedly.
  stderr.writeln('[TodoistServer] Configuring TodoistApiService with provided token.');
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
       final errorMsg = 'Error: Todoist API health check failed with the provided token.';
       stderr.writeln('[TodoistServer] $errorMsg');
       return mcp_dart.CallToolResult(
         content: [mcp_dart.TextContent(text: errorMsg)],
       );
    }
    stderr.writeln('[TodoistServer] TodoistApiService configured and health check passed.');
  } catch (e) {
     final errorMsg = 'Error configuring TodoistApiService: ${e.toString()}';
     stderr.writeln('[TodoistServer] $errorMsg');
     return mcp_dart.CallToolResult(
       content: [mcp_dart.TextContent(text: errorMsg)],
     );
  }


  // 3. Parse Arguments
  final content = args?['content'] as String?;
  if (content == null || content.trim().isEmpty) {
    const errorMsg = 'Error: Task content cannot be empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return const mcp_dart.CallToolResult(
      content: [mcp_dart.TextContent(text: errorMsg)],
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

  // Construct Due object if any due fields are present
  todoist.TaskDue? due;
  if (dueString != null || dueDate != null || dueDatetime != null) {
    // Basic parsing - assumes valid formats. Add more robust parsing if needed.
    DateTime? parsedDueDate;
    DateTime? parsedDueDateTime;
    try {
      if (dueDate != null) parsedDueDate = DateTime.parse(dueDate);
      if (dueDatetime != null) parsedDueDateTime = DateTime.parse(dueDatetime);
    } catch (e) {
       stderr.writeln('[TodoistServer] Warning: Could not parse due date/datetime: $e');
       // Decide how to handle parse errors - ignore, return error, etc.
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

  // 4. Call Todoist API
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
        'Todoist task created successfully: "${newTask.content}" (ID: ${newTask.id})';
    stderr.writeln('[TodoistServer] $successMsg');
    return mcp_dart.CallToolResult(
      content: [mcp_dart.TextContent(text: successMsg)],
    );
  } catch (e) {
    final errorMsg = 'Error creating Todoist task: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    // Consider checking for specific API errors (e.g., invalid token)
    if (e is todoist.ApiException) {
       stderr.writeln('[TodoistServer] API Exception Details: Code=${e.code}, Message=${e.message}, Body=${e.innerException}');
       // Try to decode body if available
       String responseBody = '';
      // Use http.Response here
      if (e.innerException is http.Response) {
         try {
          // Use http.Response here
          final bodyBytes = (e.innerException as http.Response).bodyBytes;
          responseBody = utf8.decode(bodyBytes);
            stderr.writeln('[TodoistServer] API Response Body: $responseBody');
         } catch (decodeError) {
            stderr.writeln('[TodoistServer] Could not decode API response body.');
         }
       }
       return mcp_dart.CallToolResult(
         content: [mcp_dart.TextContent(text: 'API Error (${e.code}): ${e.message}')],
       );
    }
    return mcp_dart.CallToolResult(
      content: [mcp_dart.TextContent(text: errorMsg)],
    );
  }
}
