// Add imports for NoteItem, NotesState, note_providers, and settings_provider
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/utils/filter_presets.dart'; // Import FilterPresets
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart'; // Import mocktail
import 'package:shared_preferences/shared_preferences.dart';

// Mock NotesState if needed for overriding notesNotifierProvider
class MockNotesState extends Mock implements note_providers.NotesState {}

void main() {
  group('Filter Providers Tests', () {
    late ProviderContainer container;

    setUp(() {
      // Initialize SharedPreferences mock values before creating the container
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('quickFilterPresetProvider should have correct default value', () {
      expect(container.read(quickFilterPresetProvider), equals('inbox'));
    });

    test('rawCelFilterProvider should have correct default value', () {
      expect(container.read(rawCelFilterProvider), isEmpty);
    });

    test('combinedFilterProvider should use preset filter by default', () {
      // Default preset is 'inbox', which uses untaggedFilter
      expect(
        container.read(combinedFilterProvider),
        equals(FilterPresets.untaggedFilter()),
      );
    });

    test('combinedFilterProvider should use preset filter when changed', () {
      // Change preset to 'today'
      container.read(quickFilterPresetProvider.notifier).state = 'today';
      expect(
        container.read(combinedFilterProvider),
        equals(FilterPresets.todayFilter()),
      );

      // Change preset to 'all'
      container.read(quickFilterPresetProvider.notifier).state = 'all';
      expect(
        container.read(combinedFilterProvider),
        equals(FilterPresets.allFilter()), // Should be empty string
      );
      expect(container.read(combinedFilterProvider), isEmpty);

      // Change preset to 'tagged'
      container.read(quickFilterPresetProvider.notifier).state = 'tagged';
      expect(
        container.read(combinedFilterProvider),
        equals(FilterPresets.taggedFilter()),
      );
    });

    test(
      'combinedFilterProvider should use rawCelFilter when preset is custom',
      () {
        const customFilter =
            'content.contains("custom") && visibility == "PUBLIC"';

        // Set preset to 'custom' and provide a raw filter
        container.read(quickFilterPresetProvider.notifier).state = 'custom';
        container.read(rawCelFilterProvider.notifier).state = customFilter;

        // Verify combinedFilterProvider returns the raw filter
        expect(container.read(combinedFilterProvider), equals(customFilter));

        // Change raw filter while preset is still 'custom'
        const anotherCustomFilter = 'tag in ["project"]';
        container.read(rawCelFilterProvider.notifier).state =
            anotherCustomFilter;
      expect(
        container.read(combinedFilterProvider),
          equals(anotherCustomFilter),
      );
      },
    );

    test(
      'combinedFilterProvider should switch back to preset when preset changes from custom',
      () {
        const customFilter = 'content.contains("custom")';

        // Start with custom filter
        container.read(quickFilterPresetProvider.notifier).state = 'custom';
        container.read(rawCelFilterProvider.notifier).state = customFilter;
        expect(container.read(combinedFilterProvider), equals(customFilter));

        // Change preset back to 'inbox'
        container.read(quickFilterPresetProvider.notifier).state = 'inbox';
      expect(
        container.read(combinedFilterProvider),
          equals(FilterPresets.untaggedFilter()),
      );

        // Ensure raw filter wasn't cleared automatically (MemosScreen UI does this)
        expect(container.read(rawCelFilterProvider), equals(customFilter));
    });

    test(
      'saving and loading filter preferences uses quickFilterPresetProvider',
      () async {
        // Mock SharedPreferences (already done in setUp)

        // Set filter preset
        container.read(quickFilterPresetProvider.notifier).state = 'tagged';

        // Save preferences
        await container.read(filterPreferencesProvider)(
          container.read(quickFilterPresetProvider),
        );

        // Reset filter to default
        container.read(quickFilterPresetProvider.notifier).state = 'inbox';

        // Create a new container to simulate app restart
        final newContainer = ProviderContainer();
        // Ensure SharedPreferences are mocked for the new container too
        // SharedPreferences.setMockInitialValues are global, so this might not be strictly needed, but good practice.
        // If tests were parallel, this would be crucial.

        // Load preferences in the new container
        await newContainer.read(loadFilterPreferencesProvider.future);

        // Verify preferences were loaded into the new container
        expect(newContainer.read(quickFilterPresetProvider), equals('tagged'));

        newContainer.dispose(); // Clean up the new container
      },
    );

    test('saving preferences ignores "custom" preset key', () async {
      // Set filter preset to 'custom'
      container.read(quickFilterPresetProvider.notifier).state = 'custom';
      container.read(rawCelFilterProvider.notifier).state = 'some_filter';

      // Save preferences
      await container.read(filterPreferencesProvider)(
        container.read(quickFilterPresetProvider), // This is 'custom'
      );

      // Reset filter to default
      container.read(quickFilterPresetProvider.notifier).state = 'inbox';

      // Load preferences
      await container.read(loadFilterPreferencesProvider.future);

      // Verify preferences loaded the default ('inbox'), not 'custom'
      expect(container.read(quickFilterPresetProvider), equals('inbox'));
    });

    test('loading preferences ignores invalid saved key', () async {
      // Manually set an invalid value in SharedPreferences mock
      SharedPreferences.setMockInitialValues({
        'last_quick_preset': 'invalid_key',
      });

      // Create container AFTER setting mock values
      final testContainer = ProviderContainer();

      // Load preferences
      await testContainer.read(loadFilterPreferencesProvider.future);

      // Verify that the provider defaulted to 'inbox' because the saved key was invalid
      expect(testContainer.read(quickFilterPresetProvider), equals('inbox'));

      testContainer.dispose();
    });

    test('filterKeyProvider derives state from quickFilterPresetProvider', () {
      // Default state
      expect(container.read(quickFilterPresetProvider), equals('inbox'));
      expect(container.read(filterKeyProvider), equals('inbox'));

      // Change preset
      container.read(quickFilterPresetProvider.notifier).state = 'all';
      expect(container.read(filterKeyProvider), equals('all'));

      container.read(quickFilterPresetProvider.notifier).state = 'tagged';
      expect(
        container.read(filterKeyProvider),
        equals('all'),
      ); // Based on current mapping

      container.read(quickFilterPresetProvider.notifier).state = 'today';
      expect(
        container.read(filterKeyProvider),
        equals('all'),
      ); // Based on current mapping

      container.read(quickFilterPresetProvider.notifier).state = 'custom';
      expect(
        container.read(filterKeyProvider),
        equals('all'),
      ); // Based on current mapping

      // Test a non-mapped preset key (if one existed)
      // container.read(quickFilterPresetProvider.notifier).state = 'some_tag';
      // expect(container.read(filterKeyProvider), equals('some_tag'));
    });

    // --- Tests for filteredNotesProvider ---

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

    // Test data
    final noteVisible1 = createDummyNote(id: 'visible1');
    final noteVisible2 = createDummyNote(id: 'visible2');
    final noteManuallyHidden = createDummyNote(id: 'hiddenManual');
    final noteFuture = createDummyNote(
      id: 'hiddenFuture',
      startDate: DateTime.now().add(const Duration(days: 1)),
    );
    final noteFutureManuallyHidden = createDummyNote(
      id: 'hiddenFutureManual',
      startDate: DateTime.now().add(const Duration(days: 2)),
    );
    final noteArchived = createDummyNote(
      id: 'archived1',
      state: NoteState.archived,
    );
    final notePinnedVisible = createDummyNote(
      id: 'pinnedVisible',
      pinned: true,
    );
    final notePinnedManualHidden = createDummyNote(
      id: 'pinnedManualHidden',
      pinned: true,
    );
    final notePinnedFuture = createDummyNote(
      id: 'pinnedFuture',
      pinned: true,
      startDate: DateTime.now().add(const Duration(days: 3)),
    );

    final allNotes = [
      noteVisible1,
      noteVisible2,
      noteManuallyHidden,
      noteFuture,
      noteFutureManuallyHidden,
      noteArchived,
      notePinnedVisible,
      notePinnedManualHidden,
      notePinnedFuture,
    ];

    // Mock NotesState containing all test notes
    final mockNotesState = note_providers.NotesState(
      notes: {for (var note in allNotes) note.id: note},
      isLoading: false,
      errorMessage: null,
      nextPageToken: null,
    );

    test(
      'filteredNotesProvider returns only manually hidden and future notes when preset is "hidden"',
      () {
        final container = ProviderContainer(
          overrides: [
            // Override the source of notes
            note_providers.notesNotifierProvider.overrideWithValue(
              note_providers.NotesNotifier()..state = mockNotesState,
            ),
            // Override the set of manually hidden IDs
            settings_p.manuallyHiddenNoteIdsProvider.overrideWithValue(
              settings_p.PersistentSetNotifier<String>()
                ..state = {
                  noteManuallyHidden.id,
                  noteFutureManuallyHidden.id,
                  notePinnedManualHidden.id,
                },
            ),
            // Set the quick filter preset to 'hidden'
            quickFilterPresetProvider.overrideWithValue(
              StateController('hidden'),
            ),
            // showHiddenNotesProvider doesn't matter for the 'hidden' preset view
          ],
        );

        final filtered = container.read(note_providers.filteredNotesProvider);

        // Expected: Manually hidden notes + Future notes (regardless of manual hidden status)
        // Pinned status should be preserved but doesn't affect inclusion in 'hidden' view itself
        expect(
          filtered,
          containsAll([
            noteManuallyHidden,
            noteFuture,
            noteFutureManuallyHidden,
            notePinnedManualHidden,
            notePinnedFuture,
          ]),
        );
        expect(filtered, isNot(contains(noteVisible1)));
        expect(filtered, isNot(contains(noteVisible2)));
        expect(filtered, isNot(contains(noteArchived)));
        expect(filtered, isNot(contains(notePinnedVisible)));
        expect(filtered.length, 5); // Verify exact count
      },
    );

    test(
      'filteredNotesProvider excludes hidden notes when preset is not "hidden" and showHiddenNotesProvider is false',
      () {
        final container = ProviderContainer(
          overrides: [
            note_providers.notesNotifierProvider.overrideWithValue(
              note_providers.NotesNotifier()..state = mockNotesState,
            ),
            settings_p.manuallyHiddenNoteIdsProvider.overrideWithValue(
              settings_p.PersistentSetNotifier<String>()
                ..state = {
                  noteManuallyHidden.id,
                  noteFutureManuallyHidden
                      .id, // Future note also manually hidden
                  notePinnedManualHidden.id,
                },
            ),
            // Use 'all' preset (or 'inbox', etc.)
            quickFilterPresetProvider.overrideWithValue(StateController('all')),
            // Explicitly hide the hidden notes
            showHiddenNotesProvider.overrideWithValue(StateController(false)),
          ],
        );

        final filtered = container.read(note_providers.filteredNotesProvider);

        // Expected: Only normally visible notes (including pinned)
        expect(
          filtered,
          containsAll([noteVisible1, noteVisible2, notePinnedVisible]),
        );
        expect(filtered, isNot(contains(noteManuallyHidden)));
        expect(filtered, isNot(contains(noteFuture)));
        expect(filtered, isNot(contains(noteFutureManuallyHidden)));
        expect(filtered, isNot(contains(noteArchived)));
        expect(filtered, isNot(contains(notePinnedManualHidden)));
        expect(filtered, isNot(contains(notePinnedFuture)));
        expect(filtered.length, 3);
      },
    );

    test(
      'filteredNotesProvider includes hidden notes when preset is not "hidden" and showHiddenNotesProvider is true',
      () {
        final container = ProviderContainer(
          overrides: [
            note_providers.notesNotifierProvider.overrideWithValue(
              note_providers.NotesNotifier()..state = mockNotesState,
            ),
            settings_p.manuallyHiddenNoteIdsProvider.overrideWithValue(
              settings_p.PersistentSetNotifier<String>()
                ..state = {
                  noteManuallyHidden.id,
                  noteFutureManuallyHidden
                      .id, // Future note also manually hidden
                  notePinnedManualHidden.id,
                },
            ),
            // Use 'all' preset
            quickFilterPresetProvider.overrideWithValue(StateController('all')),
            // Explicitly show the hidden notes
            showHiddenNotesProvider.overrideWithValue(StateController(true)),
          ],
        );

        final filtered = container.read(note_providers.filteredNotesProvider);

        // Expected: All non-archived notes
        expect(
          filtered,
          containsAll([
            noteVisible1,
            noteVisible2,
            noteManuallyHidden,
            noteFuture,
            noteFutureManuallyHidden,
            notePinnedVisible,
            notePinnedManualHidden,
            notePinnedFuture,
          ]),
        );
        expect(filtered, isNot(contains(noteArchived)));
        expect(filtered.length, 8);
      },
    );

    test('filteredNotesProvider respects search query', () {
      final container = ProviderContainer(
        overrides: [
          note_providers.notesNotifierProvider.overrideWithValue(
            note_providers.NotesNotifier()..state = mockNotesState,
          ),
          settings_p.manuallyHiddenNoteIdsProvider.overrideWithValue(
            settings_p.PersistentSetNotifier<String>()
              ..state = {noteManuallyHidden.id},
          ),
          quickFilterPresetProvider.overrideWithValue(StateController('all')),
          showHiddenNotesProvider.overrideWithValue(
            StateController(false),
          ), // Start with hidden notes excluded
          // Add search query
          searchQueryProvider.overrideWithValue(StateController('visible1')),
        ],
      );

      final filtered = container.read(note_providers.filteredNotesProvider);

      // Expected: Only noteVisible1 matches the search
      expect(filtered, contains(noteVisible1));
      expect(filtered.length, 1);

      // Change search query to match a hidden note, but keep showHidden false
      container.read(searchQueryProvider.notifier).state = 'hiddenManual';
      final filteredHiddenSearch = container.read(
        note_providers.filteredNotesProvider,
      );
      // Should still be empty because hidden notes are globally hidden
      expect(filteredHiddenSearch, isEmpty);

      // Now, enable showing hidden notes AND search for the hidden note
      container.read(showHiddenNotesProvider.notifier).state = true;
      container.read(searchQueryProvider.notifier).state = 'hiddenManual';
      final filteredShowHiddenSearch = container.read(
        note_providers.filteredNotesProvider,
      );
      // Should now find the manually hidden note
      expect(filteredShowHiddenSearch, contains(noteManuallyHidden));
      expect(filteredShowHiddenSearch.length, 1);

      // Test search within the 'hidden' preset view
      container.read(quickFilterPresetProvider.notifier).state = 'hidden';
      container.read(searchQueryProvider.notifier).state =
          'Future'; // Search for future notes
      final filteredHiddenViewSearch = container.read(
        note_providers.filteredNotesProvider,
      );
      // Should find future notes within the hidden view
      expect(
        filteredHiddenViewSearch,
        containsAll([noteFuture, noteFutureManuallyHidden, notePinnedFuture]),
      );
      expect(filteredHiddenViewSearch.length, 3);
    });

  });
}
