import 'dart:async'; // Added for Timer

import 'package:collection/collection.dart'; // Added for listEquals
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/list_notes_response.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/api_providers.dart'
    as api_p; // Keep for global OpenAI
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/services/base_api_service.dart';
import 'package:flutter_memos/services/blinko_api_service.dart';
import 'package:flutter_memos/services/memos_api_service.dart';
import 'package:flutter_memos/services/minimal_openai_service.dart';
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_memos/utils/comment_utils.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_memos/utils/migration_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// +++ Add new providers +++
/// Provider that creates a MemosApiService instance.
final memosApiServiceProvider = Provider<MemosApiService>((ref) {
  // Could add logic here if needed, e.g., reading base config
  return MemosApiService();
}, name: 'memosApiServiceProvider');

/// Provider that creates a BlinkoApiService instance.
final blinkoApiServiceProvider = Provider<BlinkoApiService>((ref) {
  // Could add logic here if needed
  return BlinkoApiService();
}, name: 'blinkoApiServiceProvider');
// +++ End new providers +++

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

// Helper function to get and configure the API service for a specific server ID
NoteApiService _getNoteApiServiceForServer(Ref ref, String serverId) {
  final serverConfig = ref
      .read(multiServerConfigProvider)
      .servers
      .firstWhereOrNull((s) => s.id == serverId);

  if (serverConfig == null) {
    throw Exception("Server config not found for ID: $serverId");
  }

  BaseApiService service;
  switch (serverConfig.serverType) {
    case ServerType.memos:
      service = ref.read(memosApiServiceProvider);
      break;
    case ServerType.blinko:
      service = ref.read(blinkoApiServiceProvider);
      break;
    default:
      throw Exception(
        "Unsupported server type for NoteApiService: ${serverConfig.serverType}",
      );
  }

  service.configureService(
    baseUrl: serverConfig.serverUrl,
    authToken: serverConfig.authToken,
  );

  if (service is! NoteApiService) {
    // This should ideally not happen if the switch case is correct
    throw Exception("Configured service is not a NoteApiService.");
  }
  return service;
}


class NotesNotifier extends StateNotifier<NotesState> {
  final Ref _ref;
  final String serverId; // Add serverId
  late final NoteApiService
  _apiService; // Store the configured service instance
  static const int _pageSize = 20;
  final bool _skipInitialFetchForTesting;

  // Modify constructor to accept serverId
  NotesNotifier(
    this._ref,
    this.serverId, {
    bool skipInitialFetchForTesting = false,
  })
      : _skipInitialFetchForTesting = skipInitialFetchForTesting,
        super(const NotesState(isLoading: true)) {
    // Get and configure the API service instance for this serverId
    _apiService = _getNoteApiServiceForServer(_ref, serverId);
    _initialize();
  }

  void _initialize() {
    if (_skipInitialFetchForTesting) {
      if (kDebugMode) {
        print('[NotesNotifier($serverId)] Skipping initialization for testing');
      }
      return;
    }

    // Listen to filter changes (these are global for now)
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
    if (kDebugMode) {
      // print('[NotesNotifier($serverId)._fetchPage] Attempting fetch.');
      // print('[NotesNotifier($serverId)._fetchPage] Using API Service: ${_apiService.runtimeType}');
    }

    // Use the stored _apiService instance
    final NoteApiService apiService = _apiService;

    final combinedFilter = _ref.read(combinedFilterProvider);
    final filterKey = _ref.read(filterKeyProvider);
    final selectedPresetKey = _ref.read(quickFilterPresetProvider);
    final searchQuery = _ref.read(searchQueryProvider).trim();

    String stateFilter = '';
    if (selectedPresetKey == 'inbox') {
      stateFilter = 'NORMAL';
    } else if (selectedPresetKey == 'archive') {
      stateFilter = 'ARCHIVED';
    }

    final rawCelFilter = _ref.read(rawCelFilterProvider);
    bool usingRawFilter = rawCelFilter.isNotEmpty;
    String? finalFilter = combinedFilter.isNotEmpty ? combinedFilter : null;

    // Apply search query if present
    if (searchQuery.isNotEmpty) {
      // Assuming the API supports a 'content' field search
      // Adjust field name if necessary (e.g., 'text', 'body')
      final searchFilter = 'content.contains("$searchQuery")';
      finalFilter =
          finalFilter == null
              ? searchFilter
              : FilterBuilder.and([finalFilter, searchFilter]);
    }

    // Apply tag filter if not using raw filter and a specific tag preset is selected
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

    if (kDebugMode) {
      // print('[NotesNotifier($serverId)] Fetching page with filter: $finalFilter, state: $stateFilter, pageToken: ${pageToken ?? "null"}');
      // print('[NotesNotifier($serverId)] Current state: ${state.notes.length} notes, isLoading=${state.isLoading}, isLoadingMore=${state.isLoadingMore}, hasReachedEnd=${state.hasReachedEnd}');
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
        // print('[NotesNotifier($serverId)] API Response: ${response.notes.length} notes received. Next page token: ${response.nextPageToken ?? "null"}');
      }

      response.notes.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updateTime.compareTo(a.updateTime);
      });

      var newNotes = response.notes;
      final nextPageToken = response.nextPageToken;

      final bool hasReachedEnd =
          (nextPageToken == null || nextPageToken.isEmpty); // Simplified check
      final newTotalLoaded =
          (pageToken == null)
              ? newNotes.length
              : state.totalLoaded + newNotes.length;

      if (kDebugMode) {
        // print('[NotesNotifier($serverId)] Fetched ${newNotes.length} new notes.');
        // print('[NotesNotifier($serverId)] nextPageToken: ${nextPageToken ?? "null"}');
        // print('[NotesNotifier($serverId)] hasReachedEnd: $hasReachedEnd');
        // print('[NotesNotifier($serverId)] totalLoaded: $newTotalLoaded');
      }

      final List<NoteItem> resultNotes;
      if (pageToken == null) {
        resultNotes = newNotes;
      } else {
        // Prevent duplicates when loading more
        final currentIds = state.notes.map((n) => n.id).toSet();
        final uniqueNewNotes =
            newNotes.where((n) => !currentIds.contains(n.id)).toList();
        resultNotes = [...state.notes, ...uniqueNewNotes];

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
      // Added stack trace
      if (kDebugMode)
        print('[NotesNotifier($serverId)] Error fetching page: $e\n$st');
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
    if (!state.canLoadMore || state.nextPageToken == null) {
      if (kDebugMode) {
        print(
          '[NotesNotifier($serverId)] Cannot load more notes (no token or already loading/ended).',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '[NotesNotifier($serverId)] Fetching more notes with token: ${state.nextPageToken}',
      );
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    await _fetchPage(pageToken: state.nextPageToken);
  }

  Future<void> refresh() async {
    if (kDebugMode) print('[NotesNotifier($serverId)] Refresh triggered.');
    await fetchInitialPage();
  }

  // Optimistic updates remain largely the same, just log serverId
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
    if (kDebugMode)
      print(
        '[NotesNotifier($serverId)] Optimistically updated note: ${updatedNote.id}',
      );
  }

  void removeNoteOptimistically(String noteId) {
    final initialLength = state.notes.length;
    final updatedNotes =
        state.notes.where((note) => note.id != noteId).toList();

    if (kDebugMode) {
      if (updatedNotes.length < initialLength) {
        print(
          '[NotesNotifier($serverId)] removeNoteOptimistically: Removed note $noteId.',
        );
      } else {
        print(
          '[NotesNotifier($serverId)] removeNoteOptimistically: Note $noteId not found.',
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
    if (kDebugMode)
      print('[NotesNotifier($serverId)] Optimistically archived note: $noteId');
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
    if (kDebugMode)
      print(
        '[NotesNotifier($serverId)] Optimistically toggled pin for note: $noteId',
      );
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
      if (kDebugMode)
        print('[NotesNotifier($serverId)] Optimistically bumped note: $noteId');
    }
  }

  // This method now uses the instance's _apiService
  Future<void> updateNoteStartDate(
    String noteId,
    DateTime? newStartDate,
  ) async {
    final noteIndex = state.notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) {
      if (kDebugMode) {
        print(
          '[NotesNotifier($serverId)] Note $noteId not found for start date update.',
        );
      }
      return;
    }

    final originalNote = state.notes[noteIndex];
    if (newStartDate != null &&
        originalNote.endDate != null &&
        newStartDate.isAfter(originalNote.endDate!)) {
      if (kDebugMode) {
        print(
          '[NotesNotifier($serverId)] Cannot set start date ($newStartDate) after end date (${originalNote.endDate}) for note $noteId.',
        );
      }
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
    if (kDebugMode) {
      print(
        '[NotesNotifier($serverId)] Optimistically updated start date for note $noteId to $newStartDate.',
      );
    }

    try {
      // Use the stored _apiService
      final NoteApiService apiService = _apiService;
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
        if (kDebugMode) {
          print(
            '[NotesNotifier($serverId)] Confirmed start date update for note $noteId from API (merged state).',
          );
        }
      } else {
        if (kDebugMode) {
          print(
            '[NotesNotifier($serverId)] Note $noteId disappeared after API update confirmation? Refreshing list.',
          );
        }
        refresh();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[NotesNotifier($serverId)] Failed to update start date via API for note $noteId: $e',
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
        if (kDebugMode) {
          print(
            '[NotesNotifier($serverId)] Reverted optimistic start date update for note $noteId.',
          );
        }
      }
    }
  }
}

// Convert notesNotifierProvider to a family
final notesNotifierProviderFamily =
    StateNotifierProvider.family<NotesNotifier, NotesState, String>((
      ref,
      serverId, // The family parameter
    ) {
      // Pass serverId to the notifier
      return NotesNotifier(ref, serverId);
    }, name: 'notesNotifierProviderFamily');


// --- Derived Providers (Now Families) ---

// --- Start Hidden Count Providers (Families) ---

// Base provider needs to be a family too
final _baseFilteredNotesProviderFamily = Provider.family<
  List<NoteItem>,
  String
>((ref, serverId) {
  // Depend on the correct family instance
  final notesState = ref.watch(notesNotifierProviderFamily(serverId));
  // Global filters are still okay here, but could be made server-specific if needed
  final filterKey = ref.watch(filterKeyProvider);
  final selectedPresetKey = ref.watch(quickFilterPresetProvider);

  // Filter logic remains similar, but uses notesState from the specific server
  return notesState.notes.where((note) {
    switch (selectedPresetKey) {
      case 'inbox':
      case 'all':
      case 'today':
      case 'tagged':
      case 'custom': // Treat custom like 'all' for state filtering
        return note.state != NoteState.archived;
      case 'archive':
        return note.state == NoteState.archived;
      case 'hidden': // Hidden view handles state internally later
        return note.state != NoteState.archived;
      default: // Specific tag filter
        return note.tags.contains(selectedPresetKey) &&
            note.state != NoteState.archived;
    }
  }).toList();
}, name: '_baseFilteredNotesProviderFamily');

// Manually hidden count provider family
final manuallyHiddenNoteCountProviderFamily = Provider.family<int, String>((
  ref,
  serverId,
) {
  // Depend on the base family instance
  final baseNotes = ref.watch(_baseFilteredNotesProviderFamily(serverId));
  // Assume manually hidden IDs are global for now
  final manuallyHiddenIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  return baseNotes.where((note) => manuallyHiddenIds.contains(note.id)).length;
}, name: 'manuallyHiddenNoteCountProviderFamily');

// Future dated count provider family
final futureDatedHiddenNoteCountProviderFamily = Provider.family<int, String>((
  ref,
  serverId,
) {
  // Depend on the base family instance
  final baseNotes = ref.watch(_baseFilteredNotesProviderFamily(serverId));
  // Assume manually hidden IDs are global
  final manuallyHiddenIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  final now = DateTime.now();
  return baseNotes.where((note) {
    return !manuallyHiddenIds.contains(note.id) &&
        note.startDate != null &&
        note.startDate!.isAfter(now);
  }).length;
}, name: 'futureDatedHiddenNoteCountProviderFamily');

// Total hidden count provider family
final totalHiddenNoteCountProviderFamily = Provider.family<int, String>((
  ref,
  serverId,
) {
  // Depend on the other count families
  final manualCount = ref.watch(
    manuallyHiddenNoteCountProviderFamily(serverId),
  );
  final futureCount = ref.watch(
    futureDatedHiddenNoteCountProviderFamily(serverId),
  );
  final total = manualCount + futureCount;
  if (kDebugMode) {
    // print('[totalHiddenNoteCountProviderFamily($serverId)] Manual: $manualCount, Future: $futureCount, Total: $total');
  }
  return total;
}, name: 'totalHiddenNoteCountProviderFamily');

// --- End Hidden Count Providers (Families) ---

// isItemHiddenProvider remains global for now
final isItemHiddenProvider = Provider.family<bool, String>((ref, id) {
  final hiddenItemIds = ref.watch(settings_p.manuallyHiddenNoteIdsProvider);
  return hiddenItemIds.contains(id);
}, name: 'isItemHiddenProvider');

// toggleItemVisibilityProvider remains global for now
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
      if (kDebugMode) {
        print('[toggleItemVisibilityProvider] Unhid item (manual): $id');
      }
    } else {
      manuallyHiddenIdsNotifier.add(id);
      if (kDebugMode) {
        print('[toggleItemVisibilityProvider] Hid item (manual): $id');
      }
    }
    // No need to invalidate server-specific providers here unless hidden state affects server data directly
  };
}, name: 'toggleItemVisibilityProvider');

// Convert filteredNotesProvider to a family
final filteredNotesProviderFamily = Provider.family<List<NoteItem>, String>((
  ref,
  serverId,
) {
  // Depend on the correct notifier family instance
  final notesState = ref.watch(notesNotifierProviderFamily(serverId));
  // Global filters
  final filterKey = ref.watch(filterKeyProvider);
  final selectedPresetKey = ref.watch(quickFilterPresetProvider);
  final hidePinned = ref.watch(hidePinnedProvider);
  final showHiddenToggle = ref.watch(showHiddenNotesProvider);
  final manuallyHiddenIds = ref.watch(
    settings_p.manuallyHiddenNoteIdsProvider,
  ); // Global
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();
  final now = DateTime.now();

  List<NoteItem> currentList;

  // Start with all notes for the specific server
  currentList = notesState.notes;

  // Apply state filter based on preset
  if (selectedPresetKey == 'archive') {
    currentList =
        currentList.where((note) => note.state == NoteState.archived).toList();
  } else if (selectedPresetKey != 'hidden') {
    // Exclude hidden view for now
    currentList =
        currentList.where((note) => note.state != NoteState.archived).toList();
  }

  // Apply tag filter if a specific tag preset is selected
  if (![
    'all',
    'inbox',
    'archive',
    'today',
    'hidden',
    'custom',
    'tagged',
  ].contains(selectedPresetKey)) {
    currentList =
        currentList
            .where((note) => note.tags.contains(selectedPresetKey))
            .toList();
  } else if (selectedPresetKey == 'tagged') {
    currentList = currentList.where((note) => note.tags.isNotEmpty).toList();
  }


  // Apply hidden filter logic
  if (selectedPresetKey == 'hidden') {
    // Show only hidden notes (manual or future-dated)
    currentList =
        currentList.where((note) {
          if (note.state == NoteState.archived)
            return false; // Exclude archived from hidden view
          final isManuallyHidden = manuallyHiddenIds.contains(note.id);
          final isFutureDated =
              note.startDate != null && note.startDate!.isAfter(now);
          return isManuallyHidden || isFutureDated;
        }).toList();
  } else if (!showHiddenToggle) {
    // Hide hidden notes (manual or future-dated)
    currentList =
        currentList.where((note) {
          final isManuallyHidden = manuallyHiddenIds.contains(note.id);
          final isFutureDated =
              note.startDate != null && note.startDate!.isAfter(now);
          return !isManuallyHidden && !isFutureDated;
        }).toList();
  }
  // Else (showHiddenToggle is true and not in 'hidden' view), show all non-archived

  // Apply pinned filter
  if (hidePinned) {
    currentList = currentList.where((note) => !note.pinned).toList();
  }

  // Apply search filter
  if (searchQuery.isNotEmpty) {
    final initialCount = currentList.length;
    currentList =
        currentList.where((note) {
          return note.content.toLowerCase().contains(searchQuery);
        }).toList();
    if (kDebugMode) {
      // print('[filteredNotesProviderFamily($serverId)] Filtered by search query "$searchQuery" from $initialCount to ${currentList.length} notes.');
    }
  }

  // Final sort
  currentList.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    final timeA = a.displayTime;
    final timeB = b.displayTime;
    return timeB.compareTo(timeA);
  });


  if (kDebugMode) {
    // print('[filteredNotesProviderFamily($serverId)] Final sorted list count: ${currentList.length}');
  }
  return currentList;
}, name: 'filteredNotesProviderFamily');


// hasSearchResultsProvider remains global for now, might need adjustment if search becomes server-specific
final hasSearchResultsProvider = Provider<bool>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  // This needs context of which server's notes to check. Cannot be global anymore.
  // This provider should likely be removed or refactored to accept serverId.
  // For now, return true to avoid breaking UI that might depend on it.
  return true;
  // final filteredNotes = ref.watch(filteredNotesProvider); // This is now a family
  // return searchQuery.isEmpty || filteredNotes.isNotEmpty;
}, name: 'hasSearchResultsProvider');

// --- Action Providers (Families where necessary) ---

// unhideNoteProvider remains global as it modifies global hidden IDs
final unhideNoteProvider = Provider.family<void Function(), String>((ref, id) {
  return () {
    if (kDebugMode) print('[unhideNoteProvider] Unhiding note: $id');
    ref.read(settings_p.manuallyHiddenNoteIdsProvider.notifier).remove(id);
    // Invalidate relevant server notifiers if needed, though filter should update
    // ref.invalidate(notesNotifierProviderFamily); // Maybe too broad?
  };
}, name: 'unhideNoteProvider');

// unhideAllNotesProvider becomes a family as it affects a specific server's view potentially
final unhideAllNotesProviderFamily = Provider.family<
  Future<void> Function(),
  String
>((ref, serverId) {
  return () async {
    if (kDebugMode) {
      print(
        '[unhideAllNotesProviderFamily($serverId)] Clearing all manually hidden notes.',
      );
    }
    // Action modifies global state
    await ref.read(settings_p.manuallyHiddenNoteIdsProvider.notifier).clear();
    // Refresh the specific server's list to reflect changes
    await ref.read(notesNotifierProviderFamily(serverId).notifier).refresh();
  };
}, name: 'unhideAllNotesProviderFamily');


// archiveNoteProvider becomes a family
final archiveNoteProviderFamily = Provider.family<
  Future<void> Function(),
  ({String serverId, String noteId})
>((
  ref,
  ids,
) {
  return () async {
    final serverId = ids.serverId;
    final noteId = ids.noteId;
    final apiService = _getNoteApiServiceForServer(ref, serverId);

    final currentSelectedId = ref.read(ui_providers.selectedItemIdProvider);
    final notesBeforeAction = ref.read(filteredNotesProviderFamily(serverId));
    String? nextSelectedId = currentSelectedId;

    // Calculate next selection (logic remains the same)
    if (currentSelectedId == noteId && notesBeforeAction.isNotEmpty) {
      final actionIndex = notesBeforeAction.indexWhere((n) => n.id == noteId);
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

    // Use the correct notifier instance
    ref
        .read(notesNotifierProviderFamily(serverId).notifier)
        .archiveNoteOptimistically(noteId);
    ref.read(ui_providers.selectedItemIdProvider.notifier).state =
        nextSelectedId;

    try {
      await apiService.archiveNote(noteId);
    } catch (e) {
      if (kDebugMode)
        print(
          '[archiveNoteProviderFamily($serverId)] Error archiving note: $e',
        );
      await ref.read(notesNotifierProviderFamily(serverId).notifier).refresh();
      rethrow;
    }
  };
});

// deleteNoteProvider becomes a family
final deleteNoteProviderFamily = Provider.family<
  Future<void> Function(),
  ({String serverId, String noteId})
>((
  ref,
  ids,
) {
  return () async {
    final serverId = ids.serverId;
    final noteId = ids.noteId;
    if (kDebugMode)
      print('[deleteNoteProviderFamily($serverId)] Deleting note: $noteId');
    final apiService = _getNoteApiServiceForServer(ref, serverId);

    final currentSelectedId = ref.read(ui_providers.selectedItemIdProvider);
    final notesBeforeAction = ref.read(filteredNotesProviderFamily(serverId));
    String? nextSelectedId = currentSelectedId;

    // Calculate next selection (logic remains the same)
    if (currentSelectedId == noteId && notesBeforeAction.isNotEmpty) {
      final actionIndex = notesBeforeAction.indexWhere((n) => n.id == noteId);
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

    // Use the correct notifier instance
    ref
        .read(notesNotifierProviderFamily(serverId).notifier)
        .removeNoteOptimistically(noteId);
    ref.read(ui_providers.selectedItemIdProvider.notifier).state =
        nextSelectedId;

    try {
      await apiService.deleteNote(noteId);
      if (kDebugMode) {
        print(
          '[deleteNoteProviderFamily($serverId)] Successfully deleted note: $noteId',
        );
      }
      // Also remove from global hidden list if present
      ref
          .read(settings_p.manuallyHiddenNoteIdsProvider.notifier)
          .remove(noteId);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[deleteNoteProviderFamily($serverId)] Error deleting note $noteId: $e',
        );
        print(stackTrace);
      }
      await ref.read(notesNotifierProviderFamily(serverId).notifier).refresh();
      rethrow;
    }
  };
});

// bumpNoteProvider becomes a family
final bumpNoteProviderFamily = Provider.family<
  Future<void> Function(),
  ({String serverId, String noteId})
>((
  ref,
  ids,
) {
  return () async {
    final serverId = ids.serverId;
    final noteId = ids.noteId;
    if (kDebugMode)
      print('[bumpNoteProviderFamily($serverId)] Bumping note: $noteId');
    final apiService = _getNoteApiServiceForServer(ref, serverId);

    // Use the correct notifier instance
    ref
        .read(notesNotifierProviderFamily(serverId).notifier)
        .bumpNoteOptimistically(noteId);
    try {
      final NoteItem currentNote = await apiService.getNote(noteId);
      await apiService.updateNote(noteId, currentNote);
      if (kDebugMode) {
        print(
          '[bumpNoteProviderFamily($serverId)] Successfully bumped note: $noteId',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[bumpNoteProviderFamily($serverId)] Error bumping note $noteId: $e',
        );
        print(stackTrace);
      }
      await ref.read(notesNotifierProviderFamily(serverId).notifier).refresh();
      rethrow;
    }
  };
}, name: 'bumpNoteFamily'); // Renamed for clarity

// updateNoteProvider becomes a family
final updateNoteProviderFamily = Provider.family<
  Future<NoteItem> Function(NoteItem),
  ({String serverId, String noteId})
>((ref, ids) {
  return (NoteItem updatedNote) async {
    final serverId = ids.serverId;
    final noteId = ids.noteId;
    if (kDebugMode)
      print('[updateNoteProviderFamily($serverId)] Updating note: $noteId');
    final apiService = _getNoteApiServiceForServer(ref, serverId);

    try {
      final NoteItem result = await apiService.updateNote(noteId, updatedNote);
      // Use the correct notifier instance
      ref
          .read(notesNotifierProviderFamily(serverId).notifier)
          .updateNoteOptimistically(result);
      // Update global cache (if still used)
      ref
          .read(noteDetailCacheProvider.notifier)
          .update((state) => {...state, result.id: result});
      if (kDebugMode) {
        print(
          '[updateNoteProviderFamily($serverId)] Note $noteId updated successfully.',
        );
      }
      // Invalidate specific detail provider if it exists
      ref.invalidate(
        noteDetailProviderFamily((serverId: serverId, noteId: noteId)),
      );
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[updateNoteProviderFamily($serverId)] Error updating note: $e\n$stackTrace',
        );
      }
      // Invalidate the specific server's list and detail
      ref.invalidate(notesNotifierProviderFamily(serverId));
      ref.invalidate(
        noteDetailProviderFamily((serverId: serverId, noteId: noteId)),
      );
      rethrow;
    }
  };
});

// togglePinNoteProvider becomes a family
final togglePinNoteProviderFamily = Provider.family<
    Future<NoteItem> Function(),
  ({String serverId, String noteId})
>((ref, ids) {
  return () async {
    final serverId = ids.serverId;
    final noteId = ids.noteId;
    if (kDebugMode) {
      print(
        '[togglePinNoteProviderFamily($serverId)] Toggling pin state for note: $noteId',
      );
    }
    final apiService = _getNoteApiServiceForServer(ref, serverId);

    // Use the correct notifier instance
    ref
        .read(notesNotifierProviderFamily(serverId).notifier)
        .togglePinOptimistically(noteId);

    try {
      final NoteItem result = await apiService.togglePinNote(noteId);
      // Update global cache (if still used)
      ref
          .read(noteDetailCacheProvider.notifier)
          .update((state) => {...state, result.id: result});
      // Invalidate specific detail provider if it exists
      ref.invalidate(
        noteDetailProviderFamily((serverId: serverId, noteId: noteId)),
      );
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[togglePinNoteProviderFamily($serverId)] Error toggling pin state for note: $noteId\n$stackTrace',
        );
      }
      await ref.read(notesNotifierProviderFamily(serverId).notifier).refresh();
      rethrow;
    }
  };
});


// --- Move Note Logic ---

// Helper function to get the correct API service instance based on config (already defined above)
// BaseApiService _getApiServiceForConfig(ServerConfig config, Ref ref) { ... }

@immutable
class MoveNoteParams {
  final String noteId;
  final String sourceServerId; // Add sourceServerId
  final ServerConfig targetServer;

  const MoveNoteParams({
    required this.noteId,
    required this.sourceServerId, // Make required
    required this.targetServer,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveNoteParams &&
          runtimeType == other.runtimeType &&
          noteId == other.noteId &&
          sourceServerId == other.sourceServerId && // Compare sourceServerId
          targetServer == other.targetServer;

  @override
  int get hashCode =>
      noteId.hashCode ^ sourceServerId.hashCode ^ targetServer.hashCode; // Include sourceServerId
}

// moveNoteProvider remains a family keyed by MoveNoteParams
final moveNoteProvider = Provider.family<
    Future<void> Function(),
    MoveNoteParams
>((ref, params) {
  return () async {
    final noteId = params.noteId;
    final sourceServerId = params.sourceServerId; // Use from params
    final targetServer = params.targetServer;
    // Get the correct notifier instance for the source server
    final sourceNotifier = ref.read(
      notesNotifierProviderFamily(sourceServerId).notifier,
    );
    final sourceServerConfig = ref
        .read(multiServerConfigProvider)
        .servers
        .firstWhereOrNull((s) => s.id == sourceServerId);

    if (sourceServerConfig == null) {
      throw Exception(
        'Cannot move note: Source server config not found for ID $sourceServerId.',
      );
    }
    if (sourceServerId == targetServer.id) {
      throw Exception(
        'Cannot move note: Source and target servers are the same.',
      );
    }

    // Instantiate API services for source and target using the helper
    // Corrected calls to use the defined helper function
    final BaseApiService sourceApiService = _getNoteApiServiceForServer(
      ref,
      sourceServerId,
    );
    final BaseApiService targetApiService = _getNoteApiServiceForServer(
      ref,
      targetServer.id,
    );


    if (kDebugMode) {
      print(
        '[moveNoteProvider] Starting move for note $noteId from ${sourceServerConfig.name ?? sourceServerId} (${sourceServerConfig.serverType.name}) to ${targetServer.name ?? targetServer.id} (${targetServer.serverType.name})',
      );
      print(
        '[moveNoteProvider] Source Service: ${sourceApiService.runtimeType}, Target Service: ${targetApiService.runtimeType}',
      );
    }

    // --- Optimistic UI Update ---
    NoteItem? originalSourceNote;
    // Read notes from the correct family instance
    final currentNotes =
        ref.read(notesNotifierProviderFamily(sourceServerId)).notes;
    final originalIndex = currentNotes.indexWhere((n) => n.id == noteId);
    if (originalIndex != -1) {
      originalSourceNote = currentNotes[originalIndex];
    }
    // Use the correct notifier instance
    sourceNotifier.removeNoteOptimistically(noteId);

    NoteItem sourceNoteData;
    List<Comment> sourceComments = [];
    List<({Uint8List bytes, String filename, String contentType, String originalIdentifier})> sourceResourceData = [];
    NoteItem? createdNoteOnTarget;

    try {
      // --- 1. Fetch Data from Source ---
      if (kDebugMode) print('[moveNoteProvider] Fetching note details from source...');
      if (sourceApiService is! NoteApiService) {
        throw Exception('Source service does not support note operations.');
      }
      sourceNoteData = await (sourceApiService).getNote(
        noteId,
      );

      if (kDebugMode) print('[moveNoteProvider] Fetching comments from source...');
      try {
        sourceComments = await (sourceApiService)
            .listNoteComments(noteId);
        if (kDebugMode)
          print(
            '[moveNoteProvider] Found ${sourceComments.length} comments on source.',
          );
      } catch (e) {
        if (kDebugMode)
          print(
            '[moveNoteProvider] Warning: Failed to fetch comments from source: $e. Proceeding without comments.',
          );
        sourceComments = [];
      }

      // Fetch Resource Data
      if (sourceNoteData.resources != null && sourceNoteData.resources!.isNotEmpty) {
        if (kDebugMode)
          print(
            '[moveNoteProvider] Fetching ${sourceNoteData.resources!.length} resources from source...',
          );
        for (final resourceMap in sourceNoteData.resources!) {
          String? resourceIdentifier;
          String filename = resourceMap['filename'] as String? ?? 'unknown_file';
          String contentType = resourceMap['contentType'] as String? ?? 'application/octet-stream';

          if (sourceServerConfig.serverType == ServerType.memos) {
            resourceIdentifier = resourceMap['name'] as String?;
          } else if (sourceServerConfig.serverType == ServerType.blinko) {
            resourceIdentifier = resourceMap['externalLink'] as String? ?? resourceMap['name'] as String?;
          }

          if (resourceIdentifier != null) {
            try {
              if (kDebugMode)
                print(
                  '[moveNoteProvider] Fetching resource data for identifier: $resourceIdentifier',
                );
              final bytes = await sourceApiService.getResourceData(resourceIdentifier);
              sourceResourceData.add((
                bytes: bytes,
                filename: filename,
                contentType: contentType,
                originalIdentifier: resourceIdentifier
              ));
              if (kDebugMode)
                print(
                  '[moveNoteProvider] Fetched ${bytes.length} bytes for resource: $filename',
                );
            } catch (e) {
              if (kDebugMode)
                print(
                  '[moveNoteProvider] Warning: Failed to fetch resource data for $resourceIdentifier: $e. Skipping resource.',
                );
            }
          } else {
            if (kDebugMode)
              print(
                '[moveNoteProvider] Warning: Could not determine resource identifier for resource map: $resourceMap. Skipping resource.',
              );
          }
        }
        if (kDebugMode)
          print(
            '[moveNoteProvider] Finished fetching resource data. Got data for ${sourceResourceData.length} resources.',
          );
      }

      // --- 2. Create on Target ---
      if (kDebugMode) print('[moveNoteProvider] Starting creation process on target server...');

      // Upload Resources to Target
      List<Map<String, dynamic>> targetResourcesMetadata = [];
      if (sourceResourceData.isNotEmpty) {
        if (kDebugMode)
          print(
            '[moveNoteProvider] Uploading ${sourceResourceData.length} resources to target...',
          );
        for (final resourceItem in sourceResourceData) {
          try {
            if (kDebugMode)
              print(
                '[moveNoteProvider] Uploading resource: ${resourceItem.filename} (${resourceItem.contentType})',
              );
            final uploadedMetadata = await targetApiService.uploadResource(
              resourceItem.bytes,
              resourceItem.filename,
              resourceItem.contentType,
            );
            targetResourcesMetadata.add(uploadedMetadata);
            if (kDebugMode)
              print(
                '[moveNoteProvider] Successfully uploaded resource: ${resourceItem.filename}. Metadata: $uploadedMetadata',
              );
          } catch (e) {
            if (kDebugMode)
              print(
                '[moveNoteProvider] Warning: Failed to upload resource ${resourceItem.filename} to target: $e. Skipping resource.',
              );
          }
        }
        if (kDebugMode)
          print(
            '[moveNoteProvider] Finished uploading resources. Got metadata for ${targetResourcesMetadata.length} resources.',
          );
      }

      final NoteItem noteDataForTarget = MigrationUtils.adaptNoteForTarget(
        sourceNoteData,
        targetServer.serverType,
        targetResourcesMetadata,
      );

      if (kDebugMode) print('[moveNoteProvider] Creating note on target server with adapted data...');
      if (targetApiService is! NoteApiService) {
        throw Exception('Target service does not support note operations.');
      }
      createdNoteOnTarget = await (targetApiService)
          .createNote(noteDataForTarget);
      if (kDebugMode) {
        print(
          '[moveNoteProvider] Note created on target with ID: ${createdNoteOnTarget.id}', // Removed null check as it's assigned
        );
      }

      // Adapt and Create Comments on Target
      if (sourceComments.isNotEmpty) {
        if (kDebugMode)
          print(
            '[moveNoteProvider] Creating ${sourceComments.length} comments on target...',
          );
        for (final sourceComment in sourceComments) {
          try {
            final Comment commentDataForTarget = MigrationUtils.adaptCommentForTarget(
              sourceComment,
              targetServer.serverType,
            );
            // Ensure createdNoteOnTarget is not null before accessing its ID
            await (targetApiService).createNoteComment(
              createdNoteOnTarget.id, // Use ! after null check
              commentDataForTarget,
            );
          } catch (e) {
            if (kDebugMode)
              print(
                '[moveNoteProvider] Warning: Failed to create comment (original ID: ${sourceComment.id}) on target: $e',
              );
          }
        }
        if (kDebugMode) print('[moveNoteProvider] Finished creating comments on target.');
      }

      // --- 3. Delete from Source (Only if Target Creation Succeeded and Note Exists) ---
      if (kDebugMode) print('[moveNoteProvider] Deleting note from source server...');
      await (sourceApiService).deleteNote(noteId);
      if (kDebugMode)
        print(
          '[moveNoteProvider] Note $noteId successfully deleted from source.',
        );


      if (kDebugMode)
        print(
          '[moveNoteProvider] Move completed successfully for note $noteId.',
        );
      // Optionally invalidate target server's list
      ref.invalidate(notesNotifierProviderFamily(targetServer.id));

    } catch (e, st) {
      if (kDebugMode) {
        print(
          '[moveNoteProvider] Error during move operation for note $noteId: $e',
        );
        print(st);
      }
      // Revert optimistic removal on source if error occurred
      if (originalSourceNote != null) {
        if (kDebugMode)
          print(
            '[moveNoteProvider] Error occurred. Attempting to refresh source list to revert optimistic removal.',
          );
        await sourceNotifier.refresh();
      } else {
        // If note wasn't in the list initially, still refresh maybe?
        await sourceNotifier.refresh();
      }
      // If note was created on target but subsequent step failed, attempt to delete it
      if (createdNoteOnTarget != null && targetApiService is NoteApiService) {
        try {
          if (kDebugMode)
            print(
              '[moveNoteProvider] Attempting cleanup: Deleting partially created note ${createdNoteOnTarget.id} from target...',
            );
          await targetApiService.deleteNote(createdNoteOnTarget.id);
          if (kDebugMode)
            print(
              '[moveNoteProvider] Cleanup successful: Deleted note from target.',
            );
        } catch (cleanupError) {
          if (kDebugMode)
            print(
              '[moveNoteProvider] Cleanup failed: Could not delete note ${createdNoteOnTarget.id} from target: $cleanupError',
            );
        }
      }
      rethrow; // Rethrow original error
    }
  };
}, name: 'moveNoteProvider');


// --- Multi-Select (Remains Global for now) ---

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
    if (kDebugMode) {
      print(
        '[toggleItemSelectionModeProvider] Selection mode: ${!currentMode}',
      );
    }
  };
}, name: 'toggleItemSelectionModeProvider');

// --- Detail/Comment Providers (Need to become families) ---

// Global cache might still be useful, but access needs care
final noteDetailCacheProvider = StateProvider<Map<String, NoteItem>>(
  (ref) => {},
  name: 'noteDetailCacheProvider',
);

// prefetchNoteDetailsProvider needs serverId context
// This provider is complex to make family-based easily.
// Let's comment it out for now as it's not directly causing build errors.
/*
final prefetchNoteDetailsProvider = Provider<
    Future<void> Function(List<String>)
>((ref) {
  return (List<String> ids) async {
    // Needs serverId to get the correct API service
    // ... implementation requires serverId ...
  };
}, name: 'prefetchNoteDetailsProvider');
*/

// createNoteProvider needs serverId context
final createNoteProviderFamily = Provider.family<
  Future<void> Function(NoteItem),
  String // serverId
>((ref, serverId) {
  return (NoteItem note) async {
    final apiService = _getNoteApiServiceForServer(ref, serverId);
    try {
      await apiService.createNote(note);
    } catch (e) {
      if (kDebugMode) {
        print('[createNoteProviderFamily($serverId)] Error creating note: $e');
      }
      rethrow;
    } finally {
      if (kDebugMode) {
        print(
          '[createNoteProviderFamily($serverId)] Invalidating notesNotifierProviderFamily($serverId) after create attempt.',
        );
      }
      ref.invalidate(notesNotifierProviderFamily(serverId));
    }
  };
});

// fixNoteGrammarProvider needs serverId context
final fixNoteGrammarProviderFamily = FutureProvider.family<
  void,
  ({String serverId, String noteId})
>((ref, ids) async {
  final serverId = ids.serverId;
  final noteId = ids.noteId;
  if (kDebugMode) {
    print(
      '[fixNoteGrammarProviderFamily($serverId)] Starting grammar fix for note: $noteId',
    );
  }

  final notesApiService = _getNoteApiServiceForServer(ref, serverId);
  final MinimalOpenAiService openaiApiService = ref.read(
    api_p.openaiApiServiceProvider, // OpenAI service is global
  );
  final String selectedModelId = ref.read(
    settings_p.openAiModelIdProvider,
  ); // Global setting

  if (!openaiApiService.isConfigured) {
    if (kDebugMode) {
      print(
        '[fixNoteGrammarProviderFamily($serverId)] OpenAI service not configured. Aborting.',
      );
    }
    throw Exception('OpenAI API key is not configured in settings.');
  }

  try {
    if (kDebugMode)
      print(
        '[fixNoteGrammarProviderFamily($serverId)] Fetching note content...',
      );
    final NoteItem currentNote = await notesApiService.getNote(noteId);
    final String originalContent = currentNote.content;

    if (originalContent.trim().isEmpty) {
      if (kDebugMode) {
        print(
          '[fixNoteGrammarProviderFamily($serverId)] Note content is empty. Skipping.',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '[fixNoteGrammarProviderFamily($serverId)] Calling OpenAI API with model: $selectedModelId...',
      );
    }
    final String correctedContent = await openaiApiService.fixGrammar(
      originalContent,
      modelId: selectedModelId,
    );

    if (correctedContent == originalContent ||
        correctedContent.trim().isEmpty) {
      if (kDebugMode) {
        print(
          '[fixNoteGrammarProviderFamily($serverId)] Content unchanged or correction empty. No update needed.',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '[fixNoteGrammarProviderFamily($serverId)] Content corrected. Updating note...',
      );
    }
    final NoteItem updatedNoteData = currentNote.copyWith(
      content: correctedContent,
    );
    final NoteItem resultNote = await notesApiService.updateNote(
      noteId,
      updatedNoteData,
    );

    // Update the correct notifier instance
    ref
        .read(notesNotifierProviderFamily(serverId).notifier)
        .updateNoteOptimistically(resultNote);
    // Update global cache
    ref
        .read(noteDetailCacheProvider.notifier)
        .update((state) => {...state, noteId: resultNote});
    // Invalidate the specific detail provider
    ref.invalidate(
      noteDetailProviderFamily((serverId: serverId, noteId: noteId)),
    );

    if (kDebugMode) {
      print(
        '[fixNoteGrammarProviderFamily($serverId)] Note $noteId updated successfully with corrected grammar.',
      );
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print(
        '[fixNoteGrammarProviderFamily($serverId)] Error fixing grammar for note $noteId: $e',
      );
      print(stackTrace);
    }
    rethrow;
  }
});

// noteDetailProvider becomes a family
final noteDetailProviderFamily =
    FutureProvider.family<NoteItem, ({String serverId, String noteId})>((
      ref,
      ids,
    ) async {
      final apiService = _getNoteApiServiceForServer(ref, ids.serverId);
      return apiService.getNote(ids.noteId);
    }, name: 'noteDetailProviderFamily');

// noteCommentsProvider becomes a family
final noteCommentsProviderFamily =
    FutureProvider.family<List<Comment>, ({String serverId, String noteId})>((
      ref,
      ids,
    ) async {
      final apiService = _getNoteApiServiceForServer(ref, ids.serverId);
      final comments = await apiService.listNoteComments(ids.noteId);
  CommentUtils.sortByPinnedThenUpdateTime(comments);
  return comments;
}, name: 'noteCommentsProviderFamily');


// isFixingGrammarProvider remains global for now, controls UI state
final isFixingGrammarProvider = StateProvider<bool>(
  (ref) => false,
  name: 'isFixingGrammarProvider',
);
