import 'package:flutter/cupertino.dart'; // Import Cupertino
// Remove unused Icons import
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/multi_server_config_state.dart'; // Import MultiServerConfigState
import 'package:flutter_memos/models/server_config.dart'; // Import ServerConfig
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/screens/memos/memo_list_item.dart';
import 'package:flutter_memos/screens/memos/memos_body.dart'; // Import MemosBody
import 'package:flutter_memos/screens/memos/memos_screen.dart';
import 'package:flutter_memos/services/api_service.dart' as api_service;
import 'package:flutter_memos/services/api_service.dart'; // Import for PaginatedMemoResponse
import 'package:flutter_memos/widgets/advanced_filter_panel.dart'; // Import AdvancedFilterPanel
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Keep if Slidable is used
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:uuid/uuid.dart'; // Import Uuid

import 'memos_screen_test.mocks.dart';

// Generate nice mock for ApiService
@GenerateNiceMocks([MockSpec<api_service.ApiService>()])
// Helper to create a list of dummy memos
List<Memo> createDummyMemos(int count) {
  return List.generate(count, (i) {
    final now = DateTime.now();
    final updateTime = now.subtract(Duration(minutes: i)).toIso8601String();
    return Memo(
      id: 'memo_$i',
      content: 'Dummy Memo Content $i',
      pinned: false,
      state: MemoState.normal,
      updateTime: updateTime,
      createTime: updateTime,
    );
  });
}

// Mock Notifier extending the actual Notifier
class MockMemosNotifier extends MemosNotifier {
  // Constructor needs to call super, passing the ref and setting the skip flag
  MockMemosNotifier(super.ref, MemosState initialState)
    : super(skipInitialFetchForTesting: true) {
    // Manually set the state after initialization
    state = initialState;
  }

  // Override methods that might be called during the test if needed,
  // otherwise, they inherit the base implementation (which might try to fetch)
  @override
  Future<void> refresh() async {
    // No-op for mock
  }

  @override
  Future<void> fetchMoreMemos() async {
    // No-op for mock
  }
}

// Modify buildTestableWidget to accept the container and use CupertinoApp
Widget buildTestableWidget(Widget child, ProviderContainer container) {
  // Keep ProviderScope so the widget can lookup providers
  // Link it to the container created in the test setup
  return UncontrolledProviderScope(
    container: container,
    child: CupertinoApp(
      // Use CupertinoApp
      home: child,
      // Define routes needed for navigation actions within MemoListItem (like edit)
      routes: {
        '/edit-entity':
            (context) => const CupertinoPageScaffold(
              child: Center(child: Text('Edit Screen')),
            ),
        '/memo-detail':
            (context) => const CupertinoPageScaffold(
              child: Center(child: Text('Detail Screen')),
            ),
        '/new-memo':
            (context) => const CupertinoPageScaffold(
              child: Center(child: Text('New Memo Screen')),
            ),
        // Add route for settings if needed by server switcher
        '/settings':
            (context) => const CupertinoPageScaffold(
              child: Center(child: Text('Settings Screen')),
            ),
      },
      // Add onGenerateRoute for modal popups like AdvancedFilterPanel if needed
      // or ensure the test setup handles them.
    ),
  );
} // End of buildTestableWidget

// Mock Notifier for MultiServerConfigState that extends the real one
class MockMultiServerConfigNotifier extends MultiServerConfigNotifier {
  MockMultiServerConfigNotifier(MultiServerConfigState initialState) : super() {
    // Manually set the initial state after calling the super constructor
    state = initialState;
  }

  // Override methods only if their behavior needs to be mocked for the test
  @override
  Future<void> loadFromPreferences() async {
    // No-op for mock
  }

  @override
  Future<bool> addServer(ServerConfig config) async {
    // Simple state update for testing purposes if needed
    state = state.copyWith(servers: [...state.servers, config]);
    return true;
  }

  @override
  void setActiveServer(String? serverId) {
    // Simple state update for testing purposes if needed
    state = state.copyWith(activeServerId: serverId);
  }

  @override
  Future<bool> setDefaultServer(String? serverId) async {
    // Simple state update for testing purposes if needed
    state = state.copyWith(defaultServerId: () => serverId);
    return true;
  }

  // Add other overrides if necessary for specific test interactions
}

void main() {
  final dummyMemos = createDummyMemos(3); // Create 3 dummy memos for testing
  late ProviderContainer container; // Declare container
  late MockApiService mockApiService; // Declare the mock API service
  late ServerConfig mockServer1;
  late ServerConfig mockServer2;

  // Use setUp to create the container before each test
  setUp(() async {
    // Make setUp async for SharedPreferences
    // Initialize mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    // Initialize the mock API service
    mockApiService = MockApiService();

    // Create mock server configs
    mockServer1 = ServerConfig(
      id: const Uuid().v4(),
      name: 'Mock Server 1',
      serverUrl: 'https://mock1.test',
      authToken: 'token1',
    );
    mockServer2 = ServerConfig(
      id: const Uuid().v4(),
      name: 'Mock Server 2',
      serverUrl: 'https://mock2.test',
      authToken: 'token2',
    );

    // Add stub for apiBaseUrl property (using mockServer1's URL)
    when(mockApiService.apiBaseUrl).thenReturn(mockServer1.serverUrl);

    // Configure the mock API service to return the dummy memos
    when(
      mockApiService.listMemos(
        parent: anyNamed('parent'),
        filter: anyNamed('filter'),
        state: anyNamed('state'),
        sort: anyNamed('sort'),
        direction: anyNamed('direction'),
        pageSize: anyNamed('pageSize'),
        pageToken: anyNamed('pageToken'),
        // Remove deprecated parameters
        // tags: anyNamed('tags'),
        // visibility: anyNamed('visibility'),
        // contentSearch: anyNamed('contentSearch'),
        // createdAfter: anyNamed('createdAfter'),
        // createdBefore: anyNamed('createdBefore'),
        // updatedAfter: anyNamed('updatedAfter'),
        // updatedBefore: anyNamed('updatedBefore'),
        // timeExpression: anyNamed('timeExpression'),
        // useUpdateTimeForExpression: anyNamed('useUpdateTimeForExpression'),
      ),
    ).thenAnswer(
      (_) async => PaginatedMemoResponse(
        // Use the imported type
        memos: dummyMemos,
        nextPageToken: null, // No more pages available
      ),
    );

    final initialMemoState = const MemosState().copyWith(
      memos: dummyMemos,
      isLoading: false,
      hasReachedEnd: true,
      totalLoaded: dummyMemos.length,
    );

    // Initial multi-server state (server1 is active and default)
    final initialMultiServerState = MultiServerConfigState(
      servers: [mockServer1, mockServer2],
      activeServerId: mockServer1.id,
      defaultServerId: mockServer1.id,
    );

    container = ProviderContainer(
      overrides: [
        // Override the API service with our mock
        api_service.apiServiceProvider.overrideWithValue(mockApiService),
        // Override the actual notifier with our mock builder
        memosNotifierProvider.overrideWith(
          (ref) => MockMemosNotifier(ref, initialMemoState),
        ),
        // Override multi-server config provider with an instance of the mock notifier
        multiServerConfigProvider.overrideWith(
          (ref) => MockMultiServerConfigNotifier(initialMultiServerState),
        ),
        // Override active server config (derived from multiServerConfigProvider)
        // No need to override activeServerConfigProvider directly if multiServerConfigProvider is mocked correctly

        // Ensure UI providers start in a known state
        ui_providers.memoMultiSelectModeProvider.overrideWith((ref) => false),
        ui_providers.selectedMemoIdsForMultiSelectProvider.overrideWith(
          (ref) => {},
        ),
        ui_providers.selectedMemoIdProvider.overrideWith((ref) => null),
        // Explicitly set the filter preset for consistent AppBar title
        quickFilterPresetProvider.overrideWith(
          (ref) => 'inbox',
        ), // Start with 'inbox'
      ],
    );

    // Ensure preferences are loaded (needed for filter preset)
    await container.read(loadFilterPreferencesProvider.future);
  });

  // Use tearDown to dispose the container after each test
  tearDown(() {
    container.dispose();
  });

  // Test 1: Standard UI
  testWidgets('MemosScreen displays standard UI elements initially', (
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const MemosScreen(), container),
    );
    await tester.pumpAndSettle(); // Wait for initial build and preference load

    // Act & Assert
    // Verify NavigationBar
    expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    // Verify Title (based on initial 'inbox' preset)
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('Inbox'), // Check for 'Inbox' title
      ),
      findsOneWidget,
    );
    // Verify Server Switcher button
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

    // Verify Trailing Buttons
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

    // Verify Search Bar
    expect(find.byType(CupertinoSearchTextField), findsOneWidget);

    // Verify Quick Filter Control
    expect(
      find.byType(CupertinoSlidingSegmentedControl<String>),
      findsOneWidget,
    );
    expect(find.text('Inbox'), findsWidgets); // Segment label
    expect(find.text('Today'), findsWidgets); // Segment label
    expect(find.text('Tagged'), findsWidgets); // Segment label
    expect(find.text('All'), findsWidgets); // Segment label

    // Verify Memo List Items (now within MemosBody)
    // Verify Memo List Items (now within MemosBody)
    // Check if MemosBody exists, which contains the list
    expect(find.byType(MemosBody), findsOneWidget);
    // We can still check for MemoListItem *within* MemosBody if needed,
    // but verifying MemosBody itself is often sufficient at this level.
    // expect(find.byType(MemoListItem), findsNWidgets(dummyMemos.length));

    // Verify multi-select actions are NOT present
    expect(
      find.widgetWithIcon(CupertinoButton, CupertinoIcons.clear),
      findsNothing, // Cancel button should not be present
    );
    expect(find.textContaining('Selected'), findsNothing); // Multi-select title

    // Verify standard trailing buttons ARE present within the NavBar (using the existing navBarFinder)
    expect(
      find.descendant(
        of: navBarFinder, // Use the navBarFinder defined earlier in the test
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
        of: navBarFinder, // Use the navBarFinder defined earlier in the test
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
        of: navBarFinder, // Use the navBarFinder defined earlier in the test
        matching: find.widgetWithIcon(CupertinoButton, CupertinoIcons.add),
      ),
      findsOneWidget,
      reason: 'Add memo button should be present',
    );
    // Verify no Checkboxes/Switches are present within list items
    expect(
      find.descendant(
        of: find.byType(MemoListItem),
        matching: find.byType(CupertinoSwitch),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(MemoListItem),
        matching: find.byType(CupertinoCheckbox),
      ),
      findsNothing,
    );

    // Verify Slidable IS present in normal mode
    expect(
      find.descendant(
        of: find.byType(MemoListItem),
        matching: find.byType(Slidable),
      ),
      findsNWidgets(dummyMemos.length), // Expect Slidable for each item
    );
  });

  // Test 2: Enter Multi-Select Mode
  testWidgets('MemosScreen enters multi-select mode on button tap', (
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const MemosScreen(), container),
    );
    await tester.pumpAndSettle();

    // Act: Find and tap the "Select" button (checkmark_seal)
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
    expect(container.read(ui_providers.memoMultiSelectModeProvider), isTrue);

    // Verify NavigationBar changes
    expect(
      find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.clear,
      ), // Cancel button
      findsOneWidget,
    );
    expect(find.text('0 Selected'), findsOneWidget); // Title
    expect(
      find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.delete,
      ), // Delete action
      findsOneWidget,
    );
    expect(
      find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.archivebox,
      ), // Archive action
      findsOneWidget,
    );
    // Verify standard title and trailing buttons are gone
    expect(find.text('Inbox'), findsNothing); // Original title
    expect(
      find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.checkmark_seal,
      ), // Select button
      findsNothing,
    );
    expect(
      find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.tuningfork,
      ), // Advanced filter button
      findsNothing,
    );
    expect(
      find.widgetWithIcon(CupertinoButton, CupertinoIcons.add), // Add button
      findsNothing,
    );
    // Verify Search Bar and Filter Control are hidden
    expect(find.byType(CupertinoSearchTextField), findsNothing);
    expect(find.byType(CupertinoSlidingSegmentedControl<String>), findsNothing);

    // Verify Checkboxes appear in list items
    final checkboxFinder = find.descendant(
      of: find.byType(MemoListItem),
      matching: find.byType(CupertinoCheckbox),
    );
    expect(checkboxFinder, findsNWidgets(dummyMemos.length));
  });

  // Test 3: Select/Deselect Item
  testWidgets('MemosScreen selects/deselects memo via Checkbox tap', (
    WidgetTester tester,
  ) async {
    // Arrange: Enter multi-select mode
    await tester.pumpWidget(
      buildTestableWidget(const MemosScreen(), container),
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
    final firstItemFinder = find.byType(MemoListItem).first;
    final firstCheckboxFinder = find.descendant(
      of: firstItemFinder,
      matching: find.byType(CupertinoCheckbox),
    );
    expect(firstCheckboxFinder, findsOneWidget);
    await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();

    // Assert: Item selected
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      contains(dummyMemos[0].id),
    );
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider).length,
      1,
    );
    expect(find.text('1 Selected'), findsOneWidget); // Title updates

    // Act: Tap the first checkbox again
    await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();

    // Assert: Item deselected
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      isEmpty,
    );
    expect(find.text('0 Selected'), findsOneWidget); // Title updates
  });

  // Test 4: Exit Multi-Select Mode
  testWidgets('MemosScreen exits multi-select mode via Cancel button', (
    WidgetTester tester,
  ) async {
    // Arrange: Enter multi-select mode and select an item
    await tester.pumpWidget(
      buildTestableWidget(const MemosScreen(), container),
    );
    await tester.pumpAndSettle();
    container.read(ui_providers.toggleMemoMultiSelectModeProvider)();
    await tester.pumpAndSettle();
    final firstItemFinder = find.byType(MemoListItem).first;
    final firstCheckboxFinder = find.descendant(
      of: firstItemFinder,
      matching: find.byType(CupertinoCheckbox),
    );
    await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();
    expect(container.read(ui_providers.memoMultiSelectModeProvider), isTrue);
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      isNotEmpty,
    );

    // Act: Tap the Cancel button (clear icon)
    final navBarFinder = find.byType(CupertinoNavigationBar);
    final cancelButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(CupertinoButton, CupertinoIcons.clear),
    );
    expect(cancelButtonFinder, findsOneWidget);
    await tester.tap(cancelButtonFinder);
    await tester.pumpAndSettle();

    // Assert: Exited multi-select mode
    expect(container.read(ui_providers.memoMultiSelectModeProvider), isFalse);
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      isEmpty, // Selection cleared
    );

    // Verify NavigationBar reverts - Use the existing navBarFinder
    expect(
      find.descendant(
        of: navBarFinder,
        matching: find.text('Inbox'), // Find title within NavBar
      ),
      findsOneWidget,
      reason: 'Title should revert to preset label',
    );
    expect(
      find.descendant(
        // Check within NavBar
        of: navBarFinder,
        matching: find.widgetWithIcon(
          CupertinoButton,
          CupertinoIcons.checkmark_seal,
        ),
      ), // Select button back
      findsOneWidget,
    );
    expect(
      find.descendant(
        // Check within NavBar
        of: navBarFinder,
        matching: find.widgetWithIcon(CupertinoButton, CupertinoIcons.clear,
        ),
      ), // Cancel button gone
      findsNothing,
    );
    expect(
      find.descendant(
        // Check within NavBar
        of: navBarFinder,
        matching: find.textContaining('Selected'),
      ),
      findsNothing,
    ); // Multi-select title gone

    // Verify Search Bar and Filter Control are visible again
    expect(find.byType(CupertinoSearchTextField), findsOneWidget);

    // Verify Search Bar and Filter Control are visible again
    expect(find.byType(CupertinoSearchTextField), findsOneWidget);
    expect(
      find.byType(CupertinoSlidingSegmentedControl<String>),
      findsOneWidget,
    );

    // Verify Checkboxes are gone
    expect(
      find.descendant(
        of: find.byType(MemoListItem),
        matching: find.byType(CupertinoCheckbox),
      ),
      findsNothing,
    );
  });

  // Test 5: Server Switcher
  testWidgets('MemosScreen displays server switcher and opens action sheet', (
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const MemosScreen(), container),
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
    ); // Initial server

    await tester.tap(serverSwitcherButtonFinder);
    await tester.pumpAndSettle(); // Allow action sheet animation

    // Assert: Action sheet appears
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    expect(find.text('Switch Active Server'), findsOneWidget); // Title
    expect(find.text('Mock Server 1'), findsWidgets); // Option 1
    expect(find.text('Mock Server 2'), findsWidgets); // Option 2
    expect(find.text('Cancel'), findsOneWidget); // Cancel button
  });

  // Test 6: Quick Filter Control Interaction
  testWidgets('MemosScreen updates filter preset via segmented control', (
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const MemosScreen(), container),
    );
    await tester.pumpAndSettle();
    expect(container.read(quickFilterPresetProvider), 'inbox'); // Initial state

    // Verify Initial Title specifically within NavBar
    final navBarFinder = find.byType(
      CupertinoNavigationBar,
    ); // Define navBarFinder here
    expect(
      find.descendant(
        of: navBarFinder,
        matching: find.text('Inbox'), // Find title within NavBar
      ),
      findsOneWidget,
      reason: 'Initial title should be Inbox',
    );

    // Act: Tap the 'Today' segment
    // Finding specific segments can be tricky. We'll find the text within the control.
    final todaySegmentFinder = find.descendant(
      of: find.byType(CupertinoSlidingSegmentedControl<String>),
      matching: find.text('Today'),
    );
    expect(todaySegmentFinder, findsOneWidget);
    await tester.tap(todaySegmentFinder);
    await tester.pumpAndSettle();

    // Assert: Provider updated and title changed
    expect(container.read(quickFilterPresetProvider), 'today');
    // Verify Title specifically within NavBar
    expect(
      find.descendant(
        of: navBarFinder, // Use the same finder from above
        matching: find.text('Today'), // Find title within NavBar
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
    // Verify Title specifically within NavBar
    expect(
      find.descendant(
        of: navBarFinder, // Use the same finder from above
        matching: find.text('All'), // Find title within NavBar
      ),
      findsOneWidget,
      reason: 'Title should update to All',
    );
  });

  // Test 7: Open Advanced Filter Panel
  testWidgets('MemosScreen opens AdvancedFilterPanel on tuning fork tap', (
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      buildTestableWidget(const MemosScreen(), container),
    );
    await tester.pumpAndSettle();

    // Act: Tap the advanced filter button (tuningfork)
    final navBarFinder = find.byType(CupertinoNavigationBar);
    final advancedFilterButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(CupertinoButton, CupertinoIcons.tuningfork),
    );
    expect(advancedFilterButtonFinder, findsOneWidget);
    await tester.tap(advancedFilterButtonFinder);
    await tester.pumpAndSettle(); // Allow modal animation

    // Assert: AdvancedFilterPanel is displayed
    // Finding modal popups can require looking for content within them.
    expect(find.byType(AdvancedFilterPanel), findsOneWidget);
    expect(find.text('Advanced Filter'), findsOneWidget); // Panel title
  });
}
