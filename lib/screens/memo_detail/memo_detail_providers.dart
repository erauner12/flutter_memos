import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/utils/comment_utils.dart';
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
  final comments = await apiService.listMemoComments(memoId);

  // Sort comments with pinned first, then by *update* time
  CommentUtils.sortByPinnedThenUpdateTime(
    comments,
  ); // <-- Apply requested change

  return comments;
});
