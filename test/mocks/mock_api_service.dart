import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';

/// A manual mock implementation of ApiService for testing
class MockApiService implements ApiService {
  // Storage for stub responses
  List<Memo> _mockMemos = [];
  Map<String, Memo> _mockMemoById = {};
  final Map<String, List<Comment>> _mockComments = {};
  
  // Mock control - to verify calls
  int listMemosCallCount = 0;
  int getMemoCallCount = 0;
  int createMemoCallCount = 0;
  int updateMemoCallCount = 0;
  int deleteMemoCallCount = 0;

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
    
    // Return the mock data
    return Future.value(_mockMemos);
  }

  @override
  Future<Memo> getMemo(String id) async {
    getMemoCallCount++;
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
    // Simulate creating a comment
    final createdComment = Comment(
      id: 'comment-${DateTime.now().millisecondsSinceEpoch}',
      content: comment.content,
      createTime: DateTime.now().millisecondsSinceEpoch,
      creatorId: comment.creatorId,
    );
    
    if (_mockComments[memoId] == null) {
      _mockComments[memoId] = [];
    }
    
    _mockComments[memoId]!.add(createdComment);
    
    return Future.value(createdComment);
  }
}
