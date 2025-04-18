import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/workbench_item_type.dart'; // Corrected import path
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/services/base_api_service.dart'; // For BaseApiService
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_memos/services/task_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Fetches the parent item and all its comments, returning a formatted string.
///
/// Throws an error if fetching fails, the item's server is not active (for non-global items),
/// or the required service is not configured.
Future<String> getFormattedThreadContent(
  WidgetRef ref,
  String itemId,
  WorkbenchItemType itemType,
  String itemServerId,
) async {
  // 1. Initialize variables
  final buffer = StringBuffer();
  List<Comment> comments = [];
  BaseApiService apiService; // General service variable

  // 2. Determine the correct API service and perform necessary checks
  if (itemType == WorkbenchItemType.task) {
    if (itemServerId == 'global-todoist-integration') {
      // Use the dedicated global Todoist API provider
      final todoistService = ref.read(todoistApiServiceProvider);

      // Check if the global Todoist service is configured
      if (!todoistService.isConfigured) {
        throw Exception(
          'Cannot fetch task thread: Todoist integration is not configured. Please add the API key in Settings.',
        );
      }
      // We know this is a TaskApiService
      apiService = todoistService;

      // Fetch task and comments using the specific service
      final task = await (apiService as TaskApiService).getTask(itemId);
      buffer.writeln("# Task: ${task.content}");
      buffer.writeln(); // Add blank line
      buffer.writeln(
        "**Description**: ${task.description?.isNotEmpty == true ? task.description : 'N/A'}",
      );
      buffer.writeln(); // Add blank line
      comments = await (apiService).listComments(itemId);
    } else {
      // Handle other potential task servers if they exist in the future
      throw Exception('Unrecognized or unsupported task server: $itemServerId');
      // If other task servers could rely on the active server, add logic here:
      // final activeServer = ref.read(activeServerConfigProvider);
      // if (activeServer == null || activeServer.id != itemServerId) {
      //   throw Exception('Task server ($itemServerId) is not the active server (${activeServer?.id}).');
      // }
      // apiService = ref.read(apiServiceProvider);
      // if (apiService is! TaskApiService) {
      //   throw Exception('Cannot fetch task thread: Active API service for $itemServerId is not TaskApiService.');
      // }
      // // Fetch task and comments using the active server's TaskApiService
      // final task = await (apiService as TaskApiService).getTask(itemId);
      // ... fetch comments ...
    }
  } else if (itemType == WorkbenchItemType.note) {
    // Notes always rely on the active server
    final activeServer = ref.read(activeServerConfigProvider);
    if (activeServer == null || activeServer.id != itemServerId) {
      throw Exception(
        'Note server ($itemServerId) is not the active server (${activeServer?.id}). Cannot fetch note thread.',
      );
    }

    // Get the API service for the active server
    apiService = ref.read(apiServiceProvider);
    if (apiService is! NoteApiService) {
      throw Exception(
        'Cannot fetch note thread: Active API service is not NoteApiService.',
      );
    }

    // Fetch note and comments using the NoteApiService
    final note = await (apiService).getNote(itemId);
    final parentTimestamp = note.createTime;
    final parentHeader =
        'Note (${note.id}) - ${DateFormat.yMd().add_jm().format(parentTimestamp.toLocal())}:';
    buffer.writeln(parentHeader);
    buffer.writeln('---');
    buffer.writeln(note.content.trim()); // Trim parent content
    comments = await (apiService).listNoteComments(itemId);

  } else {
    throw Exception('Unsupported item type ($itemType) for thread fetching.');
  }

  // 3. Sort Comments Chronologically (Oldest First) - Applied after fetching
  comments.sort((a, b) {
    final timeA = a.createdTs;
    final timeB = b.createdTs;
    return timeA.compareTo(timeB);
  });

  // 4. Format Comments based on item type
  if (itemType == WorkbenchItemType.note) {
    buffer.writeln('\n---\nComments:\n---'); // Note-specific comment header
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
    buffer.writeln("## Comments:"); // Task-specific comment header
    if (comments.isEmpty) {
      // No explicit "(No comments)" for tasks in the spec, keep it clean
    } else {
      for (final comment in comments) {
        // Format task comments as specified: "- Author: Text"
        // Assuming Comment model has creatorId and content fields for Todoist
        final author =
            comment.creatorId ?? 'Unknown Author'; // Adapt if needed
        final text =
            comment.content ?? '(No content)'; // Adapt if needed
        buffer.writeln("- $author: ${text.trim()}");
      }
    }
  }

  return buffer.toString();
}
