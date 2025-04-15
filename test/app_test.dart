import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Keep for ThemeMode
import 'package:flutter_memos/main.dart';
import 'package:flutter_memos/models/list_notes_response.dart'; // Updated import
import 'package:flutter_memos/models/multi_server_config_state.dart';
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/api_providers.dart' as providers;
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/theme_provider.dart';
import 'package:flutter_memos/services/base_api_service.dart'; // Updated import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart'; // Import for platform interface

// Generate nice mock for BaseApiService
@GenerateNiceMocks([MockSpec<BaseApiService>()])
import 'app_test.mocks.dart';

// Mock Notifier
class MockMultiServerConfigNotifier
    extends StateNotifier<MultiServerConfigState>
    implements MultiServerConfigNotifier {
  MockMultiServerConfigNotifier(super.initialState);

  @override
  Future<void> loadConfiguration() async {
    return Future.value();
  }

  @override
  Future<bool> addServer(ServerConfig config) async {
    return Future.value(true);
  }

  @override
  Future<bool> removeServer(String serverId) async {
    return Future.value(true);
  }

  @override
  void setActiveServer(String? serverId) {
    // Mock implementation
  }

  @override
  Future<bool> setDefaultServer(String? serverId) async {
    return Future.value(true);
  }

  @override
  Future<bool> updateServer(ServerConfig updatedConfig) async {
    return Future.value(true);
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
  TestWidgetsFlutterBinding.ensureInitialized(); // Add this line
  late MockBaseApiService mockApiService; // Updated mock type
  late List<NoteItem> testNotes; // Updated type

  setUp(() async {
    // Clear shared preferences at setup
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_config_cache');
    await prefs.remove('defaultServerId');
    
    mockApiService = MockBaseApiService(); // Updated mock type

    when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');

    SharedPreferences.setMockInitialValues({});

    // Create test notes
    testNotes = [
      // Updated type
      NoteItem(
        // Updated type
        id: 'note-1', // Updated prefix
        content: 'First test note', // Updated content
        createTime: DateTime.now().subtract(const Duration(days: 1)),
        updateTime: DateTime.now(),
        displayTime: DateTime.now(), // Add required field
        visibility: NoteVisibility.private, // Add required field
        state: NoteState.normal, // Add required field
        pinned: false, // Already present
      ),
      NoteItem(
        // Updated type
        id: 'note-2', // Updated prefix
        content: 'Second test note', // Updated content
        createTime: DateTime.now().subtract(const Duration(days: 2)),
        updateTime: DateTime.now().subtract(const Duration(hours: 1)),
        displayTime: DateTime.now().subtract(
          const Duration(hours: 1),
        ), // Add required field
        visibility: NoteVisibility.private, // Add required field
        state: NoteState.normal, // Add required field
        pinned: false, // Already present
      ),
    ];

    // Stub listNotes for initial app load
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
      (_) async => ListNotesResponse(
        notes: testNotes,
        nextPageToken: null,
      ), // Updated response type
    );
  });

  testWidgets('App loads and displays title', (WidgetTester tester) async {
    // Mock SharedPreferences platform channel
    TestWidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();

    // Define initial states for mocks
    final initialMultiServerState = MultiServerConfigState(
      servers: [
        ServerConfig(
          id: 'mock-id',
          name: 'Mock Server',
          serverUrl: 'http://mock.test',
          authToken: 'mock-token',
          serverType: ServerType.memos, // Added serverType
        ),
      ],
      activeServerId: 'mock-id',
      defaultServerId: 'mock-id',
    );
    final initialThemeMode = ThemeMode.dark;

    // Build our app and trigger a frame
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providers.apiServiceProvider.overrideWithValue(mockApiService),
          multiServerConfigProvider.overrideWith(
            (_) => MockMultiServerConfigNotifier(initialMultiServerState),
          ),
          themeModeProvider.overrideWith((ref) => initialThemeMode),
          loadServerConfigProvider.overrideWith((ref) => Future.value()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify Cupertino widgets
    expect(find.byType(CupertinoPageScaffold), findsWidgets);

    await tester.pumpAndSettle();

    // Verify CupertinoNavigationBar exists
    expect(find.byType(CupertinoNavigationBar), findsWidgets);
    // Optionally check for a specific title if one is expected initially
    // expect(find.text('Inbox'), findsOneWidget); // Example if 'Inbox' is default
  });
}
