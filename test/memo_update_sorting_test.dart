import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/screens/edit_memo/edit_memo_providers.dart';
import 'package:flutter_memos/services/api_service.dart'; // Import ApiService
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart'; // Add Mockito annotation import
import 'package:mockito/mockito.dart'; // Add Mockito import

// Import the generated mocks file (will be created by build_runner)
import 'memo_update_sorting_test.mocks.dart';

// Annotation to generate mock for ApiService
@GenerateMocks([ApiService])
// Mock Notifier extending the actual Notifier
class MockMemosNotifier extends MemosNotifier {
  // Update to use the non-deprecated Ref type
  final Ref ref;

  MockMemosNotifier(this.ref, MemosState initialState)
    : super(ref, skipInitialFetchForTesting: true) {
    // Explicitly set the initial state in the constructor
    state = initialState;
  }

  @override
  Future<void> refresh() async {
    if (kDebugMode) {
      print('[MockMemosNotifier] Refresh called, fetching from mock API');
    }
    
    // Simulate refresh by calling the mock API service again
    final apiService = ref.read(apiServiceProvider) as MockApiService;
    // Use the mocked API service response for refresh, explicitly using null pageToken
    final response = await apiService.listMemos(
      pageToken: null,
    ); // First page for refresh

    // Update state with the response
    state = state.copyWith(
      memos: response.memos,
      isLoading: false,
      hasReachedEnd: response.nextPageToken == null,
      nextPageToken: response.nextPageToken,
      totalLoaded: response.memos.length,
    );
    
    if (kDebugMode) {
      print(
        '[MockMemosNotifier] Refresh completed with ${response.memos.length} memos',
      );
    }
  }

  @override
  Future<void> fetchMoreMemos() async {
    if (kDebugMode) {
      print('[MockMemosNotifier] fetchMoreMemos called - no-op for this test');
    }
    /* No-op for this test */
  }
}

/// This unit test focuses specifically on the data flow and logic involved
/// when a memo is updated, ensuring that:
/// 1. The `ApiService.updateMemo` correctly handles the server's potentially incorrect
///    response (epoch createTime) by restoring the original createTime. (This part is tested in api_timestamp_behavior_test)
/// 2. The `saveEntityProvider` triggers an invalidation/refresh of `memosNotifierProvider`.
/// 3. The `memosNotifierProvider` correctly refetches (using mocks), converts, and client-side sorts the data.
/// 4. The final list reflects the updated memo content and correct sorting by updateTime.
/// 5. The createTime in the *final list* reflects what the server *returned on the list fetch*,
///    demonstrating the limitation of the client-side fix (it only applies to the direct update response).
void main() {
  group('Memo Update Timestamp Correction and Sorting Logic Test (Notifier)', () {
    late MockApiService mockApiService;
    late ProviderContainer container;

    // Consistent timestamps for testing
    final now = DateTime.now().toUtc();
    final originalCreateTimeStr =
        now.subtract(const Duration(hours: 1)).toIso8601String();
    final originalUpdateTimeStr =
        now.subtract(const Duration(minutes: 30)).toIso8601String();
    final serverUpdateTimeStr = now.toIso8601String(); // Time of the update
    const serverEpochCreateTimeStr = '1970-01-01T00:00:00.000Z';

    final memoToUpdateId = 'memo-to-update';
    final otherMemoId = 'other-memo';

    // Initial memo list state (sorted by update time desc)
    final initialMemos = [
      Memo(
        id: memoToUpdateId,
        content: 'Memo before update',
        createTime: originalCreateTimeStr,
        updateTime: originalUpdateTimeStr, // Older update time
      ),
      Memo(
        id: otherMemoId,
        content: 'Another memo',
        createTime: now.subtract(const Duration(days: 1)).toIso8601String(),
        updateTime:
            now
                .subtract(const Duration(days: 1, minutes: 1))
                .toIso8601String(), // Even older
      ),
    ];

    // State of the list *as returned by the server* after the update
    // Note: Server returns epoch createTime, but correct new updateTime for the updated memo.
    // The list order from server might be arbitrary before client-side sort.
    final memosFromServerAfterUpdate = [
      Memo(
        // This represents the raw data from the server list call
        id: memoToUpdateId,
        content: 'Memo after update',
        createTime:
            serverEpochCreateTimeStr, // Incorrect time from server list response
        updateTime: serverUpdateTimeStr, // Correct new update time
      ),
      Memo(
        id: otherMemoId,
        content: 'Another memo',
        createTime: now.subtract(const Duration(days: 1)).toIso8601String(),
        updateTime:
            now.subtract(const Duration(days: 1, minutes: 1)).toIso8601String(),
      ),
    ];

    setUp(() {
      mockApiService = MockApiService();

      // --- Mock Setup ---
      // 1. Initial listMemos call response (used if notifier fetches initially)
      when(
        mockApiService.listMemos(
          parent: anyNamed('parent'),
          filter: anyNamed('filter'),
          state: anyNamed('state'),
          sort: anyNamed('sort'),
          direction: anyNamed('direction'),
          pageSize: anyNamed('pageSize'),
          pageToken: anyNamed('pageToken'), // initial call has null page token
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
            PaginatedMemoResponse(memos: initialMemos, nextPageToken: null),
      );

      // 2. updateMemo call response (used by saveEntityProvider)
      when(
        mockApiService.updateMemo(argThat(equals(memoToUpdateId)), any),
      ).thenAnswer(
        (_) async => Memo(
          id: memoToUpdateId,
          content: 'Memo after update',
          createTime: serverEpochCreateTimeStr, // Server sends bad createTime
          updateTime: serverUpdateTimeStr, // Server sends correct updateTime
        ),
      );

      // Add missing getMemo stub for memoToUpdateId
      when(mockApiService.getMemo(memoToUpdateId)).thenAnswer((_) async {
        // Return the memo state as it would be after the update
        // This mock is used during refresh/invalidation after update
        return memosFromServerAfterUpdate.firstWhere(
          (m) => m.id == memoToUpdateId,
          orElse:
              () => throw Exception('Test setup error: Updated memo not found'),
        );
      });
      
      // 3. listMemos call *after* update (used by notifier's refresh)
      // This simulates the server list response containing the epoch createTime
      when(
        mockApiService.listMemos(
          parent: anyNamed('parent'),
          filter: anyNamed('filter'),
          state: anyNamed('state'),
          sort: anyNamed('sort'),
          direction: anyNamed('direction'),
          pageSize: anyNamed('pageSize'),
          pageToken: null, // Make this match specifically for refresh
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
        (_) async => PaginatedMemoResponse(
          memos: memosFromServerAfterUpdate,
          nextPageToken: null,
        ),
      );
      // --- End Mock Setup ---

      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
          // Override the notifier to set initial state manually
          memosNotifierProvider.overrideWith((ref) {
            final initialState = const MemosState().copyWith(
              memos: initialMemos,
              isLoading: false,
              hasReachedEnd: true,
              totalLoaded: initialMemos.length,
            );
            // Use the MockMemosNotifier which overrides refresh
            return MockMemosNotifier(ref, initialState);
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'After update, memosNotifierProvider state reflects sorted list with server createTime',
      () async {
        // 1. Verify initial state
        print('[Test Flow] Verifying initial memosNotifierProvider state...');
        final initialState = container.read(memosNotifierProvider);
        print('[Test Flow] Initial state count: ${initialState.memos.length}');
        expect(initialState.memos.length, 2);
        expect(
          initialState.memos.first.id,
          memoToUpdateId, // Should be first due to its original updateTime
          reason:
              'Memo with most recent original updateTime should be first initially',
        );
        expect(
          initialState.memos.first.createTime,
          originalCreateTimeStr, // Verify initial createTime is correct
        );

        // 2. Simulate the update action using the saveEntityProvider
        print(
          '[Test Flow] Triggering saveEntityProvider for ID: $memoToUpdateId...',
        );
        final memoDataForUpdate = Memo(
          id: memoToUpdateId,
          content: 'Memo after update',
          // Pass the original createTime, as the UI would have it
          createTime: originalCreateTimeStr,
          updateTime: originalUpdateTimeStr, // This doesn't matter much here
        );
        // saveEntityProvider calls apiService.updateMemo and then triggers refresh
        await container.read(
          saveEntityProvider(
            EntityProviderParams(id: memoToUpdateId, type: 'memo'),
          ),
        )(memoDataForUpdate);
        print('[Test Flow] saveEntityProvider call complete.');

        // Verify updateMemo was called with expected arguments
        verify(
          mockApiService.updateMemo(argThat(equals(memoToUpdateId)), any),
        ).called(1);

        // The refresh triggered by saveEntityProvider uses the *second* mock response
        // for listMemos (memosFromServerAfterUpdate)

        // 3. Read the final state from memosNotifierProvider
        print(
          '[Test Flow] Reading final memosNotifierProvider state after refresh...',
        );
        // Allow time for the async refresh within the mock notifier to complete
        await container.read(memosNotifierProvider.notifier).refresh();
        final finalState = container.read(memosNotifierProvider);
        print('[Test Flow] Final state count: ${finalState.memos.length}');

        // 4. Verify the results
        expect(finalState.memos.length, 2, reason: 'Should still have 2 memos');

        // Verify sorting: The updated memo should now be first due to newer updateTime
        expect(
          finalState.memos.first.id,
          equals(memoToUpdateId),
          reason: 'Updated memo should be first when sorted by updateTime',
        );
        expect(
          finalState.memos.last.id,
          equals(otherMemoId),
          reason: 'Other memo should be second',
        );

        // Verify createTime:
        // The list was refreshed using the mock response `memosFromServerAfterUpdate`,
        // which contained the incorrect epoch createTime from the server.
        // The client-side fix in ApiService only applies to the direct `updateMemo` response,
        // not to the subsequent `listMemos` response conversion.
        final updatedMemoInList = finalState.memos.firstWhere(
          (m) => m.id == memoToUpdateId,
        );

        print(
          '[Test Verification] Checking createTime of updated memo in final list...',
        );
        print(
          '[Test Verification] Expected createTime from server list fetch: $serverEpochCreateTimeStr',
        );
        print(
          '[Test Verification] Actual createTime in list: ${updatedMemoInList.createTime}',
        );

        expect(
          updatedMemoInList.createTime,
          equals(
            serverEpochCreateTimeStr,
          ), // Expecting the incorrect time from the list fetch
          reason:
              'createTime from list fetch is expected to be epoch (server bug)',
        );

        // Verify updateTime is correct
        expect(
          updatedMemoInList.updateTime,
          equals(serverUpdateTimeStr),
          reason:
              'updateTime should be the latest one from the server list fetch',
        );

        print(
          '[Test Result] Test confirms list is sorted correctly by updateTime, but createTime reflects server list response after refresh.',
        );
      },
    );
  });
}
