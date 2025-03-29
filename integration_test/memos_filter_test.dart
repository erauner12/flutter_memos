import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Memos Filter Integration Tests', () {
    // Helper function to create a memo
    Future<void> createMemo(WidgetTester tester, String content) async {
      final captureUtilityFinder = find.byType(CaptureUtility);
      expect(captureUtilityFinder, findsOneWidget);

      // Tap placeholder if collapsed
      final placeholderFinder = find.text('Capture something ...');
      if (placeholderFinder.evaluate().isNotEmpty) {
        await tester.tap(placeholderFinder);
        await tester.pumpAndSettle();
      }

      // Enter text
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsAtLeastNWidgets(1));
      await tester.enterText(textFieldFinder.first, content);
      await tester.pumpAndSettle();

      // Tap Add Memo
      final addButtonFinder = find.text('Add Memo');
      expect(addButtonFinder, findsOneWidget);
      await tester.tap(addButtonFinder);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1)); // Wait for creation
    }

    // Helper function to interact with PopupMenuButton
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
      const taggedMemoContent = 'This memo has a #testtag';
      const untaggedMemoContent = 'This memo is untagged';

      // Create memos
      await createMemo(tester, taggedMemoContent);
      await createMemo(tester, untaggedMemoContent);

      // Finders for the memos
      final taggedMemoFinder = find.textContaining('#testtag');
      final untaggedMemoFinder = find.textContaining('untagged');

      // Verify both memos are initially visible (assuming default is 'All' or similar)
      // Note: Default filter might be 'Untagged', adjust initial check if needed.
      // Let's explicitly set to 'All Status' first for a clean start.
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
      // Just ensure we can open and select an option without crashing
      await selectFilterOption(tester, 'Filter by Time Range', 'Today');
      // Add verification if specific time-based memos were created
      debugPrint('Time filter selection test passed.');

      await selectFilterOption(tester, 'Filter by Time Range', 'All Time');
      debugPrint('Resetting Time filter to All Time.');

    });
  });
}
