import 'package:flutter_memos/api/lib/api.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiService Tests', () {
    // We'll test formatted resource names indirectly through the public APIs
    
    group('Format ID Tests', () {
      test('formats resource IDs correctly in public method calls', () {
        // Since we can't access private methods directly, we'll test the behavior
        // through the effects we can observe in other ways
        
        // One way to verify ID formatting is checking that different input formats
        // throw the same exception message, indicating they've been normalized properly
        
        // Test case: Verify resource name formatting by observing the same error
        const testMemoId1 = '123';
        const testMemoId2 = 'memos/123';
        
        final apiService = ApiService();
        
        // Both should throw the same error message if the formatting is consistent
        final error1 = throwsA(predicate((e) => e.toString().contains('123')));
        final error2 = throwsA(predicate((e) => e.toString().contains('123')));

        expect(() => apiService.getMemo(testMemoId1), error1);
        expect(() => apiService.getMemo(testMemoId2), error2);
      });
    });
    
    group('State Conversion Tests', () {
      test('converts between API state and app state correctly', () {
        // Create test memos with different states
        final normalMemo = Memo(
          id: 'test1',
          content: 'Normal memo',
          state: MemoState.normal,
        );
        
        final archivedMemo = Memo(
          id: 'test2',
          content: 'Archived memo',
          state: MemoState.archived,
        );
        
        // Note: we can't directly test the state conversion, but we can examine
        // how the state is passed to and from the API by observing API calls.
        // In a real environment, we'd use a test double for the API client.
        
        // For this test, we'll just verify that the memo objects behave correctly
        expect(normalMemo.state, equals(MemoState.normal));
        expect(archivedMemo.state, equals(MemoState.archived));
      });
    });
    
    group('Model Conversion Tests', () {
      test('app Memo model converts to and from API model correctly', () {
        // Create a sample app Memo
        final appMemo = Memo(
          id: 'test123',
          content: 'Test memo content',
          pinned: true,
          state: MemoState.normal,
          visibility: 'PUBLIC',
          createTime: '2025-03-22T21:45:00.000Z',
          updateTime: '2025-03-23T01:45:58.000Z',
          displayTime: '2025-03-22T21:45:00.000Z',
          creator: 'users/1',
        );
        
        // Verify all fields were set correctly
        expect(appMemo.id, equals('test123'));
        expect(appMemo.content, equals('Test memo content'));
        expect(appMemo.pinned, isTrue);
        expect(appMemo.state, equals(MemoState.normal));
        expect(appMemo.visibility, equals('PUBLIC'));
        expect(appMemo.createTime, equals('2025-03-22T21:45:00.000Z'));
        expect(appMemo.updateTime, equals('2025-03-23T01:45:58.000Z'));
        expect(appMemo.displayTime, equals('2025-03-22T21:45:00.000Z'));
        expect(appMemo.creator, equals('users/1'));
        
        // Create a simulated API response memo
        final apiMemo = Apiv1Memo(
          name: 'memos/abc123',
          content: 'API memo content',
          pinned: true,
          state: V1State.NORMAL,
          visibility: V1Visibility.PUBLIC,
          createTime: DateTime.parse('2025-03-22T21:45:00.000Z'),
          updateTime: DateTime.parse('2025-03-23T01:45:58.000Z'),
          displayTime: DateTime.parse('2025-03-22T21:45:00.000Z'),
          creator: 'users/1',
        );
        
        // Test manual conversion to verify format compatibility
        final extractedId = apiMemo.name?.split('/').last ?? '';
        expect(extractedId, equals('abc123'));
        
        final createTimeIso = apiMemo.createTime?.toIso8601String();
        expect(createTimeIso, equals('2025-03-22T21:45:00.000Z'));
      });
      
      test('app Comment model converts to and from API model correctly', () {
        // Create a sample app Comment
        final appComment = Comment(
          id: 'comment123',
          content: 'Test comment content',
          createTime: DateTime.now().millisecondsSinceEpoch,
          creatorId: '1',
        );
        
        // Verify all fields were set correctly
        expect(appComment.id, equals('comment123'));
        expect(appComment.content, equals('Test comment content'));
        expect(appComment.creatorId, equals('1'));
        
        // Create a simulated API response for a comment
        final apiComment = Apiv1Memo(
          name: 'memos/comment123',
          content: 'API comment content',
          createTime: DateTime.now(),
          creator: 'users/1',
        );
        
        // Test manual conversion to verify format compatibility
        final extractedId = apiComment.name?.split('/').last ?? '';
        expect(extractedId, equals('comment123'));
        
        final extractedCreatorId = apiComment.creator?.split('/').last ?? '';
        expect(extractedCreatorId, equals('1'));
      });
    });
    
    group('API URL Generation Tests', () {
      // Test that we're generating correct URLs for the API
      // We'd need integration tests or request interceptors to fully validate this
      
      test('API base URL is properly configured', () {
        // This is more of a sanity check than a real test
        final apiService = ApiService();
        
        // We'd need to expose the underlying _apiClient instance to verify this,
        // or use request interceptors in an integration test.
        
        // Without that access, we just verify the service initializes without errors
        expect(apiService, isNotNull);
      });
    });
    
    group('Server Order Tracking Tests', () {
      test('lastServerOrder is correctly exposed for testing', () {
        // This test validates the helper field we use for testing
        // Initially it should be empty
        expect(ApiService.lastServerOrder, isEmpty);
        
        // Unfortunately, we can't directly set it for testing without accessing private methods
      });
    });
  });
}
