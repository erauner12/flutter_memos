import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
// Import note_providers instead of memo_providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/services/base_api_service.dart'; // Import BaseApiService
import 'package:flutter_memos/services/minimal_openai_service.dart'; // Import MinimalOpenAiService
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_providers.dart' as api_p;
import 'settings_provider.dart' as settings_p; // Add import alias for settings

/// Provider for the list of hidden comment IDs (local state only)
final hiddenCommentIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Provider for archiving a comment
final archiveCommentProvider = Provider.family<Future<void> Function(), String>(
  (ref, id) {
    return () async {
      final apiService = ref.read(
        api_p.apiServiceProvider,
      ); // Use BaseApiService

      try {
        // Extract memoId from combined ID (format: "memoId/commentId")
        final parts = id.split('/');
        final String memoId = parts.isNotEmpty ? parts[0] : '';
        final String commentId =
            parts.length > 1 ? parts.last : id; // Actual comment ID

        // Get the comment using the actual comment ID
        final comment = await apiService.getNoteComment(
          commentId,
        ); // Use getNoteComment

        // Update the comment to archived state
        final updatedComment = comment.copyWith(
          pinned: false,
          state: CommentState.archived,
        );

        // Save the updated comment using the actual comment ID
        await apiService.updateNoteComment(
          commentId,
          updatedComment,
        ); // Use updateNoteComment

        // Refresh comments for this memo
        if (memoId.isNotEmpty) {
          // Use note_providers.noteCommentsProvider
          ref.invalidate(note_providers.noteCommentsProvider(memoId));
        }

        if (kDebugMode) {
          print('[archiveCommentProvider] Comment archived: $id');
        }
      } catch (e) {
        if (kDebugMode) {
          print('[archiveCommentProvider] Error archiving comment: $e');
        }
        rethrow;
      }
    };
  },
);

/// Provider for deleting a comment
final deleteCommentProvider = Provider.family<Future<void> Function(), String>((
  ref,
  id,
) {
  return () async {
    final apiService = ref.read(api_p.apiServiceProvider); // Use BaseApiService

    try {
      // Extract parts from the combined ID (format: "memoId/commentId")
      final parts = id.split('/');
      final memoId = parts.isNotEmpty ? parts.first : '';
      final commentId = parts.length > 1 ? parts.last : id;

      // Delete the comment using BaseApiService
      await apiService.deleteNoteComment(
        memoId,
        commentId,
      ); // Use deleteNoteComment

      // Refresh comments for this memo
      if (memoId.isNotEmpty) {
        // Use note_providers.noteCommentsProvider
        ref.invalidate(note_providers.noteCommentsProvider(memoId));
      }

      if (kDebugMode) {
        print('[deleteCommentProvider] Comment deleted: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[deleteCommentProvider] Error deleting comment: $e');
      }
      rethrow;
    }
  };
});

/// Provider for toggling the pin state of a comment
final togglePinCommentProvider =
    Provider.family<Future<void> Function(), String>((ref, id) {
  return () async {
    final apiService = ref.read(api_p.apiServiceProvider); // Use BaseApiService

    try {
      // Extract memoId from combined ID (format: "memoId/commentId")
      final parts = id.split('/');
      final String memoId = parts.isNotEmpty ? parts[0] : '';
          final String commentId =
              parts.length > 1 ? parts.last : id; // Actual comment ID

      // Get the comment using the actual comment ID
          final comment = await apiService.getNoteComment(
            commentId,
          ); // Use getNoteComment

      // Toggle the pinned state
      final updatedComment = comment.copyWith(pinned: !comment.pinned);

      // Update through API using the actual comment ID
          await apiService.updateNoteComment(
            commentId,
            updatedComment,
          ); // Use updateNoteComment

      // Invalidate the comments list to ensure UI refreshes
          if (memoId.isNotEmpty) {
        // Use note_providers.noteCommentsProvider
            ref.invalidate(note_providers.noteCommentsProvider(memoId));
      }

      if (kDebugMode) {
        print('[togglePinCommentProvider] Comment pin toggled: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[togglePinCommentProvider] Error toggling pin: $e');
      }
      rethrow;
    }
  };
});

/// Provider to check if a comment is hidden
final isCommentHiddenProvider = Provider.family<bool, String>((ref, id) {
  final hiddenCommentIds = ref.watch(hiddenCommentIdsProvider);
  return hiddenCommentIds.contains(id);
});

/// Provider for converting a comment to a full note
final convertCommentToNoteProvider = Provider.family<
  Future<NoteItem> Function(),
  String
>((ref, id) {
  return () async {
    final apiService = ref.read(api_p.apiServiceProvider); // Use BaseApiService

    try {
      // Extract parts from the combined ID (format: "memoId/commentId")
      final parts = id.split('/');
      final memoId = parts.isNotEmpty ? parts.first : '';
      final commentId = parts.length > 1 ? parts.last : id; // Actual comment ID

      if (kDebugMode) {
        print(
          '[convertCommentToNoteProvider] Converting comment to note: $id',
        ); // Updated log
      }

      // Get the comment using the actual comment ID
      final comment = await apiService.getNoteComment(
        commentId,
      ); // Use getNoteComment

      // Create a new note from the comment's content
      final newNote = NoteItem(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        content: comment.content,
        pinned: false, // Reset pinned state for the new note
        state: NoteState.normal, // Use enum
        visibility: NoteVisibility.public, // Default visibility, use enum
        createTime: DateTime.now(), // Placeholder
        updateTime: DateTime.now(), // Placeholder
        displayTime: DateTime.now(), // Placeholder
      );

      // Create the new note using BaseApiService
      final createdNote = await apiService.createNote(
        newNote,
      ); // Use createNote

      // Try to create a relation between the new note and the original note
      // But continue even if this part fails
      if (memoId.isNotEmpty) {
        try {
          final Map<String, dynamic> relationMap = {
            'relatedMemoId': memoId, // Original note ID
            'type': 'COMMENT', // Type indicating the origin
          };

          await apiService.setNoteRelations(createdNote.id, [
            relationMap,
          ]); // Use setNoteRelations
        } catch (relationError) {
          if (kDebugMode) {
            print(
              '[convertCommentToNoteProvider] Warning: Created note but failed to set relation: $relationError'
            );
          }
        }
      }

      // Refresh notes list using the new notifier
      // Use note_providers.notesNotifierProvider
      await ref
          .read(note_providers.notesNotifierProvider.notifier)
          .refresh(); // Use renamed provider

      if (kDebugMode) {
        print(
          '[convertCommentToNoteProvider] Converted comment to note: ${createdNote.id}',
        ); // Updated log
      }

      return createdNote; // Return NoteItem
    } catch (e) {
      if (kDebugMode) {
        print(
          '[convertCommentToNoteProvider] Error converting comment to note: $e',
        ); // Updated log
      }
      rethrow;
    }
  };
});

/// Provider for toggling visibility of a comment in the current view
final toggleHideCommentProvider = Provider.family<void Function(), String>((
  ref,
  id,
) {
  return () {
    final hiddenCommentIds = ref.read(hiddenCommentIdsProvider);

    if (hiddenCommentIds.contains(id)) {
      // Unhide the comment
      ref
          .read(hiddenCommentIdsProvider.notifier)
          .update((state) => state..remove(id));
      if (kDebugMode) {
        print('[toggleHideCommentProvider] Unhid comment: $id');
      }
    } else {
      // Hide the comment
      ref
          .read(hiddenCommentIdsProvider.notifier)
          .update((state) => state..add(id));
      if (kDebugMode) {
        print('[toggleHideCommentProvider] Hid comment: $id');
      }
    }
  };
});

/// Provider for creating a comment for a memo, potentially with an attachment
final createCommentProvider = Provider.family<
  Future<Comment> Function(
    Comment comment, {
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
  }),
  String
>((ref, memoId) {
  return (
    Comment comment, {
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
  }) async {
    if (kDebugMode) {
      print('[createCommentProvider] Called for memoId: $memoId');
      print('[createCommentProvider] Comment content: "${comment.content}"');
      print(
        '[createCommentProvider] File details: filename=$filename, contentType=$contentType, data_length=${fileBytes?.length}',
      );
    }

    final apiService = ref.read(api_p.apiServiceProvider); // Use BaseApiService
    List<Map<String, dynamic>>? uploadedResourceData; // Store as list of maps

    try {
      // 1. Upload resource if provided using BaseApiService
      if (fileBytes != null && filename != null && contentType != null) {
        if (kDebugMode) {
          print(
            '[createCommentProvider] Uploading attachment: $filename ($contentType, ${fileBytes.length} bytes)',
          );
        }
        final Map<String, dynamic> uploadedResourceMap = await apiService
            .uploadResource(fileBytes, filename, contentType); // Expect map
        uploadedResourceData = [uploadedResourceMap];
        if (kDebugMode) {
          print(
            "[createCommentProvider] Attachment uploaded: ${uploadedResourceMap['name']}",
          );
        }
      }

      // 2. Create the comment, passing uploaded resources using BaseApiService
      if (kDebugMode) {
        print(
          '[createCommentProvider] Creating comment for memo $memoId with ${uploadedResourceData?.length ?? 0} attachments.',
        );
      }
      final createdComment = await apiService.createNoteComment(
        memoId,
        comment,
        resources: uploadedResourceData, // Pass the list of maps
      );
      if (kDebugMode) {
        print('[createCommentProvider] Comment created: ${createdComment.id}');
      }

      // 3. Bump the parent memo after successful comment creation
      try {
        if (kDebugMode) {
          print(
            '[createCommentProvider] Bumping parent memo $memoId after comment creation.',
          );
        }
        // Use note_providers.bumpNoteProvider
        await ref.read(
          note_providers.bumpNoteProvider(memoId),
        )(); // Use renamed provider
      } catch (e) {
        if (kDebugMode) {
          print(
            '[createCommentProvider] Warning: Error bumping parent memo $memoId: $e',
          );
        }
      }

      // 4. Invalidate comments list for the specific memo
      // Use note_providers.noteCommentsProvider
      ref.invalidate(note_providers.noteCommentsProvider(memoId));

      return createdComment;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[createCommentProvider] Error creating comment for memo $memoId: $e\n$stackTrace',
        );
      }
      rethrow;
    }
  };
});

/// Provider for updating a comment's content
final updateCommentProvider = Provider<
  Future<Comment> Function(String memoId, String commentId, String newContent)
>((ref) {
  return (String memoId, String commentId, String newContent) async {
    final apiService = ref.read(api_p.apiServiceProvider); // Use BaseApiService
    if (kDebugMode) {
      print(
        '[updateCommentProvider] Updating comment $commentId for memo $memoId',
      );
    }

    try {
      // 1. Get the existing comment to preserve other properties
      final existingComment = await apiService.getNoteComment(
        commentId,
      ); // Use getNoteComment

      // 2. Create the updated comment object with new content
      final updatedCommentData = existingComment.copyWith(content: newContent);

      // 3. Call the API service to update the comment
      final resultComment = await apiService.updateNoteComment(
        commentId,
        updatedCommentData,
      );

      // 4. Invalidate the comments list for the specific memo to refresh UI
      // Use note_providers.noteCommentsProvider
      ref.invalidate(note_providers.noteCommentsProvider(memoId));

      if (kDebugMode) {
        print(
          '[updateCommentProvider] Comment $commentId updated successfully.',
        );
      }
      return resultComment;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[updateCommentProvider] Error updating comment $commentId: $e\n$stackTrace',
        );
      }
      rethrow;
    }
  };
});

/// Provider to fix grammar of a comment using OpenAI
final fixCommentGrammarProvider = FutureProvider.family<void, String>((
  ref,
  commentIdWithMemoId,
) async {
  if (kDebugMode) {
    print(
      '[fixCommentGrammarProvider] Starting grammar fix for comment: $commentIdWithMemoId',
    );
  }

  final MinimalOpenAiService openaiApiService = ref.read(
    api_p.openaiApiServiceProvider,
  );
  final String selectedModelId = ref.read(settings_p.openAiModelIdProvider);

  if (!openaiApiService.isConfigured) {
    if (kDebugMode) {
      print(
        '[fixCommentGrammarProvider] OpenAI service not configured. Aborting.',
      );
    }
    throw Exception('OpenAI API key is not configured in settings.');
  }

  try {
    final parts = commentIdWithMemoId.split('/');
    final String memoId = parts.isNotEmpty ? parts[0] : '';
    final String actualCommentId =
        parts.length > 1 ? parts.last : commentIdWithMemoId;

    if (kDebugMode) {
      print('[fixCommentGrammarProvider] Fetching comment content...');
    }
    final BaseApiService apiService = ref.read(api_p.apiServiceProvider);
    final Comment currentComment = await apiService.getNoteComment(
      actualCommentId,
    );
    final String originalContent = currentComment.content;

    if (originalContent.trim().isEmpty) {
      if (kDebugMode) {
        print(
          '[fixCommentGrammarProvider] Comment content is empty. Skipping.',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '[fixCommentGrammarProvider] Calling OpenAI API with model $selectedModelId...',
      );
    }
    final String correctedContent = await openaiApiService.fixGrammar(
      originalContent,
      modelId: selectedModelId,
    );

    if (correctedContent == originalContent ||
        correctedContent.trim().isEmpty) {
      if (kDebugMode) {
        print(
          '[fixCommentGrammarProvider] Content unchanged or correction empty. No update needed.',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '[fixCommentGrammarProvider] Content corrected. Updating comment...',
      );
    }

    final Comment updatedCommentData = currentComment.copyWith(
      content: correctedContent,
    );
    await apiService.updateNoteComment(actualCommentId, updatedCommentData);

    if (memoId.isNotEmpty) {
      // Use note_providers.noteCommentsProvider
      ref.invalidate(note_providers.noteCommentsProvider(memoId));
    }

    if (kDebugMode) {
      print(
        '[fixCommentGrammarProvider] Comment $actualCommentId updated successfully with corrected grammar.',
      );
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print(
        '[fixCommentGrammarProvider] Error fixing grammar for comment $commentIdWithMemoId: $e',
      );
      print(stackTrace);
    }
    rethrow;
  }
});
