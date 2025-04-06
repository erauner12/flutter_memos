import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/screens/edit_memo/edit_memo_screen.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Mock for ApiService
class MockApiService extends Mock implements ApiService {
  @override
  Future<Memo> getMemo(String id) async {
    return Memo(
      id: id,
      content: 'Test Memo Content',
      pinned: true,
      state: MemoState.normal,
    );
  }
  
  @override
  Future<Memo> updateMemo(String id, Memo memo) async {
    // Simulate the server returning epoch createTime but correct updateTime
    return memo.copyWith(
      id: id,
      createTime: '1970-01-01T00:00:00.000Z', // Simulate server bug
      updateTime:
          DateTime.now().toIso8601String(), // Simulate correct update time
    );
  }

  // Add stub for listMemos to handle refresh calls
  @override
  Future<PaginatedMemoResponse> listMemos({
    String parent = 'users/1',
    String? filter,
    String? state,
    String sort = 'updateTime',
    String direction = 'DESC',
    int? pageSize,
    String? pageToken,
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
    // Return an empty list for refresh calls in this test context
    print(
      '[MockApiService - EditMemoScreenTest] listMemos called (returning empty)',
    );
    return PaginatedMemoResponse(memos: [], nextPageToken: null);
  }
}

void main() {
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
  });

  // Function removed as it was unused

  testWidgets('EditMemoScreen loads memo data correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
        ],
        child: const MaterialApp(
          home: EditMemoScreen(
            entityId: 'test-memo-id', entityType: 'memo',
          ),
        ),
      ),
    );

    // Initially we should see a loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the future to complete
    await tester.pumpAndSettle();

    // Now we should see the form with the memo content
    expect(find.text('Test Memo Content'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(2)); // Pinned and Archived switches
  });

  testWidgets('EditMemoScreen handles save properly', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
        ],
        child: const MaterialApp(
          home: EditMemoScreen(
            entityId: 'test-memo-id', entityType: 'memo',
          ),
        ),
      ),
    );

    // Wait for data to load
    await tester.pumpAndSettle();

    // Edit the content
    await tester.enterText(find.byType(TextField), 'Updated Content');
    
    // Tap the save button
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Add verification that navigation occurred if needed
    // expect(find.byType(EditMemoScreen), findsNothing); // Or check for the previous screen
  });
}
