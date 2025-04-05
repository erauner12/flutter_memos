import 'package:flutter/foundation.dart';
import 'package:flutter_memos/api/lib/api.dart'; // For V1Resource, Apiv1Memo, etc.
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/memo_relation.dart';
import 'package:flutter_memos/services/api_service.dart';

/// A manual mock implementation of ApiService for testing
class MockApiService implements ApiService {
  // Storage for stub responses
  List<Memo> _mockMemos = [];
  Map<String, Memo> _mockMemoById = {};
  final Map<String, List<Comment>> _mockComments = {};
  final Map<String, List<MemoRelation>> _mockMemoRelations = {};

  // Flag to simulate API failures for testing error handling
  bool shouldFailRelations = false;

  // Mock control - to verify calls
  int listMemosCallCount = 0;
  int getMemoCallCount = 0;
  int createMemoCallCount = 0;
  int updateMemoCallCount = 0;
  int deleteMemoCallCount = 0;
  int createMemoCommentCallCount = 0;
  int listMemoCommentsCallCount = 0; // Added
  int deleteMemoCommentCallCount = 0; // Added
  int listMemoRelationsCallCount = 0; // Added
  int setMemoRelationsCallCount = 0; // Added
  int uploadResourceCallCount = 0; // Added

  // Track parameters for verification
  String? lastGetMemoId;
  String? lastUpdateMemoId;
  Memo? lastUpdateMemoPayload; // Added
  String? lastCreateMemoCommentMemoId;
  Comment? lastCreateMemoCommentComment;
  List<V1Resource>? lastCreateMemoCommentResources; // Added
  String? lastListMemoCommentsMemoId; // Added
  String? lastDeleteMemoCommentMemoId; // Added
  String? lastDeleteMemoCommentCommentId; // Added
  String? lastListMemoRelationsMemoId; // Added
  List<MemoRelation>? lastSetMemoRelationsRelations; // Added
  Uint8List? lastUploadBytes; // Added
  String? lastUploadFilename; // Added
  String? lastUploadContentType; // Added
  V1Resource? mockUploadResourceResponse; // Added

  // Instance fields for controlling listMemos responses
  PaginatedMemoResponse? _initialListResponse; // Changed type
  PaginatedMemoResponse? _subsequentListResponse; // Changed type
  int _listCallCounter = 0; // Instance counter for listMemos calls

  // Mock base URL
  String _mockBaseUrl = 'http://mock.server';

  @override
  String get apiBaseUrl => _mockBaseUrl; // Implement missing getter

  @override
  void configureService({required String baseUrl, required String authToken}) {
    _mockBaseUrl = baseUrl; // Store mock base URL if needed
    if (kDebugMode) {
      print('[MockApiService] Configure service called with baseUrl: $baseUrl');
    }
  }

  // Parameters for last calls
  String? lastListMemosParent;
  String? lastListMemosFilter;
  String? lastListMemosState;
  String? lastListMemosSort;
  String? lastListMemosDirection;
  List<String>? lastListMemosTags;
  dynamic lastListMemosVisibility;
  String? lastListMemosContentSearch;
  int? lastListMemosPageSize; // Added
  String? lastListMemosPageToken; // Added

  // Setup methods to define behavior
  void setMockMemos(List<Memo> memos) {
    _mockMemos = List.from(memos);
    _mockMemoById = {for (var memo in memos) memo.id: memo};
  }

  void setMockMemoById(String id, Memo memo) {
    _mockMemoById[id] = memo;
  }

  void setMockComments(String memoId, List<Comment> comments) {
    _mockComments[memoId] = List.from(comments);
  }

  // Helper to configure mock upload response
  void setMockUploadResourceResponse(V1Resource resource) {
    // Added helper method
    mockUploadResourceResponse = resource;
  }

  // Reset tracking counters for tests
  void resetCallCounts() {
    listMemosCallCount = 0;
    getMemoCallCount = 0;
    createMemoCallCount = 0;
    updateMemoCallCount = 0;
    deleteMemoCallCount = 0;
    createMemoCommentCallCount = 0;
    listMemoCommentsCallCount = 0;
    deleteMemoCommentCallCount = 0;
    listMemoRelationsCallCount = 0;
    setMemoRelationsCallCount = 0;
    uploadResourceCallCount = 0; // Added reset

    lastGetMemoId = null;
    lastUpdateMemoId = null;
    lastUpdateMemoPayload = null; // Added reset
    lastCreateMemoCommentMemoId = null;
    lastCreateMemoCommentComment = null;
    lastCreateMemoCommentResources = null; // Added reset
    lastListMemoCommentsMemoId = null;
    lastDeleteMemoCommentMemoId = null;
    lastDeleteMemoCommentCommentId = null;
    lastListMemoRelationsMemoId = null;
    lastSetMemoRelationsRelations = null;
    lastUploadBytes = null; // Added reset
    lastUploadFilename = null; // Added reset
    lastUploadContentType = null; // Added reset
    mockUploadResourceResponse = null; // Added reset

    // Reset listMemos tracking
    lastListMemosParent = null;
    lastListMemosFilter = null;
    lastListMemosState = null;
    lastListMemosSort = null;
    lastListMemosDirection = null;
    lastListMemosTags = null;
    lastListMemosVisibility = null;
    lastListMemosContentSearch = null;
    lastListMemosPageSize = null;
    lastListMemosPageToken = null;

    // Reset list call counter for instance-specific responses
    _listCallCounter = 0;
  }

  // Mock implementations
  @override
  Future<PaginatedMemoResponse> listMemos({
    // Updated signature
    String parent = 'users/1', // Default parent added
    String? filter,
    String? state, // Changed to nullable String
    String sort = 'updateTime',
    String direction = 'DESC',
    int? pageSize, // Added
    String? pageToken, // Added
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
    listMemosCallCount++;

    // Store parameters for verification
    lastListMemosParent = parent;
    lastListMemosFilter = filter;
    lastListMemosState = state;
    lastListMemosSort = sort;
    lastListMemosDirection = direction;
    lastListMemosTags = tags;
    lastListMemosVisibility = visibility;
    lastListMemosContentSearch = contentSearch;
    lastListMemosPageSize = pageSize; // Store pageSize
    lastListMemosPageToken = pageToken; // Store pageToken

    // Logic to return controlled responses based on call count
    _listCallCounter++;
    print('[Mock listMemos] Instance call number: $_listCallCounter');

    // Simulate pagination roughly if pageSize is provided
    List<Memo> memosToReturn = List.from(_mockMemos); // Start with all memos
    String? nextPageToken;

    if (pageSize != null && pageSize > 0 && memosToReturn.length > pageSize) {
      int startIndex = 0;
      if (pageToken != null) {
        // Very basic token simulation: assume token is the index to start from
        try {
          startIndex = int.parse(pageToken);
        } catch (e) {
          startIndex = 0; // Default if token is invalid
        }
      }

      int endIndex = startIndex + pageSize;
      if (endIndex < memosToReturn.length) {
        nextPageToken =
            endIndex.toString(); // Next token is the next start index
      } else {
        endIndex = memosToReturn.length; // Don't go past the end
      }

      if (startIndex < memosToReturn.length) {
        memosToReturn = memosToReturn.sublist(startIndex, endIndex);
      } else {
        memosToReturn = []; // Start index is beyond the list
      }
    } else {
      // No pagination or page size covers all memos
      nextPageToken = null;
    }

    if (_listCallCounter == 1 && _initialListResponse != null) {
      print('[Mock listMemos] Returning initial instance response.');
      return Future.value(_initialListResponse!); // Return configured response
    } else if (_listCallCounter > 1 && _subsequentListResponse != null) {
      print('[Mock listMemos] Returning subsequent instance response.');
      return Future.value(
        _subsequentListResponse!,
      ); // Return configured response
    } else {
      print('[Mock listMemos] Returning default mockMemos (fallback).');
      // Fallback to the general _mockMemos if specific ones aren't set
      return Future.value(
        PaginatedMemoResponse(
          memos: memosToReturn,
          nextPageToken: nextPageToken,
        ),
      );
    }
  }

  // Methods to control listMemos responses for testing
  void setMockListMemosResponse(PaginatedMemoResponse response) {
    // Updated type
    _initialListResponse = response; // Store the response
    _listCallCounter = 0; // Reset counter when setting initial response
    print(
      '[Mock Setup] Set initial listMemos response with ${response.memos.length} memos for this instance.',
    );
  }

  void setMockListMemosResponseForSubsequentCalls(
    PaginatedMemoResponse response,
  ) {
    // Updated type
    _subsequentListResponse = response; // Store the response
    print(
      '[Mock Setup] Set subsequent listMemos response with ${response.memos.length} memos for this instance.',
    );
  }

  // Helper to log the setup for updateMemo mock response
  void setMockUpdateMemoResponse(String id, Memo responseMemo) {
    print(
      '[Mock Setup] Mock response for updateMemo ID: $id is configured in base mock.',
    );
    _mockMemoById[id] = responseMemo;
  }

  @override
  Future<Memo> getMemo(String id) async {
    getMemoCallCount++;
    lastGetMemoId = id;
    final memo = _mockMemoById[id];
    if (memo == null) {
      // Try finding by formatted name if ID doesn't match directly
      final formattedId = id.startsWith('memos/') ? id : 'memos/$id';
      final foundMemo = _mockMemoById.values.firstWhere(
        (m) => 'memos/${m.id}' == formattedId,
        orElse: () => throw Exception('Memo not found: $id'),
      );
      return Future.value(foundMemo);
    }
    return Future.value(memo);
  }

  @override
  Future<Memo> createMemo(Memo memo) async {
    createMemoCallCount++;
    final createdMemo = Memo(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      content: memo.content,
      pinned: memo.pinned,
      state: memo.state,
      visibility: memo.visibility,
      createTime: DateTime.now().toIso8601String(), // Add createTime
      updateTime: DateTime.now().toIso8601String(), // Add updateTime
    );
    _mockMemos.add(createdMemo);
    _mockMemoById[createdMemo.id] = createdMemo;
    return Future.value(createdMemo);
  }

  @override
  Future<Memo> updateMemo(String id, Memo memo) async {
    updateMemoCallCount++;
    lastUpdateMemoId = id;
    lastUpdateMemoPayload = memo; // Store the payload

    final existingMemo = _mockMemoById[id];
    if (existingMemo == null) {
      throw Exception('Memo not found for update: $id');
    }

    // Simulate updating a memo, preserving original createTime
    final updatedMemo = Memo(
      id: id,
      content: memo.content,
      pinned: memo.pinned,
      state: memo.state,
      visibility: memo.visibility,
      createTime: existingMemo.createTime, // Preserve original create time
      updateTime: DateTime.now().toIso8601String(), // Set new update time
    );
    _mockMemoById[id] = updatedMemo;
    final index = _mockMemos.indexWhere((m) => m.id == id);
    if (index != -1) {
      _mockMemos[index] = updatedMemo;
    }
    return Future.value(updatedMemo);
  }

  @override
  Future<void> deleteMemo(String id) async {
    deleteMemoCallCount++;
    final formattedId = id.startsWith('memos/') ? id.split('/').last : id;
    _mockMemoById.remove(formattedId);
    _mockMemos.removeWhere((memo) => memo.id == formattedId);
    return Future.value();
  }

  // --- Resource Operations ---
  @override
  Future<V1Resource> uploadResource(
    // Added implementation
    Uint8List fileBytes,
    String filename,
    String contentType,
  ) async {
    uploadResourceCallCount++;
    lastUploadBytes = fileBytes;
    lastUploadFilename = filename;
    lastUploadContentType = contentType;

    if (mockUploadResourceResponse != null) {
      print(
        '[MockApiService] uploadResource called, returning configured mock resource: ${mockUploadResourceResponse!.name}',
      );
      // Return a copy to avoid modification issues
      return Future.value(
        V1Resource(
          name: mockUploadResourceResponse!.name,
          filename: filename,
          type: contentType,
          size: mockUploadResourceResponse!.size,
          createTime: mockUploadResourceResponse!.createTime,
          // The updateTime property doesn't exist in V1Resource
        ),
      );
    } else {
      // Default mock response if not configured
      final defaultResourceName =
          'resources/mock-resource-${DateTime.now().millisecondsSinceEpoch}';
      print(
        '[MockApiService] uploadResource called, returning default mock resource: $defaultResourceName',
      );
      return Future.value(
        V1Resource(
          name: defaultResourceName,
          filename: filename,
          type: contentType,
          size: fileBytes.length.toString(), // Add size
          createTime: DateTime.now(), // Add createTime
        ),
      );
    }
  }

  // --- Comment Operations ---
  @override
  Future<List<Comment>> listMemoComments(String memoId) async {
    listMemoCommentsCallCount++;
    lastListMemoCommentsMemoId = memoId;
    return Future.value(_mockComments[memoId] ?? []);
  }

  @override
  Future<Comment> createMemoComment(
    // Updated signature
    String memoId,
    Comment comment, {
    List<V1Resource>? resources, // Added named parameter
  }) async {
    createMemoCommentCallCount++;
    lastCreateMemoCommentMemoId = memoId;
    lastCreateMemoCommentComment = comment;
    lastCreateMemoCommentResources = resources; // Store resources

    final now = DateTime.now().millisecondsSinceEpoch;
    final createdComment = Comment(
      id:
          comment.id.startsWith('temp-')
              ? 'comment-${DateTime.now().millisecondsSinceEpoch}'
              : comment.id,
      content: comment.content,
      creatorId: comment.creatorId ?? 'mock-user',
      createTime: comment.createTime, // Use provided createTime
      updateTime: now,
      state: comment.state,
      pinned: comment.pinned,
      resources: resources, // Assign resources
    );

    _mockComments.putIfAbsent(memoId, () => []).add(createdComment);

    print(
      '[MockApiService] Created comment ${createdComment.id} for memo $memoId with ${resources?.length ?? 0} resources.',
    );
    return Future.value(createdComment);
  }

  @override
  Future<Comment> getMemoComment(String commentId) async {
    String memoId = '';
    String childId = commentId;

    if (commentId.contains('/')) {
      final parts = commentId.split('/');
      memoId = parts[0];
      childId = parts[1];
    } else {
      for (final entry in _mockComments.entries) {
        final comment = entry.value.firstWhere(
          (c) => c.id == childId,
          orElse:
              () => Comment(
                id: '',
                content: '',
                createTime: 0,
              ), // Return dummy if not found
        );
        if (comment.id.isNotEmpty) {
          memoId = entry.key;
          break;
        }
      }
    }

    if (memoId.isEmpty) throw Exception('Comment not found: $commentId');
    final commentsList = _mockComments[memoId];
    if (commentsList == null) throw Exception('No comments for memo: $memoId');

    final comment = commentsList.firstWhere(
      (c) => c.id == childId,
      orElse:
          () => throw Exception('Comment not found: $childId in memo $memoId'),
    );
    return Future.value(comment);
  }

  @override
  Future<Comment> updateMemoComment(
    String commentId,
    Comment updatedComment,
  ) async {
    String memoId = '';
    String childId = commentId;

    if (commentId.contains('/')) {
      final parts = commentId.split('/');
      memoId = parts[0];
      childId = parts[1];
    } else {
      for (final entry in _mockComments.entries) {
        final idx = entry.value.indexWhere((c) => c.id == childId);
        if (idx != -1) {
          memoId = entry.key;
          break;
        }
      }
    }

    if (memoId.isEmpty) throw Exception('Comment not found: $commentId');
    final commentsList = _mockComments[memoId];
    if (commentsList == null) throw Exception('No comments for memo: $memoId');

    final commentIndex = commentsList.indexWhere((c) => c.id == childId);
    if (commentIndex < 0)
      throw Exception('Comment not found: $childId in memo $memoId');

    final originalComment = commentsList[commentIndex];
    final updated = Comment(
      id: originalComment.id,
      content: updatedComment.content,
      createTime: originalComment.createTime,
      updateTime: DateTime.now().millisecondsSinceEpoch,
      creatorId: originalComment.creatorId,
      pinned: updatedComment.pinned,
      state: updatedComment.state,
      resources:
          updatedComment.resources ??
          originalComment.resources, // Preserve or update resources
    );
    commentsList[commentIndex] = updated;
    return Future.value(updated);
  }

  @override
  Future<void> deleteMemoComment(String memoId, String commentId) async {
    deleteMemoCommentCallCount++;
    lastDeleteMemoCommentMemoId = memoId;
    lastDeleteMemoCommentCommentId = commentId;

    final commentsList = _mockComments[memoId];
    if (commentsList == null) {
      throw Exception('No comments found for memo: $memoId');
    }
    final initialLength = commentsList.length;
    commentsList.removeWhere((c) => c.id == commentId);
    if (commentsList.length == initialLength) {
      throw Exception('Comment not found: $commentId in memo $memoId');
    }
    return Future.value();
  }

  // --- Relation Operations ---
  @override
  Future<void> setMemoRelations(
    String memoId,
    List<MemoRelation> relations,
  ) async {
    setMemoRelationsCallCount++;
    lastListMemoRelationsMemoId = memoId;
    lastSetMemoRelationsRelations = relations;

    if (shouldFailRelations) {
      throw Exception('Simulated API error: Could not set relations');
    }
    final formattedId = memoId.contains('/') ? memoId.split('/').last : memoId;
    _mockMemoRelations[formattedId] =
        relations
            .map(
              (r) => MemoRelation(
                relatedMemoId: r.relatedMemoId,
                type: r.type,
              ),
            )
            .toList(); // Store copies
    return Future.value();
  }

  @override
  Future<List<MemoRelation>> listMemoRelations(String memoId) async {
    listMemoRelationsCallCount++;
    lastListMemoRelationsMemoId = memoId;

    if (shouldFailRelations) {
      throw Exception('Simulated API error: Failed to list relations');
    }

    final formattedId = memoId.contains('/') ? memoId.split('/').last : memoId;
    final relations = _mockMemoRelations[formattedId];
    if (relations == null) return [];
    
    return Future.value(
      relations
          .map(
            (r) => MemoRelation(
              relatedMemoId: r.relatedMemoId,
              type: r.type,
            ),
          )
          .toList(),
    ); // Return copies
  }

  @override
  // Keep this method for API compatibility, even though it's not used
  @Deprecated('Method no longer used but kept for interface compatibility')
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
  
  // Deprecated methods - provide dummy implementations or throw errors
  // Not overriding any method in ApiService
  Future<MemoRelation> setMemoRelation(MemoRelation relation) async {
    throw UnimplementedError('setMemoRelation is deprecated in mock');
  }
}
