import 'package:flutter/cupertino.dart'; // Use Cupertino
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/screens/edit_entity/edit_entity_form.dart'; // Import EditEntityForm
import 'package:flutter_memos/services/url_launcher_service.dart'; // Import url launcher service
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Import mocks for this file (if any other mocks were needed)
// import 'new_memo_preview_test.mocks.dart'; // Keep if other mocks are generated for this file specifically

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart'; // Import mockito

import '../../../helpers/test_debug.dart'; // Go up two levels to reach test/helpers/
// Import mocks
import '../../../services/url_launcher_service_test.mocks.dart'; // Correct path to UrlLauncherService mock

// Generate mock for UrlLauncherService if not already done elsewhere
@GenerateNiceMocks([MockSpec<UrlLauncherService>()])
void main() {
  group('NewMemoForm Markdown Preview Tests', () {
    late MockUrlLauncherService mockUrlLauncherService;

    setUp(() {
      mockUrlLauncherService = MockUrlLauncherService();
      when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);
    });

    testWidgets('Preview mode shows rendered markdown', (WidgetTester tester) async {
      debugMarkdown('Testing preview mode rendering in NewMemoForm');

      // Build the actual NewMemoForm
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ), // Add override
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: EditEntityForm(
                entityId: '', // Indicate creation with empty string or null
                entityType: 'note',
                entity: NoteItem(
                  // Provide a default empty NoteItem
                  id: '',
                  content: '',
                  pinned: false,
                  state: NoteState.normal,
                  visibility: NoteVisibility.private,
                  createTime: DateTime.now(),
                  updateTime: DateTime.now(),
                  displayTime: DateTime.now(),
                ),
              ),
            ),
          ), // Use Cupertino
        ),
      );

      // Enter some markdown text
      const testMarkdown = '# Test Heading\n**Bold text**\n*Italic text*';
      debugMarkdown('Entering text: $testMarkdown');
      await tester.enterText(
        find.byType(CupertinoTextField),
        testMarkdown,
      ); // Use CupertinoTextField

      // Pump after text entry so widget can rebuild
      await tester.pumpAndSettle();

      // Initially we should see the TextField, not the MarkdownBody
      expect(
        find.byType(CupertinoTextField),
        findsOneWidget,
      ); // Use CupertinoTextField
      expect(find.byType(MarkdownBody), findsNothing);
      debugMarkdown('Initial state: TextField visible, MarkdownBody not visible');

      // Tap "Preview" button to toggle `_previewMode`
      debugMarkdown('Tapping Preview button');
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Now the text field should be replaced by MarkdownBody
      expect(
        find.byType(CupertinoTextField),
        findsNothing,
      ); // Use CupertinoTextField
      expect(find.byType(MarkdownBody), findsOneWidget);
      debugMarkdown('After toggle: TextField hidden, MarkdownBody visible');

      // Debug output the rendered content
      dumpRichTextContent(tester);

      // Check that the typed markdown is rendered
      expect(find.textContaining('Test Heading'), findsOneWidget);
      expect(find.textContaining('Bold text'), findsOneWidget);
      expect(find.textContaining('Italic text'), findsOneWidget);
      debugMarkdown('Found all expected content in the rendered markdown');
    });

    testWidgets('Markdown help toggle displays help information', (WidgetTester tester) async {
      // Build the form with a fixed-height container to prevent overflow errors
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            urlLauncherServiceProvider.overrideWithValue(
              mockUrlLauncherService,
            ), // Add override
          ],
          child: CupertinoApp(
            // Use CupertinoApp
            home: CupertinoPageScaffold(
              // Use CupertinoPageScaffold
              child: SizedBox(
                width: 800,
                height: 600,
                child: EditEntityForm(
                  // Use EditEntityForm
                  entityId: '', // Indicate creation
                  entityType: 'note',
                  entity: NoteItem(
                    // Provide a default empty NoteItem
                    id: '',
                    content: '',
                    pinned: false,
                    state: NoteState.normal,
                    visibility: NoteVisibility.private,
                    createTime: DateTime.now(),
                    updateTime: DateTime.now(),
                    displayTime: DateTime.now(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Initially help should not be shown
      expect(find.text('Markdown Syntax Guide'), findsNothing);

      // Pump and settle to ensure widgets are properly laid out
      await tester.pumpAndSettle();

      // Tap the help button with some extra pumps to ensure it's visible
      // Use ensureVisible to handle cases where the button might be slightly off-screen initially
      // within the SizedBox constraints, although less likely now without the extra scroll view.
      await tester.ensureVisible(find.text('Markdown Help'));
      await tester.pumpAndSettle(); // Allow time for scrolling if needed
      await tester.tap(find.text('Markdown Help'));
      await tester.pumpAndSettle(); // Wait for state update and rebuild

      // Help should now be visible
      expect(find.text('Markdown Syntax Guide'), findsOneWidget);

      // Check for some help content
      // Use ensureVisible again for robustness
      await tester.ensureVisible(find.text('Heading 1'));
      await tester.pumpAndSettle();
      expect(find.text('Heading 1'), findsOneWidget);
      expect(find.text('Bold text'), findsOneWidget);

      // Now find and tap the hide help button
      await tester.ensureVisible(find.text('Hide Help'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hide Help'));
      await tester.pumpAndSettle();

      // Help should be hidden again
      expect(find.text('Markdown Syntax Guide'), findsNothing);
    });
  });
}
