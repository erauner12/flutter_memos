import 'dart:async'; // Added for Timer

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/list_notes_response.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/providers/api_providers.dart'
    as api_p; // Keep for global OpenAI and task service
import 'package:flutter_memos/providers/filter_providers.dart';
// Import new single config providers
import 'package:flutter_memos/providers/note_server_config_provider.dart';
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/services/minimal_openai_service.dart';
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_memos/utils/comment_utils.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Removed Memos/Blinko specific service providers ---

// --- State and Notifier ---

@immutable
class NotesState {
  final List<NoteItem> notes;
  final String? nextPageToken;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;
  final bool hasReachedEnd;
  final int totalLoaded;
  final BlinkoNoteType? forcedBlinkoType; // Keep to inform notifier logic

  const NotesState({
    this.notes = const [],
    this.nextPageToken,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasReachedEnd = false,
    this.totalLoaded = 0,
    this.forcedBlinkoType,
  });

  NotesState copyWith({
    List<NoteItem>? notes,
    String? nextPageToken,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool? hasReachedEnd,
    int? totalLoaded,
    BlinkoNoteType? forcedBlinkoType,
    bool clearNextPageToken = false,
    bool clearError = false,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      nextPageToken:
          clearNextPageToken ? null : (nextPageToken ?? this.nextPageToken),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      totalLoaded: totalLoaded ?? this.totalLoaded,
      forcedBlinkoType: forcedBlinkoType ?? this.forcedBlinkoType,
    );
  }

  bool get canLoadMore => !isLoading && !isLoadingMore && !hasReachedEnd;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotesState &&
        listEquals(other.notes, notes) &&
        other.nextPageToken == nextPageToken &&
        other.isLoading == isLoading &&
        other.isLoadingMore == isLoadingMore &&
        other.error == error &&
        other.hasReachedEnd == hasReachedEnd &&
        other.totalLoaded == totalLoaded &&
        other.forcedBlinkoType == forcedBlinkoType;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(notes),
      nextPageToken,
      isLoading,
      isLoadingMore,
      error,
      hasReachedEnd,
      totalLoaded,
      forcedBlinkoType,
    );
  }
}

// Helper function to get the configured NoteApiService
NoteApiService _getNoteApiService(Ref ref) {
  final noteServerConfig = ref.read(noteServerConfigProvider);
  if (noteServerConfig == null) {
    throw Exception("No Note server configured.");
  }
  final service = ref.read(api_p.noteApiServiceProvider);
  if (service is api_p.DummyNoteApiService) {
    throw Exception(
      "Note API service is not properly configured (Dummy service returned).",
    );
  }
  return service;
}


class NotesNotifier extends StateNotifier<NotesState> {
  final Ref _ref;
  late final NoteApiService _apiService;
  static const int _pageSize = 20;
  final bool _skipInitialFetchForTesting;
  final BlinkoNoteType? _forcedBlinkoType; // Store the forced type

  NotesNotifier(
    this._ref, {
    bool skipInitialFetchForTesting = false,
    BlinkoNoteType? forcedBlinkoType,
  }) : _skipInitialFetchForTesting = skipInitialFetchForTesting,
       _forcedBlinkoType = forcedBlinkoType,
       super(NotesState(isLoading: true, forcedBlinkoType: forcedBlinkoType)) {
    try {
      _apiService = _getNoteApiService(_ref);
      _initialize();
    } catch (e) {
      if (kDebugMode)
        print('[NotesNotifier($_forcedBlinkoType)] Initialization error: $e');
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  void _initialize() {
    if (_skipInitialFetchForTesting) {
      if (kDebugMode)
        print(
          '[NotesNotifier($_forcedBlinkoType)] Skipping initialization for testing',
        );
      return;
    }

    // Listen to general filters (these might affect any instance of the notifier)
    // Consider if these listeners should be conditional based on _forcedBlinkoType
    _ref.listen(combinedFilterProvider, (_, __) {
      if (mounted) refresh();
    });
    _ref.listen(filterKeyProvider, (_, __) {
      if (mounted) refresh();
    });
    _ref.listen(quickFilterPresetProvider, (_, __) {
      if (mounted) refresh();
    });
    _ref.listen(searchQueryProvider, (_, __) {
      if (mounted) refresh();
    });
    _ref.listen(showHiddenNotesProvider, (_, __) {
      if (mounted) refresh();
    });
    _ref.listen(settings_p.manuallyHiddenNoteIdsProvider, (_, __) {
      if (mounted) refresh();
    });

    fetchInitialPage();
  }

  Future<void> _fetchPage({String? pageToken}) async {
    final NoteApiService apiService = _apiService;
    final combinedFilter = _ref.read(combinedFilterProvider);
    final selectedPresetKey = _ref.read(quickFilterPresetProvider);
    final searchQuery = _ref.read(searchQueryProvider).trim();

    String stateFilter = '';
    // State filtering: If a type is forced (Cache/Vault), always fetch NORMAL.
    // Otherwise, use preset logic.
    if (_forcedBlinkoType != null) {
      stateFilter = 'NORMAL';
    } else {
      if (selectedPresetKey == 'inbox')
        stateFilter = 'NORMAL';
      else if (selectedPresetKey == 'archive')
        stateFilter = 'ARCHIVED';
      // 'all', 'today', 'hidden', tags, etc. usually imply NORMAL unless overridden by filter
      // Let the API default or specific filter handle state otherwise
    }

    // Use the forced type directly for the API call
    BlinkoNoteType? blinkoTypeFilter = _forcedBlinkoType;

    final rawCelFilter = _ref.read(rawCelFilterProvider);
    bool usingRawFilter = rawCelFilter.isNotEmpty;
    String? finalFilter = combinedFilter.isNotEmpty ? combinedFilter : null;

    if (searchQuery.isNotEmpty) {
      final searchFilter = 'content.contains("$searchQuery")';
      finalFilter =
          finalFilter == null
              ? searchFilter
              : FilterBuilder.and([finalFilter, searchFilter]);
    }

    // Apply tag filter only if no type is forced and preset is a tag
    if (_forcedBlinkoType == null &&
        !usingRawFilter &&
        ![
          'all',
          'inbox',
          'archive',
          'today',
          'hidden',
          'custom',
          'tagged',
        ].contains(selectedPresetKey)) {
      final tagFilter = 'tag == "$selectedPresetKey"';
      finalFilter =
          finalFilter == null
              ? tagFilter
              : FilterBuilder.and([finalFilter, tagFilter]);
    }

    try {
      final ListNotesResponse response = await apiService.listNotes(
        filter: finalFilter,
        state: stateFilter.isNotEmpty ? stateFilter : null,
        sort: 'updateTime',
        direction: 'DESC',
        pageSize: _pageSize,
        pageToken: pageToken,
        blinkoType: blinkoTypeFilter, // Pass the forced type filter
      );

      // Client-side filtering safeguard (still useful)
      List<NoteItem> fetchedNotes = response.notes;
      if (_forcedBlinkoType != null) {
        fetchedNotes =
            fetchedNotes
                .where((note) => note.blinkoType == _forcedBlinkoType)
                .toList();
        if (kDebugMode && fetchedNotes.length < response.notes.length) {
          print(
            '[NotesNotifier($_forcedBlinkoType)] Client-side filter removed ${response.notes.length - fetchedNotes.length} notes with incorrect Blinko type.',
          );
        }
      }

      fetchedNotes.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updateTime.compareTo(a.updateTime);
      });

      var newNotes = fetchedNotes;
      final nextPageToken = response.nextPageToken;
      final bool hasReachedEnd =
          (nextPageToken == null ||
              nextPageToken.isEmpty ||
              (response.notes.length < _pageSize));
      final newTotalLoaded =
          (pageToken == null)
              ? newNotes.length
              : state.totalLoaded + newNotes.length;

      final List<NoteItem> resultNotes;
      if (pageToken == null) {
        resultNotes = newNotes;
      } else {
        final currentIds = state.notes.map((n) => n.id).toSet();
        final uniqueNewNotes =
            newNotes.where((n) => !currentIds.contains(n.id)).toList();
        resultNotes = [...state.notes, ...uniqueNewNotes];
        resultNotes.sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          return b.updateTime.compareTo(a.updateTime);
        });
      }

      if (mounted) {
        state = state.copyWith(
          notes: resultNotes,
          nextPageToken: nextPageToken,
          isLoading: false,
          isLoadingMore: false,
          clearError: true,
          hasReachedEnd: hasReachedEnd,
          totalLoaded: newTotalLoaded,
        );
      }
    } catch (e, st) {
      if (kDebugMode)
        print(
          '[NotesNotifier($_forcedBlinkoType)] Error fetching page: $e\n$st',
        );
      if (mounted)
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: e,
        );
    }
  }

  Future<void> fetchInitialPage() async {
    try {
      _getNoteApiService(_ref); // Check config before proceeding
    } catch (e) {
      if (mounted)
        state = state.copyWith(
          isLoading: false,
          error: e,
          notes: [],
          clearNextPageToken: true,
          hasReachedEnd: true,
          totalLoaded: 0,
        );
      return;
    }
    if (mounted) {
      state = state.copyWith(
        isLoading: true,
        notes: [],
        clearError: true,
        clearNextPageToken: true,
        hasReachedEnd: false,
        totalLoaded: 0,
      );
    }
    await _fetchPage(pageToken: null);
  }

  Future<void> fetchMoreNotes() async {
    if (!state.canLoadMore || state.nextPageToken == null) return;
    if (mounted) state = state.copyWith(isLoadingMore: true, clearError: true);
    await _fetchPage(pageToken: state.nextPageToken);
  }

  Future<void> refresh() async {
    if (kDebugMode)
      print('[NotesNotifier($_forcedBlinkoType)] Refresh triggered.');
    await fetchInitialPage();
  }

  // --- Optimistic Update Methods (Called by UI) ---

  void addNoteOptimistically(NoteItem newNote) {
    if (!mounted) return;
    // Only add if the note's type matches the forced type (if any)
    if (_forcedBlinkoType != null && newNote.blinkoType != _forcedBlinkoType) {
      if (kDebugMode)
        print(
          '[NotesNotifier($_forcedBlinkoType)] Skipped optimistic add for note ${newNote.id} due to type mismatch.',
        );
      return;
    }
    final updatedNotes = [newNote, ...state.notes];
    updatedNotes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updateTime.compareTo(a.updateTime);
    });
    state = state.copyWith(notes: updatedNotes);
    if (kDebugMode)
      print(
        '[NotesNotifier($_forcedBlinkoType)] Optimistically added note: ${newNote.id}',
      );
  }

  void updateNoteOptimistically(NoteItem updatedNote) {
    if (!mounted) return;
    // Only update if the note's type matches the forced type (if any)
    if (_forcedBlinkoType != null &&
        updatedNote.blinkoType != _forcedBlinkoType) {
      if (kDebugMode)
        print(
          '[NotesNotifier($_forcedBlinkoType)] Skipped optimistic update for note ${updatedNote.id} due to type mismatch. Removing instead.',
        );
      removeNoteOptimistically(updatedNote.id); // Remove if type changed
      return;
    }

    final updatedNotes =
        state.notes
            .map((note) => note.id == updatedNote.id ? updatedNote : note)
            .toList();
    updatedNotes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updateTime.compareTo(a.updateTime);
    });
    state = state.copyWith(notes: updatedNotes);
    if (kDebugMode)
      print(
        '[NotesNotifier($_forcedBlinkoType)] Optimistically updated note: ${updatedNote.id}',
      );
  }

  void removeNoteOptimistically(String noteId) {
    if (!mounted) return;
    final initialLength = state.notes.length;
    final updatedNotes =
        state.notes.where((note) => note.id != noteId).toList();
    if (updatedNotes.length < initialLength) {
      state = state.copyWith(notes: updatedNotes);
      if (kDebugMode)
        print(
          '[NotesNotifier($_forcedBlinkoType)] removeNoteOptimistically: Removed note $noteId.',
        );
    } else if (kDebugMode) {
      print(
        '[NotesNotifier($_forcedBlinkoType)] removeNoteOptimistically: Note $noteId not found.',
      );
    }
  }

  void archiveNoteOptimistically(String noteId) {
    if (!mounted) return;
    // Archiving always removes the note from Cache/Vault views or any view showing NORMAL state
    removeNoteOptimistically(noteId);
    if (kDebugMode)
      print(
        '[NotesNotifier($_forcedBlinkoType)] Optimistically removed archived note $noteId from view.',
      );
    // No need for the old else block, as filtering handles showing archived notes
    // in the 'archive' preset for the generic (null type) notifier.
  }

  void togglePinOptimistically(String noteId) {
    if (!mounted) return;
    final updatedNotes =
        state.notes.map((note) {
          if (note.id == noteId) return note.copyWith(pinned: !note.pinned);
          return note;
        }).toList();
    updatedNotes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updateTime.compareTo(a.updateTime);
    });
    state = state.copyWith(notes: updatedNotes);
    if (kDebugMode)
      print(
        '[NotesNotifier($_forcedBlinkoType)] Optimistically toggled pin for note: $noteId',
      );
  }

  void bumpNoteOptimistically(String noteId) {
    if (!mounted) return;
    final noteIndex = state.notes.indexWhere((note) => note.id == noteId);
    if (noteIndex != -1) {
      final noteToBump = state.notes[noteIndex];
      final updatedNote = noteToBump.copyWith(updateTime: DateTime.now());
      final updatedNotes = List<NoteItem>.from(state.notes);
      updatedNotes[noteIndex] = updatedNote;
      updatedNotes.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updateTime.compareTo(a.updateTime);
      });
      state = state.copyWith(notes: updatedNotes);
      if (kDebugMode)
        print(
          '[NotesNotifier($_forcedBlinkoType)] Optimistically bumped note: $noteId',
        );
    }
  }

  void updateNoteStartDateOptimistically(
    String noteId,
    DateTime? newStartDate,
  ) {
    if (!mounted) return;
    final noteIndex = state.notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) {
      if (kDebugMode)
        print(
          '[NotesNotifier($_forcedBlinkoType)] Note $noteId not found for start date update.',
        );
      return;
    }

    final originalNote = state.notes[noteIndex];
    // Basic validation (can be enhanced)
    if (newStartDate != null &&
        originalNote.endDate != null &&
        newStartDate.isAfter(originalNote.endDate!)) {
      if (kDebugMode)
        print(
          '[NotesNotifier($_forcedBlinkoType)] Cannot set start date ($newStartDate) after end date (${originalNote.endDate}) for note $noteId.',
        );
      // Maybe throw an error or show a message to the user?
      return;
    }

    final updatedNote = originalNote.copyWith(
      startDate: newStartDate,
      updateTime: DateTime.now(), // Bump update time
    );

    final currentNotes = List<NoteItem>.from(state.notes);
    currentNotes[noteIndex] = updatedNote;
    currentNotes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updateTime.compareTo(a.updateTime);
    });
    state = state.copyWith(notes: currentNotes);
    if (kDebugMode)
      print(
        '[NotesNotifier($_forcedBlinkoType)] Optimistically updated start date for note $noteId to $newStartDate.',
      );
  }
}

// --- Provider Definitions ---

/// **Family** Provider for Notes Notifier.
/// Pass `null` for general notes, or a specific `BlinkoNoteType` for Cache/Vault.
final notesNotifierFamily =
    StateNotifierProvider.family<NotesNotifier, NotesState, BlinkoNoteType?>((
      ref,
      blinkoTypeParam,
    ) {
      // Each family member gets its own notifier instance.
      return NotesNotifier(ref,
      forcedBlinkoType: blinkoTypeParam);
    }, name: 'notesNotifierFamily');

// --- REMOVED Old Global Providers ---
// final notesNotifierProvider = ...
// final cacheNotesNotifierProvider = ...
// final vaultNotesNotifierProvider = ...


// --- Derived Providers (Now Families) ---

/// Base filtered list based on the notifier's state and forced type.
/// Filters out archived notes unless the 'archive' preset is active for the generic type.
final baseFilteredNotesFamily = Provider.family<
  List<NoteItem>,
  BlinkoNoteType?
>((ref, type) {
  // Watch the specific notifier instance for the given type
  final notesState = ref.watch(notesNotifierFamily(type));
  final selectedPresetKey = ref.watch(quickFilterPresetProvider);

  // If a type is forced (Cache/Vault), the notifier should only fetch NORMAL state notes.
  // If type is null (generic), filter based on preset.
  final bool showArchived = (type == null && selectedPresetKey == 'archive');

  return notesState.notes.where((note) {
    // Basic state filtering
    if (showArchived) {
      return note.state == NoteState.archived;
    } else {
      return note.state != NoteState.archived;
    }
    // Note: The notifier already attempts to fetch the correct state based on type/preset.
    // This `where` clause acts as a secondary client-side filter/confirmation.
  }).toList();
}, name: 'baseFilteredNotesFamily');


/// Provides the count of manually hidden notes within the base filtered list for a specific type.
final manuallyHiddenNoteCountFamily = Provider.family<int, BlinkoNoteType?>((
  ref,
  type,
) {
  final baseNotes = ref.watch(baseFilteredNotesFamily(type));
  final manuallyHiddenIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  return baseNotes.where((note) => manuallyHiddenIds.contains(note.id)).length;
}, name: 'manuallyHiddenNoteCountFamily');

/// Provides the count of future-dated hidden notes within the base filtered list for a specific type.
final futureDatedHiddenNoteCountFamily = Provider.family<int, BlinkoNoteType?>((
  ref,
  type,
) {
  final baseNotes = ref.watch(baseFilteredNotesFamily(type));
  final manuallyHiddenIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  final now = DateTime.now();
  return baseNotes
      .where(
        (note) =>
            !manuallyHiddenIds.contains(note.id) &&
            note.startDate != null &&
            note.startDate!.isAfter(now),
      )
      .length;
}, name: 'futureDatedHiddenNoteCountFamily');

/// Provides the total count of hidden notes (manual + future-dated) for a specific type.
final totalHiddenNoteCountFamily = Provider.family<int, BlinkoNoteType?>((
  ref,
  type,
) {
  final manualCount = ref.watch(manuallyHiddenNoteCountFamily(type));
  final futureCount = ref.watch(futureDatedHiddenNoteCountFamily(type));
  return manualCount + futureCount;
}, name: 'totalHiddenNoteCountFamily');

/// Checks if a specific item ID is manually hidden. (Independent of type)
final isItemHiddenProvider = Provider.family<bool, String>((ref, id) {
  final hiddenItemIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  return hiddenItemIds.contains(id);
}, name: 'isItemHiddenProvider');

/// Provides a function to toggle the manual hidden state of an item.
/// **Important**: This needs to invalidate the correct notifier family instance(s).
final toggleItemVisibilityProvider = Provider.family<
  void Function(),
  ({String id, BlinkoNoteType? type})
>((
  ref,
  params,
) {
  return () {
    final manuallyHiddenIdsNotifier = ref.read(
      settings_p.manuallyHiddenNoteIdsProvider.notifier,
    );
    final currentHiddenIds = ref.read(settings_p.manuallyHiddenNoteIdsProvider);
    if (currentHiddenIds.contains(params.id)) {
      manuallyHiddenIdsNotifier.remove(params.id);
      if (kDebugMode)
        print(
          '[toggleItemVisibilityProvider] Unhid item (manual): ${params.id}',
        );
    } else {
      manuallyHiddenIdsNotifier.add(params.id);
      if (kDebugMode)
        print('[toggleItemVisibilityProvider] Hid item (manual): ${params.id}');
    }
    // Invalidate the specific notifier instance related to the context where toggle was called.
    // Also invalidate the generic (null) instance as the item might appear/disappear there too.
    ref.invalidate(notesNotifierFamily(params.type));
    if (params.type != null) {
      ref.invalidate(notesNotifierFamily(null));
    }
  };
}, name: 'toggleItemVisibilityProvider');

/// Provides the final filtered and sorted list of notes for display, based on type and UI filters.
final filteredNotesFamily = Provider.family<List<NoteItem>, BlinkoNoteType?>((
  ref,
  type,
) {
  // Start with the base list (already filtered by state/type partially)
  List<NoteItem> currentList = ref.watch(baseFilteredNotesFamily(type));

  // Get UI filter states
  final selectedPresetKey = ref.watch(quickFilterPresetProvider);
  final hidePinned = ref.watch(hidePinnedProvider);
  final showHiddenToggle = ref.watch(showHiddenNotesProvider);
  final manuallyHiddenIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();
  final now = DateTime.now();

  // Apply tag filtering (only for generic type)
  if (type == null) {
    if (![
      'all',
      'inbox',
      'archive',
      'today',
      'hidden',
      'custom',
      'tagged',
    ].contains(selectedPresetKey)) {
      // Assumed tag preset
      currentList =
          currentList
              .where((note) => note.tags.contains(selectedPresetKey))
              .toList();
    } else if (selectedPresetKey == 'tagged') {
      currentList = currentList.where((note) => note.tags.isNotEmpty).toList();
    }
  }

  // Apply visibility filtering (manual hide, future dates)
  // Handle 'hidden' preset view (only applies if type is null)
  if (type == null && selectedPresetKey == 'hidden') {
    // Base list for hidden view is already non-archived
    currentList =
        currentList.where((note) {
          final isManuallyHidden = manuallyHiddenIds.contains(note.id);
          final isFutureDated =
              note.startDate != null && note.startDate!.isAfter(now);
          return isManuallyHidden || isFutureDated;
        }).toList();
  } else if (!showHiddenToggle) {
    // If not in hidden view AND toggle is off, hide hidden items
    currentList =
        currentList.where((note) {
          final isManuallyHidden = manuallyHiddenIds.contains(note.id);
          final isFutureDated =
              note.startDate != null && note.startDate!.isAfter(now);
          return !isManuallyHidden && !isFutureDated;
        }).toList();
  }

  // Filter by pinned status
  if (hidePinned)
    currentList = currentList.where((note) => !note.pinned).toList();

  // Filter by search query
  if (searchQuery.isNotEmpty)
    currentList =
        currentList
            .where((note) => note.content.toLowerCase().contains(searchQuery))
            .toList();

  // Final Sort
  currentList.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    // Sort by updateTime consistently
    return b.updateTime.compareTo(a.updateTime);
  });

  return currentList;
}, name: 'filteredNotesFamily');

/// Checks if the current search query yields results for a specific type.
final hasSearchResultsFamily = Provider.family<bool, BlinkoNoteType?>((
  ref,
  type,
) {
  final searchQuery = ref.watch(searchQueryProvider);
  // Watch the final filtered list for the specific type
  final filteredNotes = ref.watch(filteredNotesFamily(type));
  return searchQuery.isEmpty || filteredNotes.isNotEmpty;
}, name: 'hasSearchResultsFamily');


// --- API Action Providers (Simplified: Perform API call, return result/error) ---

/// API call to unhide a note (removes from manual hidden list).
final unhideNoteProvider = Provider.family<void Function(), String>((ref, id) {
  // This action modifies settings, not directly the API notes state.
  // The toggleItemVisibilityProvider handles invalidation.
  return () {
    if (kDebugMode) print('[unhideNoteProvider] Unhiding note: $id');
    ref.read(settings_p.manuallyHiddenNoteIdsProvider.notifier).remove(id);
    // Invalidation is handled by the listener on manuallyHiddenNoteIdsProvider
    // or by toggleItemVisibilityProvider if called from there.
    // We might need to explicitly invalidate *all* families if unhiding from hidden view.
    ref.invalidate(notesNotifierFamily);
  };
}, name: 'unhideNoteProvider');

/// API call to unhide all manually hidden notes.
final unhideAllNotesProvider = Provider<Future<void> Function()>((ref) {
  // This action modifies settings and triggers refresh.
  return () async {
    if (kDebugMode)
      print('[unhideAllNotesProvider] Clearing all manually hidden notes.');
    await ref.read(settings_p.manuallyHiddenNoteIdsProvider.notifier).clear();
    // Refresh all potentially affected notifier instances.
    ref.invalidate(notesNotifierFamily);
  };
}, name: 'unhideAllNotesProvider');

/// API call to archive a note. Returns the updated NoteItem or throws error.
final archiveNoteApiProvider =
    Provider.family<Future<NoteItem> Function(), String>((
  ref,
  noteId,
) {
  return () async {
        final apiService = _getNoteApiService(ref);
    try {
          final NoteItem result = await apiService.archiveNote(noteId);
          // Invalidate detail cache
          ref
              .read(noteDetailCacheProvider.notifier)
              .update((state) => state..remove(noteId));
          ref.invalidate(noteDetailProvider(noteId));
          return result;
    } catch (e) {
          if (kDebugMode)
            print('[archiveNoteApiProvider] Error archiving note $noteId: $e');
          // Don't refresh here, let the caller handle error/refresh.
      rethrow;
    }
  };
});

/// API call to delete a note. Throws error on failure.
final deleteNoteApiProvider = Provider.family<Future<void> Function(), String>((
  ref,
  noteId,
) {
  return () async {
    if (kDebugMode)
      print('[deleteNoteApiProvider] Deleting note via API: $noteId');
    final apiService = _getNoteApiService(ref);
    try {
      await apiService.deleteNote(noteId);
      if (kDebugMode)
        print(
          '[deleteNoteApiProvider] Successfully deleted note via API: $noteId',
        );
      // Clear from manual hidden list if it was there
      ref
          .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
          .remove(noteId);
      // Invalidate detail cache
      ref
          .read(noteDetailCacheProvider.notifier)
          .update((state) => state..remove(noteId));
      ref.invalidate(noteDetailProvider(noteId));
    } catch (e, stackTrace) {
      if (kDebugMode)
        print(
          '[deleteNoteApiProvider] Error deleting note $noteId via API: $e\n$stackTrace',
        );
      // Don't refresh here, let the caller handle error/refresh.
      rethrow;
    }
  };
});

/// API call to "bump" a note (effectively update its updateTime). Returns updated NoteItem.
final bumpNoteApiProvider = Provider.family<
  Future<NoteItem> Function(),
  String
>((
  ref,
  noteId,
) {
  return () async {
    if (kDebugMode)
      print('[bumpNoteApiProvider] Bumping note via API: $noteId');
    final apiService = _getNoteApiService(ref);
    try {
      // Fetch current note, then immediately update it to bump timestamp server-side
      final NoteItem currentNote = await apiService.getNote(noteId);
      // Create a copy with potentially updated time (API might handle this automatically)
      final NoteItem result = await apiService.updateNote(noteId, currentNote);
      if (kDebugMode)
        print(
          '[bumpNoteApiProvider] Successfully bumped note via API: $noteId',
        );
      // Update detail cache
      ref
          .read(noteDetailCacheProvider.notifier)
          .update((state) => {...state, result.id: result});
      ref.invalidate(noteDetailProvider(noteId));
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode)
        print(
          '[bumpNoteApiProvider] Error bumping note $noteId via API: $e\n$stackTrace',
        );
      rethrow;
    }
  };
}, name: 'bumpNoteApiProvider');

/// API call to update a note. Returns the updated NoteItem.
final updateNoteApiProvider = Provider.family<
  Future<NoteItem> Function(NoteItem),
  String
>((ref, noteId) {
  return (NoteItem updatedNoteData) async {
    if (kDebugMode)
      print('[updateNoteApiProvider] Updating note via API: $noteId');
    final apiService = _getNoteApiService(ref);
    try {
      final NoteItem result = await apiService.updateNote(
        noteId,
        updatedNoteData,
      );
      if (kDebugMode)
        print(
          '[updateNoteApiProvider] Note $noteId updated successfully via API.',
        );
      // Update detail cache
      ref
          .read(noteDetailCacheProvider.notifier)
          .update((state) => {...state, result.id: result});
      ref.invalidate(noteDetailProvider(noteId));
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode)
        print(
          '[updateNoteApiProvider] Error updating note $noteId via API: $e\n$stackTrace',
        );
      ref.invalidate(
        noteDetailProvider(noteId),
      ); // Invalidate detail on error too
      rethrow;
    }
  };
});

/// API call to toggle the pin status of a note. Returns the updated NoteItem.
final togglePinNoteApiProvider = Provider.family<
  Future<NoteItem> Function(),
  String
>((ref, noteId) {
  return () async {
    if (kDebugMode)
      print(
        '[togglePinNoteApiProvider] Toggling pin state via API for note: $noteId',
      );
    final apiService = _getNoteApiService(ref);
    try {
      final NoteItem result = await apiService.togglePinNote(noteId);
      // Update detail cache
      ref
          .read(noteDetailCacheProvider.notifier)
          .update((state) => {...state, result.id: result});
      ref.invalidate(noteDetailProvider(noteId));
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode)
        print(
          '[togglePinNoteApiProvider] Error toggling pin state for note $noteId via API: $e\n$stackTrace',
        );
      rethrow;
    }
  };
});

/// API call to create a new note. Returns the created NoteItem.
final createNoteApiProvider = Provider<Future<NoteItem> Function(NoteItem)>((
  ref,
) {
  return (NoteItem note) async {
    final apiService = _getNoteApiService(ref);
    try {
      final NoteItem createdNote = await apiService.createNote(note);
      // Invalidate the relevant notifier family instance(s) after creation
      ref.invalidate(notesNotifierFamily(note.blinkoType));
      ref.invalidate(notesNotifierFamily(null)); // Invalidate generic too
      return createdNote;
    } catch (e) {
      if (kDebugMode)
        print('[createNoteApiProvider] Error creating note via API: $e');
      // Don't invalidate here, let caller handle error
      rethrow;
    }
  };
});

/// API call to fix grammar using OpenAI and update the note. Returns updated NoteItem.
final fixNoteGrammarApiProvider = Provider.family<Future<NoteItem>, String>((
  ref,
  noteId,
) {
  return () async {
    if (kDebugMode)
      print(
        '[fixNoteGrammarApiProvider] Starting grammar fix API process for note: $noteId',
      );
    final notesApiService = _getNoteApiService(ref);
    final MinimalOpenAiService openaiApiService = ref.read(
      api_p.openaiApiServiceProvider,
    );
    final String selectedModelId = ref.read(settings_p.openAiModelIdProvider);

    if (!openaiApiService.isConfigured) {
      throw Exception('OpenAI API key is not configured in settings.');
    }

    try {
      final NoteItem currentNote = await notesApiService.getNote(noteId);
      final String originalContent = currentNote.content;
      if (originalContent.trim().isEmpty) {
        if (kDebugMode)
          print(
            '[fixNoteGrammarApiProvider] Note content empty, skipping API call.',
          );
        return currentNote; // Return current note, no change
      }

      final String correctedContent = await openaiApiService.fixGrammar(
        originalContent,
        modelId: selectedModelId,
      );
      if (correctedContent == originalContent ||
          correctedContent.trim().isEmpty) {
        if (kDebugMode)
          print(
            '[fixNoteGrammarApiProvider] Content unchanged or correction empty.',
          );
        return currentNote; // Return current note, no change
      }

      final NoteItem updatedNoteData = currentNote.copyWith(
        content: correctedContent,
      );
      final NoteItem resultNote = await notesApiService.updateNote(
        noteId,
        updatedNoteData,
      );

      // Update detail cache
      ref
          .read(noteDetailCacheProvider.notifier)
          .update((state) => {...state, noteId: resultNote});
      ref.invalidate(noteDetailProvider(noteId));

      if (kDebugMode)
        print(
          '[fixNoteGrammarApiProvider] Note $noteId updated successfully via API.',
        );
      return resultNote;
    } catch (e, stackTrace) {
      if (kDebugMode)
        print(
          '[fixNoteGrammarApiProvider] Error fixing grammar for note $noteId via API: $e\n$stackTrace',
        );
      rethrow;
    }
  };
});


// --- Detail/Comment Providers (Mostly Unchanged) ---

final noteDetailCacheProvider = StateProvider<Map<String, NoteItem>>(
  (ref) => {},
  name: 'noteDetailCacheProvider',
);

final noteDetailProvider = FutureProvider.family<NoteItem, String>((
  ref,
  noteId,
) async {
  // Check cache first
  final cachedNote = ref.watch(noteDetailCacheProvider)[noteId];
  if (cachedNote != null) {
    return cachedNote;
  }
  // Fetch from API if not cached
  final apiService = _getNoteApiService(ref);
  final note = await apiService.getNote(noteId);
  // Update cache
  ref
      .read(noteDetailCacheProvider.notifier)
      .update((state) => {...state, noteId: note});
  return note;
}, name: 'noteDetailProvider');

final noteCommentsProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  noteId,
) async {
  final apiService = _getNoteApiService(ref);
  final comments = await apiService.listNoteComments(noteId);
  CommentUtils.sortByPinnedThenUpdateTime(comments);
  return comments;
}, name: 'noteCommentsProvider');

// Simple state provider for UI loading indicator
final isFixingGrammarProvider = StateProvider.family<bool, String>(
  (ref, noteId) => false,
  name: 'isFixingGrammarProvider',
);
