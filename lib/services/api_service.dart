import 'dart:convert';

import 'package:http/http.dart' as http;

/// For demonstration, set your Memos server info here.
/// In a real project, you might load these from a secure config or .env.
const String apiBaseUrl = "http://localhost:5230"; // e.g. your Memos server
const String memosApiKey =
    "eyJhbGciOiJIUzI1NiIsImtpZCI6InYxIiwidHlwIjoiSldUIn0.eyJuYW1lIjoiZXJhdW5lciIsImlzcyI6Im1lbW9zIiwic3ViIjoiMSIsImF1ZCI6WyJ1c2VyLmFjY2Vzcy10b2tlbiJdLCJpYXQiOjE3NDI0OTEyNzN9.13XNLkx2ydJBuqVdxnJm9_r0yjpFnKTOtJ_O7gpJbJc";

enum V1State { normal, archived }
enum V1Visibility { public, private, unlisted }

/// Basic Memo model
class Memo {
  final String id;
  final String content;
  final bool pinned;
  final V1State state;
  final V1Visibility visibility;

  Memo({
    required this.id,
    required this.content,
    required this.pinned,
    required this.state,
    required this.visibility,
  });

  factory Memo.fromJson(Map<String, dynamic> json) {
    // Attempt to parse state and visibility
    final stateStr = (json['state'] ?? '').toString().toLowerCase();
    final visibilityStr = (json['visibility'] ?? '').toString().toLowerCase();

    V1State parsedState = V1State.normal;
    if (stateStr == 'archived') {
      parsedState = V1State.archived;
    }

    V1Visibility parsedVisibility = V1Visibility.public;
    if (visibilityStr == 'private') {
      parsedVisibility = V1Visibility.private;
    } else if (visibilityStr == 'unlisted') {
      parsedVisibility = V1Visibility.unlisted;
    }

    // name might look like "memos/123"
    final String name = (json['name'] ?? '');
    final List<String> parts = name.split('/');
    final idPart = parts.isNotEmpty ? parts.last : name;

    return Memo(
      id: idPart,
      content: (json['content'] ?? '') as String,
      pinned: (json['pinned'] ?? false) as bool,
      state: parsedState,
      visibility: parsedVisibility,
    );
  }
}

/// Comment model - can be basically the same as Memo in Memos API
class MemoComment {
  final String id;
  final String content;

  MemoComment({
    required this.id,
    required this.content,
  });

  factory MemoComment.fromJson(Map<String, dynamic> json) {
    final String name = (json['name'] ?? '');
    final List<String> parts = name.split('/');
    final idPart = parts.isNotEmpty ? parts.last : name;

    return MemoComment(
      id: idPart,
      content: (json['content'] ?? '') as String,
    );
  }
}

/// API Service
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  /// Shared request logic with Authorization header
  Future<http.Response> _authorizedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$apiBaseUrl/api/v1/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $memosApiKey',
    };

    http.Response response;
    
    try {
      switch (method) {
        case 'POST':
          response = await http.post(url, headers: headers, body: jsonEncode(body));
          break;
        case 'PATCH':
          response = await http.patch(url, headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          response = await http.get(url, headers: headers);
          break;
      }
      
      // Check if response is likely HTML instead of JSON
      if (response.statusCode != 200 &&
          response.body.trim().toLowerCase().startsWith('<!doctype') ||
          response.body.trim().toLowerCase().startsWith('<html')) {
        throw Exception("Received HTML response instead of JSON. Check the API URL and credentials.");
      }
      
      return response;
    } catch (e) {
      throw Exception("API request failed: ${e.toString()}");
    }
  }

  /// List memos with optional filtering by state or tags
  /// Adjust to match your Memos server's API design
  Future<List<Memo>> listMemos({V1State? state, String? tag}) async {
    // Example query:
    // /v1/memos?state=NORMAL&filter=tags=="work"
    final queryParams = <String>[];
    if (state != null) {
      queryParams.add('state=${state == V1State.archived ? 'ARCHIVED' : 'NORMAL'}');
    }
    if (tag != null && tag.isNotEmpty) {
      queryParams.add('filter=tags=="$tag"');
    }

    final endpoint = queryParams.isEmpty ? 'memos' : 'memos?${queryParams.join('&')}';
    
    try {
      final response = await _authorizedRequest(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final memosData = (data['memos'] ?? []) as List;
        return memosData.map((m) => Memo.fromJson(m)).toList();
      } else {
        throw Exception("Failed to list memos: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception("Failed to parse API response as JSON. The server might be returning an error page or invalid data.");
      }
      rethrow;
    }
  }

  /// Create a new memo
  Future<Memo> createMemo(String content,
      {bool pinned = false, V1Visibility visibility = V1Visibility.public}) async {
    final body = {
      'content': content,
      'pinned': pinned,
      'visibility': visibility.name.toUpperCase(),
    };

    final response = await _authorizedRequest(
      'memos',
      method: 'POST',
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Memo.fromJson(data);
    } else {
      throw Exception("Failed to create memo: ${response.body}");
    }
  }

  /// Get a single memo by ID
  Future<Memo> getMemo(String id) async {
    try {
      final response = await _authorizedRequest('memos/$id');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Memo.fromJson(data);
      } else {
        throw Exception("Failed to get memo: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception("Failed to parse API response as JSON. The server might be returning an error page or invalid data.");
      }
      rethrow;
    }
  }

  /// Update a memo
  Future<Memo> updateMemo(String id,
      {bool? pinned, V1State? state, String? content}) async {
    final body = <String, dynamic>{};
    if (pinned != null) {
      body['pinned'] = pinned;
    }
    if (state != null) {
      body['state'] = state == V1State.archived ? 'ARCHIVED' : 'NORMAL';
    }
    if (content != null) {
      body['content'] = content;
    }

    final response = await _authorizedRequest('memos/$id', method: 'PATCH', body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Memo.fromJson(data);
    } else {
      throw Exception("Failed to update memo: ${response.body}");
    }
  }

  /// Delete a memo
  Future<void> deleteMemo(String id) async {
    final response = await _authorizedRequest('memos/$id', method: 'DELETE');
    if (response.statusCode != 200) {
      throw Exception("Failed to delete memo: ${response.body}");
    }
  }

  /// List comments for a memo
  Future<List<MemoComment>> listMemoComments(String memoId) async {
    final response = await _authorizedRequest('memos/$memoId/comments');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = (data ?? []) as List;
      return list.map((c) => MemoComment.fromJson(c)).toList();
    } else {
      throw Exception("Failed to list comments: ${response.body}");
    }
  }

  /// Add comment to a memo
  Future<MemoComment> addCommentToMemo(String memoId, String commentContent) async {
    final body = {
      'content': commentContent,
      // 'creator': 'users/1' or similar if your server requires it
    };

    final response = await _authorizedRequest('memos/$memoId/comments',
        method: 'POST', body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MemoComment.fromJson(data);
    } else {
      throw Exception("Failed to add comment: ${response.body}");
    }
  }

  /// Test the API connection and credentials
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/ping'),
        headers: {
          'Authorization': 'Bearer $memosApiKey',
        },
      );

      // Even a 401 would indicate the server is reachable, just credentials are wrong
      return response.statusCode == 200;
    } catch (e) {
      print("API connection test failed: ${e.toString()}");
      return false;
    }
  }
}