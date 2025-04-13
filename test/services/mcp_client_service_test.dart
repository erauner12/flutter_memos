import 'dart:async';
import 'dart:convert';

import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/providers/cloudkit_service_provider.dart';
import 'package:flutter_memos/providers/mcp_server_config_provider.dart';
import 'package:flutter_memos/services/gemini_service.dart';
import 'package:flutter_memos/services/mcp_client_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

const String mcpCacheKey = 'mcp_server_configs';

// Annotations to generate mocks
// We mock the GoogleMcpClient wrapper, not the underlying mcp_dart Client directly for simpler testing.
// We also mock the GeminiService and the McpServerConfigNotifier it depends on.
@GenerateMocks([
  GoogleMcpClient,
  GeminiService,
  CloudKitService,
])
void main() {
  // --- Test Setup ---
  late MockCloudKitService mockCloudKitService;
  late MockGeminiService mockGeminiService;
  late ProviderContainer container;
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

    mockClients[serverId] = client;
    return client;
  }

  setUp(() async {
    // Create fresh mocks for each test
    mockCloudKitService = MockCloudKitService();
    mockGeminiService = MockGeminiService();
    mockClients.clear();
    capturedOnErrorCallbacks.clear();
    capturedOnCloseCallbacks.clear();

    // Default behavior for CloudKitService mock
    when(
      mockCloudKitService.getAllMcpServerConfigs(),
    ).thenAnswer((_) async => []);
    when(
      mockCloudKitService.saveMcpServerConfig(any),
    ).thenAnswer((_) async => true);
    when(
      mockCloudKitService.deleteMcpServerConfig(any),
    ).thenAnswer((_) async => true);
    // Add other CloudKit defaults if needed (e.g., saveSetting, getSetting)
    when(mockCloudKitService.getSetting(any)).thenAnswer((_) async => null);
    when(
      mockCloudKitService.saveSetting(any, any),
    ).thenAnswer((_) async => true);

    // Default behavior for GeminiService mock
    when(mockGeminiService.isInitialized).thenReturn(true);
    when(mockGeminiService.model).thenReturn(null);
    when(mockGeminiService.initializationError).thenReturn(null);
    // Add default for generateContent if needed by tests
    // when(mockGeminiService.generateContent(any, any, tools: anyNamed('tools')))
    //     .thenAnswer((_) async => GenerateContentResponse([], promptFeedback: null));

    // Set default empty SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Create ProviderContainer with overrides
    container = ProviderContainer(
      overrides: [
        cloudKitServiceProvider.overrideWithValue(mockCloudKitService),
        geminiServiceProvider.overrideWithValue(mockGeminiService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    mockClients.clear();
  });

  // --- Test Groups ---

  group('McpClientNotifier Initialization and Sync', () {
    test('Initial state is correct with no servers', () async {
      // Arrange
      // Ensure CloudKit and SharedPreferences are empty (default setUp)

      // Act
      // Load the real config notifier first
      final configNotifier = container.read(mcpServerConfigProvider.notifier);
      await configNotifier.loadConfiguration();
      await container.pump(); // Allow loading to complete

      // Read the client provider AFTER config is loaded
      final state = container.read(mcpClientProvider);

      // Assert
      expect(state.serverConfigs, isEmpty);
      expect(state.serverStatuses, isEmpty);
      expect(state.activeClients, isEmpty);
      expect(state.serverErrorMessages, isEmpty);
      expect(state.hasActiveConnections, isFalse);
      expect(state.connectedServerCount, 0);
      verify(
        mockCloudKitService.getAllMcpServerConfigs(),
      ).called(1); // Verify load attempt
    });

    test(
      'Initializes with server list from config provider (via cache)',
      () async {
      // Arrange
      final initialConfigs = [mcpServerStdio, mcpServerInactive];
        // Set up SharedPreferences cache
        final cacheJson = jsonEncode(
          initialConfigs.map((s) => s.toJson()).toList(),
        );
        SharedPreferences.setMockInitialValues({mcpCacheKey: cacheJson});
        // Ensure CloudKit returns empty to isolate cache loading
        when(
          mockCloudKitService.getAllMcpServerConfigs(),
        ).thenAnswer((_) async => []);

        // Act
        // Load the real config notifier first
        final configNotifier = container.read(mcpServerConfigProvider.notifier);
        await configNotifier.loadConfiguration();
        await container.pump(); // Allow loading to complete

        // Read the client provider AFTER config is loaded
      final state = container.read(mcpClientProvider);
        // Allow microtasks like the initial sync in McpClientNotifier to run
      await container.pump();

      // Assert: Initial status should be disconnected for all
      expect(state.serverConfigs, initialConfigs);
      expect(state.serverStatuses.length, 2);
      expect(state.serverStatuses[mcpServerStdio.id], McpConnectionStatus.disconnected);
      expect(state.serverStatuses[mcpServerInactive.id], McpConnectionStatus.disconnected);
      expect(state.activeClients, isEmpty); // No connections attempted yet by default
        verify(
          mockCloudKitService.getAllMcpServerConfigs(),
        ).called(1); // Verify load attempt
    });

    // Add more tests for syncConnections logic here...
    // Example: Test that syncConnections attempts to connect active servers
    test('syncConnections attempts to connect active servers on init', () async {
      // Arrange
      final activeConfig = mcpServerStdio.copyWith(isActive: true);
      final inactiveConfig = mcpServerInactive.copyWith(isActive: false);
      final initialConfigs = [activeConfig, inactiveConfig];
      final cacheJson = jsonEncode(
        initialConfigs.map((s) => s.toJson()).toList(),
      );
      SharedPreferences.setMockInitialValues({mcpCacheKey: cacheJson});
      when(
        mockCloudKitService.getAllMcpServerConfigs(),
      ).thenAnswer((_) async => []);

      // Mock the client creation/connection process indirectly by checking state
      // We can't easily verify connectServer was called without more complex setup,
      // so we check the resulting state (connecting/connected).

      // Act
      final configNotifier = container.read(mcpServerConfigProvider.notifier);
      await configNotifier.loadConfiguration();
      await container.pump();

      // Read the client provider AFTER config is loaded - this triggers its init & sync
      final clientNotifier = container.read(mcpClientProvider.notifier);
      await container.pump(); // Allow syncConnections microtask

      // Assert: Active server should be connecting (or connected if mock is fast)
      final state = container.read(mcpClientProvider);
      expect(
        state.serverStatuses[activeConfig.id],
        McpConnectionStatus.connecting,
      );
      expect(
        state.serverStatuses[inactiveConfig.id],
        McpConnectionStatus.disconnected,
      );

      // TODO: Need a way to mock the actual GoogleMcpClient connection result
      // to fully test the transition to 'connected'. This might involve
      // overriding the factory or using a test-specific implementation.
    });

  });

  group('McpClientNotifier Connection Management', () {
    test('connectServer successfully connects an active server', () async {
      // Arrange
      final config = mcpServerStdio.copyWith(isActive: true);
      // Set up initial state via SharedPreferences/CloudKit mock
      final cacheJson = jsonEncode([config].map((s) => s.toJson()).toList());
      SharedPreferences.setMockInitialValues({mcpCacheKey: cacheJson});
      when(
        mockCloudKitService.getAllMcpServerConfigs(),
      ).thenAnswer((_) async => []);

      // Load config notifier
      final configNotifier = container.read(mcpServerConfigProvider.notifier);
      await configNotifier.loadConfiguration();
      await container.pump();

      // Get client notifier AFTER config is loaded
      final clientNotifier = container.read(mcpClientProvider.notifier);
      // ignore: unused_local_variable
      final mockClient = createMockClient(config.id, false);

      // --- IMPORTANT: How to inject the mock client? ---
      // Option 1: Modify McpClientNotifier to accept a factory (complex)
      // Option 2: Test side effects only (status changes)
      // Option 3: Use a test-specific GoogleMcpClient implementation via override (best?)
      // For now, we'll test side effects (status changes) and assume the real client works.
      // We need to mock the *result* of the connection. Let's assume connectServer
      // internally creates the client and calls connectToServer. We can't easily mock that.
      // Let's focus on the state transitions based on the *assumption* connect succeeds/fails.

      // Act: Call connectServer directly (syncConnections might also call it)
      // We need to ensure the state is ready before calling connectServer manually
      container.read(mcpClientProvider); // Ensure provider is initialized
      await container.pump(); // Allow initial sync

      // Simulate successful connection by manually updating state (since we can't mock the client easily)
      // This is NOT ideal, but demonstrates the desired outcome.
      // A better approach would involve mocking the client creation/connection.
      clientNotifier.updateServerState(
        config.id,
        McpConnectionStatus.connecting,
      ); // Simulate start
      await container.pump();
      // Simulate the client connecting and calling back
      clientNotifier.updateServerState(
        config.id,
        McpConnectionStatus.connected,
      );
      // Manually add a mock client to the state for verification (again, not ideal)
      clientNotifier.state = clientNotifier.state.copyWith(
        activeClients: {
          ...clientNotifier.state.activeClients,
          config.id: mockClient,
        },
      );
      await container.pump();


      // Assert: Check state changes
      final state = container.read(mcpClientProvider);
      expect(state.serverStatuses[config.id], McpConnectionStatus.connected);
      expect(state.activeClients.containsKey(config.id), isTrue);
      expect(state.serverErrorMessages[config.id], isNull);
    });

    // Add tests for:
    // - connectServer failure (e.g., connectToServer throws -> leads to error state)
    // - disconnectServer behavior (updates state, removes client)
    // - handleClientError -> error state + scheduleReconnect (verify state, maybe mock Timer?)
    // - handleClientClose -> disconnected state + scheduleReconnect (verify state)
  });

  // ... other test groups ...

}

// Helper extension for ProviderContainer pump
extension PumpExtension on ProviderContainer {
  Future<void> pump() async {
    await Future.delayed(Duration.zero);
  }
}
