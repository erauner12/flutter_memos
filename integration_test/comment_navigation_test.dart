import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Comment Navigation Integration Tests', () {
    testWidgets(
      'Test keyboard navigation in comment section works regardless of focus',
      (WidgetTester tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle();
        
        // Wait for app to be fully loaded
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // STEP 1: Create a memo with comments for testing
        
        // Find and tap the CaptureUtility to expand it
        final captureUtilityFinder = find.byType(CaptureUtility);
        if (captureUtilityFinder.evaluate().isNotEmpty) {
          // Tap on the placeholder text to expand
          await tester.tap(find.text('Capture something ...'));
          await tester.pumpAndSettle();

          // Enter text in the memo content field
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final testMemoContent = 'Test Memo for Keyboard Navigation - $timestamp';
          
          final textFieldFinder = find.byType(TextField);
          expect(textFieldFinder, findsAtLeastNWidgets(1), reason: 'TextField not found after expanding CaptureUtility');
          await tester.enterText(textFieldFinder.first, testMemoContent);
          await tester.pumpAndSettle();

          // Tap the "Add Memo" button
          final addMemoButtonFinder = find.text('Add Memo');
          if (addMemoButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(addMemoButtonFinder);
            await tester.pumpAndSettle();
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        // Find a memo to work with
        final memoCards = find.byType(MemoCard);
        expect(memoCards, findsWidgets, reason: 'Should find memo cards');
        
        // Navigate to detail screen
        await tester.tap(memoCards.first);
        await tester.pumpAndSettle();
        
        // Verify we're on the detail screen
        expect(find.text('Memo Detail'), findsOneWidget);
        
        // STEP 2: Add a test comment if none exists
        
        final existingComments = find.byType(CommentCard);
        if (existingComments.evaluate().isEmpty) {
          // Find the comment capture utility
          final commentCaptureUtility = find.byType(CaptureUtility);
          if (commentCaptureUtility.evaluate().isNotEmpty) {
            // Tap on the placeholder text to expand
            await tester.tap(find.textContaining('Add a comment'));
            await tester.pumpAndSettle();
            
            // Type the comment text
            final commentTextFieldFinder = find.byType(TextField);
            if (commentTextFieldFinder.evaluate().isNotEmpty) {
              await tester.enterText(commentTextFieldFinder.first, 'Test comment for keyboard navigation');
              await tester.pumpAndSettle();
              
              // Tap the "Add Comment" button
              final addCommentButtonFinder = find.text('Add Comment');
              if (addCommentButtonFinder.evaluate().isNotEmpty) {
                await tester.tap(addCommentButtonFinder);
                await tester.pumpAndSettle();
                await Future.delayed(const Duration(seconds: 1));
              }
            }
          }
        }
        
        // STEP 3: Test keyboard navigation while screen has focus
        
        // Tap somewhere on the screen to give it focus
        await tester.tap(find.text('Comments'));
        await tester.pumpAndSettle();
        
        // Try keyboard navigation with Shift+Arrow keys
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();
        
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();
        
        // STEP 4: Test keyboard navigation after focusing on different UI elements
        
        // 1. Try after focusing on a comment
        final commentCards = find.byType(CommentCard);
        if (commentCards.evaluate().isNotEmpty) {
          await tester.tap(commentCards.first);
          await tester.pumpAndSettle();
          
          // Try navigation after tapping a comment
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
          await tester.pumpAndSettle();
        }
        
        // 2. Try after focusing on the comment input
        final commentTextBox = find.textContaining('Add a comment');
        if (commentTextBox.evaluate().isNotEmpty) {
          await tester.tap(commentTextBox);
          await tester.pumpAndSettle();
          
          // Try to navigate while text input has focus (should be ignored)
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
          await tester.pumpAndSettle();
          
          // Tap outside to unfocus
          await tester.tap(find.text('Comments'));
          await tester.pumpAndSettle();
        }
        
        // STEP 5: Go back to main screen
        await tester.pageBack();
        await tester.pumpAndSettle();
        
        // Verify we're back on the main screen
        final isOnMainScreen = find.text('Flutter Memos').evaluate().isNotEmpty ||
                               find.text('Memos').evaluate().isNotEmpty;
        expect(isOnMainScreen, isTrue, reason: 'Should be back on main screen');
      },
    );
  });
}
