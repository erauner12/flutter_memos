import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Check that the TextField is visible and focused when expanded
  final textFieldFinder = find.descendant(
    of: captureUtilityFinder,
    matching: find.byType(TextField),
  );
  expect(
    textFieldFinder,
    findsOneWidget,
    reason: 'TextField should be visible when expanded',
  );
}

// --- Test Main ---
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CaptureUtility Keyboard Shortcut Tests', () {
    testWidgets('Command+Shift+M toggles CaptureUtility expansion state', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Allow init time

      // Get the initial height (collapsed state)
      final captureUtilityFinder = find.byType(CaptureUtility);
      final initialHeight = _getInitialHeight(tester);
      await _verifyCollapsed(tester, initialHeight); // Verify initial state

      // Send Command+Shift+M to toggle expansion
      debugPrint('Sending Command+Shift+M shortcut to expand...');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta); // Command/Ctrl
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);

      // Allow time for animation to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // Verify it expanded
      await _verifyExpanded(tester, initialHeight);

      // Send Command+Shift+M again to toggle back to collapsed
      debugPrint('Sending Command+Shift+M shortcut to collapse...');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta); // Command/Ctrl
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);

      // Allow time for animation to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // Verify it collapsed
      await _verifyCollapsed(tester, initialHeight);
    });

    testWidgets('Shortcut works when other screens are active', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Get the initial height (collapsed state)
      final initialHeight = _getInitialHeight(tester);

      // Navigate to settings screen
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify we're on settings screen
      expect(find.text('Settings'), findsOneWidget);

      // Send Command+Shift+M to toggle expansion
      debugPrint('Sending Command+Shift+M shortcut while on settings screen...');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);

      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // Navigate back to main screen to verify utility state
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify utility is expanded
      await _verifyExpanded(tester, initialHeight);

      // Toggle back to collapsed state
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);

      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // Verify utility is collapsed
      await _verifyCollapsed(tester, initialHeight);
    });
  });
}