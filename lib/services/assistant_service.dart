import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_memos/models/conversation.dart';
import 'package:flutter_memos/models/message.dart';
import 'package:flutter_memos/utils/env.dart';

class AssistantService {
  static final AssistantService _instance = AssistantService._internal();
  factory AssistantService() => _instance;
  AssistantService._internal();

  final String _baseUrl = Env.mcpServerUrl;
  final String _mcpKey = Env.mcpServerKey;

  /// Helper function to call the assistant API
  Future<dynamic> _assistantRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    // Safety check for missing configuration
    if (_baseUrl.isEmpty) {
      throw Exception('MCP_SERVER_URL is not configured in .env file');
    }

    if (_mcpKey.isEmpty) {
      throw Exception('MCP_SERVER_KEY is not configured in .env file');
    }

    final url = Uri.parse('$_baseUrl/api/mcp/assistant$endpoint');

    // Ensure the token is properly trimmed to avoid issues with whitespace
    final token = _mcpKey.trim();

    print('[assistantRequest] $method => $url');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: data != null ? json.encode(data) : null,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('[assistantRequest] Response status: ${response.statusCode}');

      if (!response.statusCode.toString().startsWith('2')) {
        final text = response.body;
        print('[assistantRequest] Error response: $text');
        throw Exception('Assistant request failed ${response.statusCode} - $text');
      }

      final contentType = response.headers['content-type'] ?? '';
      final text = response.body;

      if (contentType.contains('application/json')) {
        return json.decode(text);
      } else {
        return text;
      }
    } catch (error) {
      print('[assistantRequest] Request failed: $error');

      // Provide more detailed diagnostics for connection issues
      if (error.toString().contains('Connection refused') ||
          error.toString().contains('Failed to connect')) {
        print('[assistantRequest] Connection refused to $_baseUrl. If using Docker, make sure you\'re using the service name rather than \'localhost\'.');
        throw Exception('Could not connect to Assistant API at $_baseUrl. In Docker environments, use the service name (e.g., \'mcp-server:8080\') instead of \'localhost\'.');
      }

      rethrow;
    }
  }

  /// Create a new conversation
  Future<Map<String, dynamic>> createConversation({String? userId}) async {
    final response = await _assistantRequest(
      'POST',
      '/conversation',
      data: {'userId': userId ?? 'testUser'},
    );
    
    final conversationId = response['data']['conversationId'];
    final conversation = Conversation.fromJson(response['data']['conversation']);
    
    return {
      'conversationId': conversationId,
      'conversation': conversation,
    };
  }

  /// Get a conversation by ID
  Future<Conversation> getConversation(String conversationId) async {
    final response = await _assistantRequest('GET', '/conversation/$conversationId');
    return Conversation.fromJson(response['data']);
  }

  /// Send a message to a conversation
  Future<Map<String, dynamic>> sendMessage(String conversationId, String content) async {
    final response = await _assistantRequest(
      'POST',
      '/conversation/$conversationId/message',
      data: {'content': content},
    );
    
    final conversation = Conversation.fromJson(response['data']['conversation']);
    final newMessage = Message.fromJson(response['data']['newMessage']);
    
    return {
      'conversation': conversation,
      'newMessage': newMessage,
    };
  }
}