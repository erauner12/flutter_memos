import 'dart:math' show min;

import 'package:flutter_memos/api/lib/api.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/utils/env.dart';
import 'package:flutter_memos/utils/memo_utils.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late final MemoServiceApi _memoApi;

  // This static variable is used to track the original server order for testing
  static List<String>? _lastServerOrder;
  static List<String> get lastServerOrder => _lastServerOrder ?? [];

  ApiService._internal() {
    // The key is to set up the basePath correctly
    // The generated API client already includes "/api/v1/" in its paths
    String basePath = Env.apiBaseUrl;
    
    // Remove trailing slash if present
    if (basePath.endsWith('/')) {
      basePath = basePath.substring(0, basePath.length - 1);
    }
    
    // Remove "/api/v1/memos" or "/api/v1" suffix if present
    // as the generated client already includes these path segments
    if (basePath.toLowerCase().endsWith('/api/v1/memos')) {
      basePath = basePath.substring(0, basePath.length - 13);
      print(
        '[API] Removing "/api/v1/memos" from base path to avoid duplication',
      );
    } else if (basePath.toLowerCase().endsWith('/api/v1')) {
      basePath = basePath.substring(0, basePath.length - 7);
      print('[API] Removing "/api/v1" from base path to avoid duplication');
    } else if (basePath.toLowerCase().endsWith('/memos')) {
      basePath = basePath.substring(0, basePath.length - 6);
      print(
        '[API] Removing "/memos" from base path for proper URL construction',
      );
    }
    
    print('[API] Initializing with base path: $basePath');
    
    // Initialize the API client
    final apiClient = ApiClient(
      basePath: basePath,
      authentication: HttpBearerAuth()..accessToken = Env.memosApiKey,
    );
    
    _memoApi = MemoServiceApi(apiClient);
  }

  // Memo endpoints
  Future<List<Memo>> listMemos({
    String? parent,
    String? filter,
    String state = '',
    String sort = 'updateTime', // Default sort field
    String direction = 'DESC', // Default direction (newest first)
  }) async {
    print('Fetching memos with sort field: $sort');
    
    try {
      // Call the appropriate method based on whether parent is provided
      final V1ListMemosResponse? response;
      
      if (parent != null && parent.isNotEmpty) {
        // Make sure parent is correctly formatted (no leading "users/" if it's already included)
        String formattedParent = parent;
        print(
          '[API] Using memoServiceListMemos2 with parent: $formattedParent',
        );
        
        response = await _memoApi.memoServiceListMemos2(
          formattedParent,
          state: state.isNotEmpty ? state : null,
          sort: sort,
          direction: direction,
          filter: filter,
        );
      } else {
        print('[API] Using memoServiceListMemos without parent');
        response = await _memoApi.memoServiceListMemos(
          state: state.isNotEmpty ? state : null,
          sort: sort,
          direction: direction,
          filter: filter,
        );
      }
      
      // Process the response
      final apiMemos = response?.memos ?? [];
      print('[API] Response status: 200');
      print('[API] Received ${apiMemos.length} memos');
      
      if (apiMemos.isNotEmpty) {
        print(
          '[API] First memo: ${_truncateContent(apiMemos.first.content)}...',
        );
        print(
          '[API] Sort fields - createTime: ${apiMemos.first.createTime}, updateTime: ${apiMemos.first.updateTime}',
        );
      }
      
      // Convert API memos to app model memos
      final appMemos = apiMemos.map(_convertApiMemoToAppMemo).toList();

      // Store the original server order for testing
      final serverOrder = appMemos.map((memo) => memo.id).toList();
      if (serverOrder.isNotEmpty) {
        print(
          '[API] Original server order (first ${min(3, serverOrder.length)} IDs): ${serverOrder.take(min(3, serverOrder.length)).join(", ")}',
        );
      }
      
      // Apply client-side sorting
      print('[API] Applying client-side sorting by $sort');
      MemoUtils.sortMemos(appMemos, sort);

      // Store the original order in a static variable for testing
      _lastServerOrder = serverOrder;
      
      return appMemos;
    } catch (e) {
      print('[API] Error: $e');
      throw Exception('Failed to load memos: $e');
    }
  }

  Future<Memo> getMemo(String id) async {
    final formattedId = _formatMemoId(id);
    print('[API] Getting memo: $formattedId');
    
    try {
      final apiMemo = await _memoApi.memoServiceGetMemo(formattedId);
      
      if (apiMemo == null) {
        throw Exception('Memo not found');
      }
      
      return _convertApiMemoToAppMemo(apiMemo);
    } catch (e) {
      print('[API] Error: $e');
      throw Exception('Failed to load memo: $e');
    }
  }

  Future<Memo> createMemo(Memo memo) async {
    print('[API] Creating new memo');
    
    // Convert app memo to API memo
    final apiMemo = _convertAppMemoToApiMemo(memo);
    
    try {
      final response = await _memoApi.memoServiceCreateMemo(apiMemo);
      
      if (response == null) {
        throw Exception('Failed to create memo: No response');
      }
      
      return _convertApiMemoToAppMemo(response);
    } catch (e) {
      print('[API] Error: $e');
      throw Exception('Failed to create memo: $e');
    }
  }

  Future<Memo> updateMemo(String id, Memo memo) async {
    final formattedId = _formatMemoId(id);
    print('[API] Updating memo: $formattedId');
    
    // Convert app memo to API memo for update
    final apiMemo = _convertAppMemoToUpdateMemo(memo);
    
    try {
      final response = await _memoApi.memoServiceUpdateMemo(
        formattedId,
        apiMemo,
      );
      
      if (response == null) {
        throw Exception('Failed to update memo: No response');
      }
      
      return _convertApiMemoToAppMemo(response);
    } catch (e) {
      print('[API] Error: $e');
      throw Exception('Failed to update memo: $e');
    }
  }

  Future<void> deleteMemo(String id) async {
    final formattedId = _formatMemoId(id);
    print('[API] Deleting memo: $formattedId');
    
    try {
      await _memoApi.memoServiceDeleteMemo(formattedId);
    } catch (e) {
      print('[API] Error: $e');
      throw Exception('Failed to delete memo: $e');
    }
  }

  // Comments endpoints
  Future<List<Comment>> listMemoComments(String memoId) async {
    final formattedId = _formatMemoId(memoId);
    print('[API] Listing comments for memo: $formattedId');
    
    try {
      final response = await _memoApi.memoServiceListMemoComments(formattedId);
      
      if (response == null) {
        return [];
      }
      
      final comments = _parseCommentsFromApiResponse(response);
      print('[API] Received ${comments.length} comments');
      
      return comments;
    } catch (e) {
      print('[API] Error: $e');
      throw Exception('Failed to load comments: $e');
    }
  }

  Future<Comment> createMemoComment(String memoId, Comment comment) async {
    final formattedId = _formatMemoId(memoId);
    print('[API] Creating comment for memo: $formattedId');
    
    // Convert app comment to API memo for comment
    final apiMemo = _convertAppCommentToApiMemo(comment);
    
    try {
      final response = await _memoApi.memoServiceCreateMemoComment(
        formattedId,
        apiMemo,
      );
      
      if (response == null) {
        throw Exception('Failed to create comment: No response');
      }
      
      // Convert API response to app Comment
      return Comment(
        id: _extractIdFromName(response.name ?? ''),
        content: response.content ?? '',
        createTime:
            response.createTime != null
                ? response.createTime!.millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
        creatorId: _extractCreatorIdFromName(response.creator ?? ''),
      );
    } catch (e) {
      print('[API] Error: $e');
      throw Exception('Failed to create comment: $e');
    }
  }

  // Helper functions
  String _formatMemoId(String id) {
    return id.startsWith('memos/') ? id : 'memos/$id';
  }
  
  String _extractIdFromName(String name) {
    if (name.isEmpty) return '';
    final parts = name.split('/');
    return parts.length > 1 ? parts[1] : name;
  }
  
  String _extractCreatorIdFromName(String creator) {
    if (creator.isEmpty) return '';
    final match = RegExp(r'users\/(\d+)').firstMatch(creator);
    return match != null ? match.group(1) ?? '' : creator;
  }
  
  String _truncateContent(String? content) {
    if (content == null || content.isEmpty) return '';
    return content.length > 20 ? content.substring(0, 20) : content;
  }
  
  // Conversion functions between app models and API models
  Memo _convertApiMemoToAppMemo(Apiv1Memo apiMemo) {
    String id = '';
    if (apiMemo.name != null) {
      final parts = apiMemo.name!.toString().split('/');
      id = parts.length > 1 ? parts[1] : apiMemo.name!;
    }

    return Memo(
      id: id,
      content: apiMemo.content ?? '',
      pinned: apiMemo.pinned ?? false,
      state: _parseApiState(apiMemo.state),
      visibility: apiMemo.visibility?.value ?? 'PUBLIC',
      resourceNames: apiMemo.resources.map((r) => r.name ?? '').toList(),
      relationList: apiMemo.relations,
      parent: apiMemo.parent,
      creator: apiMemo.creator,
      createTime: apiMemo.createTime?.toIso8601String(),
      updateTime: apiMemo.updateTime?.toIso8601String(),
      displayTime: apiMemo.displayTime?.toIso8601String(),
    );
  }
  
  MemoState _parseApiState(V1State? state) {
    if (state == null) return MemoState.normal;
    
    switch (state) {
      case V1State.ARCHIVED:
        return MemoState.archived;
      case V1State.NORMAL:
      default:
        return MemoState.normal;
    }
  }
  
  Apiv1Memo _convertAppMemoToApiMemo(Memo memo) {
    return Apiv1Memo(
      content: memo.content,
      pinned: memo.pinned,
      state: _getApiState(memo.state),
      visibility: _getApiVisibility(memo.visibility),
      creator: memo.creator ?? 'users/1',
    );
  }
  
  TheMemoToUpdateTheNameFieldIsRequired _convertAppMemoToUpdateMemo(Memo memo) {
    return TheMemoToUpdateTheNameFieldIsRequired(
      content: memo.content,
      pinned: memo.pinned,
      state: _getApiState(memo.state),
      visibility: _getApiVisibility(memo.visibility),
    );
  }
  
  Apiv1Memo _convertAppCommentToApiMemo(Comment comment) {
    return Apiv1Memo(
      content: comment.content,
      creator:
          comment.creatorId != null ? 'users/${comment.creatorId}' : 'users/1',
    );
  }
  
  V1State _getApiState(MemoState state) {
    switch (state) {
      case MemoState.archived:
        return V1State.ARCHIVED;
      case MemoState.normal:
      default:
        return V1State.NORMAL;
    }
  }
  
  V1Visibility _getApiVisibility(String visibility) {
    switch (visibility.toUpperCase()) {
      case 'PRIVATE':
        return V1Visibility.PRIVATE;
      case 'PROTECTED':
        return V1Visibility.PROTECTED;
      case 'PUBLIC':
      default:
        return V1Visibility.PUBLIC;
    }
  }
  
  List<Comment> _parseCommentsFromApiResponse(
    V1ListMemoCommentsResponse response,
  ) {
    final comments = <Comment>[];
    
    for (final memo in response.memos) {
      // Extract comment details from memo
      String id = _extractIdFromName(memo.name ?? '');
      String content = memo.content ?? '';
      int? timestamp = memo.createTime?.millisecondsSinceEpoch;
      String? creator =
          memo.creator != null
              ? _extractCreatorIdFromName(memo.creator!)
              : null;
      
      comments.add(
        Comment(
          id: id,
          content: content,
          createTime: timestamp,
          creatorId: creator,
        ),
      );
    }
      
    return comments;
  }
}
