import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for ServicesBinding and SystemChannels
import 'package:flutter_memos/widgets/context_menu_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Ensure TestWidgetsFlutterBinding is initialized
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContextMenuLink Tests', () {
    testWidgets('ContextMenuLink displays text and handles long press', (
      WidgetTester tester,
    ) async {
      const testText = 'Test Link Text';
      const testUrl = 'flutter-memos://memo/test-memo-id';
      bool linkTapped = false;
      bool copyTapped = false;

      // Set up mock method call handler for Clipboard
      List<MethodCall> log = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'Clipboard.setData') {
            // Simulate success for setData
            return null;
          }
          // Handle other potential platform calls if necessary, otherwise return null
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextMenuLink(
              text: testText,
              url: testUrl,
              onTap: () => linkTapped = true,
              onCopy: () => copyTapped = true,
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text(testText), findsOneWidget);
      expect(linkTapped, isFalse);
      expect(copyTapped, isFalse);

      // Simulate long press to show context menu
      await tester.longPress(find.text(testText));
      await tester.pumpAndSettle(); // Wait for menu animation

      // Verify context menu items appear
      expect(find.text('Open Link'), findsOneWidget);
      expect(find.text('Copy Link'), findsOneWidget);

      // Simulate tapping 'Copy Link'
      await tester.tap(find.text('Copy Link'));
      await tester.pumpAndSettle(); // Wait for menu to dismiss

      // Verify onCopy callback was triggered
      expect(copyTapped, isTrue);

      // Filter the log for Clipboard.setData calls
      final clipboardCalls =
          log.where((call) => call.method == 'Clipboard.setData').toList();

      // Verify Clipboard.setData was called exactly once
      expect(
        clipboardCalls,
        hasLength(1),
        reason: 'Clipboard.setData should have been called exactly once',
      );
      expect(clipboardCalls.first.method, 'Clipboard.setData');
      expect(
        clipboardCalls.first.arguments['text'],
        testUrl,
        reason: 'Clipboard.setData should be called with the correct URL',
      );

      // Reset linkTapped for the next interaction
      linkTapped = false;

      // Simulate long press again
      await tester.longPress(find.text(testText));
      await tester.pumpAndSettle();

      // Simulate tapping 'Open Link'
      await tester.tap(find.text('Open Link'));
      await tester.pumpAndSettle();

      // Verify onTap callback was triggered
      expect(linkTapped, isTrue);

      // Clear the handler after the test
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    testWidgets('ContextMenuLink handles simple tap', (
      WidgetTester tester,
    ) async {
      const testText = 'Tap Me';
      const testUrl = 'flutter-memos://memo/tap-test';
      bool linkTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextMenuLink(
              text: testText,
              url: testUrl,
              onTap: () => linkTapped = true,
              onCopy: () {}, // Provide dummy onCopy
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text(testText), findsOneWidget);
      expect(linkTapped, isFalse);

      // Simulate simple tap
      await tester.tap(find.text(testText));
      await tester.pumpAndSettle();

      // Verify onTap callback was triggered
      expect(linkTapped, isTrue);

      // Verify context menu did NOT appear
      expect(find.text('Open Link'), findsNothing);
      expect(find.text('Copy Link'), findsNothing);
    });
  });
}
