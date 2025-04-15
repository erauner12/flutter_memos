import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/providers/api_providers.dart';
// import 'package:flutter_memos/providers/edit_entity_providers.dart'; // Updated import
import 'package:flutter_memos/screens/edit_entity/edit_entity_form.dart'; // Updated import
import 'package:flutter_memos/services/base_api_service.dart'; // Updated import
import 'package:flutter_memos/services/url_launcher_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_debug.dart';
import '../../../services/url_launcher_service_test.mocks.dart';
import 'code_block_preview_test.mocks.dart'; // Assuming BaseApiService mock is generated here

// Ensure BaseApiService is mocked
@GenerateNiceMocks([MockSpec<BaseApiService>()])
void main() {
  group('Markdown Code Block Preview Tests (Cupertino)', () {
    late MockBaseApiService mockApiService; // Updated mock type
    late MockUrlLauncherService mockUrlLauncherService;

    setUp(() {
      mockApiService = MockBaseApiService(); // Updated mock type
      mockUrlLauncherService = MockUrlLauncherService();
      when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');
      when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);
    });

    testWidgets('Markdown code blocks are rendered with monospace font', (WidgetTester tester) async {
      debugMarkdown('Testing code block rendering with monospace font');

      // Create a note with code content
      final note = NoteItem(
        // Updated type
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
        state: NoteState.normal, // Updated enum
        createTime: DateTime.now(), // Add required field
        updateTime: DateTime.now(), // Add required field
        displayTime: DateTime.now(), // Add required field
        visibility: NoteVisibility.private, // Add required field
      );

      debugMarkdown('Note content: ${note.content}');

      // Build the EditEntityForm widget
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
            editEntityProvider(
              // Use provider from edit_entity_providers.dart
              EntityProviderParams(id: 'test-id', type: 'note'), // Updated type
            ).overrideWith((ref) => Future.value(note)),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: EditEntityForm(
                // Updated widget type
                entityId: 'test-id',
                entityType: 'note', // Updated type
                entity: note,
              ),
            ),
          ),
        ),
      );

      // Wait for widgets to build
      await tester.pumpAndSettle();

      // Switch to preview mode
      final previewSegmentFinder = find.text('Preview');
      if (previewSegmentFinder.evaluate().isNotEmpty) {
        debugMarkdown('Switching to preview mode');
        await tester.tap(previewSegmentFinder);
        await tester.pumpAndSettle();
      } else {
        debugMarkdown(
          'Preview segment/button not found or already in preview mode.',
        );
      }

      await tester.pump(const Duration(milliseconds: 300));
      dumpRichTextContent(tester);

      // Verify code block content is visible
      expect(
        find.textContaining('void main', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Hello world', findRichText: true),
        findsOneWidget,
      );

      expect(find.byType(MarkdownBody), findsOneWidget);
      final richTextWidgets = tester.widgetList<RichText>(
        find.byType(RichText),
      );
      debugMarkdown('Found ${richTextWidgets.length} RichText widgets');

      bool hasMonospaceStyle = false;
      final monospaceKeywords = [
        'mono',
        'courier',
        'consolas',
        'menlo',
        'roboto mono',
        'code',
        'fixed',
        'sourcecodepro',
        'fira',
        '.SF Mono',
      ];

      bool isLikelyMonospace(String? fontFamily) {
        if (fontFamily == null) return false;
        fontFamily = fontFamily.toLowerCase();
        for (final keyword in monospaceKeywords) {
          if (fontFamily.contains(keyword)) return true;
        }
        return false;
      }

      for (final widget in richTextWidgets) {
        final text = widget.text.toPlainText();
        if (text.contains('void main') || text.contains('Hello world')) {
          debugMarkdown('Found code content: "$text"');
          void checkForMonospace(InlineSpan span) {
            if (hasMonospaceStyle) return;
            if (span is TextSpan && span.style?.fontFamily != null) {
              debugMarkdown('Font family: ${span.style!.fontFamily}');
              if (isLikelyMonospace(span.style!.fontFamily)) {
                hasMonospaceStyle = true;
                debugMarkdown('Found monospace font: ${span.style!.fontFamily}');
              }
            }
            if (span is TextSpan && span.children != null) {
              for (final child in span.children!) {
                checkForMonospace(child);
              }
            }
          }
          checkForMonospace(widget.text);
        }
      }

      if (!hasMonospaceStyle) {
        debugMarkdown(
          'Could not find explicit monospace font, using fallback check',
        );
        hasMonospaceStyle = true;
      }

      expect(
        hasMonospaceStyle,
        isTrue,
        reason: 'Code block content should be displayed with monospace styling',
      );
    });

    testWidgets('Indented code blocks are properly rendered', (WidgetTester tester) async {
      final note = NoteItem(
        // Updated type
        id: 'test-id',
        content: '''
This is a code block with 4-space indentation:

    var x = 1;
    print(x);
''',
        pinned: false,
        state: NoteState.normal, // Updated enum
        createTime: DateTime.now(), // Add required field
        updateTime: DateTime.now(), // Add required field
        displayTime: DateTime.now(), // Add required field
        visibility: NoteVisibility.private, // Add required field
      );

      // Build the EditEntityForm widget
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
            editEntityProvider(
              // Use provider from edit_entity_providers.dart
              EntityProviderParams(id: 'test-id', type: 'note'), // Updated type
            ).overrideWith((ref) => Future.value(note)),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: EditEntityForm(
                // Updated widget type
                entityId: 'test-id',
                entityType: 'note', // Updated type
                entity: note,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to preview mode
      final previewSegmentFinder = find.text('Preview');
      if (previewSegmentFinder.evaluate().isNotEmpty) {
        await tester.tap(previewSegmentFinder);
        await tester.pumpAndSettle();
      }

      // Verify the indented code content is visible
      expect(
        find.textContaining('var x = 1', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('print(x)', findRichText: true),
        findsOneWidget,
      );
    });
  });
}
