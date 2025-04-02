import 'package:flutter/foundation.dart';
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

  // Track parameters for verification
  String? lastGetMemoId;
  String? lastUpdateMemoId;
  String? lastCreateMemoCommentMemoId;
  Comment? lastCreateMemoCommentComment;

  // Instance fields for controlling listMemos responses
  List<Memo>? _initialListResponse;
  List<Memo>? _subsequentListResponse;
  int _listCallCounter = 0; // Instance counter for listMemos calls

  @override
  void configureService({required String baseUrl, required String authToken}) {
    // No-op in mock implementation
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
  
  // Setup methods to define behavior
  void setMockMemos(List<Memo> memos) {
    _mockMemos = List.from(memos);
    
    // Also update by-id cache
    _mockMemoById = {};
    for (var memo in memos) {
      _mockMemoById[memo.id] = memo;
    }
  }
  
  void setMockMemoById(String id, Memo memo) {
    _mockMemoById[id] = memo;
  }
  
  void setMockComments(String memoId, List<Comment> comments) {
    _mockComments[memoId] = List.from(comments);
  }
  
  // Reset tracking counters for tests
  void resetCallCounts() {
    listMemosCallCount = 0;
    getMemoCallCount = 0;
    createMemoCallCount = 0;
    updateMemoCallCount = 0;
    deleteMemoCallCount = 0;
    createMemoCommentCallCount = 0;

    lastGetMemoId = null;
    lastUpdateMemoId = null;
    lastCreateMemoCommentMemoId = null;
    lastCreateMemoCommentComment = null;
  }

  // Mock implementations
  @override
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

    // Logic to return controlled responses based on call count
    _listCallCounter++;
    print('[Mock listMemos] Instance call number: $_listCallCounter');

    if (_listCallCounter == 1 && _initialListResponse != null) {
      print('[Mock listMemos] Returning initial instance response.');
      return Future.value(List.from(_initialListResponse!)); // Return copy
    } else if (_listCallCounter > 1 && _subsequentListResponse != null) {
      print('[Mock listMemos] Returning subsequent instance response.');
      return Future.value(List.from(_subsequentListResponse!)); // Return copy
    } else if (_initialListResponse != null) {
      print('[Mock listMemos] Returning initial instance response (default).');
      return Future.value(
        List.from(_initialListResponse!),
      ); // Fallback to initial
    } else {
      print('[Mock listMemos] Returning default mockMemos (fallback).');
      // Fallback to the general _mockMemos if specific ones aren't set
      return Future.value(List.from(_mockMemos));
    }
  }

  // Methods to control listMemos responses for testing
  void setMockListMemosResponse(List<Memo> memos) {
    _initialListResponse = List.from(memos); // Store a copy
    _listCallCounter = 0; // Reset counter when setting initial response
    print(
      '[Mock Setup] Set initial listMemos response with ${memos.length} memos for this instance.',
    );
  }

  void setMockListMemosResponseForSubsequentCalls(List<Memo> memos) {
    _subsequentListResponse = List.from(memos); // Store a copy
    print(
      '[Mock Setup] Set subsequent listMemos response with ${memos.length} memos for this instance.',
    );
  }

  // Helper to log the setup for updateMemo mock response
  // The actual response logic is handled within the base MockApiService.updateMemo
  void setMockUpdateMemoResponse(String id, Memo responseMemo) {
    print(
      '[Mock Setup] Mock response for updateMemo ID: $id is configured in base mock.',
    );
    // No actual logic needed here for the manual mock setup used in the test.
    // The base MockApiService.updateMemo will be called by the provider.
    // We might enhance this later if needed to return specific data per ID.
    _mockMemoById[id] = responseMemo; // Store it so getMemo works if called
  }

  @override
  Future<Memo> getMemo(String id) async {
    getMemoCallCount++;
    lastGetMemoId = id;
    final memo = _mockMemoById[id];
    if (memo == null) {
      throw Exception('Memo not found');
    }
    return Future.value(memo);
  }

  @override
  Future<Memo> createMemo(Memo memo) async {
    createMemoCallCount++;
    // Simulate creating a memo with a new ID
    final createdMemo = Memo(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      content: memo.content,
      pinned: memo.pinned,
      state: memo.state,
      visibility: memo.visibility,
    );
    
    _mockMemos.add(createdMemo);
    _mockMemoById[createdMemo.id] = createdMemo;
    
    return Future.value(createdMemo);
  }

  @override
  Future<Memo> updateMemo(String id, Memo memo) async {
    updateMemoCallCount++;
    lastUpdateMemoId = id;
    // Simulate updating a memo
    final updatedMemo = Memo(
      id: id,
      content: memo.content,
      pinned: memo.pinned,
      state: memo.state,
      visibility: memo.visibility,
    );
    
    _mockMemoById[id] = updatedMemo;
    
    // Also update in the list
    for (var i = 0; i < _mockMemos.length; i++) {
      if (_mockMemos[i].id == id) {
        _mockMemos[i] = updatedMemo;
        break;
      }
    }
    
    return Future.value(updatedMemo);
  }

  @override
  Future<void> deleteMemo(String id) async {
    deleteMemoCallCount++;
    
    // Remove from id map
    _mockMemoById.remove(id);
    
    // Remove from list
    _mockMemos.removeWhere((memo) => memo.id == id);
    
    return Future.value();
  }

  @override
  Future<List<Comment>> listMemoComments(String memoId) async {
    return Future.value(_mockComments[memoId] ?? []);
  }

  @override
  Future<Comment> createMemoComment(String memoId, Comment comment) async {
    createMemoCommentCallCount++;
    lastCreateMemoCommentMemoId = memoId;
    lastCreateMemoCommentComment = comment;
    
    // Simulate creating a comment
    final createdComment = Comment(
      id: 'comment-${DateTime.now().millisecondsSinceEpoch}',
      content: comment.content,
      createTime: DateTime.now().millisecondsSinceEpoch,
      creatorId: comment.creatorId,
      pinned: comment.pinned,
      state: comment.state,
    );
    
    if (_mockComments[memoId] == null) {
      _mockComments[memoId] = [];
    }
    
    _mockComments[memoId]!.add(createdComment);
    
    return Future.value(createdComment);
  }

  @override
  Future<Comment> getMemoComment(String commentId) async {
    // Handle combined IDs in format "memoId/commentId"
    String memoId = '';
    String childId = commentId;

    if (commentId.contains('/')) {
      final parts = commentId.split('/');
      memoId = parts[0];
      childId = parts[1];
    } else {
      // If only childId is provided, we need to find which memo contains it
      for (final entry in _mockComments.entries) {
        final comments = entry.value;
        final comment = comments.firstWhere(
          (c) => c.id == childId,
          orElse: () => Comment(id: '', content: '', createTime: 0),
        );

        if (comment.id.isNotEmpty) {
          memoId = entry.key;
          break;
        }
      }
    }

    if (memoId.isEmpty) {
      throw Exception('Comment not found: $commentId');
    }

    final commentsList = _mockComments[memoId];
    if (commentsList == null) {
      throw Exception('No comments found for memo: $memoId');
    }

    final comment = commentsList.firstWhere(
      (c) => c.id == childId,
      orElse: () => throw Exception('Comment not found: $childId'),
    );

    return Future.value(comment);
  }

  @override
  Future<Comment> updateMemoComment(
    String commentId,
    Comment updatedComment,
  ) async {
    // Handle combined IDs in format "memoId/commentId"
    String memoId = '';
    String childId = commentId;

    if (commentId.contains('/')) {
      final parts = commentId.split('/');
      memoId = parts[0];
      childId = parts[1];
    } else {
      // If only childId is provided, we need to find which memo contains it
      for (final entry in _mockComments.entries) {
        final comments = entry.value;
        final commentIndex = comments.indexWhere((c) => c.id == childId);

        if (commentIndex >= 0) {
          memoId = entry.key;
          break;
        }
      }
    }

    if (memoId.isEmpty) {
      throw Exception('Comment not found: $commentId');
    }

    final commentsList = _mockComments[memoId];
    if (commentsList == null) {
      throw Exception('No comments found for memo: $memoId');
    }

    final commentIndex = commentsList.indexWhere((c) => c.id == childId);
    if (commentIndex < 0) {
      throw Exception('Comment not found: $childId');
    }

    // Create an updated copy that preserves the ID and creation time
    final originalComment = commentsList[commentIndex];
    final updated = Comment(
      id: originalComment.id,
      content: updatedComment.content,
      createTime: originalComment.createTime,
      updateTime: DateTime.now().millisecondsSinceEpoch,
      creatorId: originalComment.creatorId,
      pinned: updatedComment.pinned,
      state: updatedComment.state,
    );

    // Replace in the list
    commentsList[commentIndex] = updated;

    return Future.value(updated);
  }

  @override
  Future<void> deleteMemoComment(String memoId, String commentId) async {
    // This implementation handles both the two-parameter version
    return deleteMemoComment_internal('$memoId/$commentId');
  }

  // Internal implementation for deleteMemoComment to avoid duplicate signatures
  Future<void> deleteMemoComment_internal(String commentId) async {
    // Handle combined IDs in format "memoId/commentId"
    String memoId = '';
    String childId = commentId;

    if (commentId.contains('/')) {
      final parts = commentId.split('/');
      memoId = parts[0];
      childId = parts[1];
    } else {
      // If only childId is provided, we need to find which memo contains it
      for (final entry in _mockComments.entries) {
        final comments = entry.value;
        final comment = comments.firstWhere(
          (c) => c.id == childId,
          orElse: () => Comment(id: '', content: '', createTime: 0),
        );

        if (comment.id.isNotEmpty) {
          memoId = entry.key;
          break;
        }
      }
    }

    if (memoId.isEmpty) {
      throw Exception('Comment not found: $commentId');
    }

    final commentsList = _mockComments[memoId];
    if (commentsList == null) {
      throw Exception('No comments found for memo: $memoId');
    }

    final initialLength = commentsList.length;
    _mockComments[memoId] =
        commentsList.where((c) => c.id != childId).toList();

    if (_mockComments[memoId]!.length == initialLength) {
      throw Exception('Comment not found: $childId');
    }

    return Future.value();
  }

  @override
  Future<MemoRelation> setMemoRelation(MemoRelation relation) async {
    // Simulate API failures if the flag is set
    if (shouldFailRelations) {
      throw Exception('Simulated API error: Could not find a suitable class for deserialization');
    }
    
    // Ensure we have a list to add to
    final memoId = relation.relatedMemoId; // Use relatedMemoId as the key
    if (_mockMemoRelations[memoId] == null) {
      _mockMemoRelations[memoId] = [];
    }
    
    _mockMemoRelations[memoId]!.add(relation);
    
    return Future.value(relation);
  }

  @override
  Future<void> setMemoRelations(
    String memoId,
    List<MemoRelation> relations,
  ) async {
    // Simulate API failures if the flag is set
    if (shouldFailRelations) {
      throw Exception(
        'Simulated API error: Could not find a suitable class for deserialization',
      );
    }

    // Ensure we store it with a consistent ID format
    final formattedId = memoId.contains('/') ? memoId.split('/').last : memoId;

    // Create a deep copy to avoid shared references
    _mockMemoRelations[formattedId] =
        relations
            .map(
              (relation) => MemoRelation(
                relatedMemoId: relation.relatedMemoId,
                type: relation.type,
              ),
            )
            .toList();

    return Future.value();
  }

  @override
  Future<List<MemoRelation>> listMemoRelations(String memoId) async {
    // Simulate API failures if the flag is set
    if (shouldFailRelations) {
      throw Exception('Simulated API error: Failed to list relations');
    }
    
    // Return a deep copy to prevent mutations affecting stored data
    final relations = _mockMemoRelations[memoId];
    if (relations == null) {
      return [];
    }

    return relations
        .map(
          (relation) => MemoRelation(
            relatedMemoId: relation.relatedMemoId,
            type: relation.type,
          ),
        )
        .toList();
  }
  
  @override
  String parseRelationType(dynamic type) {
    if (type == null) return MemoRelation.typeComment;

    // Handle different type possibilities
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
