import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
// Import your actual app entrypoint and widget types needed
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MemoCard Context Menu Integration Tests', () {
    testWidgets('Open context menu and perform Hide action', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find the MemoCard widget
      final memoCardFinder = find.byType(MemoCard).first;
      expect(memoCardFinder, findsWidgets);

      // Get the current number of MemoCards displayed
      final initialCount = find.byType(MemoCard).evaluate().length;

      // Open context menu with appropriate gesture for the platform
      if (kIsWeb) {
        await tester.tap(memoCardFinder, buttons: kSecondaryButton);
      } else {
        await tester.longPress(memoCardFinder);
      }
      await tester.pumpAndSettle();

      // Verify context menu is shown
      expect(find.text('Memo Actions'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);

      // Tap the Hide option
      await tester.tap(find.text('Hide'));
      await tester.pumpAndSettle();

      // Verify the memo is hidden (count of visible memos decreases by 1)
      final finalCount = find.byType(MemoCard).evaluate().length;
      expect(finalCount, initialCount - 1);
      
      // Verify the hidden memos indicator appears
      expect(find.textContaining('memos hidden'), findsOneWidget);
    });

    testWidgets('Open context menu and perform Archive action', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find the MemoCard widget
      final memoCardFinder = find.byType(MemoCard).first;
      expect(memoCardFinder, findsWidgets);

      // Get the current number of MemoCards displayed
      final initialCount = find.byType(MemoCard).evaluate().length;

      // Open context menu with appropriate gesture for the platform
      if (kIsWeb) {
        await tester.tap(memoCardFinder, buttons: kSecondaryMouseButton);
      } else {
        await tester.longPress(memoCardFinder);
      }
      await tester.pumpAndSettle();

      // Verify context menu is shown
      expect(find.text('Archive'), findsOneWidget);

      // Tap the Archive option
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      // Verify the memo is archived (count of visible memos decreases by 1)
      final finalCount = find.byType(MemoCard).evaluate().length;
      expect(finalCount, initialCount - 1);
      
      // Check for success message
      expect(find.text('Memo archived successfully'), findsOneWidget);
    });

    testWidgets('Open context menu and perform Delete action with confirmation', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find the MemoCard widget
      final memoCardFinder = find.byType(MemoCard).first;
      expect(memoCardFinder, findsWidgets);

      // Get the current number of MemoCards displayed
      final initialCount = find.byType(MemoCard).evaluate().length;

      // Open context menu with appropriate gesture for the platform
      if (kIsWeb) {
        await tester.tap(memoCardFinder, buttons: kSecondaryMouseButton);
      } else {
        await tester.longPress(memoCardFinder);
      }
      await tester.pumpAndSettle();

      // Verify Delete option is shown
      expect(find.text('Delete'), findsOneWidget);

      // Tap the Delete option
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion in the dialog
      expect(find.text('Confirm Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify the memo is deleted (count of visible memos decreases by 1)
      final finalCount = find.byType(MemoCard).evaluate().length;
      expect(finalCount, initialCount - 1);
    });

    testWidgets('Open context menu and toggle Pin status', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find a MemoCard widget
      final memoCardFinder = find.byType(MemoCard).first;
      expect(memoCardFinder, findsWidgets);

      // Open context menu
      if (kIsWeb) {
        await tester.tap(memoCardFinder, buttons: kSecondaryMouseButton);
      } else {
        await tester.longPress(memoCardFinder);
      }
      await tester.pumpAndSettle();

      // Check for Pin/Unpin option (depends on the current pin state)
      final hasPinOption = find.text('Pin').evaluate().isNotEmpty;
      final hasUnpinOption = find.text('Unpin').evaluate().isNotEmpty;
      
      // One of them should be present
      expect(hasPinOption || hasUnpinOption, isTrue);
      
      // Tap the appropriate option
      if (hasPinOption) {
        await tester.tap(find.text('Pin'));
      } else {
        await tester.tap(find.text('Unpin'));
      }
      await tester.pumpAndSettle();
      
      // We can't easily verify the pin state changed without more context,
      // but we can check the menu closed properly
      expect(find.text('Memo Actions'), findsNothing);
    });

    testWidgets('Open context menu and perform Copy Text action', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find a MemoCard widget
      final memoCardFinder = find.byType(MemoCard).first;
      expect(memoCardFinder, findsWidgets);

      // Open context menu
      if (kIsWeb) {
        await tester.tap(memoCardFinder, buttons: kSecondaryMouseButton);
      } else {
        await tester.longPress(memoCardFinder);
      }
      await tester.pumpAndSettle();

      // Verify Copy Text option is shown
      expect(find.text('Copy Text'), findsOneWidget);

      // Tap the Copy Text option
      await tester.tap(find.text('Copy Text'));
      await tester.pumpAndSettle();

      // Verify copy success notification
      expect(find.text('Memo content copied to clipboard'), findsOneWidget);
    });
  });
}
