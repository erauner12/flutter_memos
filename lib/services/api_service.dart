import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/utils/env.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = Env.apiBaseUrl;
  final String _apiKey = Env.memosApiKey;

  Future<http.Response> _get(String endpoint) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    print('[API] GET => $url');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
    );

    print('[API] Response status: ${response.statusCode}');
    return response;
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    print('[API] POST => $url');
    print('[API] Request body: ${jsonEncode(data)}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(data),
    );

    print('[API] Response status: ${response.statusCode}');
    return response;
  }

  Future<http.Response> _patch(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    print('[API] PATCH => $url');
    print('[API] Request body: ${jsonEncode(data)}');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(data),
    );

    print('[API] Response status: ${response.statusCode}');
    return response;
  }

  Future<http.Response> _delete(String endpoint) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    print('[API] DELETE => $url');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
    );

    print('[API] Response status: ${response.statusCode}');
    return response;
  }

  // Memo endpoints
  Future<List<Memo>> listMemos({String? filter, String state = ''}) async {
    String endpoint = 'memos';
    
    // Add query parameters
    List<String> queryParams = [];
    if (filter != null && filter.isNotEmpty) {
      queryParams.add('filter=$filter');
    }
    if (state.isNotEmpty) {
      queryParams.add('state=$state');
    }
    
    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await _get(endpoint);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('memos')) {
        return List<Memo>.from(data['memos'].map((x) => Memo.fromJson(x)));
      }
    }
    
    throw Exception('Failed to load memos: ${response.statusCode}');
  }

  Future<Memo> getMemo(String id) async {
    final formattedId = _formatMemoId(id);
    final response = await _get(formattedId);
    
    if (response.statusCode == 200) {
      return Memo.fromJson(json.decode(response.body));
    }
    
    throw Exception('Failed to load memo: ${response.statusCode}');
  }

  Future<Memo> createMemo(Memo memo) async {
    final response = await _post('memos', memo.toJson());
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Memo.fromJson(json.decode(response.body));
    }
    
    throw Exception('Failed to create memo: ${response.statusCode}');
  }

  Future<Memo> updateMemo(String id, Memo memo) async {
    final formattedId = _formatMemoId(id);
    final response = await _patch(formattedId, memo.toJson());
    
    if (response.statusCode == 200) {
      return Memo.fromJson(json.decode(response.body));
    }
    
    throw Exception('Failed to update memo: ${response.statusCode}');
  }

  Future<void> deleteMemo(String id) async {
    final formattedId = _formatMemoId(id);
    final response = await _delete(formattedId);
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete memo: ${response.statusCode}');
    }
  }

  // Comments endpoints
  Future<List<Comment>> listMemoComments(String memoId) async {
    final formattedId = _formatMemoId(memoId);
    final response = await _get('$formattedId/comments');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseComments(data);
    }
    
    throw Exception('Failed to load comments: ${response.statusCode}');
  }

  Future<Comment> createMemoComment(String memoId, Comment comment) async {
    final formattedId = _formatMemoId(memoId);
    final response = await _post('$formattedId/comments', comment.toJson());
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Comment.fromJson(json.decode(response.body));
    }
    
    throw Exception('Failed to create comment: ${response.statusCode}');
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
          'creatorId': memo['creator'] != null
              ? memo['creator'].toString().replaceAll('users/', '')
              : null,
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