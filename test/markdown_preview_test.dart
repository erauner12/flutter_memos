import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/screens/edit_memo/edit_memo_form.dart';
import 'package:flutter_memos/screens/new_memo/new_memo_form.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Markdown Preview Functionality Tests', () {
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

    testWidgets('NewMemoForm preview mode shows rendered markdown', (WidgetTester tester) async {
      // Build the NewMemoForm widget
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NewMemoForm(),
            ),
          ),
        ),
      );

      // Enter markdown text
      await tester.enterText(find.byType(TextField), '# Test Heading\n**Bold text**\n*Italic text*');
      await tester.pump();

      // Initially in edit mode
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);

      // Switch to preview mode
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Should now be in preview mode
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(MarkdownBody), findsOneWidget);

      // Verify markdown is rendered correctly
      expect(find.text('Test Heading'), findsOneWidget);
      expect(find.text('Bold text'), findsOneWidget);
      expect(find.text('Italic text'), findsOneWidget);

      // The Test Heading should be styled as a heading
      final headingText = tester.widget<RichText>(
        find.descendant(
          of: find.text('Test Heading'),
          matching: find.byType(RichText),
        ),
      );
      expect(headingText.text.style?.fontSize, greaterThan(16));

      // Switch back to edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Should be back in edit mode with text preserved
      expect(find.byType(TextField), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, contains('# Test Heading'));
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

    testWidgets('Links in preview are styled correctly', (WidgetTester tester) async {
      // Build a form with a link in the content
      final memo = Memo(
        id: 'test-id',
        content: '[Example Link](https://example.com)',
        pinned: false,
        state: MemoState.normal,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EditMemoForm(memo: memo, memoId: 'test-id'),
            ),
          ),
        ),
      );

      // Switch to preview mode
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Find the link
      expect(find.text('Example Link'), findsOneWidget);

      // Verify the link styling
      final linkWidget = tester.widget<RichText>(
        find.descendant(
          of: find.text('Example Link'),
          matching: find.byType(RichText),
        ),
      );
      
      final linkStyle = linkWidget.text.style;
      expect(linkStyle?.decoration, equals(TextDecoration.underline));
      
      // Link color should match theme's primary color
      final BuildContext context = tester.element(find.byType(MarkdownBody));
      final expectedColor = Theme.of(context).colorScheme.primary;
      expect(linkStyle?.color, equals(expectedColor));
    });

    testWidgets('Markdown code blocks are rendered with monospace font', (WidgetTester tester) async {
      final memo = Memo(
        id: 'test-id',
        content: '''
Here is some code:
```dart
void main() {
  print('Hello world');
}
```
''',
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

      // Switch to preview mode
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // The code parts should be visible
      expect(find.textContaining('void main()'), findsOneWidget);
      expect(find.textContaining("print('Hello world')"), findsOneWidget);

      // The code should be in a code block with monospace font
      // Find all RichText widgets
      final codeWidgets = tester.widgetList<RichText>(find.byType(RichText));
      
      // Check if any of them have monospace font family
      bool foundMonospaceFont = false;
      for (final widget in codeWidgets) {
        if (widget.text.style?.fontFamily?.toLowerCase().contains('mono') == true) {
          foundMonospaceFont = true;
          break;
        }
      }
      
      expect(foundMonospaceFont, isTrue, reason: 'No monospace font found for code block');
    });
  });
}
