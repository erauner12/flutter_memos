import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/filter_providers.dart' as filters;
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/services/api_service.dart'
    as api_service; // Import ApiService
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart'; // Add Mockito annotation import
import 'package:mockito/mockito.dart'; // Add Mockito import

// Import the generated mocks file (will be created by build_runner)
import 'memo_providers_test.mocks.dart';

// Annotation to generate nice mock for ApiService
@GenerateNiceMocks([MockSpec<api_service.ApiService>()])
// Mock Notifier extending the actual Notifier
class MockMemosNotifier extends MemosNotifier {
  MockMemosNotifier(super.ref, MemosState initialState)
    : super(skipInitialFetchForTesting: true) {
    if (kDebugMode) {
      print(
        '[MockMemosNotifier] Initializing with ${initialState.memos.length} memos',
      );
    }
    state = initialState;
  }

  @override
  Future<void> refresh() async {
    if (kDebugMode) {
      print('[MockMemosNotifier] Refresh called - no-op for this test');
    }
    /* No-op */
  }

  @override
  Future<void> fetchMoreMemos() async {
    if (kDebugMode) {
      print('[MockMemosNotifier] FetchMoreMemos called - no-op for this test');
    }
    /* No-op */
  }
}

void main() {
  group('Memo Providers Tests (New Notifier)', () {
    late MockApiService mockApiService;
    late ProviderContainer container;

    // Consistent memos for testing
    final memos = [
      Memo(
        id: '1',
        content: 'Test memo 1',
        createTime: '2025-03-22T10:00:00Z',
        updateTime: '2025-03-23T10:00:00Z', // Newest
      ),
      Memo(
        id: '2',
        content: 'Test memo 2',
        createTime: '2025-03-21T10:00:00Z',
        updateTime: '2025-03-22T10:00:00Z', // Middle
      ),
      Memo(
        id: '3',
        content: 'Test memo 3 #tagged', // Tagged memo
        createTime: '2025-03-20T10:00:00Z',
        updateTime: '2025-03-21T10:00:00Z', // Oldest
      ),
    ];

    setUp(() {
      mockApiService = MockApiService();
    
      // Add stub for apiBaseUrl property
      when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');

      // Set up mock response for listMemos (used by notifier internally if not skipped)
      // Stub listMemos
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
      ).thenAnswer((invocation) async {
        // Return the list in PaginatedMemoResponse
        return api_service.PaginatedMemoResponse(
          memos: memos,
          nextPageToken: null,
        );
      });

      // Stub getMemo
      when(mockApiService.getMemo(any)).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        return memos.firstWhere(
          (m) => m.id == id,
          orElse: () => throw Exception('Memo not found: $id'),
        );
      });

      // Stub updateMemo
      when(mockApiService.updateMemo(any, any)).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        final memo = invocation.positionalArguments[1] as Memo;
        return memo.copyWith(id: id);
      });

      // Stub deleteMemo
      when(mockApiService.deleteMemo(any)).thenAnswer((_) async => {});

      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
          // Override the notifier itself
          memosNotifierProvider.overrideWith((ref) {
            final initialState = const MemosState().copyWith(
              memos: memos,
              isLoading: false,
              hasReachedEnd: true, // Assume initial load done
              totalLoaded: memos.length,
            );
            return MockMemosNotifier(ref, initialState);
          }),
          // Override filter providers if needed for specific tests
          filters.filterKeyProvider.overrideWith(
            (ref) => 'inbox',
          ), // Default filter
          // Remove overrides for providers that no longer exist
          // filters.timeFilterProvider.overrideWith((ref) => 'all'),
          // filters.statusFilterProvider.overrideWith((ref) => 'all'),
          hiddenMemoIdsProvider.overrideWith((ref) => {}),
          filters.hidePinnedProvider.overrideWith((ref) => false),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('memosNotifierProvider holds initial state correctly', () {
      final state = container.read(memosNotifierProvider);
      expect(state.memos, equals(memos));
      expect(state.isLoading, isFalse);
      expect(state.hasReachedEnd, isTrue);
    });
 
    test('visibleMemosListProvider filters out hidden memo IDs', () {
      // Hide memo with ID '2'
      container.read(hiddenMemoIdsProvider.notifier).state = {'2'};
 
      // Read the derived provider
      final visibleMemos = container.read(visibleMemosListProvider);

      // Verify results
      expect(visibleMemos.length, equals(2));
      expect(visibleMemos.map((m) => m.id).toList(), equals(['1', '3']));
    });

    testWidgets(
      // Change test to testWidgets
      'visibleMemosListProvider filters out pinned memos when hidePinned is true',
      (WidgetTester tester) async {
        // Add tester and async
        // Make memo '1' pinned
        final pinnedMemos = [
          memos[0].copyWith(pinned: true),
          memos[1],
          memos[2],
        ];
        container.read(memosNotifierProvider.notifier).state = container
            .read(memosNotifierProvider)
            .copyWith(memos: pinnedMemos);

        // Enable hidePinned
        container.read(hidePinnedProvider.notifier).state = true;

        // Add a pump to ensure state propagation before reading derived provider
        await tester.pump();

        // Read the derived provider
        final visibleMemos = container.read(visibleMemosListProvider);

        // Verify results (memo '1' should be hidden)
        expect(visibleMemos.length, equals(2));
        expect(visibleMemos.map((m) => m.id).toList(), equals(['2', '3']));
      },
    );

    test('visibleMemosListProvider filters by state based on filterKey', () {
      // Add an archived memo to the state
      final archivedMemo = Memo(
        id: '4',
        content: 'Archived',
        state: MemoState.archived,
      );
      final memosWithArchived = [...memos, archivedMemo];
      container.read(memosNotifierProvider.notifier).state = container
          .read(memosNotifierProvider)
          .copyWith(memos: memosWithArchived);

      // Test 'inbox' filter (should exclude archived)
      container.read(filters.filterKeyProvider.notifier).state = 'inbox';
      final inboxMemos = container.read(visibleMemosListProvider);
      expect(inboxMemos.length, equals(3));
      expect(inboxMemos.any((m) => m.id == '4'), isFalse);

      // Test 'archive' filter (should only include archived)
      container.read(filters.filterKeyProvider.notifier).state = 'archive';
      final archiveMemos = container.read(visibleMemosListProvider);
      expect(archiveMemos.length, equals(1));
      expect(archiveMemos.first.id, equals('4'));

      // Test 'all' filter (should exclude archived)
      container.read(filters.filterKeyProvider.notifier).state = 'all';
      final allMemos = container.read(visibleMemosListProvider);
      expect(allMemos.length, equals(3));
      expect(allMemos.any((m) => m.id == '4'), isFalse);
    });

    test('filteredMemosProvider applies search query', () {
      // Set a search query
      container.read(filters.searchQueryProvider.notifier).state = 'memo 1';

      // Read the derived provider
      final filtered = container.read(filteredMemosProvider);

      // Verify results
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('1'));
    });

    test(
      'archiveMemoProvider archives a memo correctly (optimistic + API)',
      () async {
        final memoIdToArchive = '1';
    
        // Call the archive provider
        await container.read(archiveMemoProvider(memoIdToArchive))();

        // Verify optimistic update (memo removed from visible list if filter is 'inbox')
        container.read(filters.filterKeyProvider.notifier).state =
            'inbox'; // Ensure filter excludes archived
        final visibleMemos = container.read(visibleMemosListProvider);
        expect(visibleMemos.any((m) => m.id == memoIdToArchive), isFalse);

        // Verify API calls using Mockito verification
        verify(mockApiService.getMemo(memoIdToArchive)).called(1);

        final verificationResult = verify(
          mockApiService.updateMemo(
            argThat(equals(memoIdToArchive)),
            captureAny,
          ),
        );
        verificationResult.called(1);

        final capturedMemo = verificationResult.captured.single as Memo;
        expect(capturedMemo.state, equals(MemoState.archived));
      },
    );

    test(
      'deleteMemoProvider deletes a memo correctly (optimistic + API)',
      () async {
        final memoIdToDelete = '2';

        // Call the delete provider
        await container.read(deleteMemoProvider(memoIdToDelete))();

        // Verify optimistic update (memo removed from list)
        final currentMemos = container.read(memosNotifierProvider).memos;
        expect(currentMemos.any((m) => m.id == memoIdToDelete), isFalse);

        // Verify API call using Mockito verification
        verify(mockApiService.deleteMemo(memoIdToDelete)).called(1);
      },
    );

    test(
      'togglePinMemoProvider toggles pin state (optimistic + API)',
      () async {
        final memoIdToToggle = '3';
    
        // Initial state check
        expect(
          container
              .read(memosNotifierProvider)
              .memos
              .firstWhere((m) => m.id == memoIdToToggle)
              .pinned,
          isFalse,
        );
    
        // Create a stateful mock behavior for getMemo
        final Map<String, Memo> mockMemoDatabase = {};
        mockMemoDatabase[memoIdToToggle] = memos.firstWhere(
          (m) => m.id == memoIdToToggle,
        );

        // Setup getMemo to return from our database
        when(mockApiService.getMemo(memoIdToToggle)).thenAnswer((
          invocation,
        ) async {
          return mockMemoDatabase[memoIdToToggle]!;
        });

        // Setup updateMemo to update our database
        when(
          mockApiService.updateMemo(argThat(equals(memoIdToToggle)), any),
        ).thenAnswer((invocation) async {
          final memo = invocation.positionalArguments[1] as Memo;
          // Update our mock database to reflect the change
          mockMemoDatabase[memoIdToToggle] = memo;
          return memo;
        });
    
        // Call the toggle provider (to pin)
        await container.read(togglePinMemoProvider(memoIdToToggle))();
    
        // Verify optimistic update (pinned and moved to top)
        final memosAfterPin = container.read(memosNotifierProvider).memos;
        expect(memosAfterPin.first.id, equals(memoIdToToggle));
        expect(memosAfterPin.first.pinned, isTrue);
    
        // Verify first API calls using Mockito verification
        verify(mockApiService.getMemo(memoIdToToggle)).called(1);
    
        // Verify the first updateMemo call (pin operation)
        final pinVerification = verify(
          mockApiService.updateMemo(
            argThat(equals(memoIdToToggle)),
            captureAny,
          ),
        );
        pinVerification.called(1);
    
        final capturedPinMemo = pinVerification.captured.single as Memo;
        expect(capturedPinMemo.pinned, isTrue);
    
        // Reset mock verification for clean tracking of the second call
        reset(mockApiService);

        // Setup the mock again after reset
        when(mockApiService.getMemo(memoIdToToggle)).thenAnswer((
          invocation,
        ) async {
          return mockMemoDatabase[memoIdToToggle]!;
        });

        when(
          mockApiService.updateMemo(argThat(equals(memoIdToToggle)), any),
        ).thenAnswer((invocation) async {
          final memo = invocation.positionalArguments[1] as Memo;
          mockMemoDatabase[memoIdToToggle] = memo;
          return memo;
        });
    
        // Call again (to unpin)
        await container.read(togglePinMemoProvider(memoIdToToggle))();
    
        // Verify optimistic update (unpinned and sorted back)
        final memosAfterUnpin = container.read(memosNotifierProvider).memos;
        expect(
          memosAfterUnpin.firstWhere((m) => m.id == memoIdToToggle).pinned,
          isFalse,
        );
        // Check if sorting is correct (memo '1' should be first now)
        expect(memosAfterUnpin.first.id, equals('1'));
    
        // Verify second API calls
        verify(mockApiService.getMemo(memoIdToToggle)).called(1);
        
        final unpinVerification = verify(
          mockApiService.updateMemo(
            argThat(equals(memoIdToToggle)),
            captureAny,
          ),
        );
        unpinVerification.called(
          1,
        ); // Should be called once for this verification
    
        // Check the second call's captured argument
        final capturedUnpinMemo = unpinVerification.captured.single as Memo;
        expect(capturedUnpinMemo.pinned, isFalse);
      },
    );
    
    // Add the new test case here
    test('MemosNotifier.removeMemoOptimistically removes memo from state', () {
      // Arrange
      final notifier = container.read(memosNotifierProvider.notifier) as MockMemosNotifier; // Cast to mock
      final initialMemoCount = notifier.state.memos.length;
      final memoIdToRemove = memos[1].id; // Remove the second memo ('2')

      // Pre-condition check
      expect(notifier.state.memos.any((m) => m.id == memoIdToRemove), isTrue);

      // Act
      notifier.removeMemoOptimistically(memoIdToRemove);

      // Assert
      final finalState = notifier.state; // Read state after action
      expect(finalState.memos.length, equals(initialMemoCount - 1));
      expect(finalState.memos.any((m) => m.id == memoIdToRemove), isFalse);
    });
    
  });
}
