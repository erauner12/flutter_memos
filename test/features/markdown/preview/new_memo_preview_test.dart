import 'package:flutter/cupertino.dart'; // Use Cupertino
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/screens/new_memo/new_memo_form.dart';
import 'package:flutter_memos/services/url_launcher_service.dart'; // Import url launcher service
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart'; // Import mockito

// Import mocks
import '../../../core/services/url_launcher_service_test.mocks.dart'; // Path to core service mocks
import '../../../utils/test_debug.dart'; // Go up two levels to reach test/utils/

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
          child: const CupertinoApp(
            home: CupertinoPageScaffold(child: NewMemoForm()),
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
          child: const CupertinoApp(
            // Use CupertinoApp
            home: CupertinoPageScaffold(
              // Use CupertinoPageScaffold
              child: SizedBox(
                width: 800,
                height: 600,
                child: SingleChildScrollView(child: NewMemoForm()),
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
      await tester.ensureVisible(find.text('Markdown Help'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Markdown Help'));
      await tester.pumpAndSettle();

      // Help should now be visible
      expect(find.text('Markdown Syntax Guide'), findsOneWidget);
    
      // Check for some help content
      await tester.ensureVisible(find.text('Heading 1'));
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
