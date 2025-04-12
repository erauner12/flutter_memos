import 'dart:async';
import 'dart:io'; // For exit(), stdout, stderr, ProcessSignal, Platform

// Import all necessary MCP components from the main library file
import 'package:mcp_dart/mcp_dart.dart';
// Explicitly import the file containing RequestHandlerExtra as a workaround
import 'package:mcp_dart/src/shared/protocol.dart' show RequestHandlerExtra;

// Define the echo tool callback function
FutureOr<CallToolResult> _handleEcho({
  Map<String, dynamic>? args,
  RequestHandlerExtra? extra, // Contains client info if needed
}) {
  final message = args?['message'] as String?;
  // Log to stderr
  stderr.writeln("[EchoServer] Received echo request. Message: '$message'");

  if (message == null) {
    // Log error to stderr
    stderr.writeln("[EchoServer] Error: Missing 'message' argument.");
    // Return an error result
    return const CallToolResult(
      content: [TextContent(text: "Error: Missing 'message' argument.")],
      isError: true,
    );
  }

  final resultText = "You said: $message";
  // Log response to stderr
  stderr.writeln("[EchoServer] Sending echo response: '$resultText'");

  // Return the successful result
  return CallToolResult(
    content: [TextContent(text: resultText)],
    isError: false, // Explicitly false for success
  );
}

Future<void> main(List<String> args) async {
  // Log startup to stderr
  stderr.writeln("[EchoServer] Starting MCP Echo Server...");

  // Define server information
  final serverInfo = const Implementation(
    name: 'flutter-memos-echo-server',
    version: '0.1.0',
  );

  // Instantiate McpServer
  final mcpServer = McpServer(serverInfo);

  // Register the 'echo' tool
  mcpServer.tool(
    'echo', // Tool name
    description: 'Echoes back the provided message.',
    inputSchemaProperties: { // Defines the expected input structure
      'message': {
        'type': 'string',
        'description': 'The message to echo back.',
      },
      // Note: MCP server currently doesn't enforce 'required',
      // but defining it helps clients like Gemini. Consider adding 'required': ['message']
      // if the schema format evolves to support it directly in mcp_dart's ToolInputSchema.
    },
    callback: _handleEcho, // The function to execute
  );
  // Log tool registration to stderr
  stderr.writeln("[EchoServer] 'echo' tool registered.");

  // Instantiate the stdio transport
  final transport = StdioServerTransport();
  // Log transport creation to stderr
  stderr.writeln("[EchoServer] Stdio transport created.");

  // Set up graceful shutdown handler
  Future<void> shutdown() async {
    // Log shutdown initiation to stderr
    stderr.writeln("\n[EchoServer] Shutting down...");
    try {
      await mcpServer.close(); // Close the MCP connection first
      // Log server close to stderr
      stderr.writeln("[EchoServer] MCP Server closed.");
    } catch (e) {
      // Log error during close to stderr
      stderr.writeln("[EchoServer] Error during MCP server close: $e");
    }
    // Note: StdioServerTransport doesn't have an explicit close method,
    // closing the underlying process handles it.
    // Log exit to stderr
    stderr.writeln("[EchoServer] Exiting.");
    exit(0); // Exit the process
  }

  // Watch for termination signals
  ProcessSignal.sigint.watch().listen((_) async {
    // Log signal receipt to stderr
    stderr.writeln("[EchoServer] SIGINT received.");
    await shutdown();
  });

  // SIGTERM might not be available on Windows, handle gracefully
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) async {
      // Log signal receipt to stderr
      stderr.writeln("[EchoServer] SIGTERM received.");
      await shutdown();
    });
  }
  // Log signal handler registration to stderr
  stderr.writeln("[EchoServer] Signal handlers registered.");

  // Connect the server to the transport
  try {
    await mcpServer.connect(transport);
    // Log successful connection to stderr
    stderr.writeln(
      "[EchoServer] Server connected to stdio transport. Ready for connections.",
    );
    // Explicitly flush stdout to ensure the initial message is sent immediately.
    // This might be necessary when running as a subprocess.
    stdout.flush();
    // Keep the server running indefinitely until a signal is received
    // The transport listener runs in the background.
  } catch (e, s) {
    // Log connection failure to stderr
    stderr.writeln("[EchoServer] Failed to connect: $e\n$s");
    exit(1); // Exit if connection fails
  }
}
