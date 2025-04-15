import 'package:flutter_memos/models/list_notes_response.dart'; // Updated import
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/note_providers.dart'; // Updated import
import 'package:flutter_memos/services/base_api_service.dart'; // Updated import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the generated mocks file
import 'memo_update_sorting_test.mocks.dart';

// Annotation to generate nice mock for BaseApiService
@GenerateNiceMocks([MockSpec<BaseApiService>()])
// Mock Notifier extending the actual Notifier - Use the real one for simplicity here
// or define a proper mock if more complex behavior is needed.
// class MockNotesNotifier extends NotesNotifier { ... }


/// This unit test focuses specifically on the data flow and logic involved
/// when a note is updated, ensuring that:
/// 1. The `BaseApiService.updateNote` correctly handles the server's potentially incorrect
///    response (epoch createTime) by restoring the original createTime. (This part is tested in api_timestamp_behavior_test)
/// 2. The `updateNoteProvider` triggers an invalidation/refresh of `notesNotifierProvider`.
/// 3. The `notesNotifierProvider` correctly refetches (using mocks), converts, and client-side sorts the data.
/// 4. The final list reflects the updated note content and correct sorting by updateTime.
/// 5. The createTime in the *final list* reflects what the server *returned on the list fetch*,
///    demonstrating the limitation of the client-side fix (it only applies to the direct update response).
void main() {
  group('Note Update Timestamp Correction and Sorting Logic Test (Notifier)', () {
    late MockBaseApiService mockApiService;
    late ProviderContainer container;

    // Consistent timestamps for testing
    final now = DateTime.now().toUtc();
    final originalCreateTime = now.subtract(const Duration(hours: 1));
    final originalUpdateTime = now.subtract(const Duration(minutes: 30));
    final serverUpdateTime = now; // Time of the update
    final serverEpochCreateTime = DateTime.utc(1970, 1, 1); // Use DateTime

    final noteToUpdateId = 'note-to-update';
    final otherNoteId = 'other-note';

    // Initial note list state (sorted by update time desc)
    final initialNotes = [
      NoteItem(
        id: noteToUpdateId,
        content: 'Note before update',
        pinned: false,
        createTime: originalCreateTime,
        updateTime: originalUpdateTime, // Older update time
        displayTime: originalUpdateTime,
        visibility: NoteVisibility.private,
        state: NoteState.normal,
      ),
      NoteItem(
        id: otherNoteId,
        content: 'Another note',
        pinned: false,
        createTime: now.subtract(const Duration(days: 1)),
        updateTime: now.subtract(
          const Duration(days: 1, minutes: 1),
        ), // Even older
        displayTime: now.subtract(
          const Duration(days: 1, minutes: 1),
        ),
        visibility: NoteVisibility.private,
        state: NoteState.normal,
      ),
    ];

    // State of the list *as returned by the server* after the update
    // Note: Server returns epoch createTime, but correct new updateTime for the updated note.
    // The list order from server might be arbitrary before client-side sort.
    final notesFromServerAfterUpdate = [
      NoteItem(
        // This represents the raw data from the server list call
        id: noteToUpdateId,
        content: 'Note after update',
        pinned: false,
        createTime:
            serverEpochCreateTime, // Incorrect time from server list response
        updateTime: serverUpdateTime, // Correct new update time
        displayTime: serverUpdateTime,
        visibility: NoteVisibility.private,
        state: NoteState.normal,
      ),
      NoteItem(
        id: otherNoteId,
        content: 'Another note',
        pinned: false,
        createTime: now.subtract(const Duration(days: 1)),
        updateTime: now.subtract(const Duration(days: 1, minutes: 1)),
        displayTime: now.subtract(
          const Duration(days: 1, minutes: 1),
        ),
        visibility: NoteVisibility.private,
        state: NoteState.normal,
      ),
    ];

    setUp(() {
      mockApiService = MockBaseApiService();

      // --- Mock Setup ---
      // 1. Initial listNotes call response (used if notifier fetches initially)
      // Use pageToken: null for the initial call
      when(
        mockApiService.listNotes(
          filter: anyNamed('filter'),
          state: anyNamed('state'),
          sort: anyNamed('sort'),
          direction: anyNamed('direction'),
          pageSize: anyNamed('pageSize'),
          pageToken: null, // initial call has null page token
        ),
      ).thenAnswer(
        (_) async => ListNotesResponse(
          notes: initialNotes,
          nextPageToken: null,
        ),
      );

      // 2. updateNote call response (used by updateNoteProvider)
      when(
        mockApiService.updateNote(
          argThat(equals(noteToUpdateId)),
          any,
        ),
      ).thenAnswer(
        (invocation) async {
        // Simulate the BaseApiService behavior of restoring createTime
        final originalNote = invocation.positionalArguments[1] as NoteItem;
        return NoteItem(
          id: noteToUpdateId,
          content: 'Note after update',
          createTime: originalNote.createTime, // Restore original createTime
          updateTime: serverUpdateTime, // Server sends correct updateTime
          displayTime: serverUpdateTime,
          visibility: NoteVisibility.private,
          state: NoteState.normal,
          pinned: false, // Assume pinned was not updated
        );
      },
      );

      // Add missing getNote stub for noteToUpdateId (needed by updateNoteProvider)
      when(mockApiService.getNote(noteToUpdateId)).thenAnswer((_) async {
        // Return the note state *before* the update for the getNote call
        // within updateNoteProvider
        return initialNotes.firstWhere(
          (m) => m.id == noteToUpdateId,
          orElse:
              () =>
                  throw Exception(
                    'Test setup error: Initial note not found for getNote',
                  ),
        );
      });

      // 3. listNotes call *after* update (used by notifier's refresh)
      // This simulates the server list response containing the epoch createTime
      // Use pageToken: null again for the refresh call
      when(
        mockApiService.listNotes(
          filter: anyNamed('filter'),
          state: anyNamed('state'),
          sort: anyNamed('sort'),
          direction: anyNamed('direction'),
          pageSize: anyNamed('pageSize'),
          pageToken: null, // Make this match specifically for refresh
        ),
      ).thenAnswer(
        (_) async => ListNotesResponse(
          notes: notesFromServerAfterUpdate,
          nextPageToken: null,
        ),
      );
      // --- End Mock Setup ---

      // Use the provider from note_providers.dart
      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
          // Override the notifier to set initial state manually and use the real notifier
          notesNotifierProvider.overrideWith((ref) {
            final initialState = const NotesState().copyWith(
              notes: initialNotes,
              isLoading: false,
              hasReachedEnd: true,
              totalLoaded: initialNotes.length,
            );
            // Return the REAL notifier, initialized manually
            final notifier = NotesNotifier(
              ref,
              skipInitialFetchForTesting: true,
            );
            notifier.state = initialState;
            return notifier;
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'After update, notesNotifierProvider state reflects sorted list with server createTime',
      () async {
        // 1. Verify initial state
        print(
          '[Test Flow] Verifying initial notesNotifierProvider state...',
        );
        final initialState = container.read(
          notesNotifierProvider);
        print(
          '[Test Flow] Initial state count: ${initialState.notes.length}',
        );
        expect(initialState.notes.length, 2);
        expect(
          initialState.notes.first.id,
          noteToUpdateId, // Should be first due to its original updateTime
          reason:
              'Note with most recent original updateTime should be first initially',
        );
        expect(
          initialState.notes.first.createTime,
          originalCreateTime, // Verify initial createTime is correct
        );

        // 2. Simulate the update action using the updateNoteProvider
        print(
          '[Test Flow] Triggering updateNoteProvider for ID: $noteToUpdateId...',
        );
        final noteDataForUpdate = NoteItem(
          id: noteToUpdateId,
          content: 'Note after update',
          // Pass the original createTime, as the UI would have it
          createTime: originalCreateTime,
          updateTime: originalUpdateTime, // This doesn't matter much here
          displayTime: originalUpdateTime,
          visibility: NoteVisibility.private,
          state: NoteState.normal,
          pinned: false,
        );
        // updateNoteProvider calls apiService.updateNote and invalidates notesNotifierProvider
        await container.read(
          updateNoteProvider(noteToUpdateId),
        )(noteDataForUpdate);
        print('[Test Flow] updateNoteProvider call complete.');

        // Verify updateNote was called with expected arguments
        verify(
          mockApiService.updateNote(
            argThat(equals(noteToUpdateId)),
            any,
          ),
        ).called(1);

        // The invalidation caused by updateNoteProvider will trigger a refetch
        // which uses the *second* mock response for listNotes (notesFromServerAfterUpdate)

        // 3. Read the final state from notesNotifierProvider
        print(
          '[Test Flow] Reading final notesNotifierProvider state after refresh...',
        );
        // Allow time for the provider to refetch after invalidation
        await container.pump(); // Allow invalidation and refresh to process

        final finalState = container.read(
          notesNotifierProvider);
        print(
          '[Test Flow] Final state count: ${finalState.notes.length}',
        );

        // 4. Verify the results
        expect(
          finalState.notes.length,
          2,
          reason: 'Should still have 2 notes',
        );

        // Verify sorting: The updated note should now be first due to newer updateTime
        expect(
          finalState.notes.first.id,
          equals(noteToUpdateId),
          reason:
              'Updated note should be first when sorted by updateTime',
        );
        expect(
          finalState.notes.last.id,
          equals(otherNoteId),
          reason: 'Other note should be second',
        );

        // Verify createTime:
        // The list was refreshed using the mock response `notesFromServerAfterUpdate`,
        // which contained the incorrect epoch createTime from the server.
        // The client-side fix in BaseApiService only applies to the direct `updateNote` response,
        // not to the subsequent `listNotes` response conversion.
        final updatedNoteInList = finalState.notes.firstWhere(
          (m) => m.id == noteToUpdateId,
        );

        print(
          '[Test Verification] Checking createTime of updated note in final list...',
        );
        print(
          '[Test Verification] Expected createTime from server list fetch: $serverEpochCreateTime',
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

// Helper extension for pumping futures in tests
// TODO: put this somewhere common
extension PumpExtension on ProviderContainer {
  Future<void> pump() async {
    await Future.delayed(Duration.zero);
  }
}
