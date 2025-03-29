import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('Memos Filter Integration Tests', () {
    // Helper function to create a memo PROGRAMMATICALLY
    Future<void> createMemo(WidgetTester tester, String content) async {
      debugPrint('Attempting to create memo programmatically: "$content"');
      try {
        // Instantiate the ApiService directly
        final apiService = ApiService();

        // Create a Memo object
        // NOTE: Adjust visibility, parent, etc. if needed based on your API requirements
        final newMemo = Memo(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}', // Temporary ID, API will assign real one
          content: content,
          visibility: 'PUBLIC', // Or appropriate default
          // parent: 'users/1', // Often required by the API
        );

        // Call the API service to create the memo
        // Pass only the memo object as the createMemo method expects just one argument
        await apiService.createMemo(newMemo);

        debugPrint('Programmatic memo creation successful for: "$content"');

        // IMPORTANT: Pump and settle AFTER the API call to allow the memo list
        // provider (memosProvider) to refresh and the UI to update.
        await tester.pumpAndSettle(const Duration(seconds: 2)); // Allow ample time for refresh

      } catch (e, stackTrace) {
        debugPrint('Error creating memo programmatically: $e\n$stackTrace');
        // Fail the test explicitly if setup fails
        fail('Failed to create memo programmatically: $e');
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
      // Use more distinct content for programmatic creation
      const taggedMemoContent = 'Tagged Filter Test Memo #testtag';
      const untaggedMemoContent = 'Untagged Filter Test Memo';

      // Create memos PROGRAMMATICALLY
      await createMemo(tester, taggedMemoContent);
      await createMemo(tester, untaggedMemoContent);

      // Finders for the memos (use more specific text now)
      final taggedMemoFinder = find.textContaining('Tagged Filter Test Memo #testtag');
      final untaggedMemoFinder = find.textContaining('Untagged Filter Test Memo');

      // --- Start Filter Testing ---
      // Explicitly set to 'All Status' first for a clean start.
      await selectFilterOption(tester, 'Filter by Status', 'All Status');
      expect(taggedMemoFinder, findsOneWidget, reason: 'Tagged memo should be visible with "All Status" filter');
      expect(untaggedMemoFinder, findsOneWidget, reason: 'Untagged memo should be visible with "All Status" filter');


      // --- Test Untagged Filter ---
      await selectFilterOption(tester, 'Filter by Status', 'Untagged');
      expect(taggedMemoFinder, findsNothing, reason: 'Tagged memo should NOT be visible with "Untagged" filter');
      expect(untaggedMemoFinder, findsOneWidget, reason: 'Untagged memo should be visible with "Untagged" filter');


      // --- Test Tagged Filter ---
      await selectFilterOption(tester, 'Filter by Status', 'Tagged');
      expect(taggedMemoFinder, findsOneWidget, reason: 'Tagged memo should be visible with "Tagged" filter');
      expect(untaggedMemoFinder, findsNothing, reason: 'Untagged memo should NOT be visible with "Tagged" filter');


      // --- Test All Status Filter ---
      await selectFilterOption(tester, 'Filter by Status', 'All Status');
      expect(taggedMemoFinder, findsOneWidget, reason: 'Tagged memo should be visible again with "All Status" filter');
      expect(untaggedMemoFinder, findsOneWidget, reason: 'Untagged memo should be visible again with "All Status" filter');

      // --- Test Time Filter (Basic Interaction) ---
      await selectFilterOption(tester, 'Filter by Time Range', 'Today');
      debugPrint('Time filter selection test passed.');

      await selectFilterOption(tester, 'Filter by Time Range', 'All Time');
      debugPrint('Resetting Time filter to All Time.');

    });
  });
}
