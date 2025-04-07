import 'package:flutter_memos/api/lib/api.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import mocks from memo_providers_test for MemosNotifier
import 'memo_providers_test.mocks.dart' show MockMemosNotifier;
// Import generated mocks
import 'move_memo_provider_test.mocks.dart';

// Generate mocks for ApiService
@GenerateNiceMocks([MockSpec<ApiService>()])
void main() {
  group('moveMemoProvider Tests', () {
    late MockApiService mockApiService;
    late ProviderContainer container;
    late MockMemosNotifier mockMemosNotifier; // Use the mock notifier

    final sourceServer = ServerConfig(
      id: 'source-id',
      name: 'Source Server',
      serverUrl: 'http://source.com',
      authToken: 'source-token',
    );
    final destinationServer = ServerConfig(
      id: 'dest-id',
      name: 'Destination Server',
      serverUrl: 'http://dest.com',
      authToken: 'dest-token',
    );

    final memoToMove = Memo(
      id: 'memo1',
      content: 'Memo to move',
      createTime: DateTime.now().toIso8601String(),
      updateTime: DateTime.now().toIso8601String(),
    );

    final comment1 = Comment(
      id: 'comment1',
      content: 'First comment',
      createTime: DateTime.now().millisecondsSinceEpoch,
    );
    final comment2 = Comment(
      id: 'comment2',
      content: 'Second comment',
      createTime: DateTime.now().millisecondsSinceEpoch,
    );

    // Corresponding API models for comments (needed for mocking createMemoComment)
    final apiComment1 = Apiv1Memo(name: 'memos/comment1', content: comment1.content);
    final apiComment2 = Apiv1Memo(name: 'memos/comment2', content: comment2.content);

    setUp(() {
      mockApiService = MockApiService();
      // Initialize the mock notifier with an empty state or relevant initial state
      mockMemosNotifier = MockMemosNotifier(
        ProviderContainer(), // Pass a dummy container or ref
        MemosState(memos: [memoToMove]), // Start with the memo present
      );

      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
          // Provide the source server as the active one initially
          activeServerConfigProvider.overrideWithValue(sourceServer),
          // Override the memosNotifierProvider to use our mock
          memosNotifierProvider.overrideWithValue(
            mockMemosNotifier,
            // Provide the notifier instance directly
            // This requires adjusting the override slightly if using overrideWith
            // For simplicity, overrideWithValue is used here.
          ),
        ],
      );

      // Default successful mocks (can be overridden in specific tests)
      when(
        mockApiService.getMemo(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).thenAnswer((_) async => memoToMove);

      when(
        mockApiService.listMemoComments(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).thenAnswer((_) async => [comment1, comment2]);

      when(
        mockApiService.createMemo(
          any, // Match any Memo object
          targetServerOverride: destinationServer,
        ),
      ).thenAnswer((invocation) async {
        final memoArg = invocation.positionalArguments[0] as Memo;
        // Return a memo with a new ID simulating creation
        return memoArg.copyWith(id: 'new-${memoArg.id}');
      });

      // Mock comment creation for both comments successfully by default
      when(
        mockApiService.createMemoComment(
          'new-${memoToMove.id}', // Use the expected new memo ID
          any, // Match any Comment object
          targetServerOverride: destinationServer,
          resources: anyNamed('resources'),
        ),
      ).thenAnswer((invocation) async {
         final commentArg = invocation.positionalArguments[1] as Comment;
         // Return the comment, potentially with a new ID if needed
         return commentArg.copyWith(id: 'new-${commentArg.id}');
      });


      when(
        mockApiService.deleteMemo(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).thenAnswer((_) async => {}); // Default successful deletion
    });

    tearDown(() {
      container.dispose();
    });

    test('Successful Move', () async {
      // Arrange (mocks are set up in setUp)

      // Act
      await container.read(
        moveMemoProvider(
          memoId: memoToMove.id,
          targetServer: destinationServer,
        ),
      )(); // Call the returned function

      // Assert
      // Verify optimistic removal was called on the notifier
      verify(mockMemosNotifier.removeMemoOptimistically(memoToMove.id)).called(1);

      // Verify API calls
      verify(
        mockApiService.getMemo(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
      verify(
        mockApiService.listMemoComments(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
      verify(
        mockApiService.createMemo(
          any, // Verify a memo was created
          targetServerOverride: destinationServer,
        ),
      ).called(1);
      // Verify comment creation for both comments
       verify(
        mockApiService.createMemoComment(
          'new-${memoToMove.id}',
          argThat(predicate<Comment>((c) => c.content == comment1.content)),
          targetServerOverride: destinationServer,
          resources: anyNamed('resources'),
        ),
      ).called(1);
       verify(
        mockApiService.createMemoComment(
          'new-${memoToMove.id}',
          argThat(predicate<Comment>((c) => c.content == comment2.content)),
          targetServerOverride: destinationServer,
          resources: anyNamed('resources'),
        ),
      ).called(1);
      verify(
        mockApiService.deleteMemo(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
    });

    test('Failure during Memo Creation', () async {
      // Arrange
      final exception = Exception('Memo creation failed');
      when(
        mockApiService.createMemo(
          any,
          targetServerOverride: destinationServer,
        ),
      ).thenThrow(exception);

      // Act & Assert
      await expectLater(
        container.read(
          moveMemoProvider(
            memoId: memoToMove.id,
            targetServer: destinationServer,
          ),
        )(),
        throwsA(exception), // Expect the specific exception
      );

      // Verify optimistic removal was still called
      verify(mockMemosNotifier.removeMemoOptimistically(memoToMove.id)).called(1);

      // Verify initial fetches happened
      verify(
        mockApiService.getMemo(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
      verify(
        mockApiService.listMemoComments(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);

      // Verify memo creation was attempted
      verify(
        mockApiService.createMemo(
          any,
          targetServerOverride: destinationServer,
        ),
      ).called(1);

      // Verify comment creation and deletion were NOT called
      verifyNever(
        mockApiService.createMemoComment(
          any,
          any,
          targetServerOverride: destinationServer,
          resources: anyNamed('resources'),
        ),
      );
      verifyNever(
        mockApiService.deleteMemo(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      );
    });

    test('Failure during Comment Creation (Continue)', () async {
      // Arrange
      final commentException = Exception('Comment creation failed');
      // Make only the second comment fail
      when(
        mockApiService.createMemoComment(
          'new-${memoToMove.id}',
          argThat(predicate<Comment>((c) => c.content == comment2.content)),
          targetServerOverride: destinationServer,
          resources: anyNamed('resources'),
        ),
      ).thenThrow(commentException);

      // Act
      // Expect it to complete successfully despite the comment error
      await container.read(
        moveMemoProvider(
          memoId: memoToMove.id,
          targetServer: destinationServer,
        ),
      )();

      // Assert
      // Verify optimistic removal
      verify(mockMemosNotifier.removeMemoOptimistically(memoToMove.id)).called(1);

      // Verify all initial steps happened
      verify(
        mockApiService.getMemo(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
      verify(
        mockApiService.listMemoComments(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
      verify(
        mockApiService.createMemo(
          any,
          targetServerOverride: destinationServer,
        ),
      ).called(1);

      // Verify comment creation was attempted for both
      verify(
        mockApiService.createMemoComment(
          'new-${memoToMove.id}',
          argThat(predicate<Comment>((c) => c.content == comment1.content)),
          targetServerOverride: destinationServer,
          resources: anyNamed('resources'),
        ),
      ).called(1); // First comment succeeded
      verify(
        mockApiService.createMemoComment(
          'new-${memoToMove.id}',
          argThat(predicate<Comment>((c) => c.content == comment2.content)),
          targetServerOverride: destinationServer,
          resources: anyNamed('resources'),
        ),
      ).called(1); // Second comment was attempted (and failed)

      // Verify deletion WAS called (as per current logic)
      verify(
        mockApiService.deleteMemo(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
    });

    test('Failure during Deletion', () async {
      // Arrange
      final deleteException = Exception('Deletion failed');
      when(
        mockApiService.deleteMemo(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).thenThrow(deleteException);

      // Act & Assert
      await expectLater(
        container.read(
          moveMemoProvider(
            memoId: memoToMove.id,
            targetServer: destinationServer,
          ),
        )(),
        throwsA(deleteException), // Expect the deletion exception
      );

      // Verify optimistic removal
      verify(mockMemosNotifier.removeMemoOptimistically(memoToMove.id)).called(1);

      // Verify all creation steps happened
      verify(
        mockApiService.getMemo(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
      verify(
        mockApiService.listMemoComments(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
      verify(
        mockApiService.createMemo(
          any,
          targetServerOverride: destinationServer,
        ),
      ).called(1);
      verify(
        mockApiService.createMemoComment(
          'new-${memoToMove.id}',
          any,
          targetServerOverride: destinationServer,
          resources: anyNamed('resources'),
        ),
      ).called(2); // Both comments attempted

      // Verify deletion was attempted
      verify(
        mockApiService.deleteMemo(
          memoToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
    });
  });
}
