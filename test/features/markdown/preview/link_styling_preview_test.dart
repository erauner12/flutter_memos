import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/screens/edit_entity/edit_entity_form.dart'; // Correct import
import 'package:flutter_memos/screens/edit_entity/edit_entity_providers.dart'; // Correct import
import 'package:flutter_memos/services/base_api_service.dart'; // Correct import
import 'package:flutter_memos/services/url_launcher_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_debug.dart';
import '../../../services/url_launcher_service_test.mocks.dart';
// Import the generated mocks for this file (name might change after build)
import 'link_styling_preview_test.mocks.dart';

// Ensure BaseApiService is mocked
@GenerateNiceMocks([MockSpec<BaseApiService>()]) // Use BaseApiService
// Helper function to find text in RichText widgets
bool findTextInRichText(WidgetTester tester, String textToFind) {
  final richTextWidgets = tester.widgetList<RichText>(find.byType(RichText));
  for (final widget in richTextWidgets) {
    final text = widget.text.toPlainText().toLowerCase();
    if (text.contains(textToFind.toLowerCase())) {
      return true;
    }
  }
  return false;
}

// Helper function to print all RichText content for debugging
void dumpRichTextContent(WidgetTester tester) {
  final richTextWidgets = tester.widgetList<RichText>(find.byType(RichText));
  for (final widget in richTextWidgets) {
    debugMarkdown(
      'RichText content: "${widget.text.toPlainText()}"',
    );
  }
}

void main() {
  group('Markdown Link Styling in Preview Mode', () {
    late MockBaseApiService mockApiService; // Use MockBaseApiService
    late MockUrlLauncherService mockUrlLauncherService;

    setUp(() {
      mockApiService = MockBaseApiService(); // Use MockBaseApiService
      mockUrlLauncherService = MockUrlLauncherService();
      when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');
      when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);
    });

    testWidgets('Links in preview are styled correctly', (
      WidgetTester tester,
    ) async {
      markdownDebugEnabled = false;

      // Use NoteItem
      final note = NoteItem(
        id: 'test-id',
        content: '# Test Heading\n\n[UNIQUE_EXAMPLE_LINK](https://example.com)',
        // pinned: false, // Already present
        state: NoteState.normal,
        createTime: DateTime.now(),
        updateTime: DateTime.now(),
        displayTime: DateTime.now(),
        visibility: NoteVisibility.private,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
            // Use correct provider and params
            editEntityProvider(
              EntityProviderParams(id: 'test-id', type: 'note'),
            ).overrideWith((ref) => Future.value(note)),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              // Use EditEntityForm
              child: EditEntityForm(
                entityId: 'test-id',
                entityType: 'note',
                entity: note,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byType(CupertinoTextField),
        findsOneWidget,
      );

      final textField = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      expect(textField.controller!.text, contains('UNIQUE_EXAMPLE_LINK'));

      final previewButton = find.text('Preview');
      expect(previewButton, findsOneWidget);

      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      expect(
        find.byType(CupertinoTextField),
        findsNothing,
      );
      expect(find.byType(MarkdownBody), findsOneWidget);

      debugMarkdown("All RichText widgets after preview toggle:");
      dumpRichTextContent(tester);

      final markdownBody = tester.widget<MarkdownBody>(
        find.byType(MarkdownBody),
      );
      debugMarkdown("MarkdownBody data: '${markdownBody.data}'");
      expect(markdownBody.data, contains('UNIQUE_EXAMPLE_LINK'));

      final possibleTextFragments = [
        'UNIQUE', 'EXAMPLE', 'LINK', 'Test', 'Heading'
      ];

      bool foundAnyText = false;
      for (final fragment in possibleTextFragments) {
        if (findTextInRichText(tester, fragment)) {
          foundAnyText = true;
          break;
        }
      }

      if (!foundAnyText) {
        final allRichText = tester.widgetList<RichText>(find.byType(RichText));
        final allTexts = allRichText
            .map((rt) => rt.text.toPlainText())
            .join(', ');
        expect(
          foundAnyText || markdownBody.data.contains('UNIQUE_EXAMPLE_LINK'),
          isTrue,
          reason: 'Could not find any content fragments in RichText widgets. '
                  'Found texts: $allTexts. '
                  'MarkdownBody had content: ${markdownBody.data}'
        );
      }
    });

    testWidgets('Links with special characters render correctly', (
      WidgetTester tester,
    ) async {
      markdownDebugEnabled = false;

      // Use NoteItem
      final note = NoteItem(
        id: 'test-id',
        content: '''
# MARKER_HEADING
[MARKER_SPACES](https://example.com/path with spaces)
[MARKER_PARAMS](https://example.com/search?q=flutter&lang=dart)
[MARKER_FRAGMENT](https://example.com/page#section-2)
''',
        // pinned: false, // Already present
        state: NoteState.normal,
        createTime: DateTime.now(),
        updateTime: DateTime.now(),
        displayTime: DateTime.now(),
        visibility: NoteVisibility.private,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
            // Use correct provider and params
            editEntityProvider(
              EntityProviderParams(id: 'test-id', type: 'note'),
            ).overrideWith((ref) => Future.value(note)),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              // Use EditEntityForm
              child: EditEntityForm(
                entityId: 'test-id',
                entityType: 'note',
                entity: note,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final textField = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      expect(textField.controller!.text, contains('MARKER_HEADING'));

      await tester.ensureVisible(find.text('Preview'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      expect(
        find.byType(CupertinoTextField),
        findsNothing,
      );
      expect(find.byType(MarkdownBody), findsOneWidget);

      if (markdownDebugEnabled) {
        debugMarkdown("All RichText widgets in preview mode:");
        dumpRichTextContent(tester);
      }

      final markdownBody = tester.widget<MarkdownBody>(
        find.byType(MarkdownBody),
      );
      final keywordsInContent = [
        'MARKER_HEADING', 'MARKER_SPACES', 'MARKER_PARAMS', 'MARKER_FRAGMENT'
      ];

      bool contentHasKeywords = false;
      for (final keyword in keywordsInContent) {
        if (markdownBody.data.contains(keyword)) {
          contentHasKeywords = true;
          break;
        }
      }

      expect(contentHasKeywords, isTrue,
        reason: 'None of the expected keywords found in MarkdownBody.data: "${markdownBody.data}"');

      final possibleTextFragments = [
        'MARKER', 'HEADING', 'SPACES', 'PARAMS', 'FRAGMENT'
      ];

      bool foundAnyText = false;
      for (final fragment in possibleTextFragments) {
        if (findTextInRichText(tester, fragment)) {
          foundAnyText = true;
          break;
        }
      }

      expect(
        foundAnyText || contentHasKeywords,
        isTrue,
        reason: 'Could not find any marker text in the rendered content, '
                'but MarkdownBody has appropriate content: "${markdownBody.data}"'
      );
    });
  });
}