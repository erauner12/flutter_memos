import 'package:flutter_memos/models/chat_message.dart';
import 'package:flutter_memos/models/mcp_server_config.dart'; // Needed for McpClientState setup
import 'package:flutter_memos/providers/chat_providers.dart'
    show ChatNotifier, chatProvider; // Import ChatNotifier and provider
// Import necessary symbols from settings_provider
import 'package:flutter_memos/providers/settings_provider.dart'
    show
        PersistentStringNotifier,
        geminiApiKeyProvider,
        PreferenceKeys; // Import the class containing the keys
import 'package:flutter_memos/services/gemini_service.dart'
    show GeminiService, geminiServiceProvider;
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
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mocks for dependencies
@GenerateNiceMocks([
  MockSpec<McpClientNotifier>(), // Keep this for the delegate
  MockSpec<McpClientState>(),
  MockSpec<GeminiService>(),
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

// --- Fake McpClientNotifier ---
// Extends the actual McpClientNotifier to be a valid subtype for overrideWith.
// Uses a Mockito mock internally for verifying calls and stubbing behavior.
class FakeMcpClientNotifier extends McpClientNotifier {
  // Extend McpClientNotifier
  final MockMcpClientNotifier mockDelegate; // The Mockito mock

  // Constructor now accepts Ref and initial state, passes Ref to super
  FakeMcpClientNotifier(
    super.ref, // Accept Ref
    McpClientState initialState,
    this.mockDelegate,
  ) {
    // Pass ref to super constructor
    // Manually set the initial state since the super constructor initializes differently
    // Or if the super constructor sets a default state, override it here.
    state = initialState;
  }

  // --- Methods to Delegate to Mock ---
  // Delegate any method that the code under test (ChatNotifier) might call
  // and that you need to stub or verify in your tests.

  @override // Override the method from McpClientNotifier
  Future<McpProcessResult> processQuery(String query, List<Content> history) {
    // Delegate the actual call to the mock for stubbing/verification
    return mockDelegate.processQuery(query, history);
  }

  // --- Override other methods from McpClientNotifier if needed ---
  // Override methods like initialize, connectServer, syncConnections, etc.,
  // if they might be called indirectly or interfere with the test.
  // For now, we assume they are not critical for these specific tests
  // and primarily delegate processQuery.

  @override
  void initialize() {
    // Prevent real initialization logic if necessary
    // mockDelegate.initialize(); // Optionally delegate if needed for verification
  }

  @override
  Future<void> connectServer(McpServerConfig serverConfig) async {
    // Optionally delegate: return mockDelegate.connectServer(serverConfig);
    return Future.value();
  }

  @override
  Future<void> disconnectServer(String serverId) async {
    // Optionally delegate: return mockDelegate.disconnectServer(serverId);
    return Future.value();
  }

  @override
  void syncConnections() {
    // Optionally delegate: mockDelegate.syncConnections();
  }

  @override
  void rebuildToolMap() {
    // Optionally delegate: mockDelegate.rebuildToolMap();
  }

  // Note: StateNotifier already provides 'state', 'mounted', 'stream', 'addListener', 'dispose' etc.
  // We override dispose to avoid potential issues with the real notifier's dispose logic.
}
// --- End Fake McpClientNotifier ---


// Helper to create GenerateContentResponse (Keep as is)
GenerateContentResponse generateContentResponse({String? text}) {
  return GenerateContentResponse(
    [
      // Provide all required positional arguments for Candidate in the correct order:
      // content, safetyRatings, citationMetadata, finishReason, tokenCount
      Candidate(
        Content('model', [if (text != null) TextPart(text)]), // content
        null, // safetyRatings (List<SafetyRating>?)
        null, // citationMetadata (CitationMetadata?)
        FinishReason.stop, // finishReason (FinishReason?)
        null, // tokenCount (int?)
      )
    ],
    null, // Prompt feedback can be null
  );
}

void main() {
  // Mocks
  late MockMcpClientNotifier
  mockMcpClientNotifierDelegate; // Renamed for clarity
  late MockGeminiService mockGeminiService;
  late ProviderContainer container;
  // Access ChatNotifier instance for helper method
  late ChatNotifier chatNotifierInstance;

  // Default mock states/values
  final defaultStdioMcpConfig = const McpServerConfig(
    id: 'test-stdio-id',
    name: 'Test Stdio Server',
    connectionType: McpConnectionType.stdio, // Explicitly stdio
    command: 'test',
    args: '',
    isActive: true,
  );

  final defaultStdioMcpState = McpClientState(
    serverConfigs: [defaultStdioMcpConfig],
    serverStatuses: {'test-stdio-id': McpConnectionStatus.connected},
    activeClients: {}, // Mock clients if needed for McpClientNotifier tests
    serverErrorMessages: {},
  );

  // Define the SSE config and state
  final defaultSseMcpConfig = const McpServerConfig(
    id: 'test-sse-id',
    name: 'Test SSE Server',
    connectionType: McpConnectionType.sse, // Explicitly sse
    host: 'localhost', // Example host
    port: 8999, // Example port
    isActive: true,
  );

  final defaultSseMcpState = McpClientState(
    serverConfigs: [defaultSseMcpConfig],
    serverStatuses: {'test-sse-id': McpConnectionStatus.connected},
    activeClients: {}, // Mock clients if needed
    serverErrorMessages: {},
  );

  // Define disconnected state (can be used for stdio or sse id)
  final disconnectedMcpState = McpClientState(
    serverConfigs: [defaultStdioMcpConfig], // Include a config for reference
    serverStatuses: {'test-stdio-id': McpConnectionStatus.disconnected},
    activeClients: {},
    serverErrorMessages: {},
  );

  final mockModelCallContent = Content('model', [
    FunctionCall('create_todoist_task', {'content': 'buy milk'})
  ]);
  final mockToolResponseContent = Content('function', [
    FunctionResponse(
        'create_todoist_task', {'status': 'success', 'taskId': '12345'})
  ]);
  final mockFinalModelContent = Content('model', [
    TextPart(
      'OK. Task "buy milk" created (ID: 12345).',
    ),
  ]);

  final successfulMcpResult = McpProcessResult(
    modelCallContent: mockModelCallContent,
    toolResponseContent: mockToolResponseContent,
    finalModelContent: mockFinalModelContent,
    toolName: 'create_todoist_task',
    toolArgs: {'content': 'buy milk'},
    toolResult: '{"status":"success","taskId":"12345"}',
    sourceServerId: 'test-stdio-id', // Match stdio config id
  );

  // Result specific to SSE server ID
  final successfulSseMcpResult = McpProcessResult(
    modelCallContent: mockModelCallContent,
    toolResponseContent: mockToolResponseContent,
    finalModelContent: mockFinalModelContent, // Can reuse content
    toolName: 'create_todoist_task',
    toolArgs: {'content': 'buy milk'},
    toolResult: '{"status":"success","taskId":"12345"}',
    sourceServerId: 'test-sse-id', // Match SSE config id
  );

  setUp(() async {
    // Initialize mocks
    mockMcpClientNotifierDelegate =
        MockMcpClientNotifier(); // This is the delegate
    mockGeminiService = MockGeminiService();

    // Set default stubbing for the *delegate* mock (can be overridden in tests)
    when(mockMcpClientNotifierDelegate.processQuery(any, any)).thenAnswer(
      (_) async => successfulMcpResult, // Default to stdio result
    );
    when(mockGeminiService.isInitialized).thenReturn(true);

    // Create ProviderContainer with overrides
    container = ProviderContainer(
      overrides: [
        // Override the StateNotifierProvider using overrideWith
        // Instantiate the Fake *inside* the callback, passing the ref
        mcpClientProvider.overrideWith((ref) {
          // Create the Fake Notifier Instance here, passing the ref
          final fakeMcpClientNotifier = FakeMcpClientNotifier(
            ref, // Pass the ref from the override callback
            defaultStdioMcpState, // Initial state for the fake (can be changed in tests)
            mockMcpClientNotifierDelegate, // Pass the mock delegate
          );
          return fakeMcpClientNotifier; // Return the FakeMcpClientNotifier instance
        }),
        geminiServiceProvider.overrideWithValue(mockGeminiService),
        geminiApiKeyProvider.overrideWith(
          (_) => MockPersistentStringNotifier(
            PreferenceKeys.geminiApiKey,
            'fake-gemini-key',
          ),
        ),
      ],
    );

    // Get ChatNotifier instance for helper method access
    chatNotifierInstance = container.read(chatProvider.notifier);
  });

  test(
    'sendMessage uses MCP (stdio) when active and updates history correctly on tool call',
    () async {
      // Arrange: Configure the *delegate* mock for this specific test
      const userQuery = 'create task buy milk';
      const expectedServerId = 'test-stdio-id'; // Expect stdio server

      // Get the fake notifier instance from the container
      final fakeNotifier =
          container.read(mcpClientProvider.notifier) as FakeMcpClientNotifier;

      // Ensure the fake notifier's state reflects an active stdio connection
      fakeNotifier.state = defaultStdioMcpState; // Use stdio state
      expect(fakeNotifier.state.hasActiveConnections, isTrue);

      // Ensure the delegate mock is stubbed correctly for this test case
      // Create a new result with the matching server ID instead of using copyWith
      final expectedResult = McpProcessResult(
        modelCallContent: mockModelCallContent,
        toolResponseContent: mockToolResponseContent,
        finalModelContent: mockFinalModelContent,
        toolName: 'create_todoist_task',
        toolArgs: {'content': 'buy milk'},
        toolResult: '{"status":"success","taskId":"12345"}',
        sourceServerId: expectedServerId, // Set the correct server ID
      );
      when(
        mockMcpClientNotifierDelegate.processQuery(userQuery, any),
      ).thenAnswer((_) async => expectedResult);

      // Act: Call the method under test
      await chatNotifierInstance.sendMessage(userQuery);

      // Assert
      // Verify calls on the *delegate* mock, capturing history
      // Construct the full expected query string using the static context
      final fullExpectedQuery =
          "${ChatNotifier.todoistContext}\\n\\nUser query: $userQuery";
      final verification = verify(
        mockMcpClientNotifierDelegate.processQuery(
          fullExpectedQuery,
          captureAny,
        ),
      );
      verification.called(1);
      final capturedHistory = verification.captured.single as List<Content>?;
      expect(capturedHistory, isA<List<Content>>()); // Verify type

      // Verify Gemini stream was NOT called directly
      verifyNever(mockGeminiService.sendMessageStream(any, any));

      final finalState = container.read(chatProvider);

      // Check display messages
      expect(finalState.isLoading, isFalse);
      expect(
        finalState.displayMessages.length,
        2,
      ); // User message + Final response
      expect(finalState.displayMessages.first.role, Role.user);
      expect(finalState.displayMessages.first.text, userQuery);
      expect(finalState.displayMessages.last.role, Role.model);
      expect(finalState.displayMessages.last.isLoading, isFalse);
      expect(finalState.displayMessages.last.isError, isFalse);
      expect(
        finalState.displayMessages.last.sourceServerId,
        expectedServerId,
      ); // Check source server
      expect(
        chatNotifierInstance.getTextFromContent(mockFinalModelContent),
        'OK. Task "buy milk" created (ID: 12345).',
      );
      expect(
        finalState.displayMessages.last.text,
        'OK. Task "buy milk" created (ID: 12345).',
      );

      // Check chat history
      expect(
        finalState.chatHistory.length,
        4,
      ); // User + ModelCall + ToolResponse + FinalModel
      expect(finalState.chatHistory[0].role, 'user');
      // The history user message includes the context
      expect(
        chatNotifierInstance.getTextFromContent(
          finalState.chatHistory[0],
        ),
        fullExpectedQuery, // Expect the message with context
      );
      expect(
        finalState.chatHistory[1],
        mockModelCallContent,
      ); // Check model call (role 'model')
      expect(
        finalState.chatHistory[2],
        mockToolResponseContent,
      ); // Check tool response (role 'function')
      expect(
        finalState.chatHistory[3],
        mockFinalModelContent,
      ); // Check final model summary (role 'model')
    },
  );

  test(
    'sendMessage uses MCP (SSE) when active and updates history correctly',
    () async {
      // Arrange: Configure the *delegate* mock for this specific test
      const userQuery = 'create sse task buy milk';
      const expectedServerId = 'test-sse-id'; // Expect SSE server

      // Get the fake notifier instance from the container
      final fakeNotifier =
          container.read(mcpClientProvider.notifier) as FakeMcpClientNotifier;

      // Ensure the fake notifier's state reflects an active SSE connection
      fakeNotifier.state = defaultSseMcpState; // Use SSE state
      expect(fakeNotifier.state.hasActiveConnections, isTrue);

      // Ensure the delegate mock is stubbed correctly for this test case
      // Create a new result with the matching SSE server ID instead of using copyWith
      final expectedResult = McpProcessResult(
        modelCallContent: mockModelCallContent,
        toolResponseContent: mockToolResponseContent,
        finalModelContent: mockFinalModelContent,
        toolName: 'create_todoist_task',
        toolArgs: {'content': 'buy milk'},
        toolResult: '{"status":"success","taskId":"12345"}',
        sourceServerId: expectedServerId, // Set the correct server ID
      );
      when(
        mockMcpClientNotifierDelegate.processQuery(userQuery, any),
      ).thenAnswer((_) async => expectedResult);

      // Act: Call the method under test
      await chatNotifierInstance.sendMessage(userQuery);

      // Assert
      // Verify calls on the *delegate* mock
      // Construct the full expected query string using the static context
      final fullExpectedQuery =
          "${ChatNotifier.todoistContext}\\n\\nUser query: $userQuery";
      verify(
        mockMcpClientNotifierDelegate.processQuery(fullExpectedQuery, any),
      ).called(1);
      // Verify Gemini stream was NOT called directly
      verifyNever(mockGeminiService.sendMessageStream(any, any));

      final finalState = container.read(chatProvider);

      // Check display messages
      expect(finalState.isLoading, isFalse);
      expect(
        finalState.displayMessages.length,
        2,
      ); // User message + Final response
      expect(finalState.displayMessages.first.role, Role.user);
      expect(finalState.displayMessages.first.text, userQuery);
      expect(finalState.displayMessages.last.role, Role.model);
      expect(finalState.displayMessages.last.isLoading, isFalse);
      expect(finalState.displayMessages.last.isError, isFalse);
      expect(
        finalState.displayMessages.last.sourceServerId,
        expectedServerId,
      ); // Check source server
      expect(
        chatNotifierInstance.getTextFromContent(mockFinalModelContent),
        'OK. Task "buy milk" created (ID: 12345).',
      );
      expect(
        finalState.displayMessages.last.text,
        'OK. Task "buy milk" created (ID: 12345).',
      );

      // Check chat history
      expect(
        finalState.chatHistory.length,
        4,
      ); // User + ModelCall + ToolResponse + FinalModel
      expect(finalState.chatHistory[0].role, 'user');
      // The history user message includes the context
      expect(
        chatNotifierInstance.getTextFromContent(finalState.chatHistory[0]),
        fullExpectedQuery, // Expect the message with context
      );
      expect(finalState.chatHistory[1], mockModelCallContent); // Role 'model'
      expect(
        finalState.chatHistory[2],
        mockToolResponseContent,
      ); // Role 'function'
      expect(finalState.chatHistory[3], mockFinalModelContent); // Role 'model'
    },
  );

  test(
    'sendMessage uses direct Gemini stream when MCP is not active',
    () async {
      // Arrange
      const userQuery = 'hello gemini';

      // Get the fake notifier instance
      final fakeNotifier =
          container.read(mcpClientProvider.notifier) as FakeMcpClientNotifier;

      // Set the fake notifier's state to reflect no active connections
      fakeNotifier.state = disconnectedMcpState; // Use disconnected state
      expect(fakeNotifier.state.hasActiveConnections, isFalse);

      // Mock Gemini stream response (remains the same)
      when(mockGeminiService.sendMessageStream(userQuery, any)).thenAnswer(
        (_) => Stream.fromIterable([
          // Simulate stream chunks
          generateContentResponse(text: 'Hello '),
          generateContentResponse(text: 'there!'),
        ]),
      );

      // Act
      await chatNotifierInstance.sendMessage(userQuery);
      await Future.delayed(Duration.zero);

      // Assert
      verifyNever(
        mockMcpClientNotifierDelegate.processQuery(any, any),
      );
      // Construct the full expected query string using the static context
      final fullExpectedQuery =
          "${ChatNotifier.todoistContext}\\n\\nUser query: $userQuery";
      verify(
        mockGeminiService.sendMessageStream(fullExpectedQuery, any),
      ).called(1);

      final finalState = container.read(chatProvider);
      expect(finalState.isLoading, isFalse);
      expect(finalState.displayMessages.length, 2);
      expect(finalState.displayMessages.last.text, 'Hello there!');
      expect(finalState.displayMessages.last.isLoading, isFalse);
      expect(
        finalState.displayMessages.last.sourceServerId,
        isNull,
      );

      expect(finalState.chatHistory.length, 2);
      expect(finalState.chatHistory[0].role, 'user');
      // The history user message includes the context
      expect(
        chatNotifierInstance.getTextFromContent(finalState.chatHistory[0]),
        fullExpectedQuery, // Expect the message with context
      );
      expect(finalState.chatHistory[1].role, 'model');
      expect(
        chatNotifierInstance.getTextFromContent(finalState.chatHistory[1]),
        'Hello there!',
      );
    },
  );
}
