import 'dart:convert';

import 'package:flutter_memos/utils/env.dart';
import 'package:http/http.dart' as http;

class McpService {
  static final McpService _instance = McpService._internal();
  factory McpService() => _instance;
  McpService._internal();

  final String _baseUrl = Env.mcpServerUrl;
  final String _mcpKey = Env.mcpServerKey;

  /// Make a request to the MCP server
  Future<dynamic> _mcpRequest(
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

    final url = Uri.parse('$_baseUrl/api/mcp$endpoint');
    
    // Ensure the token is properly trimmed to avoid issues with whitespace
    final token = _mcpKey.trim();

    print('[mcpRequest] $method => $url');
    print('[mcpRequest] Using key: ***${token.substring(token.length - 4)} (length: ${token.length})');

    // Prepare request with enhanced headers
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Print the full authorization header for debugging (mask most of the token)
    final authHeader = 'Bearer $token';
    final maskedAuth =
        'Bearer ${'*' * (token.length - 6)}${token.substring(token.length - 6)}';
    print('[mcpRequest] Auth header: $maskedAuth');

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
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: data != null ? json.encode(data) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('[mcpRequest] Response status: ${response.statusCode}');

      if (!response.statusCode.toString().startsWith('2')) {
        print('[mcpRequest] Error response: ${response.body}');
        throw Exception('MCP request failed ${response.statusCode} - ${response.body}');
      }

      if (response.headers['content-type']?.contains('application/json') ?? false) {
        return json.decode(response.body);
      } else {
        return response.body;
      }
    } catch (error) {
      print('[mcpRequest] Request failed: $error');
      
      // Provide more detailed diagnostics for connection issues
      if (error.toString().contains('Connection refused') ||
          error.toString().contains('Failed to connect')) {
        print('[mcpRequest] Connection refused to $_baseUrl. If using Docker, make sure you\'re using the service name rather than \'localhost\'.');
        throw Exception('Could not connect to MCP server at $_baseUrl. If using Docker, use the service name (e.g., \'mcp-server:8080\') instead of \'localhost\'.');
      }
      
      rethrow;
    }
  }

  /// Ping the MCP server to check connectivity
  Future<Map<String, dynamic>> pingMcpServer() async {
    try {
      // Special case for ping - don't throw if config is missing,
      // return a friendly error object instead
      if (_baseUrl.isEmpty || _mcpKey.isEmpty) {
        print('[pingMcpServer] Missing configuration: ${_baseUrl.isEmpty ? 'URL missing' : 'Key missing'}');
        return {
          'status': 'error',
          'message': 'MCP server not configured',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      final response = await _mcpRequest('GET', '/ping');
      return response;
    } catch (error) {
      print('Error pinging MCP server: $error');
      return {
        'status': 'error',
        'message': error.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Send data to the MCP server
  Future<dynamic> sendToMcp(dynamic data, {String? target}) async {
    // Safety check before attempting to send
    if (_baseUrl.isEmpty || _mcpKey.isEmpty) {
      print('[sendToMcp] Missing configuration: ${_baseUrl.isEmpty ? 'URL missing' : 'Key missing'}');
      throw Exception('MCP server not configured properly');
    }

    // Format data to match what the MCP server expects
    final requestData = {
      'data': data,
      if (target != null) 'target': target,
    };

    print('[sendToMcp] Sending data: ${json.encode(requestData)}');

    // Add a specific error handler for MCP authorization issues
    try {
      return await _mcpRequest('POST', '/send', data: requestData);
    } catch (e) {
      if (e.toString().contains('401')) {
        print(
          '[sendToMcp] Authorization error: MCP server rejected the credentials',
        );
        throw Exception(
          'MCP authorization failed: Please check your MCP_SERVER_KEY',
        );
      }
      rethrow;
    }
  }

  /// Fetch data from MCP server
  Future<dynamic> fetchFromMcp(String type, {String? filter}) async {
    // Safety check before attempting to fetch
    if (_baseUrl.isEmpty || _mcpKey.isEmpty) {
      print('[fetchFromMcp] Missing configuration: ${_baseUrl.isEmpty ? 'URL missing' : 'Key missing'}');
      throw Exception('MCP server not configured properly');
    }

    String endpoint = '/fetch/$type';
    if (filter != null && filter.isNotEmpty) {
      endpoint += '?filter=${Uri.encodeComponent(filter)}';
    }
    
    final response = await _mcpRequest('GET', endpoint);
    return response;
  }
}
