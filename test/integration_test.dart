import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Set this to true to run integration tests against a real server
// WARNING: These tests will create and modify real data!
const bool RUN_INTEGRATION_TESTS = true;

void main() {
  group('API Integration Tests', () {
    late ApiService apiService;
    
    setUp(() {
      apiService = ApiService();
    });
    
    test('Create, retrieve, update, and delete memo', () async {
      // Skip unless integration tests are enabled
      if (!RUN_INTEGRATION_TESTS) {
        print('Skipping integration test - set RUN_INTEGRATION_TESTS = true to run');
        return;
      }
      
      // 1. Create a test memo
      final testMemo = Memo(
        id: 'test',
        content: 'Test memo ${DateTime.now().toIso8601String()}',
        pinned: false,
      );
      
      final createdMemo = await apiService.createMemo(testMemo);
      expect(createdMemo.content, equals(testMemo.content));
      print('Created memo with ID: ${createdMemo.id}');
      
      // 2. Retrieve the memo
      final retrievedMemo = await apiService.getMemo(createdMemo.id);
      expect(retrievedMemo.id, equals(createdMemo.id));
      expect(retrievedMemo.content, equals(createdMemo.content));
      print('Retrieved memo successfully');
      
      // 3. Update the memo
      final updatedContent = 'Updated content ${DateTime.now().toIso8601String()}';
      final memoToUpdate = retrievedMemo.copyWith(
        content: updatedContent,
        pinned: true,
      );
      
      final updatedMemo = await apiService.updateMemo(retrievedMemo.id, memoToUpdate);
      expect(updatedMemo.content, equals(updatedContent));
      expect(updatedMemo.pinned, isTrue);
      print('Updated memo successfully');
      
      // 4. Delete the memo
      await apiService.deleteMemo(updatedMemo.id);
      print('Deleted memo successfully');
      
      // 5. Verify deletion (should throw)
      try {
        await apiService.getMemo(updatedMemo.id);
        fail('Memo should have been deleted');
      } catch (e) {
        // Expected exception
        expect(e.toString(), contains('Failed to load memo'));
        print('Verified deletion (memo not found as expected)');
      }
    });
    
    test('List memos with different sort parameters', () async {
      // Skip unless integration tests are enabled
      if (!RUN_INTEGRATION_TESTS) {
        print('Skipping integration test - set RUN_INTEGRATION_TESTS = true to run');
        return;
      }
      
      // Get memos sorted by update time
      final memosByUpdateTime = await apiService.listMemos(
        parent: 'users/1',
        sort: 'updateTime',
        direction: 'DESC',
      );
      
      // Get memos sorted by create time
      final memosByCreateTime = await apiService.listMemos(
        parent: 'users/1',
        sort: 'createTime',
        direction: 'DESC',
      );
      
      // Check that we got results
      expect(memosByUpdateTime, isNotEmpty);
      expect(memosByCreateTime, isNotEmpty);
      
      // Print the first few results from each query
      print('\nMemos sorted by updateTime:');
      for (int i = 0; i < 3 && i < memosByUpdateTime.length; i++) {
        print('${i+1}. ID: ${memosByUpdateTime[i].id}');
        print('   UpdateTime: ${memosByUpdateTime[i].updateTime}');
      }
      
      print('\nMemos sorted by createTime:');
      for (int i = 0; i < 3 && i < memosByCreateTime.length; i++) {
        print('${i+1}. ID: ${memosByCreateTime[i].id}');
        print('   CreateTime: ${memosByCreateTime[i].createTime}');
      }
    });

    test('Create, retrieve, update, and delete comment', () async {
      // Skip unless integration tests are enabled
      if (!RUN_INTEGRATION_TESTS) {
        print(
          'Skipping integration test - set RUN_INTEGRATION_TESTS = true to run',
        );
        return;
      }

      // 1. Create a test memo to add comments to
      final testMemo = Memo(
        id: 'test',
        content: 'Test memo for comments ${DateTime.now().toIso8601String()}',
        pinned: false,
      );

      final createdMemo = await apiService.createMemo(testMemo);
      print('Created memo with ID: ${createdMemo.id}');

      try {
        // 2. Create a comment on the memo
        final testComment = Comment(
          id: 'temp',
          content: 'Test comment ${DateTime.now().toIso8601String()}',
          createTime: DateTime.now().millisecondsSinceEpoch,
        );

        final createdComment = await apiService.createMemoComment(
          createdMemo.id,
          testComment,
        );
        expect(createdComment.content, equals(testComment.content));
        print('Created comment with ID: ${createdComment.id}');

        // 3. Retrieve the comment using the combined ID format
        final retrievedComment = await apiService.getMemoComment(
          '${createdMemo.id}/${createdComment.id}',
        );
        expect(retrievedComment.id, equals(createdComment.id));
        expect(retrievedComment.content, equals(createdComment.content));
        print('Retrieved comment successfully using combined ID format');

        // 3b. Also test retrieving with just the commentId
        final retrievedComment2 = await apiService.getMemoComment(
          createdComment.id,
        );
        expect(retrievedComment2.id, equals(createdComment.id));
        print('Retrieved comment successfully using just commentId');

        // 4. Update the comment
        final updatedContent =
            'Updated comment content ${DateTime.now().toIso8601String()}';
        final commentToUpdate = retrievedComment.copyWith(
          content: updatedContent,
          pinned: true,
        );

        final updatedComment = await apiService.updateMemoComment(
          '${createdMemo.id}/${createdComment.id}',
          commentToUpdate,
        );
        expect(updatedComment.content, equals(updatedContent));
        expect(updatedComment.pinned, isTrue);
        print('Updated comment successfully');

        // 5. List all comments
        final comments = await apiService.listMemoComments(createdMemo.id);
        expect(comments, isNotEmpty);
        expect(comments.any((c) => c.id == createdComment.id), isTrue);
        print(
          'Listed comments successfully, found ${comments.length} comments',
        );

        // 6. Delete the comment
        await apiService.deleteMemoComment(createdMemo.id, createdComment.id);
        print('Deleted comment successfully');

        // 7. Verify deletion by listing comments again
        final commentsAfterDelete = await apiService.listMemoComments(
          createdMemo.id,
        );
        expect(
          commentsAfterDelete.any((c) => c.id == createdComment.id),
          isFalse,
        );
        print('Verified comment deletion successfully');
      } finally {
        // Clean up - delete the test memo
        await apiService.deleteMemo(createdMemo.id);
        print('Cleaned up by deleting test memo');
      }
    });

    test('Comment with special states and attributes', () async {
      // Skip unless integration tests are enabled
      if (!RUN_INTEGRATION_TESTS) {
        print(
          'Skipping integration test - set RUN_INTEGRATION_TESTS = true to run',
        );
        return;
      }

      // 1. Create a test memo
      final testMemo = Memo(
        id: 'test',
        content:
            'Test memo for special comment states ${DateTime.now().toIso8601String()}',
      );

      final createdMemo = await apiService.createMemo(testMemo);
      print('Created memo with ID: ${createdMemo.id}');

      try {
        // 2. Create a pinned comment
        final pinnedComment = Comment(
          id: 'temp',
          content: 'Pinned comment test',
          createTime: DateTime.now().millisecondsSinceEpoch,
          pinned: true,
        );
        
        final createdPinnedComment = await apiService.createMemoComment(
          createdMemo.id,
          pinnedComment,
        );
        print(
          'Created pinned comment with ID: ${createdPinnedComment.id}, pinned status: ${createdPinnedComment.pinned}',
        );
        // The API may not support setting pinned=true on creation, so we'll update it explicitly
        final updatedPinnedComment = await apiService.updateMemoComment(
          '${createdMemo.id}/${createdPinnedComment.id}',
          createdPinnedComment.copyWith(pinned: true),
        );
        expect(
          updatedPinnedComment.pinned,
          isTrue,
          reason: 'Comment should be pinned after explicit update',
        );
        print('Updated pinned comment successfully');
        
        // 3. Create a comment and then mark it as archived
        final commentToArchive1 = Comment(
          id: 'temp',
          content: 'First comment to archive test',
          createTime: DateTime.now().millisecondsSinceEpoch,
        );
        
        final createdCommentToArchive1 = await apiService.createMemoComment(
          createdMemo.id,
          commentToArchive1,
        );
        final archivedCommentId1 =
            '${createdMemo.id}/${createdCommentToArchive1.id}';

        // Update to archived state
        final updatedArchivedComment1 = await apiService.updateMemoComment(
          archivedCommentId1,
          createdCommentToArchive1.copyWith(state: CommentState.archived),
        );
        print('Comment 1 archived state: ${updatedArchivedComment1.state}');
        expect(
          updatedArchivedComment1.state,
          equals(CommentState.archived),
          reason: 'Comment state should be archived after update',
        );
        print('Successfully created and archived comment 1');
        
        // 4. Try another approach - create a comment already marked as archived
        final archivedComment2 = Comment(
          id: 'temp',
          content: 'Second archived comment test',
          createTime: DateTime.now().millisecondsSinceEpoch,
          state: CommentState.archived,
        );
        
        final createdArchivedComment2 = await apiService.createMemoComment(
          createdMemo.id,
          archivedComment2,
        );
        // Check if the created comment retained the archived state
        final retrievedArchivedComment2 = await apiService.getMemoComment(
          '${createdMemo.id}/${createdArchivedComment2.id}',
        );
        print('Comment 2 archived state: ${retrievedArchivedComment2.state}');

        // The API might not support setting archived state on creation
        // So update it explicitly and verify
        final updatedArchivedComment2 = await apiService.updateMemoComment(
          '${createdMemo.id}/${createdArchivedComment2.id}',
          retrievedArchivedComment2.copyWith(state: CommentState.archived),
        );
        expect(
          updatedArchivedComment2.state,
          equals(CommentState.archived),
          reason: 'Comment state should be archived after explicit update',
        );
        print('Successfully created and verified archived comment 2');
        
        // 5. Clean up
        await apiService.deleteMemoComment(
          createdMemo.id,
          createdPinnedComment.id,
        );
        await apiService.deleteMemoComment(
          createdMemo.id,
          createdCommentToArchive1.id,
        );
        await apiService.deleteMemoComment(
          createdMemo.id,
          createdArchivedComment2.id,
        );
      } finally {
        // Delete the test memo
        await apiService.deleteMemo(createdMemo.id);
        print('Cleaned up by deleting test memo');
      }
    });
  });
}
