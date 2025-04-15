import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/note_providers.dart'; // Updated import
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/services/base_api_service.dart'; // Updated import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import generated mocks
import 'move_memo_provider_test.mocks.dart'; // Keep mock file name for now

// Use the imported class type here
@GenerateNiceMocks([
  MockSpec<BaseApiService>(), // Updated mock type
  MockSpec<NotesNotifier>(), // Updated mock type
])
void main() {
  group('moveNoteProvider Tests', () {
    // Updated group name
    late MockBaseApiService mockApiService; // Updated mock type
    late ProviderContainer container;
    late MockNotesNotifier mockNotesNotifierInstance; // Updated mock type

    final sourceServer = ServerConfig(
      id: 'source-id',
      name: 'Source Server',
      serverUrl: 'http://source.com',
      authToken: 'source-token',
      serverType: ServerType.memos, // Add required field
    );
    final destinationServer = ServerConfig(
      id: 'dest-id',
      name: 'Destination Server',
      serverUrl: 'http://dest.com',
      authToken: 'dest-token',
      serverType: ServerType.memos, // Add required field
    );

    final noteToMove = NoteItem(
      // Updated type
      id: 'note1', // Updated prefix
      content: 'Note to move', // Updated content
      pinned: false, // Add required parameter
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
      displayTime: DateTime.now(), // Add required field
      visibility: NoteVisibility.private, // Add required field
      state: NoteState.normal, // Add required field
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
      mockApiService = MockBaseApiService(); // Updated mock type
      mockNotesNotifierInstance = MockNotesNotifier(); // Updated mock type

      // Create the container with overrides
      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
          activeServerConfigProvider.overrideWithValue(sourceServer),
          notesNotifierProvider.overrideWith((_) {
            // Updated provider name
            when(
              mockNotesNotifierInstance.state).thenReturn(
              NotesState(notes: [noteToMove]),
            ); // Updated state type and field
            return TestNotesNotifier(
              mockNotesNotifierInstance,
            ); // Updated helper type
          }),
        ],
      );

      // Stub notifier methods
      when(
        mockNotesNotifierInstance.removeNoteOptimistically(
          any,
        ), // Updated method name
      ).thenAnswer((_) {});
      when(
        mockNotesNotifierInstance.refresh()).thenAnswer((_) async {
        return;
      });

      // Configure ApiService mocks
      when(
        mockApiService.getNote(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).thenAnswer((_) async => noteToMove);

      // Add specific stub for the note being moved (without override)
      when(
        mockApiService.getNote(noteToMove.id),
      ).thenAnswer((_) async => noteToMove);

      when(
        mockApiService.listNoteComments(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).thenAnswer((_) async => []); // Return empty list for simplicity

      when(
        mockApiService.createNote(
          // Updated method name
          any,
          targetServerOverride: destinationServer,
        ),
      ).thenAnswer((invocation) async {
        final noteArg =
            invocation.positionalArguments[0] as NoteItem; // Updated type
        return noteArg.copyWith(id: 'new-');
      });

      // Mock comment creation
      when(
        mockApiService.createNoteComment(
          // Updated method name
          'new-',
          any,
          targetServerOverride: destinationServer,
          resources: anyNamed('resources'),
        ),
      ).thenAnswer((invocation) async {
        final commentArg = invocation.positionalArguments[1] as Comment;
        return commentArg.copyWith(id: 'new-${commentArg.id}');
      });

      when(
        mockApiService.deleteNote(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).thenAnswer((_) async => {});
    });

    tearDown(() {
      container.dispose();
    });

    test('Successful Move', () async {
      // Act
      await container.read(
        moveNoteProvider(
          // Updated provider name
          MoveNoteParams(
            // Updated params type
            noteId: noteToMove.id, // Updated field name
            targetServer: destinationServer,
          ),
        ),
      )();

      // Assert
      verify(
        mockNotesNotifierInstance.removeNoteOptimistically(
          noteToMove.id,
        ), // Updated method name
      ).called(1);

      // Verify API calls
      verify(
        mockApiService.getNote(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
      verify(
        mockApiService.listNoteComments(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
      verify(
        mockApiService.createNote(
          // Updated method name
          any,
          targetServerOverride: destinationServer,
        ),
      ).called(1);
      // Verify no comments were attempted to be created
      verifyNever(
        mockApiService.createNoteComment(
          any,
          any,
          targetServerOverride: destinationServer,
          resources: anyNamed('resources'),
        ),
      );
      verify(
        mockApiService.deleteNote(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
    });

    test('Failure during Note Creation', () async {
      // Updated test name
      // Arrange
      final exception = Exception('Note creation failed'); // Updated message
      when(
        mockApiService.createNote(
          // Updated method name
          any,
          targetServerOverride: destinationServer,
        ),
      ).thenThrow(exception);

      // Act & Assert
      await expectLater(
        container.read(
          moveNoteProvider(
            // Updated provider name
            MoveNoteParams(
              // Updated params type
              noteId: noteToMove.id, // Updated field name
              targetServer: destinationServer,
            ),
          ),
        )(),
        throwsA(exception),
      );

      verify(
        mockNotesNotifierInstance.removeNoteOptimistically(
          noteToMove.id,
        ), // Updated method name
      ).called(1);

      verify(
        mockApiService.getNote(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
      verify(
        mockApiService.listNoteComments(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);

      verify(
        mockApiService.createNote(
          // Updated method name
          any,
          targetServerOverride: destinationServer,
        ),
      ).called(1);

      verifyNever(
        mockApiService.createNoteComment(
          // Updated method name
          any,
          any,
          targetServerOverride: destinationServer,
          resources: anyNamed('resources'),
        ),
      );
      verifyNever(
        mockApiService.deleteNote(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      );
    });

    // Removed 'Failure during Comment Creation (Continue)' test as comments are not moved

    test('Failure during Deletion', () async {
      // Arrange
      final deleteException = Exception('Deletion failed');
      when(
        mockApiService.deleteNote(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).thenThrow(deleteException);

      // Act: Call the provider, expect it to complete (not throw)
      await container.read(
        moveNoteProvider(
          MoveNoteParams(
            noteId: noteToMove.id,
            targetServer: destinationServer,
          ),
        ),
      )();

      // Assert
      verify(
        mockNotesNotifierInstance.removeNoteOptimistically(
          noteToMove.id),
      ).called(1);

      verify(
        mockApiService.getNote(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
      verify(
        mockApiService.listNoteComments(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);
      verify(
        mockApiService.createNote(
          // Updated method name
          any,
          targetServerOverride: destinationServer,
        ),
      ).called(1);
      verify(
        mockApiService.createNoteComment(
          // Updated method name
          'new-',
          any,
          targetServerOverride: destinationServer,
          resources: anyNamed('resources'),
        ),
      ).called(0); // Expect 0 calls as no comments are moved

      verify(
        mockApiService.deleteNote(
          // Updated method name
          noteToMove.id,
          targetServerOverride: sourceServer,
        ),
      ).called(1);

      // Assert: Verify that the notifier's refresh method was called due to the error
      verify(mockNotesNotifierInstance.refresh()).called(1);
    });
  });
}
class TestNotesNotifier extends StateNotifier<NotesState>
    implements NotesNotifier {
  final MockNotesNotifier mock;

  TestNotesNotifier(this.mock) : super(mock.state);

  @override
  Future<void> refresh() => mock.refresh();

  @override
  void removeNoteOptimistically(String noteId) {
    // Updated method name
    mock.removeNoteOptimistically(noteId); // Updated method name
  }

  // Add other methods from NotesNotifier that your tests use
  @override
  noSuchMethod(Invocation invocation) {
    // Handle potential null returns for methods returning Future<void>
    if (invocation.memberName == #fetchMoreNotes ||
        invocation.memberName == #togglePinOptimistically ||
        invocation.memberName == #bumpNoteOptimistically ||
        invocation.memberName == #archiveNoteOptimistically) {
      mock.noSuchMethod(invocation);
      return Future.value(); // Return a completed future for void methods
    }
    return mock.noSuchMethod(invocation);
  }
}
