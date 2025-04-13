import 'dart:convert';

import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/providers/mcp_server_config_provider.dart';
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import generated mocks
import 'mcp_server_config_notifier_test.mocks.dart';

// Define keys used in tests
const mcpCacheKey = 'mcp_server_config_cache';
const oldMcpPrefsKey = 'mcp_server_list'; // Match the constant in the notifier

// Sample McpServerConfig data for tests
final mcpServer1 = const McpServerConfig(
  id: 'mcp-id-1',
  name: 'MCP Server 1',
  connectionType: McpConnectionType.stdio,
  command: 'cmd1',
  args: 'arg1',
  isActive: true,
  customEnvironment: {'VAR1': 'VAL1'},
);
final mcpServer2 = const McpServerConfig(
  id: 'mcp-id-2',
  name: 'MCP Server 2',
  connectionType: McpConnectionType.sse,
  host: 'host2',
  port: 8002,
  isActive: false,
  isSecure: true,
);
final mcpServer1Updated = mcpServer1.copyWith(name: 'MCP Server 1 Updated', isActive: false);

// Annotations to generate mocks
@GenerateMocks([CloudKitService])
void main() {
  // --- Test Setup ---
  late MockCloudKitService mockCloudKitService;
  late ProviderContainer container;

  setUp(() async {
    // Create mocks
    mockCloudKitService = MockCloudKitService();

    // Clear SharedPreferences mock values before each test
    SharedPreferences.setMockInitialValues({});

    // Create ProviderContainer with overrides
    container = ProviderContainer(
      overrides: [
        cloudKitServiceProvider.overrideWithValue(mockCloudKitService),
      ],
    );

    // Default mock behavior for CloudKit MCP methods
    when(mockCloudKitService.getAllMcpServerConfigs()).thenAnswer((_) async => []);
    when(mockCloudKitService.saveMcpServerConfig(any)).thenAnswer((_) async => true);
    when(mockCloudKitService.deleteMcpServerConfig(any)).thenAnswer((_) async => true);
  });

  tearDown(() {
    container.dispose();
  });

  // --- Test Cases ---

  group('McpServerConfigNotifier', () {
    // --- loadConfiguration Tests ---
    group('loadConfiguration', () {
      test('Initial state is empty list when all sources are empty', () async {
        // Arrange: Mocks default to empty, Prefs empty

        // Act
        final notifier = container.read(mcpServerConfigProvider.notifier);
        await notifier.loadConfiguration(); // Explicitly call load
        await container.pump(); // Allow async operations to complete

        // Assert
        expect(notifier.state, isEmpty);
        verify(mockCloudKitService.getAllMcpServerConfigs()).called(1);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(mcpCacheKey), isNull);
        expect(prefs.getString(oldMcpPrefsKey), isNull);
      });

      test('Loads from cache when available, CloudKit empty', () async {
        // Arrange
        final initialServers = [mcpServer1];
        final cacheJson = jsonEncode(initialServers.map((s) => s.toJson()).toList());
        SharedPreferences.setMockInitialValues({mcpCacheKey: cacheJson});
        when(mockCloudKitService.getAllMcpServerConfigs()).thenAnswer((_) async => []); // CloudKit empty

        // Act
        final notifier = container.read(mcpServerConfigProvider.notifier);
        await notifier.loadConfiguration();
        await container.pump();

        // Assert: State should remain the cached value, not be cleared by empty CloudKit
        expect(notifier.state, initialServers); // MODIFY: Expect cached value
        verify(mockCloudKitService.getAllMcpServerConfigs()).called(1);
        // Should not attempt to migrate or upload if cache exists and CloudKit is empty
        verifyNever(mockCloudKitService.saveMcpServerConfig(any));
      });

      test('Loads from cache, CloudKit matches, no update needed', () async {
        // Arrange
        final initialServers = [mcpServer1, mcpServer2];
        final cacheJson = jsonEncode(initialServers.map((s) => s.toJson()).toList());
        SharedPreferences.setMockInitialValues({mcpCacheKey: cacheJson});
        when(mockCloudKitService.getAllMcpServerConfigs()).thenAnswer((_) async => initialServers); // CloudKit matches

        // Act
        final notifier = container.read(mcpServerConfigProvider.notifier);
        await notifier.loadConfiguration();
        await container.pump();

        // Assert
        expect(notifier.state, initialServers);
        verify(mockCloudKitService.getAllMcpServerConfigs()).called(1);
        verifyNever(
          mockCloudKitService.saveMcpServerConfig(any),
        ); // No upload needed
      });

      test(
        'Loads from cache, CloudKit differs, updates state and cache',
        () async {
        // Arrange
        final cachedServers = [mcpServer1];
        final cloudServers = [mcpServer1, mcpServer2]; // CloudKit has more data
        final cacheJson = jsonEncode(cachedServers.map((s) => s.toJson()).toList());
        SharedPreferences.setMockInitialValues({mcpCacheKey: cacheJson});
        when(mockCloudKitService.getAllMcpServerConfigs()).thenAnswer((_) async => cloudServers);

        // Act
        final notifier = container.read(mcpServerConfigProvider.notifier);
        await notifier.loadConfiguration();
        await container.pump();

        // Assert: State updated to CloudKit value
        expect(notifier.state, cloudServers);
        verify(mockCloudKitService.getAllMcpServerConfigs()).called(1);
        verifyNever(mockCloudKitService.saveMcpServerConfig(any)); // No upload needed

        // Verify cache was updated
        final prefs = await SharedPreferences.getInstance();
        final updatedCacheJson = prefs.getString(mcpCacheKey);
        expect(updatedCacheJson, isNotNull);
        final updatedCacheList = (jsonDecode(updatedCacheJson!) as List)
            .map((item) => McpServerConfig.fromJson(item as Map<String, dynamic>))
            .toList();
        expect(updatedCacheList, cloudServers);
      });

      test('Migrates from old SharedPreferences key when cache empty, CloudKit empty', () async {
        // Arrange: Cache empty, Prefs has value, CloudKit empty
        final oldServers = [mcpServer1];
        final oldPrefsJson = jsonEncode(oldServers.map((s) => s.toJson()).toList());
        SharedPreferences.setMockInitialValues({oldMcpPrefsKey: oldPrefsJson});
        when(mockCloudKitService.getAllMcpServerConfigs()).thenAnswer((_) async => []);

        // Act
        final notifier = container.read(mcpServerConfigProvider.notifier);
        await notifier.loadConfiguration();
        await container.pump(); // Allow async operations

          // Assert: State loaded from old prefs initially, should remain that value
          // even though CloudKit returned empty.
          expect(notifier.state, oldServers); // MODIFY: Expect migrated value
        verify(mockCloudKitService.getAllMcpServerConfigs()).called(1);

        // Assert Migration actions:
        // 1. Upload to CloudKit (verify for each server)
        verify(mockCloudKitService.saveMcpServerConfig(mcpServer1)).called(1);
        // 2. Write to new cache key
        final prefs = await SharedPreferences.getInstance();
        final newCacheJson = prefs.getString(mcpCacheKey);
        expect(newCacheJson, isNotNull);
        expect(
          (jsonDecode(newCacheJson!) as List).map((i) => McpServerConfig.fromJson(i)).toList(),
          oldServers,
        );
        // 3. Remove from old SharedPreferences key
        expect(prefs.getString(oldMcpPrefsKey), isNull);
      });

      test(
        'Migrates from old prefs, CloudKit has different data, uses CloudKit data',
        () async {
        // Arrange: Cache empty, Prefs has value, CloudKit has different value
        final oldServers = [mcpServer1];
        final cloudServers = [mcpServer2]; // CloudKit has different data
        final oldPrefsJson = jsonEncode(oldServers.map((s) => s.toJson()).toList());
        SharedPreferences.setMockInitialValues({oldMcpPrefsKey: oldPrefsJson});
        when(mockCloudKitService.getAllMcpServerConfigs()).thenAnswer((_) async => cloudServers);

        // Act
        final notifier = container.read(mcpServerConfigProvider.notifier);
        await notifier.loadConfiguration();
        await container.pump();

        // Assert: State loaded from old prefs initially, then updated to CloudKit value
        expect(notifier.state, cloudServers);
        verify(mockCloudKitService.getAllMcpServerConfigs()).called(1);

        // Assert Migration actions:
        // 1. Upload of OLD data to CloudKit should still happen in background
        verify(mockCloudKitService.saveMcpServerConfig(mcpServer1)).called(1);
        // 2. Write CloudKit value to new cache key
        final prefs = await SharedPreferences.getInstance();
        final newCacheJson = prefs.getString(mcpCacheKey);
        expect(newCacheJson, isNotNull);
        expect(
          (jsonDecode(newCacheJson!) as List).map((i) => McpServerConfig.fromJson(i)).toList(),
          cloudServers, // Cache should have CloudKit data
        );
        // 3. Remove from old SharedPreferences key
        expect(prefs.getString(oldMcpPrefsKey), isNull);
      });

      test('Loads from CloudKit when cache and old prefs are empty', () async {
        // Arrange: Cache empty, Prefs empty, CloudKit has value
        final cloudServers = [mcpServer1, mcpServer2];
        SharedPreferences.setMockInitialValues({});
        when(mockCloudKitService.getAllMcpServerConfigs()).thenAnswer((_) async => cloudServers);

        // Act
        final notifier = container.read(mcpServerConfigProvider.notifier);
        await notifier.loadConfiguration();
        await container.pump();

        // Assert: State updated from CloudKit
        expect(notifier.state, cloudServers);
        verify(mockCloudKitService.getAllMcpServerConfigs()).called(1);
        // Cache should be updated with CloudKit value
        final prefs = await SharedPreferences.getInstance();
        final newCacheJson = prefs.getString(mcpCacheKey);
        expect(newCacheJson, isNotNull);
        expect(
          (jsonDecode(newCacheJson!) as List).map((i) => McpServerConfig.fromJson(i)).toList(),
          cloudServers,
        );
        verifyNever(mockCloudKitService.saveMcpServerConfig(any)); // No upload needed
      });

      test('Handles CloudKit error gracefully, uses local value (cache)', () async {
        // Arrange
        final cachedServers = [mcpServer1];
        final cacheJson = jsonEncode(cachedServers.map((s) => s.toJson()).toList());
        SharedPreferences.setMockInitialValues({mcpCacheKey: cacheJson});
        when(mockCloudKitService.getAllMcpServerConfigs()).thenThrow(Exception('Network Error'));

        // Act
        final notifier = container.read(mcpServerConfigProvider.notifier);
        await notifier.loadConfiguration();
        await container.pump();

        // Assert: State remains from cache
        expect(notifier.state, cachedServers);
        verify(mockCloudKitService.getAllMcpServerConfigs()).called(1); // Attempted
        verifyNever(mockCloudKitService.saveMcpServerConfig(any));
      });

      test(
        'Handles CloudKit error during migration, uses local value (old prefs), cleans up old key',
        () async {
        // Arrange: Cache empty, Prefs has value, CloudKit fails
        final oldServers = [mcpServer1];
        final oldPrefsJson = jsonEncode(oldServers.map((s) => s.toJson()).toList());
        SharedPreferences.setMockInitialValues({oldMcpPrefsKey: oldPrefsJson});
        when(mockCloudKitService.getAllMcpServerConfigs()).thenThrow(Exception('Network Error'));

        // Act
        final notifier = container.read(mcpServerConfigProvider.notifier);
        await notifier.loadConfiguration();
        await container.pump();

        // Assert: State remains from old Prefs
        expect(notifier.state, oldServers);
        verify(mockCloudKitService.getAllMcpServerConfigs()).called(1); // Attempted

        // Assert Migration actions (partial):
        // 1. CloudKit upload attempt fails (implicitly tested by error)
        verifyNever(mockCloudKitService.saveMcpServerConfig(any));
        // 2. Write to new cache key SHOULD happen during cleanup
        final prefs = await SharedPreferences.getInstance();
        final newCacheJson = prefs.getString(mcpCacheKey);
        expect(newCacheJson, isNotNull);
        expect(
          (jsonDecode(newCacheJson!) as List).map((i) => McpServerConfig.fromJson(i)).toList(),
          oldServers,
        );
        // 3. Remove from old SharedPreferences key (SHOULD happen in cleanup)
        expect(prefs.getString(oldMcpPrefsKey), isNull);
      });
    });

    // --- addServer Tests ---
    group('addServer', () {
      test(
        'Adds server successfully, updates state, cache, and CloudKit',
        () async {
        // Arrange
        final notifier = container.read(mcpServerConfigProvider.notifier);
        await notifier.loadConfiguration(); // Start empty
        await container.pump();
        when(mockCloudKitService.saveMcpServerConfig(mcpServer1)).thenAnswer((_) async => true);

        // Act
        final success = await notifier.addServer(mcpServer1);
        await container.pump();

        // Assert
        expect(success, isTrue);
        expect(notifier.state, [mcpServer1]);
        verify(mockCloudKitService.saveMcpServerConfig(mcpServer1)).called(1);
        // Verify cache update
        final prefs = await SharedPreferences.getInstance();
        final cacheJson = prefs.getString(mcpCacheKey);
        expect(cacheJson, isNotNull);
        expect(
          (jsonDecode(cacheJson!) as List).map((i) => McpServerConfig.fromJson(i)).toList(),
          [mcpServer1],
        );
      });

      test('Fails to add server if CloudKit save fails', () async {
        // Arrange
        final notifier = container.read(mcpServerConfigProvider.notifier);
        await notifier.loadConfiguration();
        await container.pump();
        when(mockCloudKitService.saveMcpServerConfig(mcpServer1)).thenAnswer((_) async => false); // CloudKit fails

        // Act
        final success = await notifier.addServer(mcpServer1);
        await container.pump();

        // Assert
        expect(success, isFalse);
        expect(notifier.state, isEmpty); // State should not change
        verify(mockCloudKitService.saveMcpServerConfig(mcpServer1)).called(1);
        // Verify cache was not updated
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(mcpCacheKey), isNull);
      });

      test('Does not add server if ID already exists', () async {
        // Arrange
        final notifier = container.read(mcpServerConfigProvider.notifier);
        // Preload state with server1
        notifier.state = [mcpServer1];
        await container.pump();

        // Act
        final success = await notifier.addServer(mcpServer1.copyWith(name: "Duplicate ID")); // Same ID
        await container.pump();

        // Assert
        expect(success, isFalse);
        expect(notifier.state, [mcpServer1]); // State unchanged
        verifyNever(mockCloudKitService.saveMcpServerConfig(any)); // Should not attempt save
      });
    });

    // --- updateServer Tests ---
    group('updateServer', () {
      test('Updates server successfully, updates state, cache, and CloudKit', () async {
        // Arrange
        final notifier = container.read(mcpServerConfigProvider.notifier);
        notifier.state = [mcpServer1, mcpServer2]; // Initial state
        await container.pump();
        when(mockCloudKitService.saveMcpServerConfig(mcpServer1Updated)).thenAnswer((_) async => true);

        // Act
        final success = await notifier.updateServer(mcpServer1Updated);
        await container.pump();

        // Assert
        expect(success, isTrue);
        expect(notifier.state, [mcpServer1Updated, mcpServer2]); // Check updated list
        verify(mockCloudKitService.saveMcpServerConfig(mcpServer1Updated)).called(1);
        // Verify cache update
        final prefs = await SharedPreferences.getInstance();
        final cacheJson = prefs.getString(mcpCacheKey);
        expect(cacheJson, isNotNull);
        expect(
          (jsonDecode(cacheJson!) as List).map((i) => McpServerConfig.fromJson(i)).toList(),
          [mcpServer1Updated, mcpServer2],
        );
      });

      test('Fails to update server if CloudKit save fails', () async {
        // Arrange
        final notifier = container.read(mcpServerConfigProvider.notifier);
        notifier.state = [mcpServer1, mcpServer2];
        await container.pump();
        when(mockCloudKitService.saveMcpServerConfig(mcpServer1Updated)).thenAnswer((_) async => false); // CloudKit fails

        // Act
        final success = await notifier.updateServer(mcpServer1Updated);
        await container.pump();

        // Assert
        expect(success, isFalse);
        expect(notifier.state, [mcpServer1, mcpServer2]); // State should not change
        verify(mockCloudKitService.saveMcpServerConfig(mcpServer1Updated)).called(1);
        // Verify cache was not updated (check initial state)
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(mcpCacheKey), isNull); // Cache wasn't written initially
      });

      test('Fails to update server if ID does not exist', () async {
        // Arrange
        final notifier = container.read(mcpServerConfigProvider.notifier);
        notifier.state = [mcpServer2]; // Only server 2 exists
        await container.pump();
        final nonExistentUpdate = mcpServer1.copyWith(name: "Non Existent");

        // Act
        final success = await notifier.updateServer(nonExistentUpdate);
        await container.pump();

        // Assert
        expect(success, isFalse);
        expect(notifier.state, [mcpServer2]); // State unchanged
        verifyNever(mockCloudKitService.saveMcpServerConfig(any)); // Should not attempt save
      });
    });

    // --- removeServer Tests ---
    group('removeServer', () {
      test(
        'Removes server successfully, updates state, cache, and CloudKit',
        () async {
        // Arrange
        final notifier = container.read(mcpServerConfigProvider.notifier);
        notifier.state = [mcpServer1, mcpServer2]; // Initial state
        await container.pump();
        when(mockCloudKitService.deleteMcpServerConfig(mcpServer1.id)).thenAnswer((_) async => true);

        // Act
        final success = await notifier.removeServer(mcpServer1.id);
        await container.pump();

        // Assert
        expect(success, isTrue);
        expect(notifier.state, [mcpServer2]); // Check updated list
        verify(mockCloudKitService.deleteMcpServerConfig(mcpServer1.id)).called(1);
        // Verify cache update
        final prefs = await SharedPreferences.getInstance();
        final cacheJson = prefs.getString(mcpCacheKey);
        expect(cacheJson, isNotNull);
        expect(
          (jsonDecode(cacheJson!) as List).map((i) => McpServerConfig.fromJson(i)).toList(),
          [mcpServer2],
        );
      });

      test('Fails to remove server if CloudKit delete fails', () async {
        // Arrange
        final notifier = container.read(mcpServerConfigProvider.notifier);
        notifier.state = [mcpServer1, mcpServer2];
        await container.pump();
        when(mockCloudKitService.deleteMcpServerConfig(mcpServer1.id)).thenAnswer((_) async => false); // CloudKit fails

        // Act
        final success = await notifier.removeServer(mcpServer1.id);
        await container.pump();

        // Assert
        expect(success, isFalse);
        expect(notifier.state, [mcpServer1, mcpServer2]); // State should not change
        verify(mockCloudKitService.deleteMcpServerConfig(mcpServer1.id)).called(1);
        // Verify cache was not updated
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(mcpCacheKey), isNull);
      });

      test('Fails to remove server if ID does not exist', () async {
        // Arrange
        final notifier = container.read(mcpServerConfigProvider.notifier);
        notifier.state = [mcpServer2]; // Only server 2 exists
        await container.pump();

        // Act
        final success = await notifier.removeServer(mcpServer1.id); // Try to remove server 1
        await container.pump();

        // Assert
        expect(success, isFalse);
        expect(notifier.state, [mcpServer2]); // State unchanged
        verifyNever(mockCloudKitService.deleteMcpServerConfig(any)); // Should not attempt delete
      });
    });

    // --- toggleServerActive Tests ---
    group('toggleServerActive', () {
      test('Toggles isActive successfully via updateServer', () async {
        // Arrange
        final notifier = container.read(mcpServerConfigProvider.notifier);
        notifier.state = [mcpServer1]; // Initial state (isActive: true)
        await container.pump();
        final expectedUpdatedConfig = mcpServer1.copyWith(isActive: false);
        // Mock the underlying updateServer call (which saveMcpServerConfig triggers)
        when(mockCloudKitService.saveMcpServerConfig(expectedUpdatedConfig)).thenAnswer((_) async => true);

        // Act
        final success = await notifier.toggleServerActive(mcpServer1.id, false); // Toggle to false
        await container.pump();

        // Assert
        expect(success, isTrue);
        expect(notifier.state, [expectedUpdatedConfig]); // Check state updated
        // Verify that saveMcpServerConfig was called by updateServer
        verify(mockCloudKitService.saveMcpServerConfig(expectedUpdatedConfig)).called(1);
      });

      test('Fails to toggle isActive if updateServer fails', () async {
        // Arrange
        final notifier = container.read(mcpServerConfigProvider.notifier);
        notifier.state = [mcpServer1];
        await container.pump();
        final expectedUpdatedConfig = mcpServer1.copyWith(isActive: false);
        // Mock the underlying updateServer call to fail
        when(mockCloudKitService.saveMcpServerConfig(expectedUpdatedConfig)).thenAnswer((_) async => false);

        // Act
        final success = await notifier.toggleServerActive(mcpServer1.id, false);
        await container.pump();

        // Assert
        expect(success, isFalse);
        expect(notifier.state, [mcpServer1]); // State should not change
        verify(mockCloudKitService.saveMcpServerConfig(expectedUpdatedConfig)).called(1);
      });

      test('Fails to toggle isActive if server ID does not exist', () async {
        // Arrange
        final notifier = container.read(mcpServerConfigProvider.notifier);
        notifier.state = [mcpServer2]; // Only server 2 exists
        await container.pump();

        // Act
        final success = await notifier.toggleServerActive(mcpServer1.id, true); // Try to toggle server 1
        await container.pump();

        // Assert
        expect(success, isFalse);
        expect(notifier.state, [mcpServer2]); // State unchanged
        verifyNever(mockCloudKitService.saveMcpServerConfig(any)); // Should not attempt save
      });
    });
  });
}

// Helper extension for pumping futures in tests
extension PumpExtension on ProviderContainer {
  Future<void> pump() async {
    await Future.delayed(Duration.zero);
  }
}
