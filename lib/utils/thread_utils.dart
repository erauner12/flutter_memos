import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/workbench_item_type.dart'; // Corrected import path
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/services/base_api_service.dart'; // For BaseApiService
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_memos/services/task_api_service.dart';
// Import Vikunja service provider to check configuration if needed
import 'package:flutter_memos/services/vikunja_api_service.dart';
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
  final activeServer = ref.read(activeServerConfigProvider);

  // 2. Determine the correct API service and perform necessary checks
  if (itemType == WorkbenchItemType.task) {
    // Check if the task's server is the currently active server
    if (activeServer == null || activeServer.id != itemServerId) {
      throw Exception(
        'Task server ($itemServerId) is not the active server (${activeServer?.id}). Cannot fetch task thread.',
      );
    }
    // Get the API service for the active server
    apiService = ref.read(apiServiceProvider);
    // Ensure the active service is a TaskApiService (e.g., Vikunja)
    if (apiService is! TaskApiService) {
      throw Exception(
        'Cannot fetch task thread: Active API service for $itemServerId is not TaskApiService.',
      );
    }
    // Check if the specific service (Vikunja) is configured
    if (apiService is VikunjaApiService && !apiService.isConfigured) {
      throw Exception(
        'Cannot fetch task thread: Vikunja service is not configured. Please check settings.',
      );
    }

    // Fetch task and comments using the TaskApiService
    final task = await (apiService).getTask(itemId);
    buffer.writeln("# Task: ${task.title}"); // Use title instead of content
    buffer.writeln(); // Add blank line
    buffer.writeln(
      "**Description**: ${task.description?.isNotEmpty == true ? task.description : 'N/A'}",
    );
    buffer.writeln(); // Add blank line
    comments = await (apiService).listComments(itemId);

  } else if (itemType == WorkbenchItemType.note) {
    // Notes always rely on the active server
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
        // Assuming Comment model has creatorId and content fields
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
