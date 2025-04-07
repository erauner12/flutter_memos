import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/screens/edit_memo/edit_memo_screen.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/services/url_launcher_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate nice mocks for ApiService - this makes undefined methods return null instead of throwing
@GenerateNiceMocks([MockSpec<ApiService>()])

// This import will work after running build_runner
import 'edit_memo_screen_test.mocks.dart';
// Import the mock for UrlLauncherService
// Corrected path to the mock file in the core/services directory
import '../../../core/services/url_launcher_service_test.mocks.dart';


// We'll use the Mockito-generated MockApiService instead of a custom implementation

void main() {
  late MockApiService mockApiService;
  late MockUrlLauncherService
  mockUrlLauncherService; // Add mock for URL launcher
  late Memo testMemo;

  setUp(() {
    // Initialize mock services
    mockApiService = MockApiService();
    mockUrlLauncherService =
        MockUrlLauncherService(); // Initialize URL launcher mock

    // Stub the launch method to return success by default
    when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);
    
    // Add stub for apiBaseUrl property
    when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');
    
    // Create a test memo
    testMemo = Memo(
      id: 'test-edit-memo-id',
      content: 'Test memo content for editing',
      pinned: false,
      createTime: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      updateTime: DateTime.now().toIso8601String(),
    );
    // Stub getMemo
    when(mockApiService.getMemo(argThat(isA<String>()))).thenAnswer((invocation) async {
      final id = invocation.positionalArguments[0] as String;
      if (id == testMemo.id) {
        return testMemo;
      }
      throw Exception('Memo not found: $id');
    });
    
    // Stub updateMemo
    when(mockApiService.updateMemo(argThat(isA<String>()), argThat(isA<Memo>()))).thenAnswer((invocation) async {
      final id = invocation.positionalArguments[0] as String;
      final memo = invocation.positionalArguments[1] as Memo;
      
      // Return updated memo
      return memo.copyWith(
        id: id,
        updateTime: DateTime.now().toIso8601String(),
      );
    });
    
    // Stub listMemos - this is needed to avoid errors during refresh operations
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
      (_) async =>
          PaginatedMemoResponse(memos: [testMemo], nextPageToken: null),
    );
  });

  testWidgets('EditMemoScreen loads and displays memo content', (WidgetTester tester) async {
    // Set up mock response
    when(mockApiService.getMemo('test-memo-id')).thenAnswer((invocation) async {
      return Memo(
        id: 'test-memo-id',
        content: 'Test Memo Content',
        pinned: true,
        state: MemoState.normal,
      );
    });
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
          urlLauncherServiceProvider.overrideWithValue(
            mockUrlLauncherService,
          ), // Add override
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
    // Set up mock responses
    when(mockApiService.getMemo('test-edit-memo-id')).thenAnswer((
      invocation,
    ) async {
      return testMemo;
    });

    when(
      mockApiService.updateMemo(
        argThat(equals('test-edit-memo-id')),
        argThat(isA<Memo>()),
      ),
    ).thenAnswer((invocation) async {
      final memo = invocation.positionalArguments[1] as Memo;
      return memo.copyWith(
        id: 'test-edit-memo-id',
        updateTime: DateTime.now().toIso8601String(),
      );
    });
    
    // Build our app and trigger a frame
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
          urlLauncherServiceProvider.overrideWithValue(
            mockUrlLauncherService,
          ), // Add override
        ],
        child: const MaterialApp(
          home: EditMemoScreen(
            entityId: 'test-edit-memo-id',
            entityType: 'memo',
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

    // Verify the updateMemo was called
    verify(
      mockApiService.updateMemo(argThat(equals('test-edit-memo-id')), any),
    ).called(1);
  });
}