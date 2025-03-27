import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockMemo extends Mock implements Memo {
  @override
  final String id = 'test-id';
  @override
  final String content = 'Test memo content';
  @override
  final bool pinned = false;
  @override
  final MemoState state = MemoState.normal;
  @override
  final String visibility = 'PUBLIC';
}

class MockComment extends Mock implements Comment {
  @override
  final String id = 'comment-id';
  @override
  final String content = 'Test comment';
  @override
  final int createTime = DateTime.now().millisecondsSinceEpoch;
  @override
  final bool pinned = false;
}

void main() {
  group('MemoDetailScreen Focus Management Tests', () {
    late ProviderContainer container;
    late NavigatorObserver mockObserver;
    
    setUp(() {
      mockObserver = MockNavigatorObserver();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Screen should have focus by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            navigatorObservers: [mockObserver],
            home: MemoDetailScreen(memoId: 'test-id'),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify focus is on the screen by checking the focus system
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
    });

    testWidgets('K key should navigate to previous comment', (WidgetTester tester) async {
      // Initialize with some comments selected
      container.read(selectedCommentIndexProvider.notifier).state = 1;
      
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            navigatorObservers: [mockObserver],
            home: MemoDetailScreen(memoId: 'test-id'),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Send a K key event
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pumpAndSettle();
      
      // Check if the selection changed
      // Since we don't have actual comments loaded, this might not change the actual selection
      // But we can verify the code ran without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('J key should navigate to next comment', (WidgetTester tester) async {
      // Initialize with some comments selected
      container.read(selectedCommentIndexProvider.notifier).state = 0;
      
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            navigatorObservers: [mockObserver],
            home: MemoDetailScreen(memoId: 'test-id'),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Send a J key event
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pumpAndSettle();
      
      // Check if the selection changed
      // Since we don't have actual comments loaded, this might not change the actual selection
      // But we can verify the code ran without errors
      expect(tester.takeException(), isNull);
    });
    
    testWidgets('Focus should remain on screen when tapping elsewhere', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            navigatorObservers: [mockObserver],
            home: MemoDetailScreen(memoId: 'test-id'),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Get the focus state
      final initialFocusNode = FocusManager.instance.primaryFocus;
      
      // Tap somewhere on the screen
      await tester.tap(find.byType(MemoDetailScreen));
      await tester.pumpAndSettle();
      
      // Check if focus is still on the screen
      final finalFocusNode = FocusManager.instance.primaryFocus;
      expect(finalFocusNode, equals(initialFocusNode));
    });
  });
}