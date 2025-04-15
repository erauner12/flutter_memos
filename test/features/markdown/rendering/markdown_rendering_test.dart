import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/note_item.dart'; // Use NoteItem
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/note_providers.dart'
    as note_providers; // Use note_providers
import 'package:flutter_memos/screens/edit_entity/edit_entity_form.dart'; // Use EditEntityForm
import 'package:flutter_memos/screens/edit_entity/edit_entity_providers.dart'; // Use edit_entity_providers
import 'package:flutter_memos/screens/item_detail/note_content.dart'; // Use NoteContent
import 'package:flutter_memos/services/base_api_service.dart'; // Use BaseApiService
import 'package:flutter_memos/services/url_launcher_service.dart';
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_memos/widgets/note_card.dart'; // Use NoteCard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_debug.dart';
import '../../../services/url_launcher_service_test.mocks.dart';
// Import the generated mocks for this file
import 'markdown_rendering_test.mocks.dart';

// Annotation to generate nice mock for BaseApiService
@GenerateNiceMocks([MockSpec<BaseApiService>()])
void main() {
  late MockBaseApiService mockApiService; // Use MockBaseApiService
  late MockUrlLauncherService mockUrlLauncherService;

  group('Markdown Rendering Tests', () {
    setUp(() {
      mockApiService = MockBaseApiService(); // Use MockBaseApiService
      mockUrlLauncherService = MockUrlLauncherService();

      when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');
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

      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: SingleChildScrollView(
              child: MarkdownBody(data: markdownText),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      dumpRichTextContent(tester);

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

      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('Markdown renders with custom styling', (WidgetTester tester) async {
      const markdownText = '**Bold text with custom color**';
      final customColor = CupertinoColors.systemRed;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: MarkdownBody(
              data: markdownText,
              styleSheet: MarkdownStyleSheet(
                strong: TextStyle(color: customColor, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.textContaining('Bold text with custom color'),
        findsOneWidget,
      );

      final richTextWidgets = tester.widgetList<RichText>(
        find.byType(RichText),
      );

      debugMarkdown(
        '\nChecking ${richTextWidgets.length} RichText widgets for styled text:',
      );

      bool foundStyledText = false;
      void checkForRedStyling(InlineSpan span) {
        if (span is TextSpan) {
          final style = span.style;
          final text = span.text ?? '';
          if (style?.color != null) {
            debugMarkdown('Text: "$text", Color: ${style?.color}');
          }
          if (style?.color == customColor) {
            debugMarkdown('Found red text: "$text"');
            foundStyledText = true;
          }
          if (span.children != null) {
            for (final child in span.children!) {
              checkForRedStyling(child);
            }
          }
        }
      }

      for (final widget in richTextWidgets) {
        checkForRedStyling(widget.text);
        if (foundStyledText) break;
      }

      if (!foundStyledText) {
        for (final widget in richTextWidgets) {
          final plainText = widget.text.toPlainText();
          if (plainText.contains('Bold text with custom color')) {
            debugMarkdown('Found matching text: $plainText');
            void checkTextSpanColor(InlineSpan span) {
              if (span is TextSpan) {
                final color = span.style?.color;
                if (color != null) {
                  debugMarkdown(
                    'Color components: R=${color.red}, G=${color.green}, B=${color.blue}',
                  );
                  if (color.red > color.green && color.red > color.blue) {
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

    testWidgets('NoteContent renders markdown correctly', (
      WidgetTester tester,
    ) async {
      // Set up note and comments data
      final note = NoteItem(
        id: 'test-id',
        content: '# Test Heading\n**Bold text**\n*Italic text*',
        pinned: false,
        state: NoteState.normal,
        createTime: DateTime.now(),
        updateTime: DateTime.now(),
        displayTime: DateTime.now(),
        visibility: NoteVisibility.private,
      );

      final comments = [
        Comment(
          id: 'comment-1',
          content: 'Test comment',
          createTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      // Configure the mock with Mockito
      when(mockApiService.getNote('test-id')).thenAnswer((_) async => note);
      when(
        mockApiService.listNoteComments('test-id'),
      ).thenAnswer((_) async => comments);

      // Build the NoteContent widget with the provider overrides
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
            note_providers
                .noteCommentsProvider('test-id')
                .overrideWith((ref) => Future.value(comments),
            ),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: NoteContent(note: note, noteId: 'test-id'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Test Heading'), findsOneWidget);
      expect(find.textContaining('Bold text'), findsOneWidget);
      expect(find.textContaining('Italic text'), findsOneWidget);

      expect(find.byType(MarkdownBody), findsOneWidget);
    });

    testWidgets('CommentCard renders markdown correctly', (WidgetTester tester) async {
      final comment = Comment(
        id: 'comment-id',
        content: '**Bold comment**\n*Italic text*\n[Link](https://example.com)',
        createTime: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: CommentCard(
                comment: comment,
                memoId: 'test-note-id', // Keep memoId as expected by CommentCard
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.textContaining('Bold comment'), findsOneWidget);
      expect(find.textContaining('Italic text'), findsOneWidget);
      expect(find.textContaining('Link'), findsOneWidget);
    });

    testWidgets('NoteCard renders markdown correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: NoteCard(
                // Use NoteCard
                id: 'test-id',
                content: '# Card Heading\n**Bold text**\n- List item',
                pinned: false,
                updatedAt: DateTime.now().toIso8601String(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.textContaining('Card Heading'), findsOneWidget);
      expect(find.textContaining('Bold text'), findsOneWidget);
      expect(find.textContaining('List item'), findsOneWidget);
    });

    testWidgets('EditEntityForm toggles between edit and preview modes', (
      WidgetTester tester,
    ) async {
      final note = NoteItem(
        id: 'test-id',
        content: '# Test Heading\n**Bold text**',
        pinned: false,
        state: NoteState.normal,
        createTime: DateTime.now(),
        updateTime: DateTime.now(),
        displayTime: DateTime.now(),
        visibility: NoteVisibility.private,
      );

      when(mockApiService.getNote('test-id')).thenAnswer((_) async => note);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
            editEntityProvider(
              EntityProviderParams(id: 'test-id', type: 'note'),
            ).overrideWith((ref) => Future.value(note)),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: EditEntityForm(
                // Use EditEntityForm
                entityId: 'test-id',
                entityType: 'note',
                entity: note,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CupertinoTextField), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);

      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoTextField), findsNothing);
      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.textContaining('Test Heading'), findsOneWidget);
      expect(find.textContaining('Bold text'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoTextField), findsOneWidget);
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

      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: SingleChildScrollView(
              child: MarkdownBody(data: complexMarkdown),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Main heading'), findsOneWidget);
      expect(find.textContaining('Sub heading'), findsOneWidget);
      expect(find.textContaining('bold text'), findsOneWidget);
      expect(find.textContaining('italic text'), findsOneWidget);
      expect(find.textContaining('link'), findsOneWidget);
      expect(find.textContaining('Nested list item'), findsOneWidget);
      expect(find.textContaining('code'), findsOneWidget);
      expect(find.textContaining('quote'), findsOneWidget);
    });

    testWidgets('Special characters in markdown are handled correctly', (WidgetTester tester) async {
      const specialCharsMarkdown = '''
# Heading with & < > " '
Text with emoji 😊 and symbols © ®
```
Code with special <html> &tags
```
''';

      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: MarkdownBody(data: specialCharsMarkdown),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Heading with'), findsOneWidget);
      expect(find.textContaining('emoji'), findsOneWidget);
      expect(find.textContaining('Code with special'), findsOneWidget);
    });
  });
}
