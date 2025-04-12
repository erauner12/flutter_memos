import 'dart:async';
import 'dart:convert'; // For jsonEncode/Decode
import 'dart:io'; // For Platform, HttpServer, InternetAddress

import 'package:mcp_dart/mcp_dart.dart' as mcp;
// Explicitly import the file containing RequestHandlerExtra if needed by callbacks
import 'package:mcp_dart/src/shared/protocol.dart' show RequestHandlerExtra;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

// --- Custom EventSource/SSE implementation ---
class EventSourceConnection {
  final String clientId;
  final StreamController<String> _controller = StreamController<String>();
  final StreamSink<String> sink;
  final Stream<String> stream;

  EventSourceConnection(this.clientId)
    : sink = StreamController<String>().sink,
      stream = StreamController<String>().stream;

  void send(String event, {String? eventType}) {
    var message = '';
    if (eventType != null) {
      message += 'event: $eventType\n';
    }
    message += 'data: $event\n\n';
    _controller.add(message);
  }

  Future<void> close() async {
    await _controller.close();
  }
}

Response eventSourceHandler(
  Request request,
  void Function(EventSourceConnection) onConnection,
) {
  final clientId = request.connectionInfo?.remoteAddress.address ?? 'unknown';
  final connection = EventSourceConnection(clientId);

  onConnection(connection);

  return Response.ok(
    connection._controller.stream.transform(
      StreamTransformer<String, List<int>>.fromHandlers(
        handleData: (data, sink) {
          sink.add(utf8.encode(data));
        },
      ),
    ),
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  );
}

// --- Tool Callback ---
FutureOr<mcp.CallToolResult> _handleGetServerTime({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra, // Contains client info if needed
}) {
  final now = DateTime.now().toUtc().toIso8601String();
  stderr.writeln("[TimeServer] Received get_server_time request.");
  final resultText = '{"currentTime": "$now"}'; // Return JSON string
  stderr.writeln("[TimeServer] Sending time response: $resultText");
  return mcp.CallToolResult(
    content: [mcp.TextContent(text: resultText)],
    isError: false,
  );
}

// --- MCP Server Setup ---
final serverInfo = const mcp.Implementation(
  name: 'flutter-memos-sse-time-server',
  version: '0.1.0',
);
final mcpServer = mcp.McpServer(serverInfo);

// --- Main Function ---
Future<void> main(List<String> args) async {
  stderr.writeln("[TimeServer] Starting MCP SSE Time Server...");

  // Register the tool
  mcpServer.tool(
    'get_server_time',
    description: 'Gets the current UTC time from the server.',
    inputSchemaProperties: {}, // No input arguments needed
    callback: _handleGetServerTime,
  );
  stderr.writeln("[TimeServer] 'get_server_time' tool registered.");

  // --- HTTP Router Setup ---
  final router = Router();

  // EventSource Handler for /mcp endpoint
  router.get('/mcp', (Request request) {
    stderr.writeln("[TimeServer] EventSource connection request received from ${request.headers['x-forwarded-for'] ?? request.connectionInfo?.remoteAddress.address}");

    // Use custom eventSourceHandler
    return eventSourceHandler(request, (EventSourceConnection connection) {
      final clientId = connection.clientId; // Simple unique ID per connection
      stderr.writeln("[TimeServer] EventSource Client [$clientId] connected.");

      // Listen for messages FROM the client (over EventSource/SSE)
      // Note: Standard SSE doesn't support client-to-server messages this way.
      // This listener might not receive anything unless the client uses a separate
      // mechanism (like POST) to send data, which is typical for MCP over SSE.
      // We'll keep the listener structure for potential future use or custom client behavior,
      // but the primary way MCP expects client messages is via POST requests handled elsewhere.
      connection.stream.listen(
        (message) async {
          // This block might not be reached with standard SSE clients sending data.
          stderr.writeln("[TimeServer] EventSource Client [$clientId] sent (via stream, unusual for SSE): $message");
          // If messages *were* received here, process them:
          // await _processClientMessage(message, clientId, connection);
        },
        onDone: () {
          stderr.writeln("[TimeServer] EventSource Client [$clientId] disconnected.");
          // Perform any cleanup needed for this specific client connection
        },
        onError: (error) {
          stderr.writeln("[TimeServer] Error on EventSource stream for Client [$clientId]: $error");
          // Connection likely closed uncleanly
        },
        cancelOnError: true,
      );

      // Example: Send a welcome notification TO the client (standard SSE usage)
      // final welcomeNotification = mcp.McpNotification(
      //   method: 'server/status',
      //   params: {'message': 'Welcome to the Time Server! Use POST for requests.'},
      // );
      // connection.sink.add(jsonEncode(welcomeNotification.toJson()));
      // stderr.writeln("[TimeServer] Sent welcome notification to Client [$clientId]");

    }); // End of eventSourceHandler
  }); // End of router.get('/mcp')

  // --- Add a POST handler for receiving MCP requests ---
  router.post('/mcp', (Request request) async {
    final clientId = request.connectionInfo?.remoteAddress.address ?? 'unknown'; // Identify client
    final body = await request.readAsString();
    stderr.writeln("[TimeServer] Received POST request from Client [$clientId] with body: $body");

    try {
      final mcp.McpResponse? response = await mcpServer.handleRequestString(
        body,
        // Optionally pass client-specific context if needed by callbacks
        // extra: RequestHandlerExtra(clientId: clientId),
      );

      if (response != null) {
        final responseString = jsonEncode(response.toJson());
        stderr.writeln("[TimeServer] Sending response via POST to Client [$clientId]: $responseString");
        // Return the MCP response in the HTTP response body
        return Response.ok(
          responseString,
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        // It was likely a notification, no response needed according to JSON-RPC spec.
        // Return HTTP 204 No Content or 202 Accepted.
        stderr.writeln("[TimeServer] Processed notification via POST from Client [$clientId]. No MCP response sent.");
        return Response.noContent(); // Or Response.accepted()
      }
    } catch (e, s) {
      stderr.writeln("[TimeServer] Error handling POST message from Client [$clientId]: $e\n$s");
      try {
        final errorResponse = mcp.McpResponse.invalidRequest(
          id: null, // ID might not be available if parsing failed early
          message: "Server error processing request: ${e.toString()}",
        );
        return Response.internalServerError(
          body: jsonEncode(errorResponse.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (sendError) {
         stderr.writeln("[TimeServer] Failed to format error response for Client [$clientId]: $sendError");
         return Response.internalServerError(body: 'Internal Server Error');
      }
    }
  }); // End of router.post('/mcp')


  // --- HTTP Server Start ---
  final port = int.tryParse(Platform.environment['PORT'] ?? '8999') ?? 8999;
  final cascade = Cascade().add(router).handler; // Use the router
  final handler = const Pipeline()
      .addMiddleware(logRequests()) // Optional: Log requests
      .addHandler(cascade);

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4, // Listen on all interfaces
    port,
  );

  stderr.writeln('[TimeServer] Serving MCP over EventSource (GET) and HTTP (POST) at http://${server.address.host}:${server.port}/mcp');

  // --- Graceful Shutdown ---
   Future<void> shutdown() async {
     stderr.writeln("\n[TimeServer] Shutting down...");
     try {
       await server.close(force: true); // Close HTTP server
       stderr.writeln("[TimeServer] HTTP server closed.");
       await mcpServer.close(); // Close MCP server logic (if it holds resources)
       stderr.writeln("[TimeServer] MCP Server logic closed.");
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
