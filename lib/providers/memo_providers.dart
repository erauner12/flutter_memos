import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum for memo sort mode
enum MemoSortMode { byUpdateTime, byCreateTime }

/// Provider for the current sort mode
final memoSortModeProvider = StateProvider<MemoSortMode>((ref) => MemoSortMode.byUpdateTime);

/// Provider for the list of hidden memo IDs
final hiddenMemoIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Provider that fetches memos and applies filters and sorting
///
/// This provider caches its results to avoid unnecessary API calls
/// when other parts of the state change. It only refreshes when
/// filter-related providers change.
final memosProvider = FutureProvider<List<Memo>>((ref) async {
  // Keep the provider alive to maintain the cache
  ref.keepAlive();

  // Watch dependencies
  final apiService = ref.watch(apiServiceProvider);
  
  // Use select() to only listen for changes to the filter string,
  // not the entire filter object
  final combinedFilter = ref.watch(combinedFilterProvider);
  
  // Watch only the enum value, not the entire provider state
  final sortMode = ref.watch(memoSortModeProvider);
  final filterKey = ref.watch(filterKeyProvider);
  
  // Determine sort field based on current sort mode
  final String sortField = sortMode == MemoSortMode.byUpdateTime ? 'updateTime' : 'createTime';
  
  String? filter = combinedFilter.isNotEmpty ? combinedFilter : null;
  String state = '';
  
  // Apply filter logic for category/visibility
  if (filterKey == 'inbox') {
    state = 'NORMAL';
  } else if (filterKey == 'archive') {
    state = 'ARCHIVED';
  } else if (filterKey != 'all') {
    // If filter is null, set it to the tag filter, otherwise append to existing filter
    final tagFilter = 'tags=="$filterKey"';
    filter = filter == null ? tagFilter : FilterBuilder.and([filter, tagFilter]);
  }
  
  // Fetch memos with the constructed filter
  final memos = await apiService.listMemos(
    parent: 'users/1', // Specify the current user
    filter: filter,
    state: state,
    sort: sortField,
    direction: 'DESC', // Always newest first
  );
  
  // Only read this once when needed, don't watch it to avoid unnecessary rebuilds
  final statusFilter = ref.read(statusFilterProvider);
  if (statusFilter == 'untagged' && memos.isNotEmpty) {
    // Double-check client-side to ensure we only show truly untagged memos
    return memos.where((memo) {
      // Check if the memo has no tags
      final hasTags = memo.content.contains('#') ||
          (memo.resourceNames != null && memo.resourceNames!.isNotEmpty);
      return !hasTags;
    }).toList();
  }
  
  return memos;
});

/// Provider that returns only visible memos (not hidden)
final visibleMemosProvider = Provider<AsyncValue<List<Memo>>>((ref) {
  final memosAsync = ref.watch(memosProvider);
  final hiddenMemoIds = ref.watch(hiddenMemoIdsProvider);
  
  return memosAsync.whenData((memos) {
    return memos.where((memo) => !hiddenMemoIds.contains(memo.id)).toList();
  });
});

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
    
    // Refresh the memos list
    ref.invalidate(memosProvider);
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
      
      // Refresh the memos list
      ref.invalidate(memosProvider);
      
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

/// OPTIMIZATION: Provider for updating a memo with optimistic updates
final updateMemoProvider = Provider.family<Future<Memo> Function(Memo), String>(
  (ref, id) {
    return (Memo updatedMemo) async {
      if (kDebugMode) {
        print('[updateMemoProvider] Updating memo: $id');
      }

      final apiService = ref.read(apiServiceProvider);

      try {
        // Update memo through API
        final result = await apiService.updateMemo(id, updatedMemo);

        // Refresh memo list to get updated data
        ref.invalidate(memosProvider);

        // Also update any cache entries if we've implemented caching
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

        // Let AsyncValue handle the error
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

      // Update through API
      final result = await apiService.updateMemo(id, updatedMemo);

      // Refresh memos list
      ref.invalidate(memosProvider);

      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[togglePinMemoProvider] Error toggling pin state: $e');
        print(stackTrace);
      }

      // Let AsyncValue handle the error
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

      // Refresh memos list
      ref.invalidate(memosProvider);
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
