import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:mockito/mockito.dart';

// Import the generated mock file
import 'edit_memo_screen_test.mocks.dart';

/// Configure common stubs for the mock ApiService
void setupCommonApiServiceMocks(MockApiService mockApiService) {
  // Add stub for apiBaseUrl property
  when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');
  
  // Add a generic listMemos stub to avoid errors during refresh operations
  when(
    mockApiService.listMemos(
      parent: anyNamed('parent'),
      filter: anyNamed('filter'),
      state: anyNamed('state'),
      sort: anyNamed('sort'),
      direction: anyNamed('direction'),
      pageSize: anyNamed('pageSize'),
      pageToken: anyNamed('pageToken'),
      tags: anyNamed('tags'),
      visibility: anyNamed('visibility'),
      contentSearch: anyNamed('contentSearch'),
      createdAfter: anyNamed('createdAfter'),
      createdBefore: anyNamed('createdBefore'),
      updatedAfter: anyNamed('updatedAfter'),
      updatedBefore: anyNamed('updatedBefore'),
      timeExpression: anyNamed('timeExpression'),
      useUpdateTimeForExpression: anyNamed('useUpdateTimeForExpression'),
    ),
  ).thenAnswer(
    (_) async => PaginatedMemoResponse(memos: [], nextPageToken: null),
  );
}

/// Create a list of test memos for use in tests
List<Memo> createTestMemos(int count, {bool includeArchived = false}) {
  return List.generate(count, (i) {
    final now = DateTime.now();
    final updateTime = now.subtract(Duration(minutes: i)).toIso8601String();
    return Memo(
      id: 'memo_$i',
      content: 'Test Memo Content $i',
      pinned: i == 0, // First memo is pinned by default
      state: includeArchived && i == count - 1 ? MemoState.archived : MemoState.normal,
      updateTime: updateTime,
      createTime: updateTime,
    );
  });
}
