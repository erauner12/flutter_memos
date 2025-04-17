import 'package:flutter_memos/models/comment.dart'; // Add Comment import
import 'package:flutter_memos/models/multi_server_config_state.dart'; // Import MultiServerConfigState
import 'package:flutter_memos/models/note_item.dart'; // Add NoteItem import
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/api_providers.dart'; // Add API provider import
import 'package:flutter_memos/providers/server_config_provider.dart'; // Add Server Config provider import
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_memos/services/note_api_service.dart'; // Add NoteApiService import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import generated mocks
import 'workbench_provider_test.mocks.dart';

// Generate mocks for CloudKitService AND NoteApiService
@GenerateNiceMocks([
  MockSpec<CloudKitService>(),
  MockSpec<NoteApiService>(), // Change BaseApiService to NoteApiService
])
// Define test variables
late DateTime now;
late MockCloudKitService mockCloudKitService;
late MockNoteApiService
mockApiService; // Change MockBaseApiService to MockNoteApiService
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
    mockApiService = MockNoteApiService(); // Initialize MockNoteApiService
    container = ProviderContainer(
      overrides: [
        cloudKitServiceProvider.overrideWithValue(mockCloudKitService),
        // Override apiServiceProvider to return the mock NoteApiService
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
  });

  tearDown(() {
    container.dispose();
  });

  group('initial state and loadItems', () {
    test('initial state is loading', () {
      final state = container.read(workbenchProvider);
      expect(state.isLoading, false);
      expect(state.items, isEmpty);
      expect(state.error, isNull);
      verifyNever(mockCloudKitService.getAllWorkbenchItemReferences());
    });

    test('loadItems success - fetches details and sorts by overallLastUpdateTime descending', () async {
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
          .thenAnswer((_) async => [item1, item3, item2]);
        final note1UpdateTime = now.subtract(const Duration(days: 1, hours: 1));
        final note2UpdateTime = now.subtract(const Duration(hours: 12));
        final note3UpdateTime = now.subtract(const Duration(hours: 1));
      final commentForItem2 = Comment(
        id: 'comment1',
        content: 'Latest comment',
          createdTs: now, // Use createdTs with DateTime
          parentId: 'parent-id', // Add required parentId
          serverId: serverConfig1.id, // Add required serverId
        );
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
          .thenAnswer((_) async => []);
      when(mockApiService.listNoteComments(item2.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => [commentForItem2]);
      when(mockApiService.listNoteComments(item3.referencedItemId, targetServerOverride: serverConfig1))
          .thenAnswer((_) async => []);

        await notifier.loadItems();
        await Future.delayed(const Duration(milliseconds: 100));
      final state = container.read(workbenchProvider);

      expect(state.isLoading, false);
        expect(state.isRefreshingDetails, false);
      expect(state.error, isNull);
        expect(state.items.length, 3);
      verify(mockApiService.getNote(item1.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.listNoteComments(item1.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.getNote(item2.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.listNoteComments(item2.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.getNote(item3.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.listNoteComments(item3.referencedItemId, targetServerOverride: serverConfig1)).called(1);

        expect(state.items[0].id, 'id3');
        expect(state.items[0].previewComments.isEmpty, isTrue);
        expect(state.items[0].overallLastUpdateTime, item3.addedTimestamp);

        expect(state.items[1].id, 'id2');
        expect(state.items[1].previewComments.first.id, commentForItem2.id);
        expect(
          state.items[1].overallLastUpdateTime, // Compare DateTime directly
          commentForItem2.createdTs,
        ); // overall = comment (now)

        expect(state.items[2].id, 'id1');
        expect(state.items[2].previewComments.isEmpty, isTrue);
        expect(state.items[2].overallLastUpdateTime, note1UpdateTime);
    });

    test('loadItems failure', () async {
      final exception = Exception('CloudKit failed');
      when(
        mockCloudKitService.getAllWorkbenchItemReferences(),
      ).thenThrow(exception);

      await notifier.loadItems();
      final state = container.read(workbenchProvider);

      expect(state.isLoading, false);
      expect(state.error, exception);
      expect(state.items, isEmpty);
      verify(mockCloudKitService.getAllWorkbenchItemReferences()).called(1);
    });
  });

  group('addItem', () {
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
      final note1UpdateTime = now.subtract(const Duration(days: 1, hours: 1));
      final note2UpdateTime = now.subtract(const Duration(hours: 12));
      final note3UpdateTime = now.subtract(const Duration(hours: 1));
      final commentForItem2 = Comment(
        id: 'comment1',
        content: 'Latest comment',
        createdTs: now, // Use createdTs with DateTime
        parentId: 'parent-id', // Add required parentId
        serverId: serverConfig1.id, // Add required serverId
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
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('addItem success - adds item, fetches details, and sorts list', () async {
        final newItem = createMockItem(
          'id4',
          now.add(const Duration(days: 1)),
        );
        final note4UpdateTime = now.add(const Duration(days: 1, hours: 1));
        when(
          mockCloudKitService.saveWorkbenchItemReference(newItem),
        ).thenAnswer((_) async => true);
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
          .thenAnswer((_) async => []);

      await notifier.addItem(newItem);
        await Future.delayed(const Duration(milliseconds: 100));
      final state = container.read(workbenchProvider);

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
      verify(mockApiService.getNote(newItem.referencedItemId, targetServerOverride: serverConfig1)).called(1);
      verify(mockApiService.listNoteComments(newItem.referencedItemId, targetServerOverride: serverConfig1)).called(1);
    });

    test('addItem failure - reverts optimistic add and sorts', () async {
      final newItem = createMockItem(
        'id4',
        now.add(const Duration(days: 1)),
      );
      final exception = Exception('Save failed');
      when(
        mockCloudKitService.saveWorkbenchItemReference(newItem),
      ).thenThrow(exception);

      await notifier.addItem(newItem);
      final state = container.read(workbenchProvider);

      expect(state.items.length, 3);
      expect(state.items.any((item) => item.id == 'id4'), isFalse);
      expect(state.items[0].id, 'id3');
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
      expect(state.error, exception);
      verify(mockCloudKitService.saveWorkbenchItemReference(newItem)).called(1);
    });

    test('addItem duplicate - does not add item or call CloudKit', () async {
      final duplicateItem = createMockItem(
        'newIdSameRef',
        now.add(const Duration(days: 1)),
      )
          .copyWith(
        referencedItemId:
            createMockItem(
              'id2',
              now.subtract(const Duration(days: 1)),
            ).referencedItemId,
        serverId: serverConfig1.id,
      );

      await notifier.addItem(duplicateItem);
      final state = container.read(workbenchProvider);

      expect(state.items.length, 3);
      expect(state.items[0].id, 'id3');
      expect(state.items[1].id, 'id2');
      expect(state.items[2].id, 'id1');
      expect(state.error, isNull);
      verifyNever(mockCloudKitService.saveWorkbenchItemReference(duplicateItem));
    });
  });

  group('removeItem', () {
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
      final note1UpdateTime = now.subtract(const Duration(days: 1, hours: 1));
      final note2UpdateTime = now.subtract(const Duration(hours: 12));
      final note3UpdateTime = now.subtract(const Duration(hours: 1));
      final commentForItem2 = Comment(
        id: 'comment1',
        content: 'Latest comment',
        createdTs: now, // Use createdTs with DateTime
        parentId: 'parent-id', // Add required parentId
        serverId: serverConfig1.id, // Add required serverId
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
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('removeItem success - removes item', () async {
      when(
        mockCloudKitService.deleteWorkbenchItemReference('id2'),
      ).thenAnswer((_) async => true);

      await notifier.removeItem('id2');
      final state = container.read(workbenchProvider);

      expect(state.items.length, 2);
      expect(state.items.any((item) => item.id == 'id2'), isFalse);
      expect(state.items[0].id, 'id3');
      expect(state.items[1].id, 'id1');
      expect(state.error, isNull);
      verify(mockCloudKitService.deleteWorkbenchItemReference('id2')).called(1);
    });

    test(
      'removeItem failure - reverts optimistic removal and maintains sort order',
      () async {
      final exception = Exception('Delete failed');
        when(
          mockCloudKitService.deleteWorkbenchItemReference('id3'),
        ).thenThrow(exception);

      await notifier.removeItem('id3');
      final state = container.read(workbenchProvider);

        expect(state.items.length, 3);
        expect(state.items[0].id, 'id3');
        expect(state.items[1].id, 'id2');
        expect(state.items[2].id, 'id1');
        expect(state.error, exception);
        verify(
          mockCloudKitService.deleteWorkbenchItemReference('id3'),
        ).called(1);
    });

    test('removeItem non-existent id - does nothing', () async {
      await notifier.removeItem('non-existent-id');
      final state = container.read(workbenchProvider);

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
        createdTs: now, // Use createdTs with DateTime
        parentId: 'parent-id', // Add required parentId
        serverId: serverConfig1.id, // Add required serverId
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
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('moves item downwards correctly', () {
      notifier.reorderItems(0, 2);
      final state = container.read(workbenchProvider);
      expect(state.items.map((e) => e.id).toList(), ['id2', 'id3', 'id1']);
    });

    test('moves item upwards correctly', () {
      notifier.reorderItems(2, 0);
      final state = container.read(workbenchProvider);
      expect(state.items.map((e) => e.id).toList(), ['id1', 'id3', 'id2']);
    });

    test('moves item to the end correctly', () {
      notifier.reorderItems(0, 3);
      final state = container.read(workbenchProvider);
      expect(state.items.map((e) => e.id).toList(), ['id2', 'id1', 'id3']);
    });

    test('does nothing for invalid indices', () {
      final initialOrder = container.read(workbenchProvider).items;
      notifier.reorderItems(-1, 1);
      expect(container.read(workbenchProvider).items, initialOrder);
      notifier.reorderItems(3, 1);
      expect(container.read(workbenchProvider).items, initialOrder);
      notifier.reorderItems(0, 4);
      expect(container.read(workbenchProvider).items, initialOrder);
      notifier.reorderItems(1, -1);
      expect(container.read(workbenchProvider).items, initialOrder);
    });
  });

  group('resetOrder', () {
    setUp(() async {
      when(mockCloudKitService.getAllWorkbenchItemReferences())
          .thenAnswer(
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
        createdTs: now, // Use createdTs with DateTime
        parentId: 'parent-id', // Add required parentId
        serverId: serverConfig1.id, // Add required serverId
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
    });

    test('resets manually reordered list to default sort (overallLastUpdateTime desc)', () {
        notifier.reorderItems(2, 0);
        notifier.reorderItems(2, 1);
      final reorderedState = container.read(workbenchProvider);
        expect(reorderedState.items.map((e) => e.id).toList(), [
          'id1',
          'id2',
          'id3',
        ]);

      notifier.resetOrder();
      final state = container.read(workbenchProvider);
        expect(state.items.map((e) => e.id).toList(), ['id3', 'id2', 'id1']);
    });

    test('does nothing if already in default order (overallLastUpdateTime desc)', () {
        final initialOrder = container.read(workbenchProvider).items;
        expect(initialOrder.map((e) => e.id).toList(), ['id3', 'id2', 'id1']);

      notifier.resetOrder();
        final state = container.read(workbenchProvider);
        expect(
          state.items.map((e) => e.id).toList(),
          initialOrder.map((e) => e.id).toList(),
        );
    });
  });

  group('refreshItemDetails', () {
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
        createdTs: now, // Use createdTs with DateTime
        parentId: 'parent-id', // Add required parentId
        serverId: serverConfig1.id, // Add required serverId
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
    });

    test(
      'refreshItemDetails success - re-fetches details and updates state',
      () async {
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
          createdTs: now, // Use createdTs with DateTime
          parentId: 'parent-id', // Add required parentId
          serverId: serverConfig1.id, // Add required serverId
        );
        final refreshedCommentForItem3 = Comment(
          id: 'comment2',
          content: 'Refreshed comment',
          createdTs: now.add(
            const Duration(minutes: 1),
          ), // Use createdTs with DateTime
          parentId: 'parent-id', // Add required parentId
          serverId: serverConfig1.id, // Add required serverId
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
          } else if (id == item2.referencedItemId) {
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
            return [];
          } else if (id == item2.referencedItemId) {
            return [originalCommentForItem2];
          } else {
            return [refreshedCommentForItem3];
          }
        });

        clearInteractions(mockApiService);

        await notifier.refreshItemDetails();
        await Future.delayed(const Duration(milliseconds: 100));
        final state = container.read(workbenchProvider);

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

        expect(state.items[0].id, 'id3',
        );
        expect(
          state.items[0].previewComments.first.id,
          refreshedCommentForItem3.id,
        ); // Use previewComments.first
        expect(
          state.items[0].overallLastUpdateTime, // Compare DateTime directly
          refreshedCommentForItem3.createdTs,
        );

        expect(state.items[1].id, 'id2'); // Next newest (original comment)
        expect(
          state.items[1].previewComments.first.id, // Use previewComments.first
          originalCommentForItem2.id,
        );
        expect(
          state.items[1].overallLastUpdateTime, // Compare DateTime directly
          originalCommentForItem2.createdTs,
        );

        expect(state.items[2].id, 'id1',
        );
        expect(
          state.items[2].previewComments.isEmpty,
          isTrue,
        ); // Check if previewComments is empty
        expect(state.items[2].overallLastUpdateTime, refreshedNote1UpdateTime);
      },
    );

    test(
      'refreshItemDetails handles API errors gracefully for individual items',
      () async {
        final item1 = createMockItem(
          'id1',
          now.subtract(const Duration(days: 2)),
        );
        final item2 = createMockItem(
          'id2',
          now.subtract(const Duration(days: 1)),
        );
        final exception = Exception('API failed for item1');

        final expectedItem1OverallTime = item1.addedTimestamp;

        when(
          mockApiService.getNote(any, targetServerOverride: serverConfig1),
        ).thenAnswer((invocation) async {
          final id = invocation.positionalArguments[0] as String;
          if (id == item1.referencedItemId) {
            throw exception;
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

        clearInteractions(mockApiService);

        await notifier.refreshItemDetails();
        await Future.delayed(const Duration(milliseconds: 100));
        final state = container.read(workbenchProvider);

        expect(state.isRefreshingDetails, false);
        expect(state.error, isNull);
        expect(state.items.length, 3);

        final item1State = state.items.firstWhere((i) => i.id == 'id1');
        expect(item1State.overallLastUpdateTime, expectedItem1OverallTime);
        expect(
          item1State.previewComments.isEmpty,
          isTrue,
        ); // Check if previewComments is empty

        expect(state.items.map((e) => e.id).toList(), ['id3', 'id2', 'id1']);
      },
    );

    test('refreshItemDetails does nothing if no items exist', () async {
      when(
        mockCloudKitService.deleteWorkbenchItemReference(any),
      ).thenAnswer((_) async => true);
      await notifier.clearItems();
      expect(container.read(workbenchProvider).items, isEmpty);
      clearInteractions(mockApiService);
      clearInteractions(mockCloudKitService);

      await notifier.refreshItemDetails();
      final state = container.read(workbenchProvider);

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
        createdTs: now, // Use createdTs with DateTime
        parentId: 'parent-id', // Add required parentId
        serverId: serverConfig1.id, // Add required serverId
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
      expect(container.read(workbenchProvider).items.length, 3);
    });

    test(
      'clearItems success - removes all items locally and from CloudKit',
      () async {
        when(
          mockCloudKitService.deleteWorkbenchItemReference('id1'),
        ).thenAnswer((_) async => true);
        when(
          mockCloudKitService.deleteWorkbenchItemReference('id2'),
        ).thenAnswer((_) async => true);
        when(
          mockCloudKitService.deleteWorkbenchItemReference('id3'),
        ).thenAnswer((_) async => true);

        await notifier.clearItems();
        final state = container.read(workbenchProvider);

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

        await notifier.clearItems();
        final state = container.read(workbenchProvider);

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
      when(
        mockCloudKitService.deleteWorkbenchItemReference(any),
      ).thenAnswer((_) async => true);
      await notifier.clearItems();
      expect(container.read(workbenchProvider).items, isEmpty);
      clearInteractions(mockCloudKitService);

      await notifier.clearItems();
      final state = container.read(workbenchProvider);

      expect(state.items, isEmpty);
      expect(state.error, isNull);
      verifyNever(mockCloudKitService.deleteWorkbenchItemReference(any));
    });
  });
}
