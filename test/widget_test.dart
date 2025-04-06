// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mock for ApiService
@GenerateMocks([ApiService])
import 'widget_test.mocks.dart';

void main() {
  late MockApiService mockApiService;
  late List<Memo> testMemos;

  setUp(() {
    // Initialize the mock API service
    mockApiService = MockApiService();
    
    // Add stub for apiBaseUrl property
    when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');

    // Create test memos
    testMemos = [
      Memo(
        id: 'memo-1',
        content: 'First test memo',
        createTime:
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        updateTime: DateTime.now().toIso8601String(),
      ),
      Memo(
        id: 'memo-2',
        content: 'Second test memo',
        createTime:
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        updateTime:
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      ),
    ];

    // Stub listMemos for initial app load
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
      (_) async => PaginatedMemoResponse(memos: testMemos, nextPageToken: null),
    );
  });

  testWidgets('App loads and displays title', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(mockApiService)],
        child: const MyApp(),
      ),
    );

    // Verify that our app initializes correctly
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.text('Flutter Memos'), findsOneWidget);
    
    // Wait for all animations to complete
    await tester.pumpAndSettle();
    
    // Verify some basic elements of our UI exist
    expect(find.byType(AppBar), findsWidgets);
  });
}
