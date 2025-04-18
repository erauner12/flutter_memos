import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
// Import note_providers and use families
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/services/minimal_openai_service.dart'; // Import MinimalOpenAiService
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_providers.dart' as api_p;
import 'settings_provider.dart' as settings_p; // Add import alias for settings

/// Provider for the list of hidden comment IDs (local state only)
final hiddenCommentIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Parameter record for comment action providers
typedef CommentActionParams =
    ({String serverId, String memoId, String commentId});

/// Parameter record for comment creation provider
typedef CreateCommentParams = ({String serverId, String memoId});

/// Provider for archiving a comment
final archiveCommentProviderFamily = Provider.family<
  Future<void> Function(),
  CommentActionParams
>((ref, params) {
    return () async {
    // Use helper to get API service for the server
    final NoteApiService apiService = note_providers
        .getNoteApiServiceForServer(
      ref,
      params.serverId,
    ); // Use public helper

      try {
      final commentId = params.commentId; // Actual comment ID

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

      // Refresh comments for this memo using the family provider
      ref.invalidate(
        note_providers.noteCommentsProviderFamily((
          serverId: params.serverId,
          noteId: params.memoId,
        )),
      );

        if (kDebugMode) {
        print(
          '[archiveCommentProviderFamily(${params.serverId})] Comment archived: ${params.commentId}',
        );
        }
      } catch (e) {
        if (kDebugMode) {
        print(
          '[archiveCommentProviderFamily(${params.serverId})] Error archiving comment: $e',
        );
        }
        rethrow;
      }
    };
  },
);

/// Provider for deleting a comment
final deleteCommentProviderFamily = Provider.family<
  Future<void> Function(),
  CommentActionParams
>((
  ref,
  params,
) {
  return () async {
    // Use helper to get API service for the server
    final NoteApiService apiService = note_providers
        .getNoteApiServiceForServer(
      ref,
      params.serverId,
    ); // Use public helper

    try {
      final memoId = params.memoId;
      final commentId = params.commentId; // Actual comment ID

      // Delete the comment using NoteApiService
      await apiService.deleteNoteComment(
        memoId,
        commentId,
      ); // Use deleteNoteComment

      // Refresh comments for this memo using the family provider
      ref.invalidate(
        note_providers.noteCommentsProviderFamily((
          serverId: params.serverId,
          noteId: memoId,
        )),
      );

      if (kDebugMode) {
        print(
          '[deleteCommentProviderFamily(${params.serverId})] Comment deleted: ${params.commentId}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[deleteCommentProviderFamily(${params.serverId})] Error deleting comment: $e',
        );
      }
      rethrow;
    }
  };
});

/// Provider for toggling the pin state of a comment
final togglePinCommentProviderFamily = Provider.family<
  Future<void> Function(),
  CommentActionParams
>((ref, params) {
  return () async {
    // Use helper to get API service for the server
    final NoteApiService apiService = note_providers
        .getNoteApiServiceForServer(
      ref,
      params.serverId,
    ); // Use public helper

    try {
      final memoId = params.memoId;
      final commentId = params.commentId; // Actual comment ID

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

      // Invalidate the comments list to ensure UI refreshes using the family provider
      ref.invalidate(
        note_providers.noteCommentsProviderFamily((
          serverId: params.serverId,
          noteId: memoId,
        )),
      );

      if (kDebugMode) {
        print(
          '[togglePinCommentProviderFamily(${params.serverId})] Comment pin toggled: ${params.commentId}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[togglePinCommentProviderFamily(${params.serverId})] Error toggling pin: $e',
        );
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
final convertCommentToNoteProviderFamily = Provider.family<
  Future<NoteItem> Function(),
  CommentActionParams // Pass serverId, memoId, commentId
>((ref, params) {
  return () async {
    // Use helper to get API service for the server
    final NoteApiService apiService = note_providers
        .getNoteApiServiceForServer(
      ref,
      params.serverId,
    ); // Use public helper

    try {
      final memoId = params.memoId;
      final commentId = params.commentId; // Actual comment ID

      if (kDebugMode) {
        print(
          '[convertCommentToNoteProviderFamily(${params.serverId})] Converting comment to note: $commentId',
        ); // Updated log
      }

      // Get the comment using the actual comment ID
      final comment = await apiService.getNoteComment(
        commentId,
      ); // Use getNoteComment

      // Create a new note from the comment's content
      final newNote = NoteItem(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        content: comment.content ?? '', // Handle nullable content
        pinned: false, // Reset pinned state for the new note
        state: NoteState.normal, // Use enum
        visibility: NoteVisibility.public, // Default visibility, use enum
        createTime: DateTime.now(), // Placeholder
        updateTime: DateTime.now(), // Placeholder
        displayTime: DateTime.now(), // Placeholder
        tags: [], // Initialize empty lists
        resources: [],
        relations: [],
        creatorId: comment.creatorId, // Use comment creator if available
        parentId: null, // New note has no parent
      );

      // Create the new note using NoteApiService
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
              '[convertCommentToNoteProviderFamily(${params.serverId})] Warning: Created note but failed to set relation: $relationError'
            );
          }
        }
      }

      // Refresh notes list using the family provider for the correct server
      await ref
          .read(
            note_providers
                .notesNotifierProviderFamily(params.serverId)
                .notifier,
          )
          .refresh();

      if (kDebugMode) {
        print(
          '[convertCommentToNoteProviderFamily(${params.serverId})] Converted comment to note: ${createdNote.id}',
        ); // Updated log
      }

      return createdNote; // Return NoteItem
    } catch (e) {
      if (kDebugMode) {
        print(
          '[convertCommentToNoteProviderFamily(${params.serverId})] Error converting comment to note: $e',
        ); // Updated log
      }
      rethrow;
    }
  };
});

/// Provider for toggling visibility of a comment in the current view
final toggleHideCommentProvider = Provider.family<void Function(), String>((
  ref,
  id, // id is still "memoId/commentId"
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
final createCommentProviderFamily = Provider.family<
  Future<Comment> Function(
    Comment comment, {
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
  }),
  CreateCommentParams // Pass serverId and memoId
>((ref, params) {
  return (
    Comment comment, {
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
  }) async {
    final serverId = params.serverId;
    final memoId = params.memoId;

    if (kDebugMode) {
      print(
        '[createCommentProviderFamily($serverId)] Called for memoId: $memoId',
      );
      print(
        '[createCommentProviderFamily($serverId)] Comment content: "${comment.content}"',
      );
      print(
        '[createCommentProviderFamily($serverId)] File details: filename=$filename, contentType=$contentType, data_length=${fileBytes?.length}',
      );
    }

    // Use helper to get API service for the server
    final NoteApiService apiService = note_providers
        .getNoteApiServiceForServer(
      ref,
      serverId,
    ); // Use public helper

    List<Map<String, dynamic>>? uploadedResourceData; // Store as list of maps

    try {
      // 1. Upload resource if provided using NoteApiService
      if (fileBytes != null && filename != null && contentType != null) {
        if (kDebugMode) {
          print(
            '[createCommentProviderFamily($serverId)] Uploading attachment: $filename ($contentType, ${fileBytes.length} bytes)',
          );
        }
        final Map<String, dynamic> uploadedResourceMap = await apiService
            .uploadResource(fileBytes, filename, contentType); // Expect map
        uploadedResourceData = [uploadedResourceMap];
        if (kDebugMode) {
          print(
            "[createCommentProviderFamily($serverId)] Attachment uploaded: ${uploadedResourceMap['name']}",
          );
        }
      }

      // 2. Create the comment, passing uploaded resources using NoteApiService
      if (kDebugMode) {
        print(
          '[createCommentProviderFamily($serverId)] Creating comment for memo $memoId with ${uploadedResourceData?.length ?? 0} attachments.',
        );
      }
      final createdComment = await apiService.createNoteComment(
        memoId,
        comment,
        resources: uploadedResourceData, // Pass the list of maps
      );
      if (kDebugMode) {
        print(
          '[createCommentProviderFamily($serverId)] Comment created: ${createdComment.id}',
        );
      }

      // 3. Bump the parent memo after successful comment creation
      try {
        if (kDebugMode) {
          print(
            '[createCommentProviderFamily($serverId)] Bumping parent memo $memoId after comment creation.',
          );
        }
        // Use bumpNoteProviderFamily with serverId and memoId
        await ref.read(
          note_providers.bumpNoteProviderFamily((
            serverId: serverId,
            noteId: memoId,
          )),
        )();
      } catch (e) {
        if (kDebugMode) {
          print(
            '[createCommentProviderFamily($serverId)] Warning: Error bumping parent memo $memoId: $e',
          );
        }
      }

      // 4. Invalidate comments list for the specific memo using the family provider
      ref.invalidate(
        note_providers.noteCommentsProviderFamily((
          serverId: serverId,
          noteId: memoId,
        )),
      );

      return createdComment;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[createCommentProviderFamily($serverId)] Error creating comment for memo $memoId: $e\n$stackTrace',
        );
      }
      rethrow;
    }
  };
});

/// Provider for updating a comment's content
final updateCommentProviderFamily = Provider.family<
  Future<Comment> Function(String newContent),
  CommentActionParams // Pass serverId, memoId, commentId
>((ref, params) {
  return (String newContent) async {
    final serverId = params.serverId;
    final memoId = params.memoId;
    final commentId = params.commentId; // Actual comment ID

    // Use helper to get API service for the server
    final NoteApiService apiService = note_providers
        .getNoteApiServiceForServer(
      ref,
      serverId,
    ); // Use public helper

    if (kDebugMode) {
      print(
        '[updateCommentProviderFamily($serverId)] Updating comment $commentId for memo $memoId',
      );
    }

    try {
      // 1. Get the existing comment to preserve other properties
      final existingComment = await apiService.getNoteComment(
        commentId,
      ); // Use getNoteComment

      // 2. Create the updated comment object with new content
      // Use ValueGetter for nullable content
      final updatedCommentData = existingComment.copyWith(
        content: () => newContent,
      );

      // 3. Call the API service to update the comment
      final resultComment = await apiService.updateNoteComment(
        commentId,
        updatedCommentData,
      );

      // 4. Invalidate the comments list for the specific memo to refresh UI using the family provider
      ref.invalidate(
        note_providers.noteCommentsProviderFamily((
          serverId: serverId,
          noteId: memoId,
        )),
      );

      if (kDebugMode) {
        print(
          '[updateCommentProviderFamily($serverId)] Comment $commentId updated successfully.',
        );
      }
      return resultComment;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[updateCommentProviderFamily($serverId)] Error updating comment $commentId: $e\n$stackTrace',
        );
      }
      rethrow;
    }
  };
});

/// Provider to fix grammar of a comment using OpenAI
final fixCommentGrammarProviderFamily = FutureProvider.family<
  void,
  CommentActionParams
>((
  ref,
  params,
) async {
  final serverId = params.serverId;
  final memoId = params.memoId;
  final commentId = params.commentId; // Actual comment ID

  if (kDebugMode) {
    print(
      '[fixCommentGrammarProviderFamily($serverId)] Starting grammar fix for comment: $commentId',
    );
  }

  final MinimalOpenAiService openaiApiService = ref.read(
    api_p.openaiApiServiceProvider, // Global OpenAI service
  );
  final String selectedModelId = ref.read(
    settings_p.openAiModelIdProvider,
  ); // Global setting

  if (!openaiApiService.isConfigured) {
    if (kDebugMode) {
      print(
        '[fixCommentGrammarProviderFamily($serverId)] OpenAI service not configured. Aborting.',
      );
    }
    throw Exception('OpenAI API key is not configured in settings.');
  }

  try {
    if (kDebugMode) {
      print(
        '[fixCommentGrammarProviderFamily($serverId)] Fetching comment content...',
      );
    }
    // Use helper to get API service for the server
    final NoteApiService apiService = note_providers
        .getNoteApiServiceForServer(
      ref,
      serverId,
    ); // Use public helper

    final Comment currentComment = await apiService.getNoteComment(
      commentId,
    );
    final String originalContent =
        currentComment.content ?? ''; // Handle nullable

    if (originalContent.trim().isEmpty) {
      if (kDebugMode) {
        print(
          '[fixCommentGrammarProviderFamily($serverId)] Comment content is empty. Skipping.',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '[fixCommentGrammarProviderFamily($serverId)] Calling OpenAI API with model $selectedModelId...',
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
          '[fixCommentGrammarProviderFamily($serverId)] Content unchanged or correction empty. No update needed.',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '[fixCommentGrammarProviderFamily($serverId)] Content corrected. Updating comment...',
      );
    }

    // Use ValueGetter for nullable content
    final Comment updatedCommentData = currentComment.copyWith(
      content: () => correctedContent,
    );
    await apiService.updateNoteComment(commentId, updatedCommentData);

    // Invalidate comments list using the family provider
    ref.invalidate(
      note_providers.noteCommentsProviderFamily((
        serverId: serverId,
        noteId: memoId,
      )),
    );

    if (kDebugMode) {
      print(
        '[fixCommentGrammarProviderFamily($serverId)] Comment $commentId updated successfully with corrected grammar.',
      );
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print(
        '[fixCommentGrammarProviderFamily($serverId)] Error fixing grammar for comment $commentId: $e',
      );
      print(stackTrace);
    }
    rethrow;
  }
});
