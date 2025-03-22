import 'dart:convert';

import 'package:http/http.dart' as http;

/// Hard-code or load from .env
const String mcpServerUrl = "http://localhost:8080";
const String mcpServerKey = "YOUR_MCP_SERVER_KEY";

class McpService {
  McpService._();

  static final McpService instance = McpService._();

  Future<http.Response> _mcpRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$mcpServerUrl/api/mcp$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${mcpServerKey.trim()}',
    };

    switch (method) {
      case 'POST':
        return await http.post(url, headers: headers, body: jsonEncode(body));
      case 'PUT':
        return await http.put(url, headers: headers, body: jsonEncode(body));
      case 'PATCH':
        return await http.patch(url, headers: headers, body: jsonEncode(body));
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        return await http.get(url, headers: headers);
    }
  }

  /// Ping the MCP server
  Future<Map<String, dynamic>> pingMcpServer() async {
    try {
      final resp = await _mcpRequest('/ping');
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        return {
          'status': 'error',
          'message': 'Failed to ping MCP server',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Send data to the MCP server
  Future<Map<String, dynamic>> sendToMcp(Map<String, dynamic> data, {String? target}) async {
    final body = {
      'data': data,
      'target': target,
    };
    final resp = await _mcpRequest('/send', method: 'POST', body: body);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to send data: ${resp.body}');
    }
  }

  /// Fetch data from MCP server
  Future<Map<String, dynamic>> fetchFromMcp(String type, {String? filter}) async {
    String endpoint = '/fetch/$type';
    if (filter != null && filter.isNotEmpty) {
      endpoint += '?filter=${Uri.encodeComponent(filter)}';
    }
    final resp = await _mcpRequest(endpoint);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch $type: ${resp.body}');
    }
  }
}
