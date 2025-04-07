import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/services/api_service.dart'
    as api_service_file; // Import the file containing ApiService
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import generated mocks
import 'move_memo_provider_test.mocks.dart';

// Use the imported class type here
@GenerateNiceMocks([
  MockSpec<api_service_file.ApiService>(),
  MockSpec<MemosNotifier>(),
])
void main() {
  group('moveMemoProvider Tests', () {
    late MockApiService mockApiService;
    late ProviderContainer container;
    // Use the generated MockMemosNotifier
    late MockMemosNotifier mockMemosNotifierInstance;

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

    setUp(() {
      mockApiService = MockApiService(); // Instantiate ApiService mock

      // Create the container with overrides, including the mock notifier setup
      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
          activeServerConfigProvider.overrideWithValue(sourceServer),
          memosNotifierProvider.overrideWith((ref) {
            // Create a fresh mock instance for each test
            return MockMemosNotifier();
          }),
        ],
      );

      // Retrieve the created mock instance from the container for verification purposes
      // This ensures we are verifying the same instance that Riverpod is using
      mockMemosNotifierInstance =
          container.read(memosNotifierProvider.notifier) as MockMemosNotifier;

      // Now, stub the methods on the retrieved mock instance
      when(mockMemosNotifierInstance.state).thenReturn(
        MemosState(memos: [memoToMove]), // Set initial state stub
      );
      // Stub other methods needed by the provider or tests
      when(
        mockMemosNotifierInstance.removeMemoOptimistically(any),
      ).thenAnswer((_) {});
      when(
        mockMemosNotifierInstance.refresh(),
      ).thenAnswer((_) async {}); // Stub refresh

      // Configure ApiService mocks AFTER the container and notifier mock are set up
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
          MoveMemoParams(
            memoId: memoToMove.id,
            targetServer: destinationServer,
          ),
        ),
      )(); // Call the returned function

      // Assert
      // Verify optimistic removal was called on the notifier
      verify(
        mockMemosNotifierInstance.removeMemoOptimistically(memoToMove.id),
      ).called(1);

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
            MoveMemoParams(
              memoId: memoToMove.id,
              targetServer: destinationServer,
            ),
          ),
        )(),
        throwsA(exception), // Expect the specific exception
      );

      // Verify optimistic removal was still called
      verify(
        mockMemosNotifierInstance.removeMemoOptimistically(memoToMove.id),
      ).called(1);

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
          MoveMemoParams(
            memoId: memoToMove.id,
            targetServer: destinationServer,
          ),
        ),
      )();

      verify(
        mockMemosNotifierInstance.removeMemoOptimistically(memoToMove.id),
      ).called(1);

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
            MoveMemoParams(
              memoId: memoToMove.id,
              targetServer: destinationServer,
            ),
          ),
        )(),
        throwsA(deleteException), // Expect the deletion exception
      );

      // Verify optimistic removal using the mock instance
      verify(
        mockMemosNotifierInstance.removeMemoOptimistically(memoToMove.id),
      ).called(1);

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
