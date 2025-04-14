import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/list_notes_response.dart';
// import 'package:flutter_memos/models/memo.dart'; // Removed old Memo import
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/models/server_config.dart'; // Import ServerConfig
import 'package:flutter_memos/providers/api_providers.dart' as api_p;
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_detail_provider.dart'; // Keep for now, might rename later
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
// Import BaseApiService instead of concrete ApiService
import 'package:flutter_memos/services/base_api_service.dart';
import 'package:flutter_memos/services/minimal_openai_service.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_provider.dart' as settings_p;

// Rename state class and use NoteItem
@immutable
class NotesState {
  final List<NoteItem> notes; // Changed from Memo to NoteItem
  final String? nextPageToken;
  final bool isLoading; // Initial loading state
  final bool isLoadingMore; // Loading subsequent pages
  final Object? error;
  final bool hasReachedEnd; // True if no more pages
  final int totalLoaded; // Track total notes loaded

  const NotesState({
    this.notes = const [],
    this.nextPageToken,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasReachedEnd = false,
    this.totalLoaded = 0,
  });

  // copyWith method for easier state updates using NoteItem
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
      nextPageToken: clearNextPageToken ? null : (nextPageToken ?? this.nextPageToken),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      totalLoaded: totalLoaded ?? this.totalLoaded,
    );
  }

  // Convenience method to check if we can load more; removed token check as Blinko might not use it
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

@immutable
class MoveMemoParams {
  final String memoId;
  final ServerConfig targetServer;

  const MoveMemoParams({required this.memoId, required this.targetServer});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveMemoParams &&
          runtimeType == other.runtimeType &&
          memoId == other.memoId &&
          targetServer == other.targetServer;

  @override
  int get hashCode => memoId.hashCode ^ targetServer.hashCode;
}

final hiddenMemoIdsProvider = StateProvider<Set<String>>((ref) => {});
final hidePinnedProvider = StateProvider<bool>(
  (ref) => false,
  name: 'hidePinnedProvider',
);

// --- Start Pagination Notifier ---

// Rename Notifier class and update state type to use NoteItem
class NotesNotifier extends StateNotifier<NotesState> {
  final Ref _ref;
  static const int _pageSize = 20;
  final bool _skipInitialFetchForTesting;

  NotesNotifier(this._ref, {bool skipInitialFetchForTesting = false})
      : _skipInitialFetchForTesting = skipInitialFetchForTesting,
        super(const NotesState(isLoading: true)) {
    // Ensure BaseApiService is read
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

    // *** MODIFY LISTENERS ***
    // Listen directly to the active server config changing
    _ref.listen<ServerConfig?>(activeServerConfigProvider, (previous, next) {
      // Refresh only if the active server ID actually changes
      // Also check if the notifier is still mounted
      if (mounted && previous?.id != next?.id) {
        if (kDebugMode) {
          print(
            '[NotesNotifier] Active server changed (Prev: ${previous?.id}, Next: ${next?.id}), triggering refresh.',
          );
        }
        refresh(); // Call refresh when active server changes
      }
    },
    );
    // Keep other listeners if needed (filters)
    _ref.listen(combinedFilterProvider, (_, __) {
      if (mounted) refresh();
    });
    _ref.listen(filterKeyProvider, (_, __) {
      if (mounted) refresh();
    });
    // *** END MODIFIED LISTENERS ***

    fetchInitialPage();
  }

  Future<void> _fetchPage({String? pageToken}) async {
    // *** ADD THIS LOGGING BLOCK ***
    if (kDebugMode) {
      final activeServer = _ref.read(activeServerConfigProvider);
      final serviceRead = _ref.read(api_p.apiServiceProvider);
      print('[NotesNotifier._fetchPage] Attempting fetch.');
      print(
        '[NotesNotifier._fetchPage] Active Server: ${activeServer?.name} (ID: ${activeServer?.id}, Type: ${activeServer?.serverType.name})',
      );
      print(
        '[NotesNotifier._fetchPage] Reading apiServiceProvider, got instance of type: ${serviceRead.runtimeType}',
      );
    }
    // *** END ADDED LOGGING BLOCK ***

    // Read BaseApiService
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
      final tagFilter = 'tag == "$filterKey"';
      finalFilter =
          finalFilter == null
              ? tagFilter
              : FilterBuilder.and([finalFilter, tagFilter]);
    }

    if (kDebugMode) {
      print(
        '[NotesNotifier] Fetching page with filter: $finalFilter, state: $stateFilter, pageToken: ${pageToken ?? "null"}',
      );
      print(
        '[NotesNotifier] Current state: ${state.notes.length} notes, isLoading=${state.isLoading}, isLoadingMore=${state.isLoadingMore}, hasReachedEnd=${state.hasReachedEnd}',
      );
    }

    try {
      // Call listNotes on BaseApiService; assume it returns ListNotesResponse with notes and nextPageToken
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
          '[NotesNotifier] API Response: ${response.notes.length} notes received. Next page token: ${response.nextPageToken ?? "null"}',
        );
      }

      // Sort client-side by pinned then updateTime (descending)
      response.notes.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updateTime.compareTo(a.updateTime);
      });

      var newNotes = response.notes;
      final nextPageToken = response.nextPageToken;

      final bool hasReachedEnd = (nextPageToken == null || nextPageToken.isEmpty) && newNotes.length < _pageSize;
      final newTotalLoaded = (pageToken == null) ? newNotes.length : state.totalLoaded + newNotes.length;

      if (kDebugMode) {
        print('[NotesNotifier] Fetched ${newNotes.length} new notes.');
        print('[NotesNotifier] nextPageToken: ${nextPageToken ?? "null"}');
        print('[NotesNotifier] hasReachedEnd: $hasReachedEnd');
        print('[NotesNotifier] totalLoaded: $newTotalLoaded');
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
      if (kDebugMode) print('[NotesNotifier] Error fetching page: $e\n$st');
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

  Future<void> fetchMoreMemos() async {
    // Check can load more, with explicit additional check for token if needed
    if (!state.canLoadMore && state.nextPageToken == null) {
      if (kDebugMode) {
        print('[NotesNotifier] Cannot load more notes (no token or already loading/ended).');
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
      print('[NotesNotifier] Fetching more notes with token: ${state.nextPageToken}');
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    await _fetchPage(pageToken: state.nextPageToken);
  }

  Future<void> refresh() async {
    if (kDebugMode) print('[NotesNotifier] Refresh triggered.');
    await fetchInitialPage();
  }

  // Update optimistic methods to use NoteItem
  void updateNoteOptimistically(NoteItem updatedNote) {
    final updatedNotes = state.notes.map((note) {
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
    final updatedNotes = state.notes.where((note) => note.id != noteId).toList();

    if (kDebugMode) {
      if (updatedNotes.length < initialLength) {
        print('[NotesNotifier] removeNoteOptimistically: Removed note $noteId.');
      } else {
        print('[NotesNotifier] removeNoteOptimistically: Note $noteId not found.');
      }
    }

    if (updatedNotes.length < initialLength) {
      state = state.copyWith(notes: updatedNotes);
    }
  }

  void archiveNoteOptimistically(String noteId) {
    state = state.copyWith(
      notes: state.notes.map((note) {
        if (note.id == noteId) {
          return note.copyWith(state: NoteState.archived, pinned: false);
        }
        return note;
      }).toList(),
    );
  }

  void togglePinOptimistically(String noteId) {
    final updatedNotes = state.notes.map((note) {
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
}

// --- End Pagination Notifier ---

// Rename provider and update types
final notesNotifierProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier(ref);
}, name: 'notesNotifierProvider');

// Rename provider for visible notes list
final visibleNotesListProvider = Provider<List<NoteItem>>((ref) {
  final notesState = ref.watch(notesNotifierProvider);
  final hiddenMemoIds = ref.watch(hiddenMemoIdsProvider);
  final hidePinned = ref.watch(hidePinnedProvider);
  final filterKey = ref.watch(filterKeyProvider);

  final visibleNotes = notesState.notes.where((note) {
    if (hiddenMemoIds.contains(note.id)) return false;
    if (hidePinned && note.pinned) return false;

    switch (filterKey) {
      case 'inbox':
      case 'all':
        if (note.state == NoteState.archived) return false;
        break;
      case 'archive':
        if (note.state != NoteState.archived) return false;
        break;
    }
    return true;
  }).toList();

  visibleNotes.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return b.updateTime.compareTo(a.updateTime);
  });

  return visibleNotes;
}, name: 'visibleNotesListProvider');

// Rename provider for filtered notes
final filteredNotesProvider = Provider<List<NoteItem>>((ref) {
  final visibleNotes = ref.watch(visibleNotesListProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();

  if (searchQuery.isEmpty) return visibleNotes;

  final filteredNotes = visibleNotes.where((note) {
    return note.content.toLowerCase().contains(searchQuery);
  }).toList();

  if (kDebugMode) {
    print('[filteredNotesProvider] Filtered to ${filteredNotes.length} notes with query: "$searchQuery"');
  }
  return filteredNotes;
}, name: 'filteredNotesProvider');

final hasSearchResultsProvider = Provider<bool>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final filteredNotes = ref.watch(filteredNotesProvider);
  return searchQuery.isEmpty || filteredNotes.isNotEmpty;
}, name: 'hasSearchResultsProvider');

// --- Update Action Providers ---

final archiveNoteProvider = Provider.family<Future<void> Function(), String>((ref, id) {
  return () async {
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);
    final currentSelectedId = ref.read(ui_providers.selectedMemoIdProvider);
    final notesBeforeAction = ref.read(filteredNotesProvider);
    String? nextSelectedId = currentSelectedId;

    if (currentSelectedId == id && notesBeforeAction.isNotEmpty) {
      final actionIndex = notesBeforeAction.indexWhere((n) => n.id == id);
      if (actionIndex != -1) {
        if (notesBeforeAction.length == 1) {
          nextSelectedId = null;
        } else if (actionIndex < notesBeforeAction.length - 1)
          nextSelectedId = notesBeforeAction[actionIndex + 1].id;
        else
          nextSelectedId = notesBeforeAction[actionIndex - 1].id;
      } else {
        nextSelectedId = null;
      }
    }

    ref.read(notesNotifierProvider.notifier).archiveNoteOptimistically(id);
    ref.read(ui_providers.selectedMemoIdProvider.notifier).state = nextSelectedId;

    try {
      await apiService.archiveNote(id);
    } catch (e) {
      if (kDebugMode) print('[archiveNoteProvider] Error archiving note: $e');
      await ref.read(notesNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
});

final deleteNoteProvider = Provider.family<Future<void> Function(), String>((ref, id) {
  return () async {
    if (kDebugMode) print('[deleteNoteProvider] Deleting note: $id');
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);
    final currentSelectedId = ref.read(ui_providers.selectedMemoIdProvider);
    final notesBeforeAction = ref.read(filteredNotesProvider);
    String? nextSelectedId = currentSelectedId;

    if (currentSelectedId == id && notesBeforeAction.isNotEmpty) {
      final actionIndex = notesBeforeAction.indexWhere((n) => n.id == id);
      if (actionIndex != -1) {
        if (notesBeforeAction.length == 1) {
          nextSelectedId = null;
        } else if (actionIndex < notesBeforeAction.length - 1)
          nextSelectedId = notesBeforeAction[actionIndex + 1].id;
        else
          nextSelectedId = notesBeforeAction[actionIndex - 1].id;
      } else {
        nextSelectedId = null;
      }
    }

    ref.read(notesNotifierProvider.notifier).removeNoteOptimistically(id);
    ref.read(ui_providers.selectedMemoIdProvider.notifier).state = nextSelectedId;

    try {
      await apiService.deleteNote(id);
      if (kDebugMode) print('[deleteNoteProvider] Successfully deleted note: $id');
      ref.read(hiddenMemoIdsProvider.notifier).update((state) => state.contains(id) ? (state..remove(id)) : state);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[deleteNoteProvider] Error deleting note $id: $e');
        print(stackTrace);
      }
      await ref.read(notesNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
});

final bumpNoteProvider = Provider.family<Future<void> Function(), String>((ref, id) {
  return () async {
    if (kDebugMode) print('[bumpNoteProvider] Bumping note: $id');
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);

    ref.read(notesNotifierProvider.notifier).bumpNoteOptimistically(id);
    try {
      final NoteItem currentNote = await apiService.getNote(id);
      await apiService.updateNote(id, currentNote);
      if (kDebugMode) print('[bumpNoteProvider] Successfully bumped note: $id');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[bumpNoteProvider] Error bumping note $id: $e');
        print(stackTrace);
      }
      await ref.read(notesNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
}, name: 'bumpNote');

// Rename provider and update types/logic
final updateNoteProvider = Provider.family<Future<NoteItem> Function(NoteItem), String>((ref, id) {
  return (NoteItem updatedNote) async {
    if (kDebugMode) print('[updateNoteProvider] Updating note: $id');
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);

    try {
          // Call updateNote on BaseApiService
      final NoteItem result = await apiService.updateNote(id, updatedNote);

          // Update notifier and cache with NoteItem
      ref.read(notesNotifierProvider.notifier).updateNoteOptimistically(result);
          // Ensure cache provider uses NoteItem
          ref
              .read(noteDetailCacheProvider.notifier)
              .update((state) => {...state, result.id: result});

      if (kDebugMode) print('[updateNoteProvider] Note $id updated successfully.');
      return result;
    } catch (e, stackTrace) {
          if (kDebugMode) {
            print('[updateNoteProvider] Error updating note: $e\n$stackTrace');
          }
      ref.invalidate(notesNotifierProvider);
      ref.invalidate(memoDetailProvider(id));
      rethrow;
    }
  };
});

final togglePinNoteProvider = Provider.family<Future<NoteItem> Function(), String>((ref, id) {
  return () async {
    if (kDebugMode) print('[togglePinNoteProvider] Toggling pin state for note: $id');
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);

    // Optimistic update using renamed notifier
    ref.read(notesNotifierProvider.notifier).togglePinOptimistically(id);

    try {
      // Call togglePinNote on BaseApiService
      final NoteItem result = await apiService.togglePinNote(id);
      // Update cache with NoteItem
      // Ensure cache provider uses NoteItem
      ref
          .read(noteDetailCacheProvider.notifier)
          .update((state) => {...state, result.id: result});

      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[togglePinNoteProvider] Error toggling pin state for note: $id\n$stackTrace',
        );
      }
      await ref.read(notesNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
});

final moveNoteProvider = Provider.family<Future<void> Function(), MoveMemoParams>((ref, params) {
  return () async {
    final noteId = params.memoId;
    final targetServer = params.targetServer;
    final BaseApiService sourceApiService = ref.read(api_p.apiServiceProvider);
    final notifier = ref.read(notesNotifierProvider.notifier);
    final sourceServer = ref.read(activeServerConfigProvider);

    if (sourceServer == null) {
      throw Exception('Cannot move note: No active source server.');
    }
    if (sourceServer.id == targetServer.id) {
      throw Exception('Cannot move note: Source and target servers are the same.');
    }

    if (kDebugMode) {
      print('[moveNoteProvider] Starting move for note $noteId from ${sourceServer.name ?? sourceServer.id} (${sourceServer.serverType.name}) to ${targetServer.name ?? targetServer.id} (${targetServer.serverType.name})');
    }

    notifier.removeNoteOptimistically(noteId);

    NoteItem sourceNote;
    List<Comment> sourceComments = [];
    NoteItem? createdNoteOnTarget;

    try {
      if (kDebugMode) print('[moveNoteProvider] Fetching note details from source...');
      sourceNote = await sourceApiService.getNote(noteId);

      if (kDebugMode) print('[moveNoteProvider] Fetching comments from source...');
      try {
        sourceComments = await sourceApiService.listNoteComments(noteId);
        if (kDebugMode) print('[moveNoteProvider] Found ${sourceComments.length} comments on source.');
      } catch (e) {
        if (kDebugMode) print('[moveNoteProvider] Warning: Failed to fetch comments from source: $e. Proceeding without comments.');
        sourceComments = [];
      }

      if (kDebugMode) print('[moveNoteProvider] Creating note on target server...');
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
      if (kDebugMode) print('[moveNoteProvider] Note created on target with ID: ${createdNoteOnTarget.id}');

      if (sourceComments.isNotEmpty) {
        if (kDebugMode) print('[moveNoteProvider] Creating ${sourceComments.length} comments on target...');
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
            if (kDebugMode) print('[moveNoteProvider] Warning: Failed to create comment (original ID: ${comment.id}) on target: $e');
          }
        }
        if (kDebugMode) print('[moveNoteProvider] Finished creating comments on target.');
      }

      if (kDebugMode) print('[moveNoteProvider] Deleting note from source server...');
      await sourceApiService.deleteNote(noteId);
      if (kDebugMode) print('[moveNoteProvider] Note $noteId successfully deleted from source.');

      if (kDebugMode) print('[moveNoteProvider] Move completed successfully for note $noteId.');
    } catch (e, st) {
      if (kDebugMode) {
        print('[moveNoteProvider] Error during move operation for note $noteId: $e');
        print(st);
      }
      await notifier.refresh();
      rethrow;
    }
  };
}, name: 'moveNoteProvider');

final isNoteHiddenProvider = Provider.family<bool, String>((ref, id) {
  final hiddenMemoIds = ref.watch(hiddenMemoIdsProvider);
  return hiddenMemoIds.contains(id);
}, name: 'isNoteHidden');

final toggleNoteVisibilityProvider = Provider.family<void Function(), String>((ref, id) {
  return () {
    final hiddenMemoIds = ref.read(hiddenMemoIdsProvider);
    if (hiddenMemoIds.contains(id)) {
      ref.read(hiddenMemoIdsProvider.notifier).update((state) => state..remove(id));
      if (kDebugMode) print('[toggleNoteVisibilityProvider] Unhid note: $id');
    } else {
      ref.read(hiddenMemoIdsProvider.notifier).update((state) => state..add(id));
      if (kDebugMode) print('[toggleNoteVisibilityProvider] Hid note: $id');
    }
  };
}, name: 'toggleNoteVisibility');

final batchNoteOperationsProvider = Provider<Future<void> Function(List<String> ids, BatchOperation operation)>((ref) {
  return (List<String> ids, BatchOperation operation) async {
    if (ids.isEmpty) return;
    if (kDebugMode) print('[batchNoteOperationsProvider] Performing $operation on ${ids.length} notes');
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);

    try {
      await Future.wait(ids.map((id) async {
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
      }));

      await ref.read(notesNotifierProvider.notifier).refresh();
    } catch (e, stackTrace) {
      if (kDebugMode) print('[batchNoteOperationsProvider] Error during batch operation: $e\n$stackTrace');
      rethrow;
    }
  };
}, name: 'batchNoteOperations');

enum BatchOperation { archive, delete, pin, unpin }

final selectedNoteIdsProvider = StateProvider<Set<String>>(
  (ref) => {},
  name: 'selectedNoteIds',
);

final noteSelectionModeProvider = StateProvider<bool>(
  (ref) => false,
  name: 'noteSelectionMode',
);

final toggleSelectionModeProvider = Provider<void Function()>((ref) {
  return () {
    final currentMode = ref.read(noteSelectionModeProvider);
    if (currentMode) {
      ref.read(selectedNoteIdsProvider.notifier).state = {};
    }
    ref.read(noteSelectionModeProvider.notifier).state = !currentMode;
    if (kDebugMode) print('[toggleSelectionModeProvider] Selection mode: ${!currentMode}');
  };
}, name: 'toggleSelectionMode');

final noteDetailCacheProvider = StateProvider<Map<String, NoteItem>>(
  (ref) => {},
  name: 'noteDetailCache',
);

final prefetchNoteDetailsProvider = Provider<Future<void> Function(List<String>)>((ref) {
  return (List<String> ids) async {
    if (ids.isEmpty) return;
    if (kDebugMode) print('[prefetchNoteDetailsProvider] Prefetching ${ids.length} notes');
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);
    final cache = ref.read(noteDetailCacheProvider);

    final uncachedIds = ids.where((id) => !cache.containsKey(id)).toList();
    if (uncachedIds.isEmpty) return;

    const batchSize = 5;
    for (var i = 0; i < uncachedIds.length; i += batchSize) {
      final end = (i + batchSize < uncachedIds.length) ? i + batchSize : uncachedIds.length;
      final batch = uncachedIds.sublist(i, end);
      try {
        final List<NoteItem> notes = await Future.wait(batch.map((id) => apiService.getNote(id)));
        final updatedCache = Map<String, NoteItem>.from(cache);
        for (var note in notes) {
          updatedCache[note.id] = note;
        }
        ref.read(noteDetailCacheProvider.notifier).state = updatedCache;
      } catch (e) {
        if (kDebugMode) print('[prefetchNoteDetailsProvider] Error prefetching batch: $e');
      }
      if (end < uncachedIds.length) await Future.delayed(const Duration(milliseconds: 100));
    }
  };
}, name: 'prefetchNoteDetails');

final createNoteProvider = Provider<Future<void> Function(NoteItem)>((ref) {
  final BaseApiService apiService = ref.watch(api_p.apiServiceProvider);

  return (NoteItem note) async {
    await apiService.createNote(note);
    ref.invalidate(notesNotifierProvider);
  };
});

final fixNoteGrammarProvider = FutureProvider.family<void, String>((ref, noteId) async {
  if (kDebugMode) print('[fixNoteGrammarProvider] Starting grammar fix for note: $noteId');

  final BaseApiService notesApiService = ref.read(api_p.apiServiceProvider);
  final MinimalOpenAiService openaiApiService = ref.read(api_p.openaiApiServiceProvider);
  final String selectedModelId = ref.read(settings_p.openAiModelIdProvider);

  if (!openaiApiService.isConfigured) {
    if (kDebugMode) print('[fixNoteGrammarProvider] OpenAI service not configured. Aborting.');
    throw Exception('OpenAI API key is not configured in settings.');
  }

  try {
    if (kDebugMode) print('[fixNoteGrammarProvider] Fetching note content...');
    final NoteItem currentNote = await notesApiService.getNote(noteId);
    final String originalContent = currentNote.content;

    if (originalContent.trim().isEmpty) {
      if (kDebugMode) print('[fixNoteGrammarProvider] Note content is empty. Skipping.');
      return;
    }

    if (kDebugMode) print('[fixNoteGrammarProvider] Calling OpenAI API with model: $selectedModelId...');
    final String correctedContent = await openaiApiService.fixGrammar(
      originalContent,
      modelId: selectedModelId,
    );

    if (correctedContent == originalContent || correctedContent.trim().isEmpty) {
      if (kDebugMode) print('[fixNoteGrammarProvider] Content unchanged or correction empty. No update needed.');
      return;
    }

    if (kDebugMode) print('[fixNoteGrammarProvider] Content corrected. Updating note...');
    final NoteItem updatedNoteData = currentNote.copyWith(content: correctedContent);
    final NoteItem resultNote = await notesApiService.updateNote(noteId, updatedNoteData);

    ref.read(notesNotifierProvider.notifier).updateNoteOptimistically(resultNote);
    ref.read(noteDetailCacheProvider.notifier).update((state) => {...state, noteId: resultNote});
    ref.invalidate(memoDetailProvider(noteId));

    if (kDebugMode) print('[fixNoteGrammarProvider] Note $noteId updated successfully with corrected grammar.');
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('[fixNoteGrammarProvider] Error fixing grammar for note $noteId: $e');
      print(stackTrace);
    }
    rethrow;
  }
});
