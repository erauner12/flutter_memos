import 'dart:typed_data';

import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/note_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/services/blinko_api_service.dart';
// Import specific services to mock
import 'package:flutter_memos/services/memos_api_service.dart';
import 'package:flutter_memos/utils/migration_utils.dart'; // Needed for adaptation logic verification
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart'; // Import annotations
import 'package:mockito/mockito.dart';

// Import the generated mocks file (adjust path if necessary)
// Assuming the build script generates mocks in the same directory or a standard location
import 'move_note_provider_test.mocks.dart';

// Annotation to generate mocks for specific services
@GenerateNiceMocks([
  MockSpec<MemosApiService>(),
  MockSpec<BlinkoApiService>(),
])

// Re-use MockNotesNotifier from memo_providers_test.dart for consistency
// (Assuming it's accessible or defined similarly here)
// REMOVE THE MANUAL CLASS DEFINITION BELOW
// END REMOVAL

void main() {
  group('moveNoteProvider Tests', () {
    late ProviderContainer container;
    // Use specific mock types
    late MockMemosApiService mockSourceApiService; // For Memos
    late MockBlinkoApiService mockTargetApiService; // For Blinko

    // --- Sample Data ---
    final sourceMemosServer = ServerConfig(
      id: 'memos-server-id',
      name: 'My Memos Server',
      serverUrl: 'http://memos.test',
      authToken: 'memos-token',
      serverType: ServerType.memos,
    );

    final targetBlinkoServer = ServerConfig(
      id: 'blinko-server-id',
      name: 'My Blinko Server',
      serverUrl: 'http://blinko.test/api', // Example Blinko URL
      authToken: 'blinko-token',
      serverType: ServerType.blinko,
    );

    final sourceNoteId = 'memos-note-123';
    final sourceNote = NoteItem(
      id: sourceNoteId,
      content: 'Source note content with resource ![resource](resources/res1)',
      pinned: false,
      state: NoteState.normal,
      visibility: NoteVisibility.private,
      createTime: DateTime(2024, 1, 1),
      updateTime: DateTime(2024, 1, 2),
      displayTime: DateTime(2024, 1, 2),
      resources: [
        {
          'name': 'resources/res1', // Memos identifier
          'filename': 'image.png',
          'contentType': 'image/png',
          'size': 1024,
        }
      ],
      tags: ['test'],
    );

    final sourceComments = [
      Comment(
        id: 'comment-1',
        content: 'First comment',
        createTime: DateTime(2024, 1, 1, 10).millisecondsSinceEpoch,
      ),
    ];

    final resourceBytes = Uint8List.fromList([1, 2, 3]);
    final targetResourceMetadata = {
      'name': 'blinkoResources/some_hash.png', // Blinko identifier/path
      'filename': 'image.png',
      'contentType': 'image/png',
      'size': '1024', // Blinko might return size as string
      'externalLink': '/file/get/some_hash.png',
    };

    final adaptedNoteForTarget = MigrationUtils.adaptNoteForTarget(
      sourceNote,
      targetBlinkoServer.serverType,
      [targetResourceMetadata], // Use the metadata returned by target upload
    );

    final createdTargetNote = adaptedNoteForTarget.copyWith(
      id: 'blinko-note-456', // ID assigned by target
      createTime: DateTime.now(), // Target assigns create/update times
      updateTime: DateTime.now(),
    );

     final adaptedCommentForTarget = MigrationUtils.adaptCommentForTarget(
      sourceComments[0],
      targetBlinkoServer.serverType,
    );

    // --- End Sample Data ---

    setUp(() {
      // Instantiate specific mocks
      mockSourceApiService = MockMemosApiService();
      mockTargetApiService = MockBlinkoApiService();

      container = ProviderContainer(
        overrides: [
          activeServerConfigProvider.overrideWithValue(sourceMemosServer),
          // Use the override pattern from memo_providers_test.dart
          notesNotifierProvider.overrideWith((ref) {
            // Define the initial state needed for the test
            final initialState = NotesState(
              notes: [sourceNote],
              isLoading: false,
            );
            // Create the REAL notifier instance, skipping its async init
            final notifier = NotesNotifier(
              ref,
              skipInitialFetchForTesting: true,
            );
            // Manually set the state
            notifier.state = initialState;
            return notifier;
          }),
          memosApiServiceProvider.overrideWithValue(
            mockSourceApiService,
          ),
          blinkoApiServiceProvider.overrideWithValue(
            mockTargetApiService,
          ),
        ],
      );

      // --- Stub Source Service (Memos) ---
      when(mockSourceApiService.getNote(sourceNoteId))
          .thenAnswer((_) async => sourceNote);
      when(mockSourceApiService.listNoteComments(sourceNoteId))
          .thenAnswer((_) async => sourceComments);
      when(mockSourceApiService.getResourceData('resources/res1'))
          .thenAnswer((_) async => resourceBytes);
      when(mockSourceApiService.deleteNote(sourceNoteId))
          .thenAnswer((_) async => {}); // Simulate successful deletion

      // --- Stub Target Service (Blinko) ---
      when(mockTargetApiService.uploadResource(
        resourceBytes,
        'image.png',
        'image/png',
      )).thenAnswer((_) async => targetResourceMetadata);
      // Use argThat to match the adapted note (ignoring ID and times)
      when(mockTargetApiService.createNote(argThat(predicate<NoteItem>((note) {
          // Compare relevant fields, ignore generated ID/times
          return note.content == adaptedNoteForTarget.content &&
                 note.pinned == adaptedNoteForTarget.pinned &&
                 note.state == adaptedNoteForTarget.state &&
                 note.visibility == adaptedNoteForTarget.visibility &&
                 note.resources?.first['name'] == adaptedNoteForTarget.resources?.first['name'];
      }))))
          .thenAnswer((_) async => createdTargetNote);
       when(mockTargetApiService.createNoteComment(
         createdTargetNote.id, // Expect the ID of the newly created target note
         argThat(predicate<Comment>((comment) {
            // Compare relevant fields of the adapted comment
            return comment.content == adaptedCommentForTarget.content &&
                   comment.state == adaptedCommentForTarget.state &&
                   comment.pinned == adaptedCommentForTarget.pinned;
         })),
       )).thenAnswer((_) async => adaptedCommentForTarget.copyWith(id: 'blinko-comment-789')); // Return a dummy created comment


      // The test implicitly assumes the provider logic correctly selects
      // the right service instance based on the ServerConfig.
      // --- This assumption is removed as we now override the providers ---
    });

    tearDown(() {
      container.dispose();
    });

    test('successfully moves note from Memos to Blinko', () async {
      // Arrange
      final params = MoveNoteParams(
        noteId: sourceNoteId,
        targetServer: targetBlinkoServer,
      );

      // Act
      // We need to simulate the provider calling the correct services.
      // Since we can't directly inject, we rely on the stubs set up in setUp.
      // We'll manually call the methods in the expected order for verification setup.
      // This isn't ideal, but avoids complex mocking of the provider internals for now.

      // **Simulate the provider's internal calls for verification setup**
      // This doesn't run the provider logic, just sets up expectations.
      // The actual execution happens via container.read below.

      // Assert initial state contains the note
      final initialState = container.read(notesNotifierProvider);
      expect(initialState.notes.length, 1);
      expect(initialState.notes.first.id, sourceNoteId);

      // Act: Execute the provider function
      final moveFunction = container.read(moveNoteProvider(params));
      await moveFunction();

      // Assert
      // 1. Optimistic UI update (verify by checking state)
      final finalState = container.read(notesNotifierProvider);
      expect(
        finalState.notes.any((n) => n.id == sourceNoteId),
        isFalse,
        reason: "Note should have been optimistically removed",
      );


      // 2. Source API calls (Keep these)
      verify(mockSourceApiService.getNote(sourceNoteId)).called(1);
      verify(mockSourceApiService.listNoteComments(sourceNoteId)).called(1);
      verify(mockSourceApiService.getResourceData('resources/res1')).called(1);

      // 3. Target API calls (use argThat for complex objects)
      verify(mockTargetApiService.uploadResource(
        resourceBytes,
        'image.png',
        'image/png',
      )).called(1);
      verify(mockTargetApiService.createNote(argThat(predicate<NoteItem>((note) {
          return note.content == adaptedNoteForTarget.content &&
                 note.state == adaptedNoteForTarget.state &&
                 note.resources?.first['name'] == adaptedNoteForTarget.resources?.first['name'];
      })))).called(1);
       verify(mockTargetApiService.createNoteComment(
         createdTargetNote.id,
         argThat(predicate<Comment>((comment) {
            return comment.content == adaptedCommentForTarget.content &&
                   comment.state == adaptedCommentForTarget.state;
         })),
       )).called(1);


      // 4. Source Deletion Call (should happen last)
      verify(mockSourceApiService.deleteNote(sourceNoteId)).called(1);

      // Ensure target deletion wasn't called
      verifyNever(mockTargetApiService.deleteNote(any));
    });

    // TODO: Add more test cases:
    // - Blinko -> Memos success
    // - Target creation failure (no source delete)
    // - Source deletion failure (after target success)
    // - No resources case
    // - No comments case
    // - Same source/target server error
    // - No active source server error
  });
}
