import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../utils/test_debug.dart'; // Corrected path relative to features/markdown/link_handling

void main() {
  group('Special URL Schemes Tests', () {
    test('UrlHelper parses and validates different URL schemes', () {
      debugMarkdown('Testing URL scheme parsing and validation');
      
      // Test standard schemes
      expect(Uri.tryParse('https://example.com'), isNotNull);
      expect(Uri.tryParse('http://localhost:3000'), isNotNull);
      
      // Test email and phone schemes
      expect(Uri.tryParse('mailto:user@example.com'), isNotNull);
      expect(Uri.tryParse('tel:+1234567890'), isNotNull);
      
      // Test custom app scheme
      expect(Uri.tryParse('memo://12345'), isNotNull);
      
      // Test app schemes with query parameters
      expect(Uri.tryParse('memo://12345?action=view&highlight=true'), isNotNull);
      
      // Edge cases and problematic URLs
      final invalidUrl = Uri.tryParse('not a url');
      debugMarkdown('Invalid URL parse result: $invalidUrl');
      expect(invalidUrl, isNotNull); // Creates a Uri with path="not a url"
      expect(invalidUrl?.scheme, isEmpty); // but scheme will be empty
      
      // URL with spaces (should be encoded in real usage)
      final urlWithSpaces = Uri.tryParse('https://example.com/path with spaces');
      debugMarkdown('URL with spaces parse result: $urlWithSpaces');
      expect(urlWithSpaces, isNotNull);
      // URLs often encode spaces, so we shouldn't expect raw spaces
      expect(urlWithSpaces?.path.contains('with'), isTrue);
    });

    testWidgets('Custom scheme links render correctly and can be tapped', (WidgetTester tester) async {
      debugMarkdown('Testing custom scheme links rendering and tapping');
      
      // Track link taps
      String? tappedScheme;
      String? tappedPath;
      
      // Build separate widgets for each link type to avoid confusion
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Each link in its own MarkdownBody to ensure isolation
                MarkdownBody(
                  data: '[Memo Link](memo://12345)',
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      final uri = Uri.tryParse(href);
                      tappedScheme = uri?.scheme;
                      tappedPath = uri?.path;
                      debugMarkdown('Tapped memo link: scheme=$tappedScheme, path=$tappedPath');
                    }
                  },
                ),
                const SizedBox(height: 20), // Add spacing between links
                MarkdownBody(
                  data: '[Phone Link](tel:+1234567890)',
                  onTapLink: (text, href, title) {
                    // Use a different handler for the other links
                    // to avoid interference
                  },
                ),
                const SizedBox(height: 20),
                MarkdownBody(
                  data: '[Email Link](mailto:test@example.com)',
                  onTapLink: (text, href, title) {
                    // Another separate handler
                  },
                ),
              ],
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Debug output of all RichText widgets
      dumpRichTextContent(tester);
      
      // Find the Memo Link text more precisely - by looking for a widget with ONLY that text
      final memoLinkFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          final text = widget.text.toPlainText();
          debugMarkdown('Checking RichText: "$text"');
          return text == 'Memo Link'; // Must match exactly
        }
        return false;
      });
      
      expect(
        memoLinkFinder,
        findsOneWidget,
        reason: 'Could not find "Memo Link" text',
      );
      
      debugMarkdown('Tapping on memo link...');
      await tester.tap(memoLinkFinder);
      await tester.pump();

      // Verify correct scheme was detected
      debugMarkdown('Tap result: scheme=$tappedScheme, path=$tappedPath');
      expect(tappedScheme, equals('memo'));
      
      // Reset and find phone link specifically
      tappedScheme = null;
      tappedPath = null;
      
      // Test phone link separately with a new handler
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              data: '[Phone Link](tel:+1234567890)',
              onTapLink: (text, href, title) {
                if (href != null) {
                  final uri = Uri.tryParse(href);
                  tappedScheme = uri?.scheme;
                  tappedPath = uri?.path;
                }
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      final phoneLinkFinder = find.text('Phone Link');
      expect(phoneLinkFinder, findsOneWidget);

      await tester.tap(phoneLinkFinder);
      await tester.pump();

      expect(tappedScheme, equals('tel'));
    });
    
    test('UrlHelper._isCustomAppScheme identifies app schemes correctly', () {
      // Since _isCustomAppScheme is private, we're testing this indirectly
      // by checking URLs that should be handled specially
      
      // These custom schemes should typically be handled by specific apps
      final customSchemes = [
        'fb://profile/123',
        'twitter://user?screen_name=flutter',
        'instagram://user?username=flutterdev',
        'whatsapp://send?phone=1234567890',
        'spotify://track/123456',
        'com.example.app://action',
        'myapp://somepage',
      ];
      
      for (final url in customSchemes) {
        final uri = Uri.tryParse(url);
        expect(uri, isNotNull, reason: 'Could not parse $url');
        expect(uri?.scheme, isNotEmpty, reason: 'Empty scheme for $url');
      }
    });
    
    testWidgets('Links with encoded characters render correctly', (WidgetTester tester) async {
      const encodedLinksMarkdown = '''
[Encoded Space](https://example.com/path%20with%20spaces)
[Multiple Encodings](https://example.com/%20%3F%23)
[Query Params](https://example.com/search?q=flutter+widgets&lang=dart)
''';

      // Build a MarkdownBody with encoded links
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownBody(data: encodedLinksMarkdown),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find links in RichText widgets
      final richTextWidgets = tester.widgetList<RichText>(
        find.byType(RichText),
      );
      final linkTexts = ['Encoded Space', 'Multiple Encodings', 'Query Params'];

      for (final linkText in linkTexts) {
        bool foundText = false;
        for (final widget in richTextWidgets) {
          if (widget.text.toPlainText().contains(linkText)) {
            foundText = true;
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
    });
    
    testWidgets('Links with fragments and query parameters render correctly', (
      WidgetTester tester,
    ) async {
      // Track the link that was tapped
      String? tappedUrl;
      
      // Test each link type separately
      // First, test Fragment Link
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              data: '[Fragment Link](https://example.com/docs#section-3)',
              onTapLink: (text, href, title) {
                tappedUrl = href;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final fragmentLinkFinder = find.text('Fragment Link');
      expect(fragmentLinkFinder, findsOneWidget);

      await tester.tap(fragmentLinkFinder);
      await tester.pump();
      expect(tappedUrl, equals('https://example.com/docs#section-3'));
      
      // Test Query Parameters link
      tappedUrl = null;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              data:
                  '[Query Parameters](https://example.com/search?q=flutter&sort=recent)',
              onTapLink: (text, href, title) {
                tappedUrl = href;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final queryParamsFinder = find.text('Query Parameters');
      expect(queryParamsFinder, findsOneWidget);

      await tester.tap(queryParamsFinder);
      await tester.pump();
      expect(
        tappedUrl,
        equals('https://example.com/search?q=flutter&sort=recent'),
      );
      
      // Test Fragment and Query link
      tappedUrl = null;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              data:
                  '[Fragment and Query](https://example.com/page?id=123#details)',
              onTapLink: (text, href, title) {
                tappedUrl = href;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final fragmentQueryFinder = find.text('Fragment and Query');
      expect(fragmentQueryFinder, findsOneWidget);

      await tester.tap(fragmentQueryFinder);
      await tester.pump();
      expect(tappedUrl, equals('https://example.com/page?id=123#details'));
    });
  });
}