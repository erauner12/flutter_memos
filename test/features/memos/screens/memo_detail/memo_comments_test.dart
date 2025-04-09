import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/comment_providers.dart'
    as comment_providers;
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/screens/memo_detail/memo_comments.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart';
import 'package:flutter_memos/services/api_service.dart' as api_service;
// Remove the direct import of ApiService if it causes ambiguity
// import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Keep if Slidable is used
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate nice mock for ApiService
@GenerateNiceMocks([MockSpec<api_service.ApiService>()])
// Import the generated mocks file
import 'memo_comments_test.mocks.dart';

// Helper to create a list of dummy comments
List<Comment> createDummyComments(int count) {
  return List.generate(count, (i) {
    return Comment(
      id: 'comment_$i',
      content: 'Dummy Comment Content $i',
      createTime: DateTime.now().subtract(Duration(minutes: i)).millisecondsSinceEpoch,
      pinned: false,
    );
  });
}

// Modify buildTestableWidget to accept the container and use CupertinoApp
Widget buildTestableWidget(Widget child, ProviderContainer container) {
  // Keep ProviderScope so the widget can lookup providers
  // Link it to the container created in the test setup
  return UncontrolledProviderScope(
    container: container,
    child: CupertinoApp(
      // Use CupertinoApp
      home: CupertinoPageScaffold(
        child: child,
      ), // Wrap in CupertinoPageScaffold
      // Define routes needed for navigation actions within CommentCard (like edit)
      routes: {
        '/edit-entity':
            (context) => const CupertinoPageScaffold(
              child: Center(child: Text('Edit Screen')),
            ),
      },
    ),
  );
}

void main() {
  const testMemoId = 'test-memo-1';
  final dummyComments = createDummyComments(3); // Create 3 dummy comments
  late ProviderContainer container; // Declare container
  late MockApiService mockApiService;

  // Use setUp to create the container before each test
  setUp(() {
    mockApiService = MockApiService();

    // Add stub for apiBaseUrl property
    when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');

    // Create stub responses for the mock API service
    when(
      mockApiService.listMemoComments(any),
    ).thenAnswer((_) async => dummyComments);

    container = ProviderContainer(
      overrides: [
        // Override the comments provider for the specific memoId
        memoCommentsProvider(testMemoId).overrideWith(
          (ref) => Future.value(dummyComments), // Provide initial data directly
        ),
        // Ensure UI providers start in a known state
        ui_providers.commentMultiSelectModeProvider.overrideWith(
          (ref) => false,
        ),
        ui_providers.selectedCommentIdsForMultiSelectProvider.overrideWith(
          (ref) => {},
        ),
        ui_providers.selectedCommentIndexProvider.overrideWith((ref) => -1),
        comment_providers.hiddenCommentIdsProvider.overrideWith((ref) => {}),
        hidePinnedProvider.overrideWith((ref) => false),
        apiServiceProvider.overrideWithValue(mockApiService),
      ],
    );
  });

  // Use tearDown to dispose the container after each test
  tearDown(() {
    container.dispose();
  });

  testWidgets('MemoComments displays list of comments', (WidgetTester tester) async {
    // Arrange
    // Pass the container to the helper
    await tester.pumpWidget(
      buildTestableWidget(const MemoComments(memoId: testMemoId), container),
    );
    await tester.pumpAndSettle(); // Wait for FutureProvider

    // Act & Assert
    // Verify no CupertinoSwitch/Checkbox are present within CommentCards
    expect(
      find.descendant(
        of: find.byType(CommentCard),
        matching: find.byType(CupertinoSwitch), // Check for CupertinoSwitch
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(CommentCard),
        matching: find.byType(CupertinoCheckbox), // Check for CupertinoCheckbox
      ),
      findsNothing,
    );


    // Verify Slidable is present (if still used)
    expect(
      find.descendant(
        of: find.byType(CommentCard),
        matching: find.byType(Slidable),
      ),
      findsWidgets, // Assuming Slidable is kept
    );
  });

  testWidgets(
    'MemoComments enters multi-select mode and shows checkboxes/switches',
    (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const MemoComments(memoId: testMemoId), container),
    );
    await tester.pumpAndSettle();

    // Act: Simulate entering multi-select mode by directly setting the provider
    container.read(ui_providers.commentMultiSelectModeProvider.notifier).state = true;
    await tester.pumpAndSettle(); // Rebuild with multi-select mode active

    // Assert
    // Use the container created in setUp
    expect(container.read(ui_providers.commentMultiSelectModeProvider), isTrue);

      // Verify CupertinoSwitch/Checkbox appear for each item
      // Assuming CupertinoCheckbox is used for multi-select in CommentCard
      final multiSelectWidgetFinder = find.descendant(
        of: find.byType(CommentCard),
        matching: find.byType(
          CupertinoCheckbox,
        ), // Changed from CupertinoSwitch
      );
      expect(multiSelectWidgetFinder,
      findsNWidgets(dummyComments.length),
    );

    // Verify Slidable is gone
    expect(
      find.descendant(
        of: find.byType(CommentCard),
        matching: find.byType(Slidable),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'MemoComments selects/deselects comment via Checkbox/Switch tap',
    (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const MemoComments(memoId: testMemoId), container),
    );
    await tester.pumpAndSettle();

    // Enter multi-select mode
    container.read(ui_providers.commentMultiSelectModeProvider.notifier).state = true;
    await tester.pumpAndSettle();

      // Find the first multi-select widget (Assuming Checkbox)
      final firstMultiSelectWidgetFinder = find.descendant(
      of: find.byType(CommentCard).first,
        matching: find.byType(
          CupertinoCheckbox,
        ), // Changed from CupertinoSwitch
    );
      expect(firstMultiSelectWidgetFinder, findsOneWidget);

    final expectedCommentId = '$testMemoId/${dummyComments[0].id}';

      // Act: Tap the first widget to select
      await tester.tap(firstMultiSelectWidgetFinder);
    await tester.pumpAndSettle();

    // Assert: Selection state updated
    // Use the container created in setUp
    expect(
      container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
      contains(expectedCommentId),
    );
    expect(
      container
          .read(ui_providers.selectedCommentIdsForMultiSelectProvider)
          .length,
      1,
    );

      // Act: Tap the first widget again to deselect
      await tester.tap(firstMultiSelectWidgetFinder);
    await tester.pumpAndSettle();

    // Assert: Selection state updated
    // Use the container created in setUp
    expect(
      container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
      isNot(contains(expectedCommentId)),
    );
    expect(
      container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
      isEmpty,
    );
  });

  testWidgets('MemoComments selects/deselects comment via item tap in multi-select mode', (WidgetTester tester) async {
    // Arrange
      await tester.pumpWidget(
        buildTestableWidget(const MemoComments(memoId: testMemoId), container),
      );
      await tester.pumpAndSettle();

    // Enter multi-select mode
    container.read(ui_providers.commentMultiSelectModeProvider.notifier).state = true;
    await tester.pumpAndSettle();

    // Find the first CommentCard
    final firstItemFinder = find.byType(CommentCard).first;
    final expectedCommentId = '$testMemoId/${dummyComments[0].id}';

      // Act: Tap the checkbox within the first item to select
      final firstCheckboxFinder = find.descendant(
        of: firstItemFinder,
        matching: find.byType(CupertinoCheckbox),
      );
      expect(firstCheckboxFinder, findsOneWidget);
      await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();

      // Assert: Selection state updated
      expect(
        container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
        contains(expectedCommentId),
      );
      expect(
        container
            .read(ui_providers.selectedCommentIdsForMultiSelectProvider)
            .length,
        1,
      );

      // Act: Tap the checkbox within the first item again to deselect
      final secondCheckboxFinder = find.descendant(
        of: firstItemFinder,
        matching: find.byType(CupertinoCheckbox),
      );
      expect(secondCheckboxFinder, findsOneWidget);
      await tester.tap(secondCheckboxFinder);
    await tester.pumpAndSettle();

      // Assert: Selection state updated
      expect(
        container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
        isNot(contains(expectedCommentId)),
      );
      expect(
        container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
        isEmpty,
      );
  });

  testWidgets(
    'MemoComments exits multi-select mode and hides checkboxes/switches',
    (
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const MemoComments(memoId: testMemoId), container),
    );
    await tester.pumpAndSettle();

      // Enter multi-select mode and select an item via checkbox
    container.read(ui_providers.commentMultiSelectModeProvider.notifier).state = true;
    await tester.pumpAndSettle();

      final firstCheckboxFinder = find.descendant(
        of: find.byType(CommentCard).first,
        matching: find.byType(CupertinoCheckbox),
      );
      expect(firstCheckboxFinder, findsOneWidget);
      await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();

    expect(container.read(ui_providers.commentMultiSelectModeProvider), isTrue);
      // Now this assertion should pass
    expect(container.read(ui_providers.selectedCommentIdsForMultiSelectProvider), isNotEmpty);

    // Act: Simulate exiting multi-select mode
    container.read(ui_providers.commentMultiSelectModeProvider.notifier).state = false;

    // Exiting mode should also clear selections (handled by the toggle provider logic)
    container.read(ui_providers.selectedCommentIdsForMultiSelectProvider.notifier).state = {};
    await tester.pumpAndSettle();

    // Assert: Exited multi-select mode
    expect(
      container.read(ui_providers.commentMultiSelectModeProvider),
      isFalse,
    );
    expect(
      container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
      isEmpty,
    );

      // Verify Checkboxes/Switches are gone
      expect(
      find.descendant(
        of: find.byType(CommentCard),
          matching: find.byType(
            CupertinoCheckbox,
          ), // Check for CupertinoCheckbox first
        ),
        findsNothing,
      );
      // Also check for Switch just in case
      expect(
        find.descendant(
          of: find.byType(CommentCard),
          matching: find.byType(CupertinoSwitch), // Check for CupertinoSwitch
        ),
        findsNothing,
      );


    // Verify Slidable is back
    expect(
      find.descendant(
        of: find.byType(CommentCard),
        matching: find.byType(Slidable),
      ),
      findsWidgets,
    );
  });
}
