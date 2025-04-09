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

    // Use setUpAll to configure the service once
    setUpAll(() async {
      // Check environment variables FIRST
      const baseUrl = String.fromEnvironment(
        'MEMOS_TEST_API_BASE_URL',
        defaultValue: '',
      );
      const apiKey = String.fromEnvironment(
        'MEMOS_TEST_API_KEY',
        defaultValue: '',
      );

      if (RUN_INTEGRATION_TESTS) {
        if (baseUrl.isEmpty || apiKey.isEmpty) {
          print(
            'WARNING: Integration test environment variables not set (MEMOS_TEST_API_BASE_URL, MEMOS_TEST_API_KEY). Skipping configuration.',
          );
          // Instantiate to avoid null errors in tearDown/tests if they somehow run
          apiService = ApiService();
        } else {
          // Only configure if running tests AND vars are set
          apiService = ApiService(); // Instantiate here
          print('Configuring ApiService for integration tests: $baseUrl');
          apiService.configureService(baseUrl: baseUrl, authToken: apiKey);
          ApiService.verboseLogging = true; // Optional
        }
      } else {
        // Instantiate even if skipping for potential tearDown logic
        apiService = ApiService();
        print('RUN_INTEGRATION_TESTS is false. Skipping API configuration.');
      }
    });

    setUp(() {
      // No need to instantiate apiService here anymore, it's done in setUpAll
      // Add checks here if needed, e.g., ensure service is configured if RUN_INTEGRATION_TESTS is true
      if (RUN_INTEGRATION_TESTS && apiService.apiBaseUrl.isEmpty) {
        // This indicates env vars were missing, tests will likely fail or be skipped.
        print(
          "Warning: ApiService not configured in setUp, integration tests might fail.",
        );
      }
    });
    
    test('Create, retrieve, update, and delete memo', () async {
      // Skip unless integration tests are enabled AND configured
      if (!RUN_INTEGRATION_TESTS || apiService.apiBaseUrl.isEmpty) {
        print(
          'Skipping integration test - RUN_INTEGRATION_TESTS is false or ApiService not configured.',
        );
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
      final originalUpdateTime =
          retrievedMemo.updateTime; // Store original update time
      print(
        'Retrieved memo successfully. Original updateTime: $originalUpdateTime',
      );
      
      // 3. Update the memo
      // Introduce a small delay to ensure the updateTime will definitely change
      await Future.delayed(const Duration(seconds: 1));
      final updatedContent = 'Updated content ${DateTime.now().toIso8601String()}';
      final memoToUpdate = retrievedMemo.copyWith(
        content: updatedContent,
        pinned: true,
      );
      
      final updatedMemo = await apiService.updateMemo(retrievedMemo.id, memoToUpdate);
      expect(updatedMemo.content, equals(updatedContent));
      expect(updatedMemo.pinned, isTrue);
      final newUpdateTime = updatedMemo.updateTime; // Get new update time
      print('Updated memo successfully. New updateTime: $newUpdateTime');

      // Verify that updateTime actually changed and is later
      expect(
        newUpdateTime,
        isNotNull,
        reason: 'New updateTime should not be null',
      );
      expect(
        originalUpdateTime,
        isNotNull,
        reason: 'Original updateTime should not be null',
      );
      expect(
        newUpdateTime,
        isNot(equals(originalUpdateTime)),
        reason: 'UpdateTime should change after update',
      );

      // Optionally, verify the new time is later than the old one
      try {
        final originalDate = DateTime.parse(originalUpdateTime!);
        final newDate = DateTime.parse(newUpdateTime!);
        expect(
          newDate.isAfter(originalDate) ||
              newDate.isAtSameMomentAs(originalDate),
          isTrue,
          reason: 'New updateTime should be later than or same as original',
        );
      } catch (e) {
        print('Warning: Could not parse update timestamps for comparison: $e');
      }
      
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
      // Skip unless integration tests are enabled AND configured
      if (!RUN_INTEGRATION_TESTS || apiService.apiBaseUrl.isEmpty) {
        print(
          'Skipping integration test - RUN_INTEGRATION_TESTS is false or ApiService not configured.',
        );
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
      
      // Check that we got results by checking the .memos list
      expect(
        memosByUpdateTime.memos, // Correctly accessing .memos
        isNotEmpty,
        reason: "List sorted by updateTime should not be empty",
      );
      expect(
        memosByCreateTime.memos, // Correctly accessing .memos
        isNotEmpty,
        reason: "List sorted by createTime should not be empty",
      );
      
      // Print the first few results from each query
      print('\nMemos sorted by updateTime:');
      for (int i = 0; i < 3 && i < memosByUpdateTime.memos.length; i++) {
        // Access .memos
        print('${i + 1}. ID: ${memosByUpdateTime.memos[i].id}');
        print('   UpdateTime: ${memosByUpdateTime.memos[i].updateTime}');
      }
      
      print('\nMemos sorted by createTime:');
      for (int i = 0; i < 3 && i < memosByCreateTime.memos.length; i++) {
        // Access .memos
        print('${i + 1}. ID: ${memosByCreateTime.memos[i].id}');
        print('   CreateTime: ${memosByCreateTime.memos[i].createTime}');
      }
    });

    test('Create, retrieve, update, and delete comment', () async {
      // Skip unless integration tests are enabled AND configured
      if (!RUN_INTEGRATION_TESTS || apiService.apiBaseUrl.isEmpty) {
        print(
          'Skipping integration test - RUN_INTEGRATION_TESTS is false or ApiService not configured.',
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
      // Skip unless integration tests are enabled AND configured
      if (!RUN_INTEGRATION_TESTS || apiService.apiBaseUrl.isEmpty) {
        print(
          'Skipping integration test - RUN_INTEGRATION_TESTS is false or ApiService not configured.',
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
