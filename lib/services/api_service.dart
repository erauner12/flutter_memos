import 'dart:convert';
import 'dart:math' show min;

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

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };
  }

  Future<http.Response> _get(String endpoint) async {
    // If no endpoint is provided, don't modify the URL at all
    final url =
        endpoint.isEmpty
            ? Uri.parse(_baseUrl)
            : Uri.parse('$_baseUrl/${endpoint.replaceAll('//', '/')}');
    
    print('[API] GET => $url');
    print('[API] Using API key: ***${_apiKey.substring(_apiKey.length - 4)}');

    final response = await http.get(
      url,
      headers: _getHeaders(),
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
    print('[API] Using API key: ***${_apiKey.substring(_apiKey.length - 4)}');
    print('[API] Request body: ${jsonEncode(data)}');

    final response = await http.post(
      finalUrl,
      headers: _getHeaders(),
      body: jsonEncode(data),
    );

    print('[API] Response status: ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      print('[API] Error response: ${response.body}');
    }
    return response;
  }

  Future<http.Response> _patch(String endpoint, Map<String, dynamic> data) async {
    // Don't add a slash if the base URL already ends with one or endpoint starts with one
    final slash = _baseUrl.endsWith('/') || endpoint.startsWith('/') ? '' : '/';
    final url = Uri.parse('$_baseUrl$slash$endpoint');
    print('[API] PATCH => $url');
    print('[API] Using API key: ***${_apiKey.substring(_apiKey.length - 4)}');
    print('[API] Request body: ${jsonEncode(data)}');

    final response = await http.patch(
      url,
      headers: _getHeaders(),
      body: jsonEncode(data),
    );

    print('[API] Response status: ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      print('[API] Error response: ${response.body}');
    }
    return response;
  }

  Future<http.Response> _delete(String endpoint) async {
    // Don't add a slash if the base URL already ends with one or endpoint starts with one
    final slash = _baseUrl.endsWith('/') || endpoint.startsWith('/') ? '' : '/';
    final url = Uri.parse('$_baseUrl$slash$endpoint');
    print('[API] DELETE => $url');
    print('[API] Using API key: ***${_apiKey.substring(_apiKey.length - 4)}');

    final response = await http.delete(
      url,
      headers: _getHeaders(),
    );

    print('[API] Response status: ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      print('[API] Error response: ${response.body}');
    }
    return response;
  }

  // Memo endpoints
  Future<List<Memo>> listMemos({
    String? parent,
    String? filter,
    String state = '',
    String sort = 'display_time', // Default sort field
    String direction = 'DESC', // Default direction (newest first)
  }) async {
    // Note: Even though we pass sort parameters to the server, it appears the
    // server doesn't respect them and always sorts by update time.
    // We apply client-side sorting to ensure the correct order.
    
    // Build query parameters
    final queryParams = <String, String>{};

    if (filter != null && filter.isNotEmpty) {
      queryParams['filter'] = filter;
    }

    if (state.isNotEmpty) {
      queryParams['state'] = state;
    }

    // Add sorting parameters
    queryParams['sort'] = sort;
    queryParams['direction'] = direction;

    // Determine the base URL based on whether a parent is provided
    // According to the API docs, the parent is a path parameter: /api/v1/{parent}/memos
    String baseUrlToUse = _baseUrl;

    // If _baseUrl ends with /memos, we need to adjust it
    if (_baseUrl.toLowerCase().endsWith('/memos')) {
      // Remove the trailing /memos
      baseUrlToUse = _baseUrl.substring(0, _baseUrl.length - 6);
    }

    // Now construct the final URL with the appropriate parent path
    String finalPath =
        parent != null && parent.isNotEmpty
            ? '$baseUrlToUse/$parent/memos' // With parent parameter
            : '$baseUrlToUse/users/-/memos'; // Default to all memos
    
    // Build the URL with query parameters
    final uri = Uri.parse(finalPath).replace(queryParameters: queryParams);
    print('[API] GET => $uri');
    print('[API] Using parent: ${parent ?? "users/-"} (default all memos)');
    print('[API] Sort parameters: sort=$sort, direction=$direction');

    final response = await http.get(
      uri,
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
        // Log a bit more info about the response to debug sorting
        print('[API] Received ${data['memos'].length} memos');
        if (data['memos'].isNotEmpty) {
          print(
            '[API] First memo: ${data['memos'][0]['content']?.toString().substring(0, min(20, data['memos'][0]['content'].toString().length))}...',
          );
          print(
            '[API] Sort fields - createTime: ${data['memos'][0]['createTime']}, updateTime: ${data['memos'][0]['updateTime']}',
          );
        }
        
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

    // Create proper request structure with 'memo' object
    final requestBody = {'memo': memoData};
    
    final response = await _post('', requestBody);
    
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

    // Send memo data directly without wrapping it in a "memo" object
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

    // Create proper request structure with 'comment' object
    final requestBody = {'comment': comment.toJson()};

    final response = await _post(endpoint, requestBody);
    
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
    print('[API] Parsing comments from data: ${json.encode(data)}');
    
    // Handle different comment data structures
    if (data is List) {
      if (data.isEmpty) {
        print('[API] Data is an empty list');
        return [];
      }
      
      // If we have an array of [id, object] pairs
      if (data[0] is List) {
        print('[API] Data is a list of [id, object] pairs');
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
        print('[API] Data is a list of objects with content property');
        return data.map<Comment>((x) => Comment.fromJson(x)).toList();
      }
    }
    
    // If data contains a "memos" array (another format we might receive)
    if (data is Map && data.containsKey('memos') && data['memos'] is List) {
      print('[API] Data contains a "memos" array');
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
      print('[API] Data contains a "comments" property with an array');
      return data['comments'].map<Comment>((x) => Comment.fromJson(x)).toList();
    }
    
    print('[API] Unknown comments format, raw data: $data');
    return [];
  }
}
