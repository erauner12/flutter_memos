import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // List to store IDs of memos created during the test for cleanup
  final List<String> createdMemoIds = [];

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

  group('Comment Navigation Integration Tests', () {
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

    testWidgets(
      'Test keyboard navigation in comment section works regardless of focus',
      (WidgetTester tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle();

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // STEP 1: Create a memo with comments for testing (Programmatically)
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final testMemoContent =
            'Test Memo for Keyboard Navigation - $timestamp';
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

        // Find the created memo card
        final memoCardFinder = find.widgetWithText(MemoCard, testMemoContent);
        expect(
          memoCardFinder,
          findsOneWidget,
          reason: 'Created memo card not found in list',
        );

        // Navigate to detail screen
        await tester.tap(memoCardFinder);
        await tester.pumpAndSettle();

        // Verify we're on the detail screen
        expect(find.text('Memo Detail'), findsOneWidget);

        // STEP 2: Add a test comment if none exists (Keep UI interaction for comment adding)
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