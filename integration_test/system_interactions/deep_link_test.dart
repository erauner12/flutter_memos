import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/services.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/models/comment.dart'; // Add Comment model import
import 'package:flutter_memos/models/memo.dart'; // Add Memo model import
import 'package:flutter_memos/screens/memo_detail/memo_detail_screen.dart';
import 'package:flutter_memos/services/api_service.dart'; // Add ApiService import
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final ApiService apiService =
      ApiService(); // Instance for programmatic access
  final List<String> createdMemoIds = []; // Track IDs for cleanup

  setUp(() {
    // Reset clipboard between tests
    Clipboard.setData(const ClipboardData(text: ''));
  });

// Helper function to create a memo programmatically
  Future<Memo> createTestMemo(String content) async {
    debugPrint('[Test Helper] Creating memo: "$content"');
    final newMemo = Memo(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      visibility: 'PUBLIC',
    );
    final createdMemo = await apiService.createMemo(newMemo);
    createdMemoIds.add(createdMemo.id); // Track for cleanup
    debugPrint('[Test Helper] Memo created with ID: ${createdMemo.id}');
    return createdMemo;
  }

  // Helper function to create a comment programmatically
  Future<Comment> createTestComment(String memoId, String content) async {
    debugPrint('[Test Helper] Creating comment for memo $memoId: "$content"');
    final newComment = Comment(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      createTime: DateTime.now().millisecondsSinceEpoch,
    );
    // Use the service directly, assuming it handles parent memo bumping if necessary
    // or adjust if a specific provider call is needed for testing side effects.
    final createdComment = await apiService.createMemoComment(
      memoId,
      newComment,
    );
    debugPrint(
      '[Test Helper] Comment created with ID: ${createdComment.id} for memo $memoId',
    );
    // Comments don't need separate cleanup tracking if parent memo deletion cascades
    return createdComment;
  }

group('Deep Link Integration Tests', () {
    // Cleanup after all tests
    tearDownAll(() async {
      if (createdMemoIds.isNotEmpty) {
        debugPrint(
          '[Test Cleanup] Deleting ${createdMemoIds.length} test memos...',
        );
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

    testWidgets('Can copy a memo link from context menu', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(
        const Duration(seconds: 3),
      ); // Allow time for initial load

      // Find a memo card (assuming MemoCard is still the type, adjust if needed)
      final memoCardFinder = find.byType(MemoCard);
      expect(memoCardFinder, findsWidgets, reason: 'Should find memo cards');

      // Long press to open context menu (assuming CupertinoContextMenu)
      await tester.longPress(memoCardFinder.first);
      await tester.pumpAndSettle(
        const Duration(seconds: 1),
      ); // Wait for CupertinoContextMenu animation

      // Find the "Copy Link" option within the CupertinoContextMenu
      // The text might be inside a CupertinoContextMenuAction
      final copyLinkFinder = find.widgetWithText(
        CupertinoContextMenuAction,
        'Copy Link',
      );
      expect(
        copyLinkFinder,
        findsOneWidget,
        reason: 'Should find Copy Link option in context menu',
      );

      // Ensure the item is visible before tapping
      await tester.ensureVisible(copyLinkFinder);
      await tester.pumpAndSettle();

      // Tap the Copy Link option
      await tester.tap(copyLinkFinder, warnIfMissed: false);
      // Refined pump sequence for menu dismissal and clipboard
      await tester.pump(); // Process tap, start dismiss
      await tester.pump(); // Finish dismiss, start clipboard/alert
      await tester.pump(
        const Duration(milliseconds: 500),
      ); // Allow alert animation to start
      await tester.pumpAndSettle(); // Settle everything

      // Verify confirmation (assuming CupertinoAlertDialog now)
      expect(
        find.widgetWithText(
          CupertinoAlertDialog,
          'Memo link copied to clipboard',
        ),
        findsOneWidget,
        reason: 'Should show confirmation alert',
      );

      // Dismiss the alert
      await tester.tap(find.widgetWithText(CupertinoDialogAction, 'OK'));
      await tester.pumpAndSettle();


      // Get clipboard data
      final clipboardData = await Clipboard.getData('text/plain');
      expect(
        clipboardData?.text,
        matches(RegExp(r'flutter-memos://memo/.*')),
        reason: 'Clipboard should contain a valid memo link',
      );
    });

    testWidgets('Simulated deep link opens correct memo and highlights comment',
        (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // --- Test Setup ---
      // 1. Create Memo Programmatically
      final testMemoContent =
          'Memo for Deep Link Comment Test ${DateTime.now().millisecondsSinceEpoch}';
      final memo = await createTestMemo(testMemoContent);

      // 2. Create Comment Programmatically
      final testCommentContent =
          'Comment to Highlight ${DateTime.now().millisecondsSinceEpoch}';
      final comment = await createTestComment(memo.id, testCommentContent);

      // Refresh UI to ensure data might be visible if needed, though not strictly necessary for deep link simulation
      // await tester.fling(find.byType(ListView), const Offset(0.0, 400.0), 1000.0);
      // await tester.pumpAndSettle(const Duration(seconds: 2));
      // --- End Test Setup ---

      // Find the navigator
      final navigatorState = tester.state<NavigatorState>(
        find.byType(Navigator), // Navigator is still used by CupertinoApp
      );

      // Simulate deep link navigation using the *actual* created IDs
      final deepLinkUrl = 'flutter-memos://comment/${memo.id}/${comment.id}';
      debugPrint('[Test Action] Simulating deep link: $deepLinkUrl');
      navigatorState.pushNamed(
        '/deep-link-target',
        arguments: {'memoId': memo.id, 'commentIdToHighlight': comment.id},
      );

      // Allow time for navigation and potential data loading on the detail screen
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // --- Verification ---
      // 1. Verify we're on MemoDetailScreen
      expect(
        find.byType(MemoDetailScreen),
        findsOneWidget,
        reason: "Should be on MemoDetailScreen after simulated deep link",
      );

      // 2. Verify the correct memo's content is displayed (check for a substring)
      expect(
        find.textContaining(
          testMemoContent.substring(0, 10),
          findRichText: true,
        ),
        findsWidgets, // Might find multiple instances in Markdown
        reason: "Should display content of the correct memo",
      );

      // 3. Verify the specific comment is present
      expect(
        find.text(testCommentContent, findRichText: true),
        findsOneWidget,
        reason: "Target comment content should be visible",
      );

      // 4. Verify the comment card is highlighted (by checking its key)
      // Ensure the CommentCard widget builds its key correctly based on highlight state
      final highlightedCommentCardFinder = find.byKey(
        Key('highlighted-comment-card-${comment.id}'),
        skipOffstage: false, // Check even if potentially offscreen initially
      );
      // Scroll until found or timeout
      await tester.scrollUntilVisible(
        highlightedCommentCardFinder,
        500.0, // Max scroll distance
        maxScrolls: 10,
      );
      expect(
        highlightedCommentCardFinder,
        findsOneWidget,
        reason: "Target comment card should have the highlight key",
      );

      // Optional: Pop screen to clean up navigation stack
      if (navigatorState.canPop()) {
        navigatorState.pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Simulated deep link opens correct memo (no comment highlight)', (
      WidgetTester tester,
    ) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // --- Test Setup ---
      // 1. Create Memo Programmatically
      final testMemoContent =
          'Memo for Deep Link Memo Test ${DateTime.now().millisecondsSinceEpoch}';
      final memo = await createTestMemo(testMemoContent);
      // --- End Test Setup ---

      // Find the navigator
      final navigatorState = tester.state<NavigatorState>(
        find.byType(Navigator),
      );

      // Simulate deep link navigation using the *actual* created memo ID
      final deepLinkUrl = 'flutter-memos://memo/${memo.id}';
      debugPrint('[Test Action] Simulating deep link: $deepLinkUrl');
      navigatorState.pushNamed(
        '/deep-link-target',
        arguments: {
          'memoId': memo.id,
          'commentIdToHighlight': null, // Explicitly null
        },
      );

      // Allow time for navigation and potential data loading
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // --- Verification ---
      // 1. Verify we're on MemoDetailScreen
      expect(
        find.byType(MemoDetailScreen),
        findsOneWidget,
        reason: "Should be on MemoDetailScreen after simulated deep link",
      );

      // 2. Verify the correct memo's content is displayed
      expect(
        find.textContaining(
          testMemoContent.substring(0, 10),
          findRichText: true,
        ),
        findsWidgets,
        reason: "Should display content of the correct memo",
      );

      // 3. Verify NO comment card has the highlight key
      final highlightedCommentCardFinder = find.byKey(
        const Key('highlighted-comment-card-'), // Use a prefix that won't match
        skipOffstage: false,
      );
      expect(
        highlightedCommentCardFinder,
        findsNothing,
        reason: "No comment card should have the highlight key",
      );

      // Optional: Pop screen
      if (navigatorState.canPop()) {
        navigatorState.pop();
        await tester.pumpAndSettle();
      }
    });
  });
}
