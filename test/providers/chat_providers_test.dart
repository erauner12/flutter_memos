import 'package:flutter_memos/models/chat_message.dart';
import 'package:flutter_memos/models/mcp_server_config.dart'; // Needed for McpClientState setup
import 'package:flutter_memos/providers/chat_providers.dart';
// Import necessary symbols from settings_provider
import 'package:flutter_memos/providers/settings_provider.dart'
    show
        PersistentStringNotifier,
        geminiApiKeyProvider,
        PreferenceKeys; // Import the class containing the keys
import 'package:flutter_memos/services/gemini_service.dart';
// Explicitly import necessary symbols AND the provider from the service file.
import 'package:flutter_memos/services/mcp_client_service.dart'
    show // Import only what's needed + the provider
        McpClientNotifier,
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
    super.ref,
    McpClientState initialState,
    this.mockDelegate,
  ) {
    // Pass ref to super constructor
    // Manually set the initial state since the super constructor initializes differently
    state = initialState;
  }


  // --- Methods to Delegate to Mock ---
  // Delegate any method that the code under test (ChatNotifier) might call
  // and that you need to stub or verify in your tests.

  @override // Override the method from McpClientNotifier
  Future<McpProcessResult> processQuery(String query, List<Content> history) {
    // Example: Log call or modify state before delegating
    // print("FakeMcpClientNotifier: processQuery called");
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
  @override
  void dispose() {
    // Don't call super.dispose() if it has complex logic we want to avoid.
    // Or delegate if the mock needs to track disposal: mockDelegate.dispose();
    super.dispose(); // Call super.dispose()
  }
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

  // Default mock states/values
  final defaultMcpState = const McpClientState(
    serverConfigs: [
      McpServerConfig(
          id: 'test-id', name: 'Test Server', command: 'test', args: ''),
    ],
    serverStatuses: {'test-id': McpConnectionStatus.connected},
    activeClients: {}, // Mock clients if needed for McpClientNotifier tests
    serverErrorMessages: {},
  );

  final mockModelCallContent = Content('model', [
    FunctionCall('create_todoist_task', {'content': 'buy milk'})
  ]);
  final mockToolResponseContent = Content('function', [
    FunctionResponse(
        'create_todoist_task', {'status': 'success', 'taskId': '12345'})
  ]);
  final mockFinalModelContent =
      Content('model', [
    TextPart('OK. Task "buy milk created (ID: 12345).'),
  ]);

  final successfulMcpResult = McpProcessResult(
    modelCallContent: mockModelCallContent,
    toolResponseContent: mockToolResponseContent,
    finalModelContent: mockFinalModelContent,
    toolName: 'create_todoist_task',
    toolArgs: {'content': 'buy milk'},
    toolResult: '{"status":"success","taskId":"12345"}',
    sourceServerId: 'test-id',
  );

  setUp(() async {
    // Initialize mocks
    mockMcpClientNotifierDelegate =
        MockMcpClientNotifier(); // This is the delegate
    mockGeminiService = MockGeminiService();

    // Set default stubbing for the *delegate* mock
    when(mockMcpClientNotifierDelegate.processQuery(any, any)).thenAnswer(
      (_) async => successfulMcpResult,
    ); // Stub processQuery on delegate
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
            defaultMcpState, // Initial state for the fake
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

    // It might be necessary to ensure the fake notifier's state is correctly set *after*
    // the container is created, especially if the super constructor or initialize
    // methods (even if overridden) affect the state.
    // Let's read the notifier after creation and explicitly set state if needed.
    final fakeNotifier =
        container.read(mcpClientProvider.notifier) as FakeMcpClientNotifier;
    fakeNotifier.state =
        defaultMcpState; // Ensure initial state is set correctly

  });

  tearDown(() {
    container.dispose(); // Dispose container after each test
  });

  test('sendMessage uses MCP when active and updates history correctly on tool call', () async {
      // Arrange: Configure the *delegate* mock for this specific test
    const userQuery = 'create task buy milk';

      // Get the fake notifier instance from the container
      // Cast to the correct FakeMcpClientNotifier type
      final fakeNotifier =
          container.read(mcpClientProvider.notifier) as FakeMcpClientNotifier;

      // Ensure the fake notifier's state reflects an active connection
      // We can directly set the state on the fake notifier
      fakeNotifier.state = defaultMcpState.copyWith(
        // Ensure hasActiveConnections is true for this test
        serverStatuses: {'test-id': McpConnectionStatus.connected},
        // Make sure activeClients isn't empty if hasActiveConnections relies on it
        // (Though McpClientState calculates it based on serverStatuses)
      );
      // Add a debug print to confirm state before acting
      


      // Ensure the delegate mock is stubbed correctly for this test case
      when(
        mockMcpClientNotifierDelegate.processQuery(userQuery, any),
      )
        .thenAnswer((_) async => successfulMcpResult);

    final chatNotifier = container.read(chatProvider.notifier);

    // Act: Call the method under test
    await chatNotifier.sendMessage(userQuery);

    // Assert
      // Verify calls on the *delegate* mock
      verify(
        mockMcpClientNotifierDelegate.processQuery(userQuery, any),
      ).called(1);
    // Verify Gemini stream was NOT called directly
    verifyNever(mockGeminiService.sendMessageStream(any, any));

    final finalState = container.read(chatProvider);

    // Check display messages
    expect(finalState.isLoading, isFalse);
    expect(finalState.displayMessages.length, 2); // User message + Final response
    expect(finalState.displayMessages.first.role, Role.user);
    expect(finalState.displayMessages.first.text, userQuery);
    expect(finalState.displayMessages.last.role, Role.model);
    expect(finalState.displayMessages.last.isLoading, isFalse);
    expect(finalState.displayMessages.last.isError, isFalse);
      // Use the helper function to extract text for comparison
      expect(
        chatNotifier.getTextFromContent(mockFinalModelContent),
        'OK. Task "buy milk" created (ID: 12345).',
      );
    expect(finalState.displayMessages.last.text,
        'OK. Task "buy milk" created (ID: 12345).'); // Text from finalModelContent

    // Check chat history
    expect(finalState.chatHistory.length, 4); // User + ModelCall + ToolResponse + FinalModel
    expect(finalState.chatHistory[0].role, 'user');
      expect(
        chatNotifier.getTextFromContent(
          finalState.chatHistory[0],
        ), // Use helper
        userQuery,
      );
    expect(finalState.chatHistory[1], mockModelCallContent); // Check model call
    expect(finalState.chatHistory[2], mockToolResponseContent); // Check tool response
    expect(finalState.chatHistory[3], mockFinalModelContent); // Check final model summary
  });

   test('sendMessage uses direct Gemini stream when MCP is not active', () async {
    // Arrange
    const userQuery = 'hello gemini';

    // Get the fake notifier instance
    // Cast to the correct FakeMcpClientNotifier type
    final fakeNotifier =
        container.read(mcpClientProvider.notifier) as FakeMcpClientNotifier;

    // Set the fake notifier's state to reflect no active connections
    fakeNotifier.state = defaultMcpState.copyWith(
      serverStatuses: {
        'test-id': McpConnectionStatus.disconnected,
      }, // Disconnected
      activeClients: {}, // Ensure no active clients
    );
    // Add a debug print to confirm state before acting
    


    // Mock Gemini stream response (remains the same)
    when(mockGeminiService.sendMessageStream(userQuery, any)).thenAnswer(
      (_) => Stream.fromIterable([
        // Simulate stream chunks
        generateContentResponse(text: 'Hello '),
        generateContentResponse(text: 'there!'),
      ]),
    );

    final chatNotifier = container.read(chatProvider.notifier);

    // Act
    await chatNotifier.sendMessage(userQuery);
    // Need a slight delay to allow the stream listener to process 'onDone'
    await Future.delayed(Duration.zero);


    // Assert
    // Verify calls on the *delegate* mock
    verifyNever(
      mockMcpClientNotifierDelegate.processQuery(any, any),
    ); // MCP should not be called
    verify(
      mockGeminiService.sendMessageStream(userQuery, any),
    ).called(1); // Gemini should be called

    final finalState = container.read(chatProvider);
    expect(finalState.isLoading, isFalse);
    expect(finalState.displayMessages.length, 2); // User + Final response
    expect(finalState.displayMessages.last.text, 'Hello there!');
    expect(finalState.displayMessages.last.isLoading, isFalse);

    // Check history for direct Gemini call
    expect(finalState.chatHistory.length, 2); // User + Final Model
    expect(finalState.chatHistory[0].role, 'user');
    expect(finalState.chatHistory[1].role, 'model');
    expect(
      chatNotifier.getTextFromContent(finalState.chatHistory[1]), // Use helper
      'Hello there!',
    );
  });

}
