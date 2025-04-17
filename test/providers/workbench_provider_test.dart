import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/multi_server_config_state.dart'; // Import MultiServerConfigState
import 'package:flutter_memos/models/note_item.dart'; // Add NoteItem import
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_instance.dart'; // Import WorkbenchInstance
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/api_providers.dart'; // Add API provider import
import 'package:flutter_memos/providers/server_config_provider.dart'; // Add Server Config provider import
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/providers/shared_prefs_provider.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart'; // Import instances provider
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_memos/services/note_api_service.dart'; // Add NoteApiService import
import 'package:flutter_memos/utils/shared_prefs.dart'; // Import SharedPrefsService
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for mock prefs

// Import generated mocks
import 'workbench_provider_test.mocks.dart';

// Generate mocks for CloudKitService, NoteApiService, AND SharedPrefsService
@GenerateNiceMocks([
  MockSpec<CloudKitService>(),
  MockSpec<NoteApiService>(),
  MockSpec<SharedPrefsService>(), // Add SharedPrefsService mock
])
// Define test variables
late DateTime now;
late MockCloudKitService mockCloudKitService;
late MockNoteApiService mockApiService;
late MockSharedPrefsService mockSharedPrefsService; // Add mock prefs service
late ProviderContainer container;
// Add default instance and server config for tests
final testInstanceId = WorkbenchInstance.defaultInstanceId;
final testInstance = WorkbenchInstance.defaultInstance();
final serverConfig1 = ServerConfig(
  id: 'server1',
  name: 'Test Server 1',
  serverUrl: 'http://test1.com',
  authToken: 'token1',
  serverType: ServerType.memos,
);

// Helper function to create mock items for the test instance
WorkbenchItemReference createMockItem(String id, DateTime addedTimestamp) {
  return WorkbenchItemReference(
    id: id,
    instanceId: testInstanceId, // Assign the test instance ID
    referencedItemId: 'ref-$id',
    referencedItemType: WorkbenchItemType.note,
    serverId: serverConfig1.id,
    serverType: serverConfig1.serverType,
    serverName: serverConfig1.name,
    previewContent: 'Preview for $id',
    addedTimestamp: addedTimestamp,
    // overallLastUpdateTime will default to addedTimestamp
  );
}

void main() {
  // Initialize the current time for tests
  now = DateTime.now();

  setUp(() async {
    // Mock SharedPreferences for SharedPrefsService setup
    SharedPreferences.setMockInitialValues({
      'activeWorkbenchInstanceId': testInstanceId,
      'lastOpenedItemMap': '{}',
    });

    mockCloudKitService = MockCloudKitService();
    mockApiService = MockNoteApiService();
    mockSharedPrefsService =
        MockSharedPrefsService(); // Initialize mock prefs service

    // Stub SharedPrefsService methods
    when(
      mockSharedPrefsService.getActiveInstanceId(),
    ).thenReturn(testInstanceId);
    when(mockSharedPrefsService.getLastOpenedItemMap()).thenReturn({});
    when(
      mockSharedPrefsService.saveActiveInstanceId(any),
    ).thenAnswer((_) async => true);
    when(
      mockSharedPrefsService.saveLastOpenedItemMap(any),
    ).thenAnswer((_) async => true);

    container = ProviderContainer(
      overrides: [
        cloudKitServiceProvider.overrideWithValue(mockCloudKitService),
        // Override sharedPrefsServiceProvider with a Future that resolves to the mock
        sharedPrefsServiceProvider.overrideWith(
          (ref) => Future.value(mockSharedPrefsService),
        ),
        apiServiceProvider.overrideWithValue(mockApiService),
        multiServerConfigProvider.overrideWith(
          (ref) => MultiServerConfigNotifier(ref)
            ..state = MultiServerConfigState(
              servers: [serverConfig1],
              activeServerId: serverConfig1.id,
            ),
        ),
        workbenchInstancesProvider.overrideWith((ref) {
          // Update the constructor call: remove mockSharedPrefsService parameter
          final notifier = WorkbenchInstancesNotifier(ref);
          // The rest of the setup remains the same, relying on the actual provider override for sharedPrefsServiceProvider
          notifier.state = WorkbenchInstancesState(
            instances: [testInstance],
            activeInstanceId: testInstanceId,
            isLoading: false,
            lastOpenedItemId: {},
          );
          when(
            mockCloudKitService.getAllWorkbenchInstances(),
          ).thenAnswer((_) async => [testInstance]);
          when(
            mockCloudKitService.saveWorkbenchInstance(any),
          ).thenAnswer((_) async => true);
          when(
            mockCloudKitService.deleteWorkbenchInstance(any),
          ).thenAnswer((_) async => true);
          // These mocks on mockSharedPrefsService might still be needed if other parts of the test
          // interact with it directly via the overridden sharedPrefsServiceProvider.
          when(
            mockSharedPrefsService.getActiveInstanceId(),
          ).thenReturn(testInstanceId);
          when(mockSharedPrefsService.getLastOpenedItemMap()).thenReturn({});
          return notifier;
        }),
      ],
    );

    // Default mock behavior for workbench item references
    when(
      mockCloudKitService.getAllWorkbenchItemReferences(
        instanceId: testInstanceId,
      ),
    ).thenAnswer(
      (_) async => [
        createMockItem('id1', now.subtract(const Duration(days: 2))),
        createMockItem('id2', now.subtract(const Duration(days: 1))),
        createMockItem('id3', now),
      ],
    );
    when(
      mockCloudKitService.saveWorkbenchItemReference(any),
    ).thenAnswer((_) async => true);
    when(
      mockCloudKitService.deleteWorkbenchItemReference(any),
    ).thenAnswer((_) async => true);
    when(
      mockCloudKitService.deleteAllWorkbenchItemReferences(
        instanceId: testInstanceId,
      ),
    ).thenAnswer((_) async => true);

    // Default mock behavior for API calls
    when(
      mockApiService.getNote(
        any,
        targetServerOverride: anyNamed('targetServerOverride'),
      ),
    ).thenAnswer((invocation) async {
      final id = invocation.positionalArguments[0] as String;
      return NoteItem(
        id: id,
        content: 'Mock Note Content',
        pinned: false,
        state: NoteState.normal,
        visibility: NoteVisibility.public,
        createTime: now.subtract(const Duration(hours: 1)),
        updateTime: now.subtract(const Duration(hours: 1)),
        displayTime: now.subtract(const Duration(hours: 1)),
      );
    });
    when(
      mockApiService.listNoteComments(
        any,
        targetServerOverride: anyNamed('targetServerOverride'),
      ),
    ).thenAnswer((_) async => []);
  });

  tearDown(() {
    container.dispose();
  });

  group('initial state and loadItems', () {
    test('initial state is loading', () {
      final state = container.read(workbenchProviderFamily(testInstanceId));
      expect(state.isLoading, false);
      expect(state.items, isEmpty);
      expect(state.error, isNull);
      verifyNever(
        mockCloudKitService.getAllWorkbenchItemReferences(
          instanceId: testInstanceId,
        ),
      );
    });

    test(
      'loadItems success - fetches details and sorts by overallLastUpdateTime descending',
      () async {
        final notifier = container.read(
          workbenchProviderFamily(testInstanceId).notifier,
        );
        final item1 = createMockItem(
          'id1',
          now.subtract(const Duration(days: 2)),
        );
        final item2 = createMockItem(
          'id2',
          now.subtract(const Duration(days: 1)),
        );
        final item3 = createMockItem('id3', now);
        when(
          mockCloudKitService.getAllWorkbenchItemReferences(
            instanceId: testInstanceId,
          ),
        ).thenAnswer((_) async => [item1, item3, item2]);
        final note1UpdateTime = now.subtract(const Duration(days: 1, hours: 1));
        final note2UpdateTime = now.subtract(const Duration(hours: 12));
        final note3UpdateTime = now.subtract(const Duration(hours: 1));
        final commentForItem2 = Comment(
          id: 'comment1',
          content: 'Latest comment',
          createdTs: now,
          parentId: 'parent-id',
          serverId: serverConfig1.id,
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
        await container.pump();

        final state = container.read(workbenchProviderFamily(testInstanceId));
        expect(state.isLoading, false);
        expect(state.isRefreshingDetails, false);
        expect(state.error, isNull);
        expect(state.items.length, 3);
        verify(
          mockCloudKitService.getAllWorkbenchItemReferences(
            instanceId: testInstanceId,
          ),
        ).called(1);
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

        expect(state.items[0].id, 'id3');
        expect(state.items[0].previewComments.isEmpty, isTrue);
        expect(state.items[0].overallLastUpdateTime, item3.addedTimestamp);

        expect(state.items[1].id, 'id2');
        expect(state.items[1].previewComments.first.id, commentForItem2.id);
        expect(state.items[1].overallLastUpdateTime, commentForItem2.createdTs);

        expect(state.items[2].id, 'id1');
        expect(state.items[2].previewComments.isEmpty, isTrue);
        expect(state.items[2].overallLastUpdateTime, note1UpdateTime);
      },
    );

    test('loadItems failure', () async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      final exception = Exception('CloudKit failed');
      when(
        mockCloudKitService.getAllWorkbenchItemReferences(
          instanceId: testInstanceId,
        ),
      ).thenThrow(exception);

      await notifier.loadItems();
      final state = container.read(workbenchProviderFamily(testInstanceId));

      expect(state.isLoading, false);
      expect(state.error, exception);
      expect(state.items, isEmpty);
      verify(
        mockCloudKitService.getAllWorkbenchItemReferences(
          instanceId: testInstanceId,
        ),
      ).called(1);
    });
  });

  group('addItem', () {
    setUp(() async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      await notifier.loadItems();
      await container.pump();
    });

    test(
      'addItem success - adds item, fetches details, and sorts list',
      () async {
        final notifier = container.read(
          workbenchProviderFamily(testInstanceId).notifier,
        );
        final newItem = createMockItem('id4', now.add(const Duration(days: 1)));
        final note4UpdateTime = now.add(const Duration(days: 1, hours: 1));
        when(
          mockCloudKitService.saveWorkbenchItemReference(newItem),
        ).thenAnswer((_) async => true);
        when(
          mockApiService.getNote(
            newItem.referencedItemId,
            targetServerOverride: serverConfig1,
          ),
        ).thenAnswer(
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
        when(
          mockApiService.listNoteComments(
            newItem.referencedItemId,
            targetServerOverride: serverConfig1,
          ),
        ).thenAnswer((_) async => []);

        await notifier.addItem(newItem);
        await container.pump();
        final state = container.read(workbenchProviderFamily(testInstanceId));

        expect(state.items.length, 4);
        expect(state.items.first.id, 'id4');
        expect(state.items.first.overallLastUpdateTime, note4UpdateTime);
        expect(state.items.first.previewComments.isEmpty, isTrue);
        expect(state.items[1].id, 'id3');
        expect(state.items[2].id, 'id2');
        expect(state.items[3].id, 'id1');
        expect(state.error, isNull);
        verify(
          mockCloudKitService.saveWorkbenchItemReference(newItem),
        ).called(1);
        verify(
          mockApiService.getNote(
            newItem.referencedItemId,
            targetServerOverride: serverConfig1,
          ),
        ).called(1);
        verify(
          mockApiService.listNoteComments(
            newItem.referencedItemId,
            targetServerOverride: serverConfig1,
          ),
        ).called(1);
      },
    );

    test('addItem failure - reverts optimistic add and sorts', () async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      final newItem = createMockItem('id4', now.add(const Duration(days: 1)));
      final exception = Exception('Save failed');
      when(
        mockCloudKitService.saveWorkbenchItemReference(newItem),
      ).thenThrow(exception);

      await notifier.addItem(newItem);
      final state = container.read(workbenchProviderFamily(testInstanceId));

      expect(state.items.length, 3);
      expect(state.items.any((i) => i.id == 'id4'), isFalse);
      expect(state.items[0].id, 'id3');
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
      expect(state.error, exception);
      verify(mockCloudKitService.saveWorkbenchItemReference(newItem)).called(1);
    });

    test('addItem duplicate - does not add item or call CloudKit', () async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      final existingItem =
          container.read(workbenchProviderFamily(testInstanceId)).items[1];
      final duplicateItem = createMockItem(
        'newIdSameRef',
        now.add(const Duration(days: 1)),
      ).copyWith(
        referencedItemId: existingItem.referencedItemId,
        serverId: existingItem.serverId,
      );

      await notifier.addItem(duplicateItem);
      final state = container.read(workbenchProviderFamily(testInstanceId));

      expect(state.items.length, 3);
      expect(state.items[0].id, 'id3');
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
      expect(state.error, isNull);
      verifyNever(
        mockCloudKitService.saveWorkbenchItemReference(duplicateItem),
      );
    });

    test('addItem for wrong instance - does nothing', () async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      final wrongInstanceItem = WorkbenchItemReference(
        id: 'wrongId',
        instanceId: 'another-instance-id', // Different instance
        referencedItemId: 'ref-wrong',
        referencedItemType: WorkbenchItemType.note,
        serverId: serverConfig1.id,
        serverType: serverConfig1.serverType,
        serverName: serverConfig1.name, // Added missing required fields
        previewContent: '', // Added missing required fields
        addedTimestamp: now,
      );

      await notifier.addItem(wrongInstanceItem);
      final state = container.read(workbenchProviderFamily(testInstanceId));

      expect(state.items.length, 3);
      verifyNever(
        mockCloudKitService.saveWorkbenchItemReference(wrongInstanceItem),
      );
    });
  });

  group('removeItem', () {
    setUp(() async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      await notifier.loadItems();
      await container.pump();
    });

    test('removeItem success - removes item', () async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      when(
        mockCloudKitService.deleteWorkbenchItemReference('id2'),
      ).thenAnswer((_) async => true);

      await notifier.removeItem('id2');
      final state = container.read(workbenchProviderFamily(testInstanceId));

      expect(state.items.length, 2);
      expect(state.items.any((i) => i.id == 'id2'), isFalse);
      expect(state.items[0].id, 'id3');
      expect(state.items[1].id, 'id1');
      expect(state.error, isNull);
      verify(mockCloudKitService.deleteWorkbenchItemReference('id2')).called(1);
      verify(mockSharedPrefsService.saveLastOpenedItemMap(any)).called(1);
    });

    test(
      'removeItem failure - reverts optimistic removal and maintains sort order',
      () async {
        final notifier = container.read(
          workbenchProviderFamily(testInstanceId).notifier,
        );
        final exception = Exception('Delete failed');
        when(
          mockCloudKitService.deleteWorkbenchItemReference('id3'),
        ).thenThrow(exception);

        await notifier.removeItem('id3');
        final state = container.read(workbenchProviderFamily(testInstanceId));

        expect(state.items.length, 3);
        expect(state.items[0].id, 'id3');
        expect(state.items[1].id, 'id2');
        expect(state.items[2].id, 'id1');
        expect(state.error, exception);
        verify(
          mockCloudKitService.deleteWorkbenchItemReference('id3'),
        ).called(1);
        verifyNever(mockSharedPrefsService.saveLastOpenedItemMap(any));
      },
    );

    test('removeItem non-existent id - does nothing', () async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      await notifier.removeItem('non-existent-id');
      final state = container.read(workbenchProviderFamily(testInstanceId));

      expect(state.items.length, 3);
      expect(state.items[0].id, 'id3');
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
      expect(state.error, isNull);
      verifyNever(
        mockCloudKitService.deleteWorkbenchItemReference('non-existent-id'),
      );
    });
  });

  group('reorderItems', () {
    setUp(() async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      await notifier.loadItems();
      await container.pump();
    });

    test('moves item downwards correctly', () {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      notifier.reorderItems(0, 2);
      final state = container.read(workbenchProviderFamily(testInstanceId));
      expect(state.items.map((e) => e.id).toList(), ['id2', 'id3', 'id1']);
    });

    test('moves item upwards correctly', () {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      notifier.reorderItems(2, 0);
      final state = container.read(workbenchProviderFamily(testInstanceId));
      expect(state.items.map((e) => e.id).toList(), ['id1', 'id3', 'id2']);
    });

    test('moves item to the end correctly', () {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      notifier.reorderItems(0, 3);
      final state = container.read(workbenchProviderFamily(testInstanceId));
      expect(state.items.map((e) => e.id).toList(), ['id2', 'id1', 'id3']);
    });

    test('does nothing for invalid indices', () async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      final initialOrder =
          container.read(workbenchProviderFamily(testInstanceId)).items;
      notifier.reorderItems(-1, 1);
      expect(
        container.read(workbenchProviderFamily(testInstanceId)).items,
        initialOrder,
      );
      notifier.reorderItems(3, 1);
      expect(
        container.read(workbenchProviderFamily(testInstanceId)).items,
        initialOrder,
      );
      notifier.reorderItems(0, 4);
      expect(
        container.read(workbenchProviderFamily(testInstanceId)).items,
        initialOrder,
      );
      notifier.reorderItems(1, -1);
      expect(
        container.read(workbenchProviderFamily(testInstanceId)).items,
        initialOrder,
      );
    });
  });

  group('resetOrder', () {
    setUp(() async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      await notifier.loadItems();
      await container.pump();
    });

    test(
      'resets manually reordered list to default sort (overallLastUpdateTime desc)',
      () {
        final notifier = container.read(
          workbenchProviderFamily(testInstanceId).notifier,
        );
        notifier.reorderItems(2, 0);
        notifier.reorderItems(2, 1);
        final reorderedState = container.read(
          workbenchProviderFamily(testInstanceId),
        );
        expect(reorderedState.items.map((e) => e.id).toList(), [
          'id1',
          'id2',
          'id3',
        ]);

        notifier.resetOrder();
        final state = container.read(workbenchProviderFamily(testInstanceId));
        expect(state.items.map((e) => e.id).toList(), ['id3', 'id2', 'id1']);
      },
    );

    test(
      'does nothing if already in default order (overallLastUpdateTime desc)',
      () {
        final notifier = container.read(
          workbenchProviderFamily(testInstanceId).notifier,
        );
        final initialOrder =
            container.read(workbenchProviderFamily(testInstanceId)).items;
        expect(initialOrder.map((e) => e.id).toList(), ['id3', 'id2', 'id1']);

        notifier.resetOrder();
        final state = container.read(workbenchProviderFamily(testInstanceId));
        expect(
          state.items.map((e) => e.id).toList(),
          initialOrder.map((e) => e.id).toList(),
        );
      },
    );
  });

  group('refreshItemDetails', () {
    setUp(() async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      await notifier.loadItems();
      await container.pump();
    });

    test(
      'refreshItemDetails success - re-fetches details and updates state',
      () async {
        final notifier = container.read(
          workbenchProviderFamily(testInstanceId).notifier,
        );
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
        );
        final originalCommentForItem2 = Comment(
          id: 'comment1',
          content: 'Latest comment',
          createdTs: now,
          parentId: 'p',
          serverId: 's1',
        );
        final refreshedCommentForItem3 = Comment(
          id: 'comment2',
          content: 'Refreshed comment',
          createdTs: now.add(const Duration(minutes: 1)),
          parentId: 'p',
          serverId: 's1',
        );

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
          }
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
        when(
          mockApiService.listNoteComments(
            any,
            targetServerOverride: serverConfig1,
          ),
        ).thenAnswer((invocation) async {
          final id = invocation.positionalArguments[0] as String;
          if (id == item1.referencedItemId) return [];
          if (id == item2.referencedItemId) return [originalCommentForItem2];
          return [refreshedCommentForItem3];
        });

        clearInteractions(mockApiService);

        await notifier.refreshItemDetails();
        await container.pump();
        final state = container.read(workbenchProviderFamily(testInstanceId));

        expect(state.isLoading, false);
        expect(state.isRefreshingDetails, false);
        expect(state.error, isNull);
        expect(state.items.length, 3);

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

        expect(state.items[0].id, 'id3');
        expect(
          state.items[0].previewComments.first.id,
          refreshedCommentForItem3.id,
        );
        expect(
          state.items[0].overallLastUpdateTime,
          refreshedCommentForItem3.createdTs,
        );

        expect(state.items[1].id, 'id2');
        expect(
          state.items[1].previewComments.first.id,
          originalCommentForItem2.id,
        );
        expect(
          state.items[1].overallLastUpdateTime,
          originalCommentForItem2.createdTs,
        );

        expect(state.items[2].id, 'id1');
        expect(state.items[2].previewComments.isEmpty, isTrue);
        expect(state.items[2].overallLastUpdateTime, refreshedNote1UpdateTime);
      },
    );

    test(
      'refreshItemDetails handles API errors gracefully for individual items',
      () async {
        final notifier = container.read(
          workbenchProviderFamily(testInstanceId).notifier,
        );
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

        final originalState = container.read(
          workbenchProviderFamily(testInstanceId),
        );
        final originalItem1OverallTime =
            originalState.items
                .firstWhere((i) => i.id == 'id1')
                .overallLastUpdateTime;
        final originalItem2OverallTime =
            originalState.items
                .firstWhere((i) => i.id == 'id2')
                .overallLastUpdateTime;
        final originalItem3OverallTime =
            originalState.items
                .firstWhere((i) => i.id == 'id3')
                .overallLastUpdateTime;

        when(
          mockApiService.getNote(any, targetServerOverride: serverConfig1),
        ).thenAnswer((invocation) async {
          final id = invocation.positionalArguments[0] as String;
          if (id == item1.referencedItemId) throw exception;
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
        when(
          mockApiService.listNoteComments(
            any,
            targetServerOverride: serverConfig1,
          ),
        ).thenAnswer((invocation) async {
          final id = invocation.positionalArguments[0] as String;
          if (id == item2.referencedItemId) {
            return [
              Comment(
                id: 'c1',
                content: 'c',
                createdTs: now,
                parentId: 'p',
                serverId: 's1',
              ),
            ];
          }
          return [];
        });

        clearInteractions(mockApiService);

        await notifier.refreshItemDetails();
        await container.pump();
        final state = container.read(workbenchProviderFamily(testInstanceId));

        expect(state.isRefreshingDetails, false);
        expect(state.error, isNull);
        expect(state.items.length, 3);

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

        final item1State = state.items.firstWhere((i) => i.id == 'id1');
        expect(item1State.overallLastUpdateTime, originalItem1OverallTime);
        expect(item1State.previewComments.isEmpty, isTrue);

        final item2State = state.items.firstWhere((i) => i.id == 'id2');
        expect(item2State.overallLastUpdateTime, originalItem2OverallTime);

        final item3State = state.items.firstWhere((i) => i.id == 'id3');
        expect(item3State.overallLastUpdateTime, originalItem3OverallTime);

        expect(state.items.map((e) => e.id).toList(), ['id3', 'id2', 'id1']);
      },
    );

    test('refreshItemDetails does nothing if no items exist', () async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      when(
        mockCloudKitService.deleteAllWorkbenchItemReferences(
          instanceId: testInstanceId,
        ),
      ).thenAnswer((_) async => true);
      await notifier.clearItems();
      expect(
        container.read(workbenchProviderFamily(testInstanceId)).items,
        isEmpty,
      );

      clearInteractions(mockApiService);
      clearInteractions(mockCloudKitService);

      await notifier.refreshItemDetails();
      final state = container.read(workbenchProviderFamily(testInstanceId));

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
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      await notifier.loadItems();
      await container.pump();
      expect(
        container.read(workbenchProviderFamily(testInstanceId)).items.length,
        3,
      );
    });

    test(
      'clearItems success - removes all items locally and from CloudKit for the instance',
      () async {
        final notifier = container.read(
          workbenchProviderFamily(testInstanceId).notifier,
        );
        when(
          mockCloudKitService.deleteAllWorkbenchItemReferences(
            instanceId: testInstanceId,
          ),
        ).thenAnswer((_) async => true);

        await notifier.clearItems();
        final state = container.read(workbenchProviderFamily(testInstanceId));

        expect(state.items, isEmpty);
        expect(state.error, isNull);
        verify(
          mockCloudKitService.deleteAllWorkbenchItemReferences(
            instanceId: testInstanceId,
          ),
        ).called(1);
        verify(mockSharedPrefsService.saveLastOpenedItemMap(any)).called(1);
      },
    );

    test(
      'clearItems failure - reverts state for failed CloudKit deletions for the instance',
      () async {
        final notifier = container.read(
          workbenchProviderFamily(testInstanceId).notifier,
        );
        final exception = Exception('CloudKit deleteAll failed');
        when(
          mockCloudKitService.deleteAllWorkbenchItemReferences(
            instanceId: testInstanceId,
          ),
        ).thenThrow(exception);

        await notifier.clearItems();
        final state = container.read(workbenchProviderFamily(testInstanceId));

        expect(state.items.length, 3);
        expect(state.items[0].id, 'id3');
        expect(state.items[1].id, 'id2');
        expect(state.items[2].id, 'id1');
        expect(state.error, exception);
        verify(
          mockCloudKitService.deleteAllWorkbenchItemReferences(
            instanceId: testInstanceId,
          ),
        ).called(1);
        verifyNever(mockSharedPrefsService.saveLastOpenedItemMap(any));
      },
    );

    test('clearItems does nothing if list is already empty', () async {
      final notifier = container.read(
        workbenchProviderFamily(testInstanceId).notifier,
      );
      when(
        mockCloudKitService.deleteAllWorkbenchItemReferences(
          instanceId: testInstanceId,
        ),
      ).thenAnswer((_) async => true);
      await notifier.clearItems();
      expect(
        container.read(workbenchProviderFamily(testInstanceId)).items,
        isEmpty,
      );

      clearInteractions(mockCloudKitService);

      await notifier.clearItems();
      final state = container.read(workbenchProviderFamily(testInstanceId));

      expect(state.items, isEmpty);
      expect(state.error, isNull);
      verifyNever(
        mockCloudKitService.deleteAllWorkbenchItemReferences(
          instanceId: testInstanceId,
        ),
      );
    });
  });
}
