import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/services/api_service.dart'; // Import ApiService
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
  final ApiService _apiService;
  static const int _pageSize = 20; // Or make configurable

  MemosNotifier(this._ref)
    : _apiService = _ref.read(apiServiceProvider),
      super(const MemosState(isLoading: true)) {
    _initialize();
  }

  void _initialize() {
    // Listen to filter changes and trigger refresh
    // Use select to avoid unnecessary refreshes if only part of the filter changes,
    // but the combined result remains the same (less likely but possible).
    _ref.listen(combinedFilterProvider, (_, __) => refresh());
    _ref.listen(filterKeyProvider, (_, __) => refresh());
    // Add listeners for any other providers that should trigger a full refresh
    _ref.listen(statusFilterProvider, (_, __) => refresh());
    _ref.listen(timeFilterProvider, (_, __) => refresh());

    // Fetch initial data
    fetchInitialPage();
  }

  Future<void> _fetchPage({String? pageToken}) async {
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
      final tagFilter = 'tag in ["$filterKey"]';
      finalFilter =
          finalFilter == null
              ? tagFilter
              : FilterBuilder.and([finalFilter, tagFilter]);
    }

    // Read status filter for potential client-side filtering (e.g., untagged)
    final statusFilter = _ref.read(statusFilterProvider);

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
      final response = await _apiService.listMemos(
        parent: 'users/1',
        filter: finalFilter,
        state: stateFilter.isNotEmpty ? stateFilter : null,
        sort: 'updateTime', // Keep consistent sorting
        direction: 'DESC',
        pageSize: _pageSize,
        pageToken: pageToken,
      );

      // Sort client-side by updateTime and pinned status
      MemoUtils.sortByPinnedThenUpdateTime(response.memos);

      var newMemos = response.memos;
      final nextPageToken = response.nextPageToken;

      // Apply client-side filtering if needed (e.g., for 'untagged')
      if (statusFilter == 'untagged' && newMemos.isNotEmpty) {
        newMemos =
            newMemos.where((memo) {
              final hasTags =
                  memo.content.contains('#') ||
                  (memo.resourceNames != null &&
                      memo.resourceNames!.isNotEmpty);
              return !hasTags;
            }).toList();
        if (kDebugMode) {
          print(
            '[MemosNotifier] Applied client-side untagged filter, ${newMemos.length} memos remain.',
          );
        }
      }

      // Determine if we've reached the end
      final hasReachedEnd =
          nextPageToken == null || nextPageToken.isEmpty || newMemos.isEmpty;

      // Update total loaded count
      final newTotalLoaded =
          (pageToken == null)
              ? newMemos.length
              : state.totalLoaded + newMemos.length;

      if (kDebugMode) {
        print('[MemosNotifier] Fetched ${newMemos.length} new memos');
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

  // Optional: Method to update a single memo in the list optimistically
  void updateMemoOptimistically(Memo updatedMemo) {
    state = state.copyWith(
      memos:
          state.memos.map((memo) {
            return memo.id == updatedMemo.id ? updatedMemo : memo;
          }).toList(),
    );
  }

  // Optional: Method to remove a memo from the list optimistically
  void removeMemoOptimistically(String memoId) {
    state = state.copyWith(
      memos: state.memos.where((memo) => memo.id != memoId).toList(),
    );
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

  // Filter the memos currently held in the state
  final visibleMemos =
      memosState.memos.where((memo) {
        // Hide memos that are in the hidden IDs set
        if (hiddenMemoIds.contains(memo.id)) return false;
        // Hide pinned memos if hidePinned is true
        if (hidePinned && memo.pinned) return false;
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
    final apiService = ref.read(apiServiceProvider);

    // Get the memo
    final memo = await apiService.getMemo(id);

    // Update the memo to archived state
    final updatedMemo = memo.copyWith(
      pinned: false,
      state: MemoState.archived,
    );

    // Save the updated memo
    await apiService.updateMemo(id, updatedMemo);

    // Refresh the memos list using the new notifier
    // ref.invalidate(memosProvider); // Old way
    await ref.read(memosNotifierProvider.notifier).refresh(); // New way
  };
});

/// Provider for deleting a memo
final deleteMemoProvider = Provider.family<Future<void> Function(), String>((ref, id) {
  return () async {
    if (kDebugMode) {
      print('[deleteMemoProvider] Deleting memo: $id');
    }

    final apiService = ref.read(apiServiceProvider);

    try {
      // Delete the memo
      await apiService.deleteMemo(id);

      if (kDebugMode) {
        print('[deleteMemoProvider] Successfully deleted memo: $id');
      }

      // Refresh the memos list using the new notifier
      // ref.invalidate(memosProvider); // Old way
      await ref.read(memosNotifierProvider.notifier).refresh(); // New way

      // Also clear from hidden IDs cache if it's there
      ref
          .read(hiddenMemoIdsProvider.notifier)
          .update((state) => state.contains(id) ? (state..remove(id)) : state);

      return;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[deleteMemoProvider] Error deleting memo $id: $e');
        print(stackTrace);
      }
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
    final apiService = ref.read(apiServiceProvider);

    try {
      // Get the current memo data to ensure content isn't lost
      final currentMemo = await apiService.getMemo(id);

      // Call updateMemo - it sends client time as updateTime implicitly
      await apiService.updateMemo(id, currentMemo);

      if (kDebugMode) {
        print('[bumpMemoProvider] Successfully bumped memo: $id');
      }

      // Refresh the memos list to reflect the new order
      // ref.invalidate(memosProvider); // Old way
      await ref.read(memosNotifierProvider.notifier).refresh(); // New way
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[bumpMemoProvider] Error bumping memo $id: $e');
        print(stackTrace);
      }
      // Rethrow to allow UI to show error feedback
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

      final apiService = ref.read(apiServiceProvider);

      try {
      // Optional: Optimistic UI update
      // ref.read(memosNotifierProvider.notifier).updateMemoOptimistically(updatedMemo);

        // Update memo through API
        final result = await apiService.updateMemo(id, updatedMemo);

        // Refresh memo list to get updated data
      // ref.invalidate(memosProvider); // Old way
      await ref.read(memosNotifierProvider.notifier).refresh(); // New way

        // Also update any cache entries if we've implemented caching
      // Note: memoDetailCacheProvider might need adjustment if it relies on memosProvider
        if (ref.exists(memoDetailCacheProvider)) {
          ref
              .read(memoDetailCacheProvider.notifier)
              .update((state) => {...state, id: result});
        }

        return result;
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('[updateMemoProvider] Error updating memo: $e');
          print(stackTrace);
        }
      // Optional: Revert optimistic update on error
      // ref.read(memosNotifierProvider.notifier).refresh(); // Or fetch original memo
        rethrow;
      }
    };
  },
);

/// OPTIMIZATION: Provider for pinning/unpinning memos with optimistic updates
final togglePinMemoProvider = Provider.family<Future<Memo> Function(), String>((
  ref,
  id,
) {
  return () async {
    if (kDebugMode) {
      print('[togglePinMemoProvider] Toggling pin state for memo: $id');
    }

    final apiService = ref.read(apiServiceProvider);

    try {
      // Get the memo
      final memo = await apiService.getMemo(id);

      // Toggle the pinned state
      final updatedMemo = memo.copyWith(pinned: !memo.pinned);

      // Optional: Optimistic UI update
      // ref.read(memosNotifierProvider.notifier).updateMemoOptimistically(updatedMemo);

      // Update through API
      final result = await apiService.updateMemo(id, updatedMemo);

      // Refresh memos list
      // ref.invalidate(memosProvider); // Old way
      await ref.read(memosNotifierProvider.notifier).refresh(); // New way

      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[togglePinMemoProvider] Error toggling pin state: $e');
        print(stackTrace);
      }
      // Optional: Revert optimistic update on error
      // ref.read(memosNotifierProvider.notifier).refresh();
      rethrow;
    }
  };
});

/// OPTIMIZATION: Provider to check if a memo is hidden
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

    final apiService = ref.read(apiServiceProvider);

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

    final apiService = ref.read(apiServiceProvider);
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
