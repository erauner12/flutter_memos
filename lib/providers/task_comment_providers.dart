import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/api_providers.dart'; // Import taskApiServiceProvider
import 'package:flutter_memos/services/task_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Helper function to get the configured TaskApiService
TaskApiService _getTaskApiService(Ref ref) {
  final service = ref.read(taskApiServiceProvider);
  if (service is DummyTaskApiService) {
    throw Exception(
      "Task API service is not properly configured (Dummy service returned).",
    );
  }
  return service;
}

/// Provider family to fetch comments for a specific task ID.
final taskCommentsProvider = FutureProvider.family<List<Comment>, String>((ref, taskId) async {
  final apiService = _getTaskApiService(ref);
  try {
    final comments = await apiService.listComments(taskId);
    // Optional: Sort comments here if needed (e.g., by creation date)
    comments.sort((a, b) => a.createdTs.compareTo(b.createdTs));
    return comments;
  } catch (e) {
    if (kDebugMode) print('[taskCommentsProvider] Error fetching comments for task $taskId: $e');
    throw Exception('Failed to load comments for task $taskId: $e');
  }
});

/// Parameter record for task comment action providers
typedef TaskCommentActionParams = ({String taskId, String commentId});

/// Parameter record for task comment creation provider
typedef CreateTaskCommentParams = ({String taskId});

/// Provider family for creating a comment for a task.
final createTaskCommentProvider = Provider.family<
  Future<Comment> Function(Comment comment),
  CreateTaskCommentParams
>((ref, params) {
  return (Comment comment) async {
    final apiService = _getTaskApiService(ref);
    final taskId = params.taskId;
    try {
      if (kDebugMode) print('[createTaskCommentProvider] Creating comment for task $taskId');
      // Ensure the comment has the correct parentId
      final commentToCreate = comment.copyWith(parentId: taskId);
      final createdComment = await apiService.createComment(taskId, commentToCreate);
      ref.invalidate(taskCommentsProvider(taskId)); // Invalidate list to refresh UI
      if (kDebugMode) print('[createTaskCommentProvider] Comment ${createdComment.id} created for task $taskId');
      return createdComment;
    } catch (e) {
      if (kDebugMode) print('[createTaskCommentProvider] Error creating comment for task $taskId: $e');
      rethrow;
    }
  };
});

/// Provider family for updating a task comment's content.
final updateTaskCommentProvider = Provider.family<
  Future<Comment> Function(String newContent),
  TaskCommentActionParams
>((ref, params) {
  return (String newContent) async {
    final apiService = _getTaskApiService(ref);
    final taskId = params.taskId;
    final commentId = params.commentId;
    try {
      if (kDebugMode) print('[updateTaskCommentProvider] Updating comment $commentId for task $taskId');
      // Fetch existing comment to update (or assume comment object passed in has necessary info)
      // Vikunja update might just need the ID and new content.
      // We need the parentId (taskId) for the API call in VikunjaApiService.
      final commentToUpdate = Comment(
        id: commentId,
        parentId: taskId,
        content: newContent,
        createdTs: DateTime.now(), // Placeholder, not used for update payload typically
        serverId: '', // Placeholder, not used for update payload typically
      );
      final updatedComment = await apiService.updateComment(commentId, commentToUpdate);
      ref.invalidate(taskCommentsProvider(taskId)); // Invalidate list to refresh UI
      if (kDebugMode) print('[updateTaskCommentProvider] Comment $commentId updated for task $taskId');
      return updatedComment;
    } catch (e) {
      if (kDebugMode) print('[updateTaskCommentProvider] Error updating comment $commentId for task $taskId: $e');
      rethrow;
    }
  };
});

/// Provider family for deleting a task comment.
final deleteTaskCommentProvider = Provider.family<
  Future<void> Function(),
  TaskCommentActionParams
>((ref, params) {
  return () async {
    final apiService = _getTaskApiService(ref);
    final taskId = params.taskId;
    final commentId = params.commentId;
    try {
      if (kDebugMode) print('[deleteTaskCommentProvider] Deleting comment $commentId for task $taskId');
      await apiService.deleteComment(taskId, commentId);
      ref.invalidate(taskCommentsProvider(taskId)); // Invalidate list to refresh UI
      if (kDebugMode) print('[deleteTaskCommentProvider] Comment $commentId deleted for task $taskId');
    } catch (e) {
      if (kDebugMode) print('[deleteTaskCommentProvider] Error deleting comment $commentId for task $taskId: $e');
      rethrow;
    }
  };
});

// Add other providers if needed (e.g., for pinning if supported locally, grammar fix, etc.)
// For now, focus on CRUD operations.
