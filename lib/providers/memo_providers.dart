import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/server_config.dart'; // Import ServerConfig
import 'package:flutter_memos/providers/api_providers.dart'
    as api_p; // Added alias
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_detail_provider.dart'; // <-- Add this import
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/services/api_service.dart'; // Import ApiService for type hint
import 'package:flutter_memos/services/openai_api_service.dart'; // Import OpenAI service
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_memos/utils/memo_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State class to hold pagination data
@immutable // Optional but good practice
class MemosState {
  final List<Memo> memos;
  final String? nextPageToken;
  final bool isLoading; // Initial loading state
  final bool isLoadingMore; // Loading subsequent pages
  final Object? error;
  final bool hasReachedEnd; // True if no more pages
  final int totalLoaded; // Keep track of how many memos we've loaded

  const MemosState({
    this.memos = const [],
    this.nextPageToken,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasReachedEnd = false,
    this.totalLoaded = 0,
  });

  // copyWith method for easier state updates
  MemosState copyWith({
    List<Memo>? memos,
    String? nextPageToken,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error, // Allow passing null to clear error
    bool? hasReachedEnd,
    int? totalLoaded,
    bool clearNextPageToken = false, // Helper to explicitly nullify token
    bool clearError = false, // Helper to explicitly nullify error
  }) {
    return MemosState(
      memos: memos ?? this.memos,
      nextPageToken:
          clearNextPageToken ? null : (nextPageToken ?? this.nextPageToken),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      totalLoaded: totalLoaded ?? this.totalLoaded,
    );
  }

  // Convenience method to check if we can load more
  bool get canLoadMore =>
      !isLoading && !isLoadingMore && !hasReachedEnd && nextPageToken != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MemosState &&
        listEquals(other.memos, memos) &&
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
      Object.hashAll(memos), // Use Object.hashAll for list
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


// Removed MemoSortMode enum and memoSortModeProvider
// We now exclusively sort by updateTime due to server inconsistencies 
// with createTime after updates.

/// Provider for the list of hidden memo IDs
final hiddenMemoIdsProvider = StateProvider<Set<String>>((ref) => {});

final hidePinnedProvider = StateProvider<bool>(
  (ref) => false,
  name: 'hidePinnedProvider',
);



// --- Start Pagination Notifier ---

class MemosNotifier extends StateNotifier<MemosState> {
  final Ref _ref;

  static const int _pageSize = 20; // Or make configurable
  final bool _skipInitialFetchForTesting; // Flag for testing

  MemosNotifier(this._ref, {bool skipInitialFetchForTesting = false})
    : _skipInitialFetchForTesting = skipInitialFetchForTesting,
      super(const MemosState(isLoading: true)) {
    _ref.read(api_p.apiServiceProvider); // Use alias
    _initialize();
  }

  void _initialize() {
    // Skip initialization for tests to prevent overwriting manually set state
    if (_skipInitialFetchForTesting) {
      if (kDebugMode) {
        print('[MemosNotifier] Skipping initialization for testing');
      }
      return;
    }

    // Listen to providers that should trigger a full refresh
    _ref.listen(
      api_p.apiServiceProvider, // Use alias
      (_, __) => refresh(),
    ); // Add listener for API service changes
    _ref.listen(combinedFilterProvider, (_, __) => refresh());
    _ref.listen(filterKeyProvider, (_, __) => refresh());
    // REMOVED: Listener for statusFilterProvider
    // REMOVED: Listener for timeFilterProvider

    // Fetch initial data
    fetchInitialPage();
  }

  // Modified _fetchPage with raw API logging and conditional client-side filtering
  Future<void> _fetchPage({String? pageToken}) async {
    // Read apiService inside the method where it's used
    final apiService = _ref.read(
      api_p.apiServiceProvider,
    ); // Read the service here (Use alias)
    // Read current filters INSIDE the fetch method to get latest values
    final combinedFilter = _ref.read(combinedFilterProvider);
    final filterKey = _ref.read(filterKeyProvider);
    // Determine state based on filterKey ('inbox' -> NORMAL, 'archive' -> ARCHIVED)
    String stateFilter = '';
    if (filterKey == 'inbox') {
      stateFilter = 'NORMAL';
    } else if (filterKey == 'archive') {
      stateFilter = 'ARCHIVED';
    }

    // Check if a raw CEL filter is being used
    final rawCelFilter = _ref.read(rawCelFilterProvider);
    bool usingRawFilter = rawCelFilter.isNotEmpty;

    // Apply filter logic for category/visibility based on filterKey
    // Only if not using raw filter (raw filter takes precedence)
    String? finalFilter = combinedFilter.isNotEmpty ? combinedFilter : null;

    // If using a normal filterKey tag and not using raw filter, add tag condition
    if (!usingRawFilter &&
        filterKey != 'all' &&
        filterKey != 'inbox' &&
        filterKey != 'archive') {
      // If filter is null, set it to the tag filter, otherwise append to existing filter
      final tagFilter =
          'tag == "$filterKey"'; // Adjusted for potential CEL syntax
      finalFilter =
          finalFilter == null
              ? tagFilter
              : FilterBuilder.and([finalFilter, tagFilter]);
    }

    // REMOVED: Reading statusFilterProvider

    if (kDebugMode) {
      print(
        '[MemosNotifier] Fetching page with filter: $finalFilter, state: $stateFilter, pageToken: ${pageToken ?? "null"}',
      );
      if (usingRawFilter) {
        print('[MemosNotifier] Using raw CEL filter: $rawCelFilter');
      }
      print(
        '[MemosNotifier] Current state: ${state.memos.length} memos, isLoading=${state.isLoading}, isLoadingMore=${state.isLoadingMore}, hasReachedEnd=${state.hasReachedEnd}',
      );
    }

    try {
      // Use the local apiService variable here
      final response = await apiService.listMemos(
        // Use 'users/-' to fetch memos for the authenticated user
        parent: 'users/-',
        filter: finalFilter,
        state: stateFilter.isNotEmpty ? stateFilter : null,
        sort: 'updateTime', // Keep consistent sorting
        direction: 'DESC',
        pageSize: _pageSize,
        pageToken: pageToken,
      );

      // *** ADDED LOGGING ***
      if (kDebugMode) {
        print(
          '[MemosNotifier] Raw API Response: ${response.memos.length} memos received. Next page token: ${response.nextPageToken ?? "null"}',
        );
        if (response.memos.isNotEmpty) {
          print(
            '[MemosNotifier] First received memo state: ${response.memos.first.state}',
          );
        }
      }
      // *** END ADDED LOGGING ***

      // Sort client-side by updateTime and pinned status
      MemoUtils.sortByPinnedThenUpdateTime(response.memos);

      var newMemos = response.memos;
      final nextPageToken = response.nextPageToken;

      // REMOVED: Client-side untagged filter logic based on statusFilterProvider
      // This filtering should now be handled by the server via combinedFilterProvider
      // or specific presets like FilterPresets.untaggedFilter().

      // Determine if we've reached the end
      final hasReachedEnd =
          nextPageToken == null || nextPageToken.isEmpty || newMemos.isEmpty;

      // Update total loaded count
      final newTotalLoaded =
          (pageToken == null)
              ? newMemos.length
              : state.totalLoaded + newMemos.length;

      if (kDebugMode) {
        print(
          '[MemosNotifier] Fetched ${newMemos.length} new memos (after potential client filter)',
        );
        print('[MemosNotifier] nextPageToken: ${nextPageToken ?? "null"}');
        print('[MemosNotifier] hasReachedEnd: $hasReachedEnd');
        print('[MemosNotifier] totalLoaded: $newTotalLoaded');
      }

      // De-duplicate memos if we somehow received duplicate IDs
      final List<Memo> resultMemos;
      if (pageToken == null) {
        // Initial page - just use new memos
        resultMemos = newMemos;
      } else {
        // For subsequent pages, prevent duplicates by using a Map with memo.id as key
        final Map<String, Memo> mergedMemos = {};
        // Add existing memos first
        for (final memo in state.memos) {
          mergedMemos[memo.id] = memo;
        }
        // Add new memos, potentially overwriting duplicates with newer versions
        for (final memo in newMemos) {
          mergedMemos[memo.id] = memo;
        }
        // Convert back to list and sort
        resultMemos = mergedMemos.values.toList();
        MemoUtils.sortMemos(resultMemos, 'updateTime');
      }

      state = state.copyWith(
        memos: resultMemos,
        nextPageToken: nextPageToken,
        isLoading: false,
        isLoadingMore: false,
        clearError: true, // Clear previous error on success
        hasReachedEnd: hasReachedEnd,
        totalLoaded: newTotalLoaded,
      );
    } catch (e, st) {
      if (kDebugMode) {
        print('[MemosNotifier] Error fetching page: $e\n$st');
      }
      state = state.copyWith(isLoading: false, isLoadingMore: false, error: e);
    }
  }

  Future<void> fetchInitialPage() async {
    // Reset state for a fresh load
    state = state.copyWith(
      isLoading: true,
      memos: [],
      clearError: true,
      clearNextPageToken: true,
      hasReachedEnd: false,
      totalLoaded: 0,
    );
    await _fetchPage(pageToken: null);
  }

  Future<void> fetchMoreMemos() async {
    // Check if we can load more using the convenience method
    if (!state.canLoadMore) {
      if (kDebugMode) {
        print('[MemosNotifier] Cannot load more memos:');
        print('  - isLoading: ${state.isLoading}');
        print('  - isLoadingMore: ${state.isLoadingMore}');
        print('  - hasReachedEnd: ${state.hasReachedEnd}');
        print('  - nextPageToken: ${state.nextPageToken}');
      }
      return;
    }

    if (kDebugMode) {
      print(
        '[MemosNotifier] Fetching more memos with token: ${state.nextPageToken}',
      );
    }

    // Set loading more flag and clear any errors
    state = state.copyWith(isLoadingMore: true, clearError: true);

    // Fetch the next page using the stored token
    await _fetchPage(pageToken: state.nextPageToken);
  }

  Future<void> refresh() async {
    // Called by pull-to-refresh or filter changes
    if (kDebugMode) {
      print('[MemosNotifier] Refresh triggered.');
    }
    await fetchInitialPage();
  }

  // Update a single memo in the list optimistically
  void updateMemoOptimistically(Memo updatedMemo) {
    final updatedMemos = state.memos.map((memo) {
      return memo.id == updatedMemo.id ? updatedMemo : memo;
    }).toList();

    // Re-sort to maintain correct order
    MemoUtils.sortByPinnedThenUpdateTime(updatedMemos);

    state = state.copyWith(
      memos: updatedMemos,
    );
  }

  // Remove a memo from the list optimistically - Notifier only manages its own list state.
  void removeMemoOptimistically(String memoId) {
    final initialLength = state.memos.length;
    final updatedMemos =
        state.memos.where((memo) => memo.id != memoId).toList();

    if (kDebugMode) {
      if (updatedMemos.length < initialLength) {
        print(
          '[MemosNotifier] removeMemoOptimistically: Removed memo $memoId from internal list.',
        );
      } else {
        print(
          '[MemosNotifier] removeMemoOptimistically: Memo $memoId not found in internal list.',
        );
      }
    }

    // Only update state if the memo was actually found and removed
    if (updatedMemos.length < initialLength) {
      state = state.copyWith(memos: updatedMemos);
    }

    // Update selection if needed (handled by UI components watching the provider)
  }


  // Archive a memo optimistically
  void archiveMemoOptimistically(String memoId) {
    state = state.copyWith(
      memos: state.memos.map((memo) {
        if (memo.id == memoId) {
          return memo.copyWith(state: MemoState.archived, pinned: false);
        }
        return memo;
      }).toList(),
    );
  }

  // Toggle pin state optimistically
  void togglePinOptimistically(String memoId) {
    final updatedMemos = state.memos.map((memo) {
      if (memo.id == memoId) {
        return memo.copyWith(pinned: !memo.pinned);
      }
      return memo;
    }).toList();

    // Re-sort to ensure pinned items appear at top
    MemoUtils.sortByPinnedThenUpdateTime(updatedMemos);

    state = state.copyWith(memos: updatedMemos);
  }

  // Bump a memo's timestamp optimistically
  void bumpMemoOptimistically(String memoId) {
    final memoIndex = state.memos.indexWhere((memo) => memo.id == memoId);

    if (memoIndex != -1) {
      final memoToBump = state.memos[memoIndex];

      // Create updated memo with current time
      final updatedMemo = memoToBump.copyWith(
        updateTime: DateTime.now().toIso8601String(),
      );

      // Create a new list with the updated memo
      final updatedMemos = List<Memo>.from(state.memos);
      updatedMemos[memoIndex] = updatedMemo;

      // Re-sort the list to ensure correct order
      MemoUtils.sortByPinnedThenUpdateTime(updatedMemos);

      // Update the state
      state = state.copyWith(memos: updatedMemos);
    }
  }
}

// --- End Pagination Notifier ---

/// Provider that fetches memos and applies filters and sorting
// final memosProvider = FutureProvider<List<Memo>>((ref) async {
//   // Deprecated: Replaced by pagination with MemosNotifier
// }); // End of deprecated memosProvider

/// Provider that returns only visible memos (not hidden)
// final visibleMemosProvider = Provider<AsyncValue<List<Memo>>>((ref) {
//   // Deprecated: Replaced by visibleMemosListProvider
// }); // End of deprecated visibleMemosProvider

// --- New Pagination Providers ---

/// StateNotifierProvider for managing the paginated memo list state.
final memosNotifierProvider = StateNotifierProvider<MemosNotifier, MemosState>((
  ref,
) {
  // The notifier is initialized and automatically fetches the first page.
  // It also listens to filter changes internally.
  return MemosNotifier(ref);
}, name: 'memosNotifierProvider');

/// Provider that selects the list of *visible* memos from the current MemosState.
/// This replaces the old `visibleMemosProvider`.
final visibleMemosListProvider = Provider<List<Memo>>((ref) {
  // Watch the state from the notifier
  final memosState = ref.watch(memosNotifierProvider);
  // Watch the set of hidden memo IDs
  final hiddenMemoIds = ref.watch(hiddenMemoIdsProvider);
  // Watch the hide pinned setting
  final hidePinned = ref.watch(hidePinnedProvider);
  // Watch the current filter key to filter by state
  final filterKey = ref.watch(filterKeyProvider);

  // Filter the memos currently held in the state
  final visibleMemos =
      memosState.memos.where((memo) {
        // --- Basic Visibility Filters ---
        // Hide memos that are in the hidden IDs set
        if (hiddenMemoIds.contains(memo.id)) return false;
        // Hide pinned memos if hidePinned is true
        if (hidePinned && memo.pinned) return false;

        // --- State Filtering based on filterKey ---
        switch (filterKey) {
          case 'inbox':
          case 'all': // 'all' typically means non-archived
            // Hide archived memos in inbox/all view
            if (memo.state == MemoState.archived) return false;
            break;
          case 'archive':
            // Only show archived memos in archive view
            if (memo.state != MemoState.archived) return false;
            break;
          // Add cases for other filter keys (like tags) if needed,
          // although tag filtering might primarily rely on server fetch/notifier state.
        }

        // If none of the above filters excluded the memo, include it.
        return true;
      }).toList();

  // Sort with pinned first (unless all pinned are hidden)
  MemoUtils.sortByPinnedThenUpdateTime(visibleMemos);

  if (kDebugMode) {
    // Avoid excessive logging, maybe log only when count changes
    // print('[visibleMemosListProvider] Providing ${visibleMemos.length} visible memos.');
  }

  return visibleMemos;
}, name: 'visibleMemosListProvider');

/// Provider that applies local search/filtering to the visible memos
/// This delivers fast, responsive filtering as the user types
final filteredMemosProvider = Provider<List<Memo>>((ref) {
  // Get the base list of visible memos
  final visibleMemos = ref.watch(visibleMemosListProvider);

  // Get the current search query
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();

  // If there's no search query, return all visible memos
  if (searchQuery.isEmpty) {
    return visibleMemos;
  }

  // Apply the search filter
  final filteredMemos =
      visibleMemos.where((memo) {
        // Search in memo content (case-insensitive)
        return memo.content.toLowerCase().contains(searchQuery);
      }).toList();

  if (kDebugMode) {
    print(
      '[filteredMemosProvider] Filtered from ${visibleMemos.length} to ${filteredMemos.length} memos with query: "$searchQuery"',
    );
  }

  return filteredMemos;
}, name: 'filteredMemosProvider');

/// Provider to determine if we need to show "no results" for search
final hasSearchResultsProvider = Provider<bool>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final filteredMemos = ref.watch(filteredMemosProvider);

  // Only show no results message if there's a search query and no results
  return searchQuery.isEmpty || filteredMemos.isNotEmpty;
}, name: 'hasSearchResultsProvider');

// --- End New Pagination Providers ---

/// Provider for archiving a memo
final archiveMemoProvider = Provider.family<Future<void> Function(), String>((ref, id) {
  return () async {
    final apiService = ref.read(api_p.apiServiceProvider); // Use alias

    // --- Selection Update Logic (Downward Preference) ---
    final currentSelectedId = ref.read(ui_providers.selectedMemoIdProvider);
    final memosBeforeAction = ref.read(
      filteredMemosProvider,
    ); // Read list BEFORE action
    final memoIdToAction = id; // ID of the memo being removed/hidden
    String? nextSelectedId = currentSelectedId; // Default to no change

    // Only adjust selection if the item being actioned is currently selected
    if (currentSelectedId == memoIdToAction && memosBeforeAction.isNotEmpty) {
      final actionIndex = memosBeforeAction.indexWhere(
        (m) => m.id == memoIdToAction,
      );

      if (actionIndex != -1) {
        // Ensure the item was found
        if (memosBeforeAction.length == 1) {
          // List will be empty after action
          nextSelectedId = null;
        } else if (actionIndex < memosBeforeAction.length - 1) {
          // If NOT the last item, select the item originally *after* it.
          nextSelectedId = memosBeforeAction[actionIndex + 1].id;
        } else {
          // If it IS the last item, select the item originally *before* it (the new last item).
          nextSelectedId = memosBeforeAction[actionIndex - 1].id;
        }
      } else {
        // Memo to action wasn't found in the list? Clear selection.
        nextSelectedId = null;
      }
    }
    // --- End Selection Update Logic ---

    // Apply optimistic update first
    ref.read(memosNotifierProvider.notifier).archiveMemoOptimistically(id);
    // Update selection *after* optimistic update
    ref.read(ui_providers.selectedMemoIdProvider.notifier).state =
        nextSelectedId;

    try {
      // Get the memo
      final memo = await apiService.getMemo(id);

      // Update the memo to archived state
      final updatedMemo = memo.copyWith(
        pinned: false,
        state: MemoState.archived,
      );

      // Save the updated memo
      await apiService.updateMemo(id, updatedMemo);

      // Refresh is removed on success. Optimistic update handles UI change.
      // Refresh only happens on error now.
      // await ref.read(memosNotifierProvider.notifier).refresh();
    } catch (e) {
      if (kDebugMode) {
        print('[archiveMemoProvider] Error archiving memo: $e');
      }

      // Refresh on error to ensure data consistency
      await ref.read(memosNotifierProvider.notifier).refresh();

      rethrow;
    }
  };
});

/// Provider for deleting a memo. Just takes the ID as parameter.
final deleteMemoProvider = Provider.family<Future<void> Function(), String>((
  ref,
  id,
) {
  return () async {
    if (kDebugMode) {
      print('[deleteMemoProvider] Deleting memo: $id');
    }

    final apiService = ref.read(api_p.apiServiceProvider); // Use alias

    // --- Selection Update Logic (Downward Preference) ---
    final currentSelectedId = ref.read(ui_providers.selectedMemoIdProvider);
    final memosBeforeAction = ref.read(
      filteredMemosProvider,
    ); // Read list BEFORE action
    final memoIdToAction = id; // ID of the memo being removed/hidden
    String? nextSelectedId = currentSelectedId; // Default to no change

    // Only adjust selection if the item being actioned is currently selected
    if (currentSelectedId == memoIdToAction && memosBeforeAction.isNotEmpty) {
      final actionIndex = memosBeforeAction.indexWhere(
        (m) => m.id == memoIdToAction,
      );

      if (actionIndex != -1) {
        // Ensure the item was found
        if (memosBeforeAction.length == 1) {
          // List will be empty after action
          nextSelectedId = null;
        } else if (actionIndex < memosBeforeAction.length - 1) {
          // If NOT the last item, select the item originally *after* it.
          nextSelectedId = memosBeforeAction[actionIndex + 1].id;
        } else {
          // If it IS the last item, select the item originally *before* it (the new last item).
          nextSelectedId = memosBeforeAction[actionIndex - 1].id;
        }
      } else {
        // Memo to action wasn't found in the list? Clear selection.
        nextSelectedId = null;
      }
    }
    // --- End Selection Update Logic ---

    // Apply optimistic update to the memo list
    ref.read(memosNotifierProvider.notifier).removeMemoOptimistically(id);

    // Update selection *after* optimistic update
    ref.read(ui_providers.selectedMemoIdProvider.notifier).state =
        nextSelectedId;

    try {
      // Delete the memo via API
      await apiService.deleteMemo(id);

      if (kDebugMode) {
        print('[deleteMemoProvider] Successfully deleted memo: $id');
      }

      // Also clear from hidden IDs cache if it's there
      ref
          .read(hiddenMemoIdsProvider.notifier)
          .update((state) => state.contains(id) ? (state..remove(id)) : state);

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[deleteMemoProvider] Error deleting memo $id: $e');
        print(stackTrace);
      }

      // Refresh on error to ensure data consistency
      await ref.read(memosNotifierProvider.notifier).refresh();

      // Rethrow to allow proper error handling upstream
      rethrow;
    }
  };
});

/// Provider for bumping a memo (updating its timestamp)
final bumpMemoProvider = Provider.family<Future<void> Function(), String>((
  ref,
  id,
) {
  return () async {
    if (kDebugMode) {
      print('[bumpMemoProvider] Bumping memo: $id');
    }
    final apiService = ref.read(api_p.apiServiceProvider); // Use alias

    // Apply optimistic update first
    ref.read(memosNotifierProvider.notifier).bumpMemoOptimistically(id);

    // Note: No selection adjustment needed here because:
    // 1. The memo isn't removed from the list (just re-sorted)
    // 2. The ID-based selection will still track the memo even if position changes

    try {
      // Get the current memo data to ensure content isn't lost
      final currentMemo = await apiService.getMemo(id);

      // Call updateMemo - it sends client time as updateTime implicitly
      await apiService.updateMemo(id, currentMemo);

      if (kDebugMode) {
        print('[bumpMemoProvider] Successfully bumped memo: $id');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[bumpMemoProvider] Error bumping memo $id: $e');
        print(stackTrace);
      }

      // Refresh on error to ensure data consistency
      await ref.read(memosNotifierProvider.notifier).refresh();

      rethrow;
    }
  };
}, name: 'bumpMemo');

/// OPTIMIZATION: Provider for updating a memo with optimistic updates
final updateMemoProvider = Provider.family<Future<Memo> Function(Memo), String>(
  (ref, id) {
    return (Memo updatedMemo) async {
      if (kDebugMode) {
        print('[updateMemoProvider] Updating memo: $id');
      }

    final apiService = ref.read(api_p.apiServiceProvider); // Use alias

    // Optional: Optimistic UI update (already handled by notifier methods if called from elsewhere)
      // ref.read(memosNotifierProvider.notifier).updateMemoOptimistically(updatedMemo);

    try {
        // Update memo through API
        final result = await apiService.updateMemo(id, updatedMemo);

      // --- REMOVE CACHE UPDATE AND INVALIDATIONS ---
      // // Update the detail cache *before* invalidating the detail provider
      // if (ref.exists(memoDetailCacheProvider)) {
      //   ref
      //       .read(memoDetailCacheProvider.notifier)
      //       .update((state) => {...state, id: result});
      //   if (kDebugMode) {
      //     print('[updateMemoProvider] Updated memoDetailCacheProvider for $id');
      //   }
      // }
      //
      // // Refresh the main list after successful update
      // ref.invalidate(memosNotifierProvider);
      // // Invalidate the specific memo detail provider to ensure freshness if needed elsewhere
      // ref.invalidate(memoDetailProvider(id));
      // --- END REMOVAL ---

      // Instead of invalidating everything, update the specific memo in the notifier
      ref.read(memosNotifierProvider.notifier).updateMemoOptimistically(result);
      // And update the detail cache
      ref
          .read(memoDetailCacheProvider.notifier)
          .update((state) => {...state, id: result});


      if (kDebugMode) {
        print(
            '[updateMemoProvider] Memo $id updated successfully via API.');
      }
      return result; // Return the result
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[updateMemoProvider] Error updating memo: $e');
        print(stackTrace);
      }
      // Optional: Revert optimistic update on error or refresh to ensure consistency
      // Consider refreshing on error to sync with server state
      // Remove potentially stale item from cache on error? Or let refresh handle it.
      // Let's keep invalidation to trigger refresh which ensures consistency.
      ref.invalidate(memosNotifierProvider);
      ref.invalidate(memoDetailProvider(id));
      rethrow;
    }
  };
});

/// Provider for pinning/unpinning memos with optimistic updates
final togglePinMemoProvider = Provider.family<Future<Memo> Function(), String>((
  ref,
  id,
) {
  return () async {
    if (kDebugMode) {
      print('[togglePinMemoProvider] Toggling pin state for memo: $id');
    }

    final apiService = ref.read(api_p.apiServiceProvider); // Use alias

    // Apply optimistic update first
    ref.read(memosNotifierProvider.notifier).togglePinOptimistically(id);

    // Note: No selection adjustment needed here because:
    // 1. The memo isn't removed from the list (just re-sorted)
    // 2. The ID-based selection will still track the memo even if position changes
    // 3. If hidePinned is enabled, _ensureInitialSelection in MemosBody will handle clearing selection

    try {
      // Get the memo
      final memo = await apiService.getMemo(id);

      // Toggle the pinned state
      final updatedMemo = memo.copyWith(pinned: !memo.pinned);

      // Update through API
      final result = await apiService.updateMemo(id, updatedMemo);

      // Update detail cache after successful API call
      ref
          .read(memoDetailCacheProvider.notifier)
          .update((state) => {...state, id: result});

      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[togglePinMemoProvider] Error toggling pin state for memo: $id');
        print(stackTrace);
      }

      // Refresh on error to ensure data consistency
      await ref.read(memosNotifierProvider.notifier).refresh();

      rethrow;
    }
  };
});

/// Provider for moving a memo to another server
final moveMemoProvider = Provider.family<
  Future<void> Function(),
  MoveMemoParams
>((ref, params) {
  return () async {
    final memoId = params.memoId;
    final targetServer = params.targetServer;
    final apiService = ref.read(api_p.apiServiceProvider); // Use alias
    final notifier = ref.read(memosNotifierProvider.notifier);
    // Get the source server config (which is the currently active one)
    final sourceServer = ref.read(activeServerConfigProvider);

    if (sourceServer == null) {
      throw Exception('Cannot move memo: No active source server configured.');
    }
    if (sourceServer.id == targetServer.id) {
      throw Exception(
        'Cannot move memo: Source and target servers are the same.',
      );
    }

    if (kDebugMode) {
      print(
        '[moveMemoProvider] Starting move for memo $memoId from ${sourceServer.name ?? sourceServer.id} to ${targetServer.name ?? targetServer.id}',
      );
    }

    // 1. Optimistic Removal from source list
    notifier.removeMemoOptimistically(memoId);

    Memo sourceMemo;
    List<Comment> sourceComments = [];
    Memo? createdMemoOnTarget;

    try {
      // 2. Fetch Memo details from Source Server
      if (kDebugMode) {
        print('[moveMemoProvider] Fetching memo details from source...');
      }
      sourceMemo = await apiService.getMemo(
        memoId,
        targetServerOverride: sourceServer,
      );

      // 3. Fetch Comments from Source Server
      if (kDebugMode) {
        print('[moveMemoProvider] Fetching comments from source...');
      }
      try {
        sourceComments = await apiService.listMemoComments(
          memoId,
          targetServerOverride: sourceServer,
        );
        if (kDebugMode) {
          print(
            '[moveMemoProvider] Found ${sourceComments.length} comments on source.',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[moveMemoProvider] Warning: Failed to fetch comments from source: $e. Proceeding without comments.',
          );
        }
        sourceComments = []; // Continue without comments if fetch fails
      }

      // 4. Create Memo on Target Server
      if (kDebugMode) {
        print('[moveMemoProvider] Creating memo on target server...');
      }
      // Create a new Memo object without the ID for creation
      final memoToCreate = Memo(
        id: '', // ID will be assigned by the target server
        content: sourceMemo.content,
        pinned: sourceMemo.pinned,
        state: sourceMemo.state,
        visibility: sourceMemo.visibility,
        resourceNames:
            sourceMemo.resourceNames, // TODO: Handle resource moving?
        relationList: sourceMemo.relationList, // TODO: Handle relation moving?
        parent: sourceMemo.parent,
        creator:
            sourceMemo
                .creator, // Creator might change based on target server user
        createTime:
            sourceMemo.createTime, // Preserve original create time if possible
        // updateTime: sourceMemo.updateTime, // Let target server set update time
        displayTime: sourceMemo.displayTime,
      );
      createdMemoOnTarget = await apiService.createMemo(
        memoToCreate,
        targetServerOverride: targetServer,
      );
      if (kDebugMode) {
        print(
          '[moveMemoProvider] Memo created on target with ID: ${createdMemoOnTarget.id}',
        );
      }

      // 5. Create Comments on Target Server
      if (sourceComments.isNotEmpty) {
        if (kDebugMode) {
          print(
            '[moveMemoProvider] Creating ${sourceComments.length} comments on target...',
          );
        }
        for (final comment in sourceComments) {
          try {
            // Create a new Comment object without the ID
            final commentToCreate = Comment(
              id: '',
              content: comment.content,
              creatorId:
                  comment
                      .creatorId, // May need adjustment based on target server users
              createTime: comment.createTime, // Preserve original time
              state: comment.state,
              pinned: comment.pinned,
              resources: comment.resources, // TODO: Handle resource moving?
            );
            await apiService.createMemoComment(
              createdMemoOnTarget.id, // Use the new memo ID from target
              commentToCreate,
              targetServerOverride: targetServer,
              resources: comment.resources, // Pass resources if they exist
            );
          } catch (e) {
            // Log comment creation errors but continue the process
            if (kDebugMode) {
              print(
                '[moveMemoProvider] Warning: Failed to create comment (original ID: ${comment.id}) on target server: $e',
              );
            }
          }
        }
        if (kDebugMode) {
          print('[moveMemoProvider] Finished creating comments on target.');
        }
      }

      // 6. Delete Memo from Source Server (only after successful creation on target)
      if (kDebugMode) {
        print('[moveMemoProvider] Deleting memo from source server...');
      }
      await apiService.deleteMemo(memoId, targetServerOverride: sourceServer);
      if (kDebugMode) {
        print(
          '[moveMemoProvider] Memo $memoId successfully deleted from source.',
        );
      }

      if (kDebugMode) {
        print(
          '[moveMemoProvider] Move completed successfully for memo $memoId.',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        print(
          '[moveMemoProvider] Error during move operation for memo $memoId: $e',
        );
        print(st);
      }
      // Attempt to rollback or notify user?
      // For now, just rethrow the error. Critical failure.
      // Refresh the source list to potentially bring back the memo if deletion didn't happen
      await notifier.refresh();
      rethrow; // Rethrow the exception that caused the failure
    }
  };
}, name: 'moveMemoProvider');

/// OPTIMIZATION: Provider for checking if a memo is hidden
final isMemoHiddenProvider = Provider.family<bool, String>((ref, id) {
  final hiddenMemoIds = ref.watch(hiddenMemoIdsProvider.select((ids) => ids));
  return hiddenMemoIds.contains(id);
}, name: 'isMemoHidden');

/// OPTIMIZATION: Provider for toggling visibility of a memo in the current view
final toggleMemoVisibilityProvider = Provider.family<void Function(), String>((
  ref,
  id,
) {
  return () {
    final hiddenMemoIds = ref.read(hiddenMemoIdsProvider);

    if (hiddenMemoIds.contains(id)) {
      // Unhide the memo
      ref
          .read(hiddenMemoIdsProvider.notifier)
          .update((state) => state..remove(id));
      if (kDebugMode) {
        print('[toggleMemoVisibilityProvider] Unhid memo: $id');
      }
    } else {
      // Hide the memo
      ref
          .read(hiddenMemoIdsProvider.notifier)
          .update((state) => state..add(id));
      if (kDebugMode) {
        print('[toggleMemoVisibilityProvider] Hid memo: $id');
      }
    }
  };
}, name: 'toggleMemoVisibility');

/// OPTIMIZATION: Provider for batch operations on memos
final batchMemoOperationsProvider = Provider<
  Future<void> Function(List<String> ids, BatchOperation operation)
>((ref) {
  return (List<String> ids, BatchOperation operation) async {
    if (ids.isEmpty) return;

    if (kDebugMode) {
      print(
        '[batchMemoOperationsProvider] Performing $operation on ${ids.length} memos',
      );
    }

    final apiService = ref.read(api_p.apiServiceProvider); // Use alias

    try {
      switch (operation) {
        case BatchOperation.archive:
          // Process each memo in parallel
          await Future.wait(
            ids.map((id) async {
              final memo = await apiService.getMemo(id);
              final updatedMemo = memo.copyWith(
                pinned: false,
                state: MemoState.archived,
              );
              return apiService.updateMemo(id, updatedMemo);
            }),
          );
          break;

        case BatchOperation.delete:
          await Future.wait(ids.map((id) => apiService.deleteMemo(id)));
          break;

        case BatchOperation.pin:
          await Future.wait(
            ids.map((id) async {
              final memo = await apiService.getMemo(id);
              final updatedMemo = memo.copyWith(pinned: true);
              return apiService.updateMemo(id, updatedMemo);
            }),
          );
          break;

        case BatchOperation.unpin:
          await Future.wait(
            ids.map((id) async {
              final memo = await apiService.getMemo(id);
              final updatedMemo = memo.copyWith(pinned: false);
              return apiService.updateMemo(id, updatedMemo);
            }),
          );
          break;
      }

      // Refresh memos list using the new notifier
      // ref.invalidate(memosProvider); // Old way
      await ref.read(memosNotifierProvider.notifier).refresh(); // New way
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[batchMemoOperationsProvider] Error during batch operation: $e');
        print(stackTrace);
      }
      rethrow;
    }
  };
}, name: 'batchMemoOperations');

/// OPTIMIZATION: Type for tracking the batch operation
enum BatchOperation { archive, delete, pin, unpin }

/// OPTIMIZATION: Provider for selected memos in multi-select mode
final selectedMemoIdsProvider = StateProvider<Set<String>>(
  (ref) => {},
  name: 'selectedMemoIds',
);

/// OPTIMIZATION: Provider for the current memo selection mode
final memoSelectionModeProvider = StateProvider<bool>(
  (ref) => false,
  name: 'memoSelectionMode',
);

/// OPTIMIZATION: Provider to toggle selection mode
final toggleSelectionModeProvider = Provider<void Function()>((ref) {
  return () {
    final currentMode = ref.read(memoSelectionModeProvider);

    // If turning off selection mode, clear selections
    if (currentMode) {
      ref.read(selectedMemoIdsProvider.notifier).state = {};
    }

    // Toggle the mode
    ref.read(memoSelectionModeProvider.notifier).state = !currentMode;

    if (kDebugMode) {
      print('[toggleSelectionModeProvider] Selection mode: ${!currentMode}');
    }
  };
}, name: 'toggleSelectionMode');

/// OPTIMIZATION: Provider to check if memo details are cached
final memoDetailCacheProvider = StateProvider<Map<String, Memo>>(
  (ref) => {},
  name: 'memoDetailCache',
);

/// OPTIMIZATION: Provider to prefetch memo details for better UX
final prefetchMemoDetailsProvider = Provider<
  Future<void> Function(List<String>)
>((ref) {
  return (List<String> ids) async {
    if (ids.isEmpty) return;

    if (kDebugMode) {
      print('[prefetchMemoDetailsProvider] Prefetching ${ids.length} memos');
    }

    final apiService = ref.read(api_p.apiServiceProvider); // Use alias
    final cache = ref.read(memoDetailCacheProvider);

    // Filter out already cached memos
    final uncachedIds = ids.where((id) => !cache.containsKey(id)).toList();

    if (uncachedIds.isEmpty) return;

    // Fetch in parallel with a reasonable batch size to avoid overloading
    const batchSize = 5;
    for (var i = 0; i < uncachedIds.length; i += batchSize) {
      final end =
          (i + batchSize < uncachedIds.length)
              ? i + batchSize
              : uncachedIds.length;
      final batch = uncachedIds.sublist(i, end);

      try {
        // Fetch all memos in the batch in parallel
        final memos = await Future.wait(
          batch.map((id) => apiService.getMemo(id)),
        );

        // Update cache with fetched memos
        final updatedCache = Map<String, Memo>.from(cache);
        for (var memo in memos) {
          updatedCache[memo.id] = memo;
        }
        ref.read(memoDetailCacheProvider.notifier).state = updatedCache;
      } catch (e) {
        if (kDebugMode) {
          print('[prefetchMemoDetailsProvider] Error prefetching batch: $e');
        }
        // Continue with next batch even if one fails
      }

      // Small delay between batches to be gentle on the server
      if (end < uncachedIds.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  };
}, name: 'prefetchMemoDetails');

/// Create memo provider - returns a function to create a new memo
final createMemoProvider = Provider<Future<void> Function(Memo)>((ref) {
  final apiService = ref.watch(api_p.apiServiceProvider); // Use alias

  return (Memo memo) async {
    // Call the API service to create the memo
    await apiService.createMemo(memo);

    // Refresh the memos list after creating a new memo by invalidating the memosNotifierProvider
    // This is more effective than invalidateSelf() which would only refresh the function provider
    ref.invalidate(memosNotifierProvider);
  };
});


/// Provider to fix grammar of a memo using OpenAI
final fixMemoGrammarProvider = FutureProvider.family<void, String>((
  ref,
  memoId,
) async {
  if (kDebugMode) {
    print('[fixMemoGrammarProvider] Starting grammar fix for memo: $memoId');
  }

  // Get required services
  final ApiService memosApiService = ref.read(
    api_p.apiServiceProvider,
  ); // Use alias
  final OpenaiApiService openaiApiService = ref.read(
    api_p.openaiApiServiceProvider,
  );

  // Check if OpenAI service is configured
  if (!openaiApiService.isConfigured) {
    if (kDebugMode) {
      print(
        '[fixMemoGrammarProvider] OpenAI service not configured. Aborting.',
      );
    }
    throw Exception('OpenAI API key is not configured in settings.');
  }

  try {
    // 1. Fetch the current memo content from Memos API
    if (kDebugMode) print('[fixMemoGrammarProvider] Fetching memo content...');
    final Memo currentMemo = await memosApiService.getMemo(memoId);
    final String originalContent = currentMemo.content;

    if (originalContent.trim().isEmpty) {
      if (kDebugMode) {
        print('[fixMemoGrammarProvider] Memo content is empty. Skipping.');
      }
      return; // Nothing to fix
    }

    // 2. Call OpenAI service to fix grammar
    if (kDebugMode) print('[fixMemoGrammarProvider] Calling OpenAI API...');
    final String correctedContent = await openaiApiService.fixGrammar(
      originalContent,
    );

    // 3. Check if content actually changed
    if (correctedContent == originalContent ||
        correctedContent.trim().isEmpty) {
      if (kDebugMode) {
        print(
          '[fixMemoGrammarProvider] Content unchanged or correction empty. No update needed.',
        );
      }
      // Optionally show a message to the user that no changes were made
      return;
    }

    if (kDebugMode) {
      print('[fixMemoGrammarProvider] Content corrected. Updating memo...');
    }

    // 4. Update the memo using Memos API (updateMemo requires the full object)
    final Memo updatedMemoData = currentMemo.copyWith(
      content: correctedContent,
    );
    final Memo resultMemo = await memosApiService.updateMemo(
      memoId,
      updatedMemoData,
    );

    // 5. Update UI optimistically and refresh caches/providers
    // Update the memo in the main list notifier
    ref
        .read(memosNotifierProvider.notifier)
        .updateMemoOptimistically(resultMemo);
    // Update the detail cache
    ref
        .read(memoDetailCacheProvider.notifier)
        .update((state) => {...state, memoId: resultMemo});
    // Invalidate the specific detail provider to ensure it shows the latest data if navigated back
    ref.invalidate(memoDetailProvider(memoId));
    // Invalidate comments provider? Unlikely to change, but maybe for consistency.
    // ref.invalidate(memoCommentsProvider(memoId));

    if (kDebugMode) {
      print(
        '[fixMemoGrammarProvider] Memo $memoId updated successfully with corrected grammar.',
      );
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print(
        '[fixMemoGrammarProvider] Error fixing grammar for memo $memoId: $e',
      );
      print(stackTrace);
    }
    // Rethrow the error so the UI layer can catch it and display a message
    rethrow;
  }
});
