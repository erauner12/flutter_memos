import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/list_notes_response.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/api_providers.dart' as api_p;
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/services/base_api_service.dart';
import 'package:flutter_memos/services/minimal_openai_service.dart';
import 'package:flutter_memos/utils/comment_utils.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_provider.dart' as settings_p;

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

class NotesNotifier extends StateNotifier<NotesState> {
  final Ref _ref;
  static const int _pageSize = 20;
  final bool _skipInitialFetchForTesting;

  NotesNotifier(this._ref, {bool skipInitialFetchForTesting = false})
    : _skipInitialFetchForTesting = skipInitialFetchForTesting,
      super(const NotesState(isLoading: true)) {
    _ref.read(api_p.apiServiceProvider);
    _initialize();
  }

  void _initialize() {
    if (_skipInitialFetchForTesting) {
      if (kDebugMode) {
        print('[NotesNotifier] Skipping initialization for testing');
      }
      return;
    }

    _ref.listen<ServerConfig?>(activeServerConfigProvider, (previous, next) {
      if (mounted && previous?.id != next?.id) {
        if (kDebugMode) {
          print(
            '[NotesNotifier] Active server changed (Prev: \${previous?.id}, Next: \${next?.id}), triggering refresh.',
          );
        }
        refresh();
      }
    });
    _ref.listen(combinedFilterProvider, (_, __) {
      if (mounted) refresh();
    });
    _ref.listen(filterKeyProvider, (_, __) {
      if (mounted) refresh();
    });

    fetchInitialPage();
  }

  Future<void> _fetchPage({String? pageToken}) async {
    if (kDebugMode) {
      final activeServer = _ref.read(activeServerConfigProvider);
      final serviceRead = _ref.read(api_p.apiServiceProvider);
      print('[NotesNotifier._fetchPage] Attempting fetch.');
      print(
        '[NotesNotifier._fetchPage] Active Server: \${activeServer?.name} (ID: \${activeServer?.id}, Type: \${activeServer?.serverType.name})',
      );
      print(
        '[NotesNotifier._fetchPage] Reading apiServiceProvider, got instance of type: \${serviceRead.runtimeType}',
      );
    }

    final BaseApiService apiService = _ref.read(api_p.apiServiceProvider);
    final combinedFilter = _ref.read(combinedFilterProvider);
    final filterKey = _ref.read(filterKeyProvider);
    String stateFilter = '';
    if (filterKey == 'inbox') {
      stateFilter = 'NORMAL';
    } else if (filterKey == 'archive') {
      stateFilter = 'ARCHIVED';
    }

    final rawCelFilter = _ref.read(rawCelFilterProvider);
    bool usingRawFilter = rawCelFilter.isNotEmpty;
    String? finalFilter = combinedFilter.isNotEmpty ? combinedFilter : null;

    if (!usingRawFilter &&
        filterKey != 'all' &&
        filterKey != 'inbox' &&
        filterKey != 'archive') {
      final tagFilter = 'tag == "\$filterKey"';
      finalFilter =
          finalFilter == null
              ? tagFilter
              : FilterBuilder.and([finalFilter, tagFilter]);
    }

    if (kDebugMode) {
      print(
        '[NotesNotifier] Fetching page with filter: \$finalFilter, state: \$stateFilter, pageToken: \${pageToken ?? "null"}',
      );
      print(
        '[NotesNotifier] Current state: \${state.notes.length} notes, isLoading=\${state.isLoading}, isLoadingMore=\${state.isLoadingMore}, hasReachedEnd=\${state.hasReachedEnd}',
      );
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

      if (kDebugMode) {
        print(
          '[NotesNotifier] API Response: \${response.notes.length} notes received. Next page token: \${response.nextPageToken ?? "null"}',
        );
      }

      response.notes.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updateTime.compareTo(a.updateTime);
      });

      var newNotes = response.notes;
      final nextPageToken = response.nextPageToken;

      final bool hasReachedEnd =
          (nextPageToken == null || nextPageToken.isEmpty) &&
          newNotes.length < _pageSize;
      final newTotalLoaded =
          (pageToken == null)
              ? newNotes.length
              : state.totalLoaded + newNotes.length;

      if (kDebugMode) {
        print('[NotesNotifier] Fetched \${newNotes.length} new notes.');
        print('[NotesNotifier] nextPageToken: \${nextPageToken ?? "null"}');
        print('[NotesNotifier] hasReachedEnd: \$hasReachedEnd');
        print('[NotesNotifier] totalLoaded: \$newTotalLoaded');
      }

      final List<NoteItem> resultNotes;
      if (pageToken == null) {
        resultNotes = newNotes;
      } else {
        final Map<String, NoteItem> mergedNotes = {};
        for (final note in state.notes) {
          mergedNotes[note.id] = note;
        }
        for (final note in newNotes) {
          mergedNotes[note.id] = note;
        }
        resultNotes = mergedNotes.values.toList();
        resultNotes.sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          return b.updateTime.compareTo(a.updateTime);
        });
      }

      state = state.copyWith(
        notes: resultNotes,
        nextPageToken: nextPageToken,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
        hasReachedEnd: hasReachedEnd,
        totalLoaded: newTotalLoaded,
      );
    } catch (e, st) {
      if (kDebugMode) print('[NotesNotifier] Error fetching page: \$e\n\$st');
      state = state.copyWith(isLoading: false, isLoadingMore: false, error: e);
    }
  }

  Future<void> fetchInitialPage() async {
    state = state.copyWith(
      isLoading: true,
      notes: [],
      clearError: true,
      clearNextPageToken: true,
      hasReachedEnd: false,
      totalLoaded: 0,
    );
    await _fetchPage(pageToken: null);
  }

  Future<void> fetchMoreNotes() async {
    if (!state.canLoadMore && state.nextPageToken == null) {
      if (kDebugMode) {
        print(
          '[NotesNotifier] Cannot load more notes (no token or already loading/ended).',
        );
      }
      return;
    }
    if (state.isLoading || state.isLoadingMore || state.hasReachedEnd) {
      if (kDebugMode) {
        print('[NotesNotifier] Cannot load more notes (loading or ended).');
      }
      return;
    }

    if (kDebugMode) {
      print(
        '[NotesNotifier] Fetching more notes with token: \${state.nextPageToken}',
      );
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    await _fetchPage(pageToken: state.nextPageToken);
  }

  Future<void> refresh() async {
    if (kDebugMode) print('[NotesNotifier] Refresh triggered.');
    await fetchInitialPage();
  }

  void updateNoteOptimistically(NoteItem updatedNote) {
    final updatedNotes =
        state.notes.map((note) {
          return note.id == updatedNote.id ? updatedNote : note;
        }).toList();

    updatedNotes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updateTime.compareTo(a.updateTime);
    });

    state = state.copyWith(notes: updatedNotes);
  }

  void removeNoteOptimistically(String noteId) {
    final initialLength = state.notes.length;
    final updatedNotes =
        state.notes.where((note) => note.id != noteId).toList();

    if (kDebugMode) {
      if (updatedNotes.length < initialLength) {
        print(
          '[NotesNotifier] removeNoteOptimistically: Removed note \$noteId.',
        );
      } else {
        print(
          '[NotesNotifier] removeNoteOptimistically: Note \$noteId not found.',
        );
      }
    }

    if (updatedNotes.length < initialLength) {
      state = state.copyWith(notes: updatedNotes);
    }
  }

  void archiveNoteOptimistically(String noteId) {
    state = state.copyWith(
      notes:
          state.notes.map((note) {
            if (note.id == noteId) {
              return note.copyWith(state: NoteState.archived, pinned: false);
            }
            return note;
          }).toList(),
    );
  }

  void togglePinOptimistically(String noteId) {
    final updatedNotes =
        state.notes.map((note) {
          if (note.id == noteId) {
            return note.copyWith(pinned: !note.pinned);
          }
          return note;
        }).toList();

    updatedNotes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updateTime.compareTo(a.updateTime);
    });

    state = state.copyWith(notes: updatedNotes);
  }

  void bumpNoteOptimistically(String noteId) {
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
    }
  }

  Future<void> updateNoteStartDate(
    String noteId,
    DateTime? newStartDate,
  ) async {
    final noteIndex = state.notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) {
      if (kDebugMode)
        print('[NotesNotifier] Note \$noteId not found for start date update.');
      return;
    }

    final originalNote = state.notes[noteIndex];
    if (newStartDate != null &&
        originalNote.endDate != null &&
        newStartDate.isAfter(originalNote.endDate!)) {
      if (kDebugMode)
        print(
          '[NotesNotifier] Cannot set start date (\$newStartDate) after end date (\${originalNote.endDate}) for note \$noteId.',
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
        '[NotesNotifier] Optimistically updated start date for note \$noteId to \$newStartDate.',
      );

    try {
      final BaseApiService apiService = _ref.read(api_p.apiServiceProvider);
      final NoteItem confirmedNoteFromApi = await apiService.updateNote(
        noteId,
        updatedNote,
      );

      final NoteItem noteForStateUpdate = confirmedNoteFromApi.copyWith(
        startDate: newStartDate,
      );

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
            '[NotesNotifier] Confirmed start date update for note \$noteId from API (merged state).',
          );
      } else {
        if (kDebugMode)
          print(
            '[NotesNotifier] Note \$noteId disappeared after API update confirmation? Refreshing list.',
          );
        refresh();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[NotesNotifier] Failed to update start date via API for note \$noteId: \$e',
        );
        print(stackTrace);
      }
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
            '[NotesNotifier] Reverted optimistic start date update for note \$noteId.',
          );
      }
    }
  }
}

// Provider for notesNotifierProvider
final notesNotifierProvider = StateNotifierProvider<NotesNotifier, NotesState>((
  ref,
) {
  return NotesNotifier(ref);
}, name: 'notesNotifierProvider');

// --- Derived Providers ---

// --- Start Hidden Count Providers ---

final _baseFilteredNotesProvider = Provider<List<NoteItem>>((ref) {
  final notesState = ref.watch(notesNotifierProvider);
  final filterKey = ref.watch(filterKeyProvider);

  return notesState.notes.where((note) {
    switch (filterKey) {
      case 'inbox':
      case 'all':
        return note.state != NoteState.archived;
      case 'archive':
        return note.state == NoteState.archived;
      default:
        if (!['inbox', 'all', 'archive'].contains(filterKey)) {
          return note.tags.contains(filterKey) &&
              note.state != NoteState.archived;
        }
        return note.state != NoteState.archived;
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
  return baseNotes.where((note) {
    return !manuallyHiddenIds.contains(note.id) &&
        note.startDate != null &&
        note.startDate!.isAfter(now);
  }).length;
}, name: 'futureDatedHiddenNoteCountProvider');

final totalHiddenNoteCountProvider = Provider<int>((ref) {
  final manualCount = ref.watch(manuallyHiddenNoteCountProvider);
  final futureCount = ref.watch(futureDatedHiddenNoteCountProvider);
  final total = manualCount + futureCount;
  if (kDebugMode) {
    // print('[totalHiddenNoteCountProvider] Manual: \$manualCount, Future: \$futureCount, Total: \$total');
  }
  return total;
}, name: 'totalHiddenNoteCountProvider');

// --- End Hidden Count Providers ---

// Refactored filteredNotesProvider
final filteredNotesProvider = Provider<List<NoteItem>>((ref) {
  final notesState = ref.watch(notesNotifierProvider);
  final filterKey = ref.watch(filterKeyProvider);
  final hidePinned = ref.watch(hidePinnedProvider);
  final showHidden = ref.watch(showHiddenNotesProvider);
  final manuallyHiddenIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();
  final now = DateTime.now();

  List<NoteItem> currentList =
      notesState.notes.where((note) {
        if (hidePinned && note.pinned) return false;

        bool matchesFilterKey = false;
        switch (filterKey) {
          case 'inbox':
          case 'all':
            matchesFilterKey = note.state != NoteState.archived;
            break;
          case 'archive':
            matchesFilterKey = note.state == NoteState.archived;
            break;
          default:
            if (!['inbox', 'all', 'archive'].contains(filterKey)) {
              matchesFilterKey =
                  note.tags.contains(filterKey) &&
                  note.state != NoteState.archived;
            } else {
              matchesFilterKey = note.state != NoteState.archived;
            }
            break;
        }
        return matchesFilterKey;
      }).toList();

  if (!showHidden) {
    currentList =
        currentList.where((note) {
          final isManuallyHidden = manuallyHiddenIds.contains(note.id);
          final isFutureDated =
              note.startDate != null && note.startDate!.isAfter(now);
          return !isManuallyHidden && !isFutureDated;
        }).toList();
    if (kDebugMode) {
      // print('[filteredNotesProvider] Hiding hidden notes. Count after filter: \${currentList.length}');
    }
  } else {
    if (kDebugMode) {
      // print('[filteredNotesProvider] Showing hidden notes. Count before search: \${currentList.length}');
    }
  }

  if (searchQuery.isNotEmpty) {
    final initialCount = currentList.length;
    currentList =
        currentList.where((note) {
          return note.content.toLowerCase().contains(searchQuery);
        }).toList();
    if (kDebugMode) {
      print(
        '[filteredNotesProvider] Filtered by search query "\$searchQuery" from \$initialCount to \${currentList.length} notes.',
      );
    }
  }

  currentList.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    final timeA = a.displayTime;
    final timeB = b.displayTime;
    return timeB.compareTo(timeA);
  });

  if (kDebugMode) {
    // print('[filteredNotesProvider] Final sorted list count: \${currentList.length}');
  }
  return currentList;
}, name: 'filteredNotesProvider');

final hasSearchResultsProvider = Provider<bool>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final filteredNotes = ref.watch(filteredNotesProvider);
  return searchQuery.isEmpty || filteredNotes.isNotEmpty;
}, name: 'hasSearchResultsProvider');

// --- Action Providers ---

final archiveNoteProvider = Provider.family<Future<void> Function(), String>((
  ref,
  id,
) {
  return () async {
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);
    final currentSelectedId = ref.read(ui_providers.selectedItemIdProvider);
    final notesBeforeAction = ref.read(filteredNotesProvider);
    String? nextSelectedId = currentSelectedId;

    if (currentSelectedId == id && notesBeforeAction.isNotEmpty) {
      final actionIndex = notesBeforeAction.indexWhere((n) => n.id == id);
      if (actionIndex != -1) {
        if (notesBeforeAction.length == 1) {
          nextSelectedId = null;
        } else if (actionIndex < notesBeforeAction.length - 1) {
          nextSelectedId = notesBeforeAction[actionIndex + 1].id;
        } else {
          nextSelectedId = notesBeforeAction[actionIndex - 1].id;
        }
      } else {
        nextSelectedId = null;
      }
    }

    ref.read(notesNotifierProvider.notifier).archiveNoteOptimistically(id);
    ref.read(ui_providers.selectedItemIdProvider.notifier).state =
        nextSelectedId;

    try {
      await apiService.archiveNote(id);
    } catch (e) {
      if (kDebugMode) print('[archiveNoteProvider] Error archiving note: \$e');
      await ref.read(notesNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
});

final deleteNoteProvider = Provider.family<Future<void> Function(), String>((
  ref,
  id,
) {
  return () async {
    if (kDebugMode) print('[deleteNoteProvider] Deleting note: \$id');
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);
    final currentSelectedId = ref.read(ui_providers.selectedItemIdProvider);
    final notesBeforeAction = ref.read(filteredNotesProvider);
    String? nextSelectedId = currentSelectedId;

    if (currentSelectedId == id && notesBeforeAction.isNotEmpty) {
      final actionIndex = notesBeforeAction.indexWhere((n) => n.id == id);
      if (actionIndex != -1) {
        if (notesBeforeAction.length == 1) {
          nextSelectedId = null;
        } else if (actionIndex < notesBeforeAction.length - 1) {
          nextSelectedId = notesBeforeAction[actionIndex + 1].id;
        } else {
          nextSelectedId = notesBeforeAction[actionIndex - 1].id;
        }
      } else {
        nextSelectedId = null;
      }
    }

    ref.read(notesNotifierProvider.notifier).removeNoteOptimistically(id);
    ref.read(ui_providers.selectedItemIdProvider.notifier).state =
        nextSelectedId;

    try {
      await apiService.deleteNote(id);
      if (kDebugMode)
        print('[deleteNoteProvider] Successfully deleted note: \$id');
      ref.read(settings_p.manuallyHiddenNoteIdsProvider.notifier).remove(id);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[deleteNoteProvider] Error deleting note \$id: \$e');
        print(stackTrace);
      }
      await ref.read(notesNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
});

final bumpNoteProvider = Provider.family<Future<void> Function(), String>((
  ref,
  id,
) {
  return () async {
    if (kDebugMode) print('[bumpNoteProvider] Bumping note: \$id');
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);

    ref.read(notesNotifierProvider.notifier).bumpNoteOptimistically(id);
    try {
      final NoteItem currentNote = await apiService.getNote(id);
      await apiService.updateNote(id, currentNote);
      if (kDebugMode)
        print('[bumpNoteProvider] Successfully bumped note: \$id');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[bumpNoteProvider] Error bumping note \$id: \$e');
        print(stackTrace);
      }
      await ref.read(notesNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
}, name: 'bumpNote');

final updateNoteProvider =
    Provider.family<Future<NoteItem> Function(NoteItem), String>((ref, id) {
  return (NoteItem updatedNote) async {
    if (kDebugMode) print('[updateNoteProvider] Updating note: \$id');
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);

    try {
      final NoteItem result = await apiService.updateNote(id, updatedNote);
      ref.read(notesNotifierProvider.notifier).updateNoteOptimistically(result);
      ref
          .read(noteDetailCacheProvider.notifier)
          .update((state) => {...state, result.id: result});
      if (kDebugMode)
        print('[updateNoteProvider] Note \$id updated successfully.');
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[updateNoteProvider] Error updating note: \$e\n\$stackTrace');
      }
      ref.invalidate(notesNotifierProvider);
      ref.invalidate(noteDetailProvider(id));
      rethrow;
    }
  };
});

final togglePinNoteProvider = Provider.family<
  Future<NoteItem> Function(),
  String
>((ref, id) {
  return () async {
    if (kDebugMode)
      print('[togglePinNoteProvider] Toggling pin state for note: \$id');
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);

    ref.read(notesNotifierProvider.notifier).togglePinOptimistically(id);

    try {
      final NoteItem result = await apiService.togglePinNote(id);
      ref
          .read(noteDetailCacheProvider.notifier)
          .update((state) => {...state, result.id: result});
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[togglePinNoteProvider] Error toggling pin state for note: \$id\n\$stackTrace',
        );
      }
      await ref.read(notesNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
});

// --- Move Note Logic ---

@immutable
class MoveNoteParams {
  final String noteId;
  final ServerConfig targetServer;

  const MoveNoteParams({required this.noteId, required this.targetServer});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveNoteParams &&
          runtimeType == other.runtimeType &&
          noteId == other.noteId &&
          targetServer == other.targetServer;

  @override
  int get hashCode => noteId.hashCode ^ targetServer.hashCode;
}

final moveNoteProvider = Provider.family<
  Future<void> Function(),
  MoveNoteParams
>((ref, params) {
  return () async {
    final noteId = params.noteId;
    final targetServer = params.targetServer;
    final BaseApiService sourceApiService = ref.read(api_p.apiServiceProvider);
    final notifier = ref.read(notesNotifierProvider.notifier);
    final sourceServer = ref.read(activeServerConfigProvider);

    if (sourceServer == null) {
      throw Exception('Cannot move note: No active source server.');
    }
    if (sourceServer.id == targetServer.id) {
      throw Exception(
        'Cannot move note: Source and target servers are the same.',
      );
    }

    if (kDebugMode) {
      print(
        '[moveNoteProvider] Starting move for note \$noteId from \${sourceServer.name ?? sourceServer.id} (\${sourceServer.serverType.name}) to \${targetServer.name ?? targetServer.id} (\${targetServer.serverType.name})',
      );
    }

    notifier.removeNoteOptimistically(noteId);

    NoteItem sourceNote;
    List<Comment> sourceComments = [];
    NoteItem? createdNoteOnTarget;

    try {
      if (kDebugMode)
        print('[moveNoteProvider] Fetching note details from source...');
      sourceNote = await sourceApiService.getNote(noteId);

      if (kDebugMode)
        print('[moveNoteProvider] Fetching comments from source...');
      try {
        sourceComments = await sourceApiService.listNoteComments(noteId);
        if (kDebugMode)
          print(
            '[moveNoteProvider] Found \${sourceComments.length} comments on source.',
          );
      } catch (e) {
        if (kDebugMode)
          print(
            '[moveNoteProvider] Warning: Failed to fetch comments from source: \$e. Proceeding without comments.',
          );
        sourceComments = [];
      }

      if (kDebugMode)
        print('[moveNoteProvider] Creating note on target server...');
      final noteToCreate = NoteItem(
        id: '',
        content: sourceNote.content,
        pinned: sourceNote.pinned,
        state: sourceNote.state,
        visibility: sourceNote.visibility,
        createTime: sourceNote.createTime,
        updateTime: DateTime.now(),
        displayTime: sourceNote.displayTime,
        tags: sourceNote.tags,
        resources: [],
        relations: [],
        creatorId: sourceNote.creatorId,
        parentId: sourceNote.parentId,
      );
      createdNoteOnTarget = await sourceApiService.createNote(
        noteToCreate,
        targetServerOverride: targetServer,
      );
      if (kDebugMode)
        print(
          '[moveNoteProvider] Note created on target with ID: \${createdNoteOnTarget.id}',
        );

      if (sourceComments.isNotEmpty) {
        if (kDebugMode)
          print(
            '[moveNoteProvider] Creating \${sourceComments.length} comments on target...',
          );
        for (final comment in sourceComments) {
          try {
            final commentToCreate = Comment(
              id: '',
              content: comment.content,
              creatorId: comment.creatorId,
              createTime: comment.createTime,
              state: comment.state,
              pinned: comment.pinned,
              resources: null,
            );
            await sourceApiService.createNoteComment(
              createdNoteOnTarget.id,
              commentToCreate,
              targetServerOverride: targetServer,
            );
          } catch (e) {
            if (kDebugMode)
              print(
                '[moveNoteProvider] Warning: Failed to create comment (original ID: \${comment.id}) on target: \$e',
              );
          }
        }
        if (kDebugMode)
          print('[moveNoteProvider] Finished creating comments on target.');
      }

      if (kDebugMode)
        print('[moveNoteProvider] Deleting note from source server...');
      await sourceApiService.deleteNote(noteId);
      if (kDebugMode)
        print(
          '[moveNoteProvider] Note \$noteId successfully deleted from source.',
        );

      if (kDebugMode)
        print(
          '[moveNoteProvider] Move completed successfully for note \$noteId.',
        );
    } catch (e, st) {
      if (kDebugMode) {
        print(
          '[moveNoteProvider] Error during move operation for note \$noteId: \$e',
        );
        print(st);
      }
      await notifier.refresh();
      rethrow;
    }
  };
}, name: 'moveNoteProvider');

// --- Item Visibility ---

// REMOVED: hiddenItemIdsProvider (replaced by settings_provider.manuallyHiddenNoteIdsProvider)

// Rename isNoteHiddenProvider to isItemHiddenProvider
final isItemHiddenProvider = Provider.family<bool, String>((ref, id) {
  // Use the new persistent provider from settings_provider
  final hiddenItemIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  return hiddenItemIds.contains(id);
}, name: 'isItemHiddenProvider');

// Rename toggleNoteVisibilityProvider to toggleItemVisibilityProvider
final toggleItemVisibilityProvider = Provider.family<void Function(), String>((
  ref,
  id,
) {
  return () {
    // Use the new persistent provider's notifier
    final manuallyHiddenIdsNotifier = ref.read(
      settings_p.manuallyHiddenNoteIdsProvider.notifier,
    );
    final currentHiddenIds = ref.read(settings_p.manuallyHiddenNoteIdsProvider);

    if (currentHiddenIds.contains(id)) {
      manuallyHiddenIdsNotifier.remove(id);
      if (kDebugMode)
        print('[toggleItemVisibilityProvider] Unhid item (manual): \$id');
    } else {
      manuallyHiddenIdsNotifier.add(id);
      if (kDebugMode)
        print('[toggleItemVisibilityProvider] Hid item (manual): \$id');
    }
  };
}, name: 'toggleItemVisibilityProvider');

// --- Batch Operations ---

enum BatchOperation { archive, delete, pin, unpin }

final batchNoteOperationsProvider = Provider<
  Future<void> Function(List<String> ids, BatchOperation operation)
>((ref) {
  return (List<String> ids, BatchOperation operation) async {
    if (ids.isEmpty) return;
    if (kDebugMode)
      print(
        '[batchNoteOperationsProvider] Performing \$operation on \${ids.length} notes',
      );
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);

    try {
      await Future.wait(
        ids.map((id) async {
          switch (operation) {
            case BatchOperation.archive:
              await apiService.archiveNote(id);
              break;
            case BatchOperation.delete:
              await apiService.deleteNote(id);
              break;
            case BatchOperation.pin:
              await apiService.togglePinNote(id);
              break;
            case BatchOperation.unpin:
              await apiService.togglePinNote(id);
              break;
          }
        }),
      );

      await ref.read(notesNotifierProvider.notifier).refresh();
    } catch (e, stackTrace) {
      if (kDebugMode)
        print(
          '[batchNoteOperationsProvider] Error during batch operation: \$e\n\$stackTrace',
        );
      rethrow;
    }
  };
}, name: 'batchNoteOperationsProvider');

// --- Multi-Select ---

final selectedItemIdsProvider = StateProvider<Set<String>>(
  (ref) => {},
  name: 'selectedItemIdsProvider',
);

final itemSelectionModeProvider = StateProvider<bool>(
  (ref) => false,
  name: 'itemSelectionModeProvider',
);

final toggleItemSelectionModeProvider = Provider<void Function()>((ref) {
  return () {
    final currentMode = ref.read(itemSelectionModeProvider);
    if (currentMode) {
      ref.read(selectedItemIdsProvider.notifier).state = {};
    }
    ref.read(itemSelectionModeProvider.notifier).state = !currentMode;
    if (kDebugMode)
      print(
        '[toggleItemSelectionModeProvider] Selection mode: \${!currentMode}',
      );
  };
}, name: 'toggleItemSelectionModeProvider');

// --- Caching and Prefetching ---

final noteDetailCacheProvider = StateProvider<Map<String, NoteItem>>(
  (ref) => {},
  name: 'noteDetailCacheProvider',
);

final prefetchNoteDetailsProvider = Provider<
  Future<void> Function(List<String>)
>((ref) {
  return (List<String> ids) async {
    if (ids.isEmpty) return;
    if (kDebugMode)
      print('[prefetchNoteDetailsProvider] Prefetching \${ids.length} notes');
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);
    final cache = ref.read(noteDetailCacheProvider);
    final uncachedIds = ids.where((id) => !cache.containsKey(id)).toList();
    if (uncachedIds.isEmpty) return;
    const batchSize = 5;
    for (var i = 0; i < uncachedIds.length; i += batchSize) {
      final end =
          (i + batchSize < uncachedIds.length)
              ? i + batchSize
              : uncachedIds.length;
      final batch = uncachedIds.sublist(i, end);
      try {
        final List<NoteItem> notes = await Future.wait(
          batch.map((id) => apiService.getNote(id)),
        );
        final updatedCache = Map<String, NoteItem>.from(cache);
        for (var note in notes) {
          updatedCache[note.id] = note;
        }
        ref.read(noteDetailCacheProvider.notifier).state = updatedCache;
      } catch (e) {
        if (kDebugMode)
          print('[prefetchNoteDetailsProvider] Error prefetching batch: \$e');
      }
      if (end < uncachedIds.length)
        await Future.delayed(const Duration(milliseconds: 100));
    }
  };
}, name: 'prefetchNoteDetailsProvider');

// --- Create and AI Actions ---

final createNoteProvider = Provider<Future<void> Function(NoteItem)>((ref) {
  final BaseApiService apiService = ref.watch(api_p.apiServiceProvider);
  return (NoteItem note) async {
    try {
      await apiService.createNote(note);
    } catch (e) {
      if (kDebugMode) {
        print('[createNoteProvider] Error creating note: \$e');
      }
      rethrow;
    } finally {
      if (kDebugMode) {
        print(
          '[createNoteProvider] Invalidating notesNotifierProvider after create attempt.',
        );
      }
      ref.invalidate(notesNotifierProvider);
    }
  };
});

final fixNoteGrammarProvider = FutureProvider.family<void, String>((
  ref,
  noteId,
) async {
  if (kDebugMode)
    print('[fixNoteGrammarProvider] Starting grammar fix for note: \$noteId');

  final BaseApiService notesApiService = ref.read(api_p.apiServiceProvider);
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
        '[fixNoteGrammarProvider] Calling OpenAI API with model: \$selectedModelId...',
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

    if (kDebugMode) {
      print(
        '[fixNoteGrammarProvider] Note \$noteId updated successfully with corrected grammar.',
      );
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print(
        '[fixNoteGrammarProvider] Error fixing grammar for note \$noteId: \$e',
      );
      print(stackTrace);
    }
    rethrow;
  }
});

// --- Consolidated Detail Providers ---

final noteDetailProvider = FutureProvider.family<NoteItem, String>((
  ref,
  id,
) async {
  final apiService = ref.watch(api_p.apiServiceProvider);
  return apiService.getNote(id);
}, name: 'noteDetailProvider');

final noteCommentsProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  noteId,
) async {
  final apiService = ref.watch(api_p.apiServiceProvider);
  final comments = await apiService.listNoteComments(noteId);
  CommentUtils.sortByPinnedThenUpdateTime(comments);
  return comments;
}, name: 'noteCommentsProvider');

final isFixingGrammarProvider = StateProvider<bool>(
  (ref) => false,
  name: 'isFixingGrammarProvider',
);
