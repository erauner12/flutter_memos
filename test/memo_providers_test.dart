import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/filter_providers.dart' as filters;
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/services/api_service.dart'; // Import ApiService
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mock_api_service.dart'; // Use the manual mock

// Mock Notifier extending the actual Notifier
class MockMemosNotifier extends MemosNotifier {
  MockMemosNotifier(super.ref, MemosState initialState)
    : super(skipInitialFetchForTesting: true) {
    state = initialState;
  }

  @override
  Future<void> refresh() async {
    /* No-op */
  }

  @override
  Future<void> fetchMoreMemos() async {
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

      // Set up mock response for listMemos (used by notifier internally if not skipped)
      // Wrap the list in PaginatedMemoResponse
      mockApiService.setMockListMemosResponse(
        PaginatedMemoResponse(memos: memos, nextPageToken: null),
      );
      // Set up mock responses for action providers
      mockApiService.setMockMemoById('1', memos[0]);
      mockApiService.setMockMemoById('2', memos[1]);
      mockApiService.setMockMemoById('3', memos[2]);

      // Create container with overrides
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
          filters.timeFilterProvider.overrideWith((ref) => 'all'),
          filters.statusFilterProvider.overrideWith((ref) => 'all'),
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
        mockApiService.resetCallCounts(); // Reset counts before action

        // Call the archive provider
        await container.read(archiveMemoProvider(memoIdToArchive))();
 
        // Verify optimistic update (memo removed from visible list if filter is 'inbox')
        container.read(filters.filterKeyProvider.notifier).state =
            'inbox'; // Ensure filter excludes archived
        final visibleMemos = container.read(visibleMemosListProvider);
        expect(visibleMemos.any((m) => m.id == memoIdToArchive), isFalse);

        // Verify API calls
        expect(mockApiService.getMemoCallCount, equals(1));
        expect(mockApiService.updateMemoCallCount, equals(1));
        expect(mockApiService.lastUpdateMemoId, equals(memoIdToArchive));
        expect(
          mockApiService.lastUpdateMemoPayload?.state,
          equals(MemoState.archived),
        );
      },
    );

    test(
      'deleteMemoProvider deletes a memo correctly (optimistic + API)',
      () async {
        final memoIdToDelete = '2';
        mockApiService.resetCallCounts();

        // Call the delete provider
        await container.read(deleteMemoProvider(memoIdToDelete))();

        // Verify optimistic update (memo removed from list)
        final currentMemos = container.read(memosNotifierProvider).memos;
        expect(currentMemos.any((m) => m.id == memoIdToDelete), isFalse);

        // Verify API call
        expect(mockApiService.deleteMemoCallCount, equals(1));
    });

    test(
      'togglePinMemoProvider toggles pin state (optimistic + API)',
      () async {
        final memoIdToToggle = '3';
        mockApiService.resetCallCounts();

        // Initial state check
        expect(
          container
              .read(memosNotifierProvider)
              .memos
              .firstWhere((m) => m.id == memoIdToToggle)
              .pinned,
          isFalse,
        );

        // Call the toggle provider (to pin)
        await container.read(togglePinMemoProvider(memoIdToToggle))();

        // Verify optimistic update (pinned and moved to top)
        final memosAfterPin = container.read(memosNotifierProvider).memos;
        expect(memosAfterPin.first.id, equals(memoIdToToggle));
        expect(memosAfterPin.first.pinned, isTrue);

        // Verify API calls
        expect(mockApiService.getMemoCallCount, equals(1));
        expect(mockApiService.updateMemoCallCount, equals(1));
        expect(mockApiService.lastUpdateMemoPayload?.pinned, isTrue);

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

        // Verify API calls (total counts)
        expect(mockApiService.getMemoCallCount, equals(2));
        expect(mockApiService.updateMemoCallCount, equals(2));
        expect(mockApiService.lastUpdateMemoPayload?.pinned, isFalse);
      },
    );

  });
}
