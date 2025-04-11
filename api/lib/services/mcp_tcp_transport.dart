// lib/services/mcp_tcp_transport.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:mcp_dart/mcp_dart.dart' as mcp_dart;
// Assuming shared stdio helpers are accessible or reimplemented if needed
// If ReadBuffer/deserializeMessage/serializeMessage are not public, copy them
// or import the specific file if possible (adjust path if needed).
// For now, let's assume they are available via mcp_dart main export or shared.
// If not, we'll need to adjust imports or copy implementations.
// NOTE: Accessing 'src' directly is generally discouraged. If mcp_dart doesn't
// export these, they might need to be copied or reimplemented.
import 'package:mcp_dart/src/shared/stdio.dart'; // Check if this export works

/// Client transport for TCP: connects to a server over a TCP socket
/// and communicates using newline-delimited JSON messages.
class TcpClientTransport implements mcp_dart.Transport {
  final String host;
  final int port;
  Socket? _socket;
  final ReadBuffer _readBuffer = ReadBuffer();
  final Completer<void> _closeCompleter = Completer<void>();
  bool _isClosing = false;
  StreamSubscription<Uint8List>? _socketSubscription;

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
    _reportError(StateError("Socket error: $error"));
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
     if (_isClosing) return;
     try {
       onerror?.call(error);
     } catch (e) {
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
      final jsonString = serializeMessage(message); // Assumes this adds newline
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
    await _socketSubscription?.cancel();
    _socketSubscription = null;

    // Close the socket
    try {
      await _socket?.close(); // Wait for the socket to acknowledge close
       if (kDebugMode) {
         print('[TcpClientTransport] Socket closed.');
       }
    } catch (e) {
       if (kDebugMode) {
         print("[TcpClientTransport] Error closing socket: $e");
       }
       // Report error but continue cleanup
       _reportError(StateError("Error closing socket: $e"));
    } finally {
       _socket = null; // Clear the socket reference
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

    if (!_closeCompleter.isCompleted) {
        _closeCompleter.complete();
    }
     if (kDebugMode) {
       print('[TcpClientTransport] Transport closed.');
     }
    return _closeCompleter.future;
  }
}
