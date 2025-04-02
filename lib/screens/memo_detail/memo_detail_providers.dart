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

// addCommentProvider has been removed as it's now replaced by createCommentProvider in comment_providers.dart
