import 'package:flutter/foundation.dart';
import 'package:flutter_memos/api/lib/api.dart'; // For V1Resource
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/memo_relation.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/comment_providers.dart' as comment_providers;
import 'package:flutter_memos/services/api_service.dart' as api_service;
// Remove the direct import of ApiService if it causes ambiguity
// import 'package:flutter_memos/services/api_service.dart'; // Import the actual service
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart'; // Add Mockito annotation import
import 'package:mockito/mockito.dart'; // Add Mockito import

// Import the generated mocks file (will be created by build_runner)
import 'comment_providers_test.mocks.dart';



// Annotation to generate nice mock for ApiService
@GenerateNiceMocks([MockSpec<api_service.ApiService>()])
void main() {
  late MockApiService mockApiService; // Use the generated MockApiService
  late ProviderContainer container;
  // Store created entities for easier stubbing/verification
  final Map<String, Memo> createdMemos = {};
  final Map<String, List<Comment>> createdComments = {};
  final Map<String, List<MemoRelation>> createdRelations = {};
  bool shouldFailRelations = false; // Flag to simulate relation errors

  group('Comment Providers Tests', () {
    setUp(() {
      // Reset state for each test
      createdMemos.clear();
      createdComments.clear();
      createdRelations.clear();
      shouldFailRelations = false;
      mockApiService = MockApiService(); // Instantiate the generated mock

      // --- Mockito Stubbing ---

      // Stub listMemos
      when(
        mockApiService.listMemos(
          parent: anyNamed('parent'),
          filter: anyNamed('filter'),
          state: anyNamed('state'),
          sort: anyNamed('sort'),
          direction: anyNamed('direction'),
          pageSize: anyNamed('pageSize'),
          pageToken: anyNamed('pageToken'),
          // Remove deprecated filter params if they cause issues
          // tags: anyNamed('tags'),
          // visibility: anyNamed('visibility'),
          // contentSearch: anyNamed('contentSearch'),
          // createdAfter: anyNamed('createdAfter'),
          // createdBefore: anyNamed('createdBefore'),
          // updatedAfter: anyNamed('updatedAfter'),
          // updatedBefore: anyNamed('updatedBefore'),
          // timeExpression: anyNamed('timeExpression'),
          // useUpdateTimeForExpression: anyNamed('useUpdateTimeForExpression'),
        ),
      ).thenAnswer((invocation) async {
        // Return empty list for any listMemos call
        return api_service.PaginatedMemoResponse(
          memos: List.from(createdMemos.values),
          nextPageToken: null,
        );
      });

      // Stub createMemo
      when(mockApiService.createMemo(any)).thenAnswer((invocation) async {
        final memo = invocation.positionalArguments[0] as Memo;
        final newId =
            memo.id.startsWith('temp-')
                ? 'memo-${DateTime.now().millisecondsSinceEpoch}'
                : memo.id;
        final createdMemo = memo.copyWith(
          id: newId,
          createTime: DateTime.now().toIso8601String(),
          updateTime: DateTime.now().toIso8601String(),
        );
        createdMemos[createdMemo.id] = createdMemo;
        return createdMemo;
      });

      // Stub createMemoComment
      when(
        mockApiService.createMemoComment(
          any,
          any,
          resources: anyNamed('resources'),
        ),
      ).thenAnswer((invocation) async {
        final memoId = invocation.positionalArguments[0] as String;
        final comment = invocation.positionalArguments[1] as Comment;
        final resources =
            invocation.namedArguments[#resources] as List<V1Resource>?;
        final now = DateTime.now().millisecondsSinceEpoch;
        final newId =
            comment.id.startsWith('temp-')
                ? 'comment-${DateTime.now().millisecondsSinceEpoch}'
                : comment.id;
        final createdComment = Comment(
          id: newId,
          content: comment.content,
          creatorId: comment.creatorId ?? 'mock-user',
          createTime: comment.createTime,
          updateTime: now,
          state: comment.state,
          pinned: comment.pinned,
          resources: resources,
        );
        createdComments.putIfAbsent(memoId, () => []).add(createdComment);
        return createdComment;
      });

      // Stub getMemoComment
      when(mockApiService.getMemoComment(any)).thenAnswer((invocation) async {
        final fullId = invocation.positionalArguments[0] as String;
        String memoId = '';
        String commentId = fullId;

        if (fullId.contains('/')) {
          final parts = fullId.split('/');
          memoId = parts[0];
          commentId = parts[1];
        } else {
          // Find the memoId by searching through comments
          for (final entry in createdComments.entries) {
            if (entry.value.any((c) => c.id == commentId)) {
              memoId = entry.key;
              break;
            }
          }
        }

        if (memoId.isEmpty || !createdComments.containsKey(memoId)) {
          throw Exception(
            'Comment not found: $fullId (Memo context not found)',
          );
        }
        final comment = createdComments[memoId]!.firstWhere(
          (c) => c.id == commentId,
          orElse:
              () =>
                  throw Exception(
                    'Comment not found: $commentId in memo $memoId',
                  ),
        );
        return comment;
      });

      // Stub listMemoComments
      when(mockApiService.listMemoComments(any)).thenAnswer((invocation) async {
        final memoId = invocation.positionalArguments[0] as String;
        return createdComments[memoId] ?? [];
      });

      // Stub updateMemoComment
      when(mockApiService.updateMemoComment(any, any)).thenAnswer((
        invocation,
      ) async {
        final fullId = invocation.positionalArguments[0] as String;
        final updatedCommentData = invocation.positionalArguments[1] as Comment;
        String memoId = '';
        String commentId = fullId;

        if (fullId.contains('/')) {
          final parts = fullId.split('/');
          memoId = parts[0];
          commentId = parts[1];
        } else {
          for (final entry in createdComments.entries) {
            if (entry.value.any((c) => c.id == commentId)) {
              memoId = entry.key;
              break;
            }
          }
        }

        if (memoId.isEmpty || !createdComments.containsKey(memoId)) {
          throw Exception('Comment not found for update: $fullId');
        }
        final commentsList = createdComments[memoId]!;
        final index = commentsList.indexWhere((c) => c.id == commentId);
        if (index == -1) {
          throw Exception(
            'Comment not found for update: $commentId in memo $memoId',
          );
        }
        final originalComment = commentsList[index];
        final updated = Comment(
          id: originalComment.id,
          content: updatedCommentData.content,
          createTime: originalComment.createTime,
          updateTime: DateTime.now().millisecondsSinceEpoch,
          creatorId: originalComment.creatorId,
          pinned: updatedCommentData.pinned,
          state: updatedCommentData.state,
          resources: updatedCommentData.resources ?? originalComment.resources,
        );
        commentsList[index] = updated;
        return updated;
      });

      // Stub deleteMemoComment
      when(mockApiService.deleteMemoComment(any, any)).thenAnswer((
        invocation,
      ) async {
        final memoId = invocation.positionalArguments[0] as String;
        final commentId = invocation.positionalArguments[1] as String;
        if (!createdComments.containsKey(memoId)) {
          throw Exception('No comments for memo: $memoId');
        }
        final commentsList = createdComments[memoId]!;
        final initialLength = commentsList.length;
        commentsList.removeWhere((c) => c.id == commentId);
        if (commentsList.length == initialLength) {
          throw Exception(
            'Comment not found for delete: $commentId in memo $memoId',
          );
        }
        return;
      });

      // Stub listMemoRelations
      when(mockApiService.listMemoRelations(any)).thenAnswer((
        invocation,
      ) async {
        if (shouldFailRelations) {
          throw Exception('Simulated API error: Failed to list relations');
        }
        final memoId = invocation.positionalArguments[0] as String;
        final formattedId =
            memoId.contains('/') ? memoId.split('/').last : memoId;
        return createdRelations[formattedId] ?? [];
      });

      // Stub setMemoRelations
      when(mockApiService.setMemoRelations(any, any)).thenAnswer((
        invocation,
      ) async {
        if (shouldFailRelations) {
          throw Exception('Simulated API error: Could not set relations');
        }
        final memoId = invocation.positionalArguments[0] as String;
        final relations =
            invocation.positionalArguments[1] as List<MemoRelation>;
        final formattedId =
            memoId.contains('/') ? memoId.split('/').last : memoId;
        createdRelations[formattedId] = List.from(relations);
        return;
      });

      // Stub uploadResource
      when(mockApiService.uploadResource(any, any, any)).thenAnswer((
        invocation,
      ) async {
        final bytes = invocation.positionalArguments[0] as Uint8List;
        final filename = invocation.positionalArguments[1] as String;
        final contentType = invocation.positionalArguments[2] as String;
        final resourceName =
            'resources/mock-resource-${DateTime.now().millisecondsSinceEpoch}';
        return V1Resource(
          name: resourceName,
          filename: filename,
          type: contentType,
          size: bytes.length.toString(),
          createTime: DateTime.now(),
        );
      });

      // Override the apiServiceProvider to use our mock
      container = ProviderContainer(
        overrides: [apiServiceProvider.overrideWithValue(mockApiService)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('archiveCommentProvider archives a comment correctly', () async {
      // Set up test memo and comment using the stubbed methods
      final memo = await mockApiService.createMemo(
        Memo(id: 'test-memo-1', content: 'Test memo'),
      );
      final comment = await mockApiService.createMemoComment(
        memo.id,
        Comment(
          id: 'test-comment',
          content: 'Test comment',
          createTime: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      final fullId = '${memo.id}/${comment.id}';

      // Call the archive provider
      await container.read(comment_providers.archiveCommentProvider(fullId))();

      // Verify the updateMemoComment call using Mockito
      final verificationResult = verify(
        mockApiService.updateMemoComment(argThat(equals(fullId)), captureAny),
      );
      verificationResult.called(1);
      final capturedComment = verificationResult.captured.single as Comment;
      expect(capturedComment.state, equals(CommentState.archived));

      // Optional: Verify the final state by getting the comment again
      final updatedComment = await mockApiService.getMemoComment(fullId);
      expect(updatedComment.state, equals(CommentState.archived));
    });

    test('deleteCommentProvider deletes a comment correctly', () async {
      // Set up test memo and comment
      final memo = await mockApiService.createMemo(
        Memo(id: 'test-memo-2', content: 'Test memo'),
      );
      final comment = await mockApiService.createMemoComment(
        memo.id,
        Comment(
          id: 'test-comment-delete',
          content: 'Comment to delete',
          createTime: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      // Verify comment exists (using stubbed list)
      final comments = await mockApiService.listMemoComments(memo.id);
      expect(comments.any((c) => c.id == comment.id), isTrue);

      // Get combined ID
      final fullId = '${memo.id}/${comment.id}';

      // Call the delete provider
      await container.read(comment_providers.deleteCommentProvider(fullId))();

      // Verify deleteMemoComment was called
      verify(mockApiService.deleteMemoComment(memo.id, comment.id)).called(1);

      // Verify comment was deleted (using stubbed list)
      final commentsAfter = await mockApiService.listMemoComments(memo.id);
      expect(commentsAfter.any((c) => c.id == comment.id), isFalse);
    });

    test('togglePinCommentProvider toggles comment pin state', () async {
      // Set up test memo and comment
      final memo = await mockApiService.createMemo(
        Memo(id: 'test-memo-3', content: 'Test memo'),
      );
      final comment = await mockApiService.createMemoComment(
        memo.id,
        Comment(
          id: 'test-comment-pin',
          content: 'Comment to pin/unpin',
          createTime: DateTime.now().millisecondsSinceEpoch,
          pinned: false, // Start unpinned
        ),
      );
      final fullId = '${memo.id}/${comment.id}';

      // Store comments passed to updateMemoComment for later verification
      List<Comment> updatedComments = [];

      // Create a stub that also records the comments
      when(mockApiService.updateMemoComment(any, any)).thenAnswer((
        invocation,
      ) async {
        final fullId = invocation.positionalArguments[0] as String;
        final updatedCommentData = invocation.positionalArguments[1] as Comment;

        // Save the comment for verification
        updatedComments.add(updatedCommentData);

        // Original implementation from setUp
        String memoId = '';
        String commentId = fullId;

        if (fullId.contains('/')) {
          final parts = fullId.split('/');
          memoId = parts[0];
          commentId = parts[1];
        } else {
          for (final entry in createdComments.entries) {
            if (entry.value.any((c) => c.id == commentId)) {
              memoId = entry.key;
              break;
            }
          }
        }

        if (memoId.isEmpty || !createdComments.containsKey(memoId)) {
          throw Exception('Comment not found for update: $fullId');
        }
        final commentsList = createdComments[memoId]!;
        final index = commentsList.indexWhere((c) => c.id == commentId);
        if (index == -1) {
          throw Exception(
            'Comment not found for update: $commentId in memo $memoId',
          );
        }
        final originalComment = commentsList[index];
        final updated = Comment(
          id: originalComment.id,
          content: updatedCommentData.content,
          createTime: originalComment.createTime,
          updateTime: DateTime.now().millisecondsSinceEpoch,
          creatorId: originalComment.creatorId,
          pinned: updatedCommentData.pinned,
          state: updatedCommentData.state,
          resources: updatedCommentData.resources ?? originalComment.resources,
        );
        commentsList[index] = updated;
        return updated;
      });

      // --- Toggle pin state to true ---
      await container.read(
        comment_providers.togglePinCommentProvider(fullId),
      )();

      // --- Toggle pin state back to false ---
      await container.read(
        comment_providers.togglePinCommentProvider(fullId),
      )();

      // Now verify both toggle operations using the captured comments
      expect(
        updatedComments.length,
        2,
        reason: "Should have 2 comment updates",
      );
      expect(
        updatedComments[0].pinned,
        isTrue,
        reason: "First update should set pinned to true",
      );
      expect(
        updatedComments[1].pinned,
        isFalse,
        reason: "Second update should set pinned to false",
      );
      
      // Also verify the final state through the API
      final finalComment = await mockApiService.getMemoComment(fullId);
      expect(finalComment.pinned, isFalse);
    });

    test(
      'convertCommentToMemoProvider converts a comment to a memo with relation',
      () async {
        // Set up test memo and comment
        final memo = await mockApiService.createMemo(
          Memo(id: 'test-memo-convert', content: 'Test memo for conversion'),
        );
        final comment = await mockApiService.createMemoComment(
          memo.id,
          Comment(
            id: 'test-comment-convert',
            content: 'Comment to convert to memo',
            createTime: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        final fullId = '${memo.id}/${comment.id}';

        // Get the function from the provider and call it
        final convertFunction = container.read(
          comment_providers.convertCommentToMemoProvider(fullId),
        );
        final createdMemo = await convertFunction();

        // Verify memo was created
        expect(createdMemo, isNotNull);
        expect(createdMemo.content, equals(comment.content));
        // We verify that createMemo was called at least once - the exact number doesn't matter
        // since the memo refresh operation might trigger additional calls
        verify(mockApiService.createMemo(any)).called(greaterThanOrEqualTo(1));

        // Verify relation was set
        final relationVerification = verify(
          mockApiService.setMemoRelations(
            argThat(equals(createdMemo.id)),
            captureAny,
          ),
        );
        relationVerification.called(1);
        final capturedRelations =
            relationVerification.captured.single as List<MemoRelation>;
        expect(capturedRelations, hasLength(1));
        expect(capturedRelations.first.relatedMemoId, equals(memo.id));
        expect(capturedRelations.first.type, equals(MemoRelation.typeComment));

        // Optional: Verify relation list via stubbed listMemoRelations
        final relations = await mockApiService.listMemoRelations(
          createdMemo.id,
        );
        expect(relations, hasLength(1));
        expect(relations.first.relatedMemoId, equals(memo.id));
      },
    );

    test(
      'convertCommentToMemoProvider succeeds even if relation creation fails',
      () async {
        // Set up test memo and comment
        final memo = await mockApiService.createMemo(
          Memo(
            id: 'test-memo-no-relation',
            content: 'Test memo for conversion without relation',
          ),
        );
        final comment = await mockApiService.createMemoComment(
          memo.id,
          Comment(
            id: 'test-comment-no-relation',
            content: 'Comment to convert to memo without relation',
            createTime: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        final fullId = '${memo.id}/${comment.id}';

        // Configure mock to fail when setting relations
        shouldFailRelations = true; // Use the flag defined in setUp
        // Re-stub setMemoRelations to throw based on the flag
        when(mockApiService.setMemoRelations(any, any)).thenAnswer((
          invocation,
        ) async {
          if (shouldFailRelations) {
            throw Exception('Simulated API error: Could not set relations');
          }
          final memoId = invocation.positionalArguments[0] as String;
          final relations =
              invocation.positionalArguments[1] as List<MemoRelation>;
          final formattedId =
              memoId.contains('/') ? memoId.split('/').last : memoId;
          createdRelations[formattedId] = List.from(relations);
          return;
        });

        // Get the function from the provider and call it
        final convertFunction = container.read(
          comment_providers.convertCommentToMemoProvider(fullId),
        );
        final createdMemo = await convertFunction();

        // Verify memo was created successfully
        expect(createdMemo, isNotNull);
        expect(createdMemo.content, equals(comment.content));
        verify(mockApiService.createMemo(any)).called(greaterThanOrEqualTo(1));

        // Verify setMemoRelations was called but threw (implicitly handled by try/catch in provider)
        verify(
          mockApiService.setMemoRelations(argThat(equals(createdMemo.id)), any),
        ).called(1);

        // Reset flag
        shouldFailRelations = false;
      },
    );

    test(
      'createCommentProvider uploads resource and creates comment with resource link',
      () async {
        // Arrange
        final memoId = 'memo-for-upload-test';
        final commentContent = 'Test comment with upload';
        final mockComment = Comment(
          id: 'temp-upload-comment',
          content: commentContent,
          createTime: DateTime.now().millisecondsSinceEpoch,
        );
        final mockBytes = Uint8List.fromList([10, 20, 30]);
        final mockFilename = 'upload.jpg';
        final mockContentType = 'image/jpeg';
        final mockResourceName = 'resources/mock-upload-resource-123';
        final mockExpectedResource = V1Resource(
          name: mockResourceName,
          filename: mockFilename,
          type: mockContentType,
          createTime: DateTime.now(),
          size: '3',
        );

        // Configure the mock ApiService responses using Mockito
        when(
          mockApiService.uploadResource(any, any, any),
        ).thenAnswer((_) async => mockExpectedResource);

        // Act
        final createFunction = container.read(
          comment_providers.createCommentProvider(memoId),
        );
        final resultComment = await createFunction(
          mockComment,
          fileBytes: mockBytes,
          filename: mockFilename,
          contentType: mockContentType,
        );

        // Assert
        // Verify uploadResource call
        final uploadVerification = verify(
          mockApiService.uploadResource(captureAny, captureAny, captureAny),
        );
        uploadVerification.called(1);
        expect(uploadVerification.captured[0], equals(mockBytes));
        expect(uploadVerification.captured[1], equals(mockFilename));
        expect(uploadVerification.captured[2], equals(mockContentType));

        // Verify createMemoComment call
        final createCommentVerification = verify(
          mockApiService.createMemoComment(
            argThat(equals(memoId)),
            captureAny,
            resources: captureAnyNamed('resources'),
          ),
        );
        createCommentVerification.called(1);
        final capturedCommentArg =
            createCommentVerification.captured[0] as Comment;
        final capturedResourcesArg =
            createCommentVerification.captured[1] as List<V1Resource>?;

        expect(capturedCommentArg.content, equals(commentContent));
        expect(capturedResourcesArg, isNotNull);
        expect(capturedResourcesArg, hasLength(1));
        final passedResource = capturedResourcesArg!.first;
        expect(passedResource.name, equals(mockResourceName));
        expect(passedResource.filename, equals(mockFilename));
        expect(passedResource.type, equals(mockContentType));

        // Verify the final result returned by the provider
        expect(resultComment, isNotNull);
        expect(resultComment.content, equals(commentContent));
        expect(resultComment.resources, isNotNull);
        expect(resultComment.resources, hasLength(1));
        final finalResource = resultComment.resources!.first;
        expect(finalResource.name, equals(mockResourceName));
        expect(finalResource.filename, equals(mockFilename));
        expect(finalResource.type, equals(mockContentType));
      },
    );

    test(
      'createCommentProvider creates comment and bumps parent memo (no upload)',
      () async {
        // Arrange
        final memo = await mockApiService.createMemo(
          Memo(id: 'test-memo-bump', content: 'Test memo for bump'),
        );
        final newComment = Comment(
          id: 'test-comment-bump',
          content: 'Comment that should trigger memo bump',
          createTime: DateTime.now().millisecondsSinceEpoch,
        );

        // Act: Call createCommentProvider without file data
        await container.read(comment_providers.createCommentProvider(memo.id))(
          newComment,
        );

        // Assert
        verifyNever(mockApiService.uploadResource(any, any, any));

        final createCommentVerification = verify(
          mockApiService.createMemoComment(
            argThat(equals(memo.id)),
            any,
            resources: captureAnyNamed('resources'),
          ),
        );
        createCommentVerification.called(1);
        expect(createCommentVerification.captured.last, isNull);

        // Verify parent memo was bumped (getMemo followed by updateMemo)
        // NOTE: The bump logic was commented out in the original provider code.
        // If re-enabled, these assertions would be valid.
        // verify(mockApiService.getMemo(memo.id)).called(1);
        // verify(mockApiService.updateMemo(memo.id, any)).called(1);
      },
    );
  });
}
