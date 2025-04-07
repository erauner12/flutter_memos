import 'dart:typed_data';

import 'package:flutter_memos/api/lib/api.dart'; // For V1Resource
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/utils/env.dart'; // To potentially load credentials
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
// Generate nice mock for ApiService
@GenerateNiceMocks([MockSpec<ApiService>()])
void main() {
  group('ApiService Resource Integration Tests', () {
    late ApiService apiService;
    String? testMemoId; // To store the ID of the memo created for testing
    String? createdCommentId; // To store the ID of the comment created

    setUpAll(() async {
      // --- IMPORTANT ---
      // Configure ApiService with your ACTUAL test server URL and API Key
      // You might load these from environment variables or a config file
      // Ensure Env.apiBaseUrl and Env.memosApiKey are correctly set for your test environment
      final baseUrl = Env.apiBaseUrl; // Replace with your test server URL if needed
      final apiKey = Env.memosApiKey; // Replace with your test API key if needed

      if (baseUrl.isEmpty || apiKey.isEmpty) {
        throw Exception(
          'Test server URL or API Key is not configured. Set Env.apiBaseUrl and Env.memosApiKey.',
        );
      }

      apiService = ApiService(); // Get the singleton instance
      apiService.configureService(baseUrl: baseUrl, authToken: apiKey);

      // Create a temporary memo for attaching comments
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempMemo = Memo(
          id: 'temp-memo-resource-test-$timestamp',
          content: 'Temporary Memo for Resource Test - $timestamp',
          visibility: 'PRIVATE', // Keep test memos private
        );
        final createdMemo = await apiService.createMemo(tempMemo);
        testMemoId = createdMemo.id;
        print(
          '[Test Setup] Created temporary memo for testing: ID $testMemoId',
        );
      } catch (e) {
        print('[Test Setup] Failed to create temporary memo: $e');
        // Fail fast if setup fails
        throw Exception('Setup failed: Could not create test memo. $e');
      }
    });

    tearDownAll(() async {
      if (testMemoId == null) return; // No memo was created

      // Attempt to delete the created comment if it exists
      if (createdCommentId != null) {
        try {
          // The delete API needs both memoId and commentId
          await apiService.deleteMemoComment(testMemoId!, createdCommentId!);
          print(
            '[Test Cleanup] Deleted test comment: $createdCommentId from memo $testMemoId',
          );
        } catch (e) {
          print(
            '[Test Cleanup] Warning: Failed to delete test comment $createdCommentId: $e',
          );
        }
      }

      // Attempt to delete the uploaded resource if its ID is known
      // NOTE: This requires a deleteResource method in ApiService, which might not exist.
      // If it doesn't exist, this part can be commented out.
      /*
      if (uploadedResourceId != null) {
        try {
          // Assuming a deleteResource method exists in ResourceServiceApi and is exposed via ApiService
          // await apiService.deleteResource(uploadedResourceId!);
          print('[Test Cleanup] Deleted uploaded resource: $uploadedResourceId');
        } catch (e) {
          print('[Test Cleanup] Warning: Failed to delete resource $uploadedResourceId: $e');
          // Depending on the API, resource deletion might fail if it's attached to a comment.
        }
      }
      */

      // Delete the temporary memo
      try {
        await apiService.deleteMemo(testMemoId!);
        print('[Test Cleanup] Deleted temporary memo: $testMemoId');
      } catch (e) {
        print('[Test Cleanup] Warning: Failed to delete test memo $testMemoId: $e');
      }
    });

    test('uploads resource and creates comment with that resource', () async {
      // Pre-condition check
      expect(testMemoId, isNotNull, reason: 'Test memo ID should be set in setUpAll');

      // Arrange
      final mockBytes = Uint8List.fromList(
        [1, 2, 3, 4, 5],
      ); // Simple byte data
      final mockFilename = 'test_upload_${DateTime.now().millisecondsSinceEpoch}.txt';
      final mockContentType = 'text/plain';
      final commentContent = 'Comment with resource - ${DateTime.now().millisecondsSinceEpoch}';
      final tempComment = Comment(
        id: 'temp-comment-${DateTime.now().millisecondsSinceEpoch}',
        content: commentContent,
        createTime: DateTime.now().millisecondsSinceEpoch,
      );

      // Act: Upload Resource
      V1Resource? uploadedResource;
      try {
        print('[Test Action] Uploading resource: $mockFilename');
        uploadedResource = await apiService.uploadResource(
          mockBytes,
          mockFilename,
          mockContentType,
        );
        uploadedResourceId = uploadedResource.name; // Store for potential cleanup
        print(
          '[Test Action] Resource uploaded successfully: ID ${uploadedResource.name}',
        );
      } catch (e) {
        fail('Failed to upload resource: $e');
      }

      // Assert: Verify Uploaded Resource
      expect(uploadedResource, isNotNull, reason: 'uploadResource should return a resource');
      expect(uploadedResource.name, isNotNull, reason: 'Uploaded resource should have a name (ID)');
      expect(uploadedResource.name, isNotEmpty, reason: 'Uploaded resource name should not be empty');
      expect(uploadedResource.filename, equals(mockFilename), reason: 'Filename mismatch in uploaded resource');
      expect(uploadedResource.type, equals(mockContentType), reason: 'Content type mismatch in uploaded resource');
      // Size check might be unreliable depending on server implementation (e.g., base64 overhead)
      // expect(uploadedResource.size, equals(mockBytes.length.toString()));

      // Act: Create Comment with Resource
      Comment? resultComment;
      try {
        print(
          '[Test Action] Creating comment on memo $testMemoId with resource ${uploadedResource.name}',
        );
        resultComment = await apiService.createMemoComment(
          testMemoId!,
          tempComment,
          resources: [uploadedResource], // Pass the uploaded resource
        );
        createdCommentId = resultComment.id; // Store for cleanup
        print(
          '[Test Action] Comment created successfully: ID ${resultComment.id}',
        );
      } catch (e) {
        fail('Failed to create comment with resource: $e');
      }

      // Assert: Verify Created Comment
      expect(resultComment, isNotNull, reason: 'createMemoComment should return a comment');
      expect(resultComment.id, isNotNull, reason: 'Created comment should have an ID');
      expect(resultComment.id, isNotEmpty, reason: 'Created comment ID should not be empty');
      expect(resultComment.content, equals(commentContent), reason: 'Comment content mismatch');
      expect(resultComment.resources, isNotNull, reason: 'Comment should have a resources list');
      expect(resultComment.resources, hasLength(1), reason: 'Comment should have one resource');

      final resourceInComment = resultComment.resources!.first;
      expect(resourceInComment.name, equals(uploadedResource.name), reason: 'Resource name mismatch in comment');
      expect(resourceInComment.filename, equals(mockFilename), reason: 'Resource filename mismatch in comment');
      expect(resourceInComment.type, equals(mockContentType), reason: 'Resource type mismatch in comment');

      // Assert: (Optional) Fetch the comment again to verify persistence
      try {
        print(
          '[Test Verify] Fetching created comment again: ID ${resultComment.id}',
        );
        // Use the combined ID format if necessary, or just the comment's own ID
        final fetchedComment = await apiService.getMemoComment(resultComment.id);
        print('[Test Verify] Fetched comment successfully.');

        expect(fetchedComment.resources, isNotNull, reason: 'Fetched comment should have resources');
        expect(fetchedComment.resources, hasLength(1), reason: 'Fetched comment should have one resource');
        final fetchedResource = fetchedComment.resources!.first;
        expect(fetchedResource.name, equals(uploadedResource.name), reason: 'Resource name mismatch in fetched comment');
        expect(fetchedResource.filename, equals(mockFilename), reason: 'Resource filename mismatch in fetched comment');
        expect(fetchedResource.type, equals(mockContentType), reason: 'Resource type mismatch in fetched comment');
      } catch (e) {
        fail('Failed to fetch and verify the created comment: $e');
      }

      print('[Test Success] Resource upload and comment creation verified.');
    });
  });
}
