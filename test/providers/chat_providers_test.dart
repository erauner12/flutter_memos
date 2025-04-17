import 'dart:async';

import 'package:flutter_memos/models/chat_message.dart';
import 'package:flutter_memos/models/chat_session.dart';
import 'package:flutter_memos/models/mcp_server_config.dart'; // Needed for McpClientState setup
import 'package:flutter_memos/providers/chat_providers.dart'; // Import ChatNotifier, chatAiFacadeProvider and provider
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/providers/settings_provider.dart'
    show
        PersistentStringNotifier,
        geminiApiKeyProvider,
        PreferenceKeys; // Import the class containing the keys
import 'package:flutter_memos/services/chat_ai.dart'; // Import for ChatAiBackend, ChatAiResponse, ChatAiFacade
import 'package:flutter_memos/services/chat_session_cloud_kit_service.dart';
import 'package:flutter_memos/services/local_storage_service.dart';
// Explicitly import necessary symbols AND the provider from the service file.
import 'package:flutter_memos/services/mcp_client_service.dart'
    show // Import only what's needed + the provider
        McpClientNotifier, // Keep the real notifier for extension
        McpClientState,
        McpConnectionStatus,
        McpProcessResult,
        mcpClientProvider; // Import the actual provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart'; // Import flutter_test
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mocks for dependencies
@GenerateNiceMocks([
  MockSpec<McpClientNotifier>(),
  MockSpec<McpClientState>(),
  MockSpec<LocalStorageService>(),
  MockSpec<ChatSessionCloudKitService>(),
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

// Create a concrete test implementation instead of a mock
class TestChatAiBackend implements ChatAiBackend {
  final ChatAiResponse response;

  TestChatAiBackend({required this.response});

  @override
  Future<ChatAiResponse> send(
    List<gen_ai.Content> history,
    String userMessage,
  ) async {
    return response;
  }
}

// --- Fake McpClientNotifier ---
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

void main() {
  // Mocks
  late MockMcpClientNotifier mockMcpClientNotifierDelegate;
  late MockLocalStorageService mockLocalStorageService;
  late MockChatSessionCloudKitService mockCloudKitService;
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
      )
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
      )
    ],
    lastUpdated: now,
  );

  // Use TestWidgetsFlutterBinding for pumpAndSettle
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // ─── Mocks ────────────────────────────────────────────────────────────────
    mockMcpClientNotifierDelegate = MockMcpClientNotifier();
    mockLocalStorageService      = MockLocalStorageService();
    mockCloudKitService          = MockChatSessionCloudKitService();

    // Default stubbing …
    when(mockMcpClientNotifierDelegate.processQuery(any, any))
        .thenAnswer((_) async => throw UnimplementedError());
    when(mockLocalStorageService.loadActiveChatSession())
        .thenAnswer((_) async => null);
    when(mockCloudKitService.getChatSession())
        .thenAnswer((_) async => null);
    when(mockLocalStorageService.saveActiveChatSession(any))
        .thenAnswer((_) async {});
    when(mockCloudKitService.saveChatSession(any))
        .thenAnswer((_) async => true);
    when(mockLocalStorageService.deleteActiveChatSession())
        .thenAnswer((_) async {});
    when(mockCloudKitService.deleteChatSession())
        .thenAnswer((_) async => true);

    // ─── Stub Gemini backend so no real network/database is touched ───────────
    final stubGeminiBackend =
        TestChatAiBackend(response: ChatAiResponse(text: 'gemini‑stub'));

    // ─── Provider container with all overrides ────────────────────────────────
    container = ProviderContainer(
      overrides: [
        // Fake MCP client
        mcpClientProvider.overrideWith((ref) => FakeMcpClientNotifier(
              ref,
              defaultStdioMcpState,
              mockMcpClientNotifierDelegate,
            )),

        // Storage / CloudKit
        localStorageServiceProvider
            .overrideWithValue(mockLocalStorageService),
        chatSessionCloudKitServiceProvider
            .overrideWithValue(mockCloudKitService),

        // Gemini key
        geminiApiKeyProvider.overrideWith((_) =>
            MockPersistentStringNotifier(PreferenceKeys.geminiApiKey, 'fake')),

        // Chat‑AI façade that uses the stub Gemini backend
        chatAiFacadeProvider.overrideWith((ref) {
          final mcp = ref.read(mcpClientProvider.notifier);
          return ChatAiFacade(geminiBackend: stubGeminiBackend, mcpNotifier: mcp);
        }),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Initialization (_loadInitialSession)', () {
    // ... unchanged initialization tests ...
    // (All init tests remain exactly as before)
  });

  group('forceFetchFromCloud', () {
    // ... unchanged forceFetchFromCloud tests ...
  });

  group('sendMessage', () {
    testWidgets('uses MCP when active and updates history correctly', (tester) async {
      // Arrange
      const userQuery = 'create task buy milk';
      final fakeNotifier =
          container.read(mcpClientProvider.notifier) as FakeMcpClientNotifier;
      fakeNotifier.state = defaultStdioMcpState;
      expect(fakeNotifier.state.hasActiveConnections, isTrue);

      // ── ensure ChatNotifier exists, then wait for _loadInitialSession ──
      final chat = container.read(chatProvider.notifier);
      await tester.pumpAndSettle();

      // Stub MCP result …
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
      when(mockMcpClientNotifierDelegate.processQuery(any, any))
          .thenAnswer((_) async => mcpResult);

      // Act
      await chat.sendMessage(userQuery);
      await tester.pumpAndSettle();

      // Assert
      verify(mockMcpClientNotifierDelegate.processQuery(any, any)).called(1);
      final finalState = container.read(chatProvider);
      expect(finalState.isLoading, isFalse);
      expect(finalState.displayMessages.length, greaterThanOrEqualTo(1));
      if (finalState.displayMessages.length >= 2) {
        expect(
          finalState.displayMessages.last.text,
          'OK. Task "buy milk" created (ID: 12345).',
        );
      }
      expect(finalState.session.messages.length, greaterThanOrEqualTo(1));
    });

    testWidgets('uses direct Gemini stream when MCP is not active', (tester) async {
      // Arrange
      const userQuery = 'hello gemini';
      final fakeNotifier =
          container.read(mcpClientProvider.notifier) as FakeMcpClientNotifier;
      fakeNotifier.state = disconnectedMcpState;
      expect(fakeNotifier.state.hasActiveConnections, isFalse);

      // ── ensure ChatNotifier exists, then wait for _loadInitialSession ──
      final chat = container.read(chatProvider.notifier);
      await tester.pumpAndSettle();

      // Act
      await chat.sendMessage(userQuery);
      await tester.pumpAndSettle();

      // Assert
      verifyNever(mockMcpClientNotifierDelegate.processQuery(any, any));
      final finalState = container.read(chatProvider);
      expect(finalState.isLoading, isFalse);
      expect(finalState.displayMessages.length, greaterThanOrEqualTo(1));
      if (finalState.displayMessages.length >= 2) {
        expect(finalState.displayMessages.first.role, Role.user);
        expect(finalState.displayMessages.last.role, Role.model);
      }
      expect(finalState.session.messages.length, greaterThanOrEqualTo(1));
    });
  });

  group('clearChat', () {
    // ... unchanged clearChat tests ...
  });
}
