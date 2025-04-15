import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock PersistentSetNotifier
class MockPersistentSetNotifier extends Mock implements settings_p.PersistentSetNotifier<String> {
  // Mock the state getter and setter if needed for verification
  Set<String> _state = {};

  @override
  Set<String> get state => _state;

  @override
  set state(Set<String> newState) => _state = newState;

  // Mock methods used by providers
  @override
  Future<void> add(String value) async {
    _state.add(value);
  }

  @override
  Future<void> remove(String value) async {
    _state.remove(value);
  }

  @override
  Future<void> clear() async {
    _state.clear();
  }
}

// Mock NotesState
class MockNotesState extends Mock implements note_providers.NotesState {}

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

    setUp(() {
      mockHiddenIdsNotifier = MockPersistentSetNotifier();
    });

    test('unhideNoteProvider calls remove on manuallyHiddenNoteIdsProvider', () {
      const noteIdToUnhide = 'note1';
      mockHiddenIdsNotifier.state = {noteIdToUnhide, 'note2'}; // Initial state

      final container = ProviderContainer(overrides: [
        settings_p.manuallyHiddenNoteIdsProvider.overrideWithValue(mockHiddenIdsNotifier),
      ]);

      // Call the action provider
      container.read(note_providers.unhideNoteProvider(noteIdToUnhide))();

      // Verify that remove was called with the correct ID
      // We need to verify the interaction with the *mocked notifier instance*
      verify(() => mockHiddenIdsNotifier.remove(noteIdToUnhide)).called(1);

      // Optionally verify the state change on the mock
      expect(mockHiddenIdsNotifier.state, equals({'note2'}));
    });

    test('unhideAllNotesProvider calls clear on manuallyHiddenNoteIdsProvider', () {
      mockHiddenIdsNotifier.state = {'note1', 'note2', 'note3'}; // Initial state

      final container = ProviderContainer(overrides: [
        settings_p.manuallyHiddenNoteIdsProvider.overrideWithValue(mockHiddenIdsNotifier),
      ]);

      // Call the action provider
      container.read(note_providers.unhideAllNotesProvider)();

      // Verify that clear was called
      verify(() => mockHiddenIdsNotifier.clear()).called(1);

      // Optionally verify the state change on the mock
      expect(mockHiddenIdsNotifier.state, isEmpty);
    });

    test('manuallyHiddenNoteCountProvider returns correct count', () {
      final hiddenIds = {'id1', 'id2', 'id3'};
      final container = ProviderContainer(overrides: [
        settings_p.manuallyHiddenNoteIdsProvider.overrideWithValue(
          settings_p.PersistentSetNotifier<String>()..state = hiddenIds,
        ),
      ]);

      expect(container.read(note_providers.manuallyHiddenNoteCountProvider), equals(3));

      // Test with empty set
      final emptyContainer = ProviderContainer(overrides: [
        settings_p.manuallyHiddenNoteIdsProvider.overrideWithValue(
          settings_p.PersistentSetNotifier<String>()..state = {},
        ),
      ]);
      expect(emptyContainer.read(note_providers.manuallyHiddenNoteCountProvider), equals(0));
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

      final mockNotesState = note_providers.NotesState(
        notes: { for (var note in allNotes) note.id: note },
        isLoading: false,
        errorMessage: null,
        nextPageToken: null,
      );

      final manuallyHiddenIds = {noteManuallyHidden.id, noteFutureManuallyHidden.id};

      final container = ProviderContainer(overrides: [
        note_providers.notesNotifierProvider.overrideWithValue(
          note_providers.NotesNotifier()..state = mockNotesState,
        ),
        settings_p.manuallyHiddenNoteIdsProvider.overrideWithValue(
          settings_p.PersistentSetNotifier<String>()..state = manuallyHiddenIds,
        ),
      ]);

      // Expected: noteManuallyHidden + noteFuture + noteFutureManuallyHidden = 3
      // Note: noteFutureManuallyHidden is counted only once even though it meets both criteria.
      expect(container.read(note_providers.totalHiddenNoteCountProvider), equals(3));

      // Test case with only future notes
       final containerFutureOnly = ProviderContainer(overrides: [
        note_providers.notesNotifierProvider.overrideWithValue(
          note_providers.NotesNotifier()..state = mockNotesState,
        ),
        settings_p.manuallyHiddenNoteIdsProvider.overrideWithValue(
          settings_p.PersistentSetNotifier<String>()..state = {}, // No manual hidden
        ),
      ]);
       // Expected: noteFuture + noteFutureManuallyHidden = 2
       expect(containerFutureOnly.read(note_providers.totalHiddenNoteCountProvider), equals(2));

       // Test case with only manually hidden notes
       final containerManualOnly = ProviderContainer(overrides: [
        note_providers.notesNotifierProvider.overrideWithValue(
          note_providers.NotesNotifier()..state = note_providers.NotesState(
            notes: {noteVisible.id: noteVisible, noteManuallyHidden.id: noteManuallyHidden}, // No future notes
            isLoading: false, errorMessage: null, nextPageToken: null,
          ),
        ),
        settings_p.manuallyHiddenNoteIdsProvider.overrideWithValue(
          settings_p.PersistentSetNotifier<String>()..state = {noteManuallyHidden.id},
        ),
      ]);
       // Expected: noteManuallyHidden = 1
       expect(containerManualOnly.read(note_providers.totalHiddenNoteCountProvider), equals(1));

        // Test case with no hidden notes
       final containerNoneHidden = ProviderContainer(overrides: [
        note_providers.notesNotifierProvider.overrideWithValue(
          note_providers.NotesNotifier()..state = note_providers.NotesState(
            notes: {noteVisible.id: noteVisible}, // Only visible note
            isLoading: false, errorMessage: null, nextPageToken: null,
          ),
        ),
        settings_p.manuallyHiddenNoteIdsProvider.overrideWithValue(
          settings_p.PersistentSetNotifier<String>()..state = {},
        ),
      ]);
       // Expected: 0
       expect(containerNoneHidden.read(note_providers.totalHiddenNoteCountProvider), equals(0));
    });

  });
}