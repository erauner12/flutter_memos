import 'package:flutter_memos/api/lib/api.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/utils/env.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_memos/utils/memo_utils.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late MemoServiceApi _memoApi;
  late ApiClient _apiClient;
  
  // New fields for server configuration
  String _baseUrl = '';
  String _authToken = '';

  // Configuration flags
  static const bool CLIENT_SIDE_SORTING_ENABLED = true; // Always use client-side sorting
  static bool verboseLogging = true;  // Enable detailed logging
  static bool useFilterExpressions = true; // Enable CEL filter expressions

  // For testing purposes
  static List<String>? _lastServerOrder;
  static List<String> get lastServerOrder => _lastServerOrder ?? [];
  
  // Document the sorting limitation and filter support
  static const String SORTING_LIMITATION = """
    NOTE: The Memos server doesn't fully support dynamic sort fields.
    The backend code uses specific boolean flags (OrderByUpdatedTs, OrderByTimeAsc)
    rather than a generic sort parameter. Client-side sorting is used as a reliable
    alternative.
    
    However, the server does support powerful filtering using CEL expressions.
    This can be used to filter memos by tags, visibility, content, and timestamps.
  """;

  ApiService._internal() {
    // Default initialization will be replaced by configureService
    _initializeClient('', '');
  }

  /// Configure the service with custom server URL and auth token
  void configureService({required String baseUrl, required String authToken}) {
    if (_baseUrl == baseUrl && _authToken == authToken) {
      // No change in configuration, skip re-initialization
      if (verboseLogging) {
        print('[API] Configuration unchanged, skipping re-initialization');
      }
      return;
    }

    if (verboseLogging) {
      print(
        '[API] Updating configuration to: $baseUrl with ${authToken.isNotEmpty ? "token" : "no token"}',
      );
    }

    _baseUrl = baseUrl;
    _authToken = authToken;

    try {
      // Re-initialize the client with new configuration
      _initializeClient(baseUrl, authToken);
    } catch (e) {
      print('[API] Error during re-initialization: $e');
      // Re-throw to ensure caller is aware of the error
      rethrow;
    }
  }

  /// Initialize the API client with the given base URL and auth token
  void _initializeClient(String baseUrl, String authToken) {
    try {
      if (baseUrl.isEmpty) {
        // Fallback to environment default
        baseUrl = Env.apiBaseUrl;
      }

      // Clean up the base URL
      if (baseUrl.toLowerCase().contains('/api/v1')) {
        final apiIndex = baseUrl.toLowerCase().indexOf('/api/v1');
        baseUrl = baseUrl.substring(0, apiIndex);
        if (verboseLogging) {
          print('[API] Extracted base URL: $baseUrl');
        }
      } else if (baseUrl.toLowerCase().endsWith('/memos')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 6);
        if (verboseLogging) {
          print('[API] Removed "/memos" suffix from base URL');
        }
      }

      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      if (verboseLogging) {
        print('[API] Using base path: $baseUrl');
      }

      // Use provided auth token or fallback to environment
      final token = authToken.isNotEmpty ? authToken : Env.memosApiKey;

      // Initialize the API client and authentication
      _apiClient = ApiClient(
        basePath: baseUrl,
        authentication: HttpBearerAuth()..accessToken = token,
      );

      _memoApi = MemoServiceApi(_apiClient);
      
      if (verboseLogging) {
        print('[API] Successfully initialized client with base URL: $baseUrl');
      }
    } catch (e) {
      print('[API] Error initializing client: $e');
      throw Exception('Failed to initialize API client: $e');
    }
  }

  // MEMO OPERATIONS

  /// List memos with filtering and sorting
  Future<List<Memo>> listMemos({
    String? parent,
    String? filter,
    String state = '',
    String sort = 'updateTime',
    String direction = 'DESC',
    List<String>? tags,
    dynamic visibility,
    String? contentSearch,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? updatedAfter,
    DateTime? updatedBefore,
    String? timeExpression,
    bool useUpdateTimeForExpression = false,
  }) async {
    if (verboseLogging) {
      print('[API] Listing memos with sort=$sort, direction=$direction');
    }
    
    // If filter expressions are enabled, build a CEL filter
    String? celFilter = filter;
    if (useFilterExpressions) {
      final filterList = <String>[];
      
      // Add tags filter
      if (tags != null && tags.isNotEmpty) {
        filterList.add(FilterBuilder.byTags(tags));
      }
      
      // Add visibility filter
      if (visibility != null) {
        filterList.add(FilterBuilder.byVisibility(visibility));
      }
      
      // Add content search
      if (contentSearch != null && contentSearch.isNotEmpty) {
        filterList.add(FilterBuilder.byContent(contentSearch));
      }
      
      // Add time filters
      if (createdAfter != null && createdBefore != null) {
        filterList.add(
          FilterBuilder.byCreateTimeRange(createdAfter, createdBefore),
        );
      } else {
        if (createdAfter != null) {
          filterList.add(
            FilterBuilder.byCreateTime(createdAfter, operator: '>='),
          );
        }
        if (createdBefore != null) {
          filterList.add(
            FilterBuilder.byCreateTime(createdBefore, operator: '<='),
          );
        }
      }
      
      if (updatedAfter != null && updatedBefore != null) {
        filterList.add(
          FilterBuilder.byUpdateTimeRange(updatedAfter, updatedBefore),
        );
      } else {
        if (updatedAfter != null) {
          filterList.add(
            FilterBuilder.byUpdateTime(updatedAfter, operator: '>='),
          );
        }
        if (updatedBefore != null) {
          filterList.add(
            FilterBuilder.byUpdateTime(updatedBefore, operator: '<='),
          );
        }
      }
      
      // Add time expression
      if (timeExpression != null && timeExpression.isNotEmpty) {
        final expressionFilter = FilterBuilder.byTimeExpression(
          timeExpression,
          useUpdateTime: useUpdateTimeForExpression,
        );
        if (expressionFilter.isNotEmpty) {
          filterList.add(expressionFilter);
        }
      }
      
      // Combine filters with AND
      if (filterList.isNotEmpty) {
        final combinedFilter = FilterBuilder.and(filterList);
        
        // If the user provided a filter, combine it with our generated filter
        if (filter != null && filter.isNotEmpty) {
          celFilter = FilterBuilder.and([filter, combinedFilter]);
        } else {
          celFilter = combinedFilter;
        }
        
        if (verboseLogging) {
          print('[API] Using CEL filter: $celFilter');
        }
      }
    }
    
    try {
      final V1ListMemosResponse? response;
      
      // Use the appropriate endpoint based on whether parent is specified
      if (parent != null && parent.isNotEmpty) {
        response = await _memoApi.memoServiceListMemos2(
          parent,
          state: state.isNotEmpty ? state : null,
          sort: sort,
          direction: direction,
          filter: celFilter,
        );
      } else {
        response = await _memoApi.memoServiceListMemos(
          parent: parent,
          state: state.isNotEmpty ? state : null,
          sort: sort, 
          direction: direction,
          filter: celFilter,
        );
      }
      
      if (response == null) {
        return [];
      }

      final memos = response.memos.map(_convertApiMemoToAppMemo).toList();
      
      _lastServerOrder = memos.map((memo) => memo.id).toList();
      
      if (verboseLogging) {
        print('[API-DEBUG] Server returned ${memos.length} memos');
        if (memos.isNotEmpty) {
          print(
            '[API-DEBUG] First memo: ${memos[0].id}, updateTime: ${memos[0].updateTime}, createTime: ${memos[0].createTime}',
          );
        }
      }

      if (CLIENT_SIDE_SORTING_ENABLED) {
        final preSortOrder = memos.map((memo) => memo.id).toList();
        MemoUtils.sortMemos(memos, sort);
        final postSortOrder = memos.map((memo) => memo.id).toList();
        final orderingChanged = !_areListsEqual(preSortOrder, postSortOrder);

        if (verboseLogging) {
          print(
            '[API-DEBUG] Client-side sorting by "$sort" ${orderingChanged ? "changed" : "preserved"} the order',
          );
          if (orderingChanged && memos.isNotEmpty) {
            print(
              '[API-DEBUG] First memo after sorting: ${memos[0].id}, $sort: ${sort == 'updateTime' ? memos[0].updateTime : memos[0].createTime}',
            );
          }
        }
      }
      
      return memos;
    } catch (e) {
      print('[API] Error listing memos: $e');
      throw Exception('Failed to load memos: $e');
    }
  }

  /// Get a single memo by ID
  Future<Memo> getMemo(String id) async {
    try {
      final apiMemo = await _memoApi.memoServiceGetMemo(
        _formatResourceName(id, 'memos'),
      );
      
      if (apiMemo == null) {
        throw Exception('Memo not found');
      }
      
      return _convertApiMemoToAppMemo(apiMemo);
    } catch (e) {
      print('[API] Error getting memo: $e');
      throw Exception('Failed to load memo: $e');
    }
  }

  /// Create a new memo
  Future<Memo> createMemo(Memo memo) async {
    try {
      final apiMemo = Apiv1Memo(
        content: memo.content,
        pinned: memo.pinned,
        state: _getApiState(memo.state),
        visibility: _getApiVisibility(memo.visibility),
        creator: memo.creator ?? 'users/1',
      );
      
      final response = await _memoApi.memoServiceCreateMemo(apiMemo);
      
      if (response == null) {
        throw Exception('Failed to create memo: No response from server');
      }
      
      return _convertApiMemoToAppMemo(response);
    } catch (e) {
      print('[API] Error creating memo: $e');
      throw Exception('Failed to create memo: $e');
    }
  }

  /// Update an existing memo
  Future<Memo> updateMemo(String id, Memo memo) async {
    try {
      final updateMemo = TheMemoToUpdateTheNameFieldIsRequired(
        content: memo.content,
        pinned: memo.pinned,
        state: _getApiState(memo.state),
        visibility: _getApiVisibility(memo.visibility),
      );
      
      final response = await _memoApi.memoServiceUpdateMemo(
        _formatResourceName(id, 'memos'),
        updateMemo,
      );
      
      if (response == null) {
        throw Exception('Failed to update memo: No response from server');
      }
      
      return _convertApiMemoToAppMemo(response);
    } catch (e) {
      print('[API] Error updating memo: $e');
      throw Exception('Failed to update memo: $e');
    }
  }

  /// Delete a memo
  Future<void> deleteMemo(String id) async {
    try {
      final formattedId = _formatResourceName(id, 'memos');
      print('[API] Deleting memo: $formattedId');
      
      final response = await _memoApi.memoServiceDeleteMemoWithHttpInfo(formattedId);
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        print('[API] Successfully deleted memo: $id');
        return;
      } else if (response.statusCode >= 400) {
        print('[API] Error deleting memo: HTTP ${response.statusCode}');
        throw Exception('Failed to delete memo: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('[API] Error deleting memo: $e');
      throw Exception('Failed to delete memo: $e');
    }
  }

  // COMMENT OPERATIONS

  /// List comments for a memo
  Future<List<Comment>> listMemoComments(String memoId) async {
    try {
      final response = await _memoApi.memoServiceListMemoComments(
        _formatResourceName(memoId, 'memos'),
      );
      
      if (response == null) {
        return [];
      }
      
      return _parseCommentsFromApiResponse(response);
    } catch (e) {
      print('[API] Error listing comments: $e');
      throw Exception('Failed to load comments: $e');
    }
  }

  /// Create a comment on a memo
  Future<Comment> createMemoComment(String memoId, Comment comment) async {
    try {
      final apiMemo = Apiv1Memo(
        content: comment.content,
        creator:
            comment.creatorId != null
                ? 'users/${comment.creatorId}'
                : 'users/1',
      );
      
      final response = await _memoApi.memoServiceCreateMemoComment(
        _formatResourceName(memoId, 'memos'),
        apiMemo,
      );
      
      if (response == null) {
        throw Exception('Failed to create comment: No response from server');
      }
      
      return Comment(
        id: _extractIdFromName(response.name ?? ''),
        content: response.content ?? '',
        createTime:
            response.createTime?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
        creatorId: _extractIdFromName(response.creator ?? ''),
      );
    } catch (e) {
      print('[API] Error creating comment: $e');
      throw Exception('Failed to create comment: $e');
    }
  }

  /// HELPER METHODS

  String _toSnakeCase(String camelCase) {
    return camelCase.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  String _formatResourceName(String id, String resourceType) {
    return id.startsWith('$resourceType/') ? id : '$resourceType/$id';
  }
  
  String _extractIdFromName(String name) {
    if (name.isEmpty) return '';
    final parts = name.split('/');
    return parts.length > 1 ? parts[1] : name;
  }
  
  Memo _convertApiMemoToAppMemo(Apiv1Memo apiMemo) {
    return Memo(
      id: _extractIdFromName(apiMemo.name ?? ''),
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
    return response.memos
        .map(
          (memo) => Comment(
            id: _extractIdFromName(memo.name ?? ''),
            content: memo.content ?? '',
            createTime:
                memo.createTime?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            creatorId:
                memo.creator != null ? _extractIdFromName(memo.creator!) : null,
          ),
        )
        .toList();
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}
