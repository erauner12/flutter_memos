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
const Duration handshakeTimeout = Duration(
  seconds: 20,
); // Keep for potential future use
const Duration requestTimeout = Duration(
  seconds: 60,
); // Overall request timeout
const Duration processStartTimeout = Duration(
  seconds: 10,
); // Timeout for Process.start
const Duration processExitTimeout = Duration(
  seconds: 5,
); // Grace period for process exit after response

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
    final pids = _activeProcesses.values.map((p) => p.pid).toList();
    for (var process in _activeProcesses.values) {
      try {
        print('[TCP Proxy] Killing lingering process PID ${process.pid}');
        process.kill(ProcessSignal.sigterm); // Try graceful first
      } catch (e) {
        print('[TCP Proxy] Error killing process PID ${process.pid}: $e');
      }
    }
    _activeProcesses.clear();
    _processCompleters.clear(); // Clear completers
    for (var sub in _stderrSubscriptions.values) {
      // Cancel subscriptions
      sub.cancel();
    }
    _stderrSubscriptions.clear();
    for (var sub in _stdoutSubscriptions.values) {
      sub.cancel();
    }
    _stdoutSubscriptions.clear();
    print('[TCP Proxy] Killed lingering processes: $pids');
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
  // Active processes related to this client are not directly tracked here.
  // Cancellation requests (`notifications/cancelled`) or timeouts in `handleMcpRequest`
  // are responsible for cleaning up individual processes via `_cancelProcess` or the `finally` block.
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
        // Decode even if empty, trim later
        messageString = utf8.decode(messageBytes);
        if (messageString.trim().isNotEmpty) {
          print('[TCP Proxy] Received raw from $clientDesc: $messageString');
          // Handle the request asynchronously, don't await here
          // Use unawaited_futures or simply ignore the future if not needed
          handleMcpRequest(messageString, clientSocket, clientDesc);
        } else {
          print('[TCP Proxy] Received empty line from $clientDesc. Ignoring.');
        }
      } catch (e, s) {
        print('[TCP Proxy] Error decoding message from $clientDesc: $e\n$s');
        _sendJsonError(clientSocket, null, parseErrorCode, 'Parse error', e.toString());
        // Consider dropping connection on persistent parse errors?
        // clientSocket.destroy();
        // return;
      }
    } else {
      break; // No complete line found, wait for more data
    }
  }

  // Update the buffer with remaining bytes
  if (offset > 0) {
    if (offset < currentBytes.length) {
      final remainingBytes = Uint8List.sublistView(currentBytes, offset);
      buffer.clear();
      buffer.add(remainingBytes);
    } else {
      buffer.clear(); // All bytes processed
    }
  }
}

// --- MCP Request Handling ---
Future<void> handleMcpRequest(String messageJsonString, Socket clientSocket, String clientDesc) async {
  Map<String, dynamic>? request; // Make nullable
  dynamic requestId; // Can be int, String, or null

  try {
    request = jsonDecode(messageJsonString) as Map<String, dynamic>;
    requestId = request['id']; // Store ID early, can be null
    final method = request['method'] as String?;
    final params = request['params']; // Can be Map, List, or null

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
        // Ensure request is not null before passing
        await _handleToolCall(
          messageJsonString,
          request,
          clientSocket,
          clientDesc,
        );
        break;
      case 'tools/list':
        await _handleToolList(request, clientSocket, clientDesc);
        break;
      case 'notifications/initialized':
         print('[TCP Proxy] Received initialized notification from $clientDesc. Ignoring.');
         // No response needed for notifications
        break;
      case 'notifications/cancelled':
        dynamic cancelledRequestId;
        if (params is Map<String, dynamic>) {
          cancelledRequestId = params['requestId'];
        }
          print('[TCP Proxy] Received cancel notification for request ID $cancelledRequestId from $clientDesc.');
        if (cancelledRequestId != null) {
          _cancelProcess(cancelledRequestId);
        } else {
          print('[TCP Proxy] Cancel notification missing requestId.');
        }
          break;
      default:
        _sendJsonError(clientSocket, requestId, methodNotFoundCode, 'Method not found', method);
    }
  } on FormatException catch (e) {
    print('[TCP Proxy] JSON Parse Error from $clientDesc: $e');
    // requestId might be null here if parsing failed early
    _sendJsonError(
      clientSocket,
      requestId,
      parseErrorCode,
      'Parse error',
      e.message,
    );
  } catch (e, s) {
    print('[TCP Proxy] Error processing request from $clientDesc: $e\n$s');
    // Attempt to send error, using potentially recovered requestId
    _sendJsonError(clientSocket, requestId, internalErrorCode, 'Internal server error', e.toString());
  }
}

// --- Specific Handlers ---

void _handleInitialize(Socket clientSocket, dynamic requestId) {
  print('[TCP Proxy] Handling initialize request ID: $requestId');
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
  final requestId = request['id']; // Already known to be non-null from caller

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

    // Forward the raw response JSON back to the client
    print('[TCP Proxy] Forwarding response for tool "$toolName" (ID: $requestId) to client $clientDesc');
    _sendRawJson(clientSocket, responseJson);

  } catch (e, s) {
    print(
      '[TCP Proxy] Error executing/handling stdio server $serverCmdPath for tool "$toolName" (ID: $requestId): $e\n$s',
    );
     String errorMessage = 'Error executing tool "$toolName"';
     if (e is TimeoutException) {
      _sendJsonError(
        clientSocket,
        requestId,
        serverTimeoutCode,
        'Tool execution timed out',
        e.message,
      );
     } else {
        _sendJsonError(clientSocket, requestId, internalErrorCode, errorMessage, e.toString());
     }
    // Cleanup happens in _executeStdioServer's finally block now
  }
  // No finally block needed here, _executeStdioServer handles its own cleanup
}

Future<void> _handleToolList(Map<String, dynamic> request, Socket clientSocket, String clientDesc) async {
  final requestId = request['id']; // Already known to be non-null from caller
  print('[TCP Proxy] Handling tools/list request (ID: $requestId) from $clientDesc');

  final List<Map<String, dynamic>> allTools = [];
  final List<Future<List<Map<String, dynamic>>>> futures = [];
  final Set<String> serversProcessed = {}; // Avoid duplicate calls for same server path

  // Create the tools/list request JSON to send to each server
  final listRequestPayload = {
    'jsonrpc': '2.0',
    'method': 'tools/list',
    'id': requestId, // Use the client's original request ID
  };
  final listRequestJson = jsonEncode(listRequestPayload);

  for (final serverCmdPath in serversToListTools) {
      if (serversProcessed.contains(serverCmdPath)) {
      continue; // Already querying this server path
      }
      serversProcessed.add(serverCmdPath);

    // Generate a unique sub-request ID for tracking this specific process call
    final subRequestId = '$requestId-list-${serverCmdPath.hashCode}';
    print(
      '[TCP Proxy] Querying tools/list from $serverCmdPath (Sub-ID: $subRequestId, Orig-ID: $requestId)',
    );

      futures.add(
      _executeStdioServer(serverCmdPath, listRequestJson, subRequestId)
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
            // Errors during execution are logged within _executeStdioServer
            print(
              '[TCP Proxy] Execution/Handling failed for $serverCmdPath during tools/list (Sub-ID: $subRequestId): $e',
            );
                  return <Map<String, dynamic>>[]; // Return empty list on error
              })
      // No whenComplete cleanup needed here, _executeStdioServer handles it
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
  // Ensure requestId is provided
  if (requestId == null) {
    throw ArgumentError('requestId cannot be null for _executeStdioServer');
  }
  print('[TCP Proxy] Executing: $serverCmdPath for request ID: $requestId');

  Process? process; // Make nullable
  final processCompleter = Completer<void>();
  _processCompleters[requestId] = processCompleter;

  final stopwatch = Stopwatch()..start();
  StreamSubscription? stderrSub;
  StreamSubscription? stdoutSub;
  final stderrBuffer = StringBuffer();

  try {
    process = await Process.start(
      serverCmdPath,
      [],
      environment: Platform.environment, // Forward environment variables
      runInShell: false,
    ).timeout(processStartTimeout);

    // Store the non-null process associated with this request ID
    _activeProcesses[requestId] = process;
    print(
      '[TCP Proxy] Started subprocess PID ${process.pid} for $serverCmdPath (ID: $requestId) in ${stopwatch.elapsedMilliseconds}ms',
    );

    // Capture stderr asynchronously
    stderrSub = process.stderr
        .transform(utf8.decoder)
        .listen(
      (line) {
            final pid = _activeProcesses[requestId]?.pid ?? 'unknown';
            print('[Subprocess $pid stderr] $line');
        stderrBuffer.writeln(line);
      },
      onError: (err) {
            final pid = _activeProcesses[requestId]?.pid ?? 'unknown';
            print(
              '[TCP Proxy] Error reading stderr from PID $pid (ID: $requestId): $err',
            );
         stderrBuffer.writeln('Error reading stderr: $err');
      },
      onDone: () {
            final pid = _activeProcesses[requestId]?.pid ?? 'unknown';
            print(
              '[TCP Proxy] Stderr pipe closed for PID $pid (ID: $requestId)',
            );
      }
    );
    _stderrSubscriptions[requestId] = stderrSub; // Track subscription

    // Handle process exit asynchronously
    process.exitCode.then((exitCode) {
          final pid =
              process?.pid ?? 'unknown'; // Capture pid before potential cleanup
          print(
            '[TCP Proxy] Subprocess PID $pid (ID: $requestId) exited with code $exitCode.',
          );
          // Complete the completer *only if it hasn't been completed by successful response*
      if (!processCompleter.isCompleted) {
            String errorMsg = 'Process PID $pid ($serverCmdPath) exited ';
          if (exitCode != 0) {
              errorMsg += 'with code $exitCode';
          } else {
              errorMsg += 'with code 0 unexpectedly before sending response';
          }
            errorMsg += '. Stderr:\n$stderrBuffer';
            processCompleter.completeError(Exception(errorMsg));
      }
          // Resource cleanup is now handled in the main finally block
    }).catchError((e) {
          final pid = process?.pid ?? 'unknown';
          print(
            '[TCP Proxy] Error waiting for exit code for PID $pid (ID: $requestId): $e',
          );
         if (!processCompleter.isCompleted) {
           processCompleter.completeError(e);
          }
    });

    // --- MCP Handshake and Request/Response ---
    final responseCompleter = Completer<String>();

    stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
            final currentProcess =
                _activeProcesses[requestId]; // Check if still active
            if (currentProcess == null)
              return; // Process was cancelled/cleaned up

            final pid = currentProcess.pid;
            print('[Subprocess $pid stdout] $line');
        try {
            final jsonLine = jsonDecode(line);
            if (jsonLine is Map<String,dynamic>) {
                final responseId = jsonLine['id'];
                final parsedRequest = jsonDecode(requestJson) as Map<String,dynamic>;
                final originalRequestId =
                    parsedRequest['id']; // ID from the *client's* request

                if (responseId == originalRequestId && !responseCompleter.isCompleted) {
                  print(
                    '[TCP Proxy] Received final response for ID $responseId from PID $pid',
                  );
                  responseCompleter.complete(
                    '$line\n',
                  ); // Complete with the full line+newline
                  // Indicate successful communication by completing the process completer
                  if (!processCompleter.isCompleted) {
                    processCompleter.complete();
                  }
                } else if (responseId.toString().startsWith('proxy-init-')) {
                  // This is the response to our internal initialize request
                  print(
                    '[TCP Proxy] Received handshake response line for ID $responseId from PID $pid',
                  );
                  // Basic validation could be added here if needed
                } else {
                  print(
                    '[TCP Proxy] Received unexpected stdout JSON line from PID $pid (ID: $responseId): $line',
                  );
                }
            } else {
                print(
                  '[TCP Proxy] Received non-JSON stdout line from PID $pid: $line',
                );
            }
        } catch (e) {
              print(
                '[TCP Proxy] Warning: Failed to parse stdout line from PID $pid as JSON: $e. Line: "$line". Ignoring line.',
              );
        }
      },
      onError: (err) {
            final pid = _activeProcesses[requestId]?.pid ?? 'unknown';
            print(
              '[TCP Proxy] Error reading stdout from PID $pid (ID: $requestId): $err',
            );
            final error = Exception('Stdout stream error for $requestId: $err');
            if (!responseCompleter.isCompleted)
              responseCompleter.completeError(error);
            if (!processCompleter.isCompleted)
              processCompleter.completeError(error);
      },
      onDone: () {
            final pid = _activeProcesses[requestId]?.pid ?? 'unknown';
            print(
              '[TCP Proxy] Stdout pipe closed for PID $pid (ID: $requestId)',
            );
         if (!responseCompleter.isCompleted) {
              // Process exited without sending the expected final response after handshake
              final error = Exception(
                'Stdout closed before final response received for ID $requestId. Stderr:\n$stderrBuffer',
              );
              responseCompleter.completeError(error);
              if (!processCompleter.isCompleted)
                processCompleter.completeError(error);
         }
      },
      cancelOnError: true,
    );
    _stdoutSubscriptions[requestId] = stdoutSub; // Track subscription

    // --- Send Handshake and Request ---
    // 1. Send initialize request
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

    // 2. Send initialized notification
    print('[TCP Proxy] PID ${process.pid}: Sending initialized notification');
    process.stdin.writeln(
      '{"jsonrpc":"2.0","method":"notifications/initialized"}',
    );

    // 3. Send the actual client request
    final clientId = jsonDecode(requestJson)['id'];
    print(
      '[TCP Proxy] PID ${process.pid}: Sending actual request (Client ID: $clientId)',
    );
    process.stdin.writeln(requestJson);

    // 4. Flush and Close stdin: Signal that no more input is coming.
    try {
      await process.stdin.flush().timeout(const Duration(seconds: 5));
      await process.stdin.close();
      print('[TCP Proxy] PID ${process.pid}: Flushed and closed stdin.');
    } catch (e) {
      print(
        '[TCP Proxy] PID ${process.pid}: Error flushing/closing stdin: $e. Process might have already exited.',
      );
      // Don't necessarily fail the whole operation here, stdout might still arrive.
    }

    // 5. Wait for the final response from stdout listener OR timeout
    final responseJson = await responseCompleter.future.timeout(requestTimeout,
        onTimeout: () {
        // This timeout triggers if the responseCompleter isn't completed in time.
            throw TimeoutException(
          'Timeout waiting for response from $serverCmdPath (PID ${process?.pid ?? 'unknown'}) for request ID $requestId. Stderr:\n$stderrBuffer',
                requestTimeout);
         });

    // 6. If response received, wait briefly for the process to exit gracefully.
    // The exitCode handler completes the processCompleter.
    try {
      await processCompleter.future.timeout(processExitTimeout);
      print(
        "[TCP Proxy] Process PID ${process.pid ?? 'unknown'} (ID: $requestId) exited gracefully after response.",
      );
    } on TimeoutException {
      print(
        "[TCP Proxy] Warning: Process PID ${process.pid ?? 'unknown'} (ID: $requestId) did not exit within ${processExitTimeout.inSeconds}s after response. Cleanup will force kill if needed.",
      );
    } catch (e) {
      print(
        "[TCP Proxy] Error waiting for process exit completer for PID ${process.pid ?? 'unknown'} (ID: $requestId): $e",
      );
    }

    return responseJson; // Return the successfully received response

  } catch (e,s) {
    // Catch errors from Process.start, timeouts, stream errors, etc.
    print(
      '[TCP Proxy] Error in _executeStdioServer outer catch for ID $requestId: $e\n$s',
    );
    // Process killing and resource cleanup are handled in the finally block
    rethrow; // Rethrow the error to be handled by the caller (_handleToolCall/_handleToolList)
  } finally {
     stopwatch.stop();
    print(
      '[TCP Proxy] _executeStdioServer for ID $requestId finished in ${stopwatch.elapsedMilliseconds}ms',
    );
    // Perform cleanup robustly in finally block, regardless of success or failure
    _cleanupProcessResources(requestId);
  }
}

// --- Cleanup and Cancellation ---

void _cleanupProcessResources(dynamic requestId) {
    if (requestId == null) return;

    print("[TCP Proxy] Cleaning up resources for request ID: $requestId");

  // Cancel stream subscriptions safely
    _stderrSubscriptions.remove(requestId)?.cancel();
    _stdoutSubscriptions.remove(requestId)?.cancel();

  // Remove and potentially kill the process
    final process = _activeProcesses.remove(requestId);
  if (process != null) {
        print("[TCP Proxy] Removed process PID ${process.pid} from active map for request ID $requestId.");
    // Attempt to kill the process if it's still somehow alive.
    // This might happen if the exitCode future hasn't completed yet or there was an error.
    try {
      // Send SIGKILL as a final measure, as SIGTERM might have been tried already.
      process.kill(ProcessSignal.sigkill);
      print(
        "[TCP Proxy] Sent SIGKILL to process PID ${process.pid} during cleanup (request ID: $requestId).",
      );
    } catch (e) {
      // Might fail if process already exited
      print(
        "[TCP Proxy] Error sending SIGKILL during cleanup for PID ${process.pid} (request ID: $requestId): $e",
      );
    }
    }

  // Remove the completer (don't complete it again)
  _processCompleters.remove(requestId);
}

void _cancelProcess(dynamic requestId) {
  if (requestId == null) return;
  print('[TCP Proxy] Attempting to cancel process for request ID: $requestId');

  // Complete the process completer immediately with a cancellation error
  // This signals to any waiters that the operation was cancelled.
  final completer = _processCompleters[requestId];
  if (completer != null && !completer.isCompleted) {
    completer.completeError(
      Exception('Request $requestId cancelled by client'),
    );
  } else if (completer == null) {
    print(
      '[TCP Proxy] No process completer found for request ID $requestId to cancel.',
    );
    // No active process or it already finished/failed.
    return; // Nothing more to do
  }
  // Note: Don't remove the completer here, cleanup will handle it.

  final process = _activeProcesses[requestId];
  if (process != null) {
    print('[TCP Proxy] Sending SIGTERM to process PID ${process.pid} for request ID $requestId');
    bool killed = process.kill(
      ProcessSignal.sigterm,
    ); // Try graceful kill first
    if (!killed) {
       print('[TCP Proxy] Failed to send SIGTERM to PID ${process.pid}, attempting SIGKILL.');
       process.kill(ProcessSignal.sigkill);
    }
    // Process exit handler (`process.exitCode.then`) should still run eventually.
    // The `finally` block in `_executeStdioServer` will call `_cleanupProcessResources`.
  } else {
    print(
      '[TCP Proxy] No active process found in map for request ID $requestId to kill.',
    );
    // If completer existed but process didn't, cleanup might be needed anyway.
    _cleanupProcessResources(requestId);
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
    // Use async flush but don't wait for it here to avoid blocking.
    clientSocket.flush().catchError((e, s) {
      print('[TCP Proxy] Error flushing socket during sendRawJson: $e\n$s');
      // Consider destroying socket on flush error?
      // try { clientSocket.destroy(); } catch (_) {}
    });
  } catch (e, s) {
    // Catch errors like socket being closed
    print('[TCP Proxy] Error sending raw JSON response: $e\n$s');
    try {
      clientSocket.destroy();
    } catch (_) {} // Attempt to close socket
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
    if (data != null) 'data': data.toString(), // Ensure data is stringified
  };
  final response = {
    'jsonrpc': '2.0',
    'id': id, // Use original ID, which might be null
    'error': errorPayload,
  };
   try {
     final responseString = jsonEncode(response);
     _sendRawJson(clientSocket, responseString);
   } catch (e) {
      print('[TCP Proxy] CRITICAL: Error encoding error response: $e');
    // Fallback to pre-formatted string if JSON encoding fails
      try {
      // Ensure ID is JSON compatible (null, string, number)
      String idString = 'null';
      if (id is String) {
        idString =
            '"${jsonEncode(id).substring(1, jsonEncode(id).length - 1)}"'; // Basic string escape
      } else if (id is num) {
        idString = id.toString();
      }
      final fallbackError =
          '{"jsonrpc":"2.0","id":$idString,"error":{"code":$internalErrorCode,"message":"Proxy failed to encode error response"}}\n';
         clientSocket.write(fallbackError);
      clientSocket.flush().catchError((flushError, stack) {
        print(
          '[TCP Proxy] Error flushing socket during fallback error send: $flushError\n$stack',
        );
         });
    } catch (fallbackErr, stack) {
      print(
        '[TCP Proxy] CRITICAL: Failed even to send fallback error: $fallbackErr\n$stack',
      );
      try {
        clientSocket.destroy();
      } catch (_) {} // Final attempt: close socket
      }
   }
}
