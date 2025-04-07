import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
// Add imports for Memo model and ApiService
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  // Initialize integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // List to store IDs of memos created during the test for cleanup
  final List<String> createdMemoIds = [];

  // Helper function to create test file data
  Uint8List createTestFileData() {
    // Create a simple test file (a small PNG-like byte array)
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x01, // IHDR chunk
      0x00, 0x00, 0x00, 0x01, // Width: 1 pixel
      0x00, 0x00, 0x00, 0x01, // Height: 1 pixel
      0x08, 0x02, 0x00, 0x00, 0x00, // Bit depth, color type, etc.
      0x00, 0x00, 0x00, 0x00, // CRC
      0x00, 0x00, 0x00, 0x00, // IDAT chunk (empty)
      0x00, 0x00, 0x00, 0x00, // IEND chunk
    ]);
  }

  // Helper function to create a memo PROGRAMMATICALLY and return it
  Future<Memo?> createMemoProgrammatically(
    WidgetTester tester,
    String content,
  ) async {
    debugPrint(
      '[Test Setup] Attempting to create memo programmatically: "$content"',
    );
    try {
      final apiService = ApiService();
      final newMemo = Memo(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        visibility: 'PUBLIC',
      );
      final createdMemo = await apiService.createMemo(newMemo);
      debugPrint(
        '[Test Setup] Programmatic memo creation successful. ID: ${createdMemo.id}',
      );
      createdMemoIds.add(createdMemo.id); // Store ID for cleanup
      return createdMemo;
    } catch (e, stackTrace) {
      debugPrint(
        '[Test Setup] Error creating memo programmatically: $e\n$stackTrace',
      );
      fail('Failed to create memo programmatically: $e');
    }
  }

  group('Memo Comment Integration Tests', () {
    // Cleanup after all tests in the group
    tearDownAll(() async {
      if (createdMemoIds.isNotEmpty) {
        debugPrint(
          '[Test Cleanup] Deleting ${createdMemoIds.length} test memos...',
        );
        final apiService = ApiService();
        try {
          await Future.wait(
            createdMemoIds.map((id) => apiService.deleteMemo(id)),
          );
          debugPrint('[Test Cleanup] Successfully deleted test memos.');
        } catch (e) {
          debugPrint('[Test Cleanup] Error deleting test memos: $e');
        }
        createdMemoIds.clear();
      }
    });

    testWidgets('Create a memo, add a comment with attachment attempt, and verify', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // STEP 1: Create a new memo first (Programmatically)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testMemoContent = 'Test Memo Attachments - $timestamp';
      final createdMemo = await createMemoProgrammatically(
        tester,
        testMemoContent,
      );
      expect(createdMemo, isNotNull, reason: 'Failed to create test memo');

      // Refresh the list to show the newly created memo
      debugPrint('[Test Action] Simulating pull-to-refresh...');
      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget, reason: 'ListView not found');
      await tester.fling(listFinder, const Offset(0.0, 400.0), 1000.0);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      debugPrint('[Test Action] Pull-to-refresh complete.');

      // Find our specific memo card by its content
      final memoCardFinder = find.widgetWithText(MemoCard, testMemoContent);
      expect(
        memoCardFinder,
        findsOneWidget,
        reason: 'Created memo card not found in list',
      );

      // STEP 2: Navigate to memo detail screen
      await tester.tap(memoCardFinder);
      await tester.pumpAndSettle();

      // Verify we're on the detail screen
      expect(find.text('Memo Detail'), findsOneWidget, reason: 'Not on memo detail screen');

      // STEP 3: Add a comment with an attachment attempt
      final commentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final testCommentText = 'Test Comment Attach - $commentTimestamp';

      // Find the comment capture utility
      final commentCaptureUtility = find.byType(CaptureUtility);
      expect(commentCaptureUtility, findsOneWidget, reason: 'Comment CaptureUtility not found');

      // Tap on the placeholder text to expand the CaptureUtility
      await tester.tap(find.text('Add a comment...'));
      await tester.pumpAndSettle(); // Wait for expansion animation

      // Find the TextField within the expanded CaptureUtility
      final commentTextFieldFinder = find.descendant(
        of: commentCaptureUtility,
        matching: find.byType(TextField),
      );
      expect(
        commentTextFieldFinder,
        findsOneWidget,
        reason: 'Comment TextField not found in CaptureUtility',
      );

      // Type the comment text
      await tester.enterText(commentTextFieldFinder, testCommentText);
      await tester.pumpAndSettle();

      // Find and tap the "Attach file" button
      final attachButtonFinder = find.descendant(
        of: commentCaptureUtility,
        matching: find.byIcon(Icons.attach_file),
      );
      expect(
        attachButtonFinder,
        findsOneWidget,
        reason: 'Attach file button not found',
      );

      // Instead of tapping the attach button, which would launch the native picker,
      // use a more direct approach to set file data programmatically
      final testFileData = createTestFileData();
      final testFilename =
          'test_image_${DateTime.now().millisecondsSinceEpoch}.png';

      // Find the CaptureUtility state
      final captureUtilityWidget = find.byType(CaptureUtility);
      expect(
        captureUtilityWidget,
        findsOneWidget,
        reason: 'CaptureUtility widget not found',
      );

      // Get the state directly
      final captureUtilityState =
          tester.state(captureUtilityWidget) as CaptureUtilityState;

      // Set file data directly using the state
      captureUtilityState.setFileDataForTest(
        testFileData,
        testFilename,
        'image/png',
      );

      // Wait for UI to update with the file
      await tester.pumpAndSettle();

      debugPrint(
        '[Test Action] Programmatically set test file: $testFilename',
      );

      // Find and tap the "Send" button (assuming it's an Icon button now)
      final sendButtonFinder = find.descendant(
        of: commentCaptureUtility,
        matching: find.byIcon(
          Icons.send_rounded,
        ), // Updated to find the send icon
      );
      expect(sendButtonFinder, findsOneWidget, reason: 'Send button not found');
      await tester.tap(sendButtonFinder);
      await tester.pumpAndSettle(); // Wait for submission and UI update

      // Wait a bit longer for potential network activity and UI refresh
      await tester.pump(const Duration(seconds: 3));

      // STEP 4: Verify the comment appears
      // Scroll down to ensure the comment list is visible if needed
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0.0, -300),
      );
      await tester.pumpAndSettle();

      // Find the comment text in the UI
      final commentTextFinder = find.text(testCommentText);
      expect(
        commentTextFinder,
        findsOneWidget,
        reason: 'Added comment text not found',
      );

      // **Optional Verification:** Check if the CommentCard shows an attachment indicator.
      // This depends on how CommentCard is implemented.
      final commentCardFinder = find.ancestor(
        of: commentTextFinder,
        matching: find.byType(CommentCard),
      );
      expect(
        commentCardFinder,
        findsOneWidget,
        reason: 'CommentCard not found for the comment',
      );

      // Example: Check for an image widget within the comment card
      // final attachmentImageFinder = find.descendant(
      //   of: commentCardFinder,
      //   matching: find.byType(Image), // Or a specific icon/widget indicating attachment
      // );
      // expect(attachmentImageFinder, findsOneWidget, reason: 'Attachment indicator not found in CommentCard');
      // Note: This part needs adjustment based on your actual CommentCard implementation for attachments.

      // Verify the success snackbar (optional)
      // final commentSnackbarFinder = find.text('Comment added successfully');
      // expect(commentSnackbarFinder, findsOneWidget, reason: 'Success snackbar not found');
      // await tester.pumpAndSettle(); // Ensure snackbar is gone

      // STEP 5: Go back to the main screen
      final backButtonFinder = find.byType(BackButton);
      expect(backButtonFinder, findsOneWidget, reason: 'Back button not found');
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle(
        const Duration(seconds: 2),
      ); // Give more time for navigation

      // Look for either the app title or other main screen indicators
      final isOnMainScreen =
          find.text('Memos').evaluate().isNotEmpty ||
          find.text('Flutter Memos').evaluate().isNotEmpty ||
          find.byType(app.HomeScreen).evaluate().isNotEmpty;

      expect(
        isOnMainScreen,
        isTrue,
        reason: 'Did not navigate back to main screen',
      );

      debugPrint(
        'Comment creation with programmatic attachment test completed successfully',
      );
    });
  });
}