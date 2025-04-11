import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Hide ReadBuffer from foundation to avoid conflict with the local copy
import 'package:flutter/foundation.dart' hide ReadBuffer;
import 'package:mcp_dart/mcp_dart.dart' as mcp_dart;
// Removed: import 'package:mcp_dart/src/shared/stdio.dart';

// --- Copied Helpers from mcp_dart/src/shared/stdio.dart ---

/// Buffers a continuous stdio stream (like stdin) and parses discrete,
/// newline-terminated JSON-RPC messages.
class ReadBuffer {
  final BytesBuilder _builder = BytesBuilder();
  Uint8List? _bufferCache;

  /// Appends a chunk of binary data (received from the stream) to the buffer.
  void append(Uint8List chunk) {
    _builder.add(chunk);
    _bufferCache = null;
  }

  /// Attempts to read a complete, newline-terminated JSON-RPC message
  /// from the accumulated buffer.
  ///
  /// Returns the parsed [JsonRpcMessage] if a complete message is found,
  /// otherwise returns null.
  ///
  /// Throws [FormatException] if the extracted line is not valid JSON or
  /// if the JSON does not represent a known [JsonRpcMessage] structure.
  mcp_dart.JsonRpcMessage? readMessage() {
    _bufferCache ??= _builder.toBytes();

    if (_bufferCache == null || _bufferCache!.isEmpty) {
      return null;
    }

    final newlineIndex = _bufferCache!.indexOf(10); // ASCII code for '\n'
    if (newlineIndex == -1) {
      return null; // No complete line found yet
    }

    // Extract the line bytes (excluding the newline character)
    final lineBytes = Uint8List.sublistView(_bufferCache!, 0, newlineIndex);

    String line;
    try {
      // Decode the line as UTF-8
      line = utf8.decode(lineBytes);
    } catch (e) {
      // Handle potential decoding errors (e.g., invalid UTF-8 sequence)
      // Log the error and discard the problematic segment
      if (kDebugMode) {
        print("[ReadBuffer] Error decoding UTF-8 line: $e");
      }
      _updateBufferAfterRead(newlineIndex); // Discard the invalid line
      return null; // Indicate no valid message was read
    }

    // Update the buffer to remove the processed line (including newline)
    _updateBufferAfterRead(newlineIndex);

    // Deserialize the valid JSON line
    return deserializeMessage(line);
  }

  /// Clears the internal buffer and resets the state.
  void clear() {
    _builder.clear();
    _bufferCache = null;
  }

  /// Updates the buffer by removing the processed line and its newline character.
  void _updateBufferAfterRead(int newlineIndex) {
    // Check if there are bytes remaining after the newline
    if (_bufferCache!.length > newlineIndex + 1) {
      final remainingBytes = Uint8List.sublistView(
        _bufferCache!,
        newlineIndex + 1,
      );
      _builder.clear();
      _builder.add(remainingBytes);
    } else {
      // No bytes remaining, just clear the builder
      _builder.clear();
    }
    _bufferCache = null; // Invalidate the cache
  }
}

/// Deserializes a single line of text (assumed to be a JSON object)
/// into a [JsonRpcMessage] using its factory constructor.
///
/// Throws [FormatException] if the line is not valid JSON.
mcp_dart.JsonRpcMessage deserializeMessage(String line) {
  try {
    final jsonMap = jsonDecode(line) as Map<String, dynamic>;
    // Use the factory constructor from the imported mcp_dart types
    return mcp_dart.JsonRpcMessage.fromJson(jsonMap);
  } on FormatException catch (e) {
    if (kDebugMode) {
      print("[deserializeMessage] Failed to decode JSON line: $line");
    }
    throw FormatException("Invalid JSON received: ${e.message}", line);
  } catch (e) {
    // Catch other potential errors during JsonRpcMessage parsing
    if (kDebugMode) {
      print(
        "[deserializeMessage] Failed to parse JsonRpcMessage from line: $line. Error: $e",
      );
    }
    rethrow; // Rethrow other errors
  }
}

/// Serializes a [JsonRpcMessage] into a JSON string suitable for transmission,
/// appending a newline character for line-based protocols like stdio.
String serializeMessage(mcp_dart.JsonRpcMessage message) {
  try {
    final json = jsonEncode(message.toJson());
    return '$json\n'; // Append newline
  } catch (e) {
    if (kDebugMode) {
      print(
        "[serializeMessage] Failed to serialize JsonRpcMessage: $message. Error: $e",
      );
    }
    rethrow; // Rethrow serialization errors
  }
}

// --- End Copied Helpers ---

/// Client transport for TCP: connects to a server over a TCP socket
/// and communicates using newline-delimited JSON messages.
class TcpClientTransport implements mcp_dart.Transport {
  final String host;
  final int port;
  Socket? _socket;
  // Use the locally defined ReadBuffer
  final ReadBuffer _readBuffer = ReadBuffer();
  final Completer<void> _closeCompleter = Completer<void>();
  bool _isClosing = false;
  StreamSubscription<Uint8List>? _socketSubscription;

  // @override annotations should now be valid as we implement mcp_dart.Transport
  @override
  void Function()? onclose;

  @override
  void Function(Error error)? onerror;

  @override
  void Function(mcp_dart.JsonRpcMessage message)? onmessage;

  @override
  String? get sessionId => null; // TCP doesn't have an MCP session ID concept

  TcpClientTransport({required this.host, required this.port});

  @override
  Future<void> start() async {
    if (_socket != null || _isClosing) {
      throw StateError("TcpClientTransport already started or is closing.");
    }

    if (kDebugMode) {
      print('[TcpClientTransport] Attempting to connect to $host:$port...');
    }

    try {
      // Establish the socket connection
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 10));

      if (kDebugMode) {
        print(
          '[TcpClientTransport] Connected to ${_socket?.remoteAddress.address}:${_socket?.remotePort}',
        );
      }

      // Listen for data, errors, and closure
      _socketSubscription = _socket!.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false, // We handle closure in _onDone/_onError
      );

      // Mark as not closing (in case a rapid close was called during connect)
      _isClosing = false;

    } on SocketException catch (e, s) {
      if (kDebugMode) {
        print('[TcpClientTransport] SocketException during connect: $e\n$s');
      }
      _isClosing = true; // Ensure state reflects failure
      final error = StateError("Failed to connect to $host:$port: ${e.message} (OS Error: ${e.osError?.message}, Code: ${e.osError?.errorCode})");
      _reportError(error); // Report the connection error
      throw error; // Rethrow to signal connection failure
    } catch (e, s) {
      if (kDebugMode) {
        print('[TcpClientTransport] Generic error during connect: $e\n$s');
      }
       _isClosing = true;
       final error = StateError("An unexpected error occurred during connection: $e");
      _reportError(error);
      throw error;
    }
  }

  void _onData(Uint8List data) {
     if (_isClosing || _socket == null) return;
     // Add data to buffer and process messages
     try {
       _readBuffer.append(data);
       _processReadBuffer();
     } catch (e) {
       if (kDebugMode) {
         print("[TcpClientTransport] Error processing buffer: $e");
       }
       _reportError(StateError("Error processing received data: $e"));
       // Consider closing on critical buffer errors? For now, log and continue.
     }
  }

   void _processReadBuffer() {
     while (true) {
       try {
        // Use the locally defined ReadBuffer's method
         final message = _readBuffer.readMessage();
         if (message == null) break; // No complete message yet
         try {
           onmessage?.call(message);
         } catch (e) {
           if (kDebugMode) {
             print("[TcpClientTransport] Error in onmessage handler: $e");
           }
           _reportError(StateError("Error in onmessage handler: $e"));
         }
       } catch (error) {
        // Catch errors from readMessage (e.g., FormatException)
         final Error parseError = (error is Error)
             ? error
             : StateError("Message parsing error: $error");
          _reportError(parseError);
         if (kDebugMode) {
           print(
             "[TcpClientTransport] Error parsing message from buffer: $parseError",
           );
         }
         // Decide on recovery strategy. Clearing buffer might lose subsequent valid messages.
         // For now, log and break processing loop for this data chunk.
        // Consider clearing the buffer if errors persist: _readBuffer.clear();
         break;
       }
     }
   }

  void _onError(dynamic error, StackTrace stackTrace) {
     if (_isClosing) return;
    if (kDebugMode) {
      print(
        '[TcpClientTransport] Socket error: $error\n$stackTrace',
      );
    }
    // Ensure we report an Error object
    final errorObj =
        (error is Error) ? error : StateError("Socket error: $error");
    _reportError(errorObj);
    // Close the transport on socket errors
    close();
  }

  void _onDone() {
    if (_isClosing) return;
    if (kDebugMode) {
      print('[TcpClientTransport] Socket closed by remote peer.');
    }
    // Close the transport when the socket is closed by the peer
    close();
  }

   void _reportError(Error error) {
    // Avoid reporting errors if already closing or closed
    if (_isClosing || _socket == null) return;
     try {
       onerror?.call(error);
     } catch (e) {
      // Prevent errors in the handler from crashing the app
       if (kDebugMode) {
         print("[TcpClientTransport] Error within onerror handler: $e");
       }
     }
   }

  @override
  Future<void> send(mcp_dart.JsonRpcMessage message) async {
    if (_isClosing || _socket == null) {
      throw StateError("Cannot send message: TCP transport is not connected or is closing.");
    }

    try {
      // Use the locally defined serializeMessage
      final jsonString = serializeMessage(message);
      final bytes = utf8.encode(jsonString);
      _socket!.add(bytes);
      await _socket!.flush(); // Ensure data is sent immediately
    } catch (e, s) {
       if (kDebugMode) {
         print("[TcpClientTransport] Error sending message: $e\n$s");
       }
       final error = StateError("Error sending message over TCP: $e");
       _reportError(error);
       close(); // Close transport on send error
       throw error; // Rethrow after cleanup attempt
    }
  }

  @override
  Future<void> close() async {
    if (_isClosing) {
      return _closeCompleter.future; // Already closing, return existing future
    }
    _isClosing = true;
    if (kDebugMode) {
      print('[TcpClientTransport] Closing connection to $host:$port...');
    }

    // Cancel the socket listener first
    // Use ?. operator for safety, although _socketSubscription should be non-null if connected
    await _socketSubscription?.cancel();
    _socketSubscription = null;

    // Close the socket
    try {
      // Use ?. operator for safety, although _socket should be non-null if connected/closing started now
      await _socket?.close(); // Wait for the socket to acknowledge close
       if (kDebugMode) {
         print('[TcpClientTransport] Socket closed.');
       }
    } catch (e) {
       if (kDebugMode) {
         print("[TcpClientTransport] Error closing socket: $e");
       }
       // Report error but continue cleanup
      // Ensure we report an Error object
      final errorObj =
          (e is Error) ? e : StateError("Error closing socket: $e");
      // Don't report if already closed fully
      if (_socket != null) {
        _reportError(errorObj);
      }
    } finally {
      _socket = null; // Clear the socket reference *after* attempting close
       _readBuffer.clear(); // Clear any pending buffer data
    }

    // Call the onclose callback *after* cleanup
    try {
      onclose?.call();
    } catch (e) {
      if (kDebugMode) {
        print("[TcpClientTransport] Error in onclose handler: $e");
      }
       // Don't report this via onerror as we are already closing
    }

    // Complete the completer if it hasn't been completed yet
    if (!_closeCompleter.isCompleted) {
        _closeCompleter.complete();
    }
     if (kDebugMode) {
       print('[TcpClientTransport] Transport closed.');
     }
    return _closeCompleter.future;
  }
}
