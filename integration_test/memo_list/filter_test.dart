import 'package:flutter/cupertino.dart'; // Use Cupertino
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/widgets/memo_card.dart'; // Import MemoCard widget
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('Memos Filter Integration Tests (Cupertino)', () {
    // List to store IDs of memos created during the test for cleanup
    final List<String> createdMemoIds = [];

    // Helper function to create a memo PROGRAMMATICALLY and return it
    Future<Memo?> createMemo(WidgetTester tester, String content) async {
      debugPrint('Attempting to create memo programmatically: "$content"');
      try {
        // Instantiate the ApiService directly
        final apiService = ApiService();

        // Create a Memo object
        final newMemo = Memo(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
          content: content,
          visibility: 'PUBLIC', // Or appropriate default
        );

        // Call the API service to create the memo and get the result
        final createdMemo = await apiService.createMemo(newMemo);

        debugPrint(
          'Programmatic memo creation successful for: "$content" with ID: ${createdMemo.id}',
        );

        // Store the ID for cleanup
        createdMemoIds.add(createdMemo.id);

        return createdMemo;

      } catch (e, stackTrace) {
        debugPrint('Error creating memo programmatically: $e\n$stackTrace');
        // Fail the test explicitly if setup fails
        fail('Failed to create memo programmatically: $e');
        // Return null or rethrow, depending on desired error handling
      }
    }

    // Helper function to interact with Filter Button and CupertinoActionSheet
    Future<void> selectFilterOption(
      WidgetTester tester,
      String buttonTooltip, // Tooltip might still be used on CupertinoButton
      String optionText,
    ) async {
      // Find the filter button (assuming CupertinoButton with Tooltip or Icon)
      final filterButtonFinder = find.byTooltip(buttonTooltip);
      // Alternative: find.widgetWithIcon(CupertinoButton, ...)
      expect(filterButtonFinder, findsOneWidget, reason: '$buttonTooltip button not found');
      await tester.tap(filterButtonFinder);
      await tester.pumpAndSettle(); // Wait for action sheet animation

      // Find the CupertinoActionSheet
      final actionSheetFinder = find.byType(CupertinoActionSheet);
      expect(
        actionSheetFinder,
        findsOneWidget,
        reason: 'CupertinoActionSheet not found for filter',
      );

      // Find the specific action by text within the action sheet
      final optionFinder = find.descendant(
        of: actionSheetFinder,
        matching: find.widgetWithText(CupertinoActionSheetAction, optionText),
      );
      expect(
        optionFinder,
        findsOneWidget,
        reason: '$optionText option not found in action sheet',
      );

      // Tap the action
      await tester.tap(optionFinder);
      await tester
          .pumpAndSettle(); // Wait for sheet dismissal and filter application
      await tester.pump(const Duration(milliseconds: 500)); // Extra wait for list refresh
    }

    testWidgets('Test Status Filter Dropdown', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2)); // Wait for initial load

      // --- Test Setup ---
      // Generate unique content using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final taggedMemoContent = 'Tagged Filter Test Memo #testtag $timestamp';
      final untaggedMemoContent = 'Untagged Filter Test Memo $timestamp';

      // Create memos PROGRAMMATICALLY
      await createMemo(tester, taggedMemoContent);
      await createMemo(tester, untaggedMemoContent);

      // --- Explicit Refresh ---
      // Find the Scrollable list
      final listFinder = find.byType(Scrollable).first;
      expect(
        listFinder,
        findsOneWidget,
        reason: 'Scrollable list should be present to refresh',
      );

      // Simulate the pull-to-refresh gesture
      debugPrint(
        '[Test Action] Simulating pull-to-refresh to load created memos...',
      );
      await tester.fling(listFinder, const Offset(0.0, 400.0), 1000.0);
      await tester.pumpAndSettle(
        const Duration(seconds: 3),
      ); // Allow time for API call + UI update
      debugPrint('[Test Action] Pull-to-refresh simulation complete.');
      // --- End Explicit Refresh ---


      // Finders for the memos: Use byWidgetPredicate for precise targeting
      // Update predicate to find MemoCard containing the text, not Material Card
      Finder findMemoCardWithText(String text) {
        return find.byWidgetPredicate(
          (Widget widget) =>
              widget is MemoCard && // Check if the widget is a MemoCard
              find // Check if this MemoCard has a descendant Text/RichText with the specific content
                  .descendant(
                    of: find.byWidget(
                      widget,
                    ), // Search within this specific MemoCard widget
                    matching: find.textContaining(text, findRichText: true),
                  )
                  .evaluate() // Check if the descendant finder finds anything
                  .isNotEmpty,
          description:
              'MemoCard containing text "$text"', // Description for debugging
        );
      }

      final taggedMemoCardFinder = findMemoCardWithText(taggedMemoContent);
      final untaggedMemoCardFinder = findMemoCardWithText(untaggedMemoContent);


      // --- Start Filter Testing ---
      // Explicitly set to 'All Status' first for a clean start.
      await selectFilterOption(tester, 'Filter by Status', 'All Status');
      // Assert based on the MemoCard finder now
      expect(
        taggedMemoCardFinder,
        findsOneWidget,
        reason: 'Tagged memo card should be visible with "All Status" filter',
      );
      expect(
        untaggedMemoCardFinder,
        findsOneWidget,
        reason: 'Untagged memo card should be visible with "All Status" filter',
      );


      // --- Test Untagged Filter ---
      await selectFilterOption(tester, 'Filter by Status', 'Untagged');
      // Assert based on the MemoCard finder now
      expect(
        taggedMemoCardFinder,
        findsNothing,
        reason: 'Tagged memo card should NOT be visible with "Untagged" filter',
      );
      expect(
        untaggedMemoCardFinder,
        findsOneWidget,
        reason: 'Untagged memo card should be visible with "Untagged" filter',
      );


      // --- Test Tagged Filter ---
      await selectFilterOption(tester, 'Filter by Status', 'Tagged');
      // Assert based on the MemoCard finder now
      expect(
        taggedMemoCardFinder,
        findsOneWidget,
        reason: 'Tagged memo card should be visible with "Tagged" filter',
      );
      expect(
        untaggedMemoCardFinder,
        findsNothing,
        reason: 'Untagged memo card should NOT be visible with "Tagged" filter',
      );


      // --- Test All Status Filter ---
      await selectFilterOption(tester, 'Filter by Status', 'All Status');
      // Assert based on the MemoCard finder now
      expect(
        taggedMemoCardFinder,
        findsOneWidget,
        reason:
            'Tagged memo card should be visible again with "All Status" filter',
      );
      expect(
        untaggedMemoCardFinder,
        findsOneWidget,
        reason:
            'Untagged memo card should be visible again with "All Status" filter',
      );

      // --- Test Time Filter (Basic Interaction) ---
      await selectFilterOption(tester, 'Filter by Time Range', 'Today');
      debugPrint('Time filter selection test passed.');

      await selectFilterOption(tester, 'Filter by Time Range', 'All Time');
      debugPrint('Resetting Time filter to All Time.');

    });

    // Cleanup after all tests in the group
    tearDownAll(() async {
      if (createdMemoIds.isNotEmpty) {
        debugPrint(
          '[Test Cleanup] Deleting ${createdMemoIds.length} test memos...',
        );
        final apiService = ApiService();
        try {
          // Delete memos in parallel
          await Future.wait(
            createdMemoIds.map((id) => apiService.deleteMemo(id)),
          );
          debugPrint('[Test Cleanup] Successfully deleted test memos.');
        } catch (e) {
          debugPrint('[Test Cleanup] Error deleting test memos: $e');
          // Don't fail the test for cleanup errors, but log them.
        }
        createdMemoIds.clear(); // Clear the list after attempting deletion
      } else {
        debugPrint('[Test Cleanup] No test memos to delete.');
      }
    });
  });
}
