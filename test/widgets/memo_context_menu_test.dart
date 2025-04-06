import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for ServicesBinding and SystemChannels
import 'package:flutter_memos/widgets/memo_context_menu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Ensure TestWidgetsFlutterBinding is initialized
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MemoContextMenu Tests', () {
    testWidgets('MemoContextMenu "Copy Link" option copies correct URL to clipboard', (
      WidgetTester tester,
    ) async {
      const testMemoId = 'test-memo-id';
      const testUrl = 'flutter-memos://memo/test-memo-id';
      bool copyLinkTapped = false;

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

      // Since MemoContextMenu is usually shown in a modal bottom sheet,
      // we'll create a wrapper to display it directly for testing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return MemoContextMenu(
                  memoId: testMemoId,
                  isPinned: false,
                  position: const Offset(0, 0),
                  parentContext: context,
                  onCopyLink: () => copyLinkTapped = true,
                  onClose: () {},
                );
              },
            ),
          ),
        ),
      );

      // Allow the widget to render
      await tester.pumpAndSettle();

      // Find and tap the "Copy Link" menu item
      final copyLinkFinder = find.byKey(const Key('copy_link_menu_item'));
      expect(copyLinkFinder, findsOneWidget, reason: 'Copy Link menu item should be visible');
      
        // Tap only once
        await tester.tap(copyLinkFinder);
      
        // Add a small delay to allow the async Clipboard.setData operation to complete
        await tester.pump(const Duration(milliseconds: 50));
        // Ensure all microtasks and animations are finished after the delay
        await tester.pumpAndSettle();
      
        // Filter the log for Clipboard.setData calls
        final clipboardCalls =
            log.where((call) => call.method == 'Clipboard.setData').toList();

        // Verify Clipboard.setData was called exactly once with the correct URL
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

      // Verify the callback was triggered
      expect(copyLinkTapped, isTrue, reason: 'onCopyLink callback should have been called');

      // Clear the handler after the test
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    testWidgets('MemoContextMenu should display all expected menu options', (
      WidgetTester tester,
    ) async {
      const testMemoId = 'test-memo-id';

      // Pump the MemoContextMenu widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return MemoContextMenu(
                  memoId: testMemoId,
                  isPinned: false,
                  position: const Offset(0, 0),
                  parentContext: context,
                  onClose: () {},
                );
              },
            ),
          ),
        ),
      );

      // Allow the widget to render
      await tester.pumpAndSettle();

      // Verify all expected menu items are present
      expect(find.text('View Memo'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Pin'), findsOneWidget); // Should be "Pin" since isPinned is false
      expect(find.text('Bump'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);
      expect(find.text('Copy Link'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('MemoContextMenu should toggle between Pin/Unpin based on isPinned', (
      WidgetTester tester,
    ) async {
      const testMemoId = 'test-memo-id';

      // Test with isPinned = true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return MemoContextMenu(
                  memoId: testMemoId,
                  isPinned: true, // Set to true
                  position: const Offset(0, 0),
                  parentContext: context,
                  onClose: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Unpin'), findsOneWidget); // Should show "Unpin" when isPinned is true
      
      // Rebuild with isPinned = false
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return MemoContextMenu(
                  memoId: testMemoId,
                  isPinned: false, // Set to false
                  position: const Offset(0, 0),
                  parentContext: context,
                  onClose: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Pin'), findsOneWidget); // Should show "Pin" when isPinned is false
    });
  });
}
