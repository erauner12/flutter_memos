import 'package:flutter_memos/models/chat_message.dart';
import 'package:flutter_memos/models/mcp_server_config.dart'; // Needed for McpClientState setup
import 'package:flutter_memos/providers/chat_providers.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // For geminiApiKeyProvider override
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
  MockSpec<McpClientNotifier>(),
  MockSpec<McpClientState>(), // Although not directly injected, useful for mocking notifier state
  MockSpec<GeminiService>(),
])
import 'chat_providers_test.mocks.dart';

// Simple mock for the PersistentStringNotifier used by geminiApiKeyProvider
class MockPersistentStringNotifier extends StateNotifier<String> {
  MockPersistentStringNotifier(super.initialState);

  Future<void> init() async {
    // Mock init doesn't need to do anything
  }
  // No need to mock 'update' unless the test specifically requires verifying it
}

// Helper to create GenerateContentResponse for stream testing
GenerateContentResponse generateContentResponse({String? text}) {
  return GenerateContentResponse(
    [
      // Provide all required positional arguments for Candidate
      Candidate(
        Content('model', [if (text != null) TextPart(text)]),
        FinishReason.stop, // finishReason
        null, // safetyRatings
        null, // citationMetadata
        null, // tokenCount
      ),
    ],
    null, // Prompt feedback can be null
  );
}

void main() {
  // Mocks
  late MockMcpClientNotifier mockMcpClientNotifier;
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
    // Initialize mocks before each test
    mockMcpClientNotifier = MockMcpClientNotifier();
    mockGeminiService = MockGeminiService();

    // SharedPreferences mock is no longer needed here as we override the provider state/notifier

    // Set default stubbing for mocks
    when(mockMcpClientNotifier.state).thenReturn(defaultMcpState);
    when(mockGeminiService.isInitialized).thenReturn(true); // Assume Gemini is ready

    // Create a ProviderContainer for testing
    container = ProviderContainer(
      overrides: [
        // Override providers with mocks
        mcpClientProvider.overrideWith((ref) => mockMcpClientNotifier),
        geminiServiceProvider.overrideWithValue(mockGeminiService),
        // Override the StateNotifierProvider with our mock notifier instance
        geminiApiKeyProvider.overrideWith(
          (_) => MockPersistentStringNotifier('fake-gemini-key'),
        ),
      ],
    );

     // Initialize PersistentStringNotifiers (needed by ChatNotifier constructor listener)
    // We don't need to wait for the real init here as we override the value
    await container.read(geminiApiKeyProvider.notifier).init();

  });

  tearDown(() {
    container.dispose(); // Dispose container after each test
  });

  test('sendMessage uses MCP when active and updates history correctly on tool call', () async {
    // Arrange: Configure mocks for this specific test
    const userQuery = 'create task buy milk';
    // Ensure the notifier's state reflects an active connection
    when(mockMcpClientNotifier.state).thenReturn(defaultMcpState.copyWith(
      serverStatuses: {'test-id': McpConnectionStatus.connected},
    ));
    // Mock the processQuery call to return the successful result
    when(mockMcpClientNotifier.processQuery(userQuery, any))
        .thenAnswer((_) async => successfulMcpResult);

    final chatNotifier = container.read(chatProvider.notifier);

    // Act: Call the method under test
    await chatNotifier.sendMessage(userQuery);

    // Assert
    // Verify processQuery was called
    verify(mockMcpClientNotifier.processQuery(userQuery, any)).called(1);
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
    // Ensure MCP state shows no active connections
     when(mockMcpClientNotifier.state).thenReturn(defaultMcpState.copyWith(
      serverStatuses: {'test-id': McpConnectionStatus.disconnected}, // Disconnected
    ));
    // Mock Gemini stream response
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
     verifyNever(mockMcpClientNotifier.processQuery(any, any)); // MCP should not be called
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
