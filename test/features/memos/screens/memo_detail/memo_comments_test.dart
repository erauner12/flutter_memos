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
  // Generate dummy comments
  final initialDummyComments = createDummyComments(3);
  // **Explicitly sort the list like the widget likely does (newest first)**
  final sortedDummyComments = List<Comment>.from(initialDummyComments)
    ..sort((a, b) => b.createTime.compareTo(a.createTime));

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
      // Use the pre-sorted list here
    ).thenAnswer((_) async => sortedDummyComments);

    container = ProviderContainer(
      overrides: [
        // Override the comments provider for the specific memoId
        // Provide the pre-sorted list directly
        memoCommentsProvider(testMemoId).overrideWith(
          (ref) => Future.value(sortedDummyComments),
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
        findsNWidgets(sortedDummyComments.length),
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

      // The first item in the sorted list is comment_0
      final targetCommentId = sortedDummyComments[0].id;
      final expectedCombinedId = '$testMemoId/$targetCommentId';
      expect(targetCommentId, 'comment_0'); // Verify it's comment_0

      // Find the specific CommentCard for comment_0
      final targetCardFinder = find.byWidgetPredicate(
        (widget) =>
            widget is CommentCard && widget.comment.id == targetCommentId,
      );
      expect(
        targetCardFinder,
        findsOneWidget,
        reason: 'Could not find CommentCard for comment_0',
      );

      // Find the checkbox within that specific card
      final targetCheckboxFinder = find.descendant(
        of: targetCardFinder,
        matching: find.byType(CupertinoCheckbox),
      );
      expect(
        targetCheckboxFinder,
        findsOneWidget,
        reason: 'Could not find Checkbox in CommentCard for comment_0',
      );

      // Act: Tap the target checkbox to select
      await tester.tap(targetCheckboxFinder);
      await tester.pumpAndSettle();

      // Assert: Selection state updated
      expect(
        container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
        contains(expectedCombinedId), // Check for the combined ID
      );
      expect(
        container
            .read(ui_providers.selectedCommentIdsForMultiSelectProvider)
            .length,
        1,
      );

      // Act: Tap the target checkbox again to deselect
      await tester.tap(targetCheckboxFinder);
      await tester.pumpAndSettle();

      // Assert: Selection state updated
      expect(
        container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
        isNot(contains(expectedCombinedId)),
      );
      expect(
        container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
        isEmpty,
      );
    },
  );

testWidgets(
    'MemoComments selects/deselects comment via item tap in multi-select mode',
    (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        buildTestableWidget(const MemoComments(memoId: testMemoId), container),
      );
      await tester.pumpAndSettle();

      // Enter multi-select mode
      container
          .read(ui_providers.commentMultiSelectModeProvider.notifier)
          .state = true;
      await tester.pumpAndSettle();

      // The first item in the sorted list is comment_0
      final targetCommentId = sortedDummyComments[0].id;
      final expectedCombinedId = '$testMemoId/$targetCommentId';
      expect(targetCommentId, 'comment_0'); // Verify it's comment_0

      // Find the specific CommentCard for comment_0
      final targetCardFinder = find.byWidgetPredicate(
        (widget) =>
            widget is CommentCard && widget.comment.id == targetCommentId,
      );
      expect(
        targetCardFinder,
        findsOneWidget,
        reason: 'Could not find CommentCard for comment_0',
      );

      // Find the checkbox within that specific card
      final targetCheckboxFinder = find.descendant(
        of: targetCardFinder,
        matching: find.byType(CupertinoCheckbox),
      );
      expect(
        targetCheckboxFinder,
        findsOneWidget,
        reason: 'Could not find Checkbox in CommentCard for comment_0',
      );

      // Act: Tap the checkbox within the target item to select
      await tester.tap(targetCheckboxFinder); // Tap the checkbox directly
      await tester.pumpAndSettle();

      // Assert: Selection state updated
      expect(
        container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
        contains(expectedCombinedId), // Check for the combined ID
      );
      expect(
        container
            .read(ui_providers.selectedCommentIdsForMultiSelectProvider)
            .length,
        1,
      );

      // Act: Tap the checkbox within the target item again to deselect
      await tester.tap(targetCheckboxFinder); // Tap the checkbox directly
      await tester.pumpAndSettle();

      // Assert: Selection state updated
      expect(
        container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
        isNot(contains(expectedCombinedId)),
      );
      expect(
        container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
        isEmpty,
      );
    },
  );

testWidgets(
    'MemoComments exits multi-select mode and hides checkboxes/switches',
    (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        buildTestableWidget(const MemoComments(memoId: testMemoId), container),
      );
      await tester.pumpAndSettle();

      // Enter multi-select mode and select an item via checkbox
      container
          .read(ui_providers.commentMultiSelectModeProvider.notifier)
          .state = true;
      await tester.pumpAndSettle();

      final firstCheckboxFinder = find.descendant(
        of: find.byType(CommentCard).first,
        matching: find.byType(CupertinoCheckbox),
      );
      expect(firstCheckboxFinder, findsOneWidget);
      await tester.tap(firstCheckboxFinder);
      await tester.pumpAndSettle();

      expect(
        container.read(ui_providers.commentMultiSelectModeProvider),
        isTrue,
      );
      // Now this assertion should pass
      expect(
        container.read(ui_providers.selectedCommentIdsForMultiSelectProvider),
        isNotEmpty,
      );

      // Act: Simulate exiting multi-select mode
      container
          .read(ui_providers.commentMultiSelectModeProvider.notifier)
          .state = false;

      // Exiting mode should also clear selections (handled by the toggle provider logic)
      container
          .read(ui_providers.selectedCommentIdsForMultiSelectProvider.notifier)
          .state = {};
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
    },
  );
}
