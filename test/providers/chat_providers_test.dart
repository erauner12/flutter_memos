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
// Hide the provider from the service file to avoid conflict with the one in chat_providers.dart
import 'package:flutter_memos/services/mcp_client_service.dart'
    hide mcpClientProvider;
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
// Extends StateNotifier to manage state correctly for Riverpod
// Uses a Mockito mock internally for verifying calls and stubbing behavior.
class FakeMcpClientNotifier extends StateNotifier<McpClientState> {
  final MockMcpClientNotifier mockDelegate; // The Mockito mock

  FakeMcpClientNotifier(super.initialState, this.mockDelegate);

  // --- Methods to Delegate to Mock ---
  // Delegate any method that the code under test (ChatNotifier) might call
  // and that you need to stub or verify in your tests.

  Future<McpProcessResult> processQuery(String query, List<Content>? history) {
    // Example: Log call or modify state before delegating
    // print("FakeMcpClientNotifier: processQuery called");
    // Delegate the actual call to the mock for stubbing/verification
    return mockDelegate.processQuery(query, history);
  }

  // --- Other methods/getters from McpClientNotifier ---
  // Implement other methods if ChatNotifier uses them, otherwise they can be omitted
  // if the mockDelegate handles them or they are not called.
  // For simplicity, we'll assume only processQuery and the state (handled by StateNotifier)
  // are directly relevant based on the ChatNotifier code provided.
  // If ChatNotifier used e.g., `syncConnections`, you'd add:
  // void syncConnections() => mockDelegate.syncConnections();

  // Note: StateNotifier already provides 'state', 'mounted', 'stream', 'addListener', 'dispose' etc.
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
      Content('model', [TextPart('OK. Task "buy milk" created (ID: 12345).')]);

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

    // Create the Fake Notifier Instance
    final fakeMcpClientNotifier = FakeMcpClientNotifier(
      defaultMcpState, // Initial state for the fake
      mockMcpClientNotifierDelegate, // Pass the mock delegate
    );

    // Set default stubbing for the *delegate* mock
    // No need to stub 'state' on the delegate anymore
    when(mockMcpClientNotifierDelegate.processQuery(any, any)).thenAnswer(
      (_) async => successfulMcpResult,
    ); // Stub processQuery on delegate
    when(mockGeminiService.isInitialized).thenReturn(true);

    // Create ProviderContainer with overrides using the *fake* notifier
    container = ProviderContainer(
      overrides: [
        // Override with the fake StateNotifier instance using overrideWithValue
        mcpClientProvider.overrideWith((ref) => fakeMcpClientNotifier),
        geminiServiceProvider.overrideWithValue(mockGeminiService),
        geminiApiKeyProvider.overrideWith(
          (_) => MockPersistentStringNotifier(
            PreferenceKeys.geminiApiKey,
            'fake-gemini-key',
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose(); // Dispose container after each test
  });

  test('sendMessage uses MCP when active and updates history correctly on tool call', () async {
      // Arrange: Configure the *delegate* mock for this specific test
    const userQuery = 'create task buy milk';

      // Get the fake notifier instance from the container to potentially change its state if needed
      // Cast is necessary because container.read returns the base StateNotifier type
      final fakeNotifier =
          container.read(mcpClientProvider.notifier) as FakeMcpClientNotifier;

      // Ensure the fake notifier's state reflects an active connection
      // We can directly set the state on the fake notifier
      fakeNotifier.state = defaultMcpState.copyWith(
      serverStatuses: {'test-id': McpConnectionStatus.connected},
      );

      // Ensure the delegate mock is stubbed correctly for this test case
      // (already done in setUp, but could be overridden here if needed)
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
    expect(finalState.displayMessages.last.text,
        'OK. Task "buy milk" created (ID: 12345).'); // Text from finalModelContent

    // Check chat history
    expect(finalState.chatHistory.length, 4); // User + ModelCall + ToolResponse + FinalModel
    expect(finalState.chatHistory[0].role, 'user');
      expect(
        (finalState.chatHistory[0].parts.first as TextPart).text,
        userQuery,
      ); // Cast to TextPart
    expect(finalState.chatHistory[1], mockModelCallContent); // Check model call
    expect(finalState.chatHistory[2], mockToolResponseContent); // Check tool response
    expect(finalState.chatHistory[3], mockFinalModelContent); // Check final model summary
  });

   test('sendMessage uses direct Gemini stream when MCP is not active', () async {
    // Arrange
    const userQuery = 'hello gemini';

    // Get the fake notifier instance
    // Cast is necessary because container.read returns the base StateNotifier type
    final fakeNotifier =
        container.read(mcpClientProvider.notifier) as FakeMcpClientNotifier;

    // Set the fake notifier's state to reflect no active connections
    fakeNotifier.state = defaultMcpState.copyWith(
      serverStatuses: {'test-id': McpConnectionStatus.disconnected}, // Disconnected
    );

    // Mock Gemini stream response (remains the same)
    when(mockGeminiService.sendMessageStream(userQuery, any))
        .thenAnswer((_) => Stream.fromIterable([
              // Simulate stream chunks
              generateContentResponse(text: 'Hello '),
              generateContentResponse(text: 'there!'),
            ]));

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
     verify(mockGeminiService.sendMessageStream(userQuery, any)).called(1); // Gemini should be called

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
        (finalState.chatHistory[1].parts.first as TextPart).text,
        'Hello there!',
      ); // Cast to TextPart
   });

}
