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

  const NotesState({
    this.notes = const [],
    this.nextPageToken,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasReachedEnd = false,
    this.totalLoaded = 0,
  });

  NotesState copyWith({
    List<NoteItem>? notes,
    String? nextPageToken,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool? hasReachedEnd,
    int? totalLoaded,
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
        other.totalLoaded == totalLoaded;
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

  NotesNotifier(this._ref, {bool skipInitialFetchForTesting = false})
      : _skipInitialFetchForTesting = skipInitialFetchForTesting,
        super(const NotesState(isLoading: true)) {
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
    if (selectedPresetKey == 'inbox')
      stateFilter = 'NORMAL';
    else if (selectedPresetKey == 'archive')
      stateFilter = 'ARCHIVED';

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

    if (!usingRawFilter &&
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
      );

      response.notes.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updateTime.compareTo(a.updateTime);
      });

      var newNotes = response.notes;
      final nextPageToken = response.nextPageToken;
      final bool hasReachedEnd =
          (nextPageToken == null || nextPageToken.isEmpty);
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

final notesNotifierProvider = StateNotifierProvider<NotesNotifier, NotesState>((
  ref,
) {
  return NotesNotifier(ref);
}, name: 'notesNotifierProvider');


// --- Derived Providers ---

final _baseFilteredNotesProvider = Provider<List<NoteItem>>((ref) {
  final notesState = ref.watch(notesNotifierProvider);
  ref.watch(filterKeyProvider);
  final selectedPresetKey = ref.watch(quickFilterPresetProvider);

  return notesState.notes.where((note) {
    switch (selectedPresetKey) {
      case 'inbox':
      case 'all':
      case 'today':
      case 'tagged':
      case 'custom':
        return note.state != NoteState.archived;
      case 'archive':
        return note.state == NoteState.archived;
      case 'hidden':
        return note.state != NoteState.archived;
      default:
        return note.tags.contains(selectedPresetKey) &&
            note.state != NoteState.archived;
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
    ref.invalidate(notesNotifierProvider);
  };
}, name: 'toggleItemVisibilityProvider');

final filteredNotesProvider = Provider<List<NoteItem>>((ref) {
  final notesState = ref.watch(notesNotifierProvider);
  ref.watch(filterKeyProvider);
  final selectedPresetKey = ref.watch(quickFilterPresetProvider);
  final hidePinned = ref.watch(hidePinnedProvider);
  final showHiddenToggle = ref.watch(showHiddenNotesProvider);
  final manuallyHiddenIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();
  final now = DateTime.now();

  List<NoteItem> currentList = notesState.notes;

  if (selectedPresetKey == 'archive')
    currentList =
        currentList.where((note) => note.state == NoteState.archived).toList();
  else if (selectedPresetKey != 'hidden')
    currentList =
        currentList.where((note) => note.state != NoteState.archived).toList();

  if (![
    'all',
    'inbox',
    'archive',
    'today',
    'hidden',
    'custom',
    'tagged',
  ].contains(selectedPresetKey))
    currentList =
        currentList
            .where((note) => note.tags.contains(selectedPresetKey))
            .toList();
  else if (selectedPresetKey == 'tagged')
    currentList = currentList.where((note) => note.tags.isNotEmpty).toList();

  if (selectedPresetKey == 'hidden') {
    currentList =
        currentList.where((note) {
          if (note.state == NoteState.archived) return false;
          final isManuallyHidden = manuallyHiddenIds.contains(note.id);
          final isFutureDated =
              note.startDate != null && note.startDate!.isAfter(now);
          return isManuallyHidden || isFutureDated;
        }).toList();
  } else if (!showHiddenToggle) {
    currentList =
        currentList.where((note) {
          final isManuallyHidden = manuallyHiddenIds.contains(note.id);
          final isFutureDated =
              note.startDate != null && note.startDate!.isAfter(now);
          return !isManuallyHidden && !isFutureDated;
        }).toList();
  }

  if (hidePinned)
    currentList = currentList.where((note) => !note.pinned).toList();
  if (searchQuery.isNotEmpty)
    currentList =
        currentList
            .where((note) => note.content.toLowerCase().contains(searchQuery))
            .toList();

  currentList.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    final timeA = a.displayTime;
    final timeB = b.displayTime;
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
    ref.invalidate(notesNotifierProvider);
  };
}, name: 'unhideNoteProvider');

final unhideAllNotesProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    if (kDebugMode)
      print('[unhideAllNotesProvider] Clearing all manually hidden notes.');
    await ref.read(settings_p.manuallyHiddenNoteIdsProvider.notifier).clear();
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

    ref.read(notesNotifierProvider.notifier).archiveNoteOptimistically(noteId);
    ref.read(ui_providers.selectedItemIdProvider.notifier).state =
        nextSelectedId;

    try {
      await apiService.archiveNote(noteId);
    } catch (e) {
      if (kDebugMode) print('[archiveNoteProvider] Error archiving note: $e');
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
    ref.read(notesNotifierProvider.notifier).bumpNoteOptimistically(noteId);
    try {
      final NoteItem currentNote = await apiService.getNote(noteId);
      await apiService.updateNote(noteId, currentNote);
      if (kDebugMode)
        print('[bumpNoteProvider] Successfully bumped note: $noteId');
    } catch (e, stackTrace) {
      if (kDebugMode)
        print('[bumpNoteProvider] Error bumping note $noteId: $e\n$stackTrace');
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
      ref.invalidate(notesNotifierProvider);
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
