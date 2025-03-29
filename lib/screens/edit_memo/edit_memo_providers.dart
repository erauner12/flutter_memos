import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/memo_detail_provider.dart';
import 'package:flutter_memos/providers/memo_providers.dart' as memo_providers;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the current memo being edited
final editMemoProvider = FutureProvider.family<Memo, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMemo(id);
});

// Provider for saving memo changes
final saveMemoProvider = Provider.family<Future<void> Function(Memo), String>((
  ref,
  id,
) {
  return (Memo updatedMemo) async {
    final apiService = ref.read(apiServiceProvider);
    
    if (kDebugMode) {
      print('[saveMemoProvider] Updating memo: $id');
      print(
        '[saveMemoProvider] Before update: createTime=${updatedMemo.createTime}, updateTime=${updatedMemo.updateTime}',
      );
    }
    
    // Update memo in the backend
    final savedMemo = await apiService.updateMemo(id, updatedMemo);

    if (kDebugMode) {
      print(
        '[saveMemoProvider] After update: createTime=${savedMemo.createTime}, updateTime=${savedMemo.updateTime}',
      );
    }

    // Update memo detail cache if it exists
    if (ref.exists(memoDetailCacheProvider)) {
      ref
          .read(memoDetailCacheProvider.notifier)
          .update((state) => {...state, id: savedMemo});
    }

    // Invalidate all related providers to ensure UI is consistent
    ref.invalidate(memo_providers.memosProvider); // Refresh the memos list
    
    // Also invalidate memo detail provider if it exists
    ref.invalidate(memoDetailProvider(id));

    // Clear any hidden memo IDs for this memo to ensure it's visible
    ref
        .read(memo_providers.hiddenMemoIdsProvider.notifier)
        .update((state) => state.contains(id) ? (state..remove(id)) : state);
  };
});
