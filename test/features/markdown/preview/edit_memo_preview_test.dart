import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart'; // Import api provider
import 'package:flutter_memos/screens/edit_memo/edit_memo_form.dart';
import 'package:flutter_memos/screens/edit_memo/edit_memo_providers.dart'; // Add this import
import 'package:flutter_memos/services/url_launcher_service.dart'; // Import url launcher service
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart'; // Import mockito

// Import mocks
import '../rendering/markdown_rendering_test.mocks.dart'; // Corrected path
import '../../../core/services/url_launcher_service_test.mocks.dart'; // Corrected path
import '../../../utils/test_debug.dart'; // Corrected path

void main() {
  group('EditMemoForm Markdown Preview Tests', () {
    late MockApiService mockApiService;
    late MockUrlLauncherService mockUrlLauncherService;

    setUp(() {
      mockApiService = MockApiService();
      mockUrlLauncherService = MockUrlLauncherService();
      when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');
      when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);
    });

    testWidgets('EditMemoForm markdown help toggle works', (WidgetTester tester) async {
      debugMarkdown('Testing markdown help toggle in EditMemoForm');

      final memo = Memo(
        id: 'test-id',
        content: 'Test content',
        pinned: false,
        state: MemoState.normal,
      );

      // Build the EditMemoForm widget
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
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
                entity: memo, // Add the required entity parameter
              ),
            ),
          ),
        ),
      );

      // Wait for FutureProvider to resolve
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
      
      // Check for some help content
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

      final memo = Memo(
        id: 'test-id',
        content: 'Initial content',
        pinned: false,
        state: MemoState.normal,
      );

      // Build the EditMemoForm widget
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
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
                entity: memo, // Add the required entity parameter
              ),
            ),
          ),
        ),
      );

      // Wait for FutureProvider to resolve
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
      await tester.enterText(find.byType(TextField), '# New Heading\n**Bold**');
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

      final memo = Memo(
        id: 'test-id',
        content: '# Test Heading\n**Bold text**',
        pinned: false,
        state: MemoState.normal,
      );

      // Build the EditMemoForm widget
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApiService),
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ),
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
                entity: memo, // Add the required entity parameter
              ),
            ),
          ),
        ),
      );

      // Wait for FutureProvider to resolve
      await tester.pumpAndSettle();

      // Initially in edit mode - TextField should be visible
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);
      debugMarkdown('Initially in edit mode, TextField is visible, MarkdownBody is not');

      // Find and tap the Preview button
      debugMarkdown('Tapping Preview button');
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Now should be in preview mode - MarkdownBody should be visible, TextField hidden
      expect(find.byType(TextField), findsNothing);
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
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);
      debugMarkdown('Back in edit mode, TextField is visible, MarkdownBody is not');
    });
  });
}