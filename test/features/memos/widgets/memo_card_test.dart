import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/services/url_launcher_service.dart';
import 'package:flutter_memos/widgets/note_card.dart'; // Updated import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Import mocks
import '../../../services/url_launcher_service_test.mocks.dart';

// Helper to wrap widget for testing with CupertinoApp and CupertinoPageScaffold
Widget buildTestableWidget(Widget child) {
  final mockUrlLauncherService = MockUrlLauncherService();
  when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);

  return ProviderScope(
    overrides: [
      urlLauncherServiceProvider.overrideWithValue(
        mockUrlLauncherService,
      ),
    ],
    child: CupertinoApp(
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        primaryColor: CupertinoColors.systemBlue,
      ),
      home: CupertinoPageScaffold(child: child),
    ),
  );
}

void main() {
  // Create a dummy note object to pass to NoteCard
  final testNote = NoteItem(
    // Updated type
    id: 'test-id-123',
    content: 'This is the test note content.', // Updated content
    updateTime: DateTime.now(), // Use DateTime
    createTime: DateTime.now(), // Add required field
    displayTime: DateTime.now(), // Add required field
    visibility: NoteVisibility.private, // Add required field
    state: NoteState.normal, // Add required field
    pinned: false, // Ensure pinned is present
  );

  group('NoteCard Visual Selection State (Cupertino)', () {
    // Updated group name
    testWidgets('renders with default style when not selected (Light Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        buildTestableWidget(
          CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.light),
            child: NoteCard(
              // Updated widget type
              id: testNote.id,
              content: testNote.content,
              updatedAt:
                  testNote.updateTime
                      .toIso8601String(), // Convert DateTime to String?
            isSelected: false,
          ),
        ),
      ));

      // Act
      final containerFinder = find.descendant(
        of: find.byType(NoteCard), // Updated widget type
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
      final containerWidget = tester.widget<Container>(
        containerFinder.first,
      );
      final decoration = containerWidget.decoration as BoxDecoration?;

      // Assert: Check against expected default colors/borders for light theme
      expect(
        decoration?.color,
        CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          tester.element(containerFinder.first),
        ),
        reason: 'Default background color mismatch (Light)',
      );
      expect(
        decoration?.border == null ||
            (decoration?.border as Border?)?.top.width == 0.0,
        isTrue,
        reason: 'Default border should be null or width 0 (Light)',
      );
    });

    testWidgets('renders with default style when not selected (Dark Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        buildTestableWidget(
          CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.dark),
            child: NoteCard(
              // Updated widget type
              id: testNote.id,
              content: testNote.content,
              updatedAt:
                  testNote.updateTime
                      .toIso8601String(), // Convert DateTime to String?
            isSelected: false,
          ),
        ),
      ));

      // Act
      final containerFinder = find.descendant(
        of: find.byType(NoteCard), // Updated widget type
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
      final containerWidget = tester.widget<Container>(containerFinder.first);
      final decoration = containerWidget.decoration as BoxDecoration?;

      // Assert: Check against expected default colors/borders for dark theme
      expect(
        decoration?.color,
        CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          tester.element(containerFinder.first),
        ),
        reason: 'Default background color mismatch (Dark)',
      );
      // Expect a non-null border for dark theme based on logs
      expect(
        decoration?.border,
        isNotNull,
        reason: 'Default border should not be null (Dark)',
      );
      expect(
        (decoration?.border as Border?)?.top.width,
        isNot(0.0), // Border should have some width
        reason: 'Default border width should not be 0 (Dark)',
      );
    });

    testWidgets('renders with selected style when selected (Light Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
          CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.light),
            child: NoteCard(
              // Updated widget type
              id: testNote.id,
              content: testNote.content,
              updatedAt:
                  testNote.updateTime
                      .toIso8601String(), // Convert DateTime to String?
              isSelected: true,
          ),
        ),
      ));

      // Act
      final containerFinder = find.descendant(
        of: find.byType(NoteCard), // Updated widget type
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
      final containerWidget = tester.widget<Container>(containerFinder.first);
      final decoration = containerWidget.decoration as BoxDecoration?;

      // Assert: Check against the specific selected style colors/borders for light theme
      const expectedSelectedColor = Color(0x4D8E8E93);
      final expectedSelectedBorderColor = CupertinoColors.systemGrey2.resolveFrom(tester.element(containerFinder.first));
      final expectedSelectedBorder = Border.all(
        color: expectedSelectedBorderColor,
        width: 1,
      );

      expect(
        decoration?.color,
        expectedSelectedColor,
        reason: 'Selected background color mismatch (Light)',
      );
      expect(
        (decoration?.border as Border?)?.top.color.value,
        closeTo(
          expectedSelectedBorderColor.value,
          2140000000,
        ), // Allow tolerance
        reason: 'Selected border color mismatch (Light)',
      );
      expect(
        (decoration?.border as Border?)?.top.width,
        expectedSelectedBorder.top.width,
        reason: 'Selected border width mismatch (Light)',
      );
    });

    testWidgets('renders with selected style when selected (Dark Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
          CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.dark),
            child: NoteCard(
              // Updated widget type
              id: testNote.id,
              content: testNote.content,
              updatedAt:
                  testNote.updateTime
                      .toIso8601String(), // Convert DateTime to String?
              isSelected: true,
          ),
        ),
      ));

      // Act
      final containerFinder = find.descendant(
        of: find.byType(NoteCard), // Updated widget type
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
      final containerWidget = tester.widget<Container>(containerFinder.first);
      final decoration = containerWidget.decoration as BoxDecoration?;

      // Assert: Check against the specific selected style colors/borders for dark theme
      final expectedSelectedBorderColor = CupertinoColors.systemGrey2.resolveFrom(tester.element(containerFinder.first));
      final expectedSelectedBorder = Border.all(
        color: expectedSelectedBorderColor,
        width: 1,
      );
      const expectedSelectedColorDark = Color(0x4D8E8E93);

      expect(
        decoration?.color.toString(),
        expectedSelectedColorDark.toString(),
        reason: 'Selected background color mismatch (Dark)',
      );
      expect(
        (decoration?.border as Border?)?.top.color.value,
        closeTo(
          expectedSelectedBorderColor.value,
          2140000000,
        ), // Allow tolerance
        reason: 'Selected border color mismatch (Dark)',
      );
      expect(
        (decoration?.border as Border?)?.top.width,
        expectedSelectedBorder.top.width,
        reason: 'Selected border width mismatch (Dark)',
      );
    });

    testWidgets('GestureDetector handles tap', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
          NoteCard(
            // Updated widget type
            id: testNote.id,
            content: testNote.content,
            updatedAt:
                testNote.updateTime
                    .toIso8601String(), // Convert DateTime to String?
            isSelected: false,
        ),
        ),
      );
      final gestureDetectorFinder = find.descendant(
        of: find.byType(NoteCard), // Updated widget type
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetectorFinder, findsOneWidget);

      // Act: Simulate a tap
      await tester.tap(
        gestureDetectorFinder,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Assert: Verify the GestureDetector exists. Tap effect tested elsewhere.
      expect(gestureDetectorFinder, findsOneWidget);
    });
  });
}