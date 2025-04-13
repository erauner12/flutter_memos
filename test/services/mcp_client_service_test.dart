import 'dart:async';

import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/providers/mcp_server_config_provider.dart';
import 'package:flutter_memos/services/gemini_service.dart';
import 'package:flutter_memos/services/mcp_client_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import generated mocks relative to this file's location
import 'mcp_client_service_test.mocks.dart';

// Sample McpServerConfig data for tests
final mcpServerStdio = const McpServerConfig(
  id: 'mcp-stdio-1',
  name: 'MCP Stdio Server',
  connectionType: McpConnectionType.stdio,
  command: 'echo',
  args: 'hello',
  isActive: true,
);
final mcpServerSse = const McpServerConfig(
  id: 'mcp-sse-1',
  name: 'MCP SSE Server',
  connectionType: McpConnectionType.sse,
  host: 'localhost',
  port: 8080,
  isActive: true,
  isSecure: false,
);
final mcpServerInactive = const McpServerConfig(
  id: 'mcp-inactive-1',
  name: 'MCP Inactive Server',
  connectionType: McpConnectionType.stdio,
  command: 'sleep',
  args: '5',
  isActive: false,
);

// Annotations to generate mocks
// We mock the GoogleMcpClient wrapper, not the underlying mcp_dart Client directly for simpler testing.
// We also mock the GeminiService and the McpServerConfigNotifier it depends on.
@GenerateMocks([
  McpServerConfigNotifier,
  GoogleMcpClient,
  GeminiService,
  // GenerativeModel, // Removed: Cannot mock final class 'GenerativeModel'
])
void main() {
  // --- Test Setup ---
  late MockMcpServerConfigNotifier mockMcpServerConfigNotifier;
  late MockGeminiService mockGeminiService;
  // late MockGenerativeModel mockGenerativeModel; // Removed
  late ProviderContainer container;
  // Declare the stream controller here
  late StreamController<List<McpServerConfig>> serverConfigStreamController;
  // Keep track of mocked clients created during tests
  final Map<String, MockGoogleMcpClient> mockClients = {};
  // Maps to capture callbacks for triggering in tests
  final Map<String, Function(String, String)?> capturedOnErrorCallbacks = {};
  final Map<String, Function(String)?> capturedOnCloseCallbacks = {};

  // Helper to create a mock client instance
  MockGoogleMcpClient createMockClient(String serverId, bool initiallyConnected) {
    final client = MockGoogleMcpClient();
    when(client.serverId).thenReturn(serverId);
    when(client.isConnected).thenReturn(initiallyConnected);
    when(client.availableTools).thenReturn([]); // Default to no tools
    // when(client.model).thenReturn(mockGenerativeModel); // Removed: Cannot mock final class
    // Default cleanup behavior
    when(client.cleanup()).thenAnswer((_) async {
      return;
    });
    // Default connect behavior (can be overridden per test)
    when(client.connectToServer(any)).thenAnswer((_) async {
      // Simulate successful connection by default in mock
      when(client.isConnected).thenReturn(true);
      return;
    });
    // Store callbacks for later triggering
    Function(String, String)? onErrorCallback;
    Function(String)? onCloseCallback;
    when(client.setupCallbacks(
      onError: anyNamed('onError'),
      onClose: anyNamed('onClose'),
    )).thenAnswer((invocation) {
      onErrorCallback = invocation.namedArguments[#onError];
      onCloseCallback = invocation.namedArguments[#onClose];
      // Capture callbacks for external triggering
      capturedOnErrorCallbacks[serverId] = onErrorCallback;
      capturedOnCloseCallbacks[serverId] = onCloseCallback;
    });
    // Add methods to trigger callbacks from tests if needed
    // client.triggerError = (String msg) => onErrorCallback?.call(serverId, msg); // Removed: Use capturedOnErrorCallbacks map
    // client.triggerClose = () => onCloseCallback?.call(serverId); // Removed: Use capturedOnCloseCallbacks map

    mockClients[serverId] = client;
    return client;
  }

  setUp(() {
    // Create fresh mocks for each test
    mockMcpServerConfigNotifier = MockMcpServerConfigNotifier();
    // Stub state IMMEDIATELY
    when(mockMcpServerConfigNotifier.state).thenReturn([]);
    // Stub debugState as well, as Riverpod might check it during init
    when(mockMcpServerConfigNotifier.debugState).thenReturn([]);

    mockGeminiService = MockGeminiService();
    // mockGenerativeModel = MockGenerativeModel(); // Removed
    mockClients.clear(); // Clear client map
    capturedOnErrorCallbacks.clear();
    capturedOnCloseCallbacks.clear();

    // Default behavior for mocks
    // McpServerConfigNotifier: Use streamController for updates
    serverConfigStreamController =
        StreamController<List<McpServerConfig>>.broadcast();
    when(
      mockMcpServerConfigNotifier.stream,
    ).thenAnswer((_) => serverConfigStreamController.stream);

    // ADD: Stub for addListener to satisfy ref.listen
    when(
      mockMcpServerConfigNotifier.addListener(
        any,
        fireImmediately: anyNamed('fireImmediately'),
      ),
    ).thenReturn(() {}); // Return a no-op RemoveListener

    // Initial state for the stream
    serverConfigStreamController.add([]);

    // GeminiService: Assume initialized by default, provide null for the model
    when(mockGeminiService.isInitialized).thenReturn(true);
    when(
      mockGeminiService.model,
    ).thenReturn(null); // Return null as GenerativeModel can't be mocked
    when(mockGeminiService.initializationError).thenReturn(null);

    // Create ProviderContainer with overrides
    container = ProviderContainer(
      overrides: [
        // Override the config *provider* to return the *notifier* mock
        mcpServerConfigProvider.overrideWith(
          (_) => mockMcpServerConfigNotifier,
        ), // Correct override for StateNotifierProvider
        geminiServiceProvider.overrideWithValue(mockGeminiService),
        // We don't override mcpClientProvider itself, but its dependencies
      ],
    );
  });

  tearDown(() {
    container.dispose();
    mockClients.clear();
    // Close the stream controller
    serverConfigStreamController.close();
  });

  // --- Test Groups ---

  group('McpClientNotifier Initialization and Sync', () {
    test('Initial state is correct with no servers', () {
      // Arrange (already done in setUp)

      // Act
      // Read the provider here to trigger initialization
      final state = container.read(mcpClientProvider);

      // Assert
      expect(state.serverConfigs, isEmpty);
      expect(state.serverStatuses, isEmpty);
      expect(state.activeClients, isEmpty);
      expect(state.serverErrorMessages, isEmpty);
      expect(state.hasActiveConnections, isFalse);
      expect(state.connectedServerCount, 0);
    });

    test('Initializes with server list from config provider', () async {
      // Arrange
      final initialConfigs = [mcpServerStdio, mcpServerInactive];
      // Update the mock *before* reading the provider
      when(mockMcpServerConfigNotifier.state).thenReturn(initialConfigs);
      serverConfigStreamController.add(initialConfigs);

      // Act: Re-read or trigger initialization if needed (depends on setup)
      // We might need a small delay or pump to ensure listener fires.
      // final state = container.read(mcpClientProvider); // Original line

      // Act: Read the provider to trigger initialization and initial sync logic
      final state = container.read(mcpClientProvider);
      // Allow microtasks like the initial sync to run
      await container.pump();


      // Assert: Initial status should be disconnected for all
      expect(state.serverConfigs, initialConfigs);
      expect(state.serverStatuses.length, 2);
      expect(state.serverStatuses[mcpServerStdio.id], McpConnectionStatus.disconnected);
      expect(state.serverStatuses[mcpServerInactive.id], McpConnectionStatus.disconnected);
      expect(state.activeClients, isEmpty); // No connections attempted yet by default
    });

    // Add more tests for syncConnections logic here...
    // - Connecting active servers
    // - Disconnecting inactive servers
    // - Handling server list updates (add/remove)
  });

  group('McpClientNotifier Connection Management', () {
    // Tests for connectServer, disconnectServer, handleClientError, handleClientClose
    // Need to mock GoogleMcpClient interactions

    test('connectServer successfully connects an active server', () async {
      // Arrange
      final config = mcpServerStdio.copyWith(isActive: true);
      when(mockMcpServerConfigNotifier.state).thenReturn([config]);
      serverConfigStreamController.add([config]); // Set initial config
      final notifier = container.read(mcpClientProvider.notifier);
      // ignore: unused_local_variable
      final mockClient = createMockClient(
        config.id,
        false,
      ); // Create mock client (will be used for verification later)

      // Mock the factory/constructor or inject the mock client instance
      // This is tricky without direct injection. We might need to adjust the service
      // or use a more complex mocking strategy if GoogleMcpClient isn't easily mockable.
      // For now, assume we can intercept/verify the call somehow or test side effects.

      // Initialize the provider before acting
      container.read(mcpClientProvider);
      await container.pump(); // Allow initialization microtasks

      // Act
      await notifier.connectServer(config);
      await container.pump(); // Allow futures to complete

      // Assert: Check state changes
      final state = container.read(mcpClientProvider);
      // Verify connectToServer was called on the (mocked) client
      // verify(mockClient.connectToServer(config)).called(1); // This requires intercepting creation
      expect(state.serverStatuses[config.id], McpConnectionStatus.connected);
      expect(state.activeClients.containsKey(config.id), isTrue); // Check if client added
      expect(state.serverErrorMessages[config.id], isNull);
    });

    // Add tests for:
    // - connectServer failure (e.g., connectToServer throws)
    // - disconnectServer behavior
    // - handleClientError -> error state + scheduleReconnect
    // - handleClientClose -> disconnected state + scheduleReconnect (if active)
  });

  group('McpClientNotifier Reconnection Logic', () {
    // Tests specifically for _scheduleReconnect and timer behavior
    // Requires FakeAsync or Timer mocking

    // testWidgets('onError triggers reconnection attempt after delay', (tester) async {
    //   await tester.runAsync((async) async {
    //     // Arrange: Setup with an active, connected server & mock client
    //     final config = mcpServerStdio.copyWith(isActive: true);
    //     mockMcpServerConfigNotifier.updateState([config]);
    //     final notifier = container.read(mcpClientProvider.notifier);
    //     final mockClient = createMockClient(config.id, true);
    //     // Assume client is already in state (needs setup adjustment)
    //     container.read(mcpClientProvider).activeClients[config.id] = mockClient;
    //     container.read(mcpClientProvider).serverStatuses[config.id] = McpConnectionStatus.connected;

    //     // Act: Trigger error
    //     mockClient.triggerError('Simulated connection error');
    //     await container.pump(); // Process error handler

    //     // Assert: Status becomes error
    //     expect(container.read(mcpClientProvider).serverStatuses[config.id], McpConnectionStatus.error);

    //     // Act: Advance time past the initial reconnect delay
    //     async.elapse(Duration(seconds: 6)); // More than initial 5s delay
    //     await container.pump();

    //     // Assert: connectServer should be called again (verify on mock/spy)
    //     // verify(notifier.connectServer(config)).called(1); // Need spy or mock setup
    //   });
    // });

    // Add tests for:
    // - onClose triggers reconnect
    // - Exponential backoff calculation
    // - Max reconnect delay respected
    // - Timer cancellation on disconnectServer
    // - Timer cancellation on server becoming inactive
  });

  group('McpClientNotifier Tool Management', () {
    // Tests for rebuildToolMap and processQuery (if testing here)
  });

  // Add more groups and tests as needed...
}

// Helper extension for ProviderContainer pump
extension PumpExtension on ProviderContainer {
  Future<void> pump() async {
    await Future.delayed(Duration.zero);
  }
}

// Helper extension for MockMcpServerConfigNotifier
// extension MockNotifierExtension on MockMcpServerConfigNotifier { // Removed: Caused assignment_to_method error
//   // Define a setter-like method to update state for tests
//   void updateState(List<McpServerConfig> newState) {
//     // This function body is defined within the setUp method
//     // where the stream controller is accessible.
//   }
// }

// Helper extension for MockGoogleMcpClient
// extension MockClientTriggerExtension on MockGoogleMcpClient { // Removed: Caused assignment_to_method error
//   void triggerError(String msg) {
//     // Defined in createMockClient
//   }
//   void triggerClose() {
//     // Defined in createMockClient
//   }
// }
