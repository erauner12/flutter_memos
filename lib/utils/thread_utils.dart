import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/workbench_item_type.dart'; // Corrected import path
import 'package:flutter_memos/providers/api_providers.dart'; // Import API providers
// Import new single config providers
import 'package:flutter_memos/providers/note_server_config_provider.dart';
import 'package:flutter_memos/providers/task_server_config_provider.dart';
import 'package:flutter_memos/services/base_api_service.dart'; // For BaseApiService
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_memos/services/task_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Fetches the parent item and all its comments, returning a formatted string.
///
/// Throws an error if fetching fails, the item's server config doesn't match
/// the configured note/task server, or the required service is not configured.
Future<String> getFormattedThreadContent(
  WidgetRef ref,
  String itemId,
  WorkbenchItemType itemType,
  String itemServerId, // The server ID associated with the item
) async {
  // 1. Initialize variables
  final buffer = StringBuffer();
  List<Comment> comments = [];
  BaseApiService? apiService; // Nullable initially

  // 2. Determine the correct API service based on itemType and itemServerId
  if (itemType == WorkbenchItemType.note) {
    final noteConfig = ref.read(noteServerConfigProvider);
    if (noteConfig == null || noteConfig.id != itemServerId) {
      throw Exception(
        'Note server ($itemServerId) does not match configured note server (${noteConfig?.id}). Cannot fetch note thread.',
      );
    }
    apiService = ref.read(
      noteApiServiceProvider,
    ); // Get configured note service
    if (apiService is! NoteApiService || apiService is DummyNoteApiService) {
      throw Exception(
        'Cannot fetch note thread: Note API service is not properly configured.',
      );
    }

    // Fetch note and comments using the NoteApiService
    final note = await (apiService).getNote(itemId);
    final parentTimestamp = note.createTime;
    final parentHeader =
        'Note (${note.id}) - ${DateFormat.yMd().add_jm().format(parentTimestamp.toLocal())}:';
    buffer.writeln(parentHeader);
    buffer.writeln('---');
    buffer.writeln(note.content.trim());
    comments = await (apiService).listNoteComments(itemId);

  } else if (itemType == WorkbenchItemType.task) {
    final taskConfig = ref.read(taskServerConfigProvider);
    if (taskConfig == null || taskConfig.id != itemServerId) {
      throw Exception(
        'Task server ($itemServerId) does not match configured task server (${taskConfig?.id}). Cannot fetch task thread.',
      );
    }
    apiService = ref.read(
      taskApiServiceProvider,
    ); // Get configured task service
    if (apiService is! TaskApiService || apiService is DummyTaskApiService) {
      throw Exception(
        'Cannot fetch task thread: Task API service is not properly configured.',
      );
    }

    // Fetch task and comments using the TaskApiService
    final task = await (apiService).getTask(itemId);
    buffer.writeln("# Task: ${task.title}");
    buffer.writeln();
    buffer.writeln(
      "**Description**: ${task.description?.isNotEmpty == true ? task.description : 'N/A'}",
    );
    buffer.writeln();
    comments = await (apiService).listComments(itemId);

  } else {
    throw Exception('Unsupported item type ($itemType) for thread fetching.');
  }

  // 3. Sort Comments Chronologically (Oldest First)
  comments.sort((a, b) => a.createdTs.compareTo(b.createdTs));

  // 4. Format Comments based on item type
  if (itemType == WorkbenchItemType.note) {
    buffer.writeln('\n---\nComments:\n---');
    if (comments.isEmpty) {
      buffer.writeln('(No comments)');
    } else {
      for (final comment in comments) {
        final timestamp = comment.createdTs;
        buffer.writeln(
          '\nComment (${comment.id}) - ${DateFormat.yMd().add_jm().format(timestamp.toLocal())}:',
        );
        buffer.writeln((comment.content ?? '(No content)').trim());
      }
    }
  } else if (itemType == WorkbenchItemType.task) {
    buffer.writeln("## Comments:");
    if (comments.isNotEmpty) {
      for (final comment in comments) {
        final author = comment.creatorId ?? 'Unknown Author';
        final text = comment.content ?? '(No content)';
        buffer.writeln("- $author: ${text.trim()}");
      }
    }
    // No "(No comments)" for tasks
  }

  return buffer.toString();
}
