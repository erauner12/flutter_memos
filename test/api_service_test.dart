import 'package:flutter_memos/api/lib/api.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mock classes
@GenerateMocks([MemoServiceApi, ApiClient])
import 'api_service_test.mocks.dart';

void main() {
  group('ApiService Unit Tests', () {
    late ApiService apiService;
    late MockMemoServiceApi mockMemoApi;
    
    setUp(() {
      apiService = ApiService();
      // Access the private _memoApi field (for unit testing only)
      mockMemoApi = MockMemoServiceApi();
      // We'd need to use reflection to inject the mock, which is complex
      // Instead, we'll test specific utility methods
    });
    
    group('Helper Method Tests', () {
      test('_formatResourceName formats ID correctly', () {
        // Using invoke to access a private method (for test only)
        final formatResourceName = apiService.formatResourceNameForTest;
        
        // Test without prefix
        expect(formatResourceName('123', 'memos'), equals('memos/123'));
        
        // Test with prefix already present
        expect(formatResourceName('memos/123', 'memos'), equals('memos/123'));
        
        // Test with comments
        expect(formatResourceName('456', 'comments'), equals('comments/456'));
      });
      
      test('_extractIdFromName extracts ID correctly', () {
        final extractIdFromName = apiService.extractIdFromNameForTest;
        
        // Test with memo resource name
        expect(extractIdFromName('memos/abc123'), equals('abc123'));
        
        // Test with user resource name
        expect(extractIdFromName('users/1'), equals('1'));
        
        // Test with already extracted ID
        expect(extractIdFromName('plainId'), equals('plainId'));
        
        // Test with empty string
        expect(extractIdFromName(''), equals(''));
      });
    });
    
    group('Model Conversion Tests', () {
      test('converts Apiv1Memo to app Memo correctly', () {
        // Create a sample API memo
        final apiMemo = Apiv1Memo(
          name: 'memos/abc123',
          content: 'Test memo content',
          pinned: true,
          state: V1State.NORMAL,
          visibility: V1Visibility.PUBLIC,
          createTime: DateTime.parse('2025-03-22T21:45:00.000Z'),
          updateTime: DateTime.parse('2025-03-23T01:45:58.000Z'),
          displayTime: DateTime.parse('2025-03-22T21:45:00.000Z'),
          creator: 'users/1',
        );
        
        // Convert to app model
        final appMemo = apiService.convertApiMemoToAppMemoForTest(apiMemo);
        
        // Verify conversion
        expect(appMemo.id, equals('abc123'));
        expect(appMemo.content, equals('Test memo content'));
        expect(appMemo.pinned, isTrue);
        expect(appMemo.state, equals(MemoState.normal));
        expect(appMemo.visibility, equals('PUBLIC'));
        expect(appMemo.createTime, equals('2025-03-22T21:45:00.000Z'));
        expect(appMemo.updateTime, equals('2025-03-23T01:45:58.000Z'));
        expect(appMemo.displayTime, equals('2025-03-22T21:45:00.000Z'));
        expect(appMemo.creator, equals('users/1'));
      });
      
      test('parse API state to app state correctly', () {
        final parseApiState = apiService.parseApiStateForTest;
        
        expect(parseApiState(V1State.NORMAL), equals(MemoState.normal));
        expect(parseApiState(V1State.ARCHIVED), equals(MemoState.archived));
        expect(parseApiState(null), equals(MemoState.normal)); // Default
      });
      
      test('convert app state to API state correctly', () {
        final getApiState = apiService.getApiStateForTest;
        
        expect(getApiState(MemoState.normal), equals(V1State.NORMAL));
        expect(getApiState(MemoState.archived), equals(V1State.ARCHIVED));
      });
      
      test('convert visibility string to API visibility enum correctly', () {
        final getApiVisibility = apiService.getApiVisibilityForTest;
        
        expect(getApiVisibility('PUBLIC'), equals(V1Visibility.PUBLIC));
        expect(getApiVisibility('PRIVATE'), equals(V1Visibility.PRIVATE));
        expect(getApiVisibility('PROTECTED'), equals(V1Visibility.PROTECTED));
        expect(getApiVisibility('unknown'), equals(V1Visibility.PUBLIC)); // Default
      });
    });
    
    group('Comment Parsing Tests', () {
      test('parse comments from API response correctly', () {
        // Create a sample API response with comments
        final response = V1ListMemoCommentsResponse(
          memos: [
            Apiv1Memo(
              name: 'memos/comment1',
              content: 'Comment 1 content',
              creator: 'users/1',
              createTime: DateTime.parse('2025-03-23T01:42:32.000Z'),
            ),
            Apiv1Memo(
              name: 'memos/comment2',
              content: 'Comment 2 content',
              creator: 'users/2',
              createTime: DateTime.parse('2025-03-23T01:45:58.000Z'),
            ),
          ],
        );
        
        // Use the parse method
        final parseComments = apiService.parseCommentsFromApiResponseForTest;
        final comments = parseComments(response);
        
        // Verify parsing
        expect(comments.length, equals(2));
        expect(comments[0].id, equals('comment1'));
        expect(comments[0].content, equals('Comment 1 content'));
        expect(comments[0].creatorId, equals('1'));
        expect(comments[0].createTime, equals(DateTime.parse('2025-03-23T01:42:32.000Z').millisecondsSinceEpoch));
        
        expect(comments[1].id, equals('comment2'));
        expect(comments[1].content, equals('Comment 2 content'));
        expect(comments[1].creatorId, equals('2'));
        expect(comments[1].createTime, equals(DateTime.parse('2025-03-23T01:45:58.000Z').millisecondsSinceEpoch));
      });
    });
  });
}

// Extension to expose private methods for testing
extension TestableApiService on ApiService {
  String formatResourceNameForTest(String id, String resourceType) {
    return _formatResourceName(id, resourceType);
  }
  
  String extractIdFromNameForTest(String name) {
    return _extractIdFromName(name);
  }
  
  Memo convertApiMemoToAppMemoForTest(Apiv1Memo apiMemo) {
    return _convertApiMemoToAppMemo(apiMemo);
  }
  
  MemoState parseApiStateForTest(V1State? state) {
    return _parseApiState(state);
  }
  
  V1State getApiStateForTest(MemoState state) {
    return _getApiState(state);
  }
  
  V1Visibility getApiVisibilityForTest(String visibility) {
    return _getApiVisibility(visibility);
  }
  
  List<Comment> parseCommentsFromApiResponseForTest(V1ListMemoCommentsResponse response) {
    return _parseCommentsFromApiResponse(response);
  }
}
