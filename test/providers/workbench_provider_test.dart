import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

// Import generated mocks
import 'workbench_provider_test.mocks.dart';

// Generate mocks for CloudKitService
@GenerateNiceMocks([MockSpec<CloudKitService>()])

void main() {
  group('WorkbenchNotifier Tests', () {
    late MockCloudKitService mockCloudKitService;
    late ProviderContainer container;

    // Helper to create a sample item
    WorkbenchItemReference createItem({
      String? id,
      String refId = 'note1',
      DateTime? added,
      DateTime? opened,
    }) {
      final now = DateTime.now();
      return WorkbenchItemReference(
        id: id ?? const Uuid().v4(),
        referencedItemId: refId,
        referencedItemType: WorkbenchItemType.note,
        serverId: 'server1',
        serverType: ServerType.memos,
        addedTimestamp: added ?? now,
        lastOpenedTimestamp: opened,
      );
    }

    setUp(() {
      mockCloudKitService = MockCloudKitService();
      container = ProviderContainer(
        overrides: [
          cloudKitServiceProvider.overrideWithValue(mockCloudKitService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is loading, then loads and sorts items correctly', () async {
      // Arrange
      final item1Added = DateTime.now().subtract(const Duration(days: 2));
      final item2Added = DateTime.now().subtract(const Duration(days: 1));
      final item3Added = DateTime.now();
      final item1Opened = DateTime.now().subtract(const Duration(hours: 1)); // Opened recently
      final item3Opened = DateTime.now().subtract(const Duration(hours: 5)); // Opened earlier

      final item1 = createItem(id: 'id1', added: item1Added, opened: item1Opened); // Opened most recently
      final item2 = createItem(id: 'id2', added: item2Added, opened: null);      // Never opened
      final item3 = createItem(id: 'id3', added: item3Added, opened: item3Opened); // Opened less recently

      final cloudKitItems = [item2, item3, item1]; // Unsorted from CloudKit
      when(mockCloudKitService.getAllWorkbenchItemReferences())
          .thenAnswer((_) async => List.from(cloudKitItems)); // Return a copy

      // Act
      // Provider initialization triggers loadItems via unawaited
      // Wait for the loading future to complete
      await container.read(workbenchProvider.future);

      // Assert
      final state = container.read(workbenchProvider);
      expect(state.isLoading, false);
      expect(state.error, null);
      expect(state.items.length, 3);
      // Verify sorting: item1 (opened recently), item3 (opened earlier), item2 (never opened)
      expect(state.items[0].id, 'id1');
      expect(state.items[1].id, 'id3');
      expect(state.items[2].id, 'id2');
    });

     test('addItem prevents duplicates and adds new item', () async {
      // Arrange: Start with one item
      final existingItem = createItem(id: 'id1', refId: 'note1', serverId: 'server1');
      when(mockCloudKitService.getAllWorkbenchItemReferences())
          .thenAnswer((_) async => [existingItem]);
      await container.read(workbenchProvider.future); // Initial load

      final duplicateItem = createItem(refId: 'note1', serverId: 'server1'); // Same refId and serverId
      final newItem = createItem(id: 'id2', refId: 'note2', serverId: 'server1');

      when(mockCloudKitService.saveWorkbenchItemReference(any))
          .thenAnswer((_) async => true); // Mock successful save

      // Act: Try adding duplicate, then new item
      final notifier = container.read(workbenchProvider.notifier);
      await notifier.addItem(duplicateItem); // Should be skipped
      await notifier.addItem(newItem);       // Should be added

      // Assert
      final state = container.read(workbenchProvider);
      expect(state.items.length, 2); // Only existing + new item
      expect(state.items.any((i) => i.id == 'id1'), isTrue);
      expect(state.items.any((i) => i.id == 'id2'), isTrue);
      verify(mockCloudKitService.saveWorkbenchItemReference(newItem)).called(1);
      // Verify save wasn't called for the duplicate
      verifyNever(mockCloudKitService.saveWorkbenchItemReference(duplicateItem));
    });

    test('removeItem removes item locally and calls CloudKit delete', () async {
      // Arrange
      final itemToRemove = createItem(id: 'id1');
      final itemToKeep = createItem(id: 'id2');
      when(mockCloudKitService.getAllWorkbenchItemReferences())
          .thenAnswer((_) async => [itemToRemove, itemToKeep]);
      await container.read(workbenchProvider.future); // Initial load

      when(mockCloudKitService.deleteWorkbenchItemReference('id1'))
          .thenAnswer((_) async => true); // Mock successful delete

      // Act
      final notifier = container.read(workbenchProvider.notifier);
      await notifier.removeItem('id1');

      // Assert
      final state = container.read(workbenchProvider);
      expect(state.items.length, 1);
      expect(state.items.first.id, 'id2');
      verify(mockCloudKitService.deleteWorkbenchItemReference('id1')).called(1);
    });

     test('markItemOpened updates timestamp, re-sorts, and calls CloudKit', () async {
      // Arrange
      final item1 = createItem(id: 'id1', added: DateTime.now().subtract(const Duration(days: 1)), opened: null); // Never opened
      final item2 = createItem(id: 'id2', added: DateTime.now(), opened: null); // Never opened, added later

      when(mockCloudKitService.getAllWorkbenchItemReferences())
          .thenAnswer((_) async => [item1, item2]); // Initial order by added desc
      await container.read(workbenchProvider.future); // Initial load

      // Verify initial sort order (item2 then item1)
      expect(container.read(workbenchProvider).items[0].id, 'id2');
      expect(container.read(workbenchProvider).items[1].id, 'id1');

      when(mockCloudKitService.updateWorkbenchItemLastOpened('id1'))
          .thenAnswer((_) async => true); // Mock successful update

      // Act: Mark the older item (item1) as opened
      final notifier = container.read(workbenchProvider.notifier);
      await notifier.markItemOpened('id1');

      // Assert
      final state = container.read(workbenchProvider);
      expect(state.items.length, 2);
      // Verify new sort order (item1 now first because it was opened)
      expect(state.items[0].id, 'id1');
      expect(state.items[1].id, 'id2');
      expect(state.items[0].lastOpenedTimestamp, isNotNull);
      expect(state.items[1].lastOpenedTimestamp, isNull);
      verify(mockCloudKitService.updateWorkbenchItemLastOpened('id1')).called(1);
    });

     test('markItemOpened handles CloudKit update failure and reverts state', () async {
      // Arrange
      final item1 = createItem(id: 'id1', opened: null);
      when(mockCloudKitService.getAllWorkbenchItemReferences())
          .thenAnswer((_) async => [item1]);
      await container.read(workbenchProvider.future); // Initial load

      // Mock CloudKit failure
      when(mockCloudKitService.updateWorkbenchItemLastOpened('id1'))
          .thenAnswer((_) async => false);

      // Act
      final notifier = container.read(workbenchProvider.notifier);
      await notifier.markItemOpened('id1');

      // Assert
      final state = container.read(workbenchProvider);
      expect(state.items.length, 1);
      expect(state.items[0].id, 'id1');
      expect(state.items[0].lastOpenedTimestamp, isNull); // Should have reverted
      expect(state.error, isNotNull); // Error should be set
      verify(mockCloudKitService.updateWorkbenchItemLastOpened('id1')).called(1);
    });

  });
}
