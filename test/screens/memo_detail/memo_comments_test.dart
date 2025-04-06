import 'package:flutter/material.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/comment_providers.dart' as comment_providers; // For hidden IDs
import 'package:flutter_memos/providers/filter_providers.dart'; // For hidePinnedProvider
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/screens/memo_detail/memo_comments.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart'; // For memoCommentsProvider
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

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

// Helper to wrap widget for testing
Widget buildTestableWidget(Widget child, String memoId, List<Comment> initialComments) {
  return ProviderScope(
    overrides: [
      // Override the comments provider for the specific memoId
      memoCommentsProvider.overrideWithProvider(
        (argument) => FutureProvider((ref) async => initialComments),
      ),
      // Ensure UI providers start in a known state
      ui_providers.commentMultiSelectModeProvider.overrideWith((ref) => false),
      ui_providers.selectedCommentIdsForMultiSelectProvider.overrideWith((ref) => {}),
      ui_providers.selectedCommentIndexProvider.overrideWith((ref) => -1),
      comment_providers.hiddenCommentIdsProvider.overrideWith((ref) => {}), // Needed by MemoComments
      hidePinnedProvider.overrideWith((ref) => false), // Needed by MemoComments
    ],
    child: MaterialApp(
      home: Scaffold(body: child), // Wrap in Scaffold for context
      // Define routes needed for navigation actions within CommentCard (like edit)
      routes: {
        '/edit-entity': (context) => const Scaffold(body: Text('Edit Screen')),
      },
    ),
  );
}


void main() {
  const testMemoId = 'test-memo-1';
  final dummyComments = createDummyComments(3); // Create 3 dummy comments

  testWidgets('MemoComments displays no checkboxes initially', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemoComments(memoId: testMemoId), testMemoId, dummyComments));
    await tester.pumpAndSettle(); // Wait for FutureProvider

    // Act & Assert
    // Verify no Checkboxes are present within CommentCards
    expect(find.descendant(of: find.byType(CommentCard), matching: find.byType(Checkbox)), findsNothing);

    // Verify Slidable is present
    expect(find.descendant(of: find.byType(CommentCard), matching: find.byType(Slidable)), findsWidgets);
  });

  testWidgets('MemoComments enters multi-select mode and shows checkboxes', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemoComments(memoId: testMemoId), testMemoId, dummyComments));
    await tester.pumpAndSettle();
    final container = tester.element<ProviderScope>(find.byType(ProviderScope));

    // Act: Simulate entering multi-select mode by directly setting the provider
    // In a real screen test, you'd tap a button, but here we test MemoComments directly.
    container.read(ui_providers.commentMultiSelectModeProvider.notifier).state = true;
    await tester.pumpAndSettle(); // Rebuild with multi-select mode active

    // Assert
    // Verify provider state
    expect(container.read(ui_providers.commentMultiSelectModeProvider), isTrue);

    // Verify Checkboxes appear for each item
    expect(find.descendant(of: find.byType(CommentCard), matching: find.byType(Checkbox)), findsNWidgets(dummyComments.length));

    // Verify Slidable is gone
    expect(find.descendant(of: find.byType(CommentCard), matching: find.byType(Slidable)), findsNothing);
  });

  testWidgets('MemoComments selects/deselects comment via Checkbox tap', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemoComments(memoId: testMemoId), testMemoId, dummyComments));
    await tester.pumpAndSettle();
    final container = tester.element<ProviderScope>(find.byType(ProviderScope));

    // Enter multi-select mode
    container.read(ui_providers.commentMultiSelectModeProvider.notifier).state = true;
    await tester.pumpAndSettle();

    // Find the first checkbox
    final firstCheckboxFinder = find.descendant(
      of: find.byType(CommentCard).first,
      matching: find.byType(Checkbox),
    );
    expect(firstCheckboxFinder, findsOneWidget);

    final expectedCommentId = '$testMemoId/${dummyComments[0].id}';

    // Act: Tap the first checkbox to select
    await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();

    // Assert: Selection state updated
    expect(container.read(ui_providers.selectedCommentIdsForMultiSelectProvider), contains(expectedCommentId));
    expect(container.read(ui_providers.selectedCommentIdsForMultiSelectProvider).length, 1);

    // Act: Tap the first checkbox again to deselect
    await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();

    // Assert: Selection state updated
    expect(container.read(ui_providers.selectedCommentIdsForMultiSelectProvider), isNot(contains(expectedCommentId)));
    expect(container.read(ui_providers.selectedCommentIdsForMultiSelectProvider), isEmpty);
  });

  testWidgets('MemoComments selects/deselects comment via item tap in multi-select mode', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemoComments(memoId: testMemoId), testMemoId, dummyComments));
    await tester.pumpAndSettle();
    final container = tester.element<ProviderScope>(find.byType(ProviderScope));

    // Enter multi-select mode
    container.read(ui_providers.commentMultiSelectModeProvider.notifier).state = true;
    await tester.pumpAndSettle();

    // Find the first CommentCard
    final firstItemFinder = find.byType(CommentCard).first;
    final expectedCommentId = '$testMemoId/${dummyComments[0].id}';

    // Act: Tap the first item to select
    await tester.tap(firstItemFinder);
    await tester.pumpAndSettle();

    // Assert: Selection state updated
    expect(container.read(ui_providers.selectedCommentIdsForMultiSelectProvider), contains(expectedCommentId));
    expect(container.read(ui_providers.selectedCommentIdsForMultiSelectProvider).length, 1);

    // Act: Tap the first item again to deselect
    await tester.tap(firstItemFinder);
    await tester.pumpAndSettle();

    // Assert: Selection state updated
    expect(container.read(ui_providers.selectedCommentIdsForMultiSelectProvider), isNot(contains(expectedCommentId)));
    expect(container.read(ui_providers.selectedCommentIdsForMultiSelectProvider), isEmpty);
  });

   testWidgets('MemoComments exits multi-select mode and hides checkboxes', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemoComments(memoId: testMemoId), testMemoId, dummyComments));
    await tester.pumpAndSettle();
    final container = tester.element<ProviderScope>(find.byType(ProviderScope));

    // Enter multi-select mode and select an item
    container.read(ui_providers.commentMultiSelectModeProvider.notifier).state = true;
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CommentCard).first);
    await tester.pumpAndSettle();
    expect(container.read(ui_providers.commentMultiSelectModeProvider), isTrue);
    expect(container.read(ui_providers.selectedCommentIdsForMultiSelectProvider), isNotEmpty);

    // Act: Simulate exiting multi-select mode
    container.read(ui_providers.commentMultiSelectModeProvider.notifier).state = false;
    // Exiting mode should also clear selections (handled by the toggle provider logic)
    container.read(ui_providers.selectedCommentIdsForMultiSelectProvider.notifier).state = {};
    await tester.pumpAndSettle();

    // Assert: Exited multi-select mode
    expect(container.read(ui_providers.commentMultiSelectModeProvider), isFalse);
    expect(container.read(ui_providers.selectedCommentIdsForMultiSelectProvider), isEmpty);

    // Verify Checkboxes are gone
    expect(find.descendant(of: find.byType(CommentCard), matching: find.byType(Checkbox)), findsNothing);

    // Verify Slidable is back
    expect(find.descendant(of: find.byType(CommentCard), matching: find.byType(Slidable)), findsWidgets);
  });
}
