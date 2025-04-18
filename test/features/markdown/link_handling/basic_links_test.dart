import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_debug.dart'; // Go up two levels to reach test/helpers/

void main() {
  group('Basic Markdown Link Tests (Cupertino)', () {
    testWidgets('MarkdownBody passes link tap events to callback', (WidgetTester tester) async {
      // Track if the link callback was called
      bool linkTapped = false;
      String? tappedUrl;

      // Build a MarkdownBody with a link inside CupertinoApp
      await tester.pumpWidget(
        CupertinoApp(
          // Use CupertinoApp
          home: CupertinoPageScaffold(
            // Use CupertinoPageScaffold
            child: MarkdownBody(
              data: '[Test Link](https://example.com)',
              onTapLink: (text, href, title) {
                linkTapped = true;
                tappedUrl = href;
                debugMarkdown(
                  'Link tapped: $text, URL: $href',
                ); // Add debug output
              },
            ),
          ),
        ),
      );

      // Find and tap the link (rendered as RichText)
      await tester.tap(find.text('Test Link'));
      await tester.pump();

      // Log the result
      debugMarkdown('Link tap registered: $linkTapped, URL: $tappedUrl');

      // Verify callback was called with correct URL
      expect(linkTapped, isTrue);
      expect(tappedUrl, equals('https://example.com'));
    });

    testWidgets('Different link types are displayed correctly', (WidgetTester tester) async {
      const markdownText = '''
[Regular link](https://example.com)
[Email link](mailto:test@example.com)
[Phone link](tel:+1234567890)
[Custom scheme](memo://12345)
''';

      // Build a MarkdownBody with different link types and explicit styling
      await tester.pumpWidget(
        CupertinoApp(
          // Use CupertinoApp
          theme: const CupertinoThemeData(
            // Use CupertinoThemeData
            // Ensure links have explicit styling that we can detect
            textTheme: CupertinoTextThemeData(
              // Use CupertinoTextThemeData
              textStyle: TextStyle(color: CupertinoColors.black), // Base style
            ),
          ),
          home: CupertinoPageScaffold(
            // Use CupertinoPageScaffold
            child: MarkdownBody(
              data: markdownText,
              styleSheet: MarkdownStyleSheet(
                a: const TextStyle(
                  color: CupertinoColors.activeBlue, // Use Cupertino color
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debug: print all RichText content
      dumpRichTextContent(tester);

      // Check if the links are present in the rendered output
      final linkTexts = [
        'Regular link',
        'Email link',
        'Phone link',
        'Custom scheme',
      ];

      for (final linkText in linkTexts) {
        // Find all RichText widgets
        final richTextWidgets = tester.widgetList<RichText>(
          find.byType(RichText),
        );
        bool foundText = false;

        for (final richText in richTextWidgets) {
          if (richText.text.toPlainText().contains(linkText)) {
            foundText = true;
            debugMarkdown('Found link text: $linkText'); // Add debug log
            break;
          }
        }

        expect(
          foundText,
          isTrue,
          reason:
              'Could not find the link text "$linkText" in any RichText widget',
        );
      }

      // Find all TextSpan instances and verify at least one has underline decoration
      bool foundUnderlinedText = false;

      // Helper function to traverse TextSpan tree
      void findUnderlinedText(InlineSpan span) {
        if (span is TextSpan) {
          // Check if this span has underline decoration
          if (span.style?.decoration == TextDecoration.underline) {
            foundUnderlinedText = true;
            debugMarkdown(
              'Found underlined text: ${span.text}',
            ); // Add debug log
          }

          // Check children if they exist
          if (!foundUnderlinedText && span.children != null) {
            for (final child in span.children!) {
              findUnderlinedText(child);
              if (foundUnderlinedText) break;
            }
          }
        }
      }

      // Get all RichText widgets and check their text spans
      final allRichText = tester.widgetList<RichText>(find.byType(RichText));
      for (final richText in allRichText) {
        findUnderlinedText(richText.text);
        if (foundUnderlinedText) break;
      }

      expect(
        foundUnderlinedText,
        isTrue,
        reason:
            'No underlined text found, expected at least one link to be underlined',
      );
    });
  });
}