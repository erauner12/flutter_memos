import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Required for Uint8List

import 'package:args/args.dart';

// Configuration mapping tool names to the command to run the stdio server
// These paths point to locations *inside* the Docker container
const Map<String, String> toolToServerCommand = {
  // Tool names used in 'callTool' requests
  'echo': '/app/bin/mcp_echo_server_executable', // Example path in Docker
  'create_todoist_task': '/app/bin/todoist_mcp_server_executable',
  'update_todoist_task': '/app/bin/todoist_mcp_server_executable',
  'get_todoist_tasks': '/app/bin/todoist_mcp_server_executable',
  'todoist_delete_task': '/app/bin/todoist_mcp_server_executable',
  'todoist_complete_task': '/app/bin/todoist_mcp_server_executable',
  'get_todoist_task_by_id': '/app/bin/todoist_mcp_server_executable',
  'get_task_comments': '/app/bin/todoist_mcp_server_executable',
  'create_task_comment': '/app/bin/todoist_mcp_server_executable',
  // Add other tools/servers if needed
};

// Configuration for 'listTools' - determines which servers to query
// Using the executable paths as keys for simplicity here
final List<String> serversToListTools = toolToServerCommand.values.toSet().toList();


Future<void> main(List<String> arguments) async {
  // --- Argument Parsing ---
  final parser = ArgParser()..addOption('port', abbr: 'p', defaultsTo: '8999');
  final argResults = parser.parse(arguments);
  final port = int.tryParse(argResults['port'] ?? '8999') ?? 8999;

  // --- Start TCP Server ---
  ServerSocket serverSocket;
  try {
    serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('[TCP Proxy] Listening on port ${serverSocket.port}...');
  } catch (e) {
    print('[TCP Proxy] FATAL: Could not bind to port $port: $e');
    exit(1);
  }

  // --- Handle Incoming Connections ---
  serverSocket.listen(
    (Socket clientSocket) {
      final clientDesc = '${clientSocket.remoteAddress.address}:${clientSocket.remotePort}';
      print('[TCP Proxy] Client connected: $clientDesc');
      handleClient(clientSocket, clientDesc);
    },
    onError: (error) {
      print('[TCP Proxy] Server socket error: $error');
    },
    onDone: () {
      print('[TCP Proxy] Server socket closed.');
    },
  );

   // --- Graceful Shutdown ---
   ProcessSignal.sigint.watch().listen((_) async {
     print('\n[TCP Proxy] SIGINT received, shutting down...');
     await serverSocket.close();
     // TODO: Add logic to gracefully shut down active client handlers/processes
     exit(0);
   });
    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((_) async {
         print('\n[TCP Proxy] SIGTERM received, shutting down...');
         await serverSocket.close();
         // TODO: Add logic to gracefully shut down active client handlers/processes
         exit(0);
      });
   }
}

// --- Client Handling Logic ---
void handleClient(Socket clientSocket, String clientDesc) {
  final buffer = BytesBuilder();
  StreamSubscription? subscription;

  // Map to keep track of running stdio processes for this client connection
  // Key: Request ID, Value: Process
  final Map<dynamic, Process> activeProcesses = {};

  subscription = clientSocket.listen(
    (Uint8List data) {
      buffer.add(data);
      // Attempt to process complete messages (newline-delimited JSON)
      _processClientBuffer(buffer, clientSocket, clientDesc, activeProcesses);
    },
    onError: (error) {
      print('[TCP Proxy] Error from client $clientDesc: $error');
      // Clean up any running processes associated with this client
      for (var process in activeProcesses.values) {
        print('[TCP Proxy] Killing process PID ${process.pid} due to client error.');
        process.kill();
      }
      activeProcesses.clear();
      clientSocket.destroy(); // Close socket on error
    },
    onDone: () {
      print('[TCP Proxy] Client $clientDesc disconnected.');
      // Clean up any running processes associated with this client
      for (var process in activeProcesses.values) {
         print('[TCP Proxy] Killing process PID ${process.pid} due to client disconnect.');
        process.kill();
      }
      activeProcesses.clear();
      // Handle any remaining data in the buffer? Usually not needed if client closes cleanly.
    },
    cancelOnError: true, // Automatically cancel subscription on error
  );
}

// --- Buffer Processing ---
void _processClientBuffer(BytesBuilder buffer, Socket clientSocket, String clientDesc, Map<dynamic, Process> activeProcesses) {
    // More robust approach: Use a temporary list to hold bytes for processing
    // This avoids modifying the main buffer while iterating
    Uint8List currentBytes = buffer.toBytes();
    int offset = 0; // Keep track of how much we've processed

    while (offset < currentBytes.length) {
        int newlineIndex = -1;
        // Find the next newline starting from the current offset
        for (int i = offset; i < currentBytes.length; i++) {
            if (currentBytes[i] == 10) { // '\n'
                newlineIndex = i;
                break;
            }
        }

        if (newlineIndex != -1) {
            // Extract the message bytes (from offset up to newline)
            final messageBytes = Uint8List.sublistView(currentBytes, offset, newlineIndex);
            // Update offset to point after the newline for the next iteration
            offset = newlineIndex + 1;

            // Decode and handle the message
            String messageString;
            try {
                messageString = utf8.decode(messageBytes);
                if (messageString.trim().isNotEmpty) {
                    print('[TCP Proxy] Received raw from $clientDesc: $messageString');
                    // Pass activeProcesses map to the handler
                    handleMcpRequest(messageString, clientSocket, clientDesc, activeProcesses);
                }
            } catch (e) {
                print('[TCP Proxy] Error decoding message from $clientDesc: $e');
                // Decide how to handle invalid data - here we just log and continue
            }
        } else {
            // No more newlines found in the remaining bytes
            break; // Exit the loop, wait for more data
        }
    }

    // If we processed any data, update the main buffer
    if (offset > 0) {
        if (offset < currentBytes.length) {
            // There are remaining bytes that didn't form a complete line
            final remainingBytes = Uint8List.sublistView(currentBytes, offset);
            buffer.clear();
            buffer.add(remainingBytes);
        } else {
            // All bytes were processed
            buffer.clear();
        }
    }
    // Any remaining bytes stay in the main buffer for the next data event
}


// --- MCP Request Handling (Placeholder - Needs Full Implementation) ---
Future<void> handleMcpRequest(String messageJsonString, Socket clientSocket, String clientDesc, Map<dynamic, Process> activeProcesses) async {
    // TODO: Implement the core logic as described in the prompt:
    // 1. Parse messageJsonString into a JsonRpcMessage object (or Map).
    // 2. Identify the method (e.g., "tools/call", "tools/list").
    // 3. If "tools/call":
    //    a. Extract tool name, arguments, and request ID.
    //    b. Look up the command for the tool name in `toolToServerCommand`.
    //    c. If found:
    //       i. Spawn the stdio server process using `Process.start`.
    //      ii. Pass required environment variables (e.g., TODOIST_API_TOKEN from Platform.environment).
    //     iii. Store the process in `activeProcesses` using the request ID.
    //      iv. Write the original request JSON to the process's stdin. Close stdin.
    //       v. Read the response JSON from the process's stdout (handle potential multiple lines/buffering).
    //      vi. Read stderr for logging/errors.
    //     vii. Wait for the process to exit. Remove from `activeProcesses`.
    //    viii. Send the response back to the clientSocket.
    //    d. If not found, send a "Method not found" JSON-RPC error back to clientSocket.
    // 4. If "tools/list":
    //    a. Iterate through `serversToListTools`.
    //    b. For each server: spawn process, send `tools/list` request, read response, handle stderr, kill process.
    //    c. Aggregate the tool lists from all responses into a single `ListToolsResult` structure.
    //    d. Send the aggregated result back to clientSocket using the original request ID.
    // 5. Handle other methods or send "Method not found".
    // 6. Implement robust error handling for parsing, process spawning, communication, timeouts, etc.
    //    Send appropriate JSON-RPC error responses back to the client.

    print('[TCP Proxy] TODO: Handle MCP Request from $clientDesc: $messageJsonString');

    // Example: Echo back for testing (REMOVE THIS LATER)
    try {
        final request = jsonDecode(messageJsonString) as Map<String, dynamic>;
        final response = {
             'jsonrpc': '2.0',
             'id': request['id'], // Echo ID back is crucial for JSON-RPC
             'result': {'message': 'Proxy received method: ${request['method']}'}
             // For errors, use 'error': {'code': ..., 'message': ...} instead of 'result'
         };
         final responseString = '${jsonEncode(response)}\n';
         print('[TCP Proxy] Sending placeholder response to $clientDesc: $responseString');
         clientSocket.write(responseString);
         await clientSocket.flush();
     } catch(e) {
         print("[TCP Proxy] Error processing/sending placeholder response for $clientDesc: $e");
         // Attempt to send a generic JSON-RPC error if possible
         try {
            final errorResponse = {
                'jsonrpc': '2.0',
                'id': null, // ID might not be available if parsing failed early
                'error': {'code': -32603, 'message': 'Internal server error during request processing: $e'}
            };
            clientSocket.write('${jsonEncode(errorResponse)}\n');
            await clientSocket.flush();
         } catch (sendError) {
             print("[TCP Proxy] Failed to send error response to $clientDesc: $sendError");
         }
     }
}
