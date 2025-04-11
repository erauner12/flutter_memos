# Creating and Integrating MCP Servers with Flutter Memos

This guide explains how to create a new Model Controller Protocol (MCP) server using the `mcp_dart` library, compile it into a standalone executable, and integrate it with the Flutter Memos application for local testing and development.

## 1. Purpose of MCP Servers

MCP servers act as external processes that Flutter Memos can communicate with to perform specific tasks, often involving external APIs, local computations, or interactions that shouldn't block the main Flutter application thread. They expose "tools" that the application (or potentially an AI model integrated with the app) can call.

In Flutter Memos, MCP servers are managed via the Settings -> MCP Servers screen. The application connects to active servers using standard input/output (stdio) by launching the configured executable.

## 2. Creating a New MCP Server Project

It's recommended to create a separate Dart project for each MCP server.

1.  **Create a new Dart project:**
    ```bash
    # Navigate to a suitable location (e.g., alongside flutter_memos)
    cd /path/to/your/projects/
    dart create -t console my_new_mcp_server
    cd my_new_mcp_server
    ```

2.  **Add `mcp_dart` dependency:**
    Open `pubspec.yaml` in your new project and add `mcp_dart`. You can use a path dependency if you have a local checkout, or fetch from pub.dev if it's published.

    *Example using a path dependency (adjust path as needed):*
    ```yaml
    name: my_new_mcp_server
    description: A new MCP server example.
    version: 1.0.0
    # repository: https://github.com/my_org/my_repo

    environment:
      sdk: '>=3.0.0 <4.0.0' # Adjust SDK constraint as needed

    dependencies:
      mcp_dart:
        path: ../mcp_dart # Path to your local mcp_dart checkout

    dev_dependencies:
      lints: ^3.0.0
      test: ^1.24.0
    ```

    *Example using pub.dev (replace with actual version if published):*
    ```yaml
    dependencies:
      mcp_dart: ^0.3.2 # Or the latest version
    ```

3.  **Fetch dependencies:**
    ```bash
    dart pub get
    ```

## 3. Writing the Server Code

Replace the contents of `bin/my_new_mcp_server.dart` (or `bin/main.dart` if created that way) with your server logic. Here's a minimal example:

```dart
// bin/my_new_mcp_server.dart
import 'dart:io'; // Required for stderr
import 'package:mcp_dart/mcp_dart.dart';

void main() async {
  // 1. Create the McpServer instance
  // Provide basic info about your server.
  final server = McpServer(
    Implementation(name: "my-new-server", version: "1.0.0"),
    options: ServerOptions(
      // Advertise capabilities (optional but good practice)
      capabilities: ServerCapabilities(
        tools: ServerCapabilitiesTools(), // Indicate tool support
      ),
    ),
  );

  // 2. Register Tools
  // Define the tools your server provides.
  server.tool(
    'greet', // Tool name
    description: 'Returns a simple greeting.', // Tool description
    // Define input schema (optional, empty object {} if no args)
    inputSchemaProperties: {
      'name': {
        'type': 'string',
        'description': 'The name to greet.',
      },
    },
    // The callback function that executes the tool logic
    callback: ({args, extra}) async {
      final name = args?['name'] as String? ?? 'World';
      final greeting = 'Hello, $name! This message is from my_new_mcp_server.';

      // Log to stderr for debugging (visible in Flutter Memos console)
      stderr.writeln('[MyNewServer] Received greet request. Name: \'$name\'');
      stderr.writeln('[MyNewServer] Sending greeting response.');

      // Return the result using CallToolResult
      return CallToolResult(
        content: [
          TextContent(text: greeting), // Use TextContent for string results
        ],
      );
    },
  );

  // Add more tools here using server.tool(...)

  // 3. Connect to the Transport
  // For Flutter Memos integration, use StdioServerTransport.
  final transport = StdioServerTransport();
  await server.connect(transport);

  // Log that the server is ready (goes to stderr)
  stderr.writeln('[MyNewServer] MCP Server running on stdio, ready for connections.');
  stderr.writeln('[MyNewServer] Registered tools: greet');

  // The server will now run until the client disconnects or the process is terminated.
}
```

## 4. Compiling the Server to an Executable

To integrate with Flutter Memos, you need a standalone executable.

1.  **Compile:**
    Navigate to your server project directory (`my_new_mcp_server`) in the terminal.
    ```bash
    dart compile exe bin/my_new_mcp_server.dart -o bin/my_new_mcp_server_executable
    ```
    *   `-o bin/my_new_mcp_server_executable`: Specifies the output path and filename for the executable. Placing it in the `bin` directory is conventional.

2.  **Verify Permissions (macOS/Linux):**
    Ensure the compiled file has execute permissions.
    ```bash
    chmod +x bin/my_new_mcp_server_executable
    ```

3.  **Test Manually (Optional):**
    You can try running it directly. It should print the stderr messages and wait for input.
    ```bash
    ./bin/my_new_mcp_server_executable
    ```
    Press `Ctrl+C` to exit.

## 5. Configuring in Flutter Memos

1.  **Get Absolute Path:**
    You need the full, absolute path to the executable you just compiled.
    In your server project's `bin` directory, run:
    ```bash
    pwd
    ```
    Copy the output and append `/my_new_mcp_server_executable`.
    *Example:* `/Users/yourname/projects/my_new_mcp_server/bin/my_new_mcp_server_executable`

2.  **Add Server in App:**
    *   Run the Flutter Memos app (`flutter run -d <your_device_id>`).
    *   Go to `Settings` -> `MCP Servers`.
    *   Tap the `+` button to add a new server.
    *   **Name:** Give it a descriptive name (e.g., "My New Server").
    *   **Command:** Paste the **absolute path** to the executable.
    *   **Arguments:** Leave this **empty** for this simple example.
    *   **Connect on Apply:** Toggle this **ON**.
    *   **Custom Environment Variables:** Leave empty for now unless your server needs specific variables.
    *   Tap `Save`.

3.  **Apply Changes:**
    Back on the MCP Servers list screen, tap "**Apply Changes**" in the header.

## 6. Testing the Integration

1.  **Check Connection Logs:**
    Observe the `flutter run` console output. You should see logs indicating Flutter Memos is attempting to connect:
    ```
    flutter: GoogleMcpClient [server-id]: Attempting connection: /path/to/your/executable
    flutter: StdioClientTransport: Preparing to start process...
    flutter: StdioClientTransport: Process start attempt successful. PID: ...
    flutter: StdioClientTransport: Piping server stderr...
    flutter: Server stderr: [MyNewServer] MCP Server running on stdio...
    flutter: MCP Client Initialized. Server: my-new-server 1.0.0...
    flutter: GoogleMcpClient [server-id]: Connected successfully.
    flutter: GoogleMcpClient [server-id]: Fetching tools...
    flutter: GoogleMcpClient [server-id]: Raw tools list result: [{name: greet, ...}]
    flutter: GoogleMcpClient [server-id]: Processed tools for Gemini: [(greet)]
    flutter: MCP [_connectServer - server-id]: Client connected successfully...
    flutter: MCP: Rebuilt tool map. 1 unique tools found: [greet]. Duplicates: []
    ```
    If you see "Operation not permitted" errors, revisit the macOS entitlements/sandbox steps used for the echo server, potentially adding a temporary exception for your new executable's path in `DebugProfile.entitlements` during testing.

2.  **Call the Tool:**
    You need to trigger a call to your new tool (`greet` in this example). The easiest way for testing is to temporarily modify the `McpClientNotifier.processQuery` method in `lib/services/mcp_client_service.dart`:

    *   Find the `processQuery` method.
    *   Locate the section that currently hardcodes the 'echo' tool call.
    *   Change `'echo'` to `'greet'` and adjust the arguments map.

    *Example Modification:*
    ```diff
    --- a/lib/services/mcp_client_service.dart
    +++ b/lib/services/mcp_client_service.dart
    @@ -730,14 +730,16 @@
       }

       // Find the server providing the 'echo' tool
    -  final targetServerId = toolToServerIdMap['echo'];
    +  // *** TEMPORARY TEST: Change 'echo' to 'greet' ***
    +  final toolToCall = 'greet';
    +  final targetServerId = toolToServerIdMap[toolToCall];
       // *** ADD LOGGING HERE ***
       debugPrint(
    -    "MCP ProcessQuery: Looked up 'echo' tool. Found Server ID: $targetServerId. Current tool map: $toolToServerIdMap",
    +    "MCP ProcessQuery: Looked up '$toolToCall' tool. Found Server ID: $targetServerId. Current tool map: $toolToServerIdMap",
       );
       if (targetServerId == null) {
         debugPrint(
    -      "MCP ProcessQuery: 'echo' tool not found in map: $toolToServerIdMap",
    +      "MCP ProcessQuery: '$toolToCall' tool not found in map: $toolToServerIdMap",
         );
         return McpProcessResult(
           finalModelContent: Content('model', [
    @@ -752,11 +754,11 @@
       debugPrint(
         "MCP ProcessQuery: Checking target client for server '$targetServerId'. Found: ${targetClient != null}, Connected: $isClientConnected",
       );
    -  if (targetClient == null || !targetClient.isConnected) {
    +  if (targetClient == null || !isClientConnected) { // Use checked variable
         debugPrint(
    -      "MCP ProcessQuery: Client for 'echo' tool (Server $targetServerId) is not connected or found.",
    +      "MCP ProcessQuery: Client for '$toolToCall' tool (Server $targetServerId) is not connected or found.",
         );
         // Optionally try to reconnect or update status? For now, return error.
         updateServerState(
    @@ -765,7 +767,7 @@
         );
         return McpProcessResult(
           finalModelContent: Content('model', [
    -        TextPart(
    -          "Error: Client for 'echo' tool (Server $targetServerId) is not connected.",
    -        ),
    +        TextPart("Error: Client for '$toolToCall' tool (Server $targetServerId) is not connected."),
           ]),
           toolName: 'echo',
           sourceServerId: targetServerId,
    @@ -773,13 +775,15 @@
       }

       debugPrint(
    -    "MCP ProcessQuery: Routing 'echo' tool call to server $targetServerId",
    +    "MCP ProcessQuery: Routing '$toolToCall' tool call to server $targetServerId",
       );

       try {
         final params = mcp_dart.CallToolRequestParams(
    -      name: 'echo',
    -      arguments: {'message': query}, // Pass the user's query
    +      name: toolToCall,
    +      // *** TEMPORARY TEST: Provide args for 'greet' ***
    +      // arguments: {'name': query}, // Pass user query as name
    +      arguments: {'name': 'Test User'}, // Or hardcode for simplicity
         );
         final result = await targetClient.callTool(params);

    @@ -790,7 +794,7 @@
           .join('\n'); // Join if multiple TextContent parts

         debugPrint(
    -      "MCP ProcessQuery: Tool 'echo' executed on server $targetServerId. Result: $toolResponseText",
    +      "MCP ProcessQuery: Tool '$toolToCall' executed on server $targetServerId. Result: $toolResponseText",
         );

         // Simulate a simple "model" response containing the tool's output
    @@ -800,14 +804,14 @@
         toolResponseContent: null, // Or construct if needed for history
         // The final content IS the tool's response in this simple case
         finalModelContent: Content('model', [TextPart(toolResponseText)]),
    -    toolName: 'echo',
    +    toolName: toolToCall,
         toolArgs: params.arguments,
         toolResult: toolResponseText,
         sourceServerId: targetServerId,
       );
     } catch (e) {
       final errorMsg =
    -      "Error executing tool 'echo' on server $targetServerId: $e";
    +      "Error executing tool '$toolToCall' on server $targetServerId: $e";
       debugPrint("MCP ProcessQuery: $errorMsg");
       // Update server status to reflect the error during tool call
       updateServerState(
    @@ -818,7 +822,7 @@
         finalModelContent: Content('model', [
           TextPart("Error: $errorMsg"),
         ]),
    -    toolName: 'echo',
    +    toolName: toolToCall,
         sourceServerId: targetServerId,
       );
     }

    ```
    *   **Save** the file. Flutter's hot reload/restart should pick up the change.
    *   Trigger the query in the app (e.g., by sending a message in the chat interface if that's where `processQuery` is called from).

3.  **Verify Tool Output:**
    Check the `flutter run` console again. You should see:
    *   Logs indicating the `greet` tool is being called.
    *   The `stderr` messages from your server (`[MyNewServer] Received greet request...`).
    *   The final result log showing the greeting text (`MCP ProcessQuery: Tool 'greet' executed... Result: Hello, Test User!...`).

4.  **Revert Changes:** Remember to undo the temporary changes made to `McpClientNotifier.processQuery` after testing.

## 7. Example: Todoist MCP Server

Let's walk through creating an MCP server that interacts with the Todoist API using the existing `TodoistApiService` within Flutter Memos.

**Goal:** Create a server (`bin/todoist_mcp_server.dart`) that exposes a `create_todoist_task` tool.

**Key Differences from Simple Example:**

*   **API Token:** The server needs the user's Todoist API token. Instead of hardcoding or asking the user to configure it in the MCP Server settings UI, the Flutter Memos app will securely pass the token (retrieved from its own settings) to the server process via an **environment variable** named `TODOIST_API_TOKEN`.
*   **Using Existing Service:** The server code will import and use `package:flutter_memos/services/todoist_api_service.dart` to avoid duplicating API logic.

**Server Code (`bin/todoist_mcp_server.dart`):**

```dart
// bin/todoist_mcp_server.dart
import 'dart:async';
import 'dart:convert'; // For jsonEncode if needed for debugging args
import 'dart:io';

// Crucial: Import the existing service and API models from the main app
import 'package:flutter_memos/services/todoist_api_service.dart';
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;
import 'package:mcp_dart/mcp_dart.dart' as mcp_dart;

// Global instance of the service
final todoistService = TodoistApiService();

void main() async {
  // Configure verbose logging for the service if desired
  TodoistApiService.verboseLogging = true;

  final server = mcp_dart.McpServer(
      mcp_dart.Implementation(name: "todoist-server", version: "1.0.0"),
      options: mcp_dart.ServerOptions(
        // Advertise capabilities (optional but good practice)
        capabilities: mcp_dart.ServerCapabilities(
          tools: mcp_dart.ServerCapabilitiesTools(), // Indicate tool support
        ),
      ),
  );

  // Register the 'create_todoist_task' tool
  server.tool(
    'create_todoist_task',
    description: 'Creates a new task in Todoist using the configured API key.',
    inputSchemaProperties: {
      'content': {'type': 'string', 'description': 'Task content (required).'},
      'description': {'type': 'string', 'description': 'Detailed description (optional).'},
      // Add other relevant properties like project_id, labels, priority, due_string etc.
      // Match the parameters expected by TodoistApiService.createTask
    },
    // required: ['content'], // Optional: Define required fields
    // required: ['content'], // Optional: Define required fields
    callback: _handleCreateTodoistTask, // Use a separate handler
  );

  // Register the 'update_todoist_task' tool
  // ... (update tool definition as needed) ...

  // Register the 'get_todoist_tasks' tool
   server.tool(
     'get_todoist_tasks',
     description: 'Retrieves active Todoist tasks. Use EITHER `filter` for complex queries OR `content_contains` for simple text search.',
     inputSchemaProperties: {
       'filter': {
         'type': 'string',
         'description': 'Full Todoist filter query (e.g., "today & #Work", "p1", "search: keyword"). Takes precedence over content_contains. Optional.',
       },
       'content_contains': {
          'type': 'string',
          'description': 'Search for tasks whose content includes this text (ignored if `filter` is provided). Optional.',
       },
     },
     callback: _handleGetTodoistTasks, // Assumes this handler exists
   );


  final transport = mcp_dart.StdioServerTransport();
  // Add signal handling (SIGINT, SIGTERM) here...

  try {
    await server.connect(transport);
    stderr.writeln('[TodoistServer] MCP Server running on stdio...');
    // Update this line if you add more tools
    stderr.writeln('[TodoistServer] Registered tools: create_todoist_task, update_todoist_task, get_todoist_tasks');
  } catch (e) {
    stderr.writeln('[TodoistServer] Failed to connect: $e');
    exit(1);
  }
}

// Handler function for the tool
Future<mcp_dart.CallToolResult> _handleCreateTodoistTask({
  Map<String, dynamic>? args,
  dynamic extra,
}) async {
  stderr.writeln('[TodoistServer] Received create_todoist_task request.');

  // 1. Get API Token from Environment Variable
  final apiToken = Platform.environment['TODOIST_API_TOKEN'];
  if (apiToken == null || apiToken.isEmpty) {
    final errorMsg = 'Error: TODOIST_API_TOKEN environment variable not set or empty.';
    stderr.writeln('[TodoistServer] $errorMsg');
    return mcp_dart.CallToolResult(content: [mcp_dart.TextContent(text: errorMsg)]);
  }

  // 2. Configure the Service (can add checks to avoid re-configuring if token hasn't changed)
  try {
    todoistService.configureService(authToken: apiToken);
    if (!await todoistService.checkHealth()) {
       throw Exception('Todoist API health check failed.');
    }
    stderr.writeln('[TodoistServer] TodoistApiService configured and health check passed.');
  } catch (e) {
     final errorMsg = 'Error configuring TodoistApiService: ${e.toString()}';
     stderr.writeln('[TodoistServer] $errorMsg');
     return mcp_dart.CallToolResult(content: [mcp_dart.TextContent(text: errorMsg)]);
  }

  // 3. Parse Arguments from 'args' map
  final content = args?['content'] as String?;
  if (content == null || content.trim().isEmpty) {
    // Return error result...
  }
  // ... parse other arguments (description, projectId, labels, etc.) ...
  // Construct TaskDue object if needed

  // 4. Call the Todoist API Service
  try {
    stderr.writeln('[TodoistServer] Calling todoistService.createTask...');
    final newTask = await todoistService.createTask(
      content: content!,
      // Pass other parsed arguments...
    );
    final successMsg = 'Todoist task created: "${newTask.content}" (ID: ${newTask.id})';
    stderr.writeln('[TodoistServer] $successMsg');
    return mcp_dart.CallToolResult(content: [mcp_dart.TextContent(text: successMsg)]);
  } catch (e) {
    final errorMsg = 'Error creating Todoist task: ${e.toString()}';
    stderr.writeln('[TodoistServer] $errorMsg');
    // Return error result, potentially checking e for ApiException details
    return mcp_dart.CallToolResult(content: [mcp_dart.TextContent(text: errorMsg)]);
  }
}

```

**Flutter App Modification (`lib/services/mcp_client_service.dart`):**

The `McpClientNotifier.connectServer` method needs to be modified to fetch the Todoist API token (e.g., from `ref.read(todoistApiKeyProvider)`) and add it to the `environment` map passed to `StdioClientTransport`.

```diff
--- a/lib/services/mcp_client_service.dart
+++ b/lib/services/mcp_client_service.dart
@@ -418,10 +418,19 @@
     GoogleMcpClient? newClientInstance;

     try {
+      // Fetch Todoist token using the provider
+      final todoistApiToken = ref.read(todoistApiKeyProvider); // Read the current token value
+
       // Use only the custom environment defined in the config
       final Map<String, String> environmentToPass =
           serverConfig.customEnvironment;
+
       // Optional: Log the environment being passed (mask sensitive values)
+      environmentToPass['TODOIST_API_TOKEN'] = todoistApiToken;
+
+      // Log the environment being passed (mask sensitive values)
+      debugPrint("MCP [$serverId]: Launching with environment: $environmentToPass");
+
       final command = serverConfig.command;
       final argsList =
@@ -439,7 +448,7 @@
         command,
         argsList,
         // Pass the combined environment map here
-        environmentToPass,
+        environmentToPass, // Pass the map with the token
       );

       if (newClientInstance.isConnected) {

```

**Configuration in Flutter Memos UI:**

*   Add the server as described in section 5.
*   **Command:** Absolute path to the compiled `todoist_mcp_server_executable`.
*   **Custom Environment Variables:** Leave this section **empty** in the UI, as the token is now passed programmatically by the app.

**Testing:**

*   Verify connection logs.
*   Temporarily modify `McpClientNotifier.processQuery` to call `create_todoist_task` with sample arguments (e.g., `{'content': 'Test from MCP', 'labels': ['test']}`).
*   Check your Todoist account and the app console for results.
*   **Remember to revert the temporary changes in `processQuery`.**

This approach keeps the API token secure within the Flutter app's storage and injects it only when launching the dedicated server process.

## 8. Release Considerations

*   **Bundling:** For a distributable macOS app, you cannot rely on absolute paths outside the app bundle. You would need to copy your compiled server executable into the app bundle during the build process (e.g., into `YourApp.app/Contents/Helpers/`) and adjust the command path in Flutter Memos to use a relative path or `@executable_path`.
*   **Entitlements:** Release builds require the sandbox to be enabled. You will need to add specific entitlements to `Release.entitlements` to allow your main app to launch the bundled helper executable. This often involves `com.apple.security.app-sandbox` and potentially related helper tool entitlements. Temporary exceptions are not allowed in App Store builds.
*   **Code Signing:** Both the main app and the helper executable must be properly code-signed for distribution.

This guide provides the basics for creating and testing local MCP servers during development. Production deployment requires careful handling of bundling, entitlements, and code signing.
