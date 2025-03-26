import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for memo details
final memoDetailProvider = FutureProvider.family<Memo, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMemo(id);
});

// Provider for memo comments
final memoCommentsProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  memoId,
) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.listMemoComments(memoId);
});

// Provider for adding a comment
final addCommentProvider =
    Provider.family<Future<void> Function(Comment), String>((ref, memoId) {
      return (Comment comment) async {
        final apiService = ref.read(apiServiceProvider);
        await apiService.createMemoComment(memoId, comment);
        ref.invalidate(memoCommentsProvider(memoId)); // Refresh comments
      };
    });
