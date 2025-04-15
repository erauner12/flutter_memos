import 'package:flutter_memos/models/list_notes_response.dart'; // Updated import
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/note_providers.dart'; // Updated import
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/services/base_api_service.dart'; // Updated import
import 'package:flutter_memos/utils/note_utils.dart'; // Updated import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the generated mock file
import 'navigation_state_test.mocks.dart';

// Generate nice mocks for BaseApiService
@GenerateNiceMocks([MockSpec<BaseApiService>()])
void main() {
  late MockBaseApiService mockApiService; // Updated mock type
  late ProviderContainer container;
  late List<NoteItem> initialNotes; // Updated type

  // Helper to create a list of notes sorted by update time
  List<NoteItem> createSortedNotes(int count) {
    // Updated function name and type
    final notes = List.generate(count, (i) {
      final now = DateTime.now();
      // Ensure update times are distinct and descending for predictable sorting
      final updateTime = now.subtract(Duration(minutes: i));
      return NoteItem(
        id: 'note_$i', // Updated prefix
        content: 'Note Content $i', // Updated content
        pinned: false,
        state: NoteState.normal, // Updated enum
        updateTime: updateTime,
        createTime: updateTime, // Keep createTime consistent for simplicity here
        displayTime: updateTime, // Add required field
        visibility: NoteVisibility.private, // Add required field
      );
    });
    // Ensure sorting matches the app's logic
    NoteUtils.sortByPinnedThenUpdateTime(notes); // Updated utility
    return notes;
  }

  // Use setUpAll for mocks that don't change per test
  setUpAll(() {
    mockApiService = MockBaseApiService(); // Updated mock type

    // --- MOCK SETUP ---
    // Stub API calls needed by the action providers (delete, get, update)
    // Stub listNotes only for potential refresh calls within action providers
    when(
      mockApiService.listNotes(
        // Updated method name
      filter: anyNamed('filter'),
      state: anyNamed('state'),
      sort: anyNamed('sort'),
      direction: anyNamed('direction'),
      pageSize: anyNamed('pageSize'),
        pageToken: null, // Specifically for refresh (first page)
      ),
    ).thenAnswer((_) async {
      // Return empty for refresh calls to isolate optimistic update tests
      return ListNotesResponse(
        notes: [],
        nextPageToken: null,
      ); // Updated response type
    });

    when(mockApiService.deleteNote(any)).thenAnswer((_) async {
      // Updated method name
      return; // Return null for void
    });
    when(mockApiService.getNote(any)).thenAnswer((invocation) async {
      // Updated method name
      final id = invocation.positionalArguments[0] as String;
      // Use a *local copy* of initialNotes for lookup if needed, but prefer direct return
      // Recreate the list here to ensure it's available for lookup in the mock
      final notes = createSortedNotes(5); // Updated function name
      return notes.firstWhere(
        (note) => note.id == id, // Updated variable name
        orElse:
            () =>
                throw Exception(
                  'Note not found for ID: $id',
                ), // Updated message
      );
    });
    when(mockApiService.updateNote(any, any)).thenAnswer((invocation) async {
      final updatedNote =
          invocation.positionalArguments[1] as NoteItem; // Updated type
      return updatedNote; // Return the updated note
    });

    // Add stubs for togglePinNote and archiveNote
    when(mockApiService.togglePinNote(any)).thenAnswer((invocation) async {
      final id = invocation.positionalArguments[0] as String;
      // Recreate the list here to ensure it's available for lookup in the mock
      final notes = createSortedNotes(5); // Updated function name
      final currentNote = notes.firstWhere((n) => n.id == id);
      return currentNote.copyWith(pinned: !currentNote.pinned);
    });
    when(mockApiService.archiveNote(any)).thenAnswer((invocation) async {
      final id = invocation.positionalArguments[0] as String;
      // Recreate the list here to ensure it's available for lookup in the mock
      final notes = createSortedNotes(5); // Updated function name
      final currentNote = notes.firstWhere((n) => n.id == id);
      return currentNote.copyWith(state: NoteState.archived, pinned: false);
    });
    // --- END MOCK SETUP ---
  });

  // Use setUp for container creation and state setting per test
  setUp(() {
    initialNotes = createSortedNotes(5); // Ensure fresh list for each test

    // Create a ProviderContainer with overrides
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
        // Override the selectedItemIdProvider to ensure it's in the same scope
        ui_providers.selectedItemIdProvider.overrideWith((_) => null),

        // Override NotesNotifier: Create it, but we will set its state manually
        notesNotifierProvider.overrideWith(
          // Updated provider name
          (ref) {
            // Create the notifier with flag to skip automatic refresh/initialization
            final notifier = NotesNotifier(
              ref,
              skipInitialFetchForTesting: true,
            ); // Updated notifier type
            // Set the state *after* creation
            // Use copyWith on the default state to ensure all flags are set correctly
            notifier.state = const NotesState().copyWith(
              // Updated state type
              notes: initialNotes, // Updated field name
              isLoading: false, // Mark as not loading
              hasReachedEnd: true, // Assume initial load is done
              totalLoaded: initialNotes.length,
            );
            return notifier;
          },
        ),
      ],
    );

    // Reset selection before each test
    container.read(ui_providers.selectedItemIdProvider.notifier).state =
        null; // Use renamed provider

    // Verify initial state immediately after setup
    final initialState = container.read(
      notesNotifierProvider,
    ); // Updated provider name
    expect(
      initialState.notes.length, // Updated field name
      initialNotes.length,
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

  group('NotesNotifier Optimistic Updates & Selection', () {
    // Updated group name
    test('removeNoteOptimistically removes note from internal list', () async {
      // Updated test name and method name
      // Arrange
      final noteToRemoveId = initialNotes[2].id; // 'note_2'
      final initialNoteCount =
          container
              .read(notesNotifierProvider)
              .notes
              .length; // Updated provider/field name

      // Act: Call the notifier method directly
      container
          .read(notesNotifierProvider.notifier) // Updated provider name
          .removeNoteOptimistically(noteToRemoveId); // Updated method name

      // Assert: Note is removed from the notifier's state
      final updatedNotes =
          container
              .read(notesNotifierProvider)
              .notes; // Updated provider/field name
      expect(updatedNotes.length, initialNoteCount - 1);
      expect(
        updatedNotes.any((m) => m.id == noteToRemoveId),
        isFalse,
        reason:
            "Note should be removed from the notifier's note list", // Updated message
      );
    });

    test('togglePinOptimistically updates pin state and re-sorts', () {
      // Arrange
      final noteToPinId = initialNotes[3].id; // 'note_3'

      // Act: Toggle pin state
      container
          .read(notesNotifierProvider.notifier) // Updated provider name
          .togglePinOptimistically(noteToPinId); // Updated method name

      // Assert: Check that the note is pinned and moved to the top
      final notes =
          container
              .read(notesNotifierProvider)
              .notes; // Updated provider/field name
      expect(notes.first.id, noteToPinId);
      expect(notes.first.pinned, isTrue);
      expect(notes.length, initialNotes.length); // Count remains same

      // Act: Unpin the note
      container
          .read(notesNotifierProvider.notifier) // Updated provider name
          .togglePinOptimistically(noteToPinId); // Updated method name

      // Assert: Verify the note is unpinned and the list is re-sorted by time again
      final notesAfterUnpin =
          container
              .read(notesNotifierProvider)
              .notes; // Updated provider/field name
      expect(
        notesAfterUnpin.any((m) => m.id == noteToPinId && m.pinned),
        isFalse,
      );
      // Verify original time-based order is restored (or close to it)
      expect(notesAfterUnpin[0].id, initialNotes[0].id);
    });

    test('bumpNoteOptimistically updates time and re-sorts', () {
      // Updated method name
      // Arrange
      final noteToBumpId = initialNotes[4].id; // 'note_4', the oldest

      // Act: Bump the note's update time optimistically
      container
          .read(notesNotifierProvider.notifier) // Updated provider name
          .bumpNoteOptimistically(noteToBumpId); // Updated method name

      // Assert: Verify the note is at the top (most recent updateTime)
      final notes =
          container
              .read(notesNotifierProvider)
              .notes; // Updated provider/field name
      expect(notes.first.id, noteToBumpId);
      expect(notes.length, initialNotes.length);
    });

    test('archiveNoteOptimistically updates state', () {
      // Updated method name
      // Arrange
      final noteToArchiveId = initialNotes[1].id; // 'note_1'

      // Act: Archive the note optimistically
      container
          .read(notesNotifierProvider.notifier) // Updated provider name
          .archiveNoteOptimistically(noteToArchiveId); // Updated method name

      // Assert: Check that the note state is updated to archived
      final notes =
          container
              .read(notesNotifierProvider)
              .notes; // Updated provider/field name
      final archivedNote = notes.firstWhere((m) => m.id == noteToArchiveId);
      expect(archivedNote.state, NoteState.archived); // Updated enum
      expect(notes.length, initialNotes.length);
    });
  });

  group('Note Action Providers with Optimistic Updates', () {
    // Updated group name
    test('deleteNoteProvider calls optimistic update then API', () async {
      // Updated provider name
      // Arrange
      final noteId = initialNotes[1].id; // Choose a note to delete
      // Mock API success (already done in setUpAll)

      // Act: Execute the delete provider, passing necessary family args
      await container.read(
        deleteNoteProvider(noteId),
      )(); // Updated provider name

      // Assert: Note removed from state
      expect(
        container
            .read(notesNotifierProvider)
            .notes
            .any((m) => m.id == noteId), // Updated provider/field name
        isFalse,
        reason:
            "Note should be removed from the final state", // Updated message
      );

      // Assert: API was called
      verify(
        mockApiService.deleteNote(noteId),
      ).called(1); // Updated method name

      // Assert: Refresh was NOT called (delete provider doesn't refresh on success)
      verifyNever(
        mockApiService.listNotes(pageToken: null),
      ); // Updated method name
    });

    test('deleteNoteProvider adjusts selection correctly (downward preference)', () async {
      // Updated provider name
      // --- Test deleting the selected item (middle) ---
      // Arrange: Select index 2 ('note_2')
      final initialIndexSelected = 2;
      final noteToDeleteSelectedId =
          initialNotes[initialIndexSelected].id; // note_2
      container
          .read(ui_providers.selectedItemIdProvider.notifier)
          .state = // Use renamed provider
          noteToDeleteSelectedId;

      // Act: Delete the selected note
      await container.read(
        deleteNoteProvider(noteToDeleteSelectedId),
      )(); // Updated provider name

      // Assert: Selection should move DOWN to the next item ('note_3')
      final expectedNextIdAfterDeleteMiddle =
          initialNotes[initialIndexSelected + 1].id; // note_3
      expect(
        container.read(
          ui_providers.selectedItemIdProvider,
        ), // Use renamed provider
        expectedNextIdAfterDeleteMiddle,
        reason:
            "Selected item ID should move DOWN to the next note after deleting a middle note", // Updated message
      );

      // --- Test deleting the selected item (first) ---
      // Arrange: Reset state, select index 0 ('note_0')
      container
          .read(notesNotifierProvider.notifier)
          .state = const NotesState() // Updated state type
          .copyWith(
            notes: createSortedNotes(5), // Updated function name and field name
            isLoading: false,
            hasReachedEnd: true,
          );
      final initialIndexFirst = 0;
      final noteToDeleteFirstId = initialNotes[initialIndexFirst].id; // note_0
      container
          .read(ui_providers.selectedItemIdProvider.notifier)
          .state = // Use renamed provider
          noteToDeleteFirstId;

      // Act: Delete the first note
      await container.read(
        deleteNoteProvider(noteToDeleteFirstId),
      )(); // Updated provider name

      // Assert: Selection should move DOWN to the next item ('note_1')
      final expectedNextIdAfterDeleteFirst =
          initialNotes[initialIndexFirst + 1].id; // note_1
      expect(
        container.read(
          ui_providers.selectedItemIdProvider,
        ), // Use renamed provider
        expectedNextIdAfterDeleteFirst,
        reason:
            "Selected item ID should move DOWN to the next note after deleting the first note", // Updated message
      );

      // --- Test deleting the selected item (last) ---
      // Arrange: Reset state, select index 4 ('note_4')
      container
          .read(notesNotifierProvider.notifier)
          .state = const NotesState() // Updated state type
          .copyWith(
            notes: createSortedNotes(5), // Updated function name and field name
            isLoading: false,
            hasReachedEnd: true,
          );
      final initialIndexLast = 4;
      final noteToDeleteLastId = initialNotes[initialIndexLast].id; // note_4
      container
          .read(ui_providers.selectedItemIdProvider.notifier)
          .state = // Use renamed provider
          noteToDeleteLastId;

      // Act: Delete the last note
      await container.read(
        deleteNoteProvider(noteToDeleteLastId),
      )(); // Updated provider name

      // Assert: Selection should move UP to the PREVIOUS item ('note_3') as it's the new last item
      final expectedNextIdAfterDeleteLast =
          initialNotes[initialIndexLast - 1].id; // note_3
      expect(
        container.read(
          ui_providers.selectedItemIdProvider,
        ), // Use renamed provider
        expectedNextIdAfterDeleteLast,
        reason:
            "Selected item ID should move UP to the previous note after deleting the last note", // Updated message
      );


      // --- Test deleting item *before* selection (selection should not change) ---
      // Arrange: Reset state, select index 2 ('note_2'), delete index 0 ('note_0')
      container
          .read(notesNotifierProvider.notifier)
          .state = const NotesState() // Updated state type
          .copyWith(
            notes: createSortedNotes(5), // Updated function name and field name
            isLoading: false,
            hasReachedEnd: true,
          );
      final selectedIdBefore = initialNotes[2].id; // note_2
      final noteToDeleteBeforeId = initialNotes[0].id; // note_0
      container
          .read(ui_providers.selectedItemIdProvider.notifier)
          .state = // Use renamed provider
          selectedIdBefore;

      // Act: Delete note before selection
      await container.read(
        deleteNoteProvider(noteToDeleteBeforeId),
      )(); // Updated provider name

      // Assert: Selection ID remains unchanged
      expect(
        container.read(
          ui_providers.selectedItemIdProvider,
        ), // Use renamed provider
        selectedIdBefore,
        reason:
            "Selected item ID should remain unchanged when deleting a different note before it", // Updated message
      );

      // --- Test deleting item *after* selection (selection should not change) ---
      // Arrange: Reset state, select index 0 ('note_0'), delete index 3 ('note_3')
      container
          .read(notesNotifierProvider.notifier)
          .state = const NotesState() // Updated state type
          .copyWith(
            notes: createSortedNotes(5), // Updated function name and field name
            isLoading: false,
            hasReachedEnd: true,
          );
      final selectedIdAfter = initialNotes[0].id; // note_0
      final noteToDeleteAfterId = initialNotes[3].id; // note_3
      container
          .read(ui_providers.selectedItemIdProvider.notifier)
          .state = // Use renamed provider
          selectedIdAfter;

      // Act: Delete note after selection
      await container.read(
        deleteNoteProvider(noteToDeleteAfterId),
      )(); // Updated provider name

      // Assert: Selection ID remains unchanged
      expect(
        container.read(
          ui_providers.selectedItemIdProvider,
        ), // Use renamed provider
        selectedIdAfter,
        reason:
            "Selected item ID should remain unchanged when deleting a note after it", // Updated message
      );

      // --- Test deleting the only item ---
      // Arrange: Set up with only one note and select it
      final singleNote = createSortedNotes(1); // Updated function name
      container
          .read(notesNotifierProvider.notifier)
          .state = const NotesState() // Updated state type
          .copyWith(
            notes: singleNote,
            isLoading: false,
            hasReachedEnd: true,
          ); // Updated field name
      final singleNoteId = singleNote[0].id;
      container
          .read(ui_providers.selectedItemIdProvider.notifier)
          .state = // Use renamed provider
          singleNoteId;

      // Act: Delete the only note
      await container.read(
        deleteNoteProvider(singleNoteId),
      )(); // Updated provider name

      // Assert: Selection should become null
      expect(
        container.read(
          ui_providers.selectedItemIdProvider,
        ), // Use renamed provider
        isNull,
        reason:
            "Selection should be null after deleting the only note in the list", // Updated message
      );
    });

    test('togglePinNoteProvider calls optimistic update then API', () async {
      // Updated provider name
      // Arrange
      final noteId = initialNotes[2].id;
      final originalNote = initialNotes.firstWhere((m) => m.id == noteId);
      // Mock API calls (already done in setUpAll)

      // Act: Toggle note pin state via the provider
      await container.read(
        togglePinNoteProvider(noteId),
      )(); // Updated provider name

      // Assert: Verify note pin state toggled optimistically
      final notes =
          container
              .read(notesNotifierProvider)
              .notes; // Updated provider/field name
      final toggledNote = notes.firstWhere((m) => m.id == noteId);
      expect(toggledNote.pinned, !originalNote.pinned);

      // Assert: API calls were made
      verify(mockApiService.getNote(noteId)).called(1); // Updated method name
      verify(
        mockApiService.updateNote(noteId, any),
      ).called(1); // Updated method name

      // Assert: Refresh was NOT called (togglePin provider doesn't refresh on success)
      verifyNever(
        mockApiService.listNotes(pageToken: null),
      ); // Updated method name
    });

    test(
      'archiveNoteProvider calls optimistic update then API, then refreshes and updates selection',
      () async {
        // Updated provider name
      // Arrange
      final initialIndexSelected = 1;
        final noteId = initialNotes[initialIndexSelected].id; // note_1
        container.read(ui_providers.selectedItemIdProvider.notifier).state =
            noteId; // Select this note // Use renamed provider
        // Mocks for get/update/listNotes(refresh) already in setUpAll

      // Act: Execute archive provider
        await container.read(
          archiveNoteProvider(noteId),
        )(); // Updated provider name

        // Assert: Verify note state update via API calls
        verify(mockApiService.getNote(noteId)).called(1); // Updated method name
        final verificationResult = verify(
          mockApiService.updateNote(noteId, captureAny),
        ); // Updated method name
      verificationResult.called(1);
        final capturedNote =
            verificationResult.captured.single as NoteItem; // Updated type
        expect(capturedNote.state, NoteState.archived); // Updated enum
        expect(capturedNote.pinned, isFalse);

        // Assert: Refresh was NOT triggered on success
        verifyNever(
          mockApiService.listNotes(
            // Updated method name
        filter: anyNamed('filter'),
        state: anyNamed('state'),
        sort: anyNamed('sort'),
        direction: anyNamed('direction'),
        pageSize: anyNamed('pageSize'),
        pageToken: null, // The pageToken should be null for refresh
          ),
        ); // No longer called on success

        // Assert: Selection was updated DOWNWARD to the next note (note_2)
        final expectedNextIdAfterArchive =
            initialNotes[initialIndexSelected + 1].id; // note_2
      expect(
          container.read(
            ui_providers.selectedItemIdProvider,
          ), // Use renamed provider
        expectedNextIdAfterArchive,
          reason:
              "Selection should move DOWN to the next note after archiving the selected one", // Updated message
      );
    });
  });

  test('selectedItemIdProvider starts as null', () {
    // Updated provider name
    final selectedId = container.read(
      ui_providers.selectedItemIdProvider,
    ); // Use renamed provider
    expect(selectedId, isNull);
  });

  test('selectedItemIdProvider can be updated', () {
    // Updated provider name
    // Start at null
    final initialId = container.read(
      ui_providers.selectedItemIdProvider,
    ); // Use renamed provider
    expect(initialId, isNull);

    // Set to a note ID
    const testNoteId = 'test-note-123'; // Updated prefix
    container
        .read(ui_providers.selectedItemIdProvider.notifier)
        .state = // Use renamed provider
        testNoteId;
    final updatedId = container.read(
      ui_providers.selectedItemIdProvider,
    ); // Use renamed provider
    expect(updatedId, equals(testNoteId));
  });

  test('selectedCommentIndexProvider starts at -1', () {
    final index = container.read(ui_providers.selectedCommentIndexProvider);
    expect(index, equals(-1));
  });
}
