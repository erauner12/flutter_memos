import 'package:flutter/foundation.dart';
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
      final memoId = id.split('/').first; // Assuming format "memoId/commentId"
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
      // Delete the comment
      final parts = id.split('/');
      final memoId = parts.isNotEmpty ? parts.first : '';
      final commentId = parts.length > 1 ? parts.last : id;
      
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
      // Get the comment
      final comment = await apiService.getMemoComment(id);
      
      // Toggle the pinned state
      final updatedComment = comment.copyWith(pinned: !comment.pinned);
      
      // Update through API
      await apiService.updateMemoComment(id, updatedComment);
      
      // Refresh comments for this memo
      final memoId = id.split('/').first; // Assuming format "memoId/commentId"
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
