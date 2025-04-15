import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/note_providers.dart'
    as note_providers; // Updated import
import 'package:flutter_memos/screens/item_detail/note_content.dart'; // Updated import
import 'package:flutter_memos/services/base_api_service.dart'; // Updated import
import 'package:flutter_memos/services/url_launcher_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_debug.dart';
import 'memo_content_links_test.mocks.dart'; // Keep mock file name for now

// Generate mocks for services used in this test file
@GenerateNiceMocks([
  MockSpec<BaseApiService>(), // Updated mock type
  MockSpec<UrlLauncherService>(),
])
void main() {
  group('NoteContent Link Handling Tests (Cupertino)', () {
    // Updated group name
    late MockBaseApiService mockApiService; // Updated mock type
    late MockUrlLauncherService mockUrlLauncherService;

    setUp(() {
      mockApiService = MockBaseApiService(); // Updated mock type
      mockUrlLauncherService = MockUrlLauncherService();
      when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');
      when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);
    });

    testWidgets('NoteContent handles link taps correctly', (
      WidgetTester tester,
    ) async {
      // Updated widget name
      debugMarkdown('Starting NoteContent link tap test'); // Updated log

      // Create a note with a link
      final note = NoteItem(
        // Updated type
        id: 'test-id',
        content: '[Example Link](https://example.com)',
        pinned: false,
        state: NoteState.normal, // Updated enum
        createTime: DateTime.now(), // Add required field
        updateTime: DateTime.now(), // Add required field
        displayTime: DateTime.now(), // Add required field
        visibility: NoteVisibility.private, // Add required field
      );

      // Create a mock list of comments
      final mockComments = [
        Comment(
          id: 'comment-1',
          content: 'Test comment',
          createTime: DateTime.now().millisecondsSinceEpoch,
        )
      ];

      debugMarkdown(
        'Building NoteContent with note: ${note.content}',
      ); // Updated log

      // Build NoteContent with the note using a ProviderScope with overrides
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override the noteCommentsProvider to return our mock comments
            note_providers
                .noteCommentsProvider('test-id')
                .overrideWith(
                  // Updated provider name
                  (ref) => Future.value(mockComments),
                ),
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
            apiServiceProvider.overrideWithValue(mockApiService),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: NoteContent(
                note: note,
                noteId: 'test-id', // Pass noteId here
              ), // Updated widget type and params
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      debugDumpAppIfEnabled();

      expect(find.byType(MarkdownBody), findsAtLeastNWidgets(1));

      final richTextWidgets = tester.widgetList<RichText>(
        find.byType(RichText),
      );

      debugMarkdown('\nAll RichText widgets content:');
      for (final widget in richTextWidgets) {
        debugMarkdown('- "${widget.text.toPlainText()}"');
      }

      bool foundLinkText = false;
      try {
        expect(find.textContaining('Example Link'), findsAtLeastNWidgets(1));
        foundLinkText = true;
        debugMarkdown('Found "Example Link" with direct text search');
      } catch (_) {
        debugMarkdown(
          'Direct text search failed, searching in RichText widgets',
        );
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

      final markdownBody = tester.widget<MarkdownBody>(
        find.byType(MarkdownBody).first,
      );
      expect(markdownBody.onTapLink, isNotNull);
      debugMarkdown('MarkdownBody onTapLink is properly configured');
    });

    testWidgets(
      'NoteContent handles different link types (HTTP, HTTPS, note://, etc)', // Updated widget name and link type
        (WidgetTester tester) async {
        final note = NoteItem(
          // Updated type
        id: 'test-id',
        content: '''
[HTTP Link](http://example.com)
[HTTPS Link](https://secure.example.com)
[Note Link](note://12345)
[Email Link](mailto:test@example.com)
[Phone Link](tel:+1234567890)
''',
        pinned: false,
          state: NoteState.normal, // Updated enum
          createTime: DateTime.now(), // Add required field
          updateTime: DateTime.now(), // Add required field
          displayTime: DateTime.now(), // Add required field
          visibility: NoteVisibility.private, // Add required field
      );

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
              note_providers
                  .noteCommentsProvider('test-id')
                  .overrideWith(
                    // Updated provider name
                    (ref) => Future.value(
                      mockComments,
                    ), // Removed id parameter from callback
                  ),
              urlLauncherServiceProvider.overrideWithValue(
                mockUrlLauncherService,
              ),
              apiServiceProvider.overrideWithValue(mockApiService),
          ],
            child: CupertinoApp(
              home: CupertinoPageScaffold(
                child: NoteContent(
                  note: note,
                  noteId: 'test-id', // Pass noteId here
                ), // Updated widget type and params
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final linkTexts = [
        'HTTP Link',
        'HTTPS Link',
          'Note Link', // Updated link text
        'Email Link',
        'Phone Link',
      ];

        for (final linkText in linkTexts) {
          bool foundText = false;
        try {
          await tester.runAsync(() async {
            final finder = find.textContaining(linkText);
            if (finder.evaluate().isNotEmpty) {
              foundText = true;
            }
          });
        } catch (_) {
            // Ignore
        }

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
            reason:
                'Could not find the link text "$linkText" in the NoteContent', // Updated message
        );
      }
    });
  });
}