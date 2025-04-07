import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper extension for working with Slidable widgets in tests
extension SlidableTestExtension on CommonFinders {
  /// Find a slidable action with the given label text
  Finder slidableAction(String label) {
    return find.descendant(
      of: find.byType(Slidable),
      matching: find.text(label),
    );
  }

  /// Find a slidable's end action pane (right side, typically delete/archive)
  Finder slidableEndActionPane() {
    return find.byWidgetPredicate((widget) {
      if (widget is ActionPane) {
        // Find the end action pane (typically for delete operations)
        return true;
      }
      return false;
    });
  }
}

/// Helper methods for testing slidable widgets
class SlidableTestUtils {
  /// Slide the widget to reveal actions and then tap an action by its label
  static Future<void> slideAndTapAction(
    WidgetTester tester,
    Finder slidableFinder,
    String actionLabel,
    {bool slideRight = false}
  ) async {
    // Swipe in the appropriate direction
    await tester.drag(
      slidableFinder,
      Offset(slideRight ? 300 : -300, 0)
    );
    await tester.pumpAndSettle();

    // Allow animation to complete
    await tester.pump(const Duration(milliseconds: 300));

    // Find and tap the action
    final actionFinder = find.text(actionLabel);
    expect(actionFinder, findsOneWidget, reason: '$actionLabel button not found');
    await tester.tap(actionFinder);
    await tester.pumpAndSettle();
  }
}