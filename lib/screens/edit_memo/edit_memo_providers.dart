import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/memo_detail_provider.dart'
    hide memoCommentsProvider; // Hide the ambiguous name
import 'package:flutter_memos/providers/memo_providers.dart' as memo_providers;
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart'
    show memoCommentsProvider; // Import memoCommentsProvider explicitly
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parameter class for entity providers to ensure consistent == checks.
class EntityProviderParams {
  final String id;
  final String type;

  EntityProviderParams({required this.id, required this.type});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EntityProviderParams &&
        other.id == id &&
        other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() => 'EntityProviderParams(id: $id, type: $type)';
}


// Provider for the current entity (Memo or Comment) being edited
final editEntityProvider = FutureProvider.family<dynamic, EntityProviderParams>(
  (
  ref,
    params, // Use EntityProviderParams
) async {
  final apiService = ref.watch(apiServiceProvider);
    final id = params.id; // Access id from params
    final type = params.type; // Access type from params

  if (kDebugMode) {
    print('[editEntityProvider] Fetching $type with ID: $id');
  }

  if (type == 'comment') {
    return apiService.getMemoComment(id); // id is "memoId/commentId"
  } else {
    // Default 'memo'
    return apiService.getMemo(id); // id is memoId
  }
}, name: 'editEntityProvider'); // Optional: Add name for debugging

// Provider for saving entity (Memo or Comment) changes
final saveEntityProvider = Provider.family<
  Future<void> Function(dynamic),
  EntityProviderParams // Use EntityProviderParams
>((ref, params) {
  final id = params.id; // Access id from params
  final type = params.type; // Access type from params

  return (dynamic updatedEntity) async {
    final apiService = ref.read(apiServiceProvider);

    if (kDebugMode) {
      print('[saveEntityProvider] Saving $type with ID: $id');
    }

    if (type == 'comment') {
      final comment = updatedEntity as Comment;
      final parts = id.split('/');
      if (parts.length < 2)
        throw ArgumentError('Invalid comment ID format for saving: $id');
      final parentMemoId = parts[0];

      // 1. Update the comment
      await apiService.updateMemoComment(id, comment);
      if (kDebugMode)
        print('[saveEntityProvider] Comment $id updated successfully.');

      // 2. Bump the parent memo (try-catch to avoid failing the whole save)
      try {
        if (kDebugMode)
          print('[saveEntityProvider] Bumping parent memo: $parentMemoId');
        await ref.read(memo_providers.bumpMemoProvider(parentMemoId))();
        if (kDebugMode)
          print(
            '[saveEntityProvider] Parent memo $parentMemoId bumped successfully.',
          );
      } catch (e, s) {
        if (kDebugMode)
          print(
            '[saveEntityProvider] Failed to bump parent memo $parentMemoId: $e\n$s',
          );
        // Optionally report error via error handler provider
        // ref.read(errorHandlerProvider)('Failed to bump parent memo after comment update', source: 'saveEntityProvider', error: e, stackTrace: s);
      }

      // 3. Invalidate relevant providers
      ref.invalidate(
        memoCommentsProvider(parentMemoId),
      ); // Refresh comments for the parent memo
      ref.invalidate(
        memo_providers.memosProvider,
      ); // Refresh main memo list because parent was bumped
    } else {
      // type == 'memo'
      final memo = updatedEntity as Memo;

      // Update memo in the backend
      final savedMemo = await apiService.updateMemo(id, memo);
      if (kDebugMode)
        print('[saveEntityProvider] Memo $id updated successfully.');

      // Update memo detail cache if it exists
      if (ref.exists(memo_providers.memoDetailCacheProvider)) {
        ref
            .read(memo_providers.memoDetailCacheProvider.notifier)
            .update((state) => {...state, id: savedMemo});
      }

      // Invalidate all related providers to ensure UI is consistent
      ref.invalidate(memo_providers.memosProvider); // Refresh the memos list
      ref.invalidate(memoDetailProvider(id)); // Refresh memo detail

      // Clear any hidden memo IDs for this memo to ensure it's visible
      ref
          .read(memo_providers.hiddenMemoIdsProvider.notifier)
          .update((state) => state.contains(id) ? (state..remove(id)) : state);
    }
  };
}, name: 'saveEntityProvider'); // Optional: Add name for debugging
