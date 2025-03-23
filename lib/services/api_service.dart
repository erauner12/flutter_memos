import 'dart:convert';

import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/utils/env.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = Env.apiBaseUrl;
  final String _apiKey = Env.memosApiKey;

  Future<http.Response> _get(String endpoint) async {
    // If no endpoint is provided, don't modify the URL at all
    final url =
        endpoint.isEmpty
            ? Uri.parse(_baseUrl)
            : Uri.parse('$_baseUrl/${endpoint.replaceAll('//', '/')}');
    
    print('[API] GET => $url');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
    );

    print('[API] Response status: ${response.statusCode}');
    return response;
  }

  Future<http.Response> _post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    // Handle the URL construction based on endpoint
    final url = endpoint.isEmpty ?
        Uri.parse(_baseUrl) :
        Uri.parse('$_baseUrl/${endpoint.replaceAll('//', '/')}');
    
    // Remove trailing slash if present
    final finalUrl = url.toString().endsWith('/') ?
        Uri.parse(url.toString().substring(0, url.toString().length - 1)) :
        url;
    
    print('[API] POST => $finalUrl');
    print('[API] Request body: ${jsonEncode(data)}');

    final response = await http.post(
      finalUrl,
      headers: {
        'Content-Type': 'text/plain;charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(data),
    );

    print('[API] Response status: ${response.statusCode}');
    return response;
  }

  Future<http.Response> _patch(String endpoint, Map<String, dynamic> data) async {
    // Don't add a slash if the base URL already ends with one or endpoint starts with one
    final slash = _baseUrl.endsWith('/') || endpoint.startsWith('/') ? '' : '/';
    final url = Uri.parse('$_baseUrl$slash$endpoint');
    print('[API] PATCH => $url');
    print('[API] Request body: ${jsonEncode(data)}');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'text/plain;charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(data),
    );

    print('[API] Response status: ${response.statusCode}');
    return response;
  }

  Future<http.Response> _delete(String endpoint) async {
    // Don't add a slash if the base URL already ends with one or endpoint starts with one
    final slash = _baseUrl.endsWith('/') || endpoint.startsWith('/') ? '' : '/';
    final url = Uri.parse('$_baseUrl$slash$endpoint');
    print('[API] DELETE => $url');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'text/plain;charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
    );

    print('[API] Response status: ${response.statusCode}');
    return response;
  }

  // Memo endpoints
  Future<List<Memo>> listMemos({String? filter, String state = ''}) async {
    // For now, let's make a direct request mimicking the curl command
    // that works, without adding any query parameters
    final url = Uri.parse(_baseUrl);
    print('[API] GET => $url');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
    );
    
    print('[API] Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('memos')) {
        return List<Memo>.from(data['memos'].map((x) => Memo.fromJson(x)));
      }
    }
    
    throw Exception('Failed to load memos: ${response.statusCode} - ${response.body}');
  }

  Future<Memo> getMemo(String id) async {
    final formattedId = _formatMemoId(id);
    // If the base URL already ends with 'memos', adjust the path accordingly
    final endpoint =
        _baseUrl.toLowerCase().endsWith('memos')
            ? id.startsWith('memos/')
                ? id.substring(6)
                : id
            : formattedId;

    final response = await _get(endpoint);
    
    if (response.statusCode == 200) {
      return Memo.fromJson(json.decode(response.body));
    }
    
    throw Exception('Failed to load memo: ${response.statusCode} - ${response.body}');
  }

  Future<Memo> createMemo(Memo memo) async {
    // Make a direct POST to the base URL without any additional path
    // This follows the format shown in the working curl command
    
    // Add creator field if not present - required by the API
    final memoData = memo.toJson();
    if (!memoData.containsKey('creator')) {
      memoData['creator'] = 'users/1'; // Default creator ID
    }
    
    final response = await _post('', memoData);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Memo.fromJson(json.decode(response.body));
    }
    
    throw Exception('Failed to create memo: ${response.statusCode} - ${response.body}');
  }

  Future<Memo> updateMemo(String id, Memo memo) async {
    final formattedId = _formatMemoId(id);
    // If the base URL already ends with 'memos', adjust the path accordingly
    final endpoint =
        _baseUrl.toLowerCase().endsWith('memos')
            ? id.startsWith('memos/')
                ? id.substring(6)
                : id
            : formattedId;

    final response = await _patch(endpoint, memo.toJson());
    
    if (response.statusCode == 200) {
      return Memo.fromJson(json.decode(response.body));
    }
    
    throw Exception('Failed to update memo: ${response.statusCode} - ${response.body}');
  }

  Future<void> deleteMemo(String id) async {
    final formattedId = _formatMemoId(id);
    // If the base URL already ends with 'memos', adjust the path accordingly
    final endpoint =
        _baseUrl.toLowerCase().endsWith('memos')
            ? id.startsWith('memos/')
                ? id.substring(6)
                : id
            : formattedId;

    final response = await _delete(endpoint);
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete memo: ${response.statusCode} - ${response.body}');
    }
  }

  // Comments endpoints
  Future<List<Comment>> listMemoComments(String memoId) async {
    final formattedId = _formatMemoId(memoId);
    // If the base URL already ends with 'memos', adjust the path accordingly
    final endpoint =
        _baseUrl.toLowerCase().endsWith('memos')
            ? '${memoId.startsWith('memos/') ? memoId.substring(6) : memoId}/comments'
            : '$formattedId/comments';

    final response = await _get(endpoint);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseComments(data);
    }
    
    throw Exception('Failed to load comments: ${response.statusCode} - ${response.body}');
  }

  Future<Comment> createMemoComment(String memoId, Comment comment) async {
    final formattedId = _formatMemoId(memoId);
    // If the base URL already ends with 'memos', adjust the path accordingly
    final endpoint =
        _baseUrl.toLowerCase().endsWith('memos')
            ? '${memoId.startsWith('memos/') ? memoId.substring(6) : memoId}/comments'
            : '$formattedId/comments';

    final response = await _post(endpoint, comment.toJson());
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Comment.fromJson(json.decode(response.body));
    }
    
    throw Exception('Failed to create comment: ${response.statusCode} - ${response.body}');
  }

  // Helper functions
  String _formatMemoId(String id) {
    return id.startsWith('memos/') ? id : 'memos/$id';
  }

  List<Comment> _parseComments(dynamic data) {
    // Handle different comment data structures
    if (data is List) {
      if (data.isEmpty) return [];
      
      // If we have an array of [id, object] pairs
      if (data[0] is List) {
        return data.map<Comment>((entry) {
          if (entry is List && entry.length == 2) {
            final commentId = entry[0];
            final commentObj = entry[1];
            commentObj['id'] = commentId;
            return Comment.fromJson(commentObj);
          }
          return Comment.fromJson({'id': 'unknown', 'content': 'Error parsing comment'});
        }).toList();
      }
      
      // If we have an array of objects with content property
      if (data[0] is Map && data[0].containsKey('content')) {
        return data.map<Comment>((x) => Comment.fromJson(x)).toList();
      }
    }
    
    // If data contains a "memos" array (another format we might receive)
    if (data is Map && data.containsKey('memos') && data['memos'] is List) {
      return data['memos'].map<Comment>((memo) {
        final commentData = {
          'id': memo['name'],
          'content': memo['content'],
          'createTime': memo['createTime'] != null
              ? DateTime.parse(memo['createTime']).millisecondsSinceEpoch
              : null,
          'creatorId': memo['creator']?.toString().replaceAll('users/', ''),
        };
        return Comment.fromJson(commentData);
      }).toList();
    }
    
    // If data contains a "comments" property with an array
    if (data is Map && data.containsKey('comments') && data['comments'] is List) {
      return data['comments'].map<Comment>((x) => Comment.fromJson(x)).toList();
    }
    
    print('Unknown comments format, raw data: $data');
    return [];
  }
}