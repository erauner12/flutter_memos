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

/// Provider for the current filter key ('inbox', 'archive', 'all', or a tag)
final filterKeyProvider = StateProvider<String>((ref) => 'inbox');

/// Provider that fetches memos and applies filters and sorting
final memosProvider = FutureProvider<List<Memo>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final combinedFilter = ref.watch(combinedFilterProvider);
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
  
  // Status filter untagged - applying additional client-side filtering if needed
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
    final apiService = ref.read(apiServiceProvider);
    
    // Delete the memo
    await apiService.deleteMemo(id);
    
    // Refresh the memos list
    ref.invalidate(memosProvider);
  };
});
