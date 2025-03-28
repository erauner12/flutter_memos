import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/screens/edit_memo/edit_memo_form.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditMemoForm Markdown Preview Tests', () {
    testWidgets('EditMemoForm markdown help toggle works', (WidgetTester tester) async {
      final memo = Memo(
        id: 'test-id',
        content: 'Test content',
        pinned: false,
        state: MemoState.normal,
      );

      // Build the EditMemoForm widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EditMemoForm(memo: memo, memoId: 'test-id'),
            ),
          ),
        ),
      );

      // Initially help should not be shown
      expect(find.text('Markdown Syntax Guide'), findsNothing);

      // Tap the help button
      await tester.tap(find.text('Markdown Help'));
      await tester.pumpAndSettle();

      // Help should now be visible
      expect(find.text('Markdown Syntax Guide'), findsOneWidget);
      
      // Check for some help content
      expect(find.text('Heading 1'), findsOneWidget);
      expect(find.text('Bold text'), findsOneWidget);
      expect(find.text('Italic text'), findsOneWidget);

      // Tap the hide help button
      await tester.tap(find.text('Hide Help'));
      await tester.pumpAndSettle();

      // Help should be hidden again
      expect(find.text('Markdown Syntax Guide'), findsNothing);
    });

    testWidgets('Live preview updates when content changes', (WidgetTester tester) async {
      final memo = Memo(
        id: 'test-id',
        content: 'Initial content',
        pinned: false,
        state: MemoState.normal,
      );

      // Build the EditMemoForm widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EditMemoForm(memo: memo, memoId: 'test-id'),
            ),
          ),
        ),
      );

      // First switch to preview mode
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Initial content should be shown
      expect(find.text('Initial content'), findsOneWidget);

      // Switch back to edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Change the content
      await tester.enterText(find.byType(TextField), '# New Heading\n**Bold**');
      await tester.pump();

      // Switch to preview mode again
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Updated content should be shown in preview
      expect(find.text('New Heading'), findsOneWidget);
      expect(find.text('Bold'), findsOneWidget);
      expect(find.text('Initial content'), findsNothing);
    });

    testWidgets('Toggle between edit and preview modes works correctly', (WidgetTester tester) async {
      final memo = Memo(
        id: 'test-id',
        content: '# Test Heading\n**Bold text**',
        pinned: false,
        state: MemoState.normal,
      );

      // Build the EditMemoForm widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EditMemoForm(memo: memo, memoId: 'test-id'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially in edit mode - TextField should be visible
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);

      // Find and tap the Preview button
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Now should be in preview mode - MarkdownBody should be visible, TextField hidden
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(MarkdownBody), findsOneWidget);

      // Verify markdown content is rendered
      expect(find.textContaining('Test Heading'), findsOneWidget);
      expect(find.textContaining('Bold text'), findsOneWidget);

      // Go back to edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Should be back in edit mode
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);
    });
  });
}
