import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp_dart;
import 'package:mcp_dart/src/shared/transport.dart'; // Import base Transport

/// Client transport for SSE: connects to a server over HTTP/SSE.
/// Sends messages via HTTP POST requests.
class SseClientTransport implements Transport {
  final String managerHost;
  final int managerPort;
  final String ssePath; // Path for the initial SSE connection, e.g., "/sse"
  // ADD: Flag for HTTPS
  final bool isSecure;

  HttpClient? _httpClient;
  StreamSubscription<String>? _sseSubscription;
  String? _messageEndpointPath; // Received from server, e.g., "/messages"
  String? _sessionId; // Received from server
  final Completer<void> _closeCompleter = Completer<void>();
  bool _isClosing = false;
  bool _isConnected = false;

  @override
  void Function()? onclose;

  @override
  void Function(Error error)? onerror;

  @override
  void Function(mcp_dart.JsonRpcMessage message)? onmessage;

  @override
  String? get sessionId => _sessionId;

  SseClientTransport({
    required this.managerHost,
    required this.managerPort,
    this.ssePath = '/sse', // Default SSE path
    this.isSecure = false, // Default to HTTP
  });

  @override
  Future<void> start() async {
    if (_isConnected || _isClosing) {
      throw StateError("SseClientTransport already started or is closing.");
    }
    if (kDebugMode) {
      print(
        '[SseClientTransport] Attempting SSE connection to ${isSecure ? 'https' : 'http'}://$managerHost:$managerPort$ssePath...',
      );
    }

    _httpClient = HttpClient();
    // Allow self-signed certificates in debug mode if needed for local testing
    // if (kDebugMode && isSecure) { // Only relevant for HTTPS
    //   _httpClient?.badCertificateCallback =
    //       (X509Certificate cert, String host, int port) => true;
    // }

    try {
      // MODIFY: Use Uri.https or Uri.http based on isSecure flag
      final uri =
          isSecure
              ? Uri.https('$managerHost:$managerPort', ssePath)
              : Uri.http('$managerHost:$managerPort', ssePath);

      final request = await _httpClient!.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      request.headers.set(HttpHeaders.connectionHeader, 'keep-alive');

      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        final body = await response.transform(utf8.decoder).join();
        throw HttpException(
          'SSE connection failed: ${response.statusCode} ${response.reasonPhrase}\n$body',
          uri: request.uri,
        );
      }

      String currentEvent = '';
      String currentData = '';

      _sseSubscription = response
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (_isClosing) return;
          // print('[SSE Raw] $line'); // Debug raw lines

          if (line.isEmpty) {
            // End of an event
            if (currentEvent.isNotEmpty && currentData.isNotEmpty) {
              _processSseEvent(currentEvent, currentData);
            }
            currentEvent = '';
            currentData = '';
          } else if (line.startsWith('event:')) {
            currentEvent = line.substring('event:'.length).trim();
          } else if (line.startsWith('data:')) {
            // Append data, handling multi-line data
            final dataLine = line.substring('data:'.length).trimLeft();
            currentData = currentData.isEmpty ? dataLine : '$currentData\n$dataLine';
          } else if (line.startsWith('id:')) {
            // Optional: handle event IDs if needed
          } else if (line.startsWith(':')) {
            // Comment line, ignore
          } else {
             if (kDebugMode) {
               print('[SseClientTransport] Ignoring unknown SSE line: $line');
             }
          }
        },
        onError: (error, stackTrace) {
          if (_isClosing) return;
          if (kDebugMode) {
            print(
              '[SseClientTransport] SSE stream error: $error\n$stackTrace',
            );
          }
          final transportError = StateError("SSE stream error: $error");
          _reportError(transportError);
          close(); // Close on stream error
        },
        onDone: () {
          if (_isClosing) return;
          if (kDebugMode) {
            print('[SseClientTransport] SSE stream closed by server.');
          }
          close(); // Close when the server closes the stream
        },
        cancelOnError: false, // We handle errors explicitly
      );

      // Wait briefly to see if the endpoint event arrives quickly
      await Future.delayed(const Duration(milliseconds: 100));
      if (_sessionId == null || _messageEndpointPath == null) {
         // Give it a bit more time, maybe network is slow
         await Future.delayed(const Duration(seconds: 2));
         if (_sessionId == null || _messageEndpointPath == null) {
          // Check if we are already closing due to an error during the delay
          if (_isClosing) {
            // Error likely occurred in _processSseEvent or stream listener
            // The error has already been reported and close() called.
            // Throw a more specific error indicating the root cause if possible,
            // otherwise rethrow a generic state error.
            throw StateError(
              "SSE connection failed during initialization (check previous logs for details).",
            );
          } else {
            // If not closing, it's a timeout waiting for the endpoint event
            throw StateError(
              "SSE connection established, but did not receive 'endpoint' event with session details in time.",
            );
          }
        }
      }

      _isConnected = true;
      _isClosing = false; // Ensure state is correct after potential delays
      if (kDebugMode) {
        print(
          '[SseClientTransport] SSE Connected. Session: $_sessionId, Message Path: $_messageEndpointPath',
        );
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[SseClientTransport] Error during SSE start: $e\n$s');
      }
      // Ensure we are marked as closing *before* reporting error and cleaning up
      if (!_isClosing) {
        _isClosing = true; // Mark as closing if not already
        final error =
            e is StateError
                ? e
                : StateError("Failed to establish SSE connection: $e");
        _reportError(error);
        await close(); // Ensure cleanup on start failure
        throw error; // Rethrow the captured or wrapped error
      } else {
        // If already closing (e.g., due to error in listener during delay), just rethrow
        rethrow;
      }
    }
  }

  void _processSseEvent(String event, String data) {
    if (kDebugMode) {
      print('[SseClientTransport] Received SSE Event: $event, Data: $data');
    }
    switch (event) {
      case 'endpoint':
        try {
          // Expect data like: /messages?sessionId=xyz
          final uri = Uri.parse(data);
          _messageEndpointPath = uri.path;
          _sessionId = uri.queryParameters['sessionId'];
          if (_sessionId == null || _messageEndpointPath == null || _sessionId!.isEmpty || _messageEndpointPath!.isEmpty) {
             throw FormatException("Invalid endpoint data format: $data");
          }
           if (kDebugMode) {
             print('[SseClientTransport] Endpoint details received: Path=$_messageEndpointPath, Session=$_sessionId');
           }
        } catch (e) {
          final error = StateError("Failed to parse 'endpoint' event data: $e");
          _reportError(error);
          close(); // Close if endpoint data is invalid
        }
        break;
      case 'message':
        try {
          final messageJson = jsonDecode(data) as Map<String, dynamic>;
          final message = mcp_dart.JsonRpcMessage.fromJson(messageJson);
          onmessage?.call(message);
        } catch (e) {
          final error = StateError("Failed to parse 'message' event data: $e");
          _reportError(error);
          // Decide whether to close on message parse error - maybe log and continue?
        }
        break;
      default:
        if (kDebugMode) {
          print('[SseClientTransport] Received unknown SSE event type: $event');
        }
    }
  }

  void _reportError(Error error) {
    if (_isClosing) return;
    try {
      onerror?.call(error);
    } catch (e) {
      if (kDebugMode) {
        print("[SseClientTransport] Error within onerror handler: $e");
      }
    }
  }

  @override
  Future<void> send(mcp_dart.JsonRpcMessage message) async {
    if (_isClosing || !_isConnected || _httpClient == null || _sessionId == null || _messageEndpointPath == null) {
      throw StateError(
        "Cannot send message: SSE transport is not connected or is closing.",
      );
    }

    // MODIFY: Use Uri.https or Uri.http based on isSecure flag
    final postUri =
        isSecure
            ? Uri.https('$managerHost:$managerPort', _messageEndpointPath!, {
              'sessionId': _sessionId!,
            })
            : Uri.http('$managerHost:$managerPort', _messageEndpointPath!, {
              'sessionId': _sessionId!,
            });

    if (kDebugMode) {
      // Log the JSON representation for better readability
      String messageJsonString = '(serialization error)';
      try {
        messageJsonString = jsonEncode(message.toJson());
      } catch (_) {}
      print(
        '[SseClientTransport] Sending POST to $postUri with message: $messageJsonString',
      );
    }

    HttpClientRequest? postRequest;
    try {
      postRequest = await _httpClient!.postUrl(postUri);
      postRequest.headers.contentType = ContentType.json;
      final bodyBytes = utf8.encode(jsonEncode(message.toJson()));
      postRequest.contentLength = bodyBytes.length;
      postRequest.add(bodyBytes);

      final response = await postRequest.close();

      if (response.statusCode != HttpStatus.accepted) {
         final responseBody = await response.transform(utf8.decoder).join();
        // Log the error response body
        if (kDebugMode) {
          print(
            '[SseClientTransport] POST failed (Status: ${response.statusCode}). Response body: $responseBody',
          );
        }
        throw HttpException(
          'Failed to send message: ${response.statusCode} ${response.reasonPhrase}\n$responseBody',
          uri: postUri,
        );
      }
      // Consume response body to free resources
      await response.drain();
       if (kDebugMode) {
         print('[SseClientTransport] POST successful (Status: ${response.statusCode})');
       }

    } catch (e, s) {
      if (kDebugMode) {
        print("[SseClientTransport] Error sending POST message: $e\n$s");
      }
      final error = StateError("Error sending message via POST: $e");
      _reportError(error);
      // Consider closing the transport on persistent send errors?
      // close();
      throw error;
    }
  }

  @override
  Future<void> close() async {
    if (_isClosing) {
      return _closeCompleter.future;
    }
    _isClosing = true;
    _isConnected = false;
    if (kDebugMode) {
      print('[SseClientTransport] Closing SSE connection...');
    }

    await _sseSubscription?.cancel();
    _sseSubscription = null;

    _httpClient?.close(force: true); // Force close HTTP client resources
    _httpClient = null;

    _sessionId = null;
    _messageEndpointPath = null;

    try {
      onclose?.call();
    } catch (e) {
      if (kDebugMode) {
        print("[SseClientTransport] Error in onclose handler: $e");
      }
    }

    if (!_closeCompleter.isCompleted) {
      _closeCompleter.complete();
    }
    if (kDebugMode) {
      print('[SseClientTransport] SSE Transport closed.');
    }
    return _closeCompleter.future;
  }
}
