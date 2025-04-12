import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
final List<String> serversToListTools =
    toolToServerCommand.values.toSet().toList();

// JSON RPC Error Codes
const int parseErrorCode = -32700;
const int invalidRequestCode = -32600;
const int methodNotFoundCode = -32601;
const int internalErrorCode = -32603;
const int serverTimeoutCode = -32001; // Custom code

// Timeouts
const Duration handshakeTimeout = Duration(seconds: 20);
const Duration requestTimeout = Duration(seconds: 60);
const Duration processStartTimeout = Duration(seconds: 10);


// Global map to track active processes managed by the proxy
// Key: Request ID (from client), Value: Process
final Map<dynamic, Process> _activeProcesses = {};
final Map<dynamic, Completer<void>> _processCompleters = {};
final Map<dynamic, StreamSubscription> _stderrSubscriptions = {};
final Map<dynamic, StreamSubscription> _stdoutSubscriptions = {};


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
      final clientDesc =
          '${clientSocket.remoteAddress.address}:${clientSocket.remotePort}';
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
  Future<void> shutdown() async {
    print('\n[TCP Proxy] Shutting down...');
    await serverSocket.close();
    // Kill any remaining active processes
    for (var process in _activeProcesses.values) {
      try {
        print('[TCP Proxy] Killing lingering process PID ${process.pid}');
        process.kill(ProcessSignal.sigterm); // Try graceful first
        // Optionally wait a short time then force kill if needed
      } catch (e) {
        print('[TCP Proxy] Error killing process PID ${process.pid}: $e');
      }
    }
    _activeProcesses.clear();
    _processCompleters.clear();
    for (var sub in _stderrSubscriptions.values) {
      sub.cancel();
    }
    _stderrSubscriptions.clear();
    for (var sub in _stdoutSubscriptions.values) {
      sub.cancel();
    }
    _stdoutSubscriptions.clear();
    print('[TCP Proxy] Exiting.');
    exit(0);
  }

  ProcessSignal.sigint.watch().listen((_) async => await shutdown());
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) async => await shutdown());
  }
}

// --- Client Handling Logic ---
void handleClient(Socket clientSocket, String clientDesc) {
  final buffer = BytesBuilder();
  StreamSubscription? socketSubscription;

  socketSubscription = clientSocket.listen(
    (Uint8List data) {
      buffer.add(data);
      // Attempt to process complete messages (newline-delimited JSON)
      _processClientBuffer(buffer, clientSocket, clientDesc);
    },
    onError: (error, stackTrace) {
      print('[TCP Proxy] Error from client $clientDesc: $error\n$stackTrace');
      _cleanupClientResources(clientSocket, clientDesc, socketSubscription);
    },
    onDone: () {
      print('[TCP Proxy] Client $clientDesc disconnected.');
      _cleanupClientResources(clientSocket, clientDesc, socketSubscription);
    },
    cancelOnError: true, // Automatically cancel subscription on error
  );
}

void _cleanupClientResources(Socket clientSocket, String clientDesc, StreamSubscription? socketSubscription) {
   socketSubscription?.cancel();
   try {
     clientSocket.destroy();
   } catch(e) {
      print('[TCP Proxy] Error destroying socket for $clientDesc: $e');
   }
   // Note: Associated processes are cleaned up when handleMcpRequest completes or times out
   // We don't have a direct mapping from client socket to request IDs here easily
}

// --- Buffer Processing ---
void _processClientBuffer(BytesBuilder buffer, Socket clientSocket, String clientDesc) {
  Uint8List currentBytes = buffer.toBytes();
  int offset = 0;

  while (offset < currentBytes.length) {
    int newlineIndex = -1;
    for (int i = offset; i < currentBytes.length; i++) {
      if (currentBytes[i] == 10) { // '\n'
        newlineIndex = i;
        break;
      }
    }

    if (newlineIndex != -1) {
      final messageBytes = Uint8List.sublistView(currentBytes, offset, newlineIndex);
      offset = newlineIndex + 1;

      String messageString;
      try {
        messageString = utf8.decode(messageBytes);
        if (messageString.trim().isNotEmpty) {
          print('[TCP Proxy] Received raw from $clientDesc: $messageString');
          // Handle the request asynchronously, don't await here
          handleMcpRequest(messageString, clientSocket, clientDesc);
        }
      } catch (e, s) {
        print('[TCP Proxy] Error decoding message from $clientDesc: $e\n$s');
        _sendJsonError(clientSocket, null, parseErrorCode, 'Parse error', e.toString());
        // Decide if the connection should be dropped on parse error
        // clientSocket.destroy();
        // return;
      }
    } else {
      break;
    }
  }

  if (offset > 0) {
    if (offset < currentBytes.length) {
      final remainingBytes = Uint8List.sublistView(currentBytes, offset);
      buffer.clear();
      buffer.add(remainingBytes);
    } else {
      buffer.clear();
    }
  }
}


// --- MCP Request Handling ---
Future<void> handleMcpRequest(String messageJsonString, Socket clientSocket, String clientDesc) async {
  Map<String, dynamic> request;
  dynamic requestId; // Can be int, String, or null

  try {
    request = jsonDecode(messageJsonString) as Map<String, dynamic>;
    requestId = request['id']; // Store ID early
    final method = request['method'] as String?;
    final params = request['params'] as Map<String, dynamic>?; // Assuming params is an object

    if (method == null) {
      _sendJsonError(clientSocket, requestId, invalidRequestCode, 'Invalid Request', 'Missing method');
      return;
    }

    print('[TCP Proxy] Parsed request ID $requestId, Method $method from $clientDesc');

    switch (method) {
      case 'initialize':
        _handleInitialize(clientSocket, requestId);
        break;
      case 'ping':
        _sendJsonResponse(clientSocket, requestId, {});
        break;
      case 'tools/call':
        await _handleToolCall(messageJsonString, request, clientSocket, clientDesc);
        break;
      case 'tools/list':
        await _handleToolList(request, clientSocket, clientDesc);
        break;
      case 'notifications/initialized':
         print('[TCP Proxy] Received initialized notification from $clientDesc. Ignoring.');
         // No response needed for notifications
        break;
      case 'notifications/cancelled':
          final cancelledRequestId = params?['requestId'];
          print('[TCP Proxy] Received cancel notification for request ID $cancelledRequestId from $clientDesc.');
          _cancelProcess(cancelledRequestId);
          break;
      default:
        _sendJsonError(clientSocket, requestId, methodNotFoundCode, 'Method not found', method);
    }
  } catch (e, s) {
    print('[TCP Proxy] Error processing request from $clientDesc: $e\n$s');
    // Attempt to send error, using potentially recovered requestId
    _sendJsonError(clientSocket, requestId, internalErrorCode, 'Internal server error', e.toString());
  }
}

// --- Specific Handlers ---

void _handleInitialize(Socket clientSocket, dynamic requestId) {
  print('[TCP Proxy] Handling initialize request');
  final response = {
    'protocolVersion': '2024-11-05', // MCP version proxy supports
    'capabilities': {
      'tools': {}, // Proxy itself doesn't offer tools directly
    },
    'serverInfo': {
      'name': 'mcp-tcp-proxy-dart',
      'version': '0.1.0',
    },
  };
  _sendJsonResponse(clientSocket, requestId, response);
}

Future<void> _handleToolCall(String originalRequestJson, Map<String, dynamic> request, Socket clientSocket, String clientDesc) async {
  final params = request['params'] as Map<String, dynamic>?;
  final toolName = params?['name'] as String?;
  final requestId = request['id'];

  if (toolName == null) {
    _sendJsonError(clientSocket, requestId, invalidRequestCode, 'Invalid params for tools/call', 'Missing tool name');
    return;
  }

  final serverCmdPath = toolToServerCommand[toolName];
  if (serverCmdPath == null) {
    _sendJsonError(clientSocket, requestId, methodNotFoundCode, 'Tool not found', 'Tool "$toolName" is not configured');
    return;
  }

  print('[TCP Proxy] Routing tool "$toolName" (ID: $requestId) to command "$serverCmdPath" for client $clientDesc');

  try {
    // Execute the stdio server, sending the original client request JSON
    final responseJson = await _executeStdioServer(serverCmdPath, originalRequestJson, requestId);

    // Forward the raw response JSON (it should include the ID) back to the client
    print('[TCP Proxy] Forwarding response for tool "$toolName" (ID: $requestId) to client $clientDesc');
    _sendRawJson(clientSocket, responseJson);

  } catch (e, s) {
    print('[TCP Proxy] Error executing stdio server $serverCmdPath for tool "$toolName" (ID: $requestId): $e\n$s');
     String errorMessage = 'Error executing tool "$toolName"';
     if (e is TimeoutException) {
        _sendJsonError(clientSocket, requestId, serverTimeoutCode, 'Tool execution timed out', errorMessage);
     } else {
        _sendJsonError(clientSocket, requestId, internalErrorCode, errorMessage, e.toString());
     }
  } finally {
      // Clean up process tracking for this request ID
      _cleanupProcessResources(requestId);
  }
}


Future<void> _handleToolList(Map<String, dynamic> request, Socket clientSocket, String clientDesc) async {
  final requestId = request['id'];
  print('[TCP Proxy] Handling tools/list request (ID: $requestId) from $clientDesc');

  final List<Map<String, dynamic>> allTools = [];
  final List<Future<List<Map<String, dynamic>>>> futures = [];
  final Set<String> serversProcessed = {}; // Avoid duplicate calls for same server path

  // Create the tools/list request JSON to send to each server
  final listRequestPayload = {
    'jsonrpc': '2.0',
    'method': 'tools/list',
    'id': requestId, // Use the client's request ID
  };
  final listRequestJson = jsonEncode(listRequestPayload);

  for (final serverCmdPath in serversToListTools) {
      if (serversProcessed.contains(serverCmdPath)) {
          continue; // Already querying this server
      }
      serversProcessed.add(serverCmdPath);
      print('[TCP Proxy] Querying tools/list from $serverCmdPath (ID: $requestId)');
      futures.add(
          _executeStdioServer(serverCmdPath, listRequestJson, '$requestId-list-${serversProcessed.length}')
              .then((responseJson) {
                  try {
                      final response = jsonDecode(responseJson) as Map<String, dynamic>;
                      // IMPORTANT: Validate the ID in the response matches the ORIGINAL client request ID
                      if (response['id'] != requestId) {
                         print('[TCP Proxy] Mismatched ID in tools/list response from $serverCmdPath. Expected: $requestId, Got: ${response['id']}. Discarding.');
                         return <Map<String, dynamic>>[];
                      }
                      if (response.containsKey('error')) {
                          final error = response['error'] as Map<String, dynamic>;
                          print('[TCP Proxy] Server $serverCmdPath returned error for tools/list (ID: $requestId): ${error['message']}');
                          return <Map<String, dynamic>>[];
                      }
                      final result = response['result'] as Map<String, dynamic>?;
                      final tools = (result?['tools'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
                      print('[TCP Proxy] Got ${tools.length} tools from $serverCmdPath (ID: $requestId)');
                      return tools;
                  } catch (e,s) {
                      print('[TCP Proxy] Error parsing tools/list response from $serverCmdPath (ID: $requestId): $e\n$s. Raw: $responseJson');
                      return <Map<String, dynamic>>[];
                  }
              })
              .catchError((e, s) {
                  print('[TCP Proxy] Error executing $serverCmdPath for tools/list (ID: $requestId): $e\n$s');
                  return <Map<String, dynamic>>[]; // Return empty list on error
              })
              .whenComplete(() {
                 // Clean up process tracking for the sub-request ID
                 _cleanupProcessResources('$requestId-list-${serversProcessed.length}');
              })
      );
  }

  // Wait for all server queries to complete
  final List<List<Map<String, dynamic>>> results = await Future.wait(futures);

  // Aggregate tools
  for (final toolList in results) {
    allTools.addAll(toolList);
  }

  print('[TCP Proxy] Aggregated ${allTools.length} tools total for request ID $requestId.');

  // Send the aggregated result back to the client
  _sendJsonResponse(clientSocket, requestId, {'tools': allTools});
}

// --- Process Execution Helper ---

// Executes a stdio server, handles handshake, sends one request, reads one response.
// Returns the raw JSON response string (including newline).
Future<String> _executeStdioServer(String serverCmdPath, String requestJson, dynamic requestId) async {
  print('[TCP Proxy] Executing: $serverCmdPath for request ID: $requestId');
  Process process;
  final processCompleter = Completer<void>();
  _processCompleters[requestId] = processCompleter;

  final stopwatch = Stopwatch()..start();
  try {
    process = await Process.start(
      serverCmdPath,
      [],
      environment: Platform.environment, // Forward environment variables
      runInShell: false, // More secure and often more reliable
    ).timeout(processStartTimeout);

     print('[TCP Proxy] Started subprocess PID ${process.pid} for $serverCmdPath (ID: $requestId) in ${stopwatch.elapsedMilliseconds}ms');
    _activeProcesses[requestId] = process;


    // Capture stderr asynchronously
    final stderrBuffer = StringBuffer();
    final stderrSub = process.stderr.transform(utf8.decoder).listen(
      (line) {
        print('[Subprocess ${process.pid} stderr] $line');
        stderrBuffer.writeln(line);
      },
      onError: (err) {
         print('[TCP Proxy] Error reading stderr from PID ${process.pid} (ID: $requestId): $err');
         stderrBuffer.writeln('Error reading stderr: $err');
      },
      onDone: () {
        print('[TCP Proxy] Stderr pipe closed for PID ${process.pid} (ID: $requestId)');
      }
    );
     _stderrSubscriptions[requestId] = stderrSub;


    // Complete the completer when the process exits
    process.exitCode.then((exitCode) {
      print('[TCP Proxy] Subprocess PID ${process.pid} (ID: $requestId) exited with code $exitCode.');
      if (!processCompleter.isCompleted) {
          if (exitCode != 0) {
             processCompleter.completeError(
                 Exception('Process PID ${process.pid} ($serverCmdPath) exited with code $exitCode. Stderr:\n$stderrBuffer'));
          } else {
             // Should have completed via stdout response normally if exit code is 0
             // If it completes here with 0 without a response, it's likely an issue.
             processCompleter.completeError(
                 Exception('Process PID ${process.pid} ($serverCmdPath) exited with code 0 before sending response. Stderr:\n$stderrBuffer'));
          }
      }
       // Ensure cleanup happens even if process exits unexpectedly
       _cleanupProcessResources(requestId);
    }).catchError((e) {
         print('[TCP Proxy] Error waiting for exit code for PID ${process.pid} (ID: $requestId): $e');
         if (!processCompleter.isCompleted) {
           processCompleter.completeError(e);
         }
          _cleanupProcessResources(requestId);
    });

    // --- MCP Handshake and Request/Response ---
    final responseCompleter = Completer<String>();
    StreamSubscription? stdoutSub;

    stdoutSub = process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        // Handle handshake responses and the final response
         print('[Subprocess ${process.pid} stdout] $line');
        try {
            final jsonLine = jsonDecode(line);
            if (jsonLine is Map<String,dynamic>) {
                final responseId = jsonLine['id'];
                // Check if it's the final response matching the requestJson's ID
                // This relies on requestJson being parsed *before* calling _executeStdioServer,
                // or parsing it here. Let's parse it here for safety.
                final parsedRequest = jsonDecode(requestJson) as Map<String,dynamic>;
                final originalRequestId = parsedRequest['id'];

                if (responseId == originalRequestId && !responseCompleter.isCompleted) {
                    print('[TCP Proxy] Received final response for ID $responseId from PID ${process.pid}');
                    responseCompleter.complete('$line\n'); // Include newline
                } else if (responseId.toString().startsWith('proxy-init-')) {
                   // Handle initialize response implicitly during handshake phase (below)
                   print('[TCP Proxy] Received handshake response line for ID $responseId from PID ${process.pid}');
                } else {
                   print('[TCP Proxy] Received unexpected stdout line from PID ${process.pid}: $line');
                }
            } else {
                print('[TCP Proxy] Received non-JSON stdout line from PID ${process.pid}: $line');
            }
        } catch (e) {
             print('[TCP Proxy] Error parsing stdout line from PID ${process.pid}: $e. Line: "$line"');
             if (!responseCompleter.isCompleted) {
                 // responseCompleter.completeError(Exception('Invalid JSON from subprocess: $line'));
                 // Decide if we should fail the whole request or just log
             }
        }
      },
      onError: (err) {
         print('[TCP Proxy] Error reading stdout from PID ${process.pid} (ID: $requestId): $err');
         if (!responseCompleter.isCompleted) {
            responseCompleter.completeError(err);
         }
      },
      onDone: () {
         print('[TCP Proxy] Stdout pipe closed for PID ${process.pid} (ID: $requestId)');
         if (!responseCompleter.isCompleted) {
             // Process likely exited without sending the expected final response
             responseCompleter.completeError(
                 Exception('Stdout closed before final response received for ID $requestId. Stderr:\n$stderrBuffer'));
         }
      },
      cancelOnError: true,
    );
     _stdoutSubscriptions[requestId] = stdoutSub;


    // 1. Send initialize
    final proxyInitId = 'proxy-init-${DateTime.now().microsecondsSinceEpoch}';
    final initRequest = jsonEncode({
      'jsonrpc': '2.0',
      'id': proxyInitId,
      'method': 'initialize',
      'params': {
        'protocolVersion': '2024-11-05',
        'clientInfo': {'name': 'mcp-tcp-proxy-dart', 'version': '0.1.0'},
        'capabilities': {},
      },
    });
    print('[TCP Proxy] PID ${process.pid}: Sending initialize (ID: $proxyInitId)');
    process.stdin.writeln(initRequest);
    await process.stdin.flush(); //.timeout(handshakeTimeout); // Add timeout?

    // (Implicitly wait for initialize response via the stdout listener)
    // We rely on the overall requestTimeout to catch handshake failures

    // 2. Send initialized notification
     print('[TCP Proxy] PID ${process.pid}: Sending initialized notification');
    process.stdin.writeln('{"jsonrpc":"2.0","method":"notifications/initialized"}');
     await process.stdin.flush(); //.timeout(handshakeTimeout);

    // 3. Send the actual client request
    print('[TCP Proxy] PID ${process.pid}: Sending actual request (ID: ${jsonDecode(requestJson)['id']})');
    process.stdin.writeln(requestJson);
     await process.stdin.flush(); //.timeout(requestTimeout);

    // 4. Close stdin - Signals the end of input to the subprocess
    // Crucially, DO NOT close stdin *immediately* after writing the request.
    // Some servers might need a moment to process. Closing it is often done
    // implicitly when the Process object is garbage collected or explicitly
    // after getting the response, but closing *early* can cause issues.
    // Let's rely on the process exiting to handle stdin closure implicitly,
    // or close it after the response is received if needed. For now, leave it open.
    // await process.stdin.close(); // <-- Potentially problematic if done too early

    // 5. Wait for the final response from stdout listener or timeout
    final responseJson = await responseCompleter.future.timeout(requestTimeout,
        onTimeout: () {
            throw TimeoutException(
                'Timeout waiting for response from $serverCmdPath (PID ${process.pid}) for request ID $requestId',
                requestTimeout);
         });

    // Optional: Close stdin now if the process hasn't exited yet
    // try { await process.stdin.close(); } catch (e) {}

    // Wait for the process to fully exit before returning
    await processCompleter.future.timeout(const Duration(seconds: 5)); // Short timeout for exit

    return responseJson;

  } catch (e,s) {
    print('[TCP Proxy] Error in _executeStdioServer for ID $requestId: $e\n$s');
    // Ensure process is killed on error/timeout
    if (_activeProcesses.containsKey(requestId)) {
      _activeProcesses[requestId]?.kill();
    }
    // Ensure the process completer is finished with an error
    if (!_processCompleters[requestId]!.isCompleted) {
       _processCompleters[requestId]!.completeError(e);
    }
    rethrow; // Rethrow the error to be handled by the caller
  } finally {
     stopwatch.stop();
     print('[TCP Proxy] _executeStdioServer for ID $requestId completed in ${stopwatch.elapsedMilliseconds}ms');
     // Cleanup is handled by callers or process exit handler now
     // _cleanupProcessResources(requestId); // Moved
  }
}

// --- Cleanup and Cancellation ---

void _cleanupProcessResources(dynamic requestId) {
    if (requestId == null) return;

    print("[TCP Proxy] Cleaning up resources for request ID: $requestId");

    _stderrSubscriptions.remove(requestId)?.cancel();
    _stdoutSubscriptions.remove(requestId)?.cancel();

    final process = _activeProcesses.remove(requestId);
    if (process != null) {
        // Check if it's still running (though it should have exited or been killed)
        // process.kill(); // Consider if kill is needed here
        print("[TCP Proxy] Removed process PID ${process.pid} from active map for request ID $requestId.");
    }

    final completer = _processCompleters.remove(requestId);
    if (completer != null && !completer.isCompleted) {
        print("[TCP Proxy] Completing process completer for request ID $requestId due to cleanup.");
        // Complete with an error indicating cleanup? Or just complete normally?
        // Let's assume the process exited or error was handled elsewhere.
        // completer.complete(); // Or completeError if appropriate
    }
}


void _cancelProcess(dynamic requestId) {
  if (requestId == null) return;
  print('[TCP Proxy] Attempting to cancel process for request ID: $requestId');
  final process = _activeProcesses[requestId];
  final completer = _processCompleters[requestId];

  if (process != null) {
    print('[TCP Proxy] Sending SIGTERM to process PID ${process.pid} for request ID $requestId');
    bool killed = process.kill(ProcessSignal.sigterm); // Try graceful kill
    if (!killed) {
       print('[TCP Proxy] Failed to send SIGTERM to PID ${process.pid}, attempting SIGKILL.');
       process.kill(ProcessSignal.sigkill);
    }
    // Process exit handler should trigger cleanup via _cleanupProcessResources
  } else {
     print('[TCP Proxy] No active process found for request ID $requestId to cancel.');
  }

   // Complete the completer immediately with a cancellation error
   if (completer != null && !completer.isCompleted) {
      completer.completeError(Exception('Request $requestId cancelled by client'));
       _cleanupProcessResources(requestId); // Ensure cleanup happens now
   }
}

// --- JSON RPC Response Helpers ---

// Sends a raw JSON string (must be a complete JSON object/array)
void _sendRawJson(Socket clientSocket, String jsonString) {
  try {
    // Ensure the string ends with a newline for MCP
    final dataToSend = jsonString.endsWith('\n') ? jsonString : '$jsonString\n';
    print('[TCP Proxy] Sending raw response: ${dataToSend.trim()}');
    clientSocket.write(dataToSend);
    // Don't await flush here to avoid blocking the handler loop
    clientSocket.flush().catchError((e) {
       print('[TCP Proxy] Error flushing socket during sendRawJson: $e');
    });
  } catch (e) {
    print('[TCP Proxy] Error sending raw JSON response: $e');
    // Attempt to close socket?
    try { clientSocket.destroy(); } catch (_) {}
  }
}


void _sendJsonResponse(Socket clientSocket, dynamic id, dynamic result) {
  final response = {
    'jsonrpc': '2.0',
    'id': id,
    'result': result,
  };
  try {
     final responseString = jsonEncode(response);
     _sendRawJson(clientSocket, responseString);
  } catch (e) {
     print('[TCP Proxy] Error encoding success response: $e');
     // Try sending a generic error if encoding fails
     _sendJsonError(clientSocket, id, internalErrorCode, 'Internal server error', 'Failed to encode success response');
  }
}

void _sendJsonError(Socket clientSocket, dynamic id, int code, String message, [dynamic data]) {
  final errorPayload = {
    'code': code,
    'message': message,
    if (data != null) 'data': data,
  };
  final response = {
    'jsonrpc': '2.0',
    'id': id, // Can be null if request ID wasn't parsed
    'error': errorPayload,
  };
   try {
     final responseString = jsonEncode(response);
     _sendRawJson(clientSocket, responseString);
   } catch (e) {
      print('[TCP Proxy] CRITICAL: Error encoding error response: $e');
      // Fallback to plain text error if JSON encoding fails
      try {
         final fallbackError = '{"jsonrpc":"2.0","id":null,"error":{"code":$internalErrorCode,"message":"Proxy failed to encode error response"}}\n';
         clientSocket.write(fallbackError);
         clientSocket.flush().catchError((flushError) {
           print('[TCP Proxy] Error flushing socket during fallback error send: $flushError');
         });
      } catch (fallbackErr) {
         print('[TCP Proxy] CRITICAL: Failed even to send fallback error: $fallbackErr');
         // Close socket as last resort
         try { clientSocket.destroy(); } catch (_) {}
      }
   }
}
