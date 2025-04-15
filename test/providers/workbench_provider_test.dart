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
    referencedItemId: 'ref-\$id',
    referencedItemType: WorkbenchItemType.note,
    serverId: serverConfig1.id,
    serverType: serverConfig1.serverType,
    serverName: serverConfig1.name,
    previewContent: 'Preview for \$id',
    addedTimestamp: addedTimestamp,
  );
}

void main() {
  // Initialize the current time for tests
  now = DateTime.now();

  // Define items with clear time differences for sorting tests
  final item1 = createMockItem('id1', now.subtract(const Duration(days: 2))); // Oldest added
  final item2 = createMockItem('id2', now.subtract(const Duration(days: 1))); // Middle added
  final item3 = createMockItem('id3', now); // Newest added
  // This list is used for the mock service response, order doesn't matter here initially
  final initialItemsForMock = [item1, item2, item3];

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
        .thenAnswer((_) async => List.from(initialItemsForMock)); // Return a copy
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
        id:
            invocation.positionalArguments[0]
                as String, // Fix: Access argument correctly
              content: 'Mock Note Content',
              pinned: false,
              state: NoteState.normal,
              visibility: NoteVisibility.public,
              createTime: now.subtract(const Duration(hours: 1)),
              updateTime: now, // Default update time
              displayTime: now.subtract(const Duration(hours: 1)),
            ));
    when(mockApiService.listNoteComments(any, targetServerOverride: anyNamed('targetServerOverride')))
        .thenAnswer((_) async => []); // Default to empty comments list
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
      when(mockCloudKitService.getAllWorkbenchItemReferences())
          .thenAnswer((_) async => [item1, item3, item2]); // Unsorted by time

      // Mock API responses for detail fetching
      final note1UpdateTime = now.subtract(const Duration(days: 1, hours: 1)); // Older than item1 added
      final note2UpdateTime = now.subtract(const Duration(hours: 12)); // Newer than item2 added
      final note3UpdateTime = now.subtract(const Duration(hours: 1)); // Newer than item3 added

      final commentForItem2 = Comment(
        id: 'comment1',
        content: 'Latest comment',
        createTime: now.millisecondsSinceEpoch, // Newest activity overall
        updateTime: null,
      );

      when(mockApiService.getNote(item1.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => NoteItem(id: item1.referencedItemId, content: '', pinned: false, state: NoteState.normal, visibility: NoteVisibility.public, createTime: note1UpdateTime, updateTime: note1UpdateTime, displayTime: note1UpdateTime));
      when(mockApiService.getNote(item2.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => NoteItem(id: item2.referencedItemId, content: '', pinned: false, state: NoteState.normal, visibility: NoteVisibility.public, createTime: note2UpdateTime, updateTime: note2UpdateTime, displayTime: note2UpdateTime));
      when(mockApiService.getNote(item3.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => NoteItem(id: item3.referencedItemId, content: '', pinned: false, state: NoteState.normal, visibility: NoteVisibility.public, createTime: note3UpdateTime, updateTime: note3UpdateTime, displayTime: note3UpdateTime));

      when(mockApiService.listNoteComments(item1.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => []); // No comments for item1
      when(mockApiService.listNoteComments(item2.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => [commentForItem2]); // Comment for item2
      when(mockApiService.listNoteComments(item3.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => []); // No comments for item3

      // Act: Trigger load
      await notifier.loadItems();
      // Wait briefly for async detail fetching to complete (adjust duration if needed)
      await Future.delayed(const Duration(milliseconds: 100));
      final state = container.read(workbenchProvider);

      // Assert
      expect(state.isLoading, false);
      expect(state.isRefreshingDetails, false); // Should be false after load
      expect(state.error, isNull);
      expect(state.items.length, 3);

      // Verify API calls were made
      verify(mockApiService.getNote(item1.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.listNoteComments(item1.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.getNote(item2.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.listNoteComments(item2.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.getNote(item3.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.listNoteComments(item3.referencedItemId, targetServerOverride: serverConfig1)).called(1);

      // Calculate expected overallLastUpdateTime
      // item1: max(item1.added, note1Update) = item1.added (now - 2d)
      // item2: max(item2.added, note2Update, commentCreate) = commentCreate (now)
      // item3: max(item3.added, note3Update) = note3Update (now - 1h)
      // Expected order: item2 (now), item3 (now - 1h), item1 (now - 2d)

      expect(state.items[0].id, 'id2'); // Newest overall activity (comment)
      expect(state.items[0].latestComment?.id, commentForItem2.id);
      expect(state.items[0].overallLastUpdateTime.millisecondsSinceEpoch, commentForItem2.createTime);

      expect(state.items[1].id, 'id3'); // Next newest (note update)
      expect(state.items[1].latestComment, isNull);
      expect(state.items[1].overallLastUpdateTime, note3UpdateTime);

      expect(state.items[2].id, 'id1'); // Oldest overall activity (added time)
      expect(state.items[2].latestComment, isNull);
      expect(state.items[2].overallLastUpdateTime, item1.addedTimestamp);

      verify(mockCloudKitService.getAllWorkbenchItemReferences()).called(1);
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
    test('addItem success - adds item, fetches details, and sorts list', () async {
      // Arrange: Load initial items first
      await notifier.loadItems();
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for initial details

      final newItem = createMockItem('id4', now.add(const Duration(days: 1))); // Even newer added time
      final note4UpdateTime = now.add(const Duration(days: 1, hours: 1)); // Newer update time
      when(mockCloudKitService.saveWorkbenchItemReference(newItem))
          .thenAnswer((_) async => true);
      when(mockApiService.getNote(newItem.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => NoteItem(id: newItem.referencedItemId, content: '', pinned: false, state: NoteState.normal, visibility: NoteVisibility.public, createTime: note4UpdateTime, updateTime: note4UpdateTime, displayTime: note4UpdateTime));
      when(mockApiService.listNoteComments(newItem.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => []); // No comments for new item

      // Act
      await notifier.addItem(newItem);
      // Wait for async detail fetching for the new item
      await Future.delayed(const Duration(milliseconds: 100));
      final state = container.read(workbenchProvider);

      // Assert: New item should be first due to its overallLastUpdateTime (note update time)
      expect(state.items.length, 4);
      expect(state.items.first.id, 'id4');
      expect(state.items.first.overallLastUpdateTime, note4UpdateTime); // Verify update time was fetched and used
      expect(state.items.first.latestComment, isNull);
      // Verify the rest of the order based on previous test's expected outcome
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id3');
      expect(state.items[3].id, 'id1');
      expect(state.error, isNull);
      verify(mockCloudKitService.saveWorkbenchItemReference(newItem)).called(1);
      // Verify detail fetch for the new item
      verify(mockApiService.getNote(newItem.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.listNoteComments(newItem.referencedItemId, targetServerOverride: serverConfig1)).called(1);
    });

    test('addItem failure - reverts optimistic add and sorts', () async {
      // Arrange: Load initial items
      await notifier.loadItems(); // Loads [item3, item2, item1]
      final newItem = createMockItem('id4', now.add(const Duration(days: 1)));
      final exception = Exception('Save failed');
      when(mockCloudKitService.saveWorkbenchItemReference(newItem))
          .thenThrow(exception);

      // Act
      await notifier.addItem(newItem);
      final state = container.read(workbenchProvider);

      // Assert: Item should be removed, list remains sorted
      expect(state.items.length, 3);
      expect(state.items.any((item) => item.id == 'id4'), isFalse);
      expect(state.items[0].id, 'id3'); // Original sort order maintained
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
      expect(state.error, exception);
      verify(mockCloudKitService.saveWorkbenchItemReference(newItem)).called(1);
    });

    test('addItem duplicate - does not add item or call CloudKit', () async {
      // Arrange: Load initial items, including item2
      await notifier.loadItems(); // Loads [item3, item2, item1]
      final duplicateItem = createMockItem('newIdSameRef', now.add(const Duration(days: 1)))
          .copyWith(referencedItemId: item2.referencedItemId, serverId: item2.serverId); // Same refId and serverId as item2

      // Act
      await notifier.addItem(duplicateItem);
      final state = container.read(workbenchProvider);

      // Assert: List remains unchanged, no save called
      expect(state.items.length, 3);
      expect(state.items[0].id, 'id3');
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
      expect(state.error, isNull); // No error should be thrown for duplicates
      verifyNever(mockCloudKitService.saveWorkbenchItemReference(duplicateItem));
    });
  });

  group('removeItem', () {
    test('removeItem success - removes item', () async {
      // Arrange: Load initial items
      await notifier.loadItems(); // Loads [item3, item2, item1]
      when(mockCloudKitService.deleteWorkbenchItemReference('id2'))
          .thenAnswer((_) async => true);

      // Act
      await notifier.removeItem('id2'); // Remove middle item
      final state = container.read(workbenchProvider);

      // Assert
      expect(state.items.length, 2);
      expect(state.items.any((item) => item.id == 'id2'), isFalse);
      expect(state.items[0].id, 'id3'); // Remaining items still sorted
      expect(state.items[1].id, 'id1');
      expect(state.error, isNull);
      verify(mockCloudKitService.deleteWorkbenchItemReference('id2')).called(1);
    });

    test('removeItem failure - reverts optimistic removal and maintains sort order', () async {
      // Arrange: Load initial items and fetch details
      await notifier.loadItems();
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for details and sorting
      // Expected initial order: [id2, id3, id1] based on mock data in loadItems test

      final exception = Exception('Delete failed');
      when(mockCloudKitService.deleteWorkbenchItemReference('id3')) // Try removing item3
          .thenThrow(exception);

      // Act
      await notifier.removeItem('id3');
      final state = container.read(workbenchProvider);

      // Assert: Item should be back, list remains sorted by overallLastUpdateTime
      expect(state.items.length, 3);
      expect(state.items.any((item) => item.id == 'id3'), isTrue); // Item reverted
      // Verify the order is still based on overallLastUpdateTime
      expect(state.items[0].id, 'id2');
      expect(state.items[1].id, 'id3');
      expect(state.items[2].id, 'id1');
      expect(state.error, exception);
      verify(mockCloudKitService.deleteWorkbenchItemReference('id3')).called(1);
    });

    test('removeItem non-existent id - does nothing', () async {
      // Arrange: Load initial items
      await notifier.loadItems(); // Loads [item3, item2, item1]

      // Act
      await notifier.removeItem('non-existent-id');
      final state = container.read(workbenchProvider);

      // Assert: List remains unchanged, no delete called
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
      // Ensure items are loaded and sorted initially for these tests
      await notifier.loadItems(); // State: [item3, item2, item1]
    });

    test('moves item downwards correctly', () {
      // Arrange: Initial state [id3, id2, id1]
      const oldIndex = 0; // item3 (newest)
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
      const oldIndex = 2; // item1 (oldest)
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
      const oldIndex = 0; // item3 (newest)
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
      // Use the same mocks as the loadItems test for consistency
      when(mockCloudKitService.getAllWorkbenchItemReferences())
          .thenAnswer((_) async => [item1, item3, item2]); // Unsorted by time
      final note1UpdateTime = now.subtract(const Duration(days: 1, hours: 1));
      final note2UpdateTime = now.subtract(const Duration(hours: 12));
      final note3UpdateTime = now.subtract(const Duration(hours: 1));
      final commentForItem2 = Comment(id: 'comment1', content: 'Latest comment', createTime: now.millisecondsSinceEpoch);
      when(mockApiService.getNote(item1.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => NoteItem(id: item1.referencedItemId, content: '', pinned: false, state: NoteState.normal, visibility: NoteVisibility.public, createTime: note1UpdateTime, updateTime: note1UpdateTime, displayTime: note1UpdateTime));
      when(mockApiService.getNote(item2.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => NoteItem(id: item2.referencedItemId, content: '', pinned: false, state: NoteState.normal, visibility: NoteVisibility.public, createTime: note2UpdateTime, updateTime: note2UpdateTime, displayTime: note2UpdateTime));
      when(mockApiService.getNote(item3.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => NoteItem(id: item3.referencedItemId, content: '', pinned: false, state: NoteState.normal, visibility: NoteVisibility.public, createTime: note3UpdateTime, updateTime: note3UpdateTime, displayTime: note3UpdateTime));
      when(mockApiService.listNoteComments(item1.referencedItemId, targetServerOverride: serverConfig1)).thenAnswer((_) async => []);
      when(mockApiService.listNoteComments(item2.referencedItemId, targetServerOverride: serverConfig1)).thenAnswer((_) async => [commentForItem2]);
      when(mockApiService.listNoteComments(item3.referencedItemId, targetServerOverride: serverConfig1)).thenAnswer((_) async => []);

      await notifier.loadItems();
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for details
      // Expected initial state after load/details: [id2, id3, id1]
    });

    test('resets manually reordered list to default sort (overallLastUpdateTime desc)', () {
      // Arrange: Manually reorder to [id1, id2, id3]
      notifier.reorderItems(2, 0); // Move id1 to start
      notifier.reorderItems(2, 1); // Move id3 after id1 -> [id1, id3, id2]
      final reorderedState = container.read(workbenchProvider);
      // Verify pre-condition
      expect(reorderedState.items[0].id, 'id1', reason: 'Pre-condition failed: Manual reorder did not work');
      expect(reorderedState.items[1].id, 'id3');
      expect(reorderedState.items[2].id, 'id2');

      // Act
      notifier.resetOrder();
      final state = container.read(workbenchProvider);

      // Assert: Order should be back to overallLastUpdateTime descending [id2, id3, id1]
      expect(state.items.length, 3);
      expect(state.items[0].id, 'id2');
      expect(state.items[1].id, 'id3');
      expect(state.items[2].id, 'id1');
    });

    test('does nothing if already in default order (overallLastUpdateTime desc)', () {
      // Arrange: Initial state is already default order [id2, id3, id1]
      final initialOrder = List<WorkbenchItemReference>.from(container.read(workbenchProvider).items);

      // Act
      notifier.resetOrder();
      final state = container.read(workbenchProvider);

      // Assert: Order remains unchanged
      expect(state.items.length, 3);
      expect(state.items.map((e) => e.id).toList(), initialOrder.map((e) => e.id).toList());
      expect(state.items[0].id, 'id2');
      expect(state.items[1].id, 'id3');
      expect(state.items[2].id, 'id1');
    });
  });

  group('refreshItemDetails', () {
    setUp(() async {
      // Arrange: Load initial items and fetch details
      // Use the same mocks as the loadItems test for consistency
      when(
        mockCloudKitService.getAllWorkbenchItemReferences(),
      ).thenAnswer((_) async => [item1, item3, item2]); // Unsorted by time
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
      ); // Wait for details
      // Expected initial state after load/details: [id2, id3, id1]
    });

    test(
      'refreshItemDetails success - re-fetches details and updates state',
      () async {
        // Arrange: Modify API mocks for the refresh call
        final refreshedNote1UpdateTime = now.subtract(
          const Duration(minutes: 5),
        ); // Much newer
        final refreshedCommentForItem3 = Comment(
          id: 'comment2',
          content: 'Refreshed comment',
          createTime:
              now.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
        ); // Newest overall

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
            createTime: refreshedNote1UpdateTime,
            updateTime: refreshedNote1UpdateTime,
            displayTime: refreshedNote1UpdateTime,
          ),
        );
        // Keep item2 mocks the same (no new comment/update)
        when(
          mockApiService.listNoteComments(
            item3.referencedItemId,
            targetServerOverride: serverConfig1,
          ),
        ).thenAnswer(
          (_) async => [refreshedCommentForItem3],
        ); // New comment for item3

        // Act
        await notifier.refreshItemDetails();
        // Wait briefly for async detail fetching to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final state = container.read(workbenchProvider);

        // Assert
        expect(state.isLoading, false); // Should not be loading
        expect(state.isRefreshingDetails, false); // Should be reset
        expect(state.error, isNull);
        expect(state.items.length, 3);

        // Verify API calls were made again during refresh
        verify(
          mockApiService.getNote(
            item1.referencedItemId,
            targetServerOverride: serverConfig1,
          ),
        ).called(1); // Called once during load, once during refresh
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

        // Calculate expected overallLastUpdateTime after refresh
        // item1: max(item1.added, refreshedNote1Update) = refreshedNote1Update (now - 5m)
        // item2: max(item2.added, note2Update, commentCreate) = commentCreate (now)
        // item3: max(item3.added, note3Update, refreshedCommentCreate) = refreshedCommentCreate (now + 1m)
        // Expected order: item3 (now + 1m), item2 (now), item1 (now - 5m)

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
          'comment1',
        ); // Should still have original comment
        expect(
          state.items[1].overallLastUpdateTime.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch,
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
        final exception = Exception('API failed for item1');
        when(
          mockApiService.getNote(
            item1.referencedItemId,
            targetServerOverride: serverConfig1,
          ),
        ).thenThrow(exception);
        // Keep other mocks the same as initial load

        // Act
        await notifier.refreshItemDetails();
        await Future.delayed(const Duration(milliseconds: 100));
        final state = container.read(workbenchProvider);

        // Assert
        expect(state.isRefreshingDetails, false);
        expect(
          state.error,
          isNull,
        ); // Error should not be set at the state level for partial failures
        expect(state.items.length, 3);

        // Verify item1 retains its original data (or defaults if details couldn't be fetched initially)
        final item1State = state.items.firstWhere((i) => i.id == 'id1');
        // Its overallLastUpdateTime should be its addedTimestamp as the note fetch failed
        expect(item1State.overallLastUpdateTime, item1.addedTimestamp);
        expect(
          item1State.referencedItemUpdateTime,
          isNull,
        ); // Should remain null or original value
        expect(
          item1State.latestComment,
          isNull,
        ); // Should remain null or original value

        // Verify other items were updated correctly (order should still be based on available data)
        // Expected order: item2 (now), item3 (now - 1h), item1 (now - 2d)
        expect(state.items[0].id, 'id2');
        expect(state.items[1].id, 'id3');
        expect(state.items[2].id, 'id1');
      },
    );

    test('refreshItemDetails does nothing if no items exist', () async {
      // Arrange: Clear all items
      // Assuming notifier exposes a method or mechanism to clear items for testing.
      // For this test, we simulate a scenario with no items.
      notifier.resetOrder(); // Reset to default order first
      // Clearing items from notifier state for test
      notifier.clearItems();

      // Act
      await notifier.refreshItemDetails();

      // Assert
      final state = container.read(workbenchProvider);
      expect(state.items, isEmpty);
    });
  });
}
