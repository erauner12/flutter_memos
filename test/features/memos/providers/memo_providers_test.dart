import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter_memos/models/list_notes_response.dart'; // Updated import
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/filter_providers.dart' as filters;
import 'package:flutter_memos/providers/note_providers.dart'; // Updated import
import 'package:flutter_memos/services/base_api_service.dart'; // Updated import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the generated mocks file
import 'memo_providers_test.mocks.dart'; // Keep mock file name for now

// Annotation to generate nice mock for BaseApiService
@GenerateNiceMocks([MockSpec<BaseApiService>()]) // Updated to BaseApiService
// Mock Notifier extending the actual Notifier
class MockNotesNotifier extends NotesNotifier { // Updated class name
  MockNotesNotifier(super.ref, NotesState initialState) // Updated state type
    : super(skipInitialFetchForTesting: true) {
    if (kDebugMode) {
      print(
        '[MockNotesNotifier] Initializing with ${initialState.notes.length} notes', // Updated log
      );
    }
    state = initialState;
  }

  @override
  Future<void> refresh() async {
    if (kDebugMode) {
      print('[MockNotesNotifier] Refresh called - no-op for this test'); // Updated log
    }
    /* No-op */
  }

  @override
  Future<void> fetchMoreNotes() async { // Updated method name
    if (kDebugMode) {
      print('[MockNotesNotifier] FetchMoreNotes called - no-op for this test'); // Updated log
    }
    /* No-op */
  }
}

void main() {
  group('Note Providers Tests (New Notifier)', () { // Updated group name
    late MockBaseApiService mockApiService; // Updated mock type
    late ProviderContainer container;

    // Consistent notes for testing
    final notes = [ // Updated variable name and type
      NoteItem( // Updated type
        id: '1',
        content: 'Test note 1', // Updated content
        pinned: false, // Add required field
        createTime: DateTime.parse('2025-03-22T10:00:00Z'),
        updateTime: DateTime.parse('2025-03-23T10:00:00Z'), // Newest
        displayTime: DateTime.parse('2025-03-23T10:00:00Z'), // Add required field
        visibility: NoteVisibility.private, // Add required field
        state: NoteState.normal, // Add required field
      ),
      NoteItem( // Updated type
        id: '2',
        content: 'Test note 2', // Updated content
        pinned: false, // Add required field
        createTime: DateTime.parse('2025-03-21T10:00:00Z'),
        updateTime: DateTime.parse('2025-03-22T10:00:00Z'), // Middle
        displayTime: DateTime.parse('2025-03-22T10:00:00Z'), // Add required field
        visibility: NoteVisibility.private, // Add required field
        state: NoteState.normal, // Add required field
      ),
      NoteItem( // Updated type
        id: '3',
        content: 'Test note 3 #tagged', // Tagged note // Updated content
        pinned: false, // Add required field
        createTime: DateTime.parse('2025-03-20T10:00:00Z'),
        updateTime: DateTime.parse('2025-03-21T10:00:00Z'), // Oldest
        displayTime: DateTime.parse('2025-03-21T10:00:00Z'), // Add required field
        visibility: NoteVisibility.private, // Add required field
        state: NoteState.normal, // Add required field
      ),
    ];

    setUp(() {
      mockApiService = MockBaseApiService(); // Updated mock type

      when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');

      // Set up mock response for listNotes
      when(
        mockApiService.listNotes(
          // Updated method name
          filter: anyNamed('filter'),
          state: anyNamed('state'),
          sort: anyNamed('sort'),
          direction: anyNamed('direction'),
          pageSize: anyNamed('pageSize'),
          pageToken: anyNamed('pageToken'),
          // Remove unused parameters for clarity
          // tags: anyNamed('tags'),
          // visibility: anyNamed('visibility'),
          // contentSearch: anyNamed('contentSearch'),
          // createdAfter: anyNamed('createdAfter'),
          // createdBefore: anyNamed('createdBefore'),
          // updatedAfter: anyNamed('updatedAfter'),
          // updatedBefore: anyNamed('updatedBefore'),
          // timeExpression: anyNamed('timeExpression'),
          // useUpdateTimeForExpression: anyNamed('useUpdateTimeForExpression'),
        ),
      ).thenAnswer((invocation) async {
        return ListNotesResponse( // Updated response type
          notes: notes, // Updated field name
          nextPageToken: null,
        );
      });

      // Stub getNote
      when(mockApiService.getNote(any)).thenAnswer((invocation) async { // Updated method name
        final id = invocation.positionalArguments[0] as String;
        return notes.firstWhere(
          (m) => m.id == id,
          orElse: () => throw Exception('Note not found: $id'), // Updated message
        );
      });

      // Stub updateNote
      when(mockApiService.updateNote(any, any)).thenAnswer((invocation) async { // Updated method name
        final id = invocation.positionalArguments[0] as String;
        final note = invocation.positionalArguments[1] as NoteItem; // Updated type
        return note.copyWith(id: id);
      });

      // Stub deleteNote
      when(mockApiService.deleteNote(any)).thenAnswer((_) async => {}); // Updated method name

      // Add stubs for togglePinNote and archiveNote
      when(mockApiService.togglePinNote(any)).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        // Find the note in the *current* state of the mock notifier if possible,
        // otherwise use the initial 'notes' list as a fallback.
        final currentNotesList = container.read(notesNotifierProvider).notes;
        final currentNote = currentNotesList.firstWhere(
          (n) => n.id == id,
          orElse: () => notes.firstWhere((n) => n.id == id),
        );
        return currentNote.copyWith(pinned: !currentNote.pinned);
      });
      when(mockApiService.archiveNote(any)).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        final currentNotesList = container.read(notesNotifierProvider).notes;
        final currentNote = currentNotesList.firstWhere(
          (n) => n.id == id,
          orElse: () => notes.firstWhere((n) => n.id == id),
        );
        return currentNote.copyWith(state: NoteState.archived, pinned: false);
      });

      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
          // Override the notifier itself
          notesNotifierProvider.overrideWith((ref) { // Updated provider name
            final initialState = const NotesState().copyWith( // Updated state type
              notes: notes, // Updated field name
              isLoading: false,
              hasReachedEnd: true,
              totalLoaded: notes.length,
            );
            return MockNotesNotifier(ref, initialState); // Updated mock type
          }),
          filters.filterKeyProvider.overrideWith(
            (ref) => 'inbox',
          ),
          hiddenItemIdsProvider.overrideWith(
            (ref) => {},
          ), // Updated provider name
          filters.hidePinnedProvider.overrideWith((ref) => false),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('notesNotifierProvider holds initial state correctly', () { // Updated provider name
      final state = container.read(notesNotifierProvider); // Updated provider name
      expect(state.notes, equals(notes)); // Updated field name
      expect(state.isLoading, isFalse);
      expect(state.hasReachedEnd, isTrue);
    });

    test('visibleNotesListProvider filters out hidden note IDs', () { // Updated provider name
      // Hide note with ID '2'
      container.read(hiddenItemIdsProvider.notifier).state = {
        '2',
      }; // Updated provider name

      // Read the derived provider
      final visibleNotes = container.read(visibleNotesListProvider); // Updated provider name

      // Verify results
      expect(visibleNotes.length, equals(2));
      expect(visibleNotes.map((m) => m.id).toList(), equals(['1', '3']));
    });

    testWidgets(
      'visibleNotesListProvider filters out pinned notes when hidePinned is true', // Updated provider name
      (WidgetTester tester) async {
        // Make note '1' pinned
        final pinnedNotes = [ // Updated variable name
          notes[0].copyWith(pinned: true),
          notes[1],
          notes[2],
        ];
        container.read(notesNotifierProvider.notifier).state = container // Updated provider name
            .read(notesNotifierProvider) // Updated provider name
            .copyWith(notes: pinnedNotes); // Updated field name

        // Enable hidePinned
        container.read(filters.hidePinnedProvider.notifier).state =
            true; // Use filters.hidePinnedProvider

        await tester.pump();

        // Read the derived provider
        final visibleNotes = container.read(visibleNotesListProvider); // Updated provider name

        // Verify results (note '1' should be hidden)
        expect(visibleNotes.length, equals(2));
        expect(visibleNotes.map((m) => m.id).toList(), equals(['2', '3']));
      },
    );

    test('visibleNotesListProvider filters by state based on filterKey', () { // Updated provider name
      // Add an archived note to the state
      final archivedNote = NoteItem( // Updated type
        id: '4',
        content: 'Archived',
        pinned: false, // Add required field
        state: NoteState.archived, // Updated enum
        createTime: DateTime.now(), // Add required field
        updateTime: DateTime.now(), // Add required field
        displayTime: DateTime.now(), // Add required field
        visibility: NoteVisibility.private, // Add required field
      );
      final notesWithArchived = [...notes, archivedNote]; // Updated variable name
      container.read(notesNotifierProvider.notifier).state = container // Updated provider name
          .read(notesNotifierProvider) // Updated provider name
          .copyWith(notes: notesWithArchived); // Updated field name

      // Test 'inbox' filter (should exclude archived)
      container.read(filters.filterKeyProvider.notifier).state = 'inbox';
      final inboxNotes = container.read(visibleNotesListProvider); // Updated provider name
      expect(inboxNotes.length, equals(3));
      expect(inboxNotes.any((m) => m.id == '4'), isFalse);

      // Test 'archive' filter (should only include archived)
      container.read(filters.filterKeyProvider.notifier).state = 'archive';
      final archiveNotes = container.read(visibleNotesListProvider); // Updated provider name
      expect(archiveNotes.length, equals(1));
      expect(archiveNotes.first.id, equals('4'));

      // Test 'all' filter (should exclude archived)
      container.read(filters.filterKeyProvider.notifier).state = 'all';
      final allNotes = container.read(visibleNotesListProvider); // Updated provider name
      expect(allNotes.length, equals(3));
      expect(allNotes.any((m) => m.id == '4'), isFalse);
    });

    test('filteredNotesProvider applies search query', () { // Updated provider name
      // Set a search query
      container.read(filters.searchQueryProvider.notifier).state = 'note 1'; // Updated query

      // Read the derived provider
      final filtered = container.read(filteredNotesProvider); // Updated provider name

      // Verify results
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('1'));
    });

    test(
      'archiveNoteProvider archives a note correctly (optimistic + API)', // Updated provider name
      () async {
        final noteIdToArchive = '1'; // Updated prefix

        // Call the archive provider
        await container.read(archiveNoteProvider(noteIdToArchive))(); // Updated provider name

        // Verify optimistic update (note removed from visible list if filter is 'inbox')
        container.read(filters.filterKeyProvider.notifier).state =
            'inbox'; // Ensure filter excludes archived
        final visibleNotes = container.read(visibleNotesListProvider); // Updated provider name
        expect(visibleNotes.any((m) => m.id == noteIdToArchive), isFalse);

        // Verify archiveNote API call
        verify(mockApiService.archiveNote(noteIdToArchive)).called(1);
      },
    );

    test(
      'deleteNoteProvider deletes a note correctly (optimistic + API)', // Updated provider name
      () async {
        final noteIdToDelete = '2'; // Updated prefix

        // Call the delete provider
        await container.read(deleteNoteProvider(noteIdToDelete))(); // Updated provider name

        // Verify optimistic update (note removed from list)
        final currentNotes = container.read(notesNotifierProvider).notes; // Updated provider/field name
        expect(currentNotes.any((m) => m.id == noteIdToDelete), isFalse);

        // Verify API call using Mockito verification
        verify(mockApiService.deleteNote(noteIdToDelete)).called(1); // Updated method name
      },
    );

    test(
      'togglePinNoteProvider toggles pin state (optimistic + API)', // Updated provider name
      () async {
        final noteIdToToggle = '3'; // Updated prefix

        // Initial state check
        expect(
          container
              .read(notesNotifierProvider) // Updated provider name
              .notes // Updated field name
              .firstWhere((m) => m.id == noteIdToToggle)
              .pinned,
          isFalse,
        );

        // Create a stateful mock behavior for getNote
        final Map<String, NoteItem> mockNoteDatabase = {}; // Updated type
        mockNoteDatabase[noteIdToToggle] = notes.firstWhere(
          (m) => m.id == noteIdToToggle,
        );

        // Setup getNote to return from our database
        when(mockApiService.getNote(noteIdToToggle)).thenAnswer(( // Updated method name
          invocation,
        ) async {
          return mockNoteDatabase[noteIdToToggle]!;
        });

        // Setup updateNote to update our database
        when(
          mockApiService.updateNote(argThat(equals(noteIdToToggle)), any), // Updated method name
        ).thenAnswer((invocation) async {
          final note = invocation.positionalArguments[1] as NoteItem; // Updated type
          // Update our mock database to reflect the change
          mockNoteDatabase[noteIdToToggle] = note;
          return note;
        });

        // Call the toggle provider (to pin)
        await container.read(togglePinNoteProvider(noteIdToToggle))(); // Updated provider name

        // Verify optimistic update (pinned and moved to top)
        final notesAfterPin = container.read(notesNotifierProvider).notes; // Updated provider/field name
        expect(notesAfterPin.first.id, equals(noteIdToToggle));
        expect(notesAfterPin.first.pinned, isTrue);

        // Verify first API calls using Mockito verification
        verify(mockApiService.getNote(noteIdToToggle)).called(1); // Updated method name

        // Verify the first updateNote call (pin operation)
        final pinVerification = verify(
          mockApiService.updateNote( // Updated method name
            argThat(equals(noteIdToToggle)),
            captureAny,
          ),
        );
        pinVerification.called(1);

        final capturedPinNote = pinVerification.captured.single as NoteItem; // Updated type
        expect(capturedPinNote.pinned, isTrue);

        // Reset mock verification for clean tracking of the second call
        reset(mockApiService);

        // Setup the mock again after reset
        when(mockApiService.getNote(noteIdToToggle)).thenAnswer(( // Updated method name
          invocation,
        ) async {
          return mockNoteDatabase[noteIdToToggle]!;
        });

        when(
          mockApiService.updateNote(argThat(equals(noteIdToToggle)), any), // Updated method name
        ).thenAnswer((invocation) async {
          final note = invocation.positionalArguments[1] as NoteItem; // Updated type
          mockNoteDatabase[noteIdToToggle] = note;
          return note;
        });

        // Call again (to unpin)
        await container.read(togglePinNoteProvider(noteIdToToggle))(); // Updated provider name

        // Verify optimistic update (unpinned and sorted back)
        final notesAfterUnpin = container.read(notesNotifierProvider).notes; // Updated provider/field name
        expect(
          notesAfterUnpin.firstWhere((m) => m.id == noteIdToToggle).pinned,
          isFalse,
        );
        // Check if sorting is correct (note '1' should be first now)
        expect(notesAfterUnpin.first.id, equals('1'));

        // Verify second API calls
        verify(mockApiService.getNote(noteIdToToggle)).called(1); // Updated method name

        final unpinVerification = verify(
          mockApiService.updateNote( // Updated method name
            argThat(equals(noteIdToToggle)),
            captureAny,
          ),
        );
        unpinVerification.called(
          1,
        );

        // Check the second call's captured argument
        final capturedUnpinNote = unpinVerification.captured.single as NoteItem; // Updated type
        expect(capturedUnpinNote.pinned, isFalse);
      },
    );

    test('NotesNotifier.removeNoteOptimistically removes note from state', () { // Updated class/method name
      // Arrange
      final notifier = container.read(notesNotifierProvider.notifier) as MockNotesNotifier; // Updated provider/mock type
      final initialNoteCount = notifier.state.notes.length; // Updated field name
      final noteIdToRemove = notes[1].id; // Remove the second note ('2')

      // Pre-condition check
      expect(notifier.state.notes.any((m) => m.id == noteIdToRemove), isTrue); // Updated field name

      // Act
      notifier.removeNoteOptimistically(noteIdToRemove); // Updated method name

      // Assert
      final finalState = notifier.state;
      expect(finalState.notes.length, equals(initialNoteCount - 1)); // Updated field name
      expect(finalState.notes.any((m) => m.id == noteIdToRemove), isFalse); // Updated field name
    });

  });
}
