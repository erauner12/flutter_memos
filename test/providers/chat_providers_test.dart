import 'package:flutter_memos/models/chat_message.dart';
import 'package:flutter_memos/models/chat_session.dart';
import 'package:flutter_memos/models/mcp_server_config.dart'; // Needed for McpClientState setup
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/chat_providers.dart'; // Import ChatNotifier and provider
// Import necessary symbols from settings_provider
import 'package:flutter_memos/providers/settings_provider.dart'
    show
        PersistentStringNotifier,
        geminiApiKeyProvider,
        PreferenceKeys; // Import the class containing the keys
import 'package:flutter_memos/services/chat_session_cloud_kit_service.dart';
import 'package:flutter_memos/services/local_storage_service.dart';
// Explicitly import necessary symbols AND the provider from the service file.
import 'package:flutter_memos/services/mcp_client_service.dart'
    show // Import only what's needed + the provider
        McpClientNotifier, // Keep the real notifier for extension
        McpClientState,
        McpConnectionStatus,
        McpProcessResult,
        // Keep if needed by McpClientState mock or other parts
        mcpClientProvider; // Import the actual provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mocks for dependencies
@GenerateNiceMocks([
  MockSpec<McpClientNotifier>(), // Keep this for the delegate
  MockSpec<McpClientState>(),
  // MockSpec<GeminiService>(), // GeminiService is internal to ChatNotifier now
  MockSpec<LocalStorageService>(), // ADDED
  MockSpec<ChatSessionCloudKitService>(), // ADDED
  MockSpec<gen_ai.GenerativeModel>(), // Mock the AI model itself
  MockSpec<gen_ai.ChatSession>(), // Mock the AI chat session
  MockSpec<gen_ai.GenerateContentResponse>(), // Mock the AI response
])
import 'chat_providers_test.mocks.dart';

// Mock for PersistentStringNotifier (Keep as is)
class MockPersistentStringNotifier extends StateNotifier<String>
    implements PersistentStringNotifier {
  final String key;
  MockPersistentStringNotifier(this.key, String initialState)
    : super(initialState);
  @override
  Future<void> init() async {}
  @override
  Future<bool> set(String value) async {
    state = value;
    return true;
  }

  @override
  Future<bool> clear() async {
    state = '';
    return true;
  }

  @override
  String get preferenceKey => key;
  @override
  set debugSecureStorage(dynamic storage) {}
}

// --- Fake McpClientNotifier --- (Keep as is)
class FakeMcpClientNotifier extends McpClientNotifier {
  final MockMcpClientNotifier mockDelegate;
  FakeMcpClientNotifier(
    super.ref,
    McpClientState initialState,
    this.mockDelegate,
  ) {
    state = initialState;
  }
  @override
  Future<McpProcessResult> processQuery(
    String query,
    List<gen_ai.Content> history,
  ) {
    return mockDelegate.processQuery(query, history);
  }
  @override
  void initialize() {}
  @override
  Future<void> connectServer(McpServerConfig serverConfig) async {
    return Future.value();
  }
  @override
  Future<void> disconnectServer(String serverId) async {
    return Future.value();
  }
  @override
  void syncConnections() {}
  @override
  void rebuildToolMap() {}
}
// --- End Fake McpClientNotifier ---

// Helper to create GenerateContentResponse (Keep as is)
gen_ai.GenerateContentResponse generateContentResponse({String? text}) {
  return gen_ai.GenerateContentResponse(
    [
    gen_ai.Candidate(
      gen_ai.Content('model', [if (text != null) gen_ai.TextPart(text)]),
      null,
      null,
      gen_ai.FinishReason.stop,
      null,
      )
    ],
    null,
  );
}

void main() {
  // Mocks
  late MockMcpClientNotifier mockMcpClientNotifierDelegate;
  late MockLocalStorageService mockLocalStorageService; // ADDED
  late MockChatSessionCloudKitService mockCloudKitService; // ADDED
  late MockGenerativeModel mockGenerativeModel; // ADDED
  late MockChatSession mockAiChatSession; // ADDED
  late MockGenerateContentResponse mockAiResponse; // ADDED
  late ProviderContainer container;

  // Default mock states/values
  final defaultStdioMcpConfig = const McpServerConfig(
    id: 'test-stdio-id',
    name: 'Test Stdio Server',
    connectionType: McpConnectionType.stdio,
    command: 'test',
    args: '',
    isActive: true,
  );

  final defaultStdioMcpState = McpClientState(
    serverConfigs: [defaultStdioMcpConfig],
    serverStatuses: {'test-stdio-id': McpConnectionStatus.connected},
    activeClients: {},
    serverErrorMessages: {},
  );

  final disconnectedMcpState = McpClientState(
    serverConfigs: [defaultStdioMcpConfig],
    serverStatuses: {'test-stdio-id': McpConnectionStatus.disconnected},
    activeClients: {},
    serverErrorMessages: {},
  );

  // Test Chat Sessions
  final now = DateTime.now().toUtc();
  final localSession = ChatSession(
    id: ChatSession.activeSessionId,
    messages: [
      ChatMessage(
        id: 'local1',
        role: Role.user,
        text: 'local msg',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
    ],
    lastUpdated: now.subtract(const Duration(hours: 1)),
  );
  final cloudSession = ChatSession(
    id: ChatSession.activeSessionId,
    messages: [
      ChatMessage(
        id: 'cloud1',
        role: Role.user,
        text: 'cloud msg',
        timestamp: now,
      ),
    ],
    lastUpdated: now,
  );

  setUp(() async {
    // Initialize mocks
    mockMcpClientNotifierDelegate = MockMcpClientNotifier();
    mockLocalStorageService = MockLocalStorageService(); // ADDED
    mockCloudKitService = MockChatSessionCloudKitService(); // ADDED
    mockGenerativeModel = MockGenerativeModel(); // ADDED
    mockAiChatSession = MockChatSession(); // ADDED
    mockAiResponse = MockGenerateContentResponse(); // ADDED

    // Default stubbing for MCP delegate
    when(mockMcpClientNotifierDelegate.processQuery(any, any)).thenAnswer(
      (_) async => throw UnimplementedError('MCP processQuery not stubbed'),
    );

    // Default stubbing for storage/cloud (return null/empty)
    when(
      mockLocalStorageService.loadActiveChatSession(),
    ).thenAnswer((_) async => null);
    when(mockCloudKitService.getChatSession()).thenAnswer((_) async => null);
    when(mockLocalStorageService.saveActiveChatSession(any)).thenAnswer((
      _,
    ) async {
      return null;
    });
    when(
      mockCloudKitService.saveChatSession(any),
    ).thenAnswer((_) async => true);
    when(mockLocalStorageService.deleteActiveChatSession()).thenAnswer((
      _,
    ) async {
      return null;
    });
    when(mockCloudKitService.deleteChatSession()).thenAnswer((_) async => true);

    // Default stubbing for AI Model
    when(
      mockGenerativeModel.startChat(history: anyNamed('history')),
    ).thenReturn(mockAiChatSession);
    when(
      mockAiChatSession.sendMessage(any),
    ).thenAnswer((_) async => mockAiResponse);
    when(
      mockAiResponse.text,
    ).thenReturn('Mock AI response'); // Default simple text response

    // Create ProviderContainer with overrides
    container = ProviderContainer(
      overrides: [
        mcpClientProvider.overrideWith((ref) {
          final fakeMcpClientNotifier = FakeMcpClientNotifier(
            ref,
            defaultStdioMcpState, // Default to connected stdio state
            mockMcpClientNotifierDelegate,
          );
          return fakeMcpClientNotifier;
        }),
        localStorageServiceProvider.overrideWithValue(
          mockLocalStorageService,
        ), // ADDED
        chatSessionCloudKitServiceProvider.overrideWithValue(
          mockCloudKitService,
        ), // ADDED
        geminiApiKeyProvider.overrideWith(
          (_) => MockPersistentStringNotifier(
            PreferenceKeys.geminiApiKey,
            'fake-gemini-key', // Provide a key so the model initializes
          ),
        ),
        // We need a way to inject the mocked model into the notifier.
        // Since the notifier creates the model internally based on the API key,
        // we can't directly override a model provider.
        // For testing, we might need to refactor ChatNotifier slightly
        // OR accept that testing the AI interaction part might be harder here.
        // Let's proceed assuming the internal model creation works,
        // and focus on testing the logic *around* the AI call.
        // If we needed to test the AI call itself, we'd mock the google_generative_ai package
        // or refactor ChatNotifier to accept a GenerativeModel instance.
      ],
    );

    // IMPORTANT: Instantiate the notifier *after* setting up overrides
    // The notifier's constructor calls _loadInitialSession, which uses the mocks.
    final notifier = container.read(chatProvider.notifier);
    // Allow initial load to complete
    await Future.delayed(Duration.zero);
  });

  tearDown(() {
    container.dispose();
  });

  group('Initialization (_loadInitialSession)', () {
    test('loads initial empty state when no local or cloud data exists', () async {
      // Arrange (mocks already return null in setUp)

      // Act: Trigger notifier creation (done implicitly by reading in setUp or here)
      // Re-create container *without* default stubs to ensure clean state for this test
      container.dispose(); // Dispose previous container
      when(
        mockLocalStorageService.loadActiveChatSession(),
      ).thenAnswer((_) async => null);
      when(mockCloudKitService.getChatSession()).thenAnswer((_) async => null);
      container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            mockLocalStorageService,
          ),
          chatSessionCloudKitServiceProvider.overrideWithValue(
            mockCloudKitService,
          ),
          geminiApiKeyProvider.overrideWith(
            (_) => MockPersistentStringNotifier(
              PreferenceKeys.geminiApiKey,
              'fake-key',
            ),
          ),
          // mcpClientProvider override needed if accessed during init
          mcpClientProvider.overrideWith(
            (ref) => FakeMcpClientNotifier(
              ref,
              disconnectedMcpState,
              mockMcpClientNotifierDelegate,
            ),
          ),
        ],
      );
      // Read the notifier to trigger initialization
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(Duration.zero); // Allow async operations

      // Assert
      final state = container.read(chatProvider);
      expect(state.session.messages, isEmpty);
      expect(state.isInitializing, isFalse); // Should be false after load
      verify(mockLocalStorageService.loadActiveChatSession()).called(1);
      verify(mockCloudKitService.getChatSession()).called(1);
      verifyNever(mockLocalStorageService.saveActiveChatSession(any));
      verifyNever(mockCloudKitService.saveChatSession(any));
    });

    test(
      'loads from local when only local data exists and saves to cloud',
      () async {
        // Arrange
        container.dispose();
        when(
          mockLocalStorageService.loadActiveChatSession(),
        ).thenAnswer((_) async => localSession);
        when(
          mockCloudKitService.getChatSession(),
        ).thenAnswer((_) async => null);
        container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(
              mockLocalStorageService,
            ),
            chatSessionCloudKitServiceProvider.overrideWithValue(
              mockCloudKitService,
            ),
            geminiApiKeyProvider.overrideWith(
              (_) => MockPersistentStringNotifier(
                PreferenceKeys.geminiApiKey,
                'fake-key',
              ),
            ),
            mcpClientProvider.overrideWith(
              (ref) => FakeMcpClientNotifier(
                ref,
                disconnectedMcpState,
                mockMcpClientNotifierDelegate,
              ),
            ),
          ],
        );

        // Act
        final notifier = container.read(chatProvider.notifier);
        await Future.delayed(Duration.zero);

        // Assert
        final state = container.read(chatProvider);
        expect(state.session, localSession);
        expect(state.isInitializing, isFalse);
        verify(mockLocalStorageService.loadActiveChatSession()).called(1);
        verify(mockCloudKitService.getChatSession()).called(1);
        verify(
          mockCloudKitService.saveChatSession(localSession),
        ).called(1); // Should save local to cloud
        verifyNever(
          mockLocalStorageService.saveActiveChatSession(any),
        ); // No need to re-save locally
      },
    );

    test(
      'loads from cloud when only cloud data exists and saves to local',
      () async {
        // Arrange
        container.dispose();
        when(
          mockLocalStorageService.loadActiveChatSession(),
        ).thenAnswer((_) async => null);
        when(
          mockCloudKitService.getChatSession(),
        ).thenAnswer((_) async => cloudSession);
        container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(
              mockLocalStorageService,
            ),
            chatSessionCloudKitServiceProvider.overrideWithValue(
              mockCloudKitService,
            ),
            geminiApiKeyProvider.overrideWith(
              (_) => MockPersistentStringNotifier(
                PreferenceKeys.geminiApiKey,
                'fake-key',
              ),
            ),
            mcpClientProvider.overrideWith(
              (ref) => FakeMcpClientNotifier(
                ref,
                disconnectedMcpState,
                mockMcpClientNotifierDelegate,
              ),
            ),
          ],
        );

        // Act
        final notifier = container.read(chatProvider.notifier);
        await Future.delayed(Duration.zero);

        // Assert
        final state = container.read(chatProvider);
        expect(state.session, cloudSession);
        expect(state.isInitializing, isFalse);
        verify(mockLocalStorageService.loadActiveChatSession()).called(1);
        verify(mockCloudKitService.getChatSession()).called(1);
        verify(
          mockLocalStorageService.saveActiveChatSession(cloudSession),
        ).called(1); // Should save cloud to local
        verifyNever(
          mockCloudKitService.saveChatSession(any),
        ); // No need to re-save to cloud
      },
    );

    test('loads from local when local is newer', () async {
      // Arrange
      container.dispose();
      final newerLocalSession = localSession.copyWith(lastUpdated: now);
      final olderCloudSession = cloudSession.copyWith(
        lastUpdated: now.subtract(const Duration(hours: 1)),
      );
      when(
        mockLocalStorageService.loadActiveChatSession(),
      ).thenAnswer((_) async => newerLocalSession);
      when(
        mockCloudKitService.getChatSession(),
      ).thenAnswer((_) async => olderCloudSession);
      container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            mockLocalStorageService,
          ),
          chatSessionCloudKitServiceProvider.overrideWithValue(
            mockCloudKitService,
          ),
          geminiApiKeyProvider.overrideWith(
            (_) => MockPersistentStringNotifier(
              PreferenceKeys.geminiApiKey,
              'fake-key',
            ),
          ),
          mcpClientProvider.overrideWith(
            (ref) => FakeMcpClientNotifier(
              ref,
              disconnectedMcpState,
              mockMcpClientNotifierDelegate,
            ),
          ),
        ],
      );

      // Act
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(chatProvider);
      expect(state.session, newerLocalSession);
      expect(state.isInitializing, isFalse);
      verify(mockLocalStorageService.loadActiveChatSession()).called(1);
      verify(mockCloudKitService.getChatSession()).called(1);
      verifyNever(mockLocalStorageService.saveActiveChatSession(any));
      // verify(mockCloudKitService.saveChatSession(newerLocalSession)).called(1); // Optional: Verify newer local is pushed
    });

    test('loads from cloud when cloud is newer and updates local', () async {
      // Arrange
      container.dispose();
      final olderLocalSession = localSession.copyWith(
        lastUpdated: now.subtract(const Duration(hours: 1)),
      );
      final newerCloudSession = cloudSession.copyWith(lastUpdated: now);
      when(
        mockLocalStorageService.loadActiveChatSession(),
      ).thenAnswer((_) async => olderLocalSession);
      when(
        mockCloudKitService.getChatSession(),
      ).thenAnswer((_) async => newerCloudSession);
      container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            mockLocalStorageService,
          ),
          chatSessionCloudKitServiceProvider.overrideWithValue(
            mockCloudKitService,
          ),
          geminiApiKeyProvider.overrideWith(
            (_) => MockPersistentStringNotifier(
              PreferenceKeys.geminiApiKey,
              'fake-key',
            ),
          ),
          mcpClientProvider.overrideWith(
            (ref) => FakeMcpClientNotifier(
              ref,
              disconnectedMcpState,
              mockMcpClientNotifierDelegate,
            ),
          ),
        ],
      );

      // Act
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(chatProvider);
      expect(state.session, newerCloudSession);
      expect(state.isInitializing, isFalse);
      verify(mockLocalStorageService.loadActiveChatSession()).called(1);
      verify(mockCloudKitService.getChatSession()).called(1);
      verify(
        mockLocalStorageService.saveActiveChatSession(newerCloudSession),
      ).called(1); // Should update local
      verifyNever(mockCloudKitService.saveChatSession(any));
    });

    test('handles error during local load', () async {
      // Arrange
      container.dispose();
      final error = Exception('Local load failed');
      when(mockLocalStorageService.loadActiveChatSession()).thenThrow(error);
      when(
        mockCloudKitService.getChatSession(),
      ).thenAnswer((_) async => cloudSession); // Cloud works
      container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            mockLocalStorageService,
          ),
          chatSessionCloudKitServiceProvider.overrideWithValue(
            mockCloudKitService,
          ),
          geminiApiKeyProvider.overrideWith(
            (_) => MockPersistentStringNotifier(
              PreferenceKeys.geminiApiKey,
              'fake-key',
            ),
          ),
          mcpClientProvider.overrideWith(
            (ref) => FakeMcpClientNotifier(
              ref,
              disconnectedMcpState,
              mockMcpClientNotifierDelegate,
            ),
          ),
        ],
      );

      // Act
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(chatProvider);
      expect(state.session, cloudSession); // Should fall back to cloud
      expect(state.isInitializing, isFalse);
      verify(
        mockLocalStorageService.saveActiveChatSession(cloudSession),
      ).called(1); // Save cloud to local
    });

    test('handles error during cloud load', () async {
      // Arrange
      container.dispose();
      final error = Exception('Cloud load failed');
      when(
        mockLocalStorageService.loadActiveChatSession(),
      ).thenAnswer((_) async => localSession); // Local works
      when(mockCloudKitService.getChatSession()).thenThrow(error);
      container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            mockLocalStorageService,
          ),
          chatSessionCloudKitServiceProvider.overrideWithValue(
            mockCloudKitService,
          ),
          geminiApiKeyProvider.overrideWith(
            (_) => MockPersistentStringNotifier(
              PreferenceKeys.geminiApiKey,
              'fake-key',
            ),
          ),
          mcpClientProvider.overrideWith(
            (ref) => FakeMcpClientNotifier(
              ref,
              disconnectedMcpState,
              mockMcpClientNotifierDelegate,
            ),
          ),
        ],
      );

      // Act
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(chatProvider);
      expect(state.session, localSession); // Should fall back to local
      expect(state.isInitializing, isFalse);
      verify(
        mockCloudKitService.saveChatSession(localSession),
      ).called(1); // Save local to cloud
    });
  });

  group('forceFetchFromCloud', () {
    // Use the container created in the main setUp
    late ChatNotifier notifier;

    setUp(() async {
      // Ensure initial load is complete before each test in this group
      // Reset mocks to default (null) for load, then run notifier init
      container.dispose(); // Dispose previous container
      when(
        mockLocalStorageService.loadActiveChatSession(),
      ).thenAnswer((_) async => null);
      when(mockCloudKitService.getChatSession()).thenAnswer((_) async => null);
      container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            mockLocalStorageService,
          ),
          chatSessionCloudKitServiceProvider.overrideWithValue(
            mockCloudKitService,
          ),
          geminiApiKeyProvider.overrideWith(
            (_) => MockPersistentStringNotifier(
              PreferenceKeys.geminiApiKey,
              'fake-key',
            ),
          ),
          mcpClientProvider.overrideWith(
            (ref) => FakeMcpClientNotifier(
              ref,
              disconnectedMcpState,
              mockMcpClientNotifierDelegate,
            ),
          ),
        ],
      );
      notifier = container.read(chatProvider.notifier);
      await Future.delayed(Duration.zero); // Allow init load
      // Reset interaction counts after initial load
      clearInteractions(mockLocalStorageService);
      clearInteractions(mockCloudKitService);
    });

    test('updates state and local storage when cloud session exists', () async {
      // Arrange
      when(
        mockCloudKitService.getChatSession(),
      ).thenAnswer((_) async => cloudSession);
      final initialState = container.read(chatProvider);
      expect(initialState.session.messages, isEmpty); // Verify initial state

      // Act
      await notifier.forceFetchFromCloud();

      // Assert
      final state = container.read(chatProvider);
      expect(state.isSyncing, isFalse);
      expect(state.session, cloudSession);
      expect(state.errorMessage, isNull);
      verify(mockCloudKitService.getChatSession()).called(1);
      verify(
        mockLocalStorageService.saveActiveChatSession(cloudSession),
      ).called(1);
    });

    test(
      'sets error message and keeps local state when no cloud session found',
      () async {
        // Arrange
        // Start with some local state first
        container.dispose();
        when(
          mockLocalStorageService.loadActiveChatSession(),
        ).thenAnswer((_) async => localSession);
        when(
          mockCloudKitService.getChatSession(),
        ).thenAnswer((_) async => null); // Cloud returns null during init
        container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(
              mockLocalStorageService,
            ),
            chatSessionCloudKitServiceProvider.overrideWithValue(
              mockCloudKitService,
            ),
            geminiApiKeyProvider.overrideWith(
              (_) => MockPersistentStringNotifier(
                PreferenceKeys.geminiApiKey,
                'fake-key',
              ),
            ),
            mcpClientProvider.overrideWith(
              (ref) => FakeMcpClientNotifier(
                ref,
                disconnectedMcpState,
                mockMcpClientNotifierDelegate,
              ),
            ),
          ],
        );
        notifier = container.read(chatProvider.notifier);
        await Future.delayed(Duration.zero); // Allow init load
        clearInteractions(mockLocalStorageService);
        clearInteractions(mockCloudKitService); // Reset interactions

        // Now mock the force fetch call to return null
        when(
          mockCloudKitService.getChatSession(),
        ).thenAnswer((_) async => null);

        // Act
        await notifier.forceFetchFromCloud();

        // Assert
        final state = container.read(chatProvider);
        expect(state.isSyncing, isFalse);
        expect(state.session, localSession); // State should remain unchanged
        expect(state.errorMessage, "No chat session found in iCloud.");
        verify(mockCloudKitService.getChatSession()).called(1);
        verifyNever(
          mockLocalStorageService.saveActiveChatSession(any),
        ); // Should not save
      },
    );

    test('sets error message when cloud fetch throws an error', () async {
      // Arrange
      final exception = Exception('CloudKit fetch failed');
      when(mockCloudKitService.getChatSession()).thenThrow(exception);
      final initialSession =
          container.read(chatProvider).session; // Capture initial state

      // Act
      await notifier.forceFetchFromCloud();

      // Assert
      final state = container.read(chatProvider);
      expect(state.isSyncing, isFalse);
      expect(state.session, initialSession); // State should remain unchanged
      expect(state.errorMessage, "Failed to fetch from iCloud: $exception");
      verify(mockCloudKitService.getChatSession()).called(1);
      verifyNever(mockLocalStorageService.saveActiveChatSession(any));
    });

    test('sets isSyncing flag during fetch', () async {
      // Arrange
      final completer = Completer<ChatSession?>();
      when(
        mockCloudKitService.getChatSession(),
      ).thenAnswer((_) => completer.future);

      // Act: Start the fetch but don't complete it yet
      final fetchFuture = notifier.forceFetchFromCloud();

      // Assert: Check state immediately after calling
      final stateBeforeCompletion = container.read(chatProvider);
      expect(stateBeforeCompletion.isSyncing, isTrue);

      // Arrange: Complete the fetch
      completer.complete(cloudSession);
      await fetchFuture; // Wait for the method to finish

      // Assert: Check state after completion
      final stateAfterCompletion = container.read(chatProvider);
      expect(stateAfterCompletion.isSyncing, isFalse);
    });

    test('does not fetch if already syncing', () async {
      // Arrange
      final completer = Completer<ChatSession?>();
      when(
        mockCloudKitService.getChatSession(),
      ).thenAnswer((_) => completer.future);

      // Act: Start the first fetch
      final fetchFuture1 = notifier.forceFetchFromCloud();
      expect(container.read(chatProvider).isSyncing, isTrue);

      // Act: Try starting a second fetch while the first is running
      await notifier.forceFetchFromCloud();

      // Assert: CloudKit service should only be called once
      verify(mockCloudKitService.getChatSession()).called(1);

      // Cleanup: Complete the first fetch
      completer.complete(null);
      await fetchFuture1;
    });
  });

  // --- Existing sendMessage tests (minor adjustments if needed) ---
  group('sendMessage', () {
    // No changes needed here based on the latest updates,
    // as these tests focus on MCP vs Gemini logic, not storage/cloud interaction
    // during the send itself. The setUp already handles the necessary mocks.
    test(
      'uses MCP when active and updates history correctly', () async {
      // Arrange: Configure the *delegate* mock for this specific test
      const userQuery = 'create task buy milk';
      final fakeNotifier =
          container.read(mcpClientProvider.notifier) as FakeMcpClientNotifier;
      fakeNotifier.state = defaultStdioMcpState; // Ensure MCP is active
      expect(fakeNotifier.state.hasActiveConnections, isTrue);

      final mcpResult = McpProcessResult(
        modelCallContent: gen_ai.Content('model', [
          gen_ai.FunctionCall('create_todoist_task', {'content': 'buy milk'}),
        ]),
        toolResponseContent: gen_ai.Content('function', [
          gen_ai.FunctionResponse('create_todoist_task', {
            'status': 'success',
            'taskId': '12345',
          }),
        ]),
        finalModelContent: gen_ai.Content('model', [
          gen_ai.TextPart('OK. Task "buy milk" created (ID: 12345).'),
        ]),
        toolName: 'create_todoist_task',
        toolArgs: {'content': 'buy milk'},
        toolResult: '{"status":"success","taskId":"12345"}',
        sourceServerId: 'test-stdio-id',
      );
      when(
        mockMcpClientNotifierDelegate.processQuery(any, any),
      ).thenAnswer((_) async => mcpResult);

      // Act
      await container.read(chatProvider.notifier).sendMessage(userQuery);

      // Assert
      verify(mockMcpClientNotifierDelegate.processQuery(any, any)).called(1);
      // verifyNever(mockGenerativeModel.startChat(history: anyNamed('history'))); // Verify direct AI not called

      final finalState = container.read(chatProvider);
      expect(finalState.isLoading, isFalse);
      expect(finalState.displayMessages.length, 2); // User + Final Model
      expect(
        finalState.displayMessages.last.text,
        'OK. Task "buy milk" created (ID: 12345).',
      );
      expect(finalState.displayMessages.last.sourceServerId, 'test-stdio-id');
      expect(
        finalState.session.messages.length,
        4,
      ); // User + ModelCall + ToolResponse + FinalModel
    });

    test(
      'uses direct Gemini stream when MCP is not active', () async {
      // Arrange
      const userQuery = 'hello gemini';
      final fakeNotifier =
          container.read(mcpClientProvider.notifier) as FakeMcpClientNotifier;
      fakeNotifier.state = disconnectedMcpState; // Ensure MCP is inactive
      expect(fakeNotifier.state.hasActiveConnections, isFalse);

      // Mock the AI response directly (as the model is created internally)
      when(mockAiResponse.text).thenReturn('Hello there!');

      // Act
      await container.read(chatProvider.notifier).sendMessage(userQuery);
      await Future.delayed(Duration.zero); // Allow stream processing

      // Assert
      verifyNever(mockMcpClientNotifierDelegate.processQuery(any, any));
      // We can't easily verify the internal model call without refactoring,
      // but we can check the outcome.

      final finalState = container.read(chatProvider);
      expect(finalState.isLoading, isFalse);
      expect(finalState.displayMessages.length, 2); // User + Model
      expect(finalState.displayMessages.last.text, 'Hello there!');
      expect(finalState.displayMessages.last.sourceServerId, isNull);
      expect(finalState.session.messages.length, 2); // User + Model
    });
  });

  group('clearChat', () {
    test('clears state and deletes local/cloud data', () async {
      // Arrange: Add some initial message to state
      final notifier = container.read(chatProvider.notifier);
      notifier.state = notifier.state.copyWith(
        session: ChatSession(
          id: ChatSession.activeSessionId,
          messages: [ChatMessage.user('test')],
          lastUpdated: DateTime.now(),
        ),
      );
      expect(container.read(chatProvider).session.messages, isNotEmpty);

      // Act
      await notifier.clearChat();

      // Assert
      final state = container.read(chatProvider);
      expect(state.session.messages, isEmpty);
      expect(state.session.contextItemId, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isSyncing, isFalse);
      expect(state.errorMessage, isNull);
      verify(mockLocalStorageService.deleteActiveChatSession()).called(1);
      verify(mockCloudKitService.deleteChatSession()).called(1);
    });
  });

  group('startChatWithContext', () {
    test('clears previous messages and sets context', () async {
      // Arrange
      final notifier = container.read(chatProvider.notifier);
      // Add initial message
      notifier.state = notifier.state.copyWith(
        session: ChatSession(
          id: ChatSession.activeSessionId,
          messages: [ChatMessage.user('previous message')],
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
          contextItemId: 'old-context',
        ),
      );

      const contextString = 'Note content';
      const parentItemId = 'note-123';
      const parentItemType = WorkbenchItemType.note;
      const parentServerId = 'server-abc';

      // Act
      await notifier.startChatWithContext(
        contextString: contextString,
        parentItemId: parentItemId,
        parentItemType: parentItemType,
        parentServerId: parentServerId,
      );

      // Assert
      final state = container.read(chatProvider);
      expect(state.session.messages.length, 1); // Only system message
      expect(state.session.messages.first.role, Role.system);
      expect(state.session.messages.first.text, 'Context:\n$contextString');
      expect(state.session.contextItemId, parentItemId);
      expect(state.session.contextItemType, parentItemType);
      expect(state.session.contextServerId, parentServerId);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);

      // Verify persistence is triggered
      // Debounce timer makes direct verification tricky, but check if save methods were called eventually
      await Future.delayed(
        const Duration(milliseconds: 600),
      ); // Wait for debounce
      verify(mockLocalStorageService.saveActiveChatSession(any)).called(1);
      verify(mockCloudKitService.saveChatSession(any)).called(1);
    });
  });
}
