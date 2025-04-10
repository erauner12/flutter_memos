import 'dart:convert'; // For base64Encode
import 'dart:typed_data'; // For Uint8List

import 'package:flutter_memos/api/lib/api.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/memo_relation.dart';
import 'package:flutter_memos/models/server_config.dart'; // Add this import
import 'package:flutter_memos/utils/env.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_memos/utils/memo_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add riverpod import
import 'package:http/http.dart' as http; // Import http for Response

// Placeholder provider for ApiService - replace with your actual provider definition
final apiServiceProvider = Provider<ApiService>((ref) {
  // This assumes ApiService is a singleton or managed elsewhere.
  // If ApiService depends on other providers (like server config),
  // adjust this provider definition accordingly.
  return ApiService(); // Return the singleton instance
});

// Define a response class to hold memos and the next page token
class PaginatedMemoResponse {
  final List<Memo> memos;
  final String? nextPageToken;

  PaginatedMemoResponse({required this.memos, this.nextPageToken});

  // Add methods to make this class work with existing code
  int get length => memos.length;

  List<Memo> where(bool Function(Memo) test) {
    return memos.where(test).toList();
  }

  // Utility method to check if there are more pages
  bool get hasMorePages => nextPageToken != null && nextPageToken!.isNotEmpty;

  // Utility method to check if empty
  bool get isEmpty => memos.isEmpty;

  // Optional: Factory constructor from JSON if needed
  // factory PaginatedMemoResponse.fromJson(Map<String, dynamic> json) { ... }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late MemoServiceApi _memoApi;
  late ResourceServiceApi _resourceApi; // Add ResourceServiceApi instance
  late ApiClient _apiClient;

  // New fields for server configuration
  String _baseUrl = '';
  String _authToken = '';

  // Getter for the base URL
  String get apiBaseUrl => _baseUrl;

  // Configuration flags (moved inside the class as static members)
  static const bool clientSideSortingEnabled =
      true; // Always use client-side sorting
  static bool verboseLogging = true; // Enable detailed logging
  static bool useFilterExpressions = true; // Enable CEL filter expressions

  // For testing purposes (moved inside the class as static members)
  static List<String>? _lastServerOrder;
  static List<String> get lastServerOrder => _lastServerOrder ?? [];

  // Document the sorting limitation and filter support (moved inside the class as static members)
  static const String sortingLimitation = """
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
      _resourceApi = ResourceServiceApi(_apiClient); // Initialize Resource API

      if (verboseLogging) {
        print('[API] Successfully initialized client with base URL: $baseUrl');
      }
    } catch (e) {
      print('[API] Error initializing client: $e');
      throw Exception('Failed to initialize API client: $e');
    }
  }

  // MEMO OPERATIONS

  /// List memos with filtering, sorting, and pagination
  Future<PaginatedMemoResponse> listMemos({
    String parent = 'users/1', // Default parent
    String? filter,
    String? state,
    String sort = 'updateTime',
    String direction = 'DESC',
    int? pageSize, // New parameter for pagination size
    String? pageToken, // New parameter for pagination token
    // Keep existing filter parameters
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
      print(
        '[API] Listing memos with sort=$sort, direction=$direction, pageSize=$pageSize, pageToken=$pageToken',
      );
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
      // Pass pageSize and pageToken to the API call
      if (parent.isNotEmpty) {
        if (verboseLogging) {
          print(
            '[API] Calling API with pageSize: $pageSize, pageToken: $pageToken',
          );
        }
        response = await _memoApi.memoServiceListMemos2(
          parent,
          state: state?.isNotEmpty ?? false ? state : null,
          sort: sort,
          direction: direction,
          filter: celFilter,
          pageSize: pageSize,
          pageToken: pageToken,
        );
      } else {
        if (verboseLogging) {
          print(
            '[API] Calling API with pageSize: $pageSize, pageToken: $pageToken',
          );
        }
        response = await _memoApi.memoServiceListMemos2(
          parent,
          state: state?.isNotEmpty ?? false ? state : null,
          sort: sort,
          direction: direction,
          filter: celFilter,
          pageSize: pageSize,
          pageToken: pageToken,
        );
      }

      // Handle potential null response from the API
      if (response == null) {
        if (verboseLogging) {
          print('[API-DEBUG] Server returned null response for listMemos.');
        }
        return PaginatedMemoResponse(memos: [], nextPageToken: null);
      }

      // Safely access memos and nextPageToken now that response is not null
      final memos = response.memos.map(_convertApiMemoToAppMemo).toList();
      final nextPageToken = response.nextPageToken; // Extract next page token

      _lastServerOrder = memos.map((memo) => memo.id).toList();

      if (verboseLogging) {
        print(
          '[API-DEBUG] Server returned ${memos.length} memos. Next page token: ${nextPageToken ?? "null"}',
        );
        if (pageToken != null) {
          print(
            '[API-DEBUG] This was a paginated request with token: $pageToken',
          );
        }
        if (memos.isNotEmpty) {
          print(
            '[API-DEBUG] First memo: ${memos[0].id}, updateTime: ${memos[0].updateTime}, createTime: ${memos[0].createTime}',
          );
          if (memos.length > 1) {
            print(
              '[API-DEBUG] Last memo: ${memos.last.id}, updateTime: ${memos.last.updateTime}, createTime: ${memos.last.createTime}',
            );
          }
        }
        if (nextPageToken != null) {
          print('[API-DEBUG] Next page token will be: $nextPageToken');
        } else {
          print('[API-DEBUG] No next page token. This is the last page.');
        }
      }

      // Client-side sorting remains important, especially if API sorting is limited
      if (clientSideSortingEnabled) {
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
              '[API-DEBUG] First memo after sorting: ${memos[0].id}, $sort: ${sort == "updateTime" ? memos[0].updateTime : memos[0].createTime}',
            );
          }
        }
      }

      // Add logging *after* client-side sorting
      if (verboseLogging && memos.isNotEmpty) {
        print(
          '[API-DEBUG] First memo AFTER client-side sort by "$sort": ID=${memos.first.id}, updateTime=${memos.first.updateTime}, createTime=${memos.first.createTime}',
        );
      }

      // Return the paginated response object
      return PaginatedMemoResponse(memos: memos, nextPageToken: nextPageToken);
    } catch (e) {
      print('[API] Error listing memos: $e');
      // Consider wrapping the error or rethrowing a more specific exception
      throw Exception('Failed to load memos: $e');
    }
  }

  /// Get a single memo by ID, optionally targeting a specific server
  Future<Memo> getMemo(String id, {ServerConfig? targetServerOverride}) async {
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final memoApi = _getMemoApiForServer(targetServerOverride); // Use helper
      final formattedId = _formatResourceName(id, 'memos');
      if (verboseLogging) {
        print(
          '[API getMemo] Getting memo $formattedId from server $serverIdForLog',
        );
      }

      final apiMemo = await memoApi.memoServiceGetMemo(formattedId);

      if (apiMemo == null) {
        throw Exception('Memo $id not found on server $serverIdForLog');
      }

      return _convertApiMemoToAppMemo(apiMemo);
    } catch (e) {
      print(
        '[API getMemo] Error getting memo $id from server $serverIdForLog: $e',
      );
      throw Exception(
        'Failed to load memo $id from server $serverIdForLog: $e',
      );
    }
  }

  /// Create a new memo, optionally targeting a specific server
  Future<Memo> createMemo(
    Memo memo, {
    ServerConfig? targetServerOverride,
  }) async {
    // Determine which API instance and server identifier to use
    final memoApiToUse = _getMemoApiForServer(targetServerOverride);
    final serverIdentifier =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        'active server';

    try {
      final apiMemo = Apiv1Memo(
        content: memo.content,
        pinned: memo.pinned,
        state: _getMemoState(memo.state),
        visibility: _getApiVisibility(memo.visibility),
        // TODO: Handle resources/relations if needed for creation
      );

      if (verboseLogging) {
        print(
          '[API createMemo] Sending createMemo request to $serverIdentifier',
        );
      }

      // Use the determined memoApiToUse instance
      final response = await memoApiToUse.memoServiceCreateMemo(apiMemo);

      if (response == null) {
        throw Exception(
          'Failed to create memo: No response from server $serverIdentifier',
        );
      }

      final createdId = _extractIdFromName(response.name ?? "");
      if (verboseLogging) {
        print(
          '[API createMemo] Memo created successfully on $serverIdentifier with ID: $createdId',
        );
      }
      return _convertApiMemoToAppMemo(response);
    } catch (e) {
      print('[API createMemo] Error creating memo on $serverIdentifier: $e');
      if (e is ApiException) {
        print(
          '[API createMemo] ApiException details: Code=${e.code}, Message=${e.message}, Inner=${e.innerException}',
        );
      }
      throw Exception('Failed to create memo on $serverIdentifier: $e');
    }
  }

  /// Update an existing memo, optionally targeting a specific server
  Future<Memo> updateMemo(
    String id,
    Memo memo, {
    ServerConfig? targetServerOverride,
  }) async {
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final memoApi = _getMemoApiForServer(targetServerOverride); // Use helper
      final formattedId = _formatResourceName(id, 'memos');
      if (verboseLogging) {
        print(
          '[API updateMemo] Updating memo $formattedId on server $serverIdForLog',
        );
      }

      // Use the createTime from the memo object passed in, which should be the original.
      final originalCreateTime = memo.createTime;
      final clientNow = DateTime.now().toUtc(); // Get client's current time

      if (verboseLogging) {
        print(
          '[API updateMemo] Sending client time as updateTime: ${clientNow.toIso8601String()}',
        );
      }

      final updatePayload = TheMemoToUpdateTheNameFieldIsRequired(
        content: memo.content,
        pinned: memo.pinned,
        state: _getMemoState(memo.state),
        visibility: _getApiVisibility(memo.visibility),
        // *** Send client's current time as updateTime ***
        updateTime: clientNow,
        // createTime: null, // Explicitly not sending createTime
      );

      final response = await memoApi.memoServiceUpdateMemo(
        formattedId,
        updatePayload,
      );

      if (response == null) {
        throw Exception(
          'Failed to update memo $id on $serverIdForLog: No response from server',
        );
      }

      // Convert the API response to our app model
      Memo updatedAppMemo = _convertApiMemoToAppMemo(response);

      // Check if the server returned an incorrect epoch createTime
      final responseCreateTimeStr = response.createTime?.toIso8601String();
      if (responseCreateTimeStr != null &&
          (responseCreateTimeStr.startsWith('1970-01-01') ||
              responseCreateTimeStr.startsWith('0001-01-01')) &&
          originalCreateTime != null) {
        if (verboseLogging) {
          print(
            '[API updateMemo] Server returned incorrect createTime (${updatedAppMemo.createTime}), restoring original: $originalCreateTime',
          );
        }
        // Restore the original createTime
        updatedAppMemo = updatedAppMemo.copyWith(
          createTime: originalCreateTime,
        );
      }

      return updatedAppMemo;
    } catch (e) {
      print('[API updateMemo] Error updating memo $id on $serverIdForLog: $e');
      throw Exception('Failed to update memo $id on $serverIdForLog: $e');
    }
  }

  /// Delete a memo, optionally targeting a specific server
  Future<void> deleteMemo(
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final memoApi = _getMemoApiForServer(targetServerOverride); // Use helper
      final formattedId = _formatResourceName(id, 'memos');
      if (verboseLogging) {
        print(
          '[API deleteMemo] Deleting memo $formattedId from server $serverIdForLog',
        );
      }

      final response = await memoApi.memoServiceDeleteMemoWithHttpInfo(
        formattedId,
      );

      // Check for success status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (verboseLogging) {
          print(
            '[API deleteMemo] Successfully deleted memo $id from server $serverIdForLog',
          );
        }
        return;
      } else {
        // Handle error status codes
        final errorBody = await _decodeBodyBytes(response);
        print(
          '[API deleteMemo] Error deleting memo $id from server $serverIdForLog: HTTP ${response.statusCode}, Body: $errorBody',
        );
        throw ApiException(response.statusCode, errorBody);
      }
    } catch (e) {
      // Catch other potential errors (network issues, etc.)
      print(
        '[API deleteMemo] Error deleting memo $id from server $serverIdForLog: $e',
      );
      if (e is ApiException) {
        rethrow;
      }
      throw Exception(
        'Failed to delete memo $id from server $serverIdForLog: $e',
      );
    }
  }

  // RESOURCE OPERATIONS

  /// Upload a resource (e.g., image)
  Future<V1Resource> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType,
  ) async {
    try {
      // Base64 encode the file content
      final String base64Content = base64Encode(fileBytes);

      // Create the resource payload
      final resourcePayload = V1Resource(
        filename: filename,
        type: contentType,
        content: base64Content, // Send base64 encoded content
        // size: fileBytes.length.toString(), // Size might be calculated server-side
      );

      if (verboseLogging) {
        print(
          '[API] Uploading resource: $filename ($contentType, ${fileBytes.length} bytes)',
        );
      }

      // Call the API to create the resource
      final V1Resource? createdResource = await _resourceApi
          .resourceServiceCreateResource(resourcePayload);

      if (createdResource == null || createdResource.name == null) {
        throw Exception(
          'Failed to upload resource: Server returned null or invalid resource',
        );
      }

      if (verboseLogging) {
        print(
          '[API] Resource uploaded successfully: ${createdResource.name} ($filename)',
        );
      }

      return createdResource;
    } catch (e) {
      print('[API] Error uploading resource: $e');
      throw Exception('Failed to upload resource: $e');
    }
  }

  // COMMENT OPERATIONS

  /// List comments for a memo, optionally targeting a specific server
  Future<List<Comment>> listMemoComments(
    String memoId, {
    ServerConfig? targetServerOverride,
  }) async {
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final memoApi = _getMemoApiForServer(targetServerOverride); // Use helper
      final formattedId = _formatResourceName(memoId, 'memos');
      if (verboseLogging) {
        print(
          '[API listMemoComments] Listing comments for memo $formattedId from server $serverIdForLog',
        );
      }

      final response = await memoApi.memoServiceListMemoComments(formattedId);

      if (response == null) {
        if (verboseLogging) {
          print(
            '[API listMemoComments] No comments found for memo $memoId on server $serverIdForLog.',
          );
        }
        return [];
      }

      final comments = _parseCommentsFromApiResponse(response);
      if (verboseLogging) {
        print(
          '[API listMemoComments] Found ${comments.length} comments for memo $memoId on server $serverIdForLog.',
        );
      }
      return comments;
    } catch (e) {
      print(
        '[API listMemoComments] Error listing comments for memo $memoId from server $serverIdForLog: $e',
      );
      throw Exception(
        'Failed to load comments for memo $memoId from server $serverIdForLog: $e',
      );
    }
  }

  /// Create a comment on a memo, optionally targeting a specific server
  Future<Comment> createMemoComment(
    String memoId,
    Comment comment, {
    List<V1Resource>? resources, // Add optional resources parameter
    ServerConfig? targetServerOverride, // Add target server override
  }) async {
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final memoApi = _getMemoApiForServer(targetServerOverride); // Use helper
      final formattedMemoId = _formatResourceName(memoId, 'memos');

      final apiMemo = Apiv1Memo(
        content: comment.content,
        // Creator might be implicitly set by the server based on the auth token
        // creator: comment.creatorId != null ? 'users/${comment.creatorId}' : null,
        pinned: comment.pinned,
        state: _getApiStateFromCommentState(comment.state),
        resources: resources ?? [], // Include resources in the payload
        // Visibility might be inherited or default
      );

      if (verboseLogging) {
        print(
          '[API createMemoComment] Creating comment for memo $formattedMemoId on server $serverIdForLog with ${resources?.length ?? 0} resources.',
        );
      }

      final response = await memoApi.memoServiceCreateMemoComment(
        formattedMemoId,
        apiMemo,
      );

      if (response == null) {
        throw Exception(
          'Failed to create comment on server $serverIdForLog: No response from server',
        );
      }

      final createdCommentId = _extractIdFromName(response.name ?? "");
      if (verboseLogging) {
        print(
          '[API createMemoComment] Comment created successfully on $serverIdForLog with ID: $createdCommentId',
        );
      }

      return _convertApiMemoToComment(response);
    } catch (e) {
      print(
        '[API createMemoComment] Error creating comment for memo $memoId on server $serverIdForLog: $e',
      );
      if (e is ApiException) {
        print('[API createMemoComment] ApiException details: ${e.message}');
      }
      throw Exception(
        'Failed to create comment for memo $memoId on server $serverIdForLog: $e',
      );
    }
  }

  /// Get a single comment, optionally targeting a specific server
  /// commentId should be the child memo's ID without 'memos/' prefix
  Future<Comment> getMemoComment(
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final memoApi = _getMemoApiForServer(targetServerOverride); // Use helper
      // Process combined IDs in format "memoId/commentId" if needed, extracting only the comment's ID
      final String childId =
          commentId.contains('/') ? commentId.split('/').last : commentId;
      final formattedId = _formatResourceName(childId, 'memos');

      if (verboseLogging) {
        print(
          '[API getMemoComment] Getting comment $formattedId from server $serverIdForLog',
        );
      }

      final response = await memoApi.memoServiceGetMemo(formattedId);

      if (response == null) {
        throw Exception('Comment $childId not found on server $serverIdForLog');
      }

      return _convertApiMemoToComment(response);
    } catch (e) {
      print(
        '[API getMemoComment] Error getting comment $commentId from server $serverIdForLog: $e',
      );
      throw Exception(
        'Failed to load comment $commentId from server $serverIdForLog: $e',
      );
    }
  }

  /// Update a comment, optionally targeting a specific server
  /// commentId should be the child memo's ID (can be in the format "memoId/commentId")
  Future<Comment> updateMemoComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  }) async {
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final memoApi = _getMemoApiForServer(targetServerOverride); // Use helper
      // Process combined IDs in format "memoId/commentId" if needed
      final String childId =
          commentId.contains('/') ? commentId.split('/').last : commentId;
      final formattedId = _formatResourceName(childId, 'memos');

      if (verboseLogging) {
        print(
          '[API updateMemoComment] Updating comment $formattedId on server $serverIdForLog',
        );
      }

      final updateMemo = TheMemoToUpdateTheNameFieldIsRequired(
        content: comment.content,
        pinned: comment.pinned,
        state: _getApiStateFromCommentState(comment.state),
        // Add other fields if comments allow updating them (e.g., visibility)
      );

      final response = await memoApi.memoServiceUpdateMemo(
        formattedId,
        updateMemo,
      );

      if (response == null) {
        throw Exception(
          'Failed to update comment $childId on server $serverIdForLog: No response from server',
        );
      }

      return _convertApiMemoToComment(response);
    } catch (e) {
      print(
        '[API updateMemoComment] Error updating comment $commentId on server $serverIdForLog: $e',
      );
      throw Exception(
        'Failed to update comment $commentId on server $serverIdForLog: $e',
      );
    }
  }

  /// Delete a comment, optionally targeting a specific server
  /// commentId should be the child memo's ID (can be in the format "memoId/commentId")
  Future<void> deleteMemoComment(
    String memoId,
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final memoApi = _getMemoApiForServer(targetServerOverride); // Use helper
      // Process combined IDs in format "memoId/commentId" if needed
      final String childId =
          commentId.contains('/') ? commentId.split('/').last : commentId;
      final formattedId = _formatResourceName(childId, 'memos');

      if (verboseLogging) {
        print(
          '[API deleteMemoComment] Deleting comment $formattedId (from memo: $memoId) on server $serverIdForLog',
        );
      }

      final response = await memoApi.memoServiceDeleteMemoWithHttpInfo(
        formattedId,
      );

      // Check for success status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (verboseLogging) {
          print(
            '[API deleteMemoComment] Successfully deleted comment $childId from server $serverIdForLog',
          );
        }
        return;
      } else {
        // Handle error status codes
        final errorBody = await _decodeBodyBytes(response);
        print(
          '[API deleteMemoComment] Error deleting comment $childId from server $serverIdForLog: HTTP ${response.statusCode}, Body: $errorBody',
        );
        throw ApiException(response.statusCode, errorBody);
      }
    } catch (e) {
      print(
        '[API deleteMemoComment] Error deleting comment $commentId (memo $memoId) on server $serverIdForLog: $e',
      );
      if (e is ApiException) {
        rethrow; // Keep the specific API exception
      }
      throw Exception(
        'Failed to delete comment $commentId (memo $memoId) on server $serverIdForLog: $e',
      );
    }
  }

  /// HELPER METHODS (moved inside the class)

  // Helper to get an ApiClient configured for a specific server or the default one
  ApiClient _getApiClientForServer(ServerConfig? serverConfig) {
    // Use default/active client if no override or if override matches active
    if (serverConfig == null ||
        (serverConfig.serverUrl == _baseUrl &&
            serverConfig.authToken == _authToken)) {
      if (verboseLogging && serverConfig != null) {
        print(
          '[API Helper] Using active client for server: ${serverConfig.name ?? serverConfig.id}',
        );
      }
      return _apiClient;
    }

    // Create temporary client for the target server
    if (verboseLogging) {
      print(
        '[API Helper] Creating temporary client for server: ${serverConfig.name ?? serverConfig.id}',
      );
    }
    try {
      String targetBaseUrl = serverConfig.serverUrl;
      // Clean up the base URL (same logic as in _initializeClient)
      if (targetBaseUrl.toLowerCase().contains('/api/v1')) {
        final apiIndex = targetBaseUrl.toLowerCase().indexOf('/api/v1');
        targetBaseUrl = targetBaseUrl.substring(0, apiIndex);
      } else if (targetBaseUrl.toLowerCase().endsWith('/memos')) {
        targetBaseUrl = targetBaseUrl.substring(0, targetBaseUrl.length - 6);
      }
      if (targetBaseUrl.endsWith('/')) {
        targetBaseUrl = targetBaseUrl.substring(0, targetBaseUrl.length - 1);
      }

      return ApiClient(
        basePath: targetBaseUrl,
        authentication: HttpBearerAuth()..accessToken = serverConfig.authToken,
      );
    } catch (e) {
      print(
        '[API Helper] Error creating temporary client for ${serverConfig.name ?? serverConfig.id}: $e',
      );
      // Fallback to default client? Or throw? Throwing is safer.
      throw Exception(
        'Failed to create API client for target server ${serverConfig.name ?? serverConfig.id}: $e',
      );
    }
  }

  // Helper to get a MemoServiceApi instance for a specific server or the default one
  MemoServiceApi _getMemoApiForServer(ServerConfig? serverConfig) {
    return MemoServiceApi(_getApiClientForServer(serverConfig));
  }

  String _formatResourceName(String id, String resourceType) {
    if (id.startsWith('$resourceType/')) {
      return id;
    }
    return '$resourceType/$id';
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
      resourceNames:
          apiMemo.resources
              .map((r) => r.name ?? '')
              .where((name) => name.isNotEmpty)
              .toList(),
      relationList: apiMemo.relations.map((r) => r.toJson()).toList(),
      parent: apiMemo.parent,
      creator: apiMemo.creator,
      createTime: _safeIsoString(apiMemo.createTime),
      updateTime: _safeIsoString(apiMemo.updateTime),
      displayTime: _safeIsoString(apiMemo.displayTime),
    );
  }

  String? _safeIsoString(DateTime? dt) {
    if (dt == null) return null;
    try {
      return dt.toIso8601String();
    } catch (e) {
      print('[API Conversion Error] Failed to format DateTime $dt: $e');
      return null;
    }
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

  V1State _getMemoState(MemoState state) {
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

  CommentState _parseCommentStateFromApi(V1State? state) {
    if (state == null) return CommentState.normal;
    switch (state) {
      case V1State.ARCHIVED:
        return CommentState.archived;
      case V1State.NORMAL:
        return CommentState.normal;
      default:
        return CommentState.normal;
    }
  }

  V1State _getApiStateFromCommentState(CommentState state) {
    switch (state) {
      case CommentState.archived:
        return V1State.ARCHIVED;
      case CommentState.deleted:
        return V1State.ARCHIVED;
      case CommentState.normal:
        return V1State.NORMAL;
    }
  }

  Comment _convertApiMemoToComment(Apiv1Memo apiMemo) {
    final commentId = _extractIdFromName(apiMemo.name ?? '');

    // Ensure createTime is handled correctly (convert DateTime? to int)
    final createTimeMillis =
        apiMemo.createTime?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    final updateTimeMillis = apiMemo.updateTime?.millisecondsSinceEpoch;

    return Comment(
      id: commentId,
      content: apiMemo.content ?? '',
      createTime: createTimeMillis, // Use converted milliseconds
      updateTime: updateTimeMillis, // Use converted milliseconds
      creatorId:
          apiMemo.creator != null ? _extractIdFromName(apiMemo.creator!) : null,
      pinned: apiMemo.pinned ?? false,
      state: _parseCommentStateFromApi(apiMemo.state),
      resources:
          apiMemo.resources.isNotEmpty
              ? apiMemo.resources
              : null, // Map resources
    );
  }

  List<Comment> _parseCommentsFromApiResponse(
    V1ListMemoCommentsResponse response,
  ) {
    return response.memos.map(_convertApiMemoToComment).toList();
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  // Helper function to decode response body bytes (moved inside)
  Future<String> _decodeBodyBytes(http.Response response) async {
    // Handle potential gzip encoding
    if (response.headers['content-encoding'] == 'gzip') {
      try {
        // Assuming GZipCodec is available or imported
        // final decodedBytes = GZipCodec().decode(response.bodyBytes);
        // return utf8.decode(decodedBytes);
        // Placeholder if GZipCodec is not readily available:
        return utf8.decode(
          response.bodyBytes,
          allowMalformed: true,
        ); // Less ideal
      } catch (e) {
        print('[API Decode Error] Failed to decode gzipped response: $e');
        // Fallback to standard decoding, might be garbled
        return utf8.decode(response.bodyBytes, allowMalformed: true);
      }
    }
    // Standard UTF-8 decoding
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  Future<void> setMemoRelations(
    String memoId,
    List<MemoRelation> relations,
  ) async {
    try {
      final formattedId = _formatResourceName(memoId, 'memos');

      if (verboseLogging) {
        print('[API] Setting relations for memo: $formattedId');
      }

      if (relations.isEmpty) {
        if (verboseLogging) {
          print('[API] No relations to set for memo: $memoId');
        }
        return;
      }

      final List<V1MemoRelation> apiRelations = [];
      for (final relation in relations) {
        final apiRelation = relation.toApiRelation();

        if (apiRelation.memo != null) {
          apiRelation.memo!.name = formattedId;
        }

        apiRelations.add(apiRelation);
      }

      if (verboseLogging) {
        print(
          '[API] Prepared ${apiRelations.length} relations for memo: $memoId',
        );
      }

      final requestBody = MemoServiceSetMemoRelationsBody(
        relations: apiRelations,
      );

      await _memoApi.memoServiceSetMemoRelations(formattedId, requestBody);

      if (verboseLogging) {
        print('[API] Successfully set relations for memo: $memoId');
      }
    } catch (e) {
      print('[API] Error setting memo relations: $e');

      if (e.toString().contains('deserialization') ||
          e.toString().contains('500')) {
        print('[API] This appears to be an API compatibility issue.');
        print(
          '[API] The memo was created successfully, but relation setting failed.',
        );
        return;
      }

      throw Exception('Failed to set memo relations: $e');
    }
  }

  Future<List<MemoRelation>> listMemoRelations(String memoId) async {
    try {
      final formattedId = _formatResourceName(memoId, 'memos');

      if (verboseLogging) {
        print('[API] Listing relations for memo: $formattedId');
      }

      final response = await _memoApi.memoServiceListMemoRelations(formattedId);

      if (response == null) {
        return [];
      }

      return response.relations
          .map((relation) => MemoRelation.fromApiRelation(relation))
          .toList();
    } catch (e) {
      print('[API] Error listing memo relations: $e');
      throw Exception('Failed to list memo relations: $e');
    }
  }

  String parseRelationType(dynamic type) {
    if (type == null) return MemoRelation.typeComment;

    String typeStr = type.toString();

    switch (typeStr.toUpperCase()) {
      case 'REFERENCE':
        return MemoRelation.typeReference;
      case 'TYPE_UNSPECIFIED':
        return MemoRelation.typeUnspecified;
      case 'COMMENT':
      default:
        return MemoRelation.typeComment;
    }
  }
}
