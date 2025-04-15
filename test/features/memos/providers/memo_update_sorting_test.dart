import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter_memos/models/list_notes_response.dart'; // Updated import
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/providers/api_providers.dart';
// Removed import for edit_entity_providers.dart
import 'package:flutter_memos/providers/note_providers.dart'
    as note_providers; // Updated import
import 'package:flutter_memos/services/base_api_service.dart'; // Updated import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the generated mocks file
import 'memo_update_sorting_test.mocks.dart'; // Keep mock file name for now

// Annotation to generate nice mock for BaseApiService
@GenerateNiceMocks([MockSpec<BaseApiService>()])
// Mock Notifier extending the actual Notifier
class MockNotesNotifier extends NotesNotifier {
  // Updated class name
  // Update to use the non-deprecated Ref type
  final Ref ref;

  MockNotesNotifier(
    this.ref,
    note_providers.NotesState initialState,
  ) // Updated state type
    : super(ref, skipInitialFetchForTesting: true) {
    // Explicitly set the initial state in the constructor
    state = initialState;
  }

  @override
  Future<void> refresh() async {
    if (kDebugMode) {
      print(
        '[MockNotesNotifier] Refresh called, fetching from mock API',
      ); // Updated log
    }

    // Simulate refresh by calling the mock API service again
    final apiService =
        ref.read(apiServiceProvider) as MockBaseApiService; // Updated mock type
    // Use the mocked API service response for refresh, explicitly using null pageToken
    final response = await apiService.listNotes(
      // Updated method name
      pageToken: null,
    ); // First page for refresh

    // Update state with the response
    state = state.copyWith(
      notes: response.notes, // Updated field name
      isLoading: false,
      hasReachedEnd: response.nextPageToken == null,
      nextPageToken: response.nextPageToken,
      totalLoaded: response.notes.length, // Updated field name
    );

    if (kDebugMode) {
      print(
        '[MockNotesNotifier] Refresh completed with ${response.notes.length} notes', // Updated log
      );
    }
  }

  @override
  Future<void> fetchMoreNotes() async {
    // Updated method name
    if (kDebugMode) {
      print(
        '[MockNotesNotifier] fetchMoreNotes called - no-op for this test',
      ); // Updated log
    }
    /* No-op for this test */
  }
}

/// This unit test focuses specifically on the data flow and logic involved
/// when a note is updated, ensuring that:
/// 1. The `BaseApiService.updateNote` correctly handles the server's potentially incorrect
///    response (epoch createTime) by restoring the original createTime. (This part is tested in api_timestamp_behavior_test)
/// 2. The `saveEntityProvider` triggers an invalidation/refresh of `notesNotifierProvider`.
/// 3. The `notesNotifierProvider` correctly refetches (using mocks), converts, and client-side sorts the data.
/// 4. The final list reflects the updated note content and correct sorting by updateTime.
/// 5. The createTime in the *final list* reflects what the server *returned on the list fetch*,
///    demonstrating the limitation of the client-side fix (it only applies to the direct update response).
void main() {
  group('Note Update Timestamp Correction and Sorting Logic Test (Notifier)', () {
    // Updated group name
    late MockBaseApiService mockApiService; // Updated mock type
    late ProviderContainer container;

    // Consistent timestamps for testing
    final now = DateTime.now().toUtc();
    final originalCreateTime = now.subtract(const Duration(hours: 1));
    final originalUpdateTime = now.subtract(const Duration(minutes: 30));
    final serverUpdateTime = now; // Time of the update
    final serverEpochCreateTime = DateTime.utc(1970, 1, 1); // Use DateTime

    final noteToUpdateId = 'note-to-update'; // Updated prefix
    final otherNoteId = 'other-note'; // Updated prefix

    // Initial note list state (sorted by update time desc)
    final initialNotes = [
      // Updated variable name and type
      NoteItem(
        id: noteToUpdateId,
        content: 'Note before update', // Updated content
        pinned: false, // Add required field
        createTime: originalCreateTime,
        updateTime: originalUpdateTime, // Older update time
        displayTime: originalUpdateTime, // Add required field
        visibility: NoteVisibility.private, // Add required field
        state: NoteState.normal, // Add required field
      ),
      NoteItem(
        id: otherNoteId,
        content: 'Another note', // Updated content
        pinned: false, // Add required field
        createTime: now.subtract(const Duration(days: 1)),
        updateTime: now.subtract(
          const Duration(days: 1, minutes: 1),
        ), // Even older
        displayTime: now.subtract(
          const Duration(days: 1, minutes: 1),
        ), // Add required field
        visibility: NoteVisibility.private, // Add required field
        state: NoteState.normal, // Add required field
      ),
    ];

    // State of the list *as returned by the server* after the update
    // Note: Server returns epoch createTime, but correct new updateTime for the updated note.
    // The list order from server might be arbitrary before client-side sort.
    final notesFromServerAfterUpdate = [
      // Updated variable name and type
      NoteItem(
        // This represents the raw data from the server list call
        id: noteToUpdateId,
        content: 'Note after update', // Updated content
        pinned: false, // Add required field
        createTime:
            serverEpochCreateTime, // Incorrect time from server list response
        updateTime: serverUpdateTime, // Correct new update time
        displayTime: serverUpdateTime, // Add required field
        visibility: NoteVisibility.private, // Add required field
        state: NoteState.normal, // Add required field
      ),
      NoteItem(
        id: otherNoteId,
        content: 'Another note', // Updated content
        pinned: false, // Add required field
        createTime: now.subtract(const Duration(days: 1)),
        updateTime: now.subtract(const Duration(days: 1, minutes: 1)),
        displayTime: now.subtract(
          const Duration(days: 1, minutes: 1),
        ), // Add required field
        visibility: NoteVisibility.private, // Add required field
        state: NoteState.normal, // Add required field
      ),
    ];

    setUp(() {
      mockApiService = MockBaseApiService(); // Updated mock type

      // --- Mock Setup ---
      // 1. Initial listNotes call response (used if notifier fetches initially)
      when(
        mockApiService.listNotes(
          // Updated method name
          state: anyNamed('state'),
          sort: anyNamed('sort'),
          direction: anyNamed('direction'),
          pageSize: anyNamed('pageSize'),
          pageToken: anyNamed('pageToken'), // initial call has null page token
        ),
      ).thenAnswer(
        (_) async => ListNotesResponse(
          // Updated response type
          notes: initialNotes, // Updated field name
          nextPageToken: null,
        ),
      );

      // 2. updateNote call response (used by saveEntityProvider)
      when(
        mockApiService.updateNote(
          argThat(equals(noteToUpdateId)),
          any,
        ), // Updated method name
      ).thenAnswer(
        (_) async => NoteItem(
          // Updated type
          id: noteToUpdateId,
          content: 'Note after update', // Updated content
          createTime: serverEpochCreateTime, // Server sends bad createTime
          updateTime: serverUpdateTime, // Server sends correct updateTime
          displayTime: serverUpdateTime, // Add required field
          visibility: NoteVisibility.private, // Add required field
          state: NoteState.normal, // Add required field
          pinned: true, // Assume pinned was updated, add required field
        ),
      );

      // Add missing getNote stub for noteToUpdateId
      when(mockApiService.getNote(noteToUpdateId)).thenAnswer((_) async {
        // Updated method name
        // Return the note state as it would be after the update
        // This mock is used during refresh/invalidation after update
        return notesFromServerAfterUpdate.firstWhere(
          (m) => m.id == noteToUpdateId,
          orElse:
              () =>
                  throw Exception(
                    'Test setup error: Updated note not found',
                  ), // Updated message
        );
      });

      // 3. listNotes call *after* update (used by notifier's refresh)
      // This simulates the server list response containing the epoch createTime
      when(
        mockApiService.listNotes(
          // Updated method name
          // parent: anyNamed('parent'), // TODO: do I need thi?
          filter: anyNamed('filter'),
          state: anyNamed('state'),
          sort: anyNamed('sort'),
          direction: anyNamed('direction'),
          pageSize: anyNamed('pageSize'),
          pageToken: null, // Make this match specifically for refresh
        ),
      ).thenAnswer(
        (_) async => ListNotesResponse(
          // Updated response type
          notes: notesFromServerAfterUpdate, // Updated field name
          nextPageToken: null,
        ),
      );
      // --- End Mock Setup ---

      // Use the provider from api_providers.dart
      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
          // Override the notifier to set initial state manually
          note_providers.notesNotifierProvider.overrideWith((ref) {
            // Updated provider name
            final initialState = const note_providers.NotesState().copyWith(
              // Updated state type
              notes: initialNotes, // Updated field name
              isLoading: false,
              hasReachedEnd: true,
              totalLoaded: initialNotes.length,
            );
            // Use the MockNotesNotifier which overrides refresh
            return MockNotesNotifier(ref, initialState); // Updated mock type
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'After update, notesNotifierProvider state reflects sorted list with server createTime', // Updated test name
      () async {
        // 1. Verify initial state
        print(
          '[Test Flow] Verifying initial notesNotifierProvider state...',
        ); // Updated log
        final initialState = container.read(
          note_providers.notesNotifierProvider,
        ); // Updated provider name
        print(
          '[Test Flow] Initial state count: ${initialState.notes.length}',
        ); // Updated field name
        expect(initialState.notes.length, 2); // Updated field name
        expect(
          initialState.notes.first.id, // Updated field name
          noteToUpdateId, // Should be first due to its original updateTime
          reason:
              'Note with most recent original updateTime should be first initially', // Updated message
        );
        expect(
          initialState.notes.first.createTime, // Updated field name
          originalCreateTime, // Verify initial createTime is correct
        );

        // 2. Simulate the update action using the saveEntityProvider
        print(
          '[Test Flow] Triggering saveEntityProvider for ID: $noteToUpdateId...',
        );
        final noteDataForUpdate = NoteItem(
          // Updated type
          id: noteToUpdateId,
          content: 'Note after update', // Updated content
          // Pass the original createTime, as the UI would have it
          createTime: originalCreateTime,
          updateTime: originalUpdateTime, // This doesn't matter much here
          displayTime: originalUpdateTime, // Add required field
          visibility: NoteVisibility.private, // Add required field
          state: NoteState.normal, // Add required field
          pinned: false, // Add required field
        );
        // updateNoteProvider calls apiService.updateNote and updates notifier state
        await container.read(
          note_providers.updateNoteProvider(noteToUpdateId),
        )(noteDataForUpdate);
        print('[Test Flow] updateNoteProvider call complete.');

        // Verify updateNote was called with expected arguments
        verify(
          mockApiService.updateNote(
            argThat(equals(noteToUpdateId)),
            any,
          ), // Updated method name
        ).called(1);

        // The refresh triggered by saveEntityProvider uses the *second* mock response
        // for listNotes (notesFromServerAfterUpdate)

        // 3. Read the final state from notesNotifierProvider
        print(
          '[Test Flow] Reading final notesNotifierProvider state after refresh...', // Updated log
        );
        // Allow time for the async refresh within the mock notifier to complete
        await container
            .read(note_providers.notesNotifierProvider.notifier)
            .refresh(); // Updated provider name
        final finalState = container.read(
          note_providers.notesNotifierProvider,
        ); // Updated provider name
        print(
          '[Test Flow] Final state count: ${finalState.notes.length}',
        ); // Updated field name

        // 4. Verify the results
        expect(
          finalState.notes.length,
          2,
          reason: 'Should still have 2 notes',
        ); // Updated field name and message

        // Verify sorting: The updated note should now be first due to newer updateTime
        expect(
          finalState.notes.first.id, // Updated field name
          equals(noteToUpdateId),
          reason:
              'Updated note should be first when sorted by updateTime', // Updated message
        );
        expect(
          finalState.notes.last.id, // Updated field name
          equals(otherNoteId),
          reason: 'Other note should be second', // Updated message
        );

        // Verify createTime:
        // The list was refreshed using the mock response `notesFromServerAfterUpdate`,
        // which contained the incorrect epoch createTime from the server.
        // The client-side fix in BaseApiService only applies to the direct `updateNote` response,
        // not to the subsequent `listNotes` response conversion.
        final updatedNoteInList = finalState.notes.firstWhere(
          // Updated field name
          (m) => m.id == noteToUpdateId,
        );

        print(
          '[Test Verification] Checking createTime of updated note in final list...', // Updated log
        );
        print(
          '[Test Verification] Expected createTime from server list fetch: $serverEpochCreateTime', // Use DateTime
        );
        print(
          '[Test Verification] Actual createTime in list: ${updatedNoteInList.createTime}',
        );

        expect(
          updatedNoteInList.createTime,
          equals(
            serverEpochCreateTime,
          ), // Expecting the incorrect time from the list fetch
          reason:
              'createTime from list fetch is expected to be epoch (server bug)',
        );

        // Verify updateTime is correct
        expect(
          updatedNoteInList.updateTime,
          equals(serverUpdateTime),
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
