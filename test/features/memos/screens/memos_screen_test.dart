import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/list_notes_response.dart'; // Updated import
import 'package:flutter_memos/models/multi_server_config_state.dart';
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/note_providers.dart'; // Updated import
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/screens/items/items_screen.dart'; // Updated import
import 'package:flutter_memos/screens/items/note_list_item.dart'; // Updated import
import 'package:flutter_memos/screens/items/notes_list_body.dart'; // Updated import
import 'package:flutter_memos/services/api_service.dart'; // Keep for PaginatedMemoResponse if needed elsewhere, or remove if ListNotesResponse is sufficient
import 'package:flutter_memos/services/base_api_service.dart'; // Updated import
import 'package:flutter_memos/widgets/advanced_filter_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'memos_screen_test.mocks.dart'; // Keep mock file name for now

// Generate nice mock for BaseApiService
@GenerateNiceMocks([MockSpec<BaseApiService>()])
// Helper to create a list of dummy notes
List<NoteItem> createDummyNotes(int count) { // Updated function name and type
  return List.generate(count, (i) {
    final now = DateTime.now();
    final updateTime = now.subtract(Duration(minutes: i));
    return NoteItem( // Updated type
      id: 'note_$i', // Updated prefix
      content: 'Dummy Note Content $i', // Updated content
      pinned: false,
      state: NoteState.normal, // Updated enum
      updateTime: updateTime,
      createTime: updateTime,
      displayTime: updateTime, // Add required field
      visibility: NoteVisibility.private, // Add required field
    );
  });
}

// Mock Notifier extending the actual Notifier
class MockNotesNotifier extends NotesNotifier { // Updated class name
  // Constructor needs to call super, passing the ref and setting the skip flag
  MockNotesNotifier(super.ref, NotesState initialState) // Updated state type
    : super(skipInitialFetchForTesting: true) {
    // Manually set the state after initialization
    state = initialState;
  }

  // Override methods that might be called during the test if needed
  @override
  Future<void> refresh() async {
    // No-op for mock
  }

  @override
  Future<void> fetchMoreNotes() async { // Updated method name
    // No-op for mock
  }
}

// Modify buildTestableWidget to accept the container and use CupertinoApp
Widget buildTestableWidget(Widget child, ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: CupertinoApp(
      home: child,
      // Define routes needed for navigation actions within NoteListItem
      routes: {
        '/edit-entity':
            (context) => const CupertinoPageScaffold(
              child: Center(child: Text('Edit Screen')),
            ),
        '/item-detail': // Updated route name
            (context) => const CupertinoPageScaffold(
              child: Center(child: Text('Detail Screen')),
            ),
        '/new-note': // Updated route name
            (context) => const CupertinoPageScaffold(
              child: Center(child: Text('New Note Screen')),
            ),
        '/settings':
            (context) => const CupertinoPageScaffold(
              child: Center(child: Text('Settings Screen')),
            ),
      },
    ),
  );
} // End of buildTestableWidget

// Mock Notifier for MultiServerConfigState that extends the real one
class MockMultiServerConfigNotifier extends MultiServerConfigNotifier {
  MockMultiServerConfigNotifier(
    super.ref,
    MultiServerConfigState initialState,
  ) {
    state = initialState;
  }

  @override
  Future<void> loadConfiguration() async {
    // No-op
  }

  @override
  Future<bool> addServer(ServerConfig config) async {
    state = state.copyWith(servers: [...state.servers, config]);
    return true;
  }

  @override
  void setActiveServer(String? serverId) {
    state = state.copyWith(activeServerId: serverId);
  }

  @override
  Future<bool> setDefaultServer(String? serverId) async {
    state = state.copyWith(defaultServerId: () => serverId);
    return true;
  }

  // Add missing resetStateAndCache method
  @override
  Future<void> resetStateAndCache() async {
    state = const MultiServerConfigState(); // Reset to default state
    // Simulate clearing cache if needed for test verification
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_config_cache');
    await prefs.remove('defaultServerId');
  }
}

void main() {
  final dummyNotes = createDummyNotes(3); // Updated variable name and function call
  late ProviderContainer container;
  late MockBaseApiService mockApiService; // Updated mock type
  late ServerConfig mockServer1;
  late ServerConfig mockServer2;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockApiService = MockBaseApiService(); // Updated mock type

    // Create mock server configs with serverType
    mockServer1 = ServerConfig(
      id: const Uuid().v4(),
      name: 'Mock Server 1',
      serverUrl: 'https://mock1.test',
      authToken: 'token1',
      serverType: ServerType.memos, // Added serverType
    );
    mockServer2 = ServerConfig(
      id: const Uuid().v4(),
      name: 'Mock Server 2',
      serverUrl: 'https://mock2.test',
      authToken: 'token2',
      serverType: ServerType.memos, // Added serverType
    );

    when(mockApiService.apiBaseUrl).thenReturn(mockServer1.serverUrl);

    // Configure the mock API service to return the dummy notes
    when(
      mockApiService.listNotes(
        // Updated method name
        filter: anyNamed('filter'),
        state: anyNamed('state'),
        sort: anyNamed('sort'),
        direction: anyNamed('direction'),
        pageSize: anyNamed('pageSize'),
        pageToken: anyNamed('pageToken'),
      ),
    ).thenAnswer(
      (_) async => ListNotesResponse( // Updated response type
        notes: dummyNotes, // Updated field name
        nextPageToken: null,
      ),
    );

    final initialNoteState = const NotesState().copyWith( // Updated state type
      notes: dummyNotes, // Updated field name
      isLoading: false,
      hasReachedEnd: true,
      totalLoaded: dummyNotes.length,
    );

    final initialMultiServerState = MultiServerConfigState(
      servers: [mockServer1, mockServer2],
      activeServerId: mockServer1.id,
      defaultServerId: mockServer1.id,
    );

    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
        notesNotifierProvider.overrideWith( // Updated provider name
          (ref) => MockNotesNotifier(ref, initialNoteState), // Updated mock type
        ),
        multiServerConfigProvider.overrideWith(
          (ref) => MockMultiServerConfigNotifier(ref, initialMultiServerState),
        ),
        ui_providers.itemMultiSelectModeProvider.overrideWith((ref) => false), // Use renamed provider
        ui_providers.selectedItemIdsForMultiSelectProvider.overrideWith( // Use renamed provider
          (ref) => {},
        ),
        ui_providers.selectedItemIdProvider.overrideWith((ref) => null), // Use renamed provider
        quickFilterPresetProvider.overrideWith(
          (ref) => 'inbox',
        ),
      ],
    );

    await container.read(loadFilterPreferencesProvider.future);
  });

  tearDown(() {
    container.dispose();
  });

  testWidgets('ItemsScreen displays standard UI elements initially', ( // Updated screen name
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const ItemsScreen(), container), // Updated screen name
    );
    await tester.pumpAndSettle();

    // Act & Assert
    expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('Inbox'),
      ),
      findsOneWidget,
    );
    final navBarFinder = find.byType(CupertinoNavigationBar);
    final serverSwitcherButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.square_stack_3d_down_right,
      ),
    );
    expect(serverSwitcherButtonFinder, findsOneWidget);
    expect(find.textContaining('Mock Server 1'), findsOneWidget);

    final multiSelectButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.checkmark_seal,
      ),
    );
    expect(multiSelectButtonFinder, findsOneWidget);
    final advancedFilterButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(CupertinoButton, CupertinoIcons.tuningfork),
    );
    expect(advancedFilterButtonFinder, findsOneWidget);
    final addButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(CupertinoButton, CupertinoIcons.add),
    );
    expect(addButtonFinder, findsOneWidget);

    expect(find.byType(CupertinoSearchTextField), findsOneWidget);
    expect(
      find.byType(CupertinoSlidingSegmentedControl<String>),
      findsOneWidget,
    );
    expect(find.text('Inbox'), findsWidgets);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Tagged'), findsWidgets);
    expect(find.text('All'), findsWidgets);

    // Verify Note List Items (now within NotesListBody)
    expect(find.byType(NotesListBody), findsOneWidget); // Updated body widget

    expect(
      find.widgetWithIcon(CupertinoButton, CupertinoIcons.clear),
      findsNothing,
    );
    expect(find.textContaining('Selected'), findsNothing);

    expect(
      find.descendant(
        of: navBarFinder,
        matching: find.widgetWithIcon(
          CupertinoButton,
          CupertinoIcons.checkmark_seal,
        ),
      ),
      findsOneWidget,
      reason: 'Multi-select toggle button should be present',
    );
    expect(
      find.descendant(
        of: navBarFinder,
        matching: find.widgetWithIcon(
          CupertinoButton,
          CupertinoIcons.tuningfork,
        ),
      ),
      findsOneWidget,
      reason: 'Advanced filter button should be present',
    );
    expect(
      find.descendant(
        of: navBarFinder,
        matching: find.widgetWithIcon(CupertinoButton, CupertinoIcons.add),
      ),
      findsOneWidget,
      reason: 'Add note button should be present', // Updated message
    );
    expect(
      find.descendant(
        of: find.byType(NoteListItem), // Updated item widget
        matching: find.byType(CupertinoSwitch),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(NoteListItem), // Updated item widget
        matching: find.byType(CupertinoCheckbox),
      ),
      findsNothing,
    );

    expect(
      find.descendant(
        of: find.byType(NoteListItem), // Updated item widget
        matching: find.byType(Slidable),
      ),
      findsNWidgets(dummyNotes.length),
    );
  });

  testWidgets('ItemsScreen enters multi-select mode on button tap', ( // Updated screen name
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const ItemsScreen(), container), // Updated screen name
    );
    await tester.pumpAndSettle();

    // Act: Find and tap the "Select" button
    final navBarFinder = find.byType(CupertinoNavigationBar);
    final selectButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.checkmark_seal,
      ),
    );
    expect(selectButtonFinder, findsOneWidget);
    await tester.tap(selectButtonFinder);
    await tester.pumpAndSettle();

    // Assert
    expect(container.read(ui_providers.itemMultiSelectModeProvider), isTrue); // Use renamed provider

    expect(
      find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.clear,
      ),
      findsOneWidget,
    );
    expect(find.text('0 Selected'), findsOneWidget);
    expect(
      find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.delete,
      ),
      findsOneWidget,
    );
    expect(
      find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.archivebox,
      ),
      findsOneWidget,
    );
    expect(find.text('Inbox'), findsNothing);
    expect(
      find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.checkmark_seal,
      ),
      findsNothing,
    );
    expect(
      find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.tuningfork,
      ),
      findsNothing,
    );
    expect(
      find.widgetWithIcon(CupertinoButton, CupertinoIcons.add),
      findsNothing,
    );
    expect(find.byType(CupertinoSearchTextField), findsNothing);
    expect(find.byType(CupertinoSlidingSegmentedControl<String>), findsNothing);

    final checkboxFinder = find.descendant(
      of: find.byType(NoteListItem), // Updated item widget
      matching: find.byType(CupertinoCheckbox),
    );
    expect(checkboxFinder, findsNWidgets(dummyNotes.length));
  });

  testWidgets('ItemsScreen selects/deselects note via Checkbox tap', ( // Updated screen name and type
    WidgetTester tester,
  ) async {
    // Arrange: Enter multi-select mode
    await tester.pumpWidget(
      buildTestableWidget(const ItemsScreen(), container), // Updated screen name
    );
    await tester.pumpAndSettle();
    final navBarFinder = find.byType(CupertinoNavigationBar);
    final selectButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.checkmark_seal,
      ),
    );
    await tester.tap(selectButtonFinder);
    await tester.pumpAndSettle();

    // Act: Tap the first checkbox
    final firstItemFinder = find.byType(NoteListItem).first; // Updated item widget
    final firstCheckboxFinder = find.descendant(
      of: firstItemFinder,
      matching: find.byType(CupertinoCheckbox),
    );
    expect(firstCheckboxFinder, findsOneWidget);
    await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();

    // Assert: Item selected
    expect(
      container.read(ui_providers.selectedItemIdsForMultiSelectProvider), // Use renamed provider
      contains(dummyNotes[0].id),
    );
    expect(
      container.read(ui_providers.selectedItemIdsForMultiSelectProvider).length, // Use renamed provider
      1,
    );
    expect(find.text('1 Selected'), findsOneWidget);

    // Act: Tap the first checkbox again
    await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();

    // Assert: Item deselected
    expect(
      container.read(ui_providers.selectedItemIdsForMultiSelectProvider), // Use renamed provider
      isEmpty,
    );
    expect(find.text('0 Selected'), findsOneWidget);
  });

  testWidgets('ItemsScreen exits multi-select mode via Cancel button', ( // Updated screen name
    WidgetTester tester,
  ) async {
    // Arrange: Enter multi-select mode and select an item
    await tester.pumpWidget(
      buildTestableWidget(const ItemsScreen(), container), // Updated screen name
    );
    await tester.pumpAndSettle();
    container.read(ui_providers.toggleItemMultiSelectModeProvider)(); // Use renamed provider
    await tester.pumpAndSettle();
    final firstItemFinder = find.byType(NoteListItem).first; // Updated item widget
    final firstCheckboxFinder = find.descendant(
      of: firstItemFinder,
      matching: find.byType(CupertinoCheckbox),
    );
    await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();
    expect(container.read(ui_providers.itemMultiSelectModeProvider), isTrue); // Use renamed provider
    expect(
      container.read(ui_providers.selectedItemIdsForMultiSelectProvider), // Use renamed provider
      isNotEmpty,
    );

    // Act: Tap the Cancel button
    final navBarFinder = find.byType(CupertinoNavigationBar);
    final cancelButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(CupertinoButton, CupertinoIcons.clear),
    );
    expect(cancelButtonFinder, findsOneWidget);
    await tester.tap(cancelButtonFinder);
    await tester.pumpAndSettle();

    // Assert: Exited multi-select mode
    expect(container.read(ui_providers.itemMultiSelectModeProvider), isFalse); // Use renamed provider
    expect(
      container.read(ui_providers.selectedItemIdsForMultiSelectProvider), // Use renamed provider
      isEmpty,
    );

    // Verify NavigationBar reverts
    expect(
      find.descendant(
        of: navBarFinder,
        matching: find.text('Inbox'),
      ),
      findsOneWidget,
      reason: 'Title should revert to preset label',
    );
    expect(
      find.descendant(
        of: navBarFinder,
        matching: find.widgetWithIcon(
          CupertinoButton,
          CupertinoIcons.checkmark_seal,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: navBarFinder,
        matching: find.widgetWithIcon(CupertinoButton, CupertinoIcons.clear),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: navBarFinder,
        matching: find.textContaining('Selected'),
      ),
      findsNothing,
    );

    expect(find.byType(CupertinoSearchTextField), findsOneWidget);
    expect(
      find.byType(CupertinoSlidingSegmentedControl<String>),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: find.byType(NoteListItem), // Updated item widget
        matching: find.byType(CupertinoCheckbox),
      ),
      findsNothing,
    );
  });

  testWidgets('ItemsScreen displays server switcher and opens action sheet', ( // Updated screen name
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const ItemsScreen(), container), // Updated screen name
    );
    await tester.pumpAndSettle();

    // Act: Find the server switcher button and tap it
    final navBarFinder = find.byType(CupertinoNavigationBar);
    final serverSwitcherButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.square_stack_3d_down_right,
      ),
    );
    expect(serverSwitcherButtonFinder, findsOneWidget);
    expect(
      find.textContaining('Mock Server 1'),
      findsOneWidget,
    );

    await tester.tap(serverSwitcherButtonFinder);
    await tester.pumpAndSettle();

    // Assert: Action sheet appears
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    expect(find.text('Switch Active Server'), findsOneWidget);
    expect(find.text('Mock Server 1'), findsWidgets);
    expect(find.text('Mock Server 2'), findsWidgets);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('ItemsScreen updates filter preset via segmented control', ( // Updated screen name
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const ItemsScreen(), container), // Updated screen name
    );
    await tester.pumpAndSettle();
    expect(container.read(quickFilterPresetProvider), 'inbox');

    final navBarFinder = find.byType(CupertinoNavigationBar);
    expect(
      find.descendant(
        of: navBarFinder,
        matching: find.text('Inbox'),
      ),
      findsOneWidget,
      reason: 'Initial title should be Inbox',
    );

    // Act: Tap the 'Today' segment
    final todaySegmentFinder = find.descendant(
      of: find.byType(CupertinoSlidingSegmentedControl<String>),
      matching: find.text('Today'),
    );
    expect(todaySegmentFinder, findsOneWidget);
    await tester.tap(todaySegmentFinder);
    await tester.pumpAndSettle();

    // Assert: Provider updated and title changed
    expect(container.read(quickFilterPresetProvider), 'today');
    expect(
      find.descendant(
        of: navBarFinder, matching: find.text('Today'),
      ),
      findsOneWidget,
      reason: 'Title should update to Today',
    );

    // Act: Tap the 'All' segment
    final allSegmentFinder = find.descendant(
      of: find.byType(CupertinoSlidingSegmentedControl<String>),
      matching: find.text('All'),
    );
    expect(allSegmentFinder, findsOneWidget);
    await tester.tap(allSegmentFinder);
    await tester.pumpAndSettle();

    // Assert: Provider updated and title changed
    expect(container.read(quickFilterPresetProvider), 'all');
    expect(
      find.descendant(
        of: navBarFinder, matching: find.text('All'),
      ),
      findsOneWidget,
      reason: 'Title should update to All',
    );
  });

  testWidgets('ItemsScreen opens AdvancedFilterPanel on tuning fork tap', ( // Updated screen name
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const ItemsScreen(), container), // Updated screen name
    );
    await tester.pumpAndSettle();

    // Act: Tap the advanced filter button
    final navBarFinder = find.byType(CupertinoNavigationBar);
    final advancedFilterButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(CupertinoButton, CupertinoIcons.tuningfork),
    );
    expect(advancedFilterButtonFinder, findsOneWidget);
    await tester.tap(advancedFilterButtonFinder);
    await tester.pumpAndSettle();

    // Assert: AdvancedFilterPanel is displayed
    expect(find.byType(AdvancedFilterPanel), findsOneWidget);
    expect(find.text('Advanced Filter'), findsOneWidget);
  });
}
