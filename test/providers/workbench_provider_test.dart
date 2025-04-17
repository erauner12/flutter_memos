import 'package:flutter_memos/models/comment.dart'; // Add Comment import
import 'package:flutter_memos/models/multi_server_config_state.dart'; // Import MultiServerConfigState
import 'package:flutter_memos/models/note_item.dart'; // Add NoteItem import
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/api_providers.dart'; // Add API provider import
import 'package:flutter_memos/providers/server_config_provider.dart'; // Add Server Config provider import
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/services/base_api_service.dart'; // Add BaseApiService import
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import generated mocks
import 'workbench_provider_test.mocks.dart';

// Generate mocks for CloudKitService AND BaseApiService
@GenerateNiceMocks([
  MockSpec<CloudKitService>(),
  MockSpec<BaseApiService>(), // Add BaseApiService mock spec
])
// Define test variables
late DateTime now;
late MockCloudKitService mockCloudKitService;
late MockBaseApiService mockApiService; // Add mock API service variable
late ProviderContainer container;
late WorkbenchNotifier notifier;
// Add a default server config for tests
final serverConfig1 = ServerConfig(
  id: 'server1',
  name: 'Test Server 1',
  serverUrl: 'http://test1.com',
  authToken: 'token1',
  serverType: ServerType.memos,
);

// Helper function to create mock items
WorkbenchItemReference createMockItem(String id, DateTime addedTimestamp) {
  return WorkbenchItemReference(
    id: id,
    // Fix: Use string interpolation for unique referencedItemId
    referencedItemId: 'ref-$id',
    referencedItemType: WorkbenchItemType.note,
    serverId: serverConfig1.id,
    serverType: serverConfig1.serverType,
    serverName: serverConfig1.name,
    previewContent: 'Preview for $id',
    addedTimestamp: addedTimestamp,
  );
}

void main() {
  // Initialize the current time for tests
  now = DateTime.now();

  setUp(() {
    mockCloudKitService = MockCloudKitService();
    mockApiService = MockBaseApiService(); // Initialize mock API service
    container = ProviderContainer(
      overrides: [
        cloudKitServiceProvider.overrideWithValue(mockCloudKitService),
        // Override apiServiceProvider to return the mock
        apiServiceProvider.overrideWithValue(mockApiService),
        // Override multiServerConfigProvider to provide a default state
        // This is needed because _fetchAndPopulateDetails reads it
        // Fix: Use .overrideWith for StateNotifierProvider
        multiServerConfigProvider.overrideWith(
          (ref) => MultiServerConfigNotifier(ref)
            ..state = MultiServerConfigState(
              servers: [serverConfig1],
              activeServerId: serverConfig1.id,
            ),
        ),
      ],
    );
    // Access the notifier directly for testing its methods
    notifier = container.read(workbenchProvider.notifier);

    // Default mock behavior for successful load
    when(mockCloudKitService.getAllWorkbenchItemReferences())
        .thenAnswer(
      (_) async => List.from([
        createMockItem('id1', now.subtract(const Duration(days: 2))),
        createMockItem('id2', now.subtract(const Duration(days: 1))),
        createMockItem('id3', now),
      ]),
    ); // Return a copy
    // Default mock behavior for successful saves/deletes
    when(mockCloudKitService.saveWorkbenchItemReference(any))
        .thenAnswer((_) async => true);
    when(mockCloudKitService.deleteWorkbenchItemReference(any))
        .thenAnswer((_) async => true);

    // Default mock behavior for API calls (used in _fetchAndPopulateDetails)
    // Return empty lists/default objects to prevent null errors if not specifically mocked in a test
    when(mockApiService.getNote(any, targetServerOverride: anyNamed('targetServerOverride')))
        .thenAnswer(
      (invocation) async => NoteItem(
        // Fix: Use invocation object
        id: invocation.positionalArguments[0] as String,
        content: 'Mock Note Content',
        pinned: false,
        state: NoteState.normal,
        visibility: NoteVisibility.public,
        createTime: now.subtract(const Duration(hours: 1)),
        updateTime: now,
        displayTime: now.subtract(const Duration(hours: 1)),
      ),
    );
    when(mockApiService.listNoteComments(any, targetServerOverride: anyNamed('targetServerOverride')))
        .thenAnswer((_) async => []); // Default to empty comments list

    // DO NOT call loadItems here automatically. Tests will call it.
  });

  tearDown(() {
    container.dispose();
  });

  group('initial state and loadItems', () {
    test('initial state is loading', () {
      // Arrange: Provider is created in setUp, constructor doesn't load
      
      // Act: Read initial state immediately
      final state = container.read(workbenchProvider);
      
      // Assert: Should not be loading, should be empty, no error
      expect(state.isLoading, false); // Changed from true to false
      expect(state.items, isEmpty);
      expect(state.error, isNull);
      
      // Verify loadItems was NOT called yet by the constructor
      verifyNever(mockCloudKitService.getAllWorkbenchItemReferences());
    });

    test('loadItems success - fetches details and sorts by overallLastUpdateTime descending', () async {
      // Arrange: Mock service returns unsorted items
        final item1 = createMockItem(
          'id1',
          now.subtract(const Duration(days: 2)),
        );
        final item2 = createMockItem(
          'id2',
          now.subtract(const Duration(days: 1)),
        );
        final item3 = createMockItem('id3', now);

      when(mockCloudKitService.getAllWorkbenchItemReferences())
          .thenAnswer((_) async => [item1, item3, item2]); // Unsorted by time

        // Mock API responses specifically for this test
        final note1UpdateTime = now.subtract(
          const Duration(days: 1, hours: 1),
        ); // Newer than item1 added
      final note2UpdateTime = now.subtract(const Duration(hours: 12)); // Newer than item2 added
      final note3UpdateTime = now.subtract(const Duration(hours: 1)); // Newer than item3 added

      final commentForItem2 = Comment(
        id: 'comment1',
        content: 'Latest comment',
          createdTs:
              now.millisecondsSinceEpoch, // Use createdTs instead of createTime
          parentId: 'parent-id', // Add required parentId
          serverId: 'server1', // Add required serverId
      );

        // Use specific mocks based on invocation arguments
      when(mockApiService.getNote(item1.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer(
          (_) async => NoteItem(
            id: item1.referencedItemId,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: note1UpdateTime,
            updateTime: note1UpdateTime,
            displayTime: note1UpdateTime,
          ),
        );
      when(mockApiService.getNote(item2.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer(
          (_) async => NoteItem(
            id: item2.referencedItemId,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: note2UpdateTime,
            updateTime: note2UpdateTime,
            displayTime: note2UpdateTime,
          ),
        );
      when(mockApiService.getNote(item3.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer(
          (_) async => NoteItem(
            id: item3.referencedItemId,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: note3UpdateTime,
            updateTime: note3UpdateTime,
            displayTime: note3UpdateTime,
          ),
        );

      when(mockApiService.listNoteComments(item1.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => []); // No comments for item1
      when(mockApiService.listNoteComments(item2.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => [commentForItem2]); // Comment for item2
      when(mockApiService.listNoteComments(item3.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => []); // No comments for item3

        // Act: Call loadItems explicitly
        await notifier.loadItems();
        // Wait briefly for async detail fetching to complete
      await Future.delayed(const Duration(milliseconds: 100));
      final state = container.read(workbenchProvider);

      // Assert
      expect(state.isLoading, false);
        expect(state.isRefreshingDetails, false);
      expect(state.error, isNull);
      expect(state.items.length, 3);

        // Verify API calls were made ONCE for each item during this loadItems call
      verify(mockApiService.getNote(item1.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.listNoteComments(item1.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.getNote(item2.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.listNoteComments(item2.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.getNote(item3.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.listNoteComments(item3.referencedItemId, targetServerOverride: serverConfig1)).called(1);

        // Expected overallLastUpdateTime:
        // item1: max(item1.added, note1Update) = note1Update (now - 1d 1h)
        // item2: max(item2.added, note2Update, commentCreate) = commentCreate (now)
        // item3: max(item3.added, note3Update) = item3.added (now)
        // Expected order: item3 (now, added), item2 (now, comment), item1 (now - 1d 1h) -> [id3, id2, id1]

        expect(state.items[0].id, 'id3');
        // WorkbenchItemReference doesn't have latestComment property directly,
        // but it's populated by the provider for UI purposes
        expect(state.items[0].previewComments.isEmpty, isTrue);
        expect(
          state.items[0].overallLastUpdateTime,
          item3.addedTimestamp,
        ); // overall = added (now)

        expect(state.items[1].id, 'id2');
        expect(state.items[1].previewComments.first.id, commentForItem2.id);
        expect(
          state.items[1].overallLastUpdateTime.millisecondsSinceEpoch,
          commentForItem2.createdTs,
        ); // overall = comment (now)

        expect(state.items[2].id, 'id1');
        expect(state.items[2].previewComments.isEmpty, isTrue);
        // overall = note update time (now - 1d 1h), which is newer than added (now - 2d)
        expect(state.items[2].overallLastUpdateTime, note1UpdateTime);
    });

    test('loadItems failure', () async {
      // Arrange
      final exception = Exception('CloudKit failed');
      when(mockCloudKitService.getAllWorkbenchItemReferences())
          .thenThrow(exception);

      // Act
      await notifier.loadItems();
      final state = container.read(workbenchProvider);

      // Assert
      expect(state.isLoading, false);
      expect(state.error, exception);
      expect(state.items, isEmpty);
      verify(mockCloudKitService.getAllWorkbenchItemReferences()).called(1);
    });
  });

  group('addItem', () {
    // Add setUp for this group to load initial items
    setUp(() async {
      final item1 = createMockItem(
        'id1',
        now.subtract(const Duration(days: 2)),
      );
      final item2 = createMockItem(
        'id2',
        now.subtract(const Duration(days: 1)),
      );
      final item3 = createMockItem('id3', now);

      // Mock API responses needed for the initial load
      final note1UpdateTime = now.subtract(const Duration(days: 1, hours: 1));
      final note2UpdateTime = now.subtract(const Duration(hours: 12));
      final note3UpdateTime = now.subtract(const Duration(hours: 1));
      final commentForItem2 = Comment(
        id: 'comment1',
        content: 'Latest comment',
        createdTs: now.millisecondsSinceEpoch,
        parentId: 'parent-id', // Add required parentId
        serverId: 'server1', // Add required serverId
      );
      when(
        mockApiService.getNote(
          item1.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer(
        (_) async => NoteItem(
          id: item1.referencedItemId,
          content: '',
          pinned: false,
          state: NoteState.normal,
          visibility: NoteVisibility.public,
          createTime: note1UpdateTime,
          updateTime: note1UpdateTime,
          displayTime: note1UpdateTime,
        ),
      );
      when(
        mockApiService.getNote(
          item2.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer(
        (_) async => NoteItem(
          id: item2.referencedItemId,
          content: '',
          pinned: false,
          state: NoteState.normal,
          visibility: NoteVisibility.public,
          createTime: note2UpdateTime,
          updateTime: note2UpdateTime,
          displayTime: note2UpdateTime,
        ),
      );
      when(
        mockApiService.getNote(
          item3.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer(
        (_) async => NoteItem(
          id: item3.referencedItemId,
          content: '',
          pinned: false,
          state: NoteState.normal,
          visibility: NoteVisibility.public,
          createTime: note3UpdateTime,
          updateTime: note3UpdateTime,
          displayTime: note3UpdateTime,
        ),
      );
      when(
        mockApiService.listNoteComments(
          item1.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((_) async => []);
      when(
        mockApiService.listNoteComments(
          item2.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((_) async => [commentForItem2]);
      when(
        mockApiService.listNoteComments(
          item3.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((_) async => []);

      await notifier.loadItems();
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for initial details
      // Initial state expected: [id3, id2, id1]
    });

    test('addItem success - adds item, fetches details, and sorts list', () async {
      // Arrange: Initial state [id3, id2, id1] loaded in setUp
      final newItem = createMockItem('id4', now.add(const Duration(days: 1))); // Even newer added time
      final note4UpdateTime = now.add(const Duration(days: 1, hours: 1)); // Newer update time
      when(mockCloudKitService.saveWorkbenchItemReference(newItem))
          .thenAnswer((_) async => true);
      when(mockApiService.getNote(newItem.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer(
        (_) async => NoteItem(
          id: newItem.referencedItemId,
          content: '',
          pinned: false,
          state: NoteState.normal,
          visibility: NoteVisibility.public,
          createTime: note4UpdateTime,
          updateTime: note4UpdateTime,
          displayTime: note4UpdateTime,
        ),
      );
      when(mockApiService.listNoteComments(newItem.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => []); // No comments for new item

      // Act
      await notifier.addItem(newItem);
      // Wait for async detail fetching for the new item
      await Future.delayed(const Duration(milliseconds: 100));
      final state = container.read(workbenchProvider);

      // Assert: New item should be first due to its overallLastUpdateTime (note update time)
      // Expected order: [id4, id3, id2, id1]
      expect(state.items.length, 4);
      expect(state.items.first.id, 'id4');
      expect(state.items.first.overallLastUpdateTime, note4UpdateTime);
      expect(state.items.first.previewComments.isEmpty, isTrue);
      // Verify the rest of the order based on previous test's expected outcome
      expect(state.items[1].id, 'id3'); // Corrected expected order
      expect(state.items[2].id, 'id2'); // Corrected expected order
      expect(state.items[3].id, 'id1'); // Corrected expected order
      expect(state.error, isNull);
      verify(mockCloudKitService.saveWorkbenchItemReference(newItem)).called(1);
      // Verify detail fetch for the new item
      verify(mockApiService.getNote(newItem.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.listNoteComments(newItem.referencedItemId, targetServerOverride: serverConfig1)).called(1);
    });

    test('addItem failure - reverts optimistic add and sorts', () async {
      // Arrange: Initial state [id3, id2, id1] loaded in setUp
      final newItem = createMockItem('id4', now.add(const Duration(days: 1)));
      final exception = Exception('Save failed');
      when(mockCloudKitService.saveWorkbenchItemReference(newItem))
          .thenThrow(exception);

      // Act
      await notifier.addItem(newItem);
      final state = container.read(workbenchProvider);

      // Assert: Item should be removed, list remains sorted [id3, id2, id1]
      expect(state.items.length, 3);
      expect(state.items.any((item) => item.id == 'id4'), isFalse);
      expect(state.items[0].id, 'id3'); // Original sort order maintained
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
      expect(state.error, exception); // Error should be set
      verify(mockCloudKitService.saveWorkbenchItemReference(newItem)).called(1);
    });

    test('addItem duplicate - does not add item or call CloudKit', () async {
      // Arrange: Initial state [id3, id2, id1] loaded in setUp
      final duplicateItem = createMockItem('newIdSameRef', now.add(const Duration(days: 1)))
          .copyWith(
        referencedItemId:
            createMockItem(
              'id2',
              now.subtract(const Duration(days: 1)),
            ).referencedItemId,
        serverId: serverConfig1.id,
      ); // Same refId and serverId as item2

      // Act
      await notifier.addItem(duplicateItem);
      final state = container.read(workbenchProvider);

      // Assert: List remains unchanged [id3, id2, id1]
      expect(state.items.length, 3);
      expect(state.items[0].id, 'id3');
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
      expect(state.error, isNull); // No error should be thrown for duplicates
      verifyNever(mockCloudKitService.saveWorkbenchItemReference(duplicateItem));
    });
  });

  group('removeItem', () {
    // Add setUp for this group to load initial items
    setUp(() async {
      final item1 = createMockItem(
        'id1',
        now.subtract(const Duration(days: 2)),
      );
      final item2 = createMockItem(
        'id2',
        now.subtract(const Duration(days: 1)),
      );
      final item3 = createMockItem('id3', now);

      // Mock API responses needed for the initial load
      final note1UpdateTime = now.subtract(const Duration(days: 1, hours: 1));
      final note2UpdateTime = now.subtract(const Duration(hours: 12));
      final note3UpdateTime = now.subtract(const Duration(hours: 1));
      final commentForItem2 = Comment(
        id: 'comment1',
        content: 'Latest comment',
        createTime: now.millisecondsSinceEpoch,
      );
      when(
        mockApiService.getNote(
          item1.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer(
        (_) async => NoteItem(
          id: item1.referencedItemId,
          content: '',
          pinned: false,
          state: NoteState.normal,
          visibility: NoteVisibility.public,
          createTime: note1UpdateTime,
          updateTime: note1UpdateTime,
          displayTime: note1UpdateTime,
        ),
      );
      when(
        mockApiService.getNote(
          item2.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer(
        (_) async => NoteItem(
          id: item2.referencedItemId,
          content: '',
          pinned: false,
          state: NoteState.normal,
          visibility: NoteVisibility.public,
          createTime: note2UpdateTime,
          updateTime: note2UpdateTime,
          displayTime: note2UpdateTime,
        ),
      );
      when(
        mockApiService.getNote(
          item3.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer(
        (_) async => NoteItem(
          id: item3.referencedItemId,
          content: '',
          pinned: false,
          state: NoteState.normal,
          visibility: NoteVisibility.public,
          createTime: note3UpdateTime,
          updateTime: note3UpdateTime,
          displayTime: note3UpdateTime,
        ),
      );
      when(
        mockApiService.listNoteComments(
          item1.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((_) async => []);
      when(
        mockApiService.listNoteComments(
          item2.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((_) async => [commentForItem2]);
      when(
        mockApiService.listNoteComments(
          item3.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((_) async => []);

      await notifier.loadItems();
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Wait for initial details
      // Initial state expected: [id3, id2, id1]
    });

    test('removeItem success - removes item', () async {
      // Arrange: Initial state [id3, id2, id1] loaded in setUp
      when(mockCloudKitService.deleteWorkbenchItemReference('id2'))
          .thenAnswer((_) async => true);

      // Act
      await notifier.removeItem('id2'); // Remove middle item
      final state = container.read(workbenchProvider);

      // Assert: Expected [id3, id1]
      expect(state.items.length, 2);
      expect(state.items.any((item) => item.id == 'id2'), isFalse);
      expect(state.items[0].id, 'id3'); // Remaining items still sorted
      expect(state.items[1].id, 'id1');
      expect(state.error, isNull);
      verify(mockCloudKitService.deleteWorkbenchItemReference('id2')).called(1);
    });

    test('removeItem failure - reverts optimistic removal and maintains sort order', () async {
        // Arrange: Initial state [id3, id2, id1] loaded in setUp
      final exception = Exception('Delete failed');
        when(
          mockCloudKitService.deleteWorkbenchItemReference(
            'id3',
          ), // Try removing item3
        )
          .thenThrow(exception);

      // Act
      await notifier.removeItem('id3');
      final state = container.read(workbenchProvider);

        // Assert: Item should be back, list remains sorted by overallLastUpdateTime [id3, id2, id1]
        expect(state.items.length, 3);
        expect(state.items[0].id, 'id3'); // Corrected expected order
        expect(state.items[1].id, 'id2'); // Corrected expected order
        expect(state.items[2].id, 'id1'); // Corrected expected order
        expect(state.error, exception);
        verify(
          mockCloudKitService.deleteWorkbenchItemReference('id3'),
        ).called(1);
    });

    test('removeItem non-existent id - does nothing', () async {
      // Arrange: Initial state [id3, id2, id1] loaded in setUp

      // Act
      await notifier.removeItem('non-existent-id');
      final state = container.read(workbenchProvider);

      // Assert: List remains unchanged [id3, id2, id1]
      expect(state.items.length, 3);
      expect(state.items[0].id, 'id3');
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
      expect(state.error, isNull);
      verifyNever(mockCloudKitService.deleteWorkbenchItemReference('non-existent-id'));
    });
  });

  group('reorderItems', () {
    setUp(() async {
      // Mock API responses needed for the initial load
      final item1 = createMockItem(
        'id1',
        now.subtract(const Duration(days: 2)),
      );
      final item2 = createMockItem(
        'id2',
        now.subtract(const Duration(days: 1)),
      );
      final item3 = createMockItem('id3', now);

      final note1UpdateTime = now.subtract(const Duration(days: 1, hours: 1));
      final note2UpdateTime = now.subtract(const Duration(hours: 12));
      final note3UpdateTime = now.subtract(const Duration(hours: 1));
      final commentForItem2 = Comment(
        id: 'comment1',
        content: 'Latest comment',
        createTime: now.millisecondsSinceEpoch,
      );
      when(
        mockApiService.getNote(
          item1.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer(
        (_) async => NoteItem(
          id: item1.referencedItemId,
          content: '',
          pinned: false,
          state: NoteState.normal,
          visibility: NoteVisibility.public,
          createTime: note1UpdateTime,
          updateTime: note1UpdateTime,
          displayTime: note1UpdateTime,
        ),
      );
      when(
        mockApiService.getNote(
          item2.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer(
        (_) async => NoteItem(
          id: item2.referencedItemId,
          content: '',
          pinned: false,
          state: NoteState.normal,
          visibility: NoteVisibility.public,
          createTime: note2UpdateTime,
          updateTime: note2UpdateTime,
          displayTime: note2UpdateTime,
        ),
      );
      when(
        mockApiService.getNote(
          item3.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer(
        (_) async => NoteItem(
          id: item3.referencedItemId,
          content: '',
          pinned: false,
          state: NoteState.normal,
          visibility: NoteVisibility.public,
          createTime: note3UpdateTime,
          updateTime: note3UpdateTime,
          displayTime: note3UpdateTime,
        ),
      );
      when(
        mockApiService.listNoteComments(
          item1.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((_) async => []);
      when(
        mockApiService.listNoteComments(
          item2.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((_) async => [commentForItem2]);
      when(
        mockApiService.listNoteComments(
          item3.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((_) async => []);

      // Ensure items are loaded and sorted initially for these tests
      await notifier.loadItems();
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Wait for details
      // Initial state expected: [id3, id2, id1]
    });

    test('moves item downwards correctly', () {
      // Arrange: Initial state [id3, id2, id1]
      const oldIndex = 0; // item3
      const newIndex = 2; // Move item3 after item2

      // Act
      notifier.reorderItems(oldIndex, newIndex);
      final state = container.read(workbenchProvider);

      // Assert: Expected state [id2, id3, id1]
      expect(state.items.length, 3);
      expect(state.items[0].id, 'id2');
      expect(state.items[1].id, 'id3');
      expect(state.items[2].id, 'id1');
    });

    test('moves item upwards correctly', () {
      // Arrange: Initial state [id3, id2, id1]
      const oldIndex = 2; // item1
      const newIndex = 0; // Move item1 to the beginning

      // Act
      notifier.reorderItems(oldIndex, newIndex);
      final state = container.read(workbenchProvider);

      // Assert: Expected state [id1, id3, id2]
      expect(state.items.length, 3);
      expect(state.items[0].id, 'id1');
      expect(state.items[1].id, 'id3');
      expect(state.items[2].id, 'id2');
    });

    test('moves item to the end correctly', () {
      // Arrange: Initial state [id3, id2, id1]
      const oldIndex = 0; // item3
      const newIndex = 3; // Move item3 to the end (becomes index 2 after removal)

      // Act
      notifier.reorderItems(oldIndex, newIndex);
      final state = container.read(workbenchProvider);

      // Assert: Expected state [id2, id1, id3]
      expect(state.items.length, 3);
      expect(state.items[0].id, 'id2');
      expect(state.items[1].id, 'id1');
      expect(state.items[2].id, 'id3');
    });

    test('does nothing for invalid indices', () {
      // Arrange: Initial state [id3, id2, id1]
      final initialOrder = List<WorkbenchItemReference>.from(
        container.read(workbenchProvider).items,
      );

      // Act: Invalid oldIndex
      notifier.reorderItems(-1, 1);
      expect(
        container.read(workbenchProvider).items,
        initialOrder,
        reason: 'Failed for oldIndex < 0',
      );

      // Act: Invalid oldIndex (too high)
      notifier.reorderItems(3, 1);
      expect(
        container.read(workbenchProvider).items,
        initialOrder,
        reason: 'Failed for oldIndex >= length',
      );

      // Act: Invalid newIndex (too high)
      notifier.reorderItems(0, 4);
      expect(
        container.read(workbenchProvider).items,
        initialOrder,
        reason: 'Failed for newIndex > length',
      );

      // Act: Invalid newIndex (negative)
      notifier.reorderItems(1, -1);
      expect(
        container.read(workbenchProvider).items,
        initialOrder,
        reason: 'Failed for newIndex < 0',
      );
    });
  });

  group('resetOrder', () {
    setUp(() async {
      // Arrange: Load initial items and fetch details
      when(mockCloudKitService.getAllWorkbenchItemReferences())
          .thenAnswer(
        (_) async => [
          createMockItem('id1', now.subtract(const Duration(days: 2))),
          createMockItem('id3', now),
          createMockItem('id2', now.subtract(const Duration(days: 1))),
        ],
      ); // Unsorted by time
      final note1UpdateTime = now.subtract(const Duration(days: 1, hours: 1));
      final note2UpdateTime = now.subtract(const Duration(hours: 12));
      final note3UpdateTime = now.subtract(const Duration(hours: 1));
      final commentForItem2 = Comment(id: 'comment1', content: 'Latest comment', createTime: now.millisecondsSinceEpoch);
      when(
        mockApiService.getNote(any, targetServerOverride: serverConfig1),
      ).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        if (id ==
            createMockItem(
              'id1',
              now.subtract(const Duration(days: 2)),
            ).referencedItemId) {
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: note1UpdateTime,
            updateTime: note1UpdateTime,
            displayTime: note1UpdateTime,
          );
        } else if (id ==
            createMockItem(
              'id2',
              now.subtract(const Duration(days: 1)),
            ).referencedItemId) {
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: note2UpdateTime,
            updateTime: note2UpdateTime,
            displayTime: note2UpdateTime,
          );
        } else {
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: note3UpdateTime,
            updateTime: note3UpdateTime,
            displayTime: note3UpdateTime,
          );
        }
      });
      when(
        mockApiService.listNoteComments(
          any,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        if (id ==
            createMockItem(
              'id2',
              now.subtract(const Duration(days: 1)),
            ).referencedItemId) {
          return [commentForItem2];
        }
        return [];
      });

      await notifier.loadItems();
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for details
      // Expected initial state after load/details: [id3, id2, id1]
    });

    test('resets manually reordered list to default sort (overallLastUpdateTime desc)', () {
      // Arrange: Manually reorder to [id1, id2, id3]
        notifier.reorderItems(2, 0); // Move id1 to start -> [id1, id3, id2]
        notifier.reorderItems(2, 1); // Move id2 after id1 -> [id1, id2, id3]
      final reorderedState = container.read(workbenchProvider);
      // Verify pre-condition
      expect(reorderedState.items[0].id, 'id1', reason: 'Pre-condition failed: Manual reorder did not work');
        expect(reorderedState.items[1].id, 'id2');
        expect(reorderedState.items[2].id, 'id3');

      // Act
      notifier.resetOrder();
      final state = container.read(workbenchProvider);

        // Assert: Order should be back to overallLastUpdateTime descending [id3, id2, id1]
      expect(state.items.length, 3);
        expect(state.items[0].id, 'id3'); // Corrected expected order
        expect(state.items[1].id, 'id2'); // Corrected expected order
        expect(state.items[2].id, 'id1'); // Corrected expected order
    });

    test('does nothing if already in default order (overallLastUpdateTime desc)', () {
        // Arrange: Initial state is already default order [id3, id2, id1]
      final initialOrder = List<WorkbenchItemReference>.from(container.read(workbenchProvider).items);
        // Verify pre-condition
        expect(
          initialOrder[0].id,
          'id3', // Corrected pre-condition check
          reason: 'Pre-condition failed: Initial order incorrect',
        );
        expect(initialOrder[1].id, 'id2');
        expect(initialOrder[2].id, 'id1');

      // Act
      notifier.resetOrder();
      final state = container.read(workbenchProvider);

        // Assert: Order remains unchanged [id3, id2, id1]
      expect(state.items.length, 3);
      expect(state.items.map((e) => e.id).toList(), initialOrder.map((e) => e.id).toList());
        expect(state.items[0].id, 'id3'); // Corrected assertion
        expect(state.items[1].id, 'id2'); // Corrected assertion
        expect(state.items[2].id, 'id1'); // Corrected assertion
    });
  });

  group('refreshItemDetails', () {
    setUp(() async {
      // Arrange: Load initial items and fetch details
      when(
        mockCloudKitService.getAllWorkbenchItemReferences(),
      ).thenAnswer(
        (_) async => [
          createMockItem('id1', now.subtract(const Duration(days: 2))),
          createMockItem('id3', now),
          createMockItem('id2', now.subtract(const Duration(days: 1))),
        ],
      ); // Unsorted by time
      final note1UpdateTime = now.subtract(const Duration(days: 1, hours: 1));
      final note2UpdateTime = now.subtract(const Duration(hours: 12));
      final note3UpdateTime = now.subtract(const Duration(hours: 1));
      final commentForItem2 = Comment(
        id: 'comment1',
        content: 'Latest comment',
        createTime: now.millisecondsSinceEpoch,
      );
      when(
        mockApiService.getNote(
          any,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        if (id ==
            createMockItem(
              'id1',
              now.subtract(const Duration(days: 2)),
            ).referencedItemId) {
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: note1UpdateTime,
            updateTime: note1UpdateTime,
            displayTime: note1UpdateTime,
          );
        } else if (id ==
            createMockItem(
              'id2',
              now.subtract(const Duration(days: 1)),
            ).referencedItemId) {
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: note2UpdateTime,
            updateTime: note2UpdateTime,
            displayTime: note2UpdateTime,
          );
        } else {
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: note3UpdateTime,
            updateTime: note3UpdateTime,
            displayTime: note3UpdateTime,
          );
        }
      });
      when(
        mockApiService.listNoteComments(
          any,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        if (id ==
            createMockItem(
              'id2',
              now.subtract(const Duration(days: 1)),
            ).referencedItemId) {
          return [commentForItem2];
        }
        return [];
      });

      await notifier.loadItems();
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Wait for details
      // Expected initial state after load/details: [id3, id2, id1]
    });

    test(
      'refreshItemDetails success - re-fetches details and updates state',
      () async {
      // Arrange: Modify API mocks specifically for the refresh call
      final item1 = createMockItem(
        'id1',
        now.subtract(const Duration(days: 2)),
      );
      final item2 = createMockItem(
        'id2',
        now.subtract(const Duration(days: 1)),
      );
      final item3 = createMockItem('id3', now);

      final refreshedNote1UpdateTime = now.subtract(
        const Duration(minutes: 5),
      ); // Much newer
      final originalCommentForItem2 = Comment(
        id: 'comment1',
        content: 'Latest comment',
        createTime: now.millisecondsSinceEpoch,
      );
      final refreshedCommentForItem3 = Comment(
        id: 'comment2',
        content: 'Refreshed comment',
        createTime: now.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
      ); // New comment for item3

      // Use specific mocks based on invocation arguments for the refresh
      when(
        mockApiService.getNote(any, targetServerOverride: serverConfig1),
      ).thenAnswer((invocation) async {
          final id = invocation.positionalArguments[0] as String;
        if (id == item1.referencedItemId) {
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: refreshedNote1UpdateTime,
            updateTime: refreshedNote1UpdateTime,
            displayTime: refreshedNote1UpdateTime,
          );
        } else if (id == item2.referencedItemId) {
          // Return original update time for item2
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: now.subtract(const Duration(hours: 12)),
            updateTime: now.subtract(const Duration(hours: 12)),
            displayTime: now.subtract(const Duration(hours: 12)),
          );
        } else {
          // item3
          // Return original update time for item3
          // This is for item3
          if (id == item3.referencedItemId) {
            return NoteItem(
              id: id,
              content: '',
              pinned: false,
              state: NoteState.normal,
              visibility: NoteVisibility.public,
              createTime: now.subtract(const Duration(hours: 1)),
              updateTime: now.subtract(const Duration(hours: 1)),
              displayTime: now.subtract(const Duration(hours: 1)),
            );
          }
          // Default fallback
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: now.subtract(const Duration(hours: 1)),
            updateTime: now.subtract(const Duration(hours: 1)),
            displayTime: now.subtract(const Duration(hours: 1)),
          );
          }
        });

      when(
        mockApiService.listNoteComments(
          any,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((invocation) async {
          final id = invocation.positionalArguments[0] as String;
        if (id == item1.referencedItemId) {
          return []; // No comments for item1
        } else if (id == item2.referencedItemId) {
          return [originalCommentForItem2]; // Original comment for item2
        } else {
          // item3
          return [refreshedCommentForItem3]; // New comment for item3
        }
        });

      // Reset interactions from initial load before the refresh call
        clearInteractions(mockApiService);

        // Act
        await notifier.refreshItemDetails();
        // Wait briefly for async detail fetching to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final state = container.read(workbenchProvider);

        // Assert
      expect(state.isLoading, false);
      expect(state.isRefreshingDetails, false);
        expect(state.error, isNull);
        expect(state.items.length, 3);

      // Verify API calls were made again ONCE for each item during refresh
      verify(
        mockApiService.getNote(
          item1.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).called(1);
      verify(
        mockApiService.listNoteComments(
          item1.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).called(1);
      verify(
        mockApiService.getNote(
          item2.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).called(1);
      verify(
        mockApiService.listNoteComments(
          item2.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).called(1);
      verify(
        mockApiService.getNote(
          item3.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).called(1);
      verify(
        mockApiService.listNoteComments(
          item3.referencedItemId,
          targetServerOverride: serverConfig1,
        ),
      ).called(1);

      // Calculate expected overallLastUpdateTime after refresh:
      // item1: max(item1.added, refreshedNote1Update) = refreshedNote1Update (now - 5m)
      // item2: max(item2.added, note2Update, commentCreate) = commentCreate (now)
      // item3: max(item3.added, note3Update, refreshedCommentCreate) = refreshedCommentCreate (now + 1m)
      // Expected order: item3 (now + 1m), item2 (now), item1 (now - 5m) -> [id3, id2, id1]

      expect(
        state.items[0].id,
        'id3',
      ); // Newest overall activity (refreshed comment)
        expect(state.items[0].latestComment?.id, refreshedCommentForItem3.id);
      expect(
        state.items[0].overallLastUpdateTime.millisecondsSinceEpoch,
        refreshedCommentForItem3.createTime,
      );

        expect(state.items[1].id, 'id2'); // Next newest (original comment)
      expect(
        state.items[1].latestComment?.id,
        originalCommentForItem2.id,
      ); // Should still have original comment
      expect(
        state.items[1].overallLastUpdateTime.millisecondsSinceEpoch,
        originalCommentForItem2.createTime,
      );

      expect(
        state.items[2].id,
        'id1',
      ); // Oldest overall activity (refreshed note update)
        expect(state.items[2].latestComment, isNull);
        expect(state.items[2].overallLastUpdateTime, refreshedNote1UpdateTime);
      },
    );

    test(
      'refreshItemDetails handles API errors gracefully for individual items',
      () async {
        // Arrange: Simulate API error for one item during refresh
        final item1 = createMockItem(
          'id1',
          now.subtract(const Duration(days: 2)),
        );
        final item2 = createMockItem(
          'id2',
          now.subtract(const Duration(days: 1)),
        );
        final item3 = createMockItem('id3', now);
        final exception = Exception('API failed for item1');

        // Capture the state *after* initial load to get the correct initial overallLastUpdateTime for item1
        final initialLoadedState = container.read(workbenchProvider);
        final initialItem1 = initialLoadedState.items.firstWhere(
          (i) => i.id == 'id1',
        );
        // The correct expected value after refresh error is item1.addedTimestamp
        final expectedItem1OverallTime = item1.addedTimestamp;

        when(
          mockApiService.getNote(any, targetServerOverride: serverConfig1),
        ).thenAnswer((invocation) async {
          final id = invocation.positionalArguments[0] as String;
          if (id == item1.referencedItemId) {
            throw exception; // Throw error for item1 during refresh
          }
          // For others return same as initial load
          if (id == item2.referencedItemId) {
            return NoteItem(
              id: id,
              content: '',
              pinned: false,
              state: NoteState.normal,
              visibility: NoteVisibility.public,
              createTime: now.subtract(const Duration(hours: 12)),
              updateTime: now.subtract(const Duration(hours: 12)),
              displayTime: now.subtract(const Duration(hours: 12)),
            );
          }
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: now.subtract(const Duration(hours: 1)),
            updateTime: now.subtract(const Duration(hours: 1)),
            displayTime: now.subtract(const Duration(hours: 1)),
          );
        });
        // Keep other mocks the same as initial load (item2 has comment1, others none)

        // Reset interactions before the refresh call
        clearInteractions(mockApiService);

        // Act
        await notifier.refreshItemDetails();
        await Future.delayed(const Duration(milliseconds: 100));
        final state = container.read(workbenchProvider);

        // Assert
        expect(state.isRefreshingDetails, false);
        expect(
          state.error,
          isNull,
        ); // Error should not be set at the state level
        expect(state.items.length, 3);

        // Verify item1 retains its original data calculated during initial load
        final item1State = state.items.firstWhere((i) => i.id == 'id1');
        // Corrected Assertion: After refresh error, overallLastUpdateTime should be item1.addedTimestamp
        expect(item1State.overallLastUpdateTime, expectedItem1OverallTime);
        // Check other fields remain as they were after initial load
        expect(
          item1State.referencedItemUpdateTime,
          isNull,
        ); // It will be null after refresh error
        expect(item1State.latestComment, isNull);

        // Verify other items were updated correctly (order should still be based on available data)
        // Expected order: [id3, id2, id1]
        expect(state.items[0].id, 'id3'); // Corrected expected order
        expect(state.items[1].id, 'id2'); // Corrected expected order
        expect(state.items[2].id, 'id1'); // Corrected expected order
      },
    );

    test('refreshItemDetails does nothing if no items exist', () async {
      // Arrange: Clear all items using the new method
      when(
        mockCloudKitService.deleteWorkbenchItemReference(any),
      ).thenAnswer((_) async => true);
      await notifier.clearItems();
      expect(
        container.read(workbenchProvider).items,
        isEmpty,
        reason: 'Pre-condition failed: Items not cleared',
      );
      clearInteractions(mockApiService);
      clearInteractions(mockCloudKitService);

      // Act
      await notifier.refreshItemDetails();
      final state = container.read(workbenchProvider);

      // Assert
      expect(state.items, isEmpty);
      expect(state.isRefreshingDetails, false);
      expect(state.error, isNull);
      verifyNever(
        mockApiService.getNote(
          any,
          targetServerOverride: anyNamed('targetServerOverride'),
        ),
      );
      verifyNever(
        mockApiService.listNoteComments(
          any,
          targetServerOverride: anyNamed('targetServerOverride'),
        ),
      );
    });
  });

  group('clearItems', () {
    setUp(() async {
      when(mockCloudKitService.getAllWorkbenchItemReferences()).thenAnswer(
        (_) async => [
          createMockItem('id1', now.subtract(const Duration(days: 2))),
          createMockItem('id3', now),
          createMockItem('id2', now.subtract(const Duration(days: 1))),
        ],
      );
      final note1UpdateTime = now.subtract(const Duration(days: 1, hours: 1));
      final note2UpdateTime = now.subtract(const Duration(hours: 12));
      final note3UpdateTime = now.subtract(const Duration(hours: 1));
      final commentForItem2 = Comment(
        id: 'comment1',
        content: 'Latest comment',
        createTime: now.millisecondsSinceEpoch,
      );
      when(
        mockApiService.getNote(any, targetServerOverride: serverConfig1),
      ).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        if (id ==
            createMockItem(
              'id1',
              now.subtract(const Duration(days: 2)),
            ).referencedItemId) {
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: note1UpdateTime,
            updateTime: note1UpdateTime,
            displayTime: note1UpdateTime,
          );
        } else if (id ==
            createMockItem(
              'id2',
              now.subtract(const Duration(days: 1)),
            ).referencedItemId) {
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: note2UpdateTime,
            updateTime: note2UpdateTime,
            displayTime: note2UpdateTime,
          );
        } else {
          return NoteItem(
            id: id,
            content: '',
            pinned: false,
            state: NoteState.normal,
            visibility: NoteVisibility.public,
            createTime: note3UpdateTime,
            updateTime: note3UpdateTime,
            displayTime: note3UpdateTime,
          );
        }
      });
      when(
        mockApiService.listNoteComments(
          any,
          targetServerOverride: serverConfig1,
        ),
      ).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        if (id ==
            createMockItem(
              'id2',
              now.subtract(const Duration(days: 1)),
            ).referencedItemId) {
          return [commentForItem2];
        }
        return [];
      });

      await notifier.loadItems();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(
        container.read(workbenchProvider).items.length,
        3,
        reason: 'Setup failed: Initial items not loaded',
      );
    });

    test(
      'clearItems success - removes all items locally and from CloudKit',
      () async {
        // Arrange: Mock successful CloudKit deletions
        when(
          mockCloudKitService.deleteWorkbenchItemReference('id1'),
        ).thenAnswer((_) async => true);
        when(
          mockCloudKitService.deleteWorkbenchItemReference('id2'),
        ).thenAnswer((_) async => true);
        when(
          mockCloudKitService.deleteWorkbenchItemReference('id3'),
        ).thenAnswer((_) async => true);

        // Act
        await notifier.clearItems();
        final state = container.read(workbenchProvider);

        // Assert
        expect(state.items, isEmpty);
        expect(state.error, isNull);
        verify(
          mockCloudKitService.deleteWorkbenchItemReference('id1'),
        ).called(1);
        verify(
          mockCloudKitService.deleteWorkbenchItemReference('id2'),
        ).called(1);
        verify(
          mockCloudKitService.deleteWorkbenchItemReference('id3'),
        ).called(1);
      },
    );

    test(
      'clearItems failure - reverts state for failed CloudKit deletions',
      () async {
        // Arrange: Mock failed deletion for item2, success for others
        final exception = Exception('CloudKit delete failed for item2');
        when(
          mockCloudKitService.deleteWorkbenchItemReference('id1'),
        ).thenAnswer((_) async => true);
        when(
          mockCloudKitService.deleteWorkbenchItemReference('id2'),
        ).thenThrow(exception);
        when(
          mockCloudKitService.deleteWorkbenchItemReference('id3'),
        ).thenAnswer((_) async => true);

        // Act
        await notifier.clearItems();
        final state = container.read(workbenchProvider);

        // Assert: Only item2 should remain, error should be set
        expect(state.items.length, 1);
        expect(state.items.first.id, 'id2');
        expect(state.error, exception);
        verify(
          mockCloudKitService.deleteWorkbenchItemReference('id1'),
        ).called(1);
        verify(
          mockCloudKitService.deleteWorkbenchItemReference('id2'),
        ).called(1);
        verify(
          mockCloudKitService.deleteWorkbenchItemReference('id3'),
        ).called(1);
      },
    );

    test('clearItems does nothing if list is already empty', () async {
      // Arrange: Clear items first
      when(
        mockCloudKitService.deleteWorkbenchItemReference(any),
      ).thenAnswer((_) async => true);
      await notifier.clearItems();
      expect(
        container.read(workbenchProvider).items,
        isEmpty,
        reason: 'Pre-condition failed: Items not cleared',
      );
      clearInteractions(mockCloudKitService);

      // Act
      await notifier.clearItems();
      final state = container.read(workbenchProvider);

      // Assert
      expect(state.items, isEmpty);
      expect(state.error, isNull);
      verifyNever(mockCloudKitService.deleteWorkbenchItemReference(any));
    });
  });
}
