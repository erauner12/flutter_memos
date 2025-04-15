import 'dart:typed_data';

import 'package:flutter_memos/api/lib/api.dart'; // Keep for V1Resource if still used by API
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/services/base_api_service.dart'; // Keep for verboseLogging
import 'package:flutter_memos/services/memos_api_service.dart'; // Confirmed import exists
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

// Define a constant for controlling integration tests
const bool runIntegrationTests =
    false; // Set to true to enable integration tests

// Generate nice mock for MemosApiService (or BaseApiService if preferred)
// Mocking the concrete class might be easier for integration-like tests
// Generate nice mock for MemosApiService (or BaseApiService if preferred)
// Mocking the concrete class might be easier for integration-like tests
@GenerateNiceMocks([MockSpec<MemosApiService>()]) // Confirmed MemosApiService
void main() {
  group('ApiService Resource Integration Tests', () {
    late MemosApiService apiService; // Use concrete type
    String? testNoteId; // Updated variable name
    String? createdCommentId;
    String? uploadedResourceId;

    setUpAll(() async {
      if (!runIntegrationTests) {
        print(
          '[Test Setup] Skipping ApiServiceResourceTest setup because runIntegrationTests is false.',
        );
        return;
      }

      const baseUrl = String.fromEnvironment(
        'MEMOS_TEST_API_BASE_URL',
        defaultValue: '',
      );
      const apiKey = String.fromEnvironment(
        'MEMOS_TEST_API_KEY',
        defaultValue: '',
      );

      if (baseUrl.isEmpty || apiKey.isEmpty) {
        print(
          'WARNING: Test server URL or API Key is not configured. Set MEMOS_TEST_API_BASE_URL and MEMOS_TEST_API_KEY environment variables. Skipping ApiServiceResourceTest configuration and note creation.', // Updated message
        );
        return;
      }

      apiService = MemosApiService(); // Instantiate concrete class
      apiService.configureService(baseUrl: baseUrl, authToken: apiKey);
      BaseApiService.verboseLogging = true; // Optional

      // Create a temporary note for attaching comments
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempNote = NoteItem(
          // Updated type
          id: 'temp-note-resource-test-$timestamp', // Updated prefix
          content:
              'Temporary Note for Resource Test - $timestamp', // Updated content
          visibility: NoteVisibility.private, // Keep test notes private
          createTime: DateTime.now(), // Add required field
          updateTime: DateTime.now(), // Add required field
          displayTime: DateTime.now(), // Add required field
          state: NoteState.normal, // Add required field
        );
        final createdNote = await apiService.createNote(
          tempNote,
        ); // Updated method name
        testNoteId = createdNote.id;
        print(
          '[Test Setup] Created temporary note for testing: ID $testNoteId', // Updated log
        );
      } catch (e) {
        print(
          '[Test Setup] Failed to create temporary note: $e',
        ); // Updated log
        throw Exception(
          'Setup failed: Could not create test note. $e',
        ); // Updated message
      }
    });

    tearDownAll(() async {
      if (!runIntegrationTests || testNoteId == null) {
        print(
          '[Test Cleanup] Skipping ApiServiceResourceTest cleanup (runIntegrationTests is false or testNoteId is null).', // Updated log
        );
        return;
      }

      // Attempt to delete the created comment if it exists
      if (createdCommentId != null) {
        try {
          await apiService.deleteNoteComment(
            testNoteId!,
            createdCommentId!,
          ); // Updated method name
          print(
            '[Test Cleanup] Deleted test comment: $createdCommentId from note $testNoteId', // Updated log
          );
        } catch (e) {
          print(
            '[Test Cleanup] Warning: Failed to delete test comment $createdCommentId: $e',
          );
        }
      }

      // Attempt to delete the uploaded resource if its ID is known
      if (uploadedResourceId != null) {
        try {
          // Assuming a deleteResource method exists
          // await apiService.deleteResource(uploadedResourceId!);
          print(
            '[Test Cleanup] Attempted to delete resource (if API exists): $uploadedResourceId',
          );
        } catch (e) {
          print(
            '[Test Cleanup] Warning: Failed to delete resource $uploadedResourceId: $e',
          );
        }
      }

      // Delete the temporary note
      try {
        await apiService.deleteNote(testNoteId!); // Updated method name
        print(
          '[Test Cleanup] Deleted temporary note: $testNoteId',
        ); // Updated log
      } catch (e) {
        print(
          '[Test Cleanup] Warning: Failed to delete test note $testNoteId: $e', // Updated log
        );
      }
    });

    test('uploads resource and creates comment with that resource', () async {
      if (!runIntegrationTests || apiService.apiBaseUrl.isEmpty) {
        print(
          'Skipping test "uploads resource and creates comment" - Integration tests disabled or MemosApiService not configured.', // Updated message
        );
        return;
      }

      expect(
        testNoteId,
        isNotNull,
        reason: 'Test note ID should be set in setUpAll', // Updated message
      );

      // Arrange
      final mockBytes = Uint8List.fromList(
        [1, 2, 3, 4, 5],
      );
      final mockFilename =
          'test_upload_${DateTime.now().millisecondsSinceEpoch}.txt';
      final mockContentType = 'text/plain';
      final commentContent =
          'Comment with resource - ${DateTime.now().millisecondsSinceEpoch}';
      final tempComment = Comment(
        id: 'temp-comment-${DateTime.now().millisecondsSinceEpoch}',
        content: commentContent,
        createTime: DateTime.now().millisecondsSinceEpoch,
      );

      // Act: Upload Resource
      // Assuming uploadResource returns Map<String, dynamic> now
      Map<String, dynamic>? uploadedResourceMap;
      try {
        print('[Test Action] Uploading resource: $mockFilename');
        uploadedResourceMap = await apiService.uploadResource(
          mockBytes,
          mockFilename,
          mockContentType,
        );
        uploadedResourceId = uploadedResourceMap['name']; // Store for cleanup
        print(
          '[Test Action] Resource uploaded successfully: ID ${uploadedResourceMap['name']}',
        );
      } catch (e) {
        fail('Failed to upload resource: $e');
      }

      // Assert: Verify Uploaded Resource Map
      expect(
        uploadedResourceMap,
        isNotNull,
        reason: 'uploadResource should return a resource map',
      );
      expect(
        uploadedResourceMap['name'],
        isNotNull,
        reason: 'Uploaded resource map should have a name (ID)',
      );
      expect(
        uploadedResourceMap['name'],
        isNotEmpty,
        reason: 'Uploaded resource name should not be empty',
      );
      expect(
        uploadedResourceMap['filename'],
        equals(mockFilename),
        reason: 'Filename mismatch in uploaded resource map',
      );
      expect(
        uploadedResourceMap['type'],
        equals(mockContentType),
        reason: 'Content type mismatch in uploaded resource map',
      );

      // Act: Create Comment with Resource Map
      Comment? resultComment;
      try {
        print(
          '[Test Action] Creating comment on note $testNoteId with resource ${uploadedResourceMap['name']}', // Updated log
        );
        resultComment = await apiService.createNoteComment(
          // Updated method name
          testNoteId!,
          tempComment,
          resources: [uploadedResourceMap], // Pass the uploaded resource map
        );
        createdCommentId = resultComment.id;
        print(
          '[Test Action] Comment created successfully: ID ${resultComment.id}',
        );
      } catch (e) {
        fail('Failed to create comment with resource: $e');
      }

      // Assert: Verify Created Comment
      expect(
        resultComment,
        isNotNull,
        reason: 'createNoteComment should return a comment', // Updated message
      );
      expect(
        resultComment.id,
        isNotNull,
        reason: 'Created comment should have an ID',
      );
      expect(
        resultComment.id,
        isNotEmpty,
        reason: 'Created comment ID should not be empty',
      );
      expect(
        resultComment.content,
        equals(commentContent),
        reason: 'Comment content mismatch',
      );
      expect(
        resultComment.resources,
        isNotNull,
        reason: 'Comment should have a resources list',
      );
      expect(
        resultComment.resources,
        hasLength(1),
        reason: 'Comment should have one resource',
      );

      // Access resource data as Map
      final resourceInComment = resultComment.resources!.first;
      expect(
        resourceInComment['name'],
        equals(uploadedResourceMap['name']),
        reason: 'Resource name mismatch in comment',
      );
      expect(
        resourceInComment['filename'],
        equals(mockFilename),
        reason: 'Resource filename mismatch in comment',
      );
      expect(
        resourceInComment['type'],
        equals(mockContentType),
        reason: 'Resource type mismatch in comment',
      );

      // Assert: (Optional) Fetch the comment again to verify persistence
      try {
        print(
          '[Test Verify] Fetching created comment again: ID ${resultComment.id}',
        );
        final fetchedComment = await apiService.getNoteComment(
          // Updated method name
          resultComment.id,
        );
        print('[Test Verify] Fetched comment successfully.');

        expect(
          fetchedComment.resources,
          isNotNull,
          reason: 'Fetched comment should have resources',
        );
        expect(
          fetchedComment.resources,
          hasLength(1),
          reason: 'Fetched comment should have one resource',
        );
        final fetchedResource = fetchedComment.resources!.first;
        expect(
          fetchedResource['name'],
          equals(uploadedResourceMap['name']),
          reason: 'Resource name mismatch in fetched comment',
        );
        expect(
          fetchedResource['filename'],
          equals(mockFilename),
          reason: 'Resource filename mismatch in fetched comment',
        );
        expect(
          fetchedResource['type'],
          equals(mockContentType),
          reason: 'Resource type mismatch in fetched comment',
        );
      } catch (e) {
        fail('Failed to fetch and verify the created comment: $e');
      }

      print('[Test Success] Resource upload and comment creation verified.');
    });
  });
}
