import 'package:flutter/cupertino.dart'; // Import Cupertino
// Remove unused Icons import
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/multi_server_config_state.dart'; // Import MultiServerConfigState
import 'package:flutter_memos/models/server_config.dart'; // Import ServerConfig
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/screens/memos/memo_list_item.dart';
import 'package:flutter_memos/screens/memos/memos_screen.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Keep if Slidable is used
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart'; // Import Uuid

import 'memos_screen_test.mocks.dart';

// Generate nice mock for ApiService
@GenerateNiceMocks([MockSpec<ApiService>()])

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

// Mock Notifier for MultiServerConfigState
class MockMultiServerConfigNotifier
    extends StateNotifier<MultiServerConfigState> {
  MockMultiServerConfigNotifier(super.initialState);

  // Override methods if needed for testing interactions, otherwise keep simple
  @override
  Future<void> loadFromPreferences() async {}

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

  // Add other methods as needed for tests
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
      },
    ),
  );
}

void main() {
  final dummyMemos = createDummyMemos(3); // Create 3 dummy memos for testing
  late ProviderContainer container; // Declare container
  late MockApiService mockApiService; // Declare the mock API service
  late ServerConfig mockServer1;
  late ServerConfig mockServer2;

  // Use setUp to create the container before each test
  setUp(() {
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
        tags: anyNamed('tags'),
        visibility: anyNamed('visibility'),
        contentSearch: anyNamed('contentSearch'),
        createdAfter: anyNamed('createdAfter'),
        createdBefore: anyNamed('createdBefore'),
        updatedAfter: anyNamed('updatedAfter'),
        updatedBefore: anyNamed('updatedBefore'),
        timeExpression: anyNamed('timeExpression'),
        useUpdateTimeForExpression: anyNamed('useUpdateTimeForExpression'),
      ),
    ).thenAnswer(
      (_) async => PaginatedMemoResponse(
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
        apiServiceProvider.overrideWithValue(mockApiService),
        // Override the actual notifier with our mock builder
        memosNotifierProvider.overrideWith(
          (ref) => MockMemosNotifier(ref, initialMemoState),
        ),
        // Override multi-server config state
        multiServerConfigProvider.overrideWith(
          (ref) => MockMultiServerConfigNotifier(initialMultiServerState),
        ),
        // Override active server config (derived from multiServerConfigProvider)
        // No need to override activeServerConfigProvider directly if multiServerConfigProvider is mocked correctly

        // Ensure UI providers start in a known state
        ui_providers.memoMultiSelectModeProvider.overrideWith((ref) => false),
        ui_providers.selectedMemoIdsForMultiSelectProvider.overrideWith((ref) => {}),
        ui_providers.selectedMemoIdProvider.overrideWith((ref) => null),
        // Explicitly set the filter key for consistent AppBar title
        filterKeyProvider.overrideWith((ref) => 'all'),
      ],
    );
  });

  // Use tearDown to dispose the container after each test
  tearDown(() {
    container.dispose();
  });

  testWidgets(
    'MemosScreen displays standard CupertinoNavigationBar and no checkboxes initially',
    (WidgetTester tester) async {
      testWidgets(
        'MemosScreen displays standard CupertinoNavigationBar and server switcher initially',
        (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemosScreen(), container));
    await tester.pumpAndSettle(); // Wait for initial build

    // Act & Assert
          expect(
            find.byType(CupertinoNavigationBar),
            findsOneWidget,
          ); // Check for CupertinoNavigationBar
    expect(
      find.descendant(
          of: find.byType(CupertinoNavigationBar),
          matching: find.text('Memos (ALL)'), // Check middle title
      ),
      findsOneWidget,
    );

          // Verify Server Switcher button exists in leading
          final navBarFinder = find.byType(CupertinoNavigationBar);
          final serverSwitcherButtonFinder = find.descendant(
            of: navBarFinder,
            matching: find.widgetWithIcon(
              CupertinoButton,
              CupertinoIcons.square_stack_3d_down_right,
            ),
          );
          expect(
            serverSwitcherButtonFinder,
            findsOneWidget,
            reason:
                "Could not find the server switcher button in NavigationBar leading",
          );
          // Verify server name is displayed (using the mocked active server)
          expect(
            find.textContaining('Mock Server 1'),
            findsOneWidget,
          ); // Check for active server name

          // Verify "Select" button exists in trailing
          final trailingButtonFinder = find.descendant(
            of: navBarFinder,
            matching: find.widgetWithIcon(
              CupertinoButton,
              CupertinoIcons.checkmark_seal,
            ),
          );
          expect(
            trailingButtonFinder,
            findsOneWidget,
            reason:
                "Could not find the Select/Multi-select toggle button (tried checkmark_seal icon) in NavigationBar trailing",
          );

    // Verify multi-select actions are NOT present
          expect(
            find.widgetWithIcon(
              CupertinoButton,
              CupertinoIcons.clear,
            ), // Cancel button (was xmark)
            findsNothing,
          );
    expect(find.textContaining('Selected'), findsNothing); // "X Selected" text
          expect(
            find.widgetWithIcon(
              CupertinoButton,
              CupertinoIcons.delete,
            ), // Delete action
            findsNothing,
          );
          expect(
            find.widgetWithIcon(
              CupertinoButton,
              CupertinoIcons.archivebox,
            ), // Archive action
            findsNothing,
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

          // Verify Slidable/Dismissible are NOT present (replaced by context menu/multi-select)
    expect(find.descendant(of: find.byType(MemoListItem), matching: find.byType(Slidable)), findsNothing);
  });

  testWidgets('MemosScreen enters multi-select mode on button tap', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemosScreen(), container));
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
    expect(
      selectButtonFinder,
      findsOneWidget,
      reason:
          "Could not find the Select/Multi-select toggle button (tried checkmark_seal icon) to tap",
    );
    await tester.ensureVisible(selectButtonFinder); // Ensure it's visible
    await tester.pumpAndSettle(); // Wait for scroll/animations
    await tester.tap(selectButtonFinder);
    await tester.pumpAndSettle();

        // Assert
    expect(container.read(ui_providers.memoMultiSelectModeProvider), isTrue);

    // Verify NavigationBar changes
    expect(
          find.widgetWithIcon(
            CupertinoButton,
            CupertinoIcons.clear,
          ), // Cancel button (was xmark)
      findsOneWidget,
        );
    expect(find.text('0 Selected'), findsOneWidget); // Initial count
    expect(
      find.widgetWithIcon(CupertinoButton, CupertinoIcons.delete),
      findsOneWidget,
    ); // Delete action
    expect(
      find.widgetWithIcon(CupertinoButton, CupertinoIcons.archivebox),
      findsOneWidget,
    ); // Archive action

    // Verify standard title and select button are gone from NavigationBar
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar), // Check within Nav Bar
        matching: find.text('Memos (ALL)'),
      ),
      findsNothing,
    );
    // Check that the trailing button is no longer the "Select" icon button
    final selectButtonFinderAfterModeChange = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.checkmark_seal,
      ),
    );
    expect(
      selectButtonFinderAfterModeChange,
      findsNothing,
      reason:
          "Select/Multi-select toggle button (checkmark_seal icon) should not be present in multi-select mode's trailing slot",
    );

        // Check that the Cancel (clear) button IS present in the leading slot
    final cancelButtonFinder = find.descendant(
      of: navBarFinder,
          matching: find.widgetWithIcon(
            CupertinoButton,
            CupertinoIcons.clear,
          ), // Use clear icon
    );
    expect(
      cancelButtonFinder,
      findsOneWidget,
      reason:
              "Cancel (clear) button should be present in multi-select mode's leading slot",
    );

    // Verify Checkboxes appear for each item
    final multiSelectWidgetFinder = find.descendant(
      of: find.byType(MemoListItem),
      matching: find.byType(CupertinoCheckbox), // Use CupertinoCheckbox
    );
    expect(multiSelectWidgetFinder, findsNWidgets(dummyMemos.length));

    // Verify Slidable/Dismissible are gone
    expect(find.descendant(of: find.byType(MemoListItem), matching: find.byType(Slidable)), findsNothing);
  });

      testWidgets('MemosScreen selects/deselects memo via Checkbox tap', (
    WidgetTester tester,
  ) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemosScreen(), container));
    await tester.pumpAndSettle();
    // Enter multi-select mode by tapping the "Select" icon button
    final navBarFinder = find.byType(CupertinoNavigationBar);
    final selectButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.checkmark_seal,
      ),
    );
    expect(
      selectButtonFinder,
      findsOneWidget,
      reason:
          "Could not find the Select/Multi-select toggle button (tried checkmark_seal icon) to tap",
    );
    await tester.ensureVisible(selectButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(selectButtonFinder);
    await tester.pumpAndSettle();

    // Find the first multi-select widget (CupertinoCheckbox)
    final firstItemFinder = find.byType(MemoListItem).first;
    final firstMultiSelectWidgetFinder = find.descendant(
      of: firstItemFinder,
      matching: find.byType(CupertinoCheckbox), // Use CupertinoCheckbox
    );
    expect(firstMultiSelectWidgetFinder, findsOneWidget); // Ensure it's found

    // Act: Tap the first checkbox to select
    await tester.tap(firstMultiSelectWidgetFinder);
    await tester.pumpAndSettle();

        // Assert: Selection state updated
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      contains(dummyMemos[0].id),
    );
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider).length,
      1,
    );
    expect(find.text('1 Selected'), findsOneWidget);

    // Act: Tap the first widget again to deselect
    await tester.tap(firstMultiSelectWidgetFinder);
    await tester.pumpAndSettle();

        // Assert: Selection state updated
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      isEmpty,
    );
    expect(find.text('0 Selected'), findsOneWidget);
  });
      expect(find.text('0 Selected'), findsOneWidget);
    },
  );

  testWidgets('MemosScreen exits multi-select mode via Cancel button', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(buildTestableWidget(const MemosScreen(), container));
    await tester.pumpAndSettle();

    // Enter multi-select mode
    container.read(ui_providers.toggleMemoMultiSelectModeProvider)();
    await tester.pumpAndSettle(); // Allow UI to rebuild

    // Tap the checkbox within the first item to select it
    final firstItemFinder = find.byType(MemoListItem).first;
    final firstCheckboxFinder = find.descendant(
      of: firstItemFinder,
      matching: find.byType(CupertinoCheckbox),
    );
    expect(firstCheckboxFinder, findsOneWidget);
    await tester.tap(firstCheckboxFinder);
    await tester.pumpAndSettle();

    expect(
      container.read(ui_providers.memoMultiSelectModeProvider),
      isTrue,
      reason: "Should be in multi-select mode initially",
    );
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      isNotEmpty,
      reason: "An item should be selected",
    );

    // Act: Tap the Cancel button (leading button in multi-select nav bar)
    final navBarFinder = find.byType(CupertinoNavigationBar);
    final cancelButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.clear,
      ), // Use clear icon
    );
    expect(
      cancelButtonFinder,
      findsOneWidget,
      reason: "Could not find Cancel button to tap",
    );
    await tester.tap(cancelButtonFinder);
    await tester.pumpAndSettle();

    // Assert: Exited multi-select mode
    expect(
      container.read(ui_providers.memoMultiSelectModeProvider),
      isFalse,
      reason: "Failed to exit multi-select mode via Cancel button",
    );
    expect(
      container.read(ui_providers.selectedMemoIdsForMultiSelectProvider),
      isEmpty,
      reason: "Selection should be cleared on exit"
    );

    // Verify NavigationBar reverts
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('Memos (ALL)'),
      ),
      findsOneWidget,
    );
    // Verify the "Select" icon button is back in the trailing slot
    final selectButtonFinder = find.descendant(
      of: navBarFinder,
      matching: find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.checkmark_seal,
      ),
    );
    expect(
      selectButtonFinder,
      findsOneWidget,
      reason:
          "Select/Multi-select toggle button (checkmark_seal icon) should reappear after exiting multi-select",
    );
    // Verify the Cancel (clear) button is gone
    expect(
      find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.clear,
      ), // Use clear icon
      findsNothing,
    ); // Cancel button should be gone

    expect(find.textContaining('Selected'), findsNothing);

    // Verify Checkboxes/Switches are gone
    expect(
      find.descendant(
        of: find.byType(MemoListItem),
        matching: find.byType(CupertinoCheckbox), // Check Checkbox
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(MemoListItem),
        matching: find.byType(CupertinoSwitch), // Also check Switch
      ),
      findsNothing,
    );

    // Verify Slidable/Dismissible are NOT back (assuming they were replaced)
    expect(find.descendant(of: find.byType(MemoListItem), matching: find.byType(Slidable)), findsNothing);
  });

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
    expect(
      serverSwitcherButtonFinder,
      findsOneWidget,
      reason: "Could not find the server switcher button",
    );
    expect(
      find.textContaining('Mock Server 1'),
      findsOneWidget,
    ); // Verify initial active server name

    await tester.tap(serverSwitcherButtonFinder);
    await tester.pumpAndSettle(); // Allow action sheet animation

    // Assert: Action sheet appears with server options
    // Finding action sheets can be tricky, look for characteristic widgets/text
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    expect(find.text('Switch Active Server'), findsOneWidget); // Title
    expect(
      find.text('Mock Server 1'),
      findsWidgets,
    ); // Option 1 (might find multiple if name is in button too)
    expect(find.text('Mock Server 2'), findsWidgets); // Option 2
    expect(find.text('Cancel'), findsOneWidget); // Cancel button

    // Optional: Tap an option and verify state change (requires mocking notifier interaction)
    // await tester.tap(find.text('Mock Server 2').last); // Tap the action sheet option
    // await tester.pumpAndSettle();
    // expect(container.read(activeServerConfigProvider)?.id, mockServer2.id); // Verify active server changed
  });
}
