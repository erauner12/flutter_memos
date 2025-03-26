import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/memo_relation.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart'
    show memoCommentsProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment.dart';
import 'api_providers.dart';

/// Provider for the list of hidden comment IDs (local state only)
final hiddenCommentIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Provider for archiving a comment
final archiveCommentProvider = Provider.family<Future<void> Function(), String>((ref, id) {
  return () async {
    final apiService = ref.read(apiServiceProvider);
    
    try {
        // Extract memoId from combined ID (format: "memoId/commentId")
        final parts = id.split('/');
        final String memoId = parts.isNotEmpty ? parts[0] : '';
      
      // Get the comment
      final comment = await apiService.getMemoComment(id);
      
      // Update the comment to archived state
      final updatedComment = comment.copyWith(
        pinned: false,
        state: CommentState.archived,
      );
      
      // Save the updated comment
      await apiService.updateMemoComment(id, updatedComment);
      
        // Refresh comments for this memo
      if (memoId.isNotEmpty) {
        ref.invalidate(memoCommentsProvider(memoId));
      }
      
      if (kDebugMode) {
        print('[archiveCommentProvider] Comment archived: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[archiveCommentProvider] Error archiving comment: $e');
      }
      rethrow;
    }
  };
});

/// Provider for deleting a comment
final deleteCommentProvider = Provider.family<Future<void> Function(), String>((ref, id) {
  return () async {
    final apiService = ref.read(apiServiceProvider);
    
    try {
      // Extract parts from the combined ID (format: "memoId/commentId")
      final parts = id.split('/');
      final memoId = parts.isNotEmpty ? parts.first : '';
      final commentId = parts.length > 1 ? parts.last : id;
      
      // Delete the comment
      await apiService.deleteMemoComment(memoId, commentId);
      
      // Refresh comments for this memo
      if (memoId.isNotEmpty) {
        ref.invalidate(memoCommentsProvider(memoId));
      }
      
      if (kDebugMode) {
        print('[deleteCommentProvider] Comment deleted: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[deleteCommentProvider] Error deleting comment: $e');
      }
      rethrow;
    }
  };
});

/// Provider for toggling the pin state of a comment
final togglePinCommentProvider = Provider.family<Future<void> Function(), String>((ref, id) {
  return () async {
    final apiService = ref.read(apiServiceProvider);

    try {
          // Extract memoId from combined ID (format: "memoId/commentId")
          final parts = id.split('/');
          final String memoId = parts.isNotEmpty ? parts[0] : '';
      
      // Get the comment
      final comment = await apiService.getMemoComment(id);
      
      // Toggle the pinned state
      final updatedComment = comment.copyWith(pinned: !comment.pinned);
      
      // Update through API
      await apiService.updateMemoComment(id, updatedComment);
      
          // Refresh comments for this memo
      if (memoId.isNotEmpty) {
        ref.invalidate(memoCommentsProvider(memoId));
      }
      
      if (kDebugMode) {
        print('[togglePinCommentProvider] Comment pin toggled: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[togglePinCommentProvider] Error toggling pin: $e');
      }
      rethrow;
    }
  };
});

/// Provider to check if a comment is hidden
final isCommentHiddenProvider = Provider.family<bool, String>((ref, id) {
  final hiddenCommentIds = ref.watch(hiddenCommentIdsProvider);
  return hiddenCommentIds.contains(id);
});

/// Provider for converting a comment to a full memo
final convertCommentToMemoProvider = Provider.family<
  Future<Memo> Function(),
  String
>((ref, id) {
  return () async {
    final apiService = ref.read(apiServiceProvider);

    try {
      // Extract parts from the combined ID (format: "memoId/commentId")
      final parts = id.split('/');
      final memoId = parts.isNotEmpty ? parts.first : '';
      final commentId = parts.length > 1 ? parts.last : id;

      if (kDebugMode) {
        print('[convertCommentToMemoProvider] Converting comment to memo: $id');
      }

      // Get the comment
      final comment = await apiService.getMemoComment(id);

      // Create a new memo from the comment's content
      final newMemo = Memo(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        content: comment.content,
        // Reset pinned state for the new memo
        pinned: false,
        state: MemoState.normal,
        visibility: 'PUBLIC', // Default visibility
      );

      // Create the new memo
      final createdMemo = await apiService.createMemo(newMemo);

      // Create a relation between the new memo and the original memo
      if (memoId.isNotEmpty) {
        final relation = MemoRelation(
          relatedMemoId: memoId,
          type: RelationType.linked,
        );

        await apiService.setMemoRelations(createdMemo.id, [relation]);
      }

      // Refresh memos list
      ref.invalidate(memosProvider);

      if (kDebugMode) {
        print(
          '[convertCommentToMemoProvider] Converted comment to memo: ${createdMemo.id}',
        );
      }

      return createdMemo;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[convertCommentToMemoProvider] Error converting comment to memo: $e',
        );
      }
      rethrow;
    }
  };
});

/// Provider for toggling visibility of a comment in the current view
final toggleHideCommentProvider = Provider.family<void Function(), String>((ref, id) {
  return () {
    final hiddenCommentIds = ref.read(hiddenCommentIdsProvider);
    
    if (hiddenCommentIds.contains(id)) {
      // Unhide the comment
      ref
          .read(hiddenCommentIdsProvider.notifier)
          .update((state) => state..remove(id));
      if (kDebugMode) {
        print('[toggleHideCommentProvider] Unhid comment: $id');
      }
    } else {
      // Hide the comment
      ref
          .read(hiddenCommentIdsProvider.notifier)
          .update((state) => state..add(id));
      if (kDebugMode) {
        print('[toggleHideCommentProvider] Hid comment: $id');
      }
    }
  };
});
