import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
// Import note_providers and use non-family providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/services/minimal_openai_service.dart'; // Import MinimalOpenAiService
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_providers.dart' as api_p;
import 'settings_provider.dart' as settings_p; // Add import alias for settings

/// Provider for the list of hidden comment IDs (local state only)
final hiddenCommentIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Parameter record for comment action providers (now only needs memoId and commentId)
typedef CommentActionParams = ({String memoId, String commentId});

/// Parameter record for comment creation provider (now only needs memoId)
typedef CreateCommentParams = ({String memoId});

// Helper function (copied from note_providers) to get the configured NoteApiService
NoteApiService _getNoteApiService(Ref ref) {
  final service = ref.read(api_p.noteApiServiceProvider);
  if (service is api_p.DummyNoteApiService) {
    throw Exception(
      "Note API service is not properly configured (Dummy service returned).",
    );
  }
  return service;
}

/// Provider for archiving a comment
final archiveCommentProvider = Provider.family<
  Future<void> Function(),
  CommentActionParams
>((ref, params) {
  return () async {
    final NoteApiService apiService = _getNoteApiService(ref);
    try {
      final commentId = params.commentId;
      final comment = await apiService.getNoteComment(commentId);
      final updatedComment = comment.copyWith(
        pinned: false,
        state: CommentState.archived,
      );
      await apiService.updateNoteComment(commentId, updatedComment);
      ref.invalidate(
        note_providers.noteCommentsProvider(params.memoId),
      ); // Use non-family provider
      if (kDebugMode)
        print('[archiveCommentProvider] Comment archived: ${params.commentId}');
    } catch (e) {
      if (kDebugMode)
        print('[archiveCommentProvider] Error archiving comment: $e');
      rethrow;
    }
  };
});

/// Provider for deleting a comment
final deleteCommentProvider = Provider.family<
  Future<void> Function(),
  CommentActionParams
>((ref, params) {
  return () async {
    final NoteApiService apiService = _getNoteApiService(ref);
    try {
      final memoId = params.memoId;
      final commentId = params.commentId;
      await apiService.deleteNoteComment(memoId, commentId);
      ref.invalidate(
        note_providers.noteCommentsProvider(memoId),
      ); // Use non-family provider
      if (kDebugMode)
        print('[deleteCommentProvider] Comment deleted: ${params.commentId}');
    } catch (e) {
      if (kDebugMode)
        print('[deleteCommentProvider] Error deleting comment: $e');
      rethrow;
    }
  };
});

/// Provider for toggling the pin state of a comment
final togglePinCommentProvider = Provider.family<
  Future<void> Function(),
  CommentActionParams
>((ref, params) {
  return () async {
    final NoteApiService apiService = _getNoteApiService(ref);
    try {
      final memoId = params.memoId;
      final commentId = params.commentId;
      final comment = await apiService.getNoteComment(commentId);
      final updatedComment = comment.copyWith(pinned: !comment.pinned);
      await apiService.updateNoteComment(commentId, updatedComment);
      ref.invalidate(
        note_providers.noteCommentsProvider(memoId),
      ); // Use non-family provider
      if (kDebugMode)
        print(
          '[togglePinCommentProvider] Comment pin toggled: ${params.commentId}',
        );
    } catch (e) {
      if (kDebugMode)
        print('[togglePinCommentProvider] Error toggling pin: $e');
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
  CommentActionParams
>((ref, params) {
  return () async {
    final NoteApiService apiService = _getNoteApiService(ref);
    try {
      final memoId = params.memoId;
      final commentId = params.commentId;
      if (kDebugMode)
        print(
          '[convertCommentToNoteProvider] Converting comment to note: $commentId',
        );

      final comment = await apiService.getNoteComment(commentId);
      final newNote = NoteItem(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        content: comment.content ?? '',
        pinned: false,
        state: NoteState.normal,
        visibility: NoteVisibility.public,
        createTime: DateTime.now(),
        updateTime: DateTime.now(),
        displayTime: DateTime.now(),
        tags: [],
        resources: [],
        relations: [],
        creatorId: comment.creatorId,
        parentId: null,
      );
      final createdNote = await apiService.createNote(newNote);

      if (memoId.isNotEmpty) {
        try {
          final Map<String, dynamic> relationMap = {
            'relatedMemoId': memoId,
            'type': 'COMMENT',
          };
          await apiService.setNoteRelations(createdNote.id, [relationMap]);
        } catch (relationError) {
          if (kDebugMode)
            print(
              '[convertCommentToNoteProvider] Warning: Created note but failed to set relation: $relationError',
            );
        }
      }

      await ref
          .read(note_providers.notesNotifierProvider.notifier)
          .refresh(); // Use non-family provider
      if (kDebugMode)
        print(
          '[convertCommentToNoteProvider] Converted comment to note: ${createdNote.id}',
        );
      return createdNote;
    } catch (e) {
      if (kDebugMode)
        print(
          '[convertCommentToNoteProvider] Error converting comment to note: $e',
        );
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
    final hiddenCommentIdsNotifier = ref.read(
      hiddenCommentIdsProvider.notifier,
    );
    final currentHiddenIds = ref.read(hiddenCommentIdsProvider);
    if (currentHiddenIds.contains(id)) {
      hiddenCommentIdsNotifier.update((state) => state..remove(id));
      if (kDebugMode) print('[toggleHideCommentProvider] Unhid comment: $id');
    } else {
      hiddenCommentIdsNotifier.update((state) => state..add(id));
      if (kDebugMode) print('[toggleHideCommentProvider] Hid comment: $id');
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
  CreateCommentParams
>((ref, params) {
  return (
    Comment comment, {
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
  }) async {
    final memoId = params.memoId;
    if (kDebugMode) {
      print('[createCommentProvider] Called for memoId: $memoId');
      print('[createCommentProvider] Comment content: "${comment.content}"');
      print(
        '[createCommentProvider] File details: filename=$filename, contentType=$contentType, data_length=${fileBytes?.length}',
      );
    }
    final NoteApiService apiService = _getNoteApiService(ref);
    List<Map<String, dynamic>>? uploadedResourceData;

    try {
      if (fileBytes != null && filename != null && contentType != null) {
        if (kDebugMode)
          print(
            '[createCommentProvider] Uploading attachment: $filename ($contentType, ${fileBytes.length} bytes)',
          );
        final Map<String, dynamic> uploadedResourceMap = await apiService
            .uploadResource(fileBytes, filename, contentType);
        uploadedResourceData = [uploadedResourceMap];
        if (kDebugMode)
          print(
            "[createCommentProvider] Attachment uploaded: ${uploadedResourceMap['name']}",
          );
      }

      if (kDebugMode)
        print(
          '[createCommentProvider] Creating comment for memo $memoId with ${uploadedResourceData?.length ?? 0} attachments.',
        );
      final createdComment = await apiService.createNoteComment(
        memoId,
        comment,
        resources: uploadedResourceData,
      );
      if (kDebugMode)
        print('[createCommentProvider] Comment created: ${createdComment.id}');

      try {
        if (kDebugMode)
          print(
            '[createCommentProvider] Bumping parent memo $memoId after comment creation.',
          );
        await ref.read(
          note_providers.bumpNoteProvider(memoId),
        )(); // Use non-family provider
      } catch (e) {
        if (kDebugMode)
          print(
            '[createCommentProvider] Warning: Error bumping parent memo $memoId: $e',
          );
      }

      ref.invalidate(
        note_providers.noteCommentsProvider(memoId),
      ); // Use non-family provider
      return createdComment;
    } catch (e, stackTrace) {
      if (kDebugMode)
        print(
          '[createCommentProvider] Error creating comment for memo $memoId: $e\n$stackTrace',
        );
      rethrow;
    }
  };
});

/// Provider for updating a comment's content
final updateCommentProvider = Provider.family<
  Future<Comment> Function(String newContent),
  CommentActionParams
>((ref, params) {
  return (String newContent) async {
    final memoId = params.memoId;
    final commentId = params.commentId;
    final NoteApiService apiService = _getNoteApiService(ref);
    if (kDebugMode)
      print(
        '[updateCommentProvider] Updating comment $commentId for memo $memoId',
      );

    try {
      final existingComment = await apiService.getNoteComment(commentId);
      final updatedCommentData = existingComment.copyWith(
        content: () => newContent,
      );
      final resultComment = await apiService.updateNoteComment(
        commentId,
        updatedCommentData,
      );
      ref.invalidate(
        note_providers.noteCommentsProvider(memoId),
      ); // Use non-family provider
      if (kDebugMode)
        print(
          '[updateCommentProvider] Comment $commentId updated successfully.',
        );
      return resultComment;
    } catch (e, stackTrace) {
      if (kDebugMode)
        print(
          '[updateCommentProvider] Error updating comment $commentId: $e\n$stackTrace',
        );
      rethrow;
    }
  };
});

/// Provider to fix grammar of a comment using OpenAI
final fixCommentGrammarProvider = FutureProvider.family<
  void,
  CommentActionParams
>((ref, params) async {
  final memoId = params.memoId;
  final commentId = params.commentId;
  if (kDebugMode)
    print(
      '[fixCommentGrammarProvider] Starting grammar fix for comment: $commentId',
    );

  final MinimalOpenAiService openaiApiService = ref.read(
    api_p.openaiApiServiceProvider,
  );
  final String selectedModelId = ref.read(settings_p.openAiModelIdProvider);

  if (!openaiApiService.isConfigured) {
    if (kDebugMode)
      print(
        '[fixCommentGrammarProvider] OpenAI service not configured. Aborting.',
      );
    throw Exception('OpenAI API key is not configured in settings.');
  }

  try {
    if (kDebugMode)
      print('[fixCommentGrammarProvider] Fetching comment content...');
    final NoteApiService apiService = _getNoteApiService(ref);
    final Comment currentComment = await apiService.getNoteComment(commentId);
    final String originalContent = currentComment.content ?? '';

    if (originalContent.trim().isEmpty) {
      if (kDebugMode)
        print(
          '[fixCommentGrammarProvider] Comment content is empty. Skipping.',
        );
      return;
    }

    if (kDebugMode)
      print(
        '[fixCommentGrammarProvider] Calling OpenAI API with model $selectedModelId...',
      );
    final String correctedContent = await openaiApiService.fixGrammar(
      originalContent,
      modelId: selectedModelId,
    );
    if (correctedContent == originalContent ||
        correctedContent.trim().isEmpty) {
      if (kDebugMode)
        print(
          '[fixCommentGrammarProvider] Content unchanged or correction empty. No update needed.',
        );
      return;
    }

    if (kDebugMode)
      print(
        '[fixCommentGrammarProvider] Content corrected. Updating comment...',
      );
    final Comment updatedCommentData = currentComment.copyWith(
      content: () => correctedContent,
    );
    await apiService.updateNoteComment(commentId, updatedCommentData);
    ref.invalidate(
      note_providers.noteCommentsProvider(memoId),
    ); // Use non-family provider
    if (kDebugMode)
      print(
        '[fixCommentGrammarProvider] Comment $commentId updated successfully with corrected grammar.',
      );
  } catch (e, stackTrace) {
    if (kDebugMode)
      print(
        '[fixCommentGrammarProvider] Error fixing grammar for comment $commentId: $e\n$stackTrace',
      );
    rethrow;
  }
});
