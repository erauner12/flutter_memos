import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart'; // For WorkbenchItemType
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/services/base_api_service.dart'; // For BaseApiService
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_memos/services/task_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Fetches the parent item and all its comments, returning a formatted string.
///
/// Throws an error if fetching fails or the item's server is not active.
Future<String> getFormattedThreadContent(
  WidgetRef ref,
  String itemId,
  WorkbenchItemType itemType,
  String itemServerId,
) async {
  // 1. Check if the item's server is active
  final activeServer = ref.read(activeServerConfigProvider);
  if (activeServer == null || activeServer.id != itemServerId) {
    throw Exception(
      'Item server ($itemServerId) is not the active server (${activeServer?.id}).',
    );
  }

  // 2. Get the correct API service (based on active server type)
  final BaseApiService apiService = ref.read(apiServiceProvider);

  String parentContent = '';
  String parentHeader = '';
  List<Comment> comments = [];
  DateTime parentTimestamp = DateTime.now();
  String parentId = itemId;

  // 3. Fetch Parent Item and Comments based on type
  if (itemType == WorkbenchItemType.note && apiService is NoteApiService) {
    final note = await apiService.getNote(itemId);
    parentContent = note.content;
    parentTimestamp = note.createTime;
    parentId = note.id;
    parentHeader =
        'Note ($parentId) - ${DateFormat.yMd().add_jm().format(parentTimestamp.toLocal())}:';
    comments = await apiService.listNoteComments(itemId);
  } else if (itemType == WorkbenchItemType.task && apiService is TaskApiService) {
    final task = await apiService.getTask(itemId);
    parentContent = task.content; // Task model has content
    parentTimestamp = task.createdAt; // Task model has createdAt
    parentId = task.id;
    parentHeader =
        'Task ($parentId) - ${DateFormat.yMd().add_jm().format(parentTimestamp.toLocal())}:';
    // Use the overridden listComments from TaskApiService
    comments = await apiService.listComments(itemId);
  } else if (itemType == WorkbenchItemType.comment) {
    // For a comment, fetch the comment itself AND its parent (Note or Task)
    // This requires knowing the parent type, which isn't directly in WorkbenchItemReference
    // We might need to enhance WorkbenchItemReference or make assumptions.
    // Assumption: Comments in workbench currently only come from Notes.
    // TODO: Enhance this if Tasks can have comments added to workbench.

    if (apiService is NoteApiService) {
      // Fetch the comment first to get its parentId (assuming it's a noteId)
      // Note: getNoteComment might not exist, or we might need parentId context.
      // Let's assume we need to list comments for the parent and find ours.
      // This is inefficient. A better approach would be to store parentType in WorkbenchItemReference.
      // For now, throwing unimplemented.
      if (kDebugMode) {
        print(
          "Fetching thread for comment $itemId. Parent context needed for robust implementation.",
        );
      }
      throw UnimplementedError(
        'Copying thread starting from a comment requires parent context (type and ID) which is not fully available yet.',
      );
      // --- Potential future logic ---
      // Comment commentData = await apiService.getComment(itemId); // Needs parent context?
      // String parentNoteId = commentData.parentId;
      // NoteItem note = await apiService.getNote(parentNoteId);
      // parentContent = note.content;
      // parentTimestamp = note.createTime;
      // parentId = note.id;
      // parentHeader = 'Note ($parentId) - ${DateFormat.yMd().add_jm().format(parentTimestamp.toLocal())}:';
      // comments = await apiService.listNoteComments(parentNoteId);
      // --- End potential logic ---
    } else {
      throw Exception(
        'Cannot fetch comment thread: Active API service is not NoteApiService.',
      );
    }
  } else {
    throw Exception(
      'Unsupported item type ($itemType) or API service mismatch (${apiService.runtimeType}).',
    );
  }

  // 4. Sort Comments Chronologically (Oldest First)
  comments.sort((a, b) {
    // Use createdTs, default to epoch if null
    final timeA = a.createdTs;
    final timeB = b.createdTs;
    return timeA.compareTo(timeB);
  });

  // 5. Format the Output String
  final buffer = StringBuffer();
  buffer.writeln(parentHeader);
  buffer.writeln('---');
  buffer.writeln(parentContent.trim()); // Trim parent content
  buffer.writeln('\n---\nComments:\n---');

  if (comments.isEmpty) {
    buffer.writeln('(No comments)');
  } else {
    for (final comment in comments) {
      final timestamp = comment.createdTs;
      buffer.writeln(
        '\nComment (${comment.id}) - ${DateFormat.yMd().add_jm().format(timestamp.toLocal())}:',
      );
      buffer.writeln((comment.content ?? '(No content)').trim()); // Trim comment content
    }
  }

  return buffer.toString();
}
