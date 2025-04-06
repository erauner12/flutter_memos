import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/screens/memos/memo_list_item.dart';
import 'package:flutter_memos/screens/memos/memos_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to create a list of dummy memos
List<Memo> createDummyMemos(int count) {
  return List.generate(count, (i) {
    final now = DateTime.now();
    final updateTime = now.subtract(Duration(minutes: i)).toIso8601String();
    return Memo(
      id: 'memo_$i',
      content: 'Dummy Memo Content $i',
      pinned: false,
      state: MemoState.normal,
      updateTime: updateTime,
      createTime: updateTime,
    );
  });
}

// Mock Notifier extending the actual Notifier
class MockMemosNotifier extends MemosNotifier {
  // Constructor needs to call super, passing the ref and setting the skip flag
  MockMemosNotifier(super.ref, MemosState initialState)
    : super(skipInitialFetchForTesting: true) {
    // Manually set the state after initialization
    state = initialState;
  }

  // Override methods that might be called during the test if needed,
  // otherwise, they inherit the base implementation (which might try to fetch)
  @override
  Future<void> refresh() async {
    // No-op for mock
  }

  @override
  Future<void> fetchMoreMemos() async {
    // No-op for mock
  }
}

// Modify buildTestableWidget to accept the container
Widget buildTestableWidget(Widget child, ProviderContainer container) {
  // Keep ProviderScope so the widget can lookup providers
  // Link it to the container created in the test setup
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: child,
      // Define routes needed for navigation actions within MemoListItem (like edit)
      routes: {
        '/edit-entity': (context) => const Scaffold(body: Text('Edit Screen')),
        '/memo-detail': (context) => const Scaffold(body: Text('Detail Screen')),
        '/new-memo': (context) => const Scaffold(body: Text('New Memo Screen')),
      },
    ),
  );
}

void main() {
  final dummyMemos = createDummyMemos(3); // Create 3 dummy memos for testing
  late ProviderContainer container; // Declare container

  // Use setUp to create the container before each test
  setUp(() {
    final initialState = const MemosState().copyWith(
      memos: dummyMemos,
      isLoading: false,
      hasReachedEnd: true,
      totalLoaded: dummyMemos.length,
    );

    container = ProviderContainer(
      overrides: [
        // Override the actual notifier with our mock builder
        memosNotifierProvider.overrideWith(
          (ref) => MockMemosNotifier(ref, initialState),
        ),
        // Ensure UI providers start in a known state
        ui_providers.memoMultiSelectModeProvider.overrideWith((ref) => false),
        ui_providers.selectedMemoIdsForMultiSelectProvider.overrideWith((ref) => {}),
        ui_providers.selectedMemoIdProvider.overrideWith((ref) => null),
        // Explicitly set the filter key for consistent AppBar title
        filterKeyProvider.overrideWith((ref) => 'all'),
      ],
    );
  });

  // Use tearDown to dispose the container after each test
  tearDown(() {
    container.dispose();
  });

  testWidgets('MemosScreen displays standard AppBar and no checkboxes initially', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemosScreen(), container));
    await tester.pumpAndSettle(); // Wait for initial build

    // Act & Assert
    expect(find.byType(AppBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Memos (ALL)'),
      ),
      findsOneWidget,
    );

    // Verify "Select Memos" button exists
    expect(find.byTooltip('Select Memos'), findsOneWidget);
    expect(find.byIcon(Icons.select_all), findsOneWidget);

    // Verify multi-select actions are NOT present
    expect(find.byIcon(Icons.close), findsNothing); // Cancel button
    expect(find.textContaining('Selected'), findsNothing); // "X Selected" text
    expect(find.widgetWithIcon(AppBar, Icons.delete), findsNothing); // Delete action
    expect(find.widgetWithIcon(AppBar, Icons.archive), findsNothing); // Archive action

    // Verify no Checkboxes are present within list items
    expect(find.descendant(of: find.byType(MemoListItem), matching: find.byType(Checkbox)), findsNothing);

    // Verify Slidable/Dismissible are present
    expect(find.descendant(of: find.byType(MemoListItem), matching: find.byType(Slidable)), findsWidgets);
    expect(find.descendant(of: find.byType(MemoListItem), matching: find.byType(Dismissible)), findsWidgets);
  });

  testWidgets('MemosScreen enters multi-select mode on button tap', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemosScreen(), container));
    await tester.pumpAndSettle();

    // Act: Tap the "Select Memos" button
    await tester.tap(find.byTooltip('Select Memos'));
    await tester.pumpAndSettle();

    // Assert
    // Use the container created in setUp
    expect(container.read(ui_providers.memoMultiSelectModeProvider), isTrue);

    // Verify AppBar changes
    expect(find.widgetWithIcon(AppBar, Icons.close), findsOneWidget); // Cancel button
    expect(find.text('0 Selected'), findsOneWidget); // Initial count
    expect(find.widgetWithIcon(AppBar, Icons.delete), findsOneWidget); // Delete action
    expect(find.widgetWithIcon(AppBar, Icons.archive), findsOneWidget); // Archive action

    // Verify standard title and select button are gone from AppBar
    expect(find.widgetWithText(AppBar, 'Memos (ALL)'), findsNothing);
    expect(find.byTooltip('Select Memos'), findsNothing);

    // Verify Checkboxes appear for each item
    expect(find.descendant(of: find.byType(MemoListItem), matching: find.byType(Checkbox)), findsNWidgets(dummyMemos.length));

    // Verify Slidable/Dismissible are gone
    expect(find.descendant(of: find.byType(MemoListItem), matching: find.byType(Slidable)), findsNothing);
    expect(find.descendant(of: find.byType(MemoListItem), matching: find.byType(Dismissible)), findsNothing);
  });

  testWidgets('MemosScreen selects/deselects memo via Checkbox tap', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemosScreen(), container));
    await tester.pumpAndSettle();
    // Enter multi-select mode
    await tester.tap(find.byTooltip('Select Memos'));
    await tester.pumpAndSettle();

    // Find the first checkbox
    final firstCheckboxFinder = find.descendant(
      of: find.byType(MemoListItem).first,
      matching: find.byType(Checkbox),
    );
    expect(firstCheckboxFinder, findsOneWidget);

    // Act: Tap the first checkbox to select
    await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();

    // Assert: Selection state updated
    // Use the container created in setUp
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      contains(dummyMemos[0].id),
    );
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider).length,
      1,
    );
    expect(find.text('1 Selected'), findsOneWidget);

    // Act: Tap the first checkbox again to deselect
    await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();

    // Assert: Selection state updated
    // Use the container created in setUp
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      isNot(contains(dummyMemos[0].id)),
    );
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      isEmpty,
    );
    expect(find.text('0 Selected'), findsOneWidget);
  });

  testWidgets('MemosScreen selects/deselects memo via item tap in multi-select mode', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemosScreen(), container));
    await tester.pumpAndSettle();

    // Enter multi-select mode
    await tester.tap(find.byTooltip('Select Memos'));
    await tester.pumpAndSettle();

    // Find the first MemoListItem
    final firstItemFinder = find.byType(MemoListItem).first;

    // Act: Tap the first item to select
    await tester.tap(firstItemFinder);
    await tester.pumpAndSettle();

    // Assert: Selection state updated
    // Use the container created in setUp
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      contains(dummyMemos[0].id),
    );
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider).length,
      1,
    );
    expect(find.text('1 Selected'), findsOneWidget);

    // Act: Tap the first item again to deselect
    await tester.tap(firstItemFinder);
    await tester.pumpAndSettle();

    // Assert: Selection state updated
    // Use the container created in setUp
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      isNot(contains(dummyMemos[0].id)),
    );
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      isEmpty,
    );
    expect(find.text('0 Selected'), findsOneWidget);
  });

  testWidgets('MemosScreen exits multi-select mode via Cancel button', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemosScreen(), container));
    await tester.pumpAndSettle();
    
    // Enter multi-select mode and select an item
    await tester.tap(find.byTooltip('Select Memos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MemoListItem).first);
    await tester.pumpAndSettle();
    
    expect(container.read(ui_providers.memoMultiSelectModeProvider), isTrue);
    expect(container.read(ui_providers.selectedMemoIdsForMultiSelectProvider), isNotEmpty);

    // Act: Tap the Cancel button (AppBar leading)
    await tester.tap(find.widgetWithIcon(AppBar, Icons.close));
    
    // Add an extra pump cycle to ensure state updates propagate
    await tester.pump();
    
    // Then complete the animation
    await tester.pumpAndSettle();

    // Assert: Exited multi-select mode
    // Use the container created in setUp
    expect(container.read(ui_providers.memoMultiSelectModeProvider), isFalse);
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      isEmpty,
    );

    // Verify AppBar reverts
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Memos (ALL)'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Select Memos'), findsOneWidget);
    expect(find.widgetWithIcon(AppBar, Icons.close), findsNothing);
    expect(find.textContaining('Selected'), findsNothing);

    // Verify Checkboxes are gone
    expect(find.descendant(of: find.byType(MemoListItem), matching: find.byType(Checkbox)), findsNothing);

    // Verify Slidable/Dismissible are back
    expect(find.descendant(of: find.byType(MemoListItem), matching: find.byType(Slidable)), findsWidgets);
    expect(find.descendant(of: find.byType(MemoListItem), matching: find.byType(Dismissible)), findsWidgets);
  });
}