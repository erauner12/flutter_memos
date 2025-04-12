import 'dart:async';
import 'dart:io'; // For Platform, HttpServer, InternetAddress, stderr

import 'package:mcp_dart/mcp_dart.dart' as mcp;
// Import necessary components from mcp_dart
import 'package:mcp_dart/src/server/sse_server_manager.dart';
import 'package:mcp_dart/src/shared/protocol.dart' show RequestHandlerExtra;
// Remove shelf imports
// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as shelf_io;

// --- Tool Callback ---
FutureOr<mcp.CallToolResult> _handleGetServerTime({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra, // Contains client info if needed
}) {
  final now = DateTime.now().toUtc().toIso8601String();
  stderr.writeln(
      "[TimeServer] Received get_server_time request from session: ${extra?.sessionId ?? 'unknown'}");
  final resultText = '{"currentTime": "$now"}'; // Return JSON string
  stderr.writeln("[TimeServer] Sending time response: $resultText");
  return mcp.CallToolResult(
    content: [mcp.TextContent(text: resultText)],
    isError: false,
  );
}

// --- MCP Server Setup ---
final serverInfo = const mcp.Implementation(
  name: 'flutter-memos-sse-time-server-manager', // Updated name slightly
  version: '0.1.0',
);
final mcpServer = mcp.McpServer(serverInfo);

// --- Main Function ---
Future<void> main(List<String> args) async {
  stderr.writeln(
      "[TimeServer] Starting MCP SSE Time Server (using SseServerManager)...");

  // Register the tool with the McpServer instance
  mcpServer.tool(
    'get_server_time',
    description: 'Gets the current UTC time from the server.',
    inputSchemaProperties: {}, // No input arguments needed
    callback: _handleGetServerTime,
  );
  stderr.writeln("[TimeServer] 'get_server_time' tool registered.");

  // --- Setup SseServerManager ---
  // It will handle requests to /sse and /messages internally
  final sseManager = SseServerManager(
    mcpServer,
    ssePath: '/sse', // Path for clients to establish SSE connection
    messagePath: '/messages', // Path for clients to POST messages
  );

  // --- HTTP Server Start ---
  final port = int.tryParse(Platform.environment['PORT'] ?? '8999') ?? 8999;

  // Use dart:io HttpServer directly
  final server = await HttpServer.bind(
    InternetAddress.anyIPv4, // Listen on all interfaces
    port,
  );

  stderr.writeln(
      '[TimeServer] Serving MCP over SSE (GET ${sseManager.ssePath}) and HTTP (POST ${sseManager.messagePath}) at http://${server.address.host}:${server.port}');

  // Listen for incoming requests and delegate to SseServerManager
  server.listen(
    (HttpRequest request) {
      // No need for shelf Pipeline or logRequests middleware here
      // Logging can be added manually if desired:
      // stderr.writeln('[TimeServer] Request: ${request.method} ${request.uri}');
      sseManager.handleRequest(request).catchError((e, s) {
        stderr.writeln(
            '[TimeServer] Error handling request ${request.uri}: $e\n$s');
        // Attempt to close the response if possible and not already closed
        try {
          if (!request.response.headers.persistentConnection) {
            request.response.statusCode = HttpStatus.internalServerError;
            request.response.write('Internal Server Error');
            request.response.close();
          }
        } catch (_) {
          // Ignore errors during error response sending
        }
      });
    },
    onError: (e, s) {
      stderr.writeln('[TimeServer] HttpServer error: $e\n$s');
    },
    onDone: () {
      stderr.writeln('[TimeServer] HttpServer closed.');
    },
  );


  // --- Graceful Shutdown ---
  Future<void> shutdown() async {
    stderr.writeln("\n[TimeServer] Shutting down...");
    try {
      // Close active SSE connections managed by the manager
      await Future.wait(
        sseManager.activeSseTransports.values.map((t) => t.close()),
      );
      stderr.writeln("[TimeServer] Active SSE transports closed.");
      await server.close(force: true); // Close HTTP server
      stderr.writeln("[TimeServer] HTTP server closed.");
      // McpServer itself doesn't hold resources like transports,
      // but closing transports handles cleanup.
      // await mcpServer.close(); // Not strictly needed if transports are closed
    } catch (e) {
      stderr.writeln("[TimeServer] Error during shutdown: $e");
    }
    stderr.writeln("[TimeServer] Exiting.");
    exit(0);
  }

  ProcessSignal.sigint.watch().listen((_) async {
    stderr.writeln("[TimeServer] SIGINT received.");
    await shutdown();
  });
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) async {
      stderr.writeln("[TimeServer] SIGTERM received.");
      await shutdown();
    });
  }
  stderr.writeln("[TimeServer] Signal handlers registered.");

} // End of main
