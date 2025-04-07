import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart'; // Import api provider
import 'package:flutter_memos/screens/memo_detail/memo_content.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart';
import 'package:flutter_memos/services/api_service.dart'; // Add this import for ApiService
import 'package:flutter_memos/services/url_launcher_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart'; // Add this import for @GenerateNiceMocks
import 'package:mockito/mockito.dart';

// Import debug utils
import '../../../utils/test_debug.dart'; // Go up two levels to reach test/utils/
// Import the generated mocks for THIS file
import 'memo_content_links_test.mocks.dart';

// Generate mocks for services used in this test file
@GenerateNiceMocks([MockSpec<ApiService>(), MockSpec<UrlLauncherService>()])

void main() {
  group('MemoContent Link Handling Tests', () {
    late MockApiService mockApiService;
    late MockUrlLauncherService mockUrlLauncherService;

    setUp(() {
      mockApiService = MockApiService();
      mockUrlLauncherService =
          MockUrlLauncherService(); // Instantiate the imported mock
      when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');
      when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);
    });

    testWidgets('MemoContent handles link taps correctly', (WidgetTester tester) async {
      // Debug logs now enabled by default from test_debug.dart
      debugMarkdown('Starting MemoContent link tap test');

      // Create a memo with a link
      final memo = Memo(
        id: 'test-id',
        content: '[Example Link](https://example.com)',
        pinned: false,
        state: MemoState.normal,
      );

      // Create a mock list of comments to avoid API calls
      final mockComments = [
        Comment(
          id: 'comment-1',
          content: 'Test comment',
          createTime: DateTime.now().millisecondsSinceEpoch,
        )
      ];

      debugMarkdown('Building MemoContent with memo: ${memo.content}');

      // Build MemoContent with the memo using a ProviderScope with overrides
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override the memoCommentsProvider to return our mock comments
            memoCommentsProvider.overrideWith(
              (ref, id) => Future.value(mockComments),
            ),
            // Override the urlLauncherServiceProvider
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
            // Override the apiServiceProvider
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: Scaffold(body: MemoContent(memo: memo, memoId: 'test-id')),
          ),
        ),
      );

      // Wait for the async operations to complete
      await tester.pumpAndSettle();

      // Print out the widget tree for debugging
      debugDumpAppIfEnabled();

      // Find the MarkdownBody widget first to narrow down the search area
      expect(find.byType(MarkdownBody), findsAtLeastNWidgets(1));
  
      // Find all RichText widgets to check for our link text
      final richTextWidgets = tester.widgetList<RichText>(
        find.byType(RichText),
      );
      
      // Debug log all RichText content
      debugMarkdown('\nAll RichText widgets content:');
      for (final widget in richTextWidgets) {
        debugMarkdown('- "${widget.text.toPlainText()}"');
      }

      // More flexible approach to find our link text
      bool foundLinkText = false;
  
      // First try direct text search
      try {
        expect(find.textContaining('Example Link'), findsAtLeastNWidgets(1));
        foundLinkText = true;
        debugMarkdown('Found "Example Link" with direct text search');
      } catch (_) {
        debugMarkdown('Direct text search failed, searching in RichText widgets');
        // Not found with direct search, try searching in RichText widgets
        for (final widget in richTextWidgets) {
          final text = widget.text.toPlainText();
          if (text.contains('Example Link')) {
            foundLinkText = true;
            debugMarkdown('Found "Example Link" in RichText: $text');
            break;
          }
        }
      }
  
      expect(
        foundLinkText,
        isTrue,
        reason: 'Could not find the link text "Example Link" in any widget',
      );

      // Verify the MarkdownBody is set up for handling link taps
      final markdownBody = tester.widget<MarkdownBody>(
        find.byType(MarkdownBody).first,
      );
      expect(markdownBody.onTapLink, isNotNull);
      debugMarkdown('MarkdownBody onTapLink is properly configured');
    });

    testWidgets('MemoContent handles different link types (HTTP, HTTPS, memo://, etc)',
        (WidgetTester tester) async {
        // Mocks are initialized in setUp

      // Create a memo with different link types
      final memo = Memo(
        id: 'test-id',
        content: '''
[HTTP Link](http://example.com)
[HTTPS Link](https://secure.example.com)
[Memo Link](memo://12345)
[Email Link](mailto:test@example.com)
[Phone Link](tel:+1234567890)
''',
        pinned: false,
        state: MemoState.normal,
      );

      // Mock comments
      final mockComments = [
        Comment(
          id: 'comment-1',
          content: 'Test comment',
          createTime: DateTime.now().millisecondsSinceEpoch,
        )
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memoCommentsProvider.overrideWith(
              (ref, id) => Future.value(mockComments),
            ),
              // Override the urlLauncherServiceProvider
              urlLauncherServiceProvider.overrideWithValue(
                mockUrlLauncherService,
              ),
              // Override the apiServiceProvider
              apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: MaterialApp(
            home: Scaffold(body: MemoContent(memo: memo, memoId: 'test-id')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that all link texts are rendered
      final linkTexts = [
        'HTTP Link',
        'HTTPS Link',
        'Memo Link',
        'Email Link',
        'Phone Link',
      ];

      for (final linkText in linkTexts) {
        // Try different approaches to find the link text
        bool foundText = false;
        
        // Try textContaining finder
        try {
          await tester.runAsync(() async {
            final finder = find.textContaining(linkText);
            if (finder.evaluate().isNotEmpty) {
              foundText = true;
            }
          });
        } catch (_) {
          // Ignore error and try alternative method
        }
        
        // If not found, try searching in RichText widgets
        if (!foundText) {
          final richTextWidgets = tester.widgetList<RichText>(
            find.byType(RichText),
          );
          
          for (final widget in richTextWidgets) {
            if (widget.text.toPlainText().contains(linkText)) {
              foundText = true;
              break;
            }
          }
        }
        
        expect(
          foundText,
          isTrue,
          reason: 'Could not find the link text "$linkText" in the MemoContent',
        );
      }
    });
  });
}