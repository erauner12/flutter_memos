import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CaptureUtility Swipe Behavior Tests', () {
    testWidgets('Swipe up to expand and down to collapse', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find the CaptureUtility
      final captureUtilityFinder = find.byType(CaptureUtility);
      expect(captureUtilityFinder, findsOneWidget, reason: 'CaptureUtility not found');

      // Measure initial height (should be collapsed)
      final initialHeight = tester.getSize(captureUtilityFinder).height;
      debugPrint('Initial height: $initialHeight');

      // Swipe up to expand - use stronger upward gesture
      await tester.drag(captureUtilityFinder, const Offset(0, -150));
      // Make sure we wait long enough for the animation
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      // Verify it expanded
      final expandedHeight = tester.getSize(captureUtilityFinder).height;
      debugPrint('Expanded height: $expandedHeight');
      expect(expandedHeight, greaterThan(initialHeight), reason: 'CaptureUtility did not expand on upward swipe');

      // Check that a TextField is now visible (indicating expanded state)
      expect(find.descendant(of: captureUtilityFinder, matching: find.byType(TextField)),
             findsOneWidget,
             reason: 'TextField should be visible when expanded');

      // Swipe down to collapse - use stronger downward gesture
      await tester.drag(captureUtilityFinder, const Offset(0, 150));
      // Make sure we wait long enough for the animation
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      // Verify it collapsed
      final collapsedHeight = tester.getSize(captureUtilityFinder).height;
      debugPrint('Collapsed height after swipe down: $collapsedHeight');
      
      // Allow for a small margin of error in the height comparison
      expect(
        (collapsedHeight - initialHeight).abs() < 10,
        isTrue,
        reason:
            'CaptureUtility height should return to approximately the initial height'
      );

      // Verify text field is no longer visible
      expect(find.descendant(of: captureUtilityFinder, matching: find.byType(TextField)),
             findsNothing,
             reason: 'TextField should not be visible when collapsed');
    });

    testWidgets('Tap to expand and swipe down to collapse', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find the CaptureUtility
      final captureUtilityFinder = find.byType(CaptureUtility);
      expect(captureUtilityFinder, findsOneWidget, reason: 'CaptureUtility not found');

      // Record initial height
      final initialHeight = tester.getSize(captureUtilityFinder).height;

      // Tap to expand
      await tester.tap(captureUtilityFinder);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify it expanded
      final expandedHeight = tester.getSize(captureUtilityFinder).height;
      debugPrint('Expanded height after tap: $expandedHeight');
      expect(
        expandedHeight,
        greaterThan(initialHeight),
        reason: 'CaptureUtility did not expand on tap',
      );
      
      // Verify text field is visible
      expect(find.descendant(of: captureUtilityFinder, matching: find.byType(TextField)),
             findsOneWidget,
             reason: 'TextField should be visible when expanded');

      // Swipe down to collapse - use stronger downward gesture
      await tester.drag(captureUtilityFinder, const Offset(0, 150));
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      // Verify it collapsed
      final collapsedHeight = tester.getSize(captureUtilityFinder).height;
      debugPrint('Collapsed height after swipe: $collapsedHeight');
      
      // Allow for a small margin of error in the height comparison
      expect(
        (collapsedHeight - initialHeight).abs() < 10,
        isTrue,
        reason:
            'CaptureUtility height should return to approximately the initial height'
      );
      
      // Verify text field is no longer visible
      expect(find.descendant(of: captureUtilityFinder, matching: find.byType(TextField)),
             findsNothing,
             reason: 'TextField should not be visible when collapsed');
    });
  });
}
