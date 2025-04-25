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
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
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
  final BlinkoNoteType? forcedBlinkoType; // Added to store forced type

  const NotesState({
    this.notes = const [],
    this.nextPageToken,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasReachedEnd = false,
    this.totalLoaded = 0,
    this.forcedBlinkoType, // Added
  });

  NotesState copyWith({
    List<NoteItem>? notes,
    String? nextPageToken,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool? hasReachedEnd,
    int? totalLoaded,
    BlinkoNoteType? forcedBlinkoType, // Added
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
      forcedBlinkoType: forcedBlinkoType ?? this.forcedBlinkoType, // Added
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
        other.forcedBlinkoType == forcedBlinkoType; // Added comparison
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
      forcedBlinkoType, // Added to hash
    );
  }
}

// Helper function to get the configured NoteApiService (moved from previous version)
// Throws if no note server is configured or if the service is invalid.
NoteApiService _getNoteApiService(Ref ref) {
  final noteServerConfig = ref.read(noteServerConfigProvider);
  if (noteServerConfig == null) {
    throw Exception("No Note server configured.");
  }
  // Use the dedicated provider which handles configuration and returns the correct type
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
  late final NoteApiService
  _apiService; // Store the configured service instance
  static const int _pageSize = 20;
  final bool _skipInitialFetchForTesting;
  final BlinkoNoteType? _forcedBlinkoType; // Store the forced type

  NotesNotifier(
    this._ref, {
    bool skipInitialFetchForTesting = false,
    BlinkoNoteType? forcedBlinkoType, // Accept forced type
  }) : _skipInitialFetchForTesting = skipInitialFetchForTesting,
       _forcedBlinkoType = forcedBlinkoType, // Store it
       super(NotesState(isLoading: true, forcedBlinkoType: forcedBlinkoType)) {
    // Initialize state with type
    try {
      _apiService = _getNoteApiService(_ref);
      _initialize();
    } catch (e) {
      if (kDebugMode) print('[NotesNotifier] Initialization error: $e');
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  void _initialize() {
    if (_skipInitialFetchForTesting) {
      if (kDebugMode)
        print('[NotesNotifier] Skipping initialization for testing');
      return;
    }

    // Only listen to general filters if no type is forced
    if (_forcedBlinkoType == null) {
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
    }
    // Always listen to these regardless of forced type
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
    // State filtering based on presets (only if type is not forced)
    if (_forcedBlinkoType == null) {
      if (selectedPresetKey == 'inbox')
        stateFilter = 'NORMAL';
      else if (selectedPresetKey == 'archive')
        stateFilter = 'ARCHIVED';
    } else {
      // If type is forced (Cache/Vault), always fetch NORMAL state
      // Archived items are typically not shown in Cache/Vault views
      stateFilter = 'NORMAL';
    }


    // Determine BlinkoNoteType based on forced type first, then preset
    BlinkoNoteType? blinkoTypeFilter =
        _forcedBlinkoType; // Use forced type if available

    // Removed: Logic deriving blinkoTypeFilter from selectedPresetKey ('cache'/'vault')
    // switch (selectedPresetKey) {
    //   case 'cache':
    //     blinkoTypeFilter = BlinkoNoteType.cache;
    //     break;
    //   case 'vault':
    //     blinkoTypeFilter = BlinkoNoteType.vault;
    //     break;
    //   default:
    //     // Keep null if not cache/vault preset
    //     break;
    // }

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
          // Removed 'cache', 'vault'
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
        blinkoType: blinkoTypeFilter, // Pass the determined type filter
      );

      // Client-side filtering safeguard: Ensure only notes of the forced type are kept
      List<NoteItem> fetchedNotes = response.notes;
      if (_forcedBlinkoType != null) {
        fetchedNotes =
            fetchedNotes
                .where((note) => note.blinkoType == _forcedBlinkoType)
                .toList();
        if (kDebugMode && fetchedNotes.length < response.notes.length) {
          print(
            '[NotesNotifier] Client-side filter removed ${response.notes.length - fetchedNotes.length} notes with incorrect Blinko type.',
          );
        }
      }

      fetchedNotes.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updateTime.compareTo(a.updateTime);
      });

      var newNotes = fetchedNotes;
      final nextPageToken = response.nextPageToken;
      // Adjust hasReachedEnd based on potentially filtered list length
      final bool hasReachedEnd =
          (nextPageToken == null ||
              nextPageToken.isEmpty ||
              (response.notes.length <
                  (_pageSize))); // Check original response length
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
      if (kDebugMode) print('[NotesNotifier] Error fetching page: $e\n$st');
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
      _getNoteApiService(_ref);
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
    if (kDebugMode) print('[NotesNotifier] Refresh triggered.');
    await fetchInitialPage();
  }

  void updateNoteOptimistically(NoteItem updatedNote) {
    if (!mounted) return;
    // Only update if the note's type matches the forced type (if any)
    if (_forcedBlinkoType != null &&
        updatedNote.blinkoType != _forcedBlinkoType) {
      if (kDebugMode)
        print(
          '[NotesNotifier] Skipped optimistic update for note ${updatedNote.id} due to type mismatch.',
        );
      // Optionally remove it if it somehow ended up in the list
      removeNoteOptimistically(updatedNote.id);
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
      print('[NotesNotifier] Optimistically updated note: ${updatedNote.id}');
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
          '[NotesNotifier] removeNoteOptimistically: Removed note $noteId.',
        );
    } else if (kDebugMode) {
      print(
        '[NotesNotifier] removeNoteOptimistically: Note $noteId not found.',
      );
    }
  }

  void archiveNoteOptimistically(String noteId) {
    if (!mounted) return;
    // Archiving removes the note from Cache/Vault views
    if (_forcedBlinkoType != null) {
      removeNoteOptimistically(noteId);
      if (kDebugMode)
        print(
          '[NotesNotifier] Optimistically removed archived note $noteId from Cache/Vault view.',
        );
    } else {
      // Standard archive logic for general views
      state = state.copyWith(
        notes:
            state.notes.map((note) {
              if (note.id == noteId)
                return note.copyWith(state: NoteState.archived, pinned: false);
              return note;
            }).toList(),
      );
      if (kDebugMode)
        print('[NotesNotifier] Optimistically archived note: $noteId');
    }
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
      print('[NotesNotifier] Optimistically toggled pin for note: $noteId');
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
        print('[NotesNotifier] Optimistically bumped note: $noteId');
    }
  }

  Future<void> updateNoteStartDate(
    String noteId,
    DateTime? newStartDate,
  ) async {
    if (!mounted) return;
    final noteIndex = state.notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) {
      if (kDebugMode)
        print('[NotesNotifier] Note $noteId not found for start date update.');
      return;
    }

    final originalNote = state.notes[noteIndex];
    if (newStartDate != null &&
        originalNote.endDate != null &&
        newStartDate.isAfter(originalNote.endDate!)) {
      if (kDebugMode)
        print(
          '[NotesNotifier] Cannot set start date ($newStartDate) after end date (${originalNote.endDate}) for note $noteId.',
        );
      return;
    }

    final updatedNote = originalNote.copyWith(
      startDate: newStartDate,
      updateTime: DateTime.now(),
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
        '[NotesNotifier] Optimistically updated start date for note $noteId to $newStartDate.',
      );

    try {
      final NoteApiService apiService = _apiService;
      final NoteItem confirmedNoteFromApi = await apiService.updateNote(
        noteId,
        updatedNote,
      );
      final NoteItem noteForStateUpdate = confirmedNoteFromApi.copyWith(
        startDate: newStartDate,
      );

      if (!mounted) return;

      // Check type match before updating state
      if (_forcedBlinkoType != null &&
          noteForStateUpdate.blinkoType != _forcedBlinkoType) {
        if (kDebugMode)
          print(
            '[NotesNotifier] Note $noteId type changed after API update. Removing from current view.',
          );
        removeNoteOptimistically(noteId);
        return;
      }


      final finalNotes = List<NoteItem>.from(state.notes);
      final confirmedIndex = finalNotes.indexWhere((n) => n.id == noteId);
      if (confirmedIndex != -1) {
        finalNotes[confirmedIndex] = noteForStateUpdate;
        finalNotes.sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          return b.updateTime.compareTo(a.updateTime);
        });
        state = state.copyWith(notes: finalNotes);
        if (kDebugMode)
          print(
            '[NotesNotifier] Confirmed start date update for note $noteId from API (merged state).',
          );
      } else {
        if (kDebugMode)
          print(
            '[NotesNotifier] Note $noteId disappeared after API update confirmation? Refreshing list.',
          );
        refresh();
      }
    } catch (e, stackTrace) {
      if (kDebugMode)
        print(
          '[NotesNotifier] Failed to update start date via API for note $noteId: $e\n$stackTrace',
        );
      if (!mounted) return;
      final revertedNotes = List<NoteItem>.from(state.notes);
      final revertIndex = revertedNotes.indexWhere((n) => n.id == noteId);
      if (revertIndex != -1) {
        revertedNotes[revertIndex] = originalNote;
        revertedNotes.sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          return b.updateTime.compareTo(a.updateTime);
        });
        state = state.copyWith(notes: revertedNotes);
        if (kDebugMode)
          print(
            '[NotesNotifier] Reverted optimistic start date update for note $noteId.',
          );
      }
    }
  }
}

// --- Provider Definitions ---

/// Generic Notes Notifier Provider - Use overrides for specific types (Cache/Vault)
final notesNotifierProvider = StateNotifierProvider<NotesNotifier, NotesState>((
  ref,
) {
  // This default instance fetches notes without a forced type.
  // It will be overridden by cacheNotesNotifierProvider/vaultNotesNotifierProvider
  // when used within CacheNotesScreen/VaultNotesScreen.
  return NotesNotifier(ref);
}, name: 'notesNotifierProvider');

/// Specific Notifier Provider for Cache Notes
final cacheNotesNotifierProvider =
    StateNotifierProvider<NotesNotifier, NotesState>((ref) {
      return NotesNotifier(ref, forcedBlinkoType: BlinkoNoteType.cache);
    }, name: 'cacheNotesNotifierProvider');

/// Specific Notifier Provider for Vault Notes
final vaultNotesNotifierProvider =
    StateNotifierProvider<NotesNotifier, NotesState>((ref) {
      return NotesNotifier(ref, forcedBlinkoType: BlinkoNoteType.vault);
    }, name: 'vaultNotesNotifierProvider');


// --- Derived Providers ---

// This provider now reflects the state of whichever notesNotifierProvider is active
// (either the generic one or an overridden one like cache/vault).
final _baseFilteredNotesProvider = Provider<List<NoteItem>>((ref) {
  final notesState = ref.watch(notesNotifierProvider);
  final selectedPresetKey = ref.watch(quickFilterPresetProvider);
  final forcedType = notesState.forcedBlinkoType; // Get forced type from state

  // If a type is forced (Cache/Vault), we primarily rely on the notifier fetching the correct type.
  // The state filter here is mainly for the generic provider.
  return notesState.notes.where((note) {
    if (forcedType != null) {
      // For Cache/Vault, notes should already be filtered by type and state=NORMAL by the notifier.
      // We just return true here, assuming the notifier did its job.
      // An extra check `note.blinkoType == forcedType && note.state != NoteState.archived` could be added for safety.
      return note.blinkoType == forcedType && note.state != NoteState.archived;
    } else {
      // Logic for the generic provider based on presets
      switch (selectedPresetKey) {
        case 'inbox':
        case 'all':
        case 'today':
        case 'tagged':
        case 'custom':
          // Removed 'cache', 'vault' cases
          return note.state != NoteState.archived;
        case 'archive':
          return note.state == NoteState.archived;
        case 'hidden':
          // Hidden view shows non-archived notes that meet hidden criteria (handled later)
          return note.state != NoteState.archived;
        default: // Assumed to be a tag filter
          return note.tags.contains(selectedPresetKey) &&
              note.state != NoteState.archived;
      }
    }
  }).toList();
}, name: '_baseFilteredNotesProvider');


final manuallyHiddenNoteCountProvider = Provider<int>((ref) {
  final baseNotes = ref.watch(_baseFilteredNotesProvider);
  final manuallyHiddenIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  return baseNotes.where((note) => manuallyHiddenIds.contains(note.id)).length;
}, name: 'manuallyHiddenNoteCountProvider');

final futureDatedHiddenNoteCountProvider = Provider<int>((ref) {
  final baseNotes = ref.watch(_baseFilteredNotesProvider);
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
}, name: 'futureDatedHiddenNoteCountProvider');

final totalHiddenNoteCountProvider = Provider<int>((ref) {
  final manualCount = ref.watch(manuallyHiddenNoteCountProvider);
  final futureCount = ref.watch(futureDatedHiddenNoteCountProvider);
  return manualCount + futureCount;
}, name: 'totalHiddenNoteCountProvider');

final isItemHiddenProvider = Provider.family<bool, String>((ref, id) {
  final hiddenItemIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  return hiddenItemIds.contains(id);
}, name: 'isItemHiddenProvider');

final toggleItemVisibilityProvider = Provider.family<void Function(), String>((
  ref,
  id,
) {
  return () {
    final manuallyHiddenIdsNotifier = ref.read(
      settings_p.manuallyHiddenNoteIdsProvider.notifier,
    );
    final currentHiddenIds = ref.read(settings_p.manuallyHiddenNoteIdsProvider);
    if (currentHiddenIds.contains(id)) {
      manuallyHiddenIdsNotifier.remove(id);
      if (kDebugMode)
        print('[toggleItemVisibilityProvider] Unhid item (manual): $id');
    } else {
      manuallyHiddenIdsNotifier.add(id);
      if (kDebugMode)
        print('[toggleItemVisibilityProvider] Hid item (manual): $id');
    }
    // Invalidate the currently active notifier (could be generic, cache, or vault)
    ref.invalidate(notesNotifierProvider);
  };
}, name: 'toggleItemVisibilityProvider');

final filteredNotesProvider = Provider<List<NoteItem>>((ref) {
  // Start with the notes already filtered by type/state from _baseFilteredNotesProvider
  List<NoteItem> currentList = ref.watch(_baseFilteredNotesProvider);
  final notesState = ref.watch(
    notesNotifierProvider,
  ); // Get state for forced type info
  final forcedType = notesState.forcedBlinkoType;

  final selectedPresetKey = ref.watch(quickFilterPresetProvider);
  final hidePinned = ref.watch(hidePinnedProvider);
  final showHiddenToggle = ref.watch(showHiddenNotesProvider);
  final manuallyHiddenIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();
  final now = DateTime.now();


  // Removed: State filtering based on preset (handled in _baseFilteredNotesProvider or by notifier)
  // if (selectedPresetKey == 'archive')
  //   currentList =
  //       currentList.where((note) => note.state == NoteState.archived).toList();
  // else if (selectedPresetKey != 'hidden') // Keep non-archived for hidden view base
  //   currentList =
  //       currentList.where((note) => note.state != NoteState.archived).toList();


  // Removed: Blinko Type filtering based on preset (handled by notifier/forcedType)
  // if (selectedPresetKey == 'cache') {
  //   currentList =
  //       currentList
  //           .where((note) => note.blinkoType == BlinkoNoteType.cache)
  //           .toList();
  // } else if (selectedPresetKey == 'vault') {
  //   currentList =
  //       currentList
  //           .where((note) => note.blinkoType == BlinkoNoteType.vault)
  //           .toList();
  // }

  // Filter by tags if a tag preset is selected (only applies if no forced type)
  if (forcedType == null) {
    if (![
      'all',
      'inbox',
      'archive',
      'today',
      'hidden',
      'custom',
      'tagged',
      // Removed 'cache', 'vault'
    ].contains(selectedPresetKey)) {
      currentList =
          currentList
              .where((note) => note.tags.contains(selectedPresetKey))
              .toList();
    } else if (selectedPresetKey == 'tagged') {
      currentList = currentList.where((note) => note.tags.isNotEmpty).toList();
    }
  }


  // Handle 'hidden' preset view (only applies if no forced type)
  if (forcedType == null && selectedPresetKey == 'hidden') {
    currentList =
        currentList.where((note) {
          // Base list for hidden view is already non-archived
          final isManuallyHidden = manuallyHiddenIds.contains(note.id);
          final isFutureDated =
              note.startDate != null && note.startDate!.isAfter(now);
          return isManuallyHidden || isFutureDated;
        }).toList();
  } else if (!showHiddenToggle) {
    // Hide manually hidden and future-dated notes if toggle is off (applies to all views)
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

  // Sort the final list
  currentList.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    // Use updateTime for sorting Cache/Vault, displayTime otherwise? Or always updateTime?
    // Let's stick to updateTime for consistency for now.
    final timeA = a.updateTime; // Changed from displayTime
    final timeB = b.updateTime; // Changed from displayTime
    return timeB.compareTo(timeA);
  });

  return currentList;
}, name: 'filteredNotesProvider');


final hasSearchResultsProvider = Provider<bool>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final filteredNotes = ref.watch(filteredNotesProvider);
  return searchQuery.isEmpty || filteredNotes.isNotEmpty;
}, name: 'hasSearchResultsProvider');

// --- Action Providers ---

final unhideNoteProvider = Provider.family<void Function(), String>((ref, id) {
  return () {
    if (kDebugMode) print('[unhideNoteProvider] Unhiding note: $id');
    ref.read(settings_p.manuallyHiddenNoteIdsProvider.notifier).remove(id);
    // Invalidate the currently active notifier
    ref.invalidate(notesNotifierProvider);
  };
}, name: 'unhideNoteProvider');

final unhideAllNotesProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    if (kDebugMode)
      print('[unhideAllNotesProvider] Clearing all manually hidden notes.');
    await ref.read(settings_p.manuallyHiddenNoteIdsProvider.notifier).clear();
    // Refresh the currently active notifier
    await ref.read(notesNotifierProvider.notifier).refresh();
  };
}, name: 'unhideAllNotesProvider');

final archiveNoteProvider = Provider.family<Future<void> Function(), String>((
  ref,
  noteId,
) {
  return () async {
    final apiService = _getNoteApiService(ref);
    final currentSelectedId = ref.read(ui_providers.selectedItemIdProvider);
    // Use the active notes provider to get notes before action
    final notesBeforeAction = ref.read(filteredNotesProvider);
    String? nextSelectedId = currentSelectedId;

    if (currentSelectedId == noteId && notesBeforeAction.isNotEmpty) {
      final actionIndex = notesBeforeAction.indexWhere((n) => n.id == noteId);
      if (actionIndex != -1) {
        if (notesBeforeAction.length == 1)
          nextSelectedId = null;
        else if (actionIndex < notesBeforeAction.length - 1)
          nextSelectedId = notesBeforeAction[actionIndex + 1].id;
        else
          nextSelectedId = notesBeforeAction[actionIndex - 1].id;
      } else
        nextSelectedId = null;
    }

    // Use the active notes provider's notifier
    ref.read(notesNotifierProvider.notifier).archiveNoteOptimistically(noteId);
    ref.read(ui_providers.selectedItemIdProvider.notifier).state =
        nextSelectedId;

    try {
      await apiService.archiveNote(noteId);
    } catch (e) {
      if (kDebugMode) print('[archiveNoteProvider] Error archiving note: $e');
      // Refresh the active notes provider
      await ref.read(notesNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
});

final deleteNoteProvider = Provider.family<Future<void> Function(), String>((
  ref,
  noteId,
) {
  return () async {
    if (kDebugMode) print('[deleteNoteProvider] Deleting note: $noteId');
    final apiService = _getNoteApiService(ref);
    final currentSelectedId = ref.read(ui_providers.selectedItemIdProvider);
    // Use the active notes provider
    final notesBeforeAction = ref.read(filteredNotesProvider);
    String? nextSelectedId = currentSelectedId;

    if (currentSelectedId == noteId && notesBeforeAction.isNotEmpty) {
      final actionIndex = notesBeforeAction.indexWhere((n) => n.id == noteId);
      if (actionIndex != -1) {
        if (notesBeforeAction.length == 1)
          nextSelectedId = null;
        else if (actionIndex < notesBeforeAction.length - 1)
          nextSelectedId = notesBeforeAction[actionIndex + 1].id;
        else
          nextSelectedId = notesBeforeAction[actionIndex - 1].id;
      } else
        nextSelectedId = null;
    }

    // Use the active notes provider's notifier
    ref.read(notesNotifierProvider.notifier).removeNoteOptimistically(noteId);
    ref.read(ui_providers.selectedItemIdProvider.notifier).state =
        nextSelectedId;

    try {
      await apiService.deleteNote(noteId);
      if (kDebugMode)
        print('[deleteNoteProvider] Successfully deleted note: $noteId');
      ref
          .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
          .remove(noteId);
    } catch (e, stackTrace) {
      if (kDebugMode)
        print(
          '[deleteNoteProvider] Error deleting note $noteId: $e\n$stackTrace',
        );
      // Refresh the active notes provider
      await ref.read(notesNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
});

final bumpNoteProvider = Provider.family<Future<void> Function(), String>((
  ref,
  noteId,
) {
  return () async {
    if (kDebugMode) print('[bumpNoteProvider] Bumping note: $noteId');
    final apiService = _getNoteApiService(ref);
    // Use the active notes provider's notifier
    ref.read(notesNotifierProvider.notifier).bumpNoteOptimistically(noteId);
    try {
      final NoteItem currentNote = await apiService.getNote(noteId);
      await apiService.updateNote(noteId, currentNote);
      if (kDebugMode)
        print('[bumpNoteProvider] Successfully bumped note: $noteId');
    } catch (e, stackTrace) {
      if (kDebugMode)
        print('[bumpNoteProvider] Error bumping note $noteId: $e\n$stackTrace');
      // Refresh the active notes provider
      await ref.read(notesNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
}, name: 'bumpNoteProvider');

final updateNoteProvider = Provider.family<
  Future<NoteItem> Function(NoteItem),
  String
>((ref, noteId) {
  return (NoteItem updatedNote) async {
    if (kDebugMode) print('[updateNoteProvider] Updating note: $noteId');
    final apiService = _getNoteApiService(ref);
    try {
      final NoteItem result = await apiService.updateNote(noteId, updatedNote);
      // Use the active notes provider's notifier
      ref.read(notesNotifierProvider.notifier).updateNoteOptimistically(result);
      ref
          .read(noteDetailCacheProvider.notifier)
          .update((state) => {...state, result.id: result});
      if (kDebugMode)
        print('[updateNoteProvider] Note $noteId updated successfully.');
      ref.invalidate(noteDetailProvider(noteId));
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode)
        print('[updateNoteProvider] Error updating note: $e\n$stackTrace');
      // Invalidate the active notes provider
      ref.invalidate(notesNotifierProvider);
      ref.invalidate(noteDetailProvider(noteId));
      rethrow;
    }
  };
});

final togglePinNoteProvider = Provider.family<
  Future<NoteItem> Function(),
  String
>((ref, noteId) {
  return () async {
    if (kDebugMode)
      print('[togglePinNoteProvider] Toggling pin state for note: $noteId');
    final apiService = _getNoteApiService(ref);
    // Use the active notes provider's notifier
    ref.read(notesNotifierProvider.notifier).togglePinOptimistically(noteId);
    try {
      final NoteItem result = await apiService.togglePinNote(noteId);
      ref
          .read(noteDetailCacheProvider.notifier)
          .update((state) => {...state, result.id: result});
      ref.invalidate(noteDetailProvider(noteId));
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode)
        print(
          '[togglePinNoteProvider] Error toggling pin state for note: $noteId\n$stackTrace',
        );
      // Refresh the active notes provider
      await ref.read(notesNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
});

// --- Removed Move Note Logic ---

// --- Detail/Comment Providers ---

final noteDetailCacheProvider = StateProvider<Map<String, NoteItem>>(
  (ref) => {},
  name: 'noteDetailCacheProvider',
);

final createNoteProvider = Provider<Future<void> Function(NoteItem)>((ref) {
  return (NoteItem note) async {
    final apiService = _getNoteApiService(ref);
    try {
      await apiService.createNote(note);
    } catch (e) {
      if (kDebugMode) print('[createNoteProvider] Error creating note: $e');
      rethrow;
    } finally {
      if (kDebugMode)
        print(
          '[createNoteProvider] Invalidating notesNotifierProvider after create attempt.',
        );
      // Invalidate the active notes provider
      ref.invalidate(notesNotifierProvider);
      // Also invalidate specific providers if they exist and might be relevant
      if (note.blinkoType == BlinkoNoteType.cache) {
        ref.invalidate(cacheNotesNotifierProvider);
      } else if (note.blinkoType == BlinkoNoteType.vault) {
        ref.invalidate(vaultNotesNotifierProvider);
      }
    }
  };
});


final fixNoteGrammarProvider = FutureProvider.family<void, String>((
  ref,
  noteId,
) async {
  if (kDebugMode)
    print('[fixNoteGrammarProvider] Starting grammar fix for note: $noteId');
  final notesApiService = _getNoteApiService(ref);
  final MinimalOpenAiService openaiApiService = ref.read(
    api_p.openaiApiServiceProvider,
  );
  final String selectedModelId = ref.read(settings_p.openAiModelIdProvider);

  if (!openaiApiService.isConfigured) {
    if (kDebugMode)
      print(
        '[fixNoteGrammarProvider] OpenAI service not configured. Aborting.',
      );
    throw Exception('OpenAI API key is not configured in settings.');
  }

  try {
    if (kDebugMode) print('[fixNoteGrammarProvider] Fetching note content...');
    final NoteItem currentNote = await notesApiService.getNote(noteId);
    final String originalContent = currentNote.content;
    if (originalContent.trim().isEmpty) {
      if (kDebugMode)
        print('[fixNoteGrammarProvider] Note content is empty. Skipping.');
      return;
    }

    if (kDebugMode)
      print(
        '[fixNoteGrammarProvider] Calling OpenAI API with model: $selectedModelId...',
      );
    final String correctedContent = await openaiApiService.fixGrammar(
      originalContent,
      modelId: selectedModelId,
    );
    if (correctedContent == originalContent ||
        correctedContent.trim().isEmpty) {
      if (kDebugMode)
        print(
          '[fixNoteGrammarProvider] Content unchanged or correction empty. No update needed.',
        );
      return;
    }

    if (kDebugMode)
      print('[fixNoteGrammarProvider] Content corrected. Updating note...');
    final NoteItem updatedNoteData = currentNote.copyWith(
      content: correctedContent,
    );
    final NoteItem resultNote = await notesApiService.updateNote(
      noteId,
      updatedNoteData,
    );

    // Use the active notes provider's notifier
    ref
        .read(notesNotifierProvider.notifier)
        .updateNoteOptimistically(resultNote);
    ref
        .read(noteDetailCacheProvider.notifier)
        .update((state) => {...state, noteId: resultNote});
    ref.invalidate(noteDetailProvider(noteId));

    if (kDebugMode)
      print(
        '[fixNoteGrammarProvider] Note $noteId updated successfully with corrected grammar.',
      );
  } catch (e, stackTrace) {
    if (kDebugMode)
      print(
        '[fixNoteGrammarProvider] Error fixing grammar for note $noteId: $e\n$stackTrace',
      );
    rethrow;
  }
});

final noteDetailProvider = FutureProvider.family<NoteItem, String>((
  ref,
  noteId,
) async {
  final apiService = _getNoteApiService(ref);
  return apiService.getNote(noteId);
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

final isFixingGrammarProvider = StateProvider<bool>(
  (ref) => false,
  name: 'isFixingGrammarProvider',
);
