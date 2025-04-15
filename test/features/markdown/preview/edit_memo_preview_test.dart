import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/screens/edit_entity/edit_entity_form.dart'; // Updated import
import 'package:flutter_memos/screens/edit_entity/edit_entity_providers.dart'; // Updated import
import 'package:flutter_memos/services/base_api_service.dart'; // Updated import
import 'package:flutter_memos/services/url_launcher_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_debug.dart';
import '../../../services/url_launcher_service_test.mocks.dart';
import 'edit_memo_preview_test.mocks.dart'; // Keep mock file name for now

// Ensure BaseApiService is mocked
@GenerateNiceMocks([MockSpec<BaseApiService>()])
void main() {
  group('EditEntityForm Markdown Preview Tests', () {
    // Updated group name
    late MockBaseApiService mockApiService; // Updated mock type
    late MockUrlLauncherService mockUrlLauncherService;

    setUp(() {
      mockApiService = MockBaseApiService(); // Updated mock type
      mockUrlLauncherService = MockUrlLauncherService();
      when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');
      when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);
    });

    testWidgets('EditEntityForm markdown help toggle works', (
      WidgetTester tester,
    ) async {
      // Updated form name
      debugMarkdown(
        'Testing markdown help toggle in EditEntityForm',
      ); // Updated log

      final note = NoteItem(
        // Updated type
        id: 'test-id',
        content: 'Test content',
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
              child: SizedBox(
                width: 800,
                height: 600,
                child: EditEntityForm(
                  // Updated widget type
                  entityId: 'test-id',
                  entityType: 'note', // Updated type
                  entity: note,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially help should not be shown
      expect(find.text('Markdown Syntax Guide'), findsNothing);
      debugMarkdown('Initially, Markdown Syntax Guide is not shown');

      // Tap the help button
      debugMarkdown('Tapping Markdown Help button');
      await tester.tap(find.text('Markdown Help'));
      await tester.pumpAndSettle();

      // Help should now be visible
      expect(find.text('Markdown Syntax Guide'), findsOneWidget);
      debugMarkdown('Markdown Syntax Guide is now visible');

      expect(find.text('Heading 1'), findsOneWidget);
      expect(find.text('Bold text'), findsOneWidget);
      expect(find.text('Italic text'), findsOneWidget);
      debugMarkdown('Found expected help content: Heading 1, Bold text, Italic text');

      // Tap the hide help button
      debugMarkdown('Tapping Hide Help button');
      await tester.tap(find.text('Hide Help'));
      await tester.pumpAndSettle();

      // Help should be hidden again
      expect(find.text('Markdown Syntax Guide'), findsNothing);
      debugMarkdown('Markdown Syntax Guide is hidden again');
    });

    testWidgets('Live preview updates when content changes', (WidgetTester tester) async {
      debugMarkdown('Testing live preview updates with content changes');

      final note = NoteItem(
        // Updated type
        id: 'test-id',
        content: 'Initial content',
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
              child: SizedBox(
                width: 800,
                height: 600,
                child: EditEntityForm(
                  // Updated widget type
                  entityId: 'test-id',
                  entityType: 'note', // Updated type
                  entity: note,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First switch to preview mode
      debugMarkdown('Tapping Preview button');
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Initial content should be shown
      expect(find.text('Initial content'), findsOneWidget);
      debugMarkdown('Initial content is displayed in preview');

      // Switch back to edit mode
      debugMarkdown('Tapping Edit button to switch back to edit mode');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Change the content
      debugMarkdown('Entering new text: # New Heading\\n**Bold**');
      await tester.enterText(
        find.byType(CupertinoTextField),
        '# New Heading\n**Bold**',
      );
      await tester.pump();

      // Switch to preview mode again
      debugMarkdown('Tapping Preview button again');
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Updated content should be shown in preview
      expect(find.text('New Heading'), findsOneWidget);
      expect(find.text('Bold'), findsOneWidget);
      expect(find.text('Initial content'), findsNothing);
      debugMarkdown('Updated content (New Heading, Bold) is displayed, initial content is not');
    });

    testWidgets('Toggle between edit and preview modes works correctly', (WidgetTester tester) async {
      debugMarkdown('Testing toggle between edit and preview modes');

      final note = NoteItem(
        // Updated type
        id: 'test-id',
        content: '# Test Heading\n**Bold text**',
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
              child: SizedBox(
                width: 800,
                height: 600,
                child: EditEntityForm(
                  // Updated widget type
                  entityId: 'test-id',
                  entityType: 'note', // Updated type
                  entity: note,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially in edit mode - TextField should be visible
      expect(
        find.byType(CupertinoTextField),
        findsOneWidget,
      );
      expect(find.byType(MarkdownBody), findsNothing);
      debugMarkdown('Initially in edit mode, TextField is visible, MarkdownBody is not');

      // Find and tap the Preview button
      debugMarkdown('Tapping Preview button');
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Now should be in preview mode - MarkdownBody should be visible, TextField hidden
      expect(
        find.byType(CupertinoTextField),
        findsNothing,
      );
      expect(find.byType(MarkdownBody), findsOneWidget);
      debugMarkdown('Now in preview mode, MarkdownBody is visible, TextField is not');

      // Verify markdown content is rendered
      expect(find.textContaining('Test Heading'), findsOneWidget);
      expect(find.textContaining('Bold text'), findsOneWidget);
      debugMarkdown('Verified markdown content (Test Heading, Bold text) is rendered');

      // Go back to edit mode
      debugMarkdown('Tapping Edit button to return to edit mode');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Should be back in edit mode
      expect(
        find.byType(CupertinoTextField),
        findsOneWidget,
      );
      expect(find.byType(MarkdownBody), findsNothing);
      debugMarkdown('Back in edit mode, TextField is visible, MarkdownBody is not');
    });
  });
}
