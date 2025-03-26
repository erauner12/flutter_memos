import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  // Initialize integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Memo Comment Integration Tests', () {
    testWidgets('Create a memo, add a comment, and verify it appears', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // STEP 1: Create a new memo first
      
      // Find and tap the CaptureUtility to expand it
      final captureUtilityFinder = find.byType(CaptureUtility);
      expect(captureUtilityFinder, findsOneWidget, reason: 'CaptureUtility not found');
      
      // Tap on the placeholder text to expand
      await tester.tap(find.text('Capture something ...'));
      await tester.pumpAndSettle();

      // Enter text in the memo content field
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testMemoContent = 'Test Memo for Comments - $timestamp';
      
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsAtLeastNWidgets(1), reason: 'TextField not found after expanding CaptureUtility');
      await tester.enterText(textFieldFinder.first, testMemoContent);
      await tester.pumpAndSettle();

      // Tap the "Add Memo" button
      final addMemoButtonFinder = find.text('Add Memo');
      expect(addMemoButtonFinder, findsOneWidget, reason: 'Add Memo button not found');
      await tester.tap(addMemoButtonFinder);
      await tester.pumpAndSettle();

      // Wait for memo creation to complete
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Find our specific memo by its content
      final memoTextFinder = find.text(testMemoContent);
      expect(memoTextFinder, findsWidgets, reason: 'Newly created memo not found');

      // Find the MemoCard containing our test content
      final memoCardFinder = find.ancestor(
        of: memoTextFinder.first,
        matching: find.byType(MemoCard),
      );
      expect(memoCardFinder, findsOneWidget, reason: 'MemoCard not found');

      // STEP 2: Navigate to memo detail screen
      
      // Tap on the memo to go to detail screen
      await tester.tap(memoCardFinder);
      await tester.pumpAndSettle();

      // Verify we're on the detail screen
      expect(find.text('Memo Detail'), findsOneWidget, reason: 'Not on memo detail screen');
      
      // STEP 3: Add a comment
      
      // Generate unique comment text
      final commentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final testCommentText = 'Test Comment - $commentTimestamp';
      
      // Find the comment capture utility
      final commentCaptureUtility = find.byType(CaptureUtility);
      expect(commentCaptureUtility, findsOneWidget, reason: 'Comment CaptureUtility not found');
      
      // Tap on the placeholder text to expand
      await tester.tap(find.text('Add a comment...'));
      await tester.pumpAndSettle();
      
      // Type the comment text
      final commentTextFieldFinder = find.byType(TextField);
      expect(commentTextFieldFinder, findsAtLeastNWidgets(1), reason: 'Comment TextField not found');
      await tester.enterText(commentTextFieldFinder.first, testCommentText);
      await tester.pumpAndSettle();
      
      // Tap the "Add Comment" button
      final addCommentButtonFinder = find.text('Add Comment');
      expect(addCommentButtonFinder, findsOneWidget, reason: 'Add Comment button not found');
      await tester.tap(addCommentButtonFinder);
      await tester.pumpAndSettle();
      
      // Wait for comment to be added
      await tester.pump(const Duration(seconds: 1));
      
      // STEP 4: Verify the comment appears
      
      // Find the comment text in the UI
      final commentTextFinder = find.text(testCommentText);
      expect(commentTextFinder, findsOneWidget, reason: 'Added comment not found');
      
      // Verify the success snackbar (optional)
      final commentSnackbarFinder = find.text('Comment added successfully');
      if (commentSnackbarFinder.evaluate().isNotEmpty) {
        debugPrint('Found comment added confirmation snackbar');
      }
      
      // STEP 5: Go back to the main screen
      
      // Find and tap the back button
      final backButtonFinder = find.byType(BackButton);
      expect(backButtonFinder, findsOneWidget, reason: 'Back button not found');
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();
      
      // Verify we're back on the main screen
      expect(find.text('Memos'), findsOneWidget, reason: 'Not back on main screen');
      
      debugPrint('Comment creation test completed successfully');
    });
  });
}
