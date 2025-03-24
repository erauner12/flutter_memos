// Import required packages
import 'package:flutter/material.dart'; // Add missing import for Icons and TextField
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  // Initialize integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MemoCard Context Menu Integration Tests', () {
    // Fix testWidgets function parameter format
    testWidgets('Open context menu and verify Archive action', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Create a new memo via the UI
      final fabFinder = find.byIcon(Icons.add);
      expect(fabFinder, findsOneWidget, reason: 'FAB not found');
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget, reason: 'New memo text field not found');
      await tester.enterText(textFieldFinder, 'Integration Test Memo');
      await tester.pumpAndSettle();

      // Tap the "Save" button
      final saveButtonFinder = find.text('Save');
      expect(saveButtonFinder, findsOneWidget, reason: 'Save button not found');
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      // Find the MemoCard widget
      final memoCardFinder = find.byType(MemoCard);
      expect(memoCardFinder, findsWidgets);
      
      // Get the initial number of memo cards for later comparison
      final initialMemoCount = memoCardFinder.evaluate().length;
      print('Initial memo card count: $initialMemoCount');

      // Open context menu
      await tester.longPress(memoCardFinder.first);
      await tester.pumpAndSettle();

      // Verify context menu is shown
      expect(find.text('Archive'), findsOneWidget);
      print('Found context menu with Archive option');

      // Tap the Archive option
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      
      // Wait for the archive operation to complete and UI to update
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Count memo cards after archiving
      final finalMemoCount = find.byType(MemoCard).evaluate().length;
      print('Final memo card count: $finalMemoCount');
      
      // Verify the memo was archived by checking that the count decreased
      expect(
        finalMemoCount,
        lessThan(initialMemoCount),
        reason: 'Memo count should decrease after archiving a memo',
      );
    }); // Fix missing parenthesis
  });
}
