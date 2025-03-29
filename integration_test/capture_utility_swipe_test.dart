import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for LogicalKeyboardKey
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// --- Helper Functions ---

// Gets the initial height of the CaptureUtility
double _getInitialHeight(WidgetTester tester) {
  final captureUtilityFinder = find.byType(CaptureUtility);
  expect(
    captureUtilityFinder,
    findsOneWidget,
    reason: 'CaptureUtility not found',
  );
  return tester.getSize(captureUtilityFinder).height;
}

// Verifies the CaptureUtility is in a collapsed state
Future<void> _verifyCollapsed(WidgetTester tester, double initialHeight) async {
  final captureUtilityFinder = find.byType(CaptureUtility);
  final collapsedHeight = tester.getSize(captureUtilityFinder).height;
  debugPrint(
    'Verifying collapsed: Current height = $collapsedHeight, Initial height = $initialHeight',
  );
  // Allow for slight variations due to physics settling
  expect(
    (collapsedHeight - initialHeight).abs() < 15,
    isTrue,
    reason:
        'CaptureUtility should be collapsed (Height: $collapsedHeight, Expected near: $initialHeight)',
  );
  // Check that the TextField is not visible when collapsed
  expect(
    find.descendant(of: captureUtilityFinder, matching: find.byType(TextField)),
    findsNothing,
    reason: 'TextField should not be visible when collapsed',
  );
}

// Verifies the CaptureUtility is in an expanded state
Future<void> _verifyExpanded(WidgetTester tester, double initialHeight) async {
  final captureUtilityFinder = find.byType(CaptureUtility);
  final expandedHeight = tester.getSize(captureUtilityFinder).height;
  debugPrint(
    'Verifying expanded: Current height = $expandedHeight, Initial height = $initialHeight',
  );
  expect(
    expandedHeight,
    greaterThan(
      initialHeight + 50,
    ), // Expect significantly larger than initial height
    reason:
        'CaptureUtility should be expanded (Height: $expandedHeight, Expected > ${initialHeight + 50})',
  );
  // Check that the TextField is visible when expanded
  expect(
    find.descendant(of: captureUtilityFinder, matching: find.byType(TextField)),
    findsOneWidget,
    reason: 'TextField should be visible when expanded',
  );
}

// --- Test Main ---
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CaptureUtility Interaction Tests', () {
    // Test setup: Launch app before each test
    setUp(() async {
      // Relaunch the app for each test to ensure a clean state
      // Note: This might be slow; consider alternatives if performance is an issue.
      // For now, it guarantees isolation.
      // app.main(); // Assuming app.main() can be called multiple times or reset state
      // await tester.pumpAndSettle(const Duration(seconds: 2)); // Allow time for app init
    });

    testWidgets('Tap to expand and swipe down to collapse', (
      WidgetTester tester,
    ) async {
      // Launch the app (moved inside test for better isolation if setUp is not used)
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Allow init time

      final captureUtilityFinder = find.byType(CaptureUtility);
      final initialHeight = _getInitialHeight(tester);
      await _verifyCollapsed(tester, initialHeight); // Verify initial state

      // Tap to expand
      debugPrint('Tapping to expand...');
      await tester.tap(captureUtilityFinder);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      await _verifyExpanded(tester, initialHeight);

      // Swipe down to collapse
      debugPrint('Swiping down to collapse...');
      await tester.drag(
        captureUtilityFinder,
        const Offset(0, 150),
      ); // Strong downward swipe
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await _verifyCollapsed(tester, initialHeight);
    });

    testWidgets('Pure swipe up and down interaction', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final captureUtilityFinder = find.byType(CaptureUtility);
      final initialHeight = _getInitialHeight(tester);
      await _verifyCollapsed(tester, initialHeight);

      // Swipe up to expand
      debugPrint('Swiping up to expand...');
      await tester.drag(
        captureUtilityFinder,
        const Offset(0, -150),
      ); // Strong upward swipe
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await _verifyExpanded(tester, initialHeight);

      // Swipe down to collapse
      debugPrint('Swiping down to collapse...');
      await tester.drag(
        captureUtilityFinder,
        const Offset(0, 150),
      ); // Strong downward swipe
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await _verifyCollapsed(tester, initialHeight);

      // Swipe up again
      debugPrint('Swiping up again...');
      await tester.drag(captureUtilityFinder, const Offset(0, -150));
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await _verifyExpanded(tester, initialHeight);

      // Swipe down decisively again
      debugPrint('Swiping down decisively again...');
      await tester.drag(
        captureUtilityFinder,
        const Offset(0, 200),
      ); // Even stronger swipe
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await _verifyCollapsed(tester, initialHeight);
    });

    testWidgets('Collapse after submitting memo', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final captureUtilityFinder = find.byType(CaptureUtility);
      final initialHeight = _getInitialHeight(tester);
      await _verifyCollapsed(tester, initialHeight);

      // Tap to expand
      debugPrint('Tapping to expand for submit test...');
      await tester.tap(captureUtilityFinder);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      await _verifyExpanded(tester, initialHeight);

      // Enter text
      final textFieldFinder = find.descendant(
        of: captureUtilityFinder,
        matching: find.byType(TextField),
      );
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, 'Test memo for submit collapse');
      await tester.pumpAndSettle();

      // Tap the "Add Memo" button
      final addButtonFinder = find.widgetWithText(ElevatedButton, 'Add Memo');
      expect(addButtonFinder, findsOneWidget);
      debugPrint('Tapping Add Memo button...');
      await tester.tap(addButtonFinder);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 1500),
      ); // Allow time for submit + collapse animation

      // Verify collapsed
      await _verifyCollapsed(tester, initialHeight);
    });

    testWidgets('Collapse using Escape key', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final captureUtilityFinder = find.byType(CaptureUtility);
      final initialHeight = _getInitialHeight(tester);
      await _verifyCollapsed(tester, initialHeight);

      // Tap to expand
      debugPrint('Tapping to expand for Escape key test...');
      await tester.tap(captureUtilityFinder);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      await _verifyExpanded(tester, initialHeight);

      // Ensure the TextField or the utility itself has focus for the key event
      final textFieldFinder = find.descendant(
        of: captureUtilityFinder,
        matching: find.byType(TextField),
      );
      await tester.tap(textFieldFinder); // Tap text field to ensure focus
      await tester.pumpAndSettle();

      // Send Escape key press
      debugPrint('Sending Escape key...');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 1000),
      ); // Allow time for collapse animation

      // Verify collapsed
      await _verifyCollapsed(tester, initialHeight);
    });

    // --- Original Tests (Refactored) ---
    // Note: These might be redundant now with the more specific tests above,
    // but kept for reference or if slightly different scenarios are intended.
    // Consider removing or merging them if the new tests cover everything.

    /* // Kept for reference, potentially merge/remove
    testWidgets('Original: Swipe up to expand and down to collapse', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final captureUtilityFinder = find.byType(CaptureUtility);
      final initialHeight = _getInitialHeight(tester);
      await _verifyCollapsed(tester, initialHeight);

      await tester.drag(captureUtilityFinder, const Offset(0, -150));
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await _verifyExpanded(tester, initialHeight);

      await tester.drag(captureUtilityFinder, const Offset(0, 150));
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await _verifyCollapsed(tester, initialHeight);
    });

    testWidgets('Original: Tap to expand and swipe down to collapse', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final captureUtilityFinder = find.byType(CaptureUtility);
      final initialHeight = _getInitialHeight(tester);
      await _verifyCollapsed(tester, initialHeight);

      await tester.tap(captureUtilityFinder);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      await _verifyExpanded(tester, initialHeight);

      await tester.drag(captureUtilityFinder, const Offset(0, 150));
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await _verifyCollapsed(tester, initialHeight);
    });
    */
  });
}
