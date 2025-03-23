import 'dart:convert';

import 'package:flutter_memos/api/lib/api.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/utils/env.dart';
import 'package:flutter_memos/utils/memo_utils.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    // Initialize the API client and MemoService API
    final apiClient = ApiClient(
      basePath: Env.apiBaseUrl,
      authentication: HttpBearerAuth()..accessToken = Env.memosApiKey,
    );
    _memoApi = MemoServiceApi(apiClient);
  }

  late final MemoServiceApi _memoApi;
  
  // This static variable is used to track the original server order for testing
  static List<String>? _lastServerOrder;
  static List<String> get lastServerOrder => _lastServerOrder ?? [];

  // Memo endpoints
  Future<List<Memo>> listMemos({
    String? parent,
    String? filter,
    String state = '',
    String sort = 'updateTime', // Default sort field
    String direction = 'DESC', // Default direction (newest first)
  }) async {
    print('Fetching memos with sort field: $sort');
    
    print(
      '[API] GET => ${_memoApi.apiClient.basePath}/${parent != null ? "$parent/memos" : "memos"}',
    );
    print(
      '[API] Using endpoint pattern: ${parent != null ? "/{parent}/memos" : "/memos"}',
    );
    print('[API] Parent: ${parent ?? "not specified"}');
    print('[API] Sort parameters: sort=$sort, direction=$direction');

    // Call the appropriate API method based on whether parent is provided
    final V1ListMemosResponse response;
    try {
      if (parent != null && parent.isNotEmpty) {
        response =
            await _memoApi.memoServiceListMemos2(
              parent,
              state: state.isNotEmpty ? state : null,
              sort: sort,
              direction: direction,
              filter: filter,
            ) ??
            V1ListMemosResponse();
      } else {
        response =
            await _memoApi.memoServiceListMemos(
              parent: parent,
              state: state.isNotEmpty ? state : null,
              sort: sort,
              direction: direction,
              filter: filter,
            ) ??
            V1ListMemosResponse();
      }

      // Log response info for debugging
      print('[API] Response status: 200');
      final memos = response.memos ?? [];
      print('[API] Received ${memos.length} memos');
      
      if (memos.isNotEmpty) {
        print('[API] First memo: ${_truncateContent(memos.first.content)}...');
        print(
          '[API] Sort fields - createTime: ${memos.first.createTime}, updateTime: ${memos.first.updateTime}',
        );
      }
      
      // Convert API memos to app model memos
      final appMemos = memos.map(_convertApiMemoToAppMemo).toList();
      
      // Store the original server order for testing
      final serverOrder = appMemos.map((memo) => memo.id).toList();
      print(
        '[API] Original server order (first 3 IDs): ${serverOrder.take(3).join(", ")}',
      );
      
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
    print('[API] GET => ${_memoApi.apiClient.basePath}/$formattedId');
    print(
      '[API] Using API key: ***${Env.memosApiKey.substring(Env.memosApiKey.length - 4)}',
    );
    
    try {
      final apiMemo = await _memoApi.memoServiceGetMemo(formattedId);
      print('[API] Response status: 200');
      
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
    print('[API] POST => ${_memoApi.apiClient.basePath}');
    print(
      '[API] Using API key: ***${Env.memosApiKey.substring(Env.memosApiKey.length - 4)}',
    );
    
    // Convert app memo to API memo
    final apiMemo = _convertAppMemoToApiMemo(memo);
    
    // Log the request body for debugging
    print('[API] Request body: ${jsonEncode({"memo": _memoToJson(apiMemo)})}');
    
    try {
      final response = await _memoApi.memoServiceCreateMemo(apiMemo);
      print('[API] Response status: 200');
      
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
    print('[API] PATCH => ${_memoApi.apiClient.basePath}/$formattedId');
    print(
      '[API] Using API key: ***${Env.memosApiKey.substring(Env.memosApiKey.length - 4)}',
    );

    // Convert app memo to API memo for update
    final apiMemo = _convertAppMemoToUpdateMemo(memo);

    // Log the request body for debugging
    print('[API] Request body: ${jsonEncode(memo.toJson())}');
    
    try {
      final response = await _memoApi.memoServiceUpdateMemo(
        formattedId,
        apiMemo,
      );
      print('[API] Response status: 200');
      
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
    print('[API] DELETE => ${_memoApi.apiClient.basePath}/$formattedId');
    print(
      '[API] Using API key: ***${Env.memosApiKey.substring(Env.memosApiKey.length - 4)}',
    );
    
    try {
      await _memoApi.memoServiceDeleteMemo(formattedId);
      print('[API] Response status: 204');
    } catch (e) {
      print('[API] Error: $e');
      throw Exception('Failed to delete memo: $e');
    }
  }

  // Comments endpoints
  Future<List<Comment>> listMemoComments(String memoId) async {
    final formattedId = _formatMemoId(memoId);
    print('[API] GET => ${_memoApi.apiClient.basePath}/$formattedId/comments');
    print(
      '[API] Using API key: ***${Env.memosApiKey.substring(Env.memosApiKey.length - 4)}',
    );

    try {
      final response = await _memoApi.memoServiceListMemoComments(formattedId);
      print('[API] Response status: 200');

      final rawResponse = response?.toJson() ?? {};
      print('[API] Parsing comments from data: ${jsonEncode(rawResponse)}');
      
      if (response?.memos != null) {
        print('[API] Data contains a "memos" array');
        final comments = _parseCommentsFromApiResponse(response!);
        print('[MemoDetail] Fetched ${comments.length} comments');
        
        // Log the first few comments for debugging
        if (comments.isNotEmpty) {
          for (int i = 0; i < comments.length && i < 3; i++) {
            print('[MemoDetail] Comment ${i + 1}: ${comments[i].content}');
          }
        }
        
        return comments;
      } else {
        print('[API] Unknown comments format');
        return [];
      }
    } catch (e) {
      print('[API] Error: $e');
      throw Exception('Failed to load comments: $e');
    }
  }

  Future<Comment> createMemoComment(String memoId, Comment comment) async {
    final formattedId = _formatMemoId(memoId);
    print('[API] POST => ${_memoApi.apiClient.basePath}/$formattedId/comments');
    print(
      '[API] Using API key: ***${Env.memosApiKey.substring(Env.memosApiKey.length - 4)}',
    );

    // Convert app comment to API memo for comment
    final apiMemo = _convertAppCommentToApiMemo(comment);
    
    // Log the request body for debugging
    print('[API] Request body: ${jsonEncode({"comment": comment.toJson()})}');
    
    try {
      final response = await _memoApi.memoServiceCreateMemoComment(
        formattedId,
        apiMemo,
      );
      print('[API] Response status: 200');
      
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
      int? timestamp =
          memo.createTime != null
              ? DateTime.parse(
                memo.createTime!.toIso8601String(),
              ).millisecondsSinceEpoch
              : null;
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
  
  // Helper to convert Apiv1Memo to a JSON Map for debug printing
  Map<String, dynamic> _memoToJson(Apiv1Memo memo) {
    return {
      if (memo.content != null) 'content': memo.content,
      if (memo.pinned != null) 'pinned': memo.pinned,
      if (memo.state != null) 'state': memo.state?.value,
      if (memo.visibility != null) 'visibility': memo.visibility?.value,
      if (memo.creator != null) 'creator': memo.creator,
    };
  }
}
