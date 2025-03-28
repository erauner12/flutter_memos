import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/screens/edit_memo/edit_memo_form.dart';
import 'package:flutter_memos/screens/memo_detail/memo_content.dart';
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Markdown Rendering Tests', () {
    testWidgets('Basic markdown elements render correctly in MarkdownBody', (WidgetTester tester) async {
      const markdownText = '''
# Heading 1
## Heading 2
**Bold text**
*Italic text*
[Link](https://example.com)
- List item 1
- List item 2
1. Numbered item 1
2. Numbered item 2
> Blockquote
`Code`
''';

      // Build a basic MarkdownBody widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownBody(data: markdownText),
          ),
        ),
      );

      // Verify markdown elements are rendered
      expect(find.text('Heading 1'), findsOneWidget);
      expect(find.text('Heading 2'), findsOneWidget);
      expect(find.text('Bold text'), findsOneWidget);
      expect(find.text('Italic text'), findsOneWidget);
      expect(find.text('Link'), findsOneWidget);
      expect(find.text('List item 1'), findsOneWidget);
      expect(find.text('List item 2'), findsOneWidget);
      expect(find.text('Numbered item 1'), findsOneWidget);
      expect(find.text('Numbered item 2'), findsOneWidget);
      expect(find.text('Blockquote'), findsOneWidget);
      expect(find.text('Code'), findsOneWidget);

      // Check that heading styles are applied correctly
      final heading1 = tester.widget<RichText>(
        find.descendant(
          of: find.text('Heading 1'),
          matching: find.byType(RichText),
        ),
      );
      expect(heading1.text.style?.fontSize, greaterThan(20));

      // Verify link is rendered with correct style
      final linkFinder = find.text('Link');
      final linkWidget = tester.widget<RichText>(
        find.descendant(
          of: linkFinder,
          matching: find.byType(RichText),
        ),
      );
      
      // Test the link's text style
      final linkStyle = linkWidget.text.style;
      expect(linkStyle?.color, isNot(Colors.black));  // Should be a different color
      expect(linkStyle?.decoration, equals(TextDecoration.underline));
    });

    testWidgets('Markdown renders with custom styling', (WidgetTester tester) async {
      const markdownText = '**Bold text with custom color**';
      final customColor = Colors.purple;

      // Build a MarkdownBody with custom styling
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              data: markdownText,
              styleSheet: MarkdownStyleSheet(
                strong: TextStyle(color: customColor, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      );

      // Find the RichText widget that contains our styled text
      final boldText = tester.widget<RichText>(
        find.descendant(
          of: find.text('Bold text with custom color'),
          matching: find.byType(RichText),
        ),
      );

      // Check that our custom color was applied
      expect(boldText.text.style?.color, equals(customColor));
    });

    testWidgets('MemoContent renders markdown correctly', (WidgetTester tester) async {
      final memo = Memo(
        id: 'test-id',
        content: '# Test Heading\n**Bold text**\n*Italic text*',
        pinned: false,
        state: MemoState.normal,
      );

      // Build the MemoContent widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MemoContent(memo: memo, memoId: 'test-id'),
            ),
          ),
        ),
      );

      // Allow async operations to complete
      await tester.pumpAndSettle();

      // Verify markdown elements are rendered
      expect(find.text('Test Heading'), findsOneWidget);
      expect(find.text('Bold text'), findsOneWidget);
      expect(find.text('Italic text'), findsOneWidget);

      // Check that heading is styled differently
      final headingText = tester.widget<RichText>(
        find.descendant(
          of: find.text('Test Heading'),
          matching: find.byType(RichText),
        ),
      );
      expect(headingText.text.style?.fontSize, greaterThan(16));
    });

    testWidgets('CommentCard renders markdown correctly', (WidgetTester tester) async {
      final comment = Comment(
        id: 'comment-id',
        content: '**Bold comment**\n*Italic text*\n[Link](https://example.com)',
        createTime: DateTime.now().millisecondsSinceEpoch,
      );

      // Build the CommentCard widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CommentCard(
                comment: comment,
                memoId: 'test-memo-id',
              ),
            ),
          ),
        ),
      );

      // Allow async operations to complete
      await tester.pumpAndSettle();

      // Verify markdown elements are rendered
      expect(find.text('Bold comment'), findsOneWidget);
      expect(find.text('Italic text'), findsOneWidget);
      expect(find.text('Link'), findsOneWidget);
    });

    testWidgets('MemoCard renders markdown correctly', (WidgetTester tester) async {
      // Build the MemoCard widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MemoCard(
              id: 'test-id',
              content: '# Card Heading\n**Bold text**\n- List item',
              pinned: false,
            ),
          ),
        ),
      );

      // Allow async operations to complete
      await tester.pumpAndSettle();

      // Verify markdown elements are rendered
      expect(find.text('Card Heading'), findsOneWidget);
      expect(find.text('Bold text'), findsOneWidget);
      expect(find.text('List item'), findsOneWidget);
    });

    testWidgets('EditMemoForm toggles between edit and preview modes', (WidgetTester tester) async {
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
      expect(find.text('Test Heading'), findsOneWidget);
      expect(find.text('Bold text'), findsOneWidget);

      // Go back to edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Should be back in edit mode
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);
    });

    testWidgets('Handles empty markdown content gracefully', (WidgetTester tester) async {
      // Build a MarkdownBody with empty content
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownBody(data: ''),
          ),
        ),
      );

      // No errors should be thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('Handles malformed markdown gracefully', (WidgetTester tester) async {
      const malformedMarkdown = '**Unclosed bold';

      // Build a MarkdownBody with malformed content
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownBody(data: malformedMarkdown),
          ),
        ),
      );

      // No errors should be thrown
      expect(tester.takeException(), isNull);
      
      // Content should still be displayed
      expect(find.text('**Unclosed bold'), findsOneWidget);
    });

    testWidgets('Complex nested markdown renders correctly', (WidgetTester tester) async {
      const complexMarkdown = '''
# Main heading
## Sub heading with **bold text**
- List item with *italic text*
- List item with [link](https://example.com)
  - Nested list item
    - Double nested item

1. First item with `code`
2. Second item with >quote
''';

      // Build a MarkdownBody with complex content
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MarkdownBody(data: complexMarkdown),
            ),
          ),
        ),
      );

      // Verify main elements are rendered
      expect(find.text('Main heading'), findsOneWidget);
      
      // For complex nested elements, we might not find exact text matches
      // because of how the render tree splits things up, but we can check
      // for partial content
      expect(find.textContaining('Sub heading'), findsOneWidget);
      expect(find.textContaining('bold text'), findsOneWidget);
      expect(find.textContaining('italic text'), findsOneWidget);
      expect(find.text('link'), findsOneWidget);
      expect(find.textContaining('Nested list item'), findsOneWidget);
      expect(find.textContaining('code'), findsOneWidget);
    });

    testWidgets('Special characters in markdown are handled correctly', (WidgetTester tester) async {
      const specialCharsMarkdown = '''
# Heading with & < > " '
Text with emoji 😊 and symbols © ®
```
Code with special <html> &tags
```
''';

      // Build a MarkdownBody with special characters
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownBody(data: specialCharsMarkdown),
          ),
        ),
      );

      // Verify elements with special characters are rendered
      expect(find.textContaining('Heading with'), findsOneWidget);
      expect(find.textContaining('emoji'), findsOneWidget);
      expect(find.textContaining('Code with special'), findsOneWidget);
    });
  });
}
