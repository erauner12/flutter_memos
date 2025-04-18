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
  // 1. Check if the item's server is active (or handle global integrations)
  // For Todoist, we might not need an "active" server check if it's global.
  // Let's assume for now the check is relevant or adapted elsewhere if needed.
  if (itemServerId != 'global-todoist-integration') {
    final activeServer = ref.read(activeServerConfigProvider);
    if (activeServer == null || activeServer.id != itemServerId) {
      throw Exception(
        'Item server ($itemServerId) is not the active server (${activeServer?.id}).',
      );
    }
  }

  // 2. Get the correct API service
  // For Tasks, we specifically need TaskApiService, regardless of active server.
  // For Notes, we use the active server's API service.
  BaseApiService apiService;
  if (itemType == WorkbenchItemType.task) {
    // Assuming TaskApiService is globally available or fetched differently.
    // If TaskApiService depends on the active server, this needs adjustment.
    // For now, let's assume we can get it directly or it's handled by the provider setup.
    // A common pattern is to have a dedicated provider for the integration service.
    // Let's refine this to use the specific task service provider if available.
    // If not, we fall back to the generic one and cast.
    // TODO: Confirm TaskApiService provider setup. Using generic for now.
    apiService = ref.read(apiServiceProvider);
    if (apiService is! TaskApiService) {
      throw Exception(
        'Cannot fetch task thread: Active API service is not TaskApiService.',
      );
    }
  } else if (itemType == WorkbenchItemType.note) {
    apiService = ref.read(apiServiceProvider);
    if (apiService is! NoteApiService) {
      throw Exception(
        'Cannot fetch note thread: Active API service is not NoteApiService.',
      );
    }
  } else if (itemType == WorkbenchItemType.comment) {
    // Existing comment logic (needs refinement as noted before)
    apiService = ref.read(apiServiceProvider);
    if (apiService is NoteApiService) {
      if (kDebugMode) {
        print(
          "Fetching thread for comment $itemId. Parent context needed for robust implementation.",
        );
      }
      throw UnimplementedError(
        'Copying thread starting from a comment requires parent context (type and ID) which is not fully available yet.',
      );
    } else {
      throw Exception(
        'Cannot fetch comment thread: Active API service is not NoteApiService.',
      );
    }
  } else {
    throw Exception('Unsupported item type ($itemType) for thread fetching.');
  }

  // 3. Fetch Parent Item and Comments based on type
  final buffer = StringBuffer();
  List<Comment> comments = [];

  if (itemType == WorkbenchItemType.note && apiService is NoteApiService) {
    final note = await apiService.getNote(itemId);
    final parentTimestamp = note.createTime;
    final parentHeader =
        'Note (${note.id}) - ${DateFormat.yMd().add_jm().format(parentTimestamp.toLocal())}:';
    buffer.writeln(parentHeader);
    buffer.writeln('---');
    buffer.writeln(note.content.trim()); // Trim parent content
    comments = await apiService.listNoteComments(itemId);
  } else if (itemType == WorkbenchItemType.task &&
      apiService is TaskApiService) {
    final task = await apiService.getTask(itemId);
    // Format according to user instructions
    buffer.writeln("# Task: ${task.content}");
    buffer.writeln(); // Add blank line
    buffer.writeln(
      "**Description**: ${task.description?.isNotEmpty == true ? task.description : 'N/A'}",
    );
    buffer.writeln(); // Add blank line
    // Fetch comments using the TaskApiService's implementation
    comments = await apiService.listComments(
      itemId,
    ); // Assumes TaskApiService implements listComments
  }
  // Note: Comment type handling is above and throws UnimplementedError

  // 4. Sort Comments Chronologically (Oldest First) - Apply to both notes and tasks
  comments.sort((a, b) {
    final timeA = a.createdTs;
    final timeB = b.createdTs;
    return timeA.compareTo(timeB);
  });

  // 5. Format Comments - Apply to both notes and tasks
  if (itemType == WorkbenchItemType.note) {
    buffer.writeln('\n---\nComments:\n---'); // Note-specific comment header
  } else if (itemType == WorkbenchItemType.task) {
    buffer.writeln("## Comments:"); // Task-specific comment header
  }

  if (comments.isEmpty) {
    if (itemType == WorkbenchItemType.note) {
      buffer.writeln('(No comments)');
    } else if (itemType == WorkbenchItemType.task) {
      // No explicit "(No comments)" for tasks in the spec, keep it clean
    }
  } else {
    for (final comment in comments) {
      final timestamp = comment.createdTs;
      if (itemType == WorkbenchItemType.note) {
        buffer.writeln(
          '\nComment (${comment.id}) - ${DateFormat.yMd().add_jm().format(timestamp.toLocal())}:',
        );
        buffer.writeln((comment.content ?? '(No content)').trim());
      } else if (itemType == WorkbenchItemType.task) {
        // Format task comments as specified: "- Author: Text"
        // Assuming Comment model has creatorName and text/content fields
        // Adjust field names based on your actual Comment model for Todoist
        final author =
            comment.creatorId ?? 'Unknown Author'; // Adapt field name if needed
        final text =
            comment.content ?? '(No content)'; // Adapt field name if needed
        buffer.writeln("- $author: ${text.trim()}");
      }
    }
  }

  return buffer.toString();
}
