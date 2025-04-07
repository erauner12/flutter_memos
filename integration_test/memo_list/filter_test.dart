import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('Memos Filter Integration Tests', () {
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
        return null;
      }
    }

    // Helper function to interact with PopupMenuButton (no changes needed here)
    Future<void> selectFilterOption(
      WidgetTester tester,
      String buttonTooltip,
      String optionText,
    ) async {
      // Find the button by tooltip
      final filterButtonFinder = find.byTooltip(buttonTooltip);
      expect(filterButtonFinder, findsOneWidget, reason: '$buttonTooltip button not found');
      await tester.tap(filterButtonFinder);
      await tester.pumpAndSettle(); // Wait for menu animation

      // Find the option by text within the menu
      final optionFinder = find.text(optionText).last; // Use last in case text appears elsewhere
      expect(optionFinder, findsOneWidget, reason: '$optionText option not found in menu');
      await tester.tap(optionFinder);
      await tester.pumpAndSettle(); // Wait for filter application
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

      // Create memos PROGRAMMATICALLY and store them (optional, IDs are stored in createMemo)
      await createMemo(tester, taggedMemoContent);
      await createMemo(tester, untaggedMemoContent);

      // --- Explicit Refresh ---
      // Find the ListView associated with the RefreshIndicator
      final listFinder = find.byType(ListView);
      expect(
        listFinder,
        findsOneWidget,
        reason: 'ListView should be present to refresh',
      );

      // Simulate the pull-to-refresh gesture
      debugPrint(
        '[Test Action] Simulating pull-to-refresh to load created memos...',
      );
      await tester.fling(listFinder, const Offset(0.0, 400.0), 1000.0);
      // Wait for the refresh indicator and data loading
      await tester.pumpAndSettle(
        const Duration(seconds: 3),
      ); // Allow time for API call + UI update
      debugPrint('[Test Action] Pull-to-refresh simulation complete.');
      // --- End Explicit Refresh ---


// Finders for the memos: Use byWidgetPredicate for precise targeting
      Finder findCardWithText(String text) {
        return find.byWidgetPredicate(
          (Widget widget) =>
              widget is Card && // Check if the widget is a Card
              find // Check if this Card has a descendant Text/RichText with the specific content
                  .descendant(
                    of: find.byWidget(
                      widget,
                    ), // Search within this specific Card widget
                    matching: find.textContaining(text, findRichText: true),
                  )
                  .evaluate() // Check if the descendant finder finds anything
                  .isNotEmpty,
          description:
              'Card containing text "$text"', // Description for debugging
        );
}

final taggedMemoCardFinder = findCardWithText(taggedMemoContent);
      final untaggedMemoCardFinder = findCardWithText(untaggedMemoContent);


// --- Start Filter Testing ---
      // Explicitly set to 'All Status' first for a clean start.
      await selectFilterOption(tester, 'Filter by Status', 'All Status');
      // Assert based on the Card finder now
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
      // Assert based on the Card finder now
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
      // Assert based on the Card finder now
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
      // Assert based on the Card finder now
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