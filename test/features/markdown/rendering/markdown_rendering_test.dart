import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/screens/edit_memo/edit_memo_form.dart';
import 'package:flutter_memos/screens/edit_memo/edit_memo_providers.dart';
import 'package:flutter_memos/screens/memo_detail/memo_content.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart';
import 'package:flutter_memos/services/api_service.dart'; // Import the actual service
import 'package:flutter_memos/services/url_launcher_service.dart';
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart'; // Add Mockito annotation import
import 'package:mockito/mockito.dart'; // Add Mockito import

// Import the generated mocks file (will be created by build_runner)
import 'markdown_rendering_test.mocks.dart';
// Import the mock for UrlLauncherService
import 'services/url_launcher_service_test.mocks.dart';
// Import test utility
import 'utils/test_debug.dart';

// Annotation to generate nice mock for ApiService
@GenerateNiceMocks([MockSpec<ApiService>()])

void main() {
  // Declare mocks at the top level
  late MockApiService mockApiService;
  late MockUrlLauncherService mockUrlLauncherService;

  group('Markdown Rendering Tests', () {
    // Setup function that runs before each test
    setUp(() {
      mockApiService = MockApiService();
      mockUrlLauncherService = MockUrlLauncherService(); // Initialize URL launcher mock

      // Add stub for apiBaseUrl property
      when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');
      // Stub the launch method to return success by default
      when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);
    });

    testWidgets('Basic markdown elements render correctly in MarkdownBody', (WidgetTester tester) async {
      debugMarkdown('Testing basic markdown elements rendering');
      
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
      debugMarkdown('Test markdown content: $markdownText');

      // Build a basic MarkdownBody widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MarkdownBody(data: markdownText),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Debug output all rendered content
      dumpRichTextContent(tester);

      // Verify markdown elements are rendered, using textContaining for more reliable results
      expect(find.textContaining('Heading 1'), findsOneWidget);
      expect(find.textContaining('Heading 2'), findsOneWidget);
      expect(find.textContaining('Bold text'), findsOneWidget);
      expect(find.textContaining('Italic text'), findsOneWidget);
      expect(find.textContaining('Link'), findsOneWidget);
      expect(find.textContaining('List item 1'), findsOneWidget);
      expect(find.textContaining('List item 2'), findsOneWidget);
      expect(find.textContaining('Numbered item 1'), findsOneWidget);
      expect(find.textContaining('Numbered item 2'), findsOneWidget);
      expect(find.textContaining('Blockquote'), findsOneWidget);
      expect(find.textContaining('Code'), findsOneWidget);
      debugMarkdown('Found all expected markdown elements in rendered output');

      // Verify RichText widgets exist (this is how markdown ultimately renders)
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('Markdown renders with custom styling', (WidgetTester tester) async {
      const markdownText = '**Bold text with custom color**';
      final customColor =
          Colors.red; // Using standard Color instead of MaterialColor

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

      await tester.pumpAndSettle();

      // Verify bold text exists
      expect(
        find.textContaining('Bold text with custom color'),
        findsOneWidget,
      );
      
      // Find RichText widgets that contain our text
      final richTextWidgets = tester.widgetList<RichText>(
        find.byType(RichText),
      );
      
      // Debug: Print all RichText widgets and their colors
      debugMarkdown(
        '\nChecking ${richTextWidgets.length} RichText widgets for styled text:',
      );

      // Look for any TextSpan with red styling
      bool foundStyledText = false;
      
      // Helper function to recursively check TextSpan and its children for red styling
      void checkForRedStyling(InlineSpan span) {
        if (span is TextSpan) {
          final style = span.style;
          final text = span.text ?? '';

          // Debug info
          if (style?.color != null) {
            debugMarkdown('Text: "$text", Color: ${style?.color}');
          }

          // Check if this span has red color
          if (style?.color != null &&
              style!.color!.r > 0.5 &&
              style.color!.g < 0.5 &&
              style.color!.b < 0.5) {
            debugMarkdown('Found red text: "$text"');
            foundStyledText = true;
          }

          // Check children if they exist
          if (span.children != null) {
            for (final child in span.children!) {
              checkForRedStyling(child);
            }
          }
        }
      }

      // Check all RichText widgets
      for (final widget in richTextWidgets) {
        checkForRedStyling(widget.text);
        if (foundStyledText) break;
      }

      // If we didn't find red text, try a different approach - check for any red styling
      if (!foundStyledText) {
        for (final widget in richTextWidgets) {
          final plainText = widget.text.toPlainText();
          if (plainText.contains('Bold text with custom color')) {
            debugMarkdown('Found matching text: $plainText');
            // Use a more lenient check for any reddish color
            void checkTextSpanColor(InlineSpan span) {
              if (span is TextSpan) {
                final color = span.style?.color;
                if (color != null) {
                  debugMarkdown(
                    'Color components: R=${color.r}, G=${color.g}, B=${color.b}',
                  );
                  // More lenient check: any shade where red is the dominant component
                  if (color.r > color.g && color.r > color.b) {
                    foundStyledText = true;
                    debugMarkdown('Found reddish color: $color');
                  }
                }

                if (span.children != null) {
                  for (final child in span.children!) {
                    checkTextSpanColor(child);
                  }
                }
              }
            }

            checkTextSpanColor(widget.text);
          }
        }
      }

      expect(
        foundStyledText,
        isTrue,
        reason: 'Did not find text with expected red styling',
      );
    });

    testWidgets('MemoContent renders markdown correctly', (
      WidgetTester tester,
    ) async {
      // Set up memo and comments data
      final memo = Memo(
        id: 'test-id',
        content: '# Test Heading\n**Bold text**\n*Italic text*',
        pinned: false,
        state: MemoState.normal,
      );
      
      final comments = [
        Comment(
          id: 'comment-1',
          content: 'Test comment',
          createTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      // Configure the mock with Mockito
      when(mockApiService.getMemo('test-id')).thenAnswer((_) async => memo);
      when(
        mockApiService.listMemoComments('test-id'),
      ).thenAnswer((_) async => comments);

      // Build the MemoContent widget with the provider overrides
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
            urlLauncherServiceProvider.overrideWithValue(mockUrlLauncherService), // Add override
            memoCommentsProvider.overrideWith(
              (ref, id) => Future.value(comments),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemoContent(memo: memo, memoId: 'test-id'),
            ),
          ),
        ),
      );

      // Allow async operations to complete
      await tester.pumpAndSettle();

      // Use textContaining for more reliable text finding
      expect(find.textContaining('Test Heading'), findsOneWidget);
      expect(find.textContaining('Bold text'), findsOneWidget);
      expect(find.textContaining('Italic text'), findsOneWidget);
      
      // Verify a MarkdownBody widget is present
      expect(find.byType(MarkdownBody), findsOneWidget);
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
          overrides: [
            urlLauncherServiceProvider.overrideWithValue(mockUrlLauncherService), // Add override
          ],
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

      // Look for MarkdownBody which renders our content
      expect(find.byType(MarkdownBody), findsOneWidget);

      // Verify markdown text is rendered somewhere in the widget tree
      expect(find.textContaining('Bold comment'), findsOneWidget);
      expect(find.textContaining('Italic text'), findsOneWidget);
      expect(find.textContaining('Link'), findsOneWidget);
    });

    testWidgets('MemoCard renders markdown correctly', (WidgetTester tester) async {
      // Build the MemoCard widget
      await tester.pumpWidget(
        ProviderScope( // Add ProviderScope for override
          overrides: [
            urlLauncherServiceProvider.overrideWithValue(mockUrlLauncherService), // Add override
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MemoCard(
                id: 'test-id',
                content: '# Card Heading\n**Bold text**\n- List item',
                pinned: false,
              ),
            ),
          ),
        ),
      );

      // Allow async operations to complete
      await tester.pumpAndSettle();

      // Find the MarkdownBody widget
      expect(find.byType(MarkdownBody), findsOneWidget);
      
      // Verify markdown elements are rendered
      expect(find.textContaining('Card Heading'), findsOneWidget);
      expect(find.textContaining('Bold text'), findsOneWidget);
      expect(find.textContaining('List item'), findsOneWidget);
    });

    testWidgets('EditMemoForm toggles between edit and preview modes', (WidgetTester tester) async {
      final memo = Memo(
        id: 'test-id',
        content: '# Test Heading\n**Bold text**',
        pinned: false,
        state: MemoState.normal,
      );

      // Set up necessary provider overrides
      final mockApiService = MockApiService();
      
      // Use Mockito stubbing instead of manual mock method
      when(mockApiService.getMemo('test-id')).thenAnswer((_) async => memo);

      // Build the EditMemoForm widget
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
            urlLauncherServiceProvider.overrideWithValue(mockUrlLauncherService), // Add override
            // Mock the provider that EditMemoForm uses to fetch the entity
            editEntityProvider(
              EntityProviderParams(id: 'test-id', type: 'memo'),
            ).overrideWith((ref) => Future.value(memo)),
          ],
          child: MaterialApp(
            home: Scaffold(
              // Use the new constructor signature
              body: EditMemoForm(
                entityId: 'test-id',
                entityType: 'memo',
                entity: memo,
              ),
            ),
          ),
        ),
      );

      // Wait for the FutureProvider to resolve and the form to build
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

      await tester.pumpAndSettle();

      // Verify main elements are rendered
      expect(find.textContaining('Main heading'), findsOneWidget);
      expect(find.textContaining('Sub heading'), findsOneWidget);
      expect(find.textContaining('bold text'), findsOneWidget);
      expect(find.textContaining('italic text'), findsOneWidget);
      expect(find.textContaining('link'), findsOneWidget);
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

      await tester.pumpAndSettle();

      // Verify elements with special characters are rendered
      expect(find.textContaining('Heading with'), findsOneWidget);
      expect(find.textContaining('emoji'), findsOneWidget);
      expect(find.textContaining('Code with special'), findsOneWidget);
    });
  });
}
