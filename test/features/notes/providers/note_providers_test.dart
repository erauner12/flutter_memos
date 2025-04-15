import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// --- Mocks ---
// Mock PersistentSetNotifier - ADD 'with Mock'
class MockPersistentSetNotifier extends StateNotifier<Set<String>>
    with
        Mock // Add this
    implements settings_p.PersistentSetNotifier<String> {
  MockPersistentSetNotifier(super.state);

  // Mock methods used by providers, ensure correct return type (Future<bool>)
  @override
  Future<bool> add(String item) async {
    state = Set.from(state)..add(item);
    return super.noSuchMethod(
      Invocation.method(#add, [item]),
      returnValue: Future.value(true), // Provide a default return value
      returnValueForMissingStub: Future.value(true),
    );
  }

  @override
  Future<bool> remove(String item) async {
    state = Set.from(state)..remove(item);
    return super.noSuchMethod(
      Invocation.method(#remove, [item]),
      returnValue: Future.value(true), // Provide a default return value
      returnValueForMissingStub: Future.value(true),
    );
  }

  @override
  Future<bool> clear() async {
    state = {};
    return super.noSuchMethod(
      Invocation.method(#clear, []),
      returnValue: Future.value(true), // Provide a default return value
      returnValueForMissingStub: Future.value(true),
    );
  }
}

// Mock NotesNotifier - ADD 'with Mock'
class MockNotesNotifier extends StateNotifier<note_providers.NotesState>
    with
        Mock // Add this
    implements note_providers.NotesNotifier {
  MockNotesNotifier(super.state);
  // No need to mock methods unless specifically testing interactions with them
}
// --- End Mocks ---

// Helper function to create a dummy NoteItem
NoteItem createDummyNote({
  required String id,
  String content = 'Test Note',
  DateTime? startDate,
  bool pinned = false,
  NoteState state = NoteState.normal,
}) {
  final now = DateTime.now();
  return NoteItem(
    id: id,
    content: content,
    pinned: pinned,
    state: state,
    visibility: NoteVisibility.public,
    createTime: now,
    updateTime: now,
    displayTime: now,
    startDate: startDate,
  );
}


void main() {
  group('Note Providers Tests', () {
    late MockPersistentSetNotifier mockHiddenIdsNotifier;
    // Declare container here, initialize in setUp
    late ProviderContainer container;

    setUp(() {
      mockHiddenIdsNotifier = MockPersistentSetNotifier(
        {},
      ); // Initialize with empty state
      // Create container fresh for each test
      container = ProviderContainer(
        overrides: [
          // Override with the *instance* of the mock notifier
          settings_p.manuallyHiddenNoteIdsProvider.overrideWith(
            (ref) => mockHiddenIdsNotifier,
          ),
          // Add overrides for other dependencies if needed by the providers under test
          // Provide a default mock for notesNotifierProvider to avoid errors in dependent providers
          note_providers.notesNotifierProvider.overrideWith(
            (ref) => MockNotesNotifier(const note_providers.NotesState()),
          ),
        ],
      );
    });

    tearDown(() {
      // Dispose container after each test
      container.dispose();
    });

    test('unhideNoteProvider calls remove on manuallyHiddenNoteIdsProvider', () {
      const noteIdToUnhide = 'note1';
      // Set initial state directly on the mock notifier instance
      mockHiddenIdsNotifier.state = {noteIdToUnhide, 'note2'};

      // Stub the remove method BEFORE calling the provider that uses it
      when(
        mockHiddenIdsNotifier.remove(noteIdToUnhide),
      ).thenAnswer((_) async => true);

      // Call the action provider using the container created in setUp
      container.read(note_providers.unhideNoteProvider(noteIdToUnhide))();

      // Verify that remove was called with the correct ID on the mock notifier
      verify(mockHiddenIdsNotifier.remove(noteIdToUnhide)).called(1);

      // Optionally verify the state change on the mock (already done by mock implementation)
      expect(mockHiddenIdsNotifier.state, equals({'note2'}));
    });

    test('unhideAllNotesProvider calls clear on manuallyHiddenNoteIdsProvider', () {
        // Set initial state directly on the mock notifier instance
        mockHiddenIdsNotifier.state = {'note1', 'note2', 'note3'};

        // Stub the clear method
        when(mockHiddenIdsNotifier.clear()).thenAnswer((_) async => true);

        // Call the action provider using the container from setUp
        container.read(note_providers.unhideAllNotesProvider)();

        // Verify that clear was called on the mock notifier
        verify(mockHiddenIdsNotifier.clear()).called(1);

        // Optionally verify the state change on the mock (already done by mock implementation)
        expect(mockHiddenIdsNotifier.state, isEmpty);
    });

    test('manuallyHiddenNoteCountProvider returns correct count', () {
      final hiddenIds = {'id1', 'id2', 'id3'};
      final mockHiddenNotifier = MockPersistentSetNotifier(hiddenIds);
      // Create a basic mock NotesState for _baseFilteredNotesProvider dependency
      final mockNotesState = note_providers.NotesState(
        notes: [
          createDummyNote(id: 'id1'),
          createDummyNote(id: 'id2'),
          createDummyNote(id: 'id3'),
          createDummyNote(id: 'id4'),
        ],
      );
      final mockNotesNotifier = MockNotesNotifier(mockNotesState);

      // Update overrides for the main container for this test scenario
      container.updateOverrides([
        settings_p.manuallyHiddenNoteIdsProvider.overrideWith(
          (ref) => mockHiddenNotifier,
        ),
        note_providers.notesNotifierProvider.overrideWith(
          (ref) => mockNotesNotifier,
        ),
      ]);

      expect(
        container.read(note_providers.manuallyHiddenNoteCountProvider),
        equals(3),
      );

      // Test with empty set
      final mockEmptyHiddenNotifier = MockPersistentSetNotifier({});
      // Update overrides again for the empty set scenario
      container.updateOverrides([
        settings_p.manuallyHiddenNoteIdsProvider.overrideWith(
          (ref) => mockEmptyHiddenNotifier,
        ),
        note_providers.notesNotifierProvider.overrideWith(
          (ref) => mockNotesNotifier,
        ), // Keep notes source
      ]);
      expect(
        container.read(note_providers.manuallyHiddenNoteCountProvider),
        equals(0),
      );
    });

    test('totalHiddenNoteCountProvider returns count of manually hidden and future notes', () {
      final noteVisible = createDummyNote(id: 'visible1');
      final noteManuallyHidden = createDummyNote(id: 'hiddenManual');
      final noteFuture = createDummyNote(
        id: 'hiddenFuture',
        startDate: DateTime.now().add(const Duration(days: 1)),
      );
      final noteFutureManuallyHidden = createDummyNote(
        id: 'hiddenFutureManual',
        startDate: DateTime.now().add(const Duration(days: 2)),
      );
      final noteArchived = createDummyNote(id: 'archived1', state: NoteState.archived);

      final allNotes = [
        noteVisible,
        noteManuallyHidden,
        noteFuture,
        noteFutureManuallyHidden,
        noteArchived,
      ];

        // Correctly create NotesState with a List<NoteItem>
      final mockNotesState = note_providers.NotesState(
          notes: allNotes,
          isLoading: false,
        nextPageToken: null,
      );
        final mockNotesNotifier = MockNotesNotifier(mockNotesState);

      final manuallyHiddenIds = {noteManuallyHidden.id, noteFutureManuallyHidden.id};
        final mockHiddenNotifier = MockPersistentSetNotifier(manuallyHiddenIds);

        // Update overrides for the main container
        container.updateOverrides([
          note_providers.notesNotifierProvider.overrideWith(
            (ref) => mockNotesNotifier,
          ),
          settings_p.manuallyHiddenNoteIdsProvider.overrideWith(
            (ref) => mockHiddenNotifier,
          ),
      ]);

        // Expected: noteManuallyHidden + noteFuture = 2 (noteFutureManuallyHidden counted in manual)
        // Correction: The logic counts unique notes that are *either* manually hidden *or* future-dated.
        // Manually Hidden: noteManuallyHidden, noteFutureManuallyHidden (2)
        // Future Dated (and not manually hidden): noteFuture (1)
        // Total = 2 + 1 = 3
        expect(
          container.read(note_providers.totalHiddenNoteCountProvider),
          equals(3),
        );

      // Test case with only future notes
        final mockHiddenNotifierFutureOnly = MockPersistentSetNotifier(
          {},
        ); // No manual hidden
        container.updateOverrides([
          note_providers.notesNotifierProvider.overrideWith(
            (ref) => mockNotesNotifier,
          ),
          settings_p.manuallyHiddenNoteIdsProvider.overrideWith(
            (ref) => mockHiddenNotifierFutureOnly,
          ),
      ]);
        // Expected: noteFuture + noteFutureManuallyHidden = 2
        expect(
          container.read(note_providers.totalHiddenNoteCountProvider),
          equals(2),
        );

        // Test case with only manually hidden notes
        final mockNotesStateManualOnly = note_providers.NotesState(
          notes: [noteVisible, noteManuallyHidden], // No future notes
          isLoading: false,
          nextPageToken: null,
        );
        final mockNotesNotifierManualOnly = MockNotesNotifier(
          mockNotesStateManualOnly,
        );
        final mockHiddenNotifierManualOnly = MockPersistentSetNotifier({
          noteManuallyHidden.id,
        });
        container.updateOverrides([
          note_providers.notesNotifierProvider.overrideWith(
            (ref) => mockNotesNotifierManualOnly,
          ),
          settings_p.manuallyHiddenNoteIdsProvider.overrideWith(
            (ref) => mockHiddenNotifierManualOnly,
          ),
      ]);
        // Expected: noteManuallyHidden = 1
        expect(
          container.read(note_providers.totalHiddenNoteCountProvider),
          equals(1),
        );

        // Test case with no hidden notes
        final mockNotesStateNoneHidden = note_providers.NotesState(
          notes: [noteVisible], // Only visible note
          isLoading: false,
          nextPageToken: null,
        );
        final mockNotesNotifierNoneHidden = MockNotesNotifier(
          mockNotesStateNoneHidden,
        );
        final mockHiddenNotifierNoneHidden = MockPersistentSetNotifier({});
        container.updateOverrides([
          note_providers.notesNotifierProvider.overrideWith(
            (ref) => mockNotesNotifierNoneHidden,
          ),
          settings_p.manuallyHiddenNoteIdsProvider.overrideWith(
            (ref) => mockHiddenNotifierNoneHidden,
          ),
      ]);
        // Expected: 0
        expect(
          container.read(note_providers.totalHiddenNoteCountProvider),
          equals(0),
        );
    });

  });
}
