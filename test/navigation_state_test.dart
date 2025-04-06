import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/utils/memo_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the generated mock file
import 'navigation_state_test.mocks.dart';

// Generate mocks for ApiService
@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApiService;
  late ProviderContainer container;
  late List<Memo> initialMemos;

  // Helper to create a list of memos sorted by update time
  List<Memo> createSortedMemos(int count) {
    final memos = List.generate(count, (i) {
      final now = DateTime.now();
      // Ensure update times are distinct and descending for predictable sorting
      final updateTime = now.subtract(Duration(minutes: i)).toIso8601String();
      return Memo(
        id: 'memo_$i',
        content: 'Memo Content $i',
        pinned: false,
        state: MemoState.normal,
        updateTime: updateTime,
        createTime: updateTime, // Keep createTime consistent for simplicity here
      );
    });
    // Ensure sorting matches the app's logic
    MemoUtils.sortByPinnedThenUpdateTime(memos);
    return memos;
  }

  // Use setUpAll for mocks that don't change per test
  setUpAll(() {
    mockApiService = MockApiService();

    // --- MOCK SETUP ---
    // Stub API calls needed by the action providers (delete, get, update)
    // Stub listMemos only for potential refresh calls within action providers
    when(mockApiService.listMemos(
      parent: anyNamed('parent'),
      filter: anyNamed('filter'),
      state: anyNamed('state'),
      sort: anyNamed('sort'),
      direction: anyNamed('direction'),
      pageSize: anyNamed('pageSize'),
        pageToken: null, // Specifically for refresh (first page)
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
    ).thenAnswer((_) async {
      // Return empty for refresh calls to isolate optimistic update tests
      return PaginatedMemoResponse(memos: [], nextPageToken: null);
    });

    when(mockApiService.deleteMemo(any)).thenAnswer((_) async {
      return; // Return null for void
    });
    when(mockApiService.getMemo(any)).thenAnswer((invocation) async {
      final id = invocation.positionalArguments[0] as String;
      // Use a *local copy* of initialMemos for lookup if needed, but prefer direct return
      // Recreate the list here to ensure it's available for lookup in the mock
      final memos = createSortedMemos(5);
      return memos.firstWhere(
        (memo) => memo.id == id,
        orElse: () => throw Exception('Memo not found for ID: $id'),
      );
    });
    when(mockApiService.updateMemo(any, any)).thenAnswer((invocation) async {
      final updatedMemo = invocation.positionalArguments[1] as Memo;
      return updatedMemo; // Return the updated memo
    });
    // --- END MOCK SETUP ---
  });

  // Use setUp for container creation and state setting per test
  setUp(() {
    initialMemos = createSortedMemos(5); // Ensure fresh list for each test

    // Create a ProviderContainer with overrides
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
        // Override the selectedMemoIdProvider to ensure it's in the same scope
        ui_providers.selectedMemoIdProvider.overrideWith((_) => null),

        // Override MemosNotifier: Create it, but we will set its state manually
        memosNotifierProvider.overrideWith(
          (ref) {
            // Create the notifier with flag to skip automatic refresh/initialization
            final notifier = MemosNotifier(ref, skipInitialFetchForTesting: true);
            // Set the state *after* creation
            // Use copyWith on the default state to ensure all flags are set correctly
            notifier.state = const MemosState().copyWith(
              memos: initialMemos,
              isLoading: false, // Mark as not loading
              hasReachedEnd: true, // Assume initial load is done
              totalLoaded: initialMemos.length,
            );
            return notifier;
          },
        ),
      ],
    );

    // Reset selection before each test
    // container.read(ui_providers.selectedMemoIndexProvider.notifier).state = 0;
    container.read(ui_providers.selectedMemoIdProvider.notifier).state = null;

    // Verify initial state immediately after setup
    final initialState = container.read(memosNotifierProvider);
    expect(
      initialState.memos.length,
      initialMemos.length,
      reason: "Notifier state not initialized correctly in setUp",
    );
    expect(
      initialState.isLoading,
      isFalse,
      reason: "Notifier should not be loading after setUp",
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('MemosNotifier Optimistic Updates & Selection', () {
    test('removeMemoOptimistically removes memo from internal list', () async {
      // Arrange
      final memoToRemoveId = initialMemos[2].id; // 'memo_2'
      final initialMemoCount = container.read(memosNotifierProvider).memos.length;

      // Act: Call the notifier method directly
      container.read(memosNotifierProvider.notifier)
          .removeMemoOptimistically(memoToRemoveId);

      // Assert: Memo is removed from the notifier's state
      final updatedMemos = container.read(memosNotifierProvider).memos;
      expect(updatedMemos.length, initialMemoCount - 1);
      expect(
        updatedMemos.any((m) => m.id == memoToRemoveId),
        isFalse,
        reason: "Memo should be removed from the notifier's memo list",
      );
    });

    test('togglePinOptimistically updates pin state and re-sorts', () {
      // Arrange
      final memoToPinId = initialMemos[3].id; // 'memo_3'

      // Act: Toggle pin state
      container.read(memosNotifierProvider.notifier)
          .togglePinOptimistically(memoToPinId);

      // Assert: Check that the memo is pinned and moved to the top
      final memos = container.read(memosNotifierProvider).memos;
      expect(memos.first.id, memoToPinId);
      expect(memos.first.pinned, isTrue);
      expect(memos.length, initialMemos.length); // Count remains same

      // Act: Unpin the memo
      container.read(memosNotifierProvider.notifier)
          .togglePinOptimistically(memoToPinId);

      // Assert: Verify the memo is unpinned and the list is re-sorted by time again
      final memosAfterUnpin = container.read(memosNotifierProvider).memos;
      expect(memosAfterUnpin.any((m) => m.id == memoToPinId && m.pinned), isFalse);
      // Verify original time-based order is restored (or close to it)
      expect(memosAfterUnpin[0].id, initialMemos[0].id);
    });

    test('bumpMemoOptimistically updates time and re-sorts', () {
      // Arrange
      final memoToBumpId = initialMemos[4].id; // 'memo_4', the oldest

      // Act: Bump the memo's update time optimistically
      container.read(memosNotifierProvider.notifier)
          .bumpMemoOptimistically(memoToBumpId);

      // Assert: Verify the memo is at the top (most recent updateTime)
      final memos = container.read(memosNotifierProvider).memos;
      expect(memos.first.id, memoToBumpId);
      expect(memos.length, initialMemos.length);
    });

    test('archiveMemoOptimistically updates state', () {
      // Arrange
      final memoToArchiveId = initialMemos[1].id; // 'memo_1'

      // Act: Archive the memo optimistically
      container.read(memosNotifierProvider.notifier)
          .archiveMemoOptimistically(memoToArchiveId);

      // Assert: Check that the memo state is updated to archived
      final memos = container.read(memosNotifierProvider).memos;
      final archivedMemo = memos.firstWhere((m) => m.id == memoToArchiveId);
      expect(archivedMemo.state, MemoState.archived);
      expect(memos.length, initialMemos.length);
    });
  });

  group('Memo Action Providers with Optimistic Updates', () {
    test('deleteMemoProvider calls optimistic update then API', () async {
      // Arrange
      final memoId = initialMemos[1].id; // Choose a memo to delete
      // Mock API success (already done in setUpAll)
  
      // Act: Execute the delete provider, passing necessary family args
      await container.read(deleteMemoProvider(memoId))();
  
      // Assert: Memo removed from state
      expect(
        container.read(memosNotifierProvider).memos.any((m) => m.id == memoId),
        isFalse,
        reason: "Memo should be removed from the final state",
      );
  
      // Assert: API was called
      verify(mockApiService.deleteMemo(memoId)).called(1);
  
      // Assert: Refresh was NOT called (delete provider doesn't refresh on success)
      verifyNever(mockApiService.listMemos(pageToken: null));
    });
  
    test('deleteMemoProvider adjusts selection correctly', () async {
      // --- Test deleting the selected item ---
      // Arrange: Set initial selection at index 2 using the main container
      final initialIndexSelected = 2;
      final memoToDeleteSelectedId = initialMemos[initialIndexSelected].id; // memo_2
  
      // Set up ID selection
      container.read(ui_providers.selectedMemoIdProvider.notifier).state =
          memoToDeleteSelectedId;
  
      // Verify initial selection
      expect(
        container.read(ui_providers.selectedMemoIdProvider),
        memoToDeleteSelectedId,
      );
  
      // Act: Execute the delete provider for the selected memo
      await container.read(deleteMemoProvider(memoToDeleteSelectedId))();
  
      // Assert: Selection ID is updated to the previous memo (memo_1)
      final expectedNextIdAfterDeleteSelected =
          initialMemos[initialIndexSelected - 1].id; // memo_1
      expect(
        container.read(ui_providers.selectedMemoIdProvider),
        expectedNextIdAfterDeleteSelected,
        reason: "Selected memo ID should be updated to the previous memo after deleting selected memo",
      );
  
      // --- Test deleting item *before* selection ---
      // Arrange: Reset state and set selection at index 2
      container.read(memosNotifierProvider.notifier).state = const MemosState()
          .copyWith(
            memos: createSortedMemos(5),
            isLoading: false,
            hasReachedEnd: true,
          ); // Reset memos
      final initialIndexBefore = 2;
      final memoSelectedId = initialMemos[initialIndexBefore].id; // memo_2
      final indexToDeleteBefore = 0;
      final memoToDeleteBeforeId = initialMemos[indexToDeleteBefore].id; // memo_0
  
      // Set up ID selection
      container.read(ui_providers.selectedMemoIdProvider.notifier).state =
          memoSelectedId;
  
      // Verify initial selection
      expect(
        container.read(ui_providers.selectedMemoIdProvider),
        memoSelectedId,
      );
  
      // Act: Execute the delete provider for the memo *before* selection
      await container.read(deleteMemoProvider(memoToDeleteBeforeId))();
  
      // Assert: Selection ID remains unchanged since we deleted a different memo before it
      expect(
        container.read(ui_providers.selectedMemoIdProvider),
        memoSelectedId,
        reason: "Selected memo ID should remain unchanged when deleting a different memo before it",
      );
  
      // --- Test deleting item *after* selection ---
      // Arrange: Reset state and set selection at index 0
      container.read(memosNotifierProvider.notifier).state = const MemosState()
          .copyWith(
            memos: createSortedMemos(5),
            isLoading: false,
            hasReachedEnd: true,
          ); // Reset memos
      final initialIndexAfter = 0;
      final memoSelectedAfterIdPrefix = initialMemos[initialIndexAfter].id; // memo_0
      final indexToDeleteAfter = 3;
      final memoToDeleteAfterId = initialMemos[indexToDeleteAfter].id; // memo_3
  
      // Set up ID selection
      container.read(ui_providers.selectedMemoIdProvider.notifier).state =
          memoSelectedAfterIdPrefix;
  
      // Verify initial selection
      expect(
        container.read(ui_providers.selectedMemoIdProvider),
        memoSelectedAfterIdPrefix,
      );
  
      // Act: Execute the delete provider for the memo *after* selection
      await container.read(deleteMemoProvider(memoToDeleteAfterId))();
  
      // Assert: Selection ID remains unchanged when deleting item after it
      expect(
        container.read(ui_providers.selectedMemoIdProvider),
        memoSelectedAfterIdPrefix,
        reason: "Selected memo ID should remain unchanged when deleting a memo after it",
      );
    });
  
    test('togglePinMemoProvider calls optimistic update then API', () async {
      // Arrange
      final memoId = initialMemos[2].id;
      final originalMemo = initialMemos.firstWhere((m) => m.id == memoId);
      // Mock API calls (already done in setUpAll)
  
      // Act: Toggle memo pin state via the provider
      await container.read(togglePinMemoProvider(memoId))();
  
      // Assert: Verify memo pin state toggled optimistically
      final memos = container.read(memosNotifierProvider).memos;
      final toggledMemo = memos.firstWhere((m) => m.id == memoId);
      expect(toggledMemo.pinned, !originalMemo.pinned);
  
      // Assert: API calls were made
      verify(mockApiService.getMemo(memoId)).called(1);
      verify(mockApiService.updateMemo(memoId, any)).called(1);
  
      // Assert: Refresh was NOT called (togglePin provider doesn't refresh on success)
      verifyNever(mockApiService.listMemos(pageToken: null));
    });
  
    test('archiveMemoProvider calls optimistic update then API, then refreshes and updates selection', () async {
      // Arrange
      final initialIndexSelected = 1;
      final memoId = initialMemos[initialIndexSelected].id; // memo_1
      container.read(ui_providers.selectedMemoIdProvider.notifier).state = memoId; // Select this memo
      // Mocks for get/update/listMemos(refresh) already in setUpAll
  
      // Act: Execute archive provider
      await container.read(archiveMemoProvider(memoId))();
  
      // Assert: Verify memo state update via API calls
      verify(mockApiService.getMemo(memoId)).called(1);
      final verificationResult = verify(mockApiService.updateMemo(memoId, captureAny));
      verificationResult.called(1);
      final capturedMemo = verificationResult.captured.single as Memo;
      expect(capturedMemo.state, MemoState.archived);
      expect(capturedMemo.pinned, isFalse);
  
        // Assert: Refresh was NOT triggered on success
        verifyNever(
          mockApiService.listMemos(
        parent: anyNamed('parent'),
        filter: anyNamed('filter'),
        state: anyNamed('state'),
        sort: anyNamed('sort'),
        direction: anyNamed('direction'),
        pageSize: anyNamed('pageSize'),
        pageToken: null, // The pageToken should be null for refresh
          ),
        ); // No longer called on success
  
        // Assert: Selection was updated to the previous memo (memo_0)
      final expectedNextIdAfterArchive = initialMemos[initialIndexSelected - 1].id; // memo_0
      expect(
        container.read(ui_providers.selectedMemoIdProvider),
        expectedNextIdAfterArchive,
        reason: "Selection should move to the previous memo after archiving the selected one",
      );
    });
  });

  test('selectedMemoIdProvider starts as null', () {
    final selectedId = container.read(ui_providers.selectedMemoIdProvider);
    expect(selectedId, isNull);
  });

  test('selectedMemoIdProvider can be updated', () {
    // Start at null
    final initialId = container.read(ui_providers.selectedMemoIdProvider);
    expect(initialId, isNull);

    // Set to a memo ID
    const testMemoId = 'test-memo-123';
    container.read(ui_providers.selectedMemoIdProvider.notifier).state =
        testMemoId;
    final updatedId = container.read(ui_providers.selectedMemoIdProvider);
    expect(updatedId, equals(testMemoId));
  });

  test('selectedCommentIndexProvider starts at -1', () {
    final index = container.read(ui_providers.selectedCommentIndexProvider);
    expect(index, equals(-1));
  });
}
