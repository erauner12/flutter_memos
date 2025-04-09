import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/comment_providers.dart';
import 'package:flutter_memos/providers/memo_detail_provider.dart';
import 'package:flutter_memos/providers/memo_providers.dart' as memo_providers;
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart'
    as memo_detail_providers;
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockMemoProvider extends Mock {
  Future<Memo> call(Memo memo) async => memo.copyWith(id: 'mock-created-id');
}

class MockUpdateMemoProvider extends Mock {
  Future<Memo> call(Memo memo) async => memo;
}

class MockCommentProvider extends Mock {
  Future<Comment> call(
    Comment comment, {
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
  }) async {
    return comment.copyWith(id: 'mock-comment-id');
  }
}

class MockUpdateCommentProvider extends Mock {
  Future<Comment> call(String memoId, String commentId, String content) async {
    return Comment(
      id: commentId,
      content: content,
      creatorId: '1',
      createTime: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

// Build a testable widget with all required providers
Widget buildTestableWidget({
  required Widget child,
  CaptureMode mode = CaptureMode.createMemo,
  String? memoId,
  List<Comment> comments = const [],
  Memo? parentMemo,
  bool simulateError = false,
}) {
  final mockCreateMemoProvider = MockMemoProvider();
  final mockUpdateMemoProvider = MockUpdateMemoProvider();
  final mockCreateCommentProvider = MockCommentProvider();
  final mockUpdateCommentProvider = MockUpdateCommentProvider();

  if (simulateError) {
    when(
      mockCreateMemoProvider.call(any),
    ).thenAnswer((_) => Future.error(Exception('Mock Error')));
    when(
      mockCreateCommentProvider.call(
        any,
        fileBytes: anyNamed('fileBytes'),
        filename: anyNamed('filename'),
        contentType: anyNamed('contentType'),
      ),
    ).thenThrow(Exception('Mock Error'));
  }

  return ProviderScope(
    overrides: [
      // Mock providers for memo operations
      memo_providers.createMemoProvider.overrideWith(
        (ref) => (memo) async {
          await mockCreateMemoProvider.call(memo);
        },
      ),
      memo_providers
          .updateMemoProvider(memoId ?? 'default')
          .overrideWith((ref) => (memo) => mockUpdateMemoProvider.call(memo)),
      // Mock providers for comment operations
      createCommentProvider(
        memoId ?? 'default',
      ).overrideWith((ref) => mockCreateCommentProvider.call),
      updateCommentProvider.overrideWithValue(mockUpdateCommentProvider.call),
      // Mock memo detail and comments providers
      memoDetailProvider(
        memoId ?? 'default',
      ).overrideWith((ref) => Future.value(parentMemo)),
      memoCommentsProvider(
        memoId ?? 'default',
      ).overrideWith((ref) async => comments),
      // UI toggle provider
      captureUtilityToggleProvider.overrideWith((ref) => false),
    ],
    child: CupertinoApp(
      theme: const CupertinoThemeData(brightness: Brightness.light),
      home: CupertinoPageScaffold(
        child: Padding(padding: const EdgeInsets.all(16.0), child: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Setup channel handlers for clipboard operations and any other platform channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'Clipboard.setData') {
            return null; // Success
          }
          return null;
        });
  });

  tearDown(() {
    // Clear handlers after each test
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('CaptureUtility Initial Rendering', () {
    testWidgets('renders in collapsed state initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: CaptureUtility(key: CaptureUtility.captureUtilityKey),
        ),
      );

      // Verify the utility is in collapsed state
      expect(find.text('Capture something...'), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsOneWidget);

      // Initial height should be collapsed height (measuring not exact widget because animation controller is involved)
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(
        container.constraints?.maxHeight,
        isNull,
      ); // Container doesn't have direct height constraint
    });

    testWidgets('shows correct hint text based on mode', (
      WidgetTester tester,
    ) async {
      // Test createMemo mode
      await tester.pumpWidget(
        buildTestableWidget(
          child: CaptureUtility(
            key: CaptureUtility.captureUtilityKey,
            mode: CaptureMode.createMemo,
          ),
        ),
      );
      expect(find.text('Capture something...'), findsOneWidget);

      // Test addComment mode
      await tester.pumpWidget(
        buildTestableWidget(
          child: CaptureUtility(
            key: CaptureUtility.captureUtilityKey,
            mode: CaptureMode.addComment,
            memoId: 'test-memo-id',
          ),
        ),
      );
      expect(find.text('Add a comment...'), findsOneWidget);

      // Test custom hint text
      await tester.pumpWidget(
        buildTestableWidget(
          child: CaptureUtility(
            key: CaptureUtility.captureUtilityKey,
            hintText: 'Custom hint text',
          ),
        ),
      );
      expect(
        find.text('Custom hint text'),
        findsNothing,
      ); // Not visible in collapsed state
      expect(
        find.text('Capture something...'),
        findsOneWidget,
      ); // Placeholder is visible
    });
  });

  group('CaptureUtility Expansion and Collapse', () {
    testWidgets('expands on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: CaptureUtility(key: CaptureUtility.captureUtilityKey),
        ),
      );

      // Initial state is collapsed
      expect(find.text('Capture something...'), findsOneWidget);

      // Tap to expand
      await tester.tap(find.text('Capture something...'));
      await tester.pumpAndSettle(); // Allow animation to complete

      // Should now be expanded with text field visible
      final textField = find.byType(CupertinoTextField);
      expect(textField, findsOneWidget);

      // In expanded state, the placeholder inside CupertinoTextField becomes visible
      expect(find.text('Type or paste memo content...'), findsOneWidget);
    });

    testWidgets('collapses when submit button pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: CaptureUtility(key: CaptureUtility.captureUtilityKey),
        ),
      );

      // Expand first
      await tester.tap(find.text('Capture something...'));
      await tester.pumpAndSettle();

      // Enter some text
      await tester.enterText(find.byType(CupertinoTextField), 'Test content');

      // Press the submit button (arrow up icon)
      await tester.tap(find.byIcon(CupertinoIcons.arrow_up));
      await tester.pumpAndSettle();

      // Should be collapsed again
      expect(find.text('Capture something...'), findsOneWidget);
      // Text should be cleared
      expect(find.text('Test content'), findsNothing);
    });

    testWidgets('expands when toggle signal received', (
      WidgetTester tester,
    ) async {
      // Create a controller to manipulate the toggle provider
      final toggleController = StateController<bool>(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            captureUtilityToggleProvider.overrideWith(
              (ref) => toggleController.state,
            ),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: CaptureUtility(key: CaptureUtility.captureUtilityKey),
            ),
          ),
        ),
      );

      // Initial state is collapsed
      expect(find.text('Capture something...'), findsOneWidget);

      // Toggle to expand
      toggleController.state = true;
      await tester.pumpAndSettle(); // Allow animation to complete

      // Should now be expanded
      expect(find.text('Type or paste memo content...'), findsOneWidget);
    });
  });

  group('CaptureUtility Text Input', () {
    testWidgets('allows text entry', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: CaptureUtility(key: CaptureUtility.captureUtilityKey),
        ),
      );

      // Expand first
      await tester.tap(find.text('Capture something...'));
      await tester.pumpAndSettle();

      // Enter text
      const testText = 'This is a test memo';
      await tester.enterText(find.byType(CupertinoTextField), testText);

      // Verify text was entered
      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('handles ESC key to collapse', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: CaptureUtility(key: CaptureUtility.captureUtilityKey),
        ),
      );

      // Expand first
      await tester.tap(find.text('Capture something...'));
      await tester.pumpAndSettle();

      // Simulate ESC key press
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Should be collapsed again
      expect(find.text('Capture something...'), findsOneWidget);
    });
  });

  group('CaptureUtility Submission', () {
    testWidgets('createMemo mode submits correctly', (
      WidgetTester tester,
    ) async {
      final mockCreateMemoProvider = MockMemoProvider();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memo_providers.createMemoProvider.overrideWith((ref) async {
              // Provide a default Memo object to satisfy non-nullable requirement
              await mockCreateMemoProvider.call(
                argThat(predicate<Memo>((memo) => true)),
              );
            }),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: CaptureUtility(
                key: CaptureUtility.captureUtilityKey,
                mode: CaptureMode.createMemo,
              ),
            ),
          ),
        ),
      );

      // Expand first
      await tester.tap(find.text('Capture something...'));
      await tester.pumpAndSettle();

      // Enter text
      const testText = 'This is a test memo';
      await tester.enterText(find.byType(CupertinoTextField), testText);

      // Submit
      await tester.tap(find.byIcon(CupertinoIcons.arrow_up));
      await tester.pumpAndSettle();

      // Verify createMemoProvider was called with correct data
      verify(
        mockCreateMemoProvider.call(
          argThat(predicate<Memo>((memo) => memo.content == testText)),
        ),
      ).called(1);

      // Should be collapsed again with text cleared
      expect(find.text('Capture something...'), findsOneWidget);
      expect(find.text(testText), findsNothing);
    });

    testWidgets('addComment mode submits correctly', (
      WidgetTester tester,
    ) async {
      final mockCreateCommentProvider = MockCommentProvider();
      final memoId = 'test-memo-id';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            createCommentProvider(
              memoId,
            ).overrideWith((ref) => mockCreateCommentProvider.call),
            memoCommentsProvider(
              memoId,
            ).overrideWith((ref) async => []),
            memoDetailProvider(memoId).overrideWith(
              (ref) async => Memo(id: memoId, content: 'Test memo'),
            ),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: CaptureUtility(
                key: CaptureUtility.captureUtilityKey,
                mode: CaptureMode.addComment,
                memoId: memoId,
              ),
            ),
          ),
        ),
      );

      // Expand first
      await tester.tap(find.text('Add a comment...'));
      await tester.pumpAndSettle();

      // Enter text
      const testText = 'This is a test comment';
      await tester.enterText(find.byType(CupertinoTextField), testText);

      // Submit
      await tester.tap(find.byIcon(CupertinoIcons.arrow_up));
      await tester.pumpAndSettle();

      // Verify createCommentProvider was called with correct data
      verify(
        mockCreateCommentProvider.call(
          argThat(predicate<Comment>((comment) => comment.content == testText)),
          fileBytes: null,
          filename: null,
          contentType: null,
        ),
      ).called(1);

      // Should be collapsed again with text cleared
      expect(find.text('Add a comment...'), findsOneWidget);
      expect(find.text(testText), findsNothing);
    });

    testWidgets('appendToMemo action works correctly', (
      WidgetTester tester,
    ) async {
      final mockUpdateMemoProvider = MockUpdateMemoProvider();
      final memoId = 'test-memo-id';
      final originalContent = 'Original memo content';
      final parentMemo = Memo(id: memoId, content: originalContent);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memo_providers
                .updateMemoProvider(memoId)
                .overrideWith(mockUpdateMemoProvider.call),
            memoDetailProvider(
              memoId,
            ).overrideWith((ref) => Future.value(parentMemo)),
            memoCommentsProvider(
              memoId,
            ).overrideWith(const AsyncValue.data([])),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: CaptureUtility(
                key: CaptureUtility.captureUtilityKey,
                mode: CaptureMode.addComment,
                memoId: memoId,
              ),
            ),
          ),
        ),
      );

      // Expand first
      await tester.tap(find.text('Add a comment...'));
      await tester.pumpAndSettle();

      // Switch to appendToMemo mode
      await tester.tap(find.text('Append 📝'));
      await tester.pumpAndSettle();

      // Enter text
      const appendedText = 'Appended text';
      await tester.enterText(find.byType(CupertinoTextField), appendedText);

      // Submit
      await tester.tap(find.byIcon(CupertinoIcons.arrow_up));
      await tester.pumpAndSettle();

      // Verify updateMemoProvider was called with correct data (original + appended with newlines)
      verify(
        mockUpdateMemoProvider.call(
          argThat(
            predicate<Memo>(
              (memo) => memo.content == '$originalContent\n\n$appendedText',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('prependToLastComment action works correctly', (
      WidgetTester tester,
    ) async {
      final mockUpdateCommentProvider = MockUpdateCommentProvider();
      final memoId = 'test-memo-id';
      final commentId = 'test-comment-id';
      final originalCommentContent = 'Original comment content';
      final comments = [
        Comment(
          id: commentId,
          content: originalCommentContent,
          creatorId: '1',
          createTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            updateCommentProvider.overrideWithValue(
              mockUpdateCommentProvider.call,
            ),
            memo_detail_providers
                .memoCommentsProvider(memoId)
                .overrideWith((ref) => comments),
            memoDetailProvider(
              memoId,
            ).overrideWith((ref) => Memo(id: memoId, content: 'Test memo')),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: CaptureUtility(
                key: CaptureUtility.captureUtilityKey,
                mode: CaptureMode.addComment,
                memoId: memoId,
              ),
            ),
          ),
        ),
      );

      // Expand first
      await tester.tap(find.text('Add a comment...'));
      await tester.pumpAndSettle();

      // Switch to prependToLastComment mode
      await tester.tap(find.text('Prepend 💬'));
      await tester.pumpAndSettle();

      // Enter text
      const prependedText = 'Prepended text';
      await tester.enterText(find.byType(CupertinoTextField), prependedText);

      // Submit
      await tester.tap(find.byIcon(CupertinoIcons.arrow_up));
      await tester.pumpAndSettle();

      // Verify updateCommentProvider was called with correct data
      verify(
        mockUpdateCommentProvider.call(
          memoId,
          commentId,
          '$prependedText\n\n$originalCommentContent',
        ),
      ).called(1);
    });
  });

  group('CaptureUtility File Handling', () {
    testWidgets('setFileDataForTest method works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: CaptureUtility(
            key: CaptureUtility.captureUtilityKey,
            mode: CaptureMode.addComment,
            memoId: 'test-memo-id',
          ),
        ),
      );

      // Expand first
      await tester.tap(find.text('Add a comment...'));
      await tester.pumpAndSettle();

      // Prepare test file data
      final testFileData = Uint8List.fromList([1, 2, 3, 4, 5]);
      const testFilename = 'test.txt';
      const testContentType = 'text/plain';

      // Use the static method to set test file data
      CaptureUtility.setTestFileData(
        testFileData,
        testFilename,
        testContentType,
      );
      await tester.pumpAndSettle();

      // Verify file info is displayed
      expect(find.text(testFilename), findsOneWidget);

      // Verify remove button is present
      expect(find.byIcon(CupertinoIcons.clear_circled_solid), findsOneWidget);

      // Test removing attachment
      await tester.tap(find.byIcon(CupertinoIcons.clear_circled_solid));
      await tester.pumpAndSettle();

      // Verify file info is no longer displayed
      expect(find.text(testFilename), findsNothing);
    });
  });

  group('CaptureUtility Error Handling', () {
    testWidgets('shows error dialog when createMemo fails', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: CaptureUtility(key: CaptureUtility.captureUtilityKey),
          simulateError: true,
        ),
      );

      // Expand first
      await tester.tap(find.text('Capture something...'));
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(CupertinoTextField), 'Test content');

      // Submit (should trigger error)
      await tester.tap(find.byIcon(CupertinoIcons.arrow_up));
      await tester.pumpAndSettle();

      // Error dialog should be shown
      expect(find.text('Submission Error'), findsOneWidget);
      expect(
        find.text('Failed to submit: Exception: Mock Error'),
        findsOneWidget,
      );

      // Dismiss error dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // CaptureUtility should still be expanded with text intact
      expect(find.text('Test content'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.arrow_up), findsOneWidget);
    });
  });
}
