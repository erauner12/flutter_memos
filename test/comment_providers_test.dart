import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/memo_relation.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/comment_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mock_api_service.dart';

void main() {
  group('Comment Providers Tests', () {
    late MockApiService mockApiService;
    late ProviderContainer container;

    setUp(() {
      mockApiService = MockApiService();
      
      // Override the apiServiceProvider to use our mock
      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('archiveCommentProvider archives a comment correctly', () async {
      // Set up test memo and comment
      final memo = await mockApiService.createMemo(
        Memo(
          id: 'test-memo-1',
          content: 'Test memo',
        ),
      );
      
      final comment = await mockApiService.createMemoComment(
        memo.id,
        Comment(
          id: 'test-comment',
          content: 'Test comment',
          createTime: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      
      // Construct the combined ID format
      final fullId = '${memo.id}/${comment.id}';
      
      // Call the archive provider
      await container.read(archiveCommentProvider(fullId))();
      
      // Verify the comment was archived
      // We would need to retrieve the comment again to check its state
      final updatedComment = await mockApiService.getMemoComment(fullId);
      expect(updatedComment.state, equals(CommentState.archived));
    });

    test('deleteCommentProvider deletes a comment correctly', () async {
      // Set up test memo and comment
      final memo = await mockApiService.createMemo(
        Memo(
          id: 'test-memo-2',
          content: 'Test memo',
        ),
      );
      
      final comment = await mockApiService.createMemoComment(
        memo.id,
        Comment(
          id: 'test-comment-delete',
          content: 'Comment to delete',
          createTime: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      
      // Verify comment exists
      final comments = await mockApiService.listMemoComments(memo.id);
      expect(comments.any((c) => c.id == comment.id), isTrue);
      
      // Get combined ID
      final fullId = '${memo.id}/${comment.id}';
      
      // Call the delete provider
      await container.read(deleteCommentProvider(fullId))();
      
      // Verify comment was deleted
      final commentsAfter = await mockApiService.listMemoComments(memo.id);
      expect(commentsAfter.any((c) => c.id == comment.id), isFalse);
    });

    test('togglePinCommentProvider toggles comment pin state', () async {
      // Set up test memo and comment
      final memo = await mockApiService.createMemo(
        Memo(
          id: 'test-memo-3',
          content: 'Test memo',
        ),
      );
      
      // Create an unpinned comment
      final comment = await mockApiService.createMemoComment(
        memo.id,
        Comment(
          id: 'test-comment-pin',
          content: 'Comment to pin/unpin',
          createTime: DateTime.now().millisecondsSinceEpoch,
          pinned: false,
        ),
      );
      
      // Get combined ID
      final fullId = '${memo.id}/${comment.id}';
      
      // Toggle pin state to true
      await container.read(togglePinCommentProvider(fullId))();
      
      // Verify pin state changed
      final pinnedComment = await mockApiService.getMemoComment(fullId);
      expect(pinnedComment.pinned, isTrue);
      
      // Toggle pin state back to false
      await container.read(togglePinCommentProvider(fullId))();
      
      // Verify pin state changed back
      final unpinnedComment = await mockApiService.getMemoComment(fullId);
      expect(unpinnedComment.pinned, isFalse);
    });

    test('hiddenCommentIdsProvider basic state operations', () {
      // Test direct state manipulation
      final commentId = 'memo1/comment1';
      
      // Initial state should be empty
      final initialState = container.read(hiddenCommentIdsProvider);
      expect(initialState.isEmpty, isTrue);
      
      // Directly modify the state to add the comment ID
      container.read(hiddenCommentIdsProvider.notifier).state = {commentId};
      
      // Verify the state was updated
      final updatedState = container.read(hiddenCommentIdsProvider);
      expect(updatedState.contains(commentId), isTrue);
      
      // Directly modify the state to remove the comment ID
      container.read(hiddenCommentIdsProvider.notifier).state = {};
      
      // Verify the state was updated
      final finalState = container.read(hiddenCommentIdsProvider);
      expect(finalState.contains(commentId), isFalse);
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

        // Get combined ID
        final fullId = '${memo.id}/${comment.id}';

        // Call the convert provider
        final createdMemo =
            await container.read(convertCommentToMemoProvider(fullId))();

        // Verify memo was created
        expect(createdMemo, isNotNull);
        expect(createdMemo.content, equals(comment.content));

        // Verify relation was created
        final relations = await mockApiService.listMemoRelations(
          createdMemo.id,
        );
        expect(relations, isNotEmpty);
        expect(relations.first.relatedMemoId, equals(memo.id));
        expect(relations.first.type, equals(MemoRelation.typeLinked));
      },
    );
  });
}
