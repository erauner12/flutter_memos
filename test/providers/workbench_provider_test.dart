import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import generated mocks
import 'workbench_provider_test.mocks.dart';

// Generate mocks for CloudKitService
@GenerateNiceMocks([MockSpec<CloudKitService>()])
// Define test variables
late DateTime now;
late MockCloudKitService mockCloudKitService;
late ProviderContainer container;
late WorkbenchNotifier notifier;

// Helper to create mock items with varying timestamps
WorkbenchItemReference createMockItem(
  String id,
  DateTime added,
) {
  return WorkbenchItemReference(
    id: id,
    referencedItemId: 'ref-$id',
    referencedItemType: WorkbenchItemType.note,
    serverId: 'server1',
    serverType: ServerType.memos,
    addedTimestamp: added,
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
    container = ProviderContainer(
      overrides: [
        cloudKitServiceProvider.overrideWithValue(mockCloudKitService),
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

    test('loadItems success - sorts items by addedTimestamp descending', () async {
      // Arrange: Mock service returns unsorted items (relative to time)
      when(mockCloudKitService.getAllWorkbenchItemReferences())
          .thenAnswer((_) async => [item1, item3, item2]); // Unsorted by time

      // Act: Trigger load (already triggered by provider init, but call again for clarity)
      await notifier.loadItems();
      final state = container.read(workbenchProvider);

      // Assert
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.items.length, 3);
      // Expect items sorted by addedTimestamp descending (newest first)
      expect(state.items[0].id, 'id3'); // Newest
      expect(state.items[1].id, 'id2'); // Middle
      expect(state.items[2].id, 'id1'); // Oldest
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
    test('addItem success - adds item and sorts list', () async {
      // Arrange: Load initial items first to have a base state
      await notifier.loadItems(); // Loads [item3, item2, item1]
      final newItem = createMockItem('id4', now.add(const Duration(days: 1))); // Even newer
      when(mockCloudKitService.saveWorkbenchItemReference(newItem))
          .thenAnswer((_) async => true);

      // Act
      await notifier.addItem(newItem);
      final state = container.read(workbenchProvider);

      // Assert: New item should be first due to default sort
      expect(state.items.length, 4);
      expect(state.items.first.id, 'id4'); // New item should be first
      expect(state.items[1].id, 'id3');
      expect(state.items[2].id, 'id2');
      expect(state.items[3].id, 'id1');
      expect(state.error, isNull);
      verify(mockCloudKitService.saveWorkbenchItemReference(newItem)).called(1);
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

    test('removeItem failure - reverts optimistic removal and sorts', () async {
      // Arrange: Load initial items
      await notifier.loadItems(); // Loads [item3, item2, item1]
      final exception = Exception('Delete failed');
      when(mockCloudKitService.deleteWorkbenchItemReference('id2'))
          .thenThrow(exception); // Simulate CloudKit failure

      // Act
      await notifier.removeItem('id2'); // Attempt to remove item2
      final state = container.read(workbenchProvider);

      // Assert: Item should be back, list sorted correctly
      expect(state.items.length, 3);
      expect(state.items.any((item) => item.id == 'id2'), isTrue); // Item reverted
      expect(state.items[0].id, 'id3'); // Still sorted correctly by time
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
      expect(state.error, exception); // Error should be set
      verify(mockCloudKitService.deleteWorkbenchItemReference('id2')).called(1);
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
      // Ensure items are loaded initially
      await notifier.loadItems(); // State: [item3, item2, item1]
    });

    test('resets manually reordered list to default sort (addedTimestamp desc)', () {
      // Arrange: Manually reorder to [id1, id3, id2]
      notifier.reorderItems(2, 0); // Move id1 (oldest) to start
      final reorderedState = container.read(workbenchProvider);
      // Verify pre-condition
      expect(reorderedState.items[0].id, 'id1', reason: 'Pre-condition failed: Manual reorder did not work');
      expect(reorderedState.items[1].id, 'id3');
      expect(reorderedState.items[2].id, 'id2');

      // Act
      notifier.resetOrder();
      final state = container.read(workbenchProvider);

      // Assert: Order should be back to addedTimestamp descending [id3, id2, id1]
      expect(state.items.length, 3);
      expect(state.items[0].id, 'id3');
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
    });

    test('does nothing if already in default order', () {
      // Arrange: Initial state is already default order [id3, id2, id1]
      final initialOrder = List<WorkbenchItemReference>.from(container.read(workbenchProvider).items);

      // Act
      notifier.resetOrder();
      final state = container.read(workbenchProvider);

      // Assert: Order remains unchanged (object identity might differ, check IDs)
      expect(state.items.length, 3);
      expect(state.items.map((e) => e.id).toList(), initialOrder.map((e) => e.id).toList());
      expect(state.items[0].id, 'id3');
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
    });
  });
}
