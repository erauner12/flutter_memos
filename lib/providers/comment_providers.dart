import 'package:flutter/foundation.dart';
import 'package:flutter_memos/api/lib/api.dart'; // Add this import for V1Resource
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/memo_relation.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart'
    show memoCommentsProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      
      // Try to create a relation between the new memo and the original memo
      // But continue even if this part fails
      if (memoId.isNotEmpty) {
        try {
          final relation = MemoRelation(
            relatedMemoId: memoId,
            type: MemoRelation.typeComment,
          );
          
          await apiService.setMemoRelations(createdMemo.id, [relation]);
        } catch (relationError) {
          // Log but don't fail the whole conversion if relation setting fails
          if (kDebugMode) {
            print(
              '[convertCommentToMemoProvider] Warning: Created memo but failed to set relation: $relationError',
            );
          }
        }
      }
      
      // Refresh memos list using the new notifier
      // ref.invalidate(memosProvider); // Old way
      await ref.read(memosNotifierProvider.notifier).refresh(); // New way
      
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

/// Provider for creating a comment for a memo, potentially with an attachment
/// Provider for creating a comment for a memo, potentially with an attachment
final createCommentProvider = Provider.family<
  Future<Comment> Function(
    Comment comment, {
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
  }),
  String
>((ref, memoId) {
  return (
    Comment comment, {
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
  }) async {
    // Add logging here
    if (kDebugMode) {
      print('[createCommentProvider] Called for memoId: $memoId');
      print('[createCommentProvider] Comment content: "${comment.content}"');
      print(
        '[createCommentProvider] File details: filename=$filename, contentType=$contentType, data_length=${fileBytes?.length}',
      );
    }

    final apiService = ref.read(apiServiceProvider);
    List<V1Resource>? uploadedResources;

    try {
      // 1. Upload resource if provided
      if (fileBytes != null && filename != null && contentType != null) {
        if (kDebugMode) {
          print(
            '[createCommentProvider] Uploading attachment: $filename ($contentType, ${fileBytes.length} bytes)',
          );
        }
        final uploadedResource = await apiService.uploadResource(
          fileBytes,
          filename,
          contentType,
        );
        uploadedResources = [uploadedResource];
        if (kDebugMode) {
          print(
            '[createCommentProvider] Attachment uploaded: ${uploadedResource.name}',
          );
        }
      }

      // 2. Create the comment, passing uploaded resources
      if (kDebugMode) {
        print(
          '[createCommentProvider] Creating comment for memo $memoId with ${uploadedResources?.length ?? 0} attachments.',
        );
      }
      final createdComment = await apiService.createMemoComment(
        memoId,
        comment,
        resources: uploadedResources, // Pass resources here
      );
      if (kDebugMode) {
        print('[createCommentProvider] Comment created: ${createdComment.id}');
      }

      // 3. Bump the parent memo after successful comment creation
      try {
        if (kDebugMode) {
          print(
            '[createCommentProvider] Bumping parent memo $memoId after comment creation.',
          );
        }
        // Assuming bumpMemoProvider exists and works correctly
        // await ref.read(bumpMemoProvider(memoId))();
      } catch (e) {
        // Log error but don't fail the comment creation
        if (kDebugMode) {
          print(
            '[createCommentProvider] Warning: Error bumping parent memo $memoId: $e',
          );
        }
      }

      // 4. Invalidate comments list for the specific memo
      ref.invalidate(memoCommentsProvider(memoId));

      return createdComment;
    } catch (e, stackTrace) {
      // Add stackTrace
      if (kDebugMode) {
        print(
          '[createCommentProvider] Error creating comment for memo $memoId: $e\n$stackTrace', // Log stacktrace
        );
      }
      rethrow; // Rethrow the error to be handled by the caller UI
    }
  };
});
