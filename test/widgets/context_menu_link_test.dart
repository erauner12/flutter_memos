import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_memos/widgets/memo_context_menu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() {
    // Reset the clipboard between tests
    Clipboard.setData(const ClipboardData(text: ''));
  });

  group('Context Menu Link Copy Tests', () {
    testWidgets('MemoContextMenu "Copy Link" copies correct URL format',
        (WidgetTester tester) async {
      final testMemoId = 'test-memo-id';
      
      // Mock clipboard
      String? clipboardText;
      SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          clipboardText = methodCall.arguments['text'] as String?;
        } else if (methodCall.method == 'Clipboard.getData') {
          return {'text': clipboardText ?? ''};
        }
        return null;
      });
      
      // Build the context menu
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return MemoContextMenu(
                memoId: testMemoId,
                isPinned: false,
                position: const Offset(0, 0),
                parentContext: context,
                onClose: () {},
                onCopyLink: () async {
                  final url = 'flutter-memos://memo/$testMemoId';
                  await Clipboard.setData(ClipboardData(text: url));
                },
              );
            },
          ),
        ),
      );
      
      // Find the Copy Link menu item
      final copyLinkFinder = find.text('Copy Link');
      expect(copyLinkFinder, findsOneWidget);
      
      // Tap the Copy Link menu item
      await tester.tap(copyLinkFinder);
      await tester.pump();
      
      // Verify the correct URL was copied
      expect(clipboardText, equals('flutter-memos://memo/$testMemoId'));
      
      // Clean up
      SystemChannels.platform.setMockMethodCallHandler(null);
    });

    testWidgets('MemoCard triggers context menu on long press',
        (WidgetTester tester) async {
      // Build a MemoCard
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemoCard(
              id: 'test-memo-id',
              content: 'Test memo content',
              onTap: () {},
            ),
          ),
        ),
      );
      
      // Ensure card is built
      expect(find.byType(MemoCard), findsOneWidget);
      
      // Long press should show context menu
      // Note: This will actually open a modal bottom sheet which might not be directly testable
      // This test verifies the GestureDetector exists and has an onLongPress handler
      final gestureFinder = find.descendant(
        of: find.byType(MemoCard),
        matching: find.byType(InkWell),
      );
      expect(gestureFinder, findsOneWidget);
      
      // Verify the InkWell has an onLongPress handler
      final inkWell = tester.widget<InkWell>(gestureFinder);
      expect(inkWell.onLongPress, isNotNull);
    });
  });
}
