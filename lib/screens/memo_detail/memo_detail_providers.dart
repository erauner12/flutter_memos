import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/utils/comment_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for memo details
final memoDetailProvider = FutureProvider.family<NoteItem, String>((
  ref,
  id,
) async {
  // Changed return type to NoteItem
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getNote(id); // Use getNote
});

// Provider for memo comments
final memoCommentsProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  memoId,
) async {
  final apiService = ref.watch(apiServiceProvider);
  final comments = await apiService.listNoteComments(
    memoId,
  ); // Use listNoteComments

  // Sort comments with pinned first, then by *update* time
  CommentUtils.sortByPinnedThenUpdateTime(
    comments,
  ); // &lt;-- Apply requested change

  return comments;
});
