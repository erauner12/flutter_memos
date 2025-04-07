import 'package:flutter_memos/models/multi_server_config_state.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Constants for SharedPreferences keys
const _multiServerConfigKey = 'multi_server_config';
const _legacyServerUrlKey = 'server_url';
const _legacyAuthTokenKey = 'auth_token';

void main() {
  group('MultiServerConfigNotifier', () {
    late ProviderContainer container;
    late MultiServerConfigNotifier notifier;
    late ServerConfig server1;
    late ServerConfig server2;

    setUp(() {
      // Clear any existing mock preferences before each test
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      notifier = container.read(multiServerConfigProvider.notifier);
      server1 = ServerConfig(
        id: const Uuid().v4(),
        name: 'Server One',
        serverUrl: 'https://server1.example.com',
        authToken: 'token1',
      );
      server2 = ServerConfig(
        id: const Uuid().v4(),
        name: 'Server Two',
        serverUrl: 'https://server2.example.com',
        authToken: 'token2',
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is empty', () {
      expect(notifier.state.servers, isEmpty);
      expect(notifier.state.activeServerId, isNull);
      expect(notifier.state.defaultServerId, isNull);
    });

    test('Loads empty state when prefs are empty', () async {
      await notifier.loadFromPreferences();
      expect(notifier.state.servers, isEmpty);
      expect(notifier.state.activeServerId, isNull);
      expect(notifier.state.defaultServerId, isNull);
    });

    test('Migrates legacy config correctly', () async {
      // Set up legacy preferences
      SharedPreferences.setMockInitialValues({
        _legacyServerUrlKey: 'https://legacy.example.com',
        _legacyAuthTokenKey: 'legacy_token',
      });

      await notifier.loadFromPreferences();

      expect(notifier.state.servers, hasLength(1));
      final migratedServer = notifier.state.servers.first;
      expect(migratedServer.serverUrl, 'https://legacy.example.com');
      expect(migratedServer.authToken, 'legacy_token');
      expect(migratedServer.name, 'Migrated Server');
      expect(notifier.state.defaultServerId, migratedServer.id);
      expect(notifier.state.activeServerId, migratedServer.id); // Active is set from default on load

      // Verify saved state in prefs
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_multiServerConfigKey);
      expect(jsonString, isNotNull);
      final savedState = MultiServerConfigState.fromJsonString(jsonString!);
      expect(savedState.servers, hasLength(1));
      expect(savedState.defaultServerId, migratedServer.id);
      expect(savedState.activeServerId, isNull); // Active ID is not saved
    });

     test('Loads existing multi-server config correctly', () async {
      final initialState = MultiServerConfigState(
        servers: [server1, server2],
        defaultServerId: server2.id,
      );
      // Save initial state to prefs (excluding activeId)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_multiServerConfigKey, initialState.toJsonString());

      await notifier.loadFromPreferences();

      expect(notifier.state.servers, hasLength(2));
      expect(notifier.state.servers, contains(server1));
      expect(notifier.state.servers, contains(server2));
      expect(notifier.state.defaultServerId, server2.id);
      expect(notifier.state.activeServerId, server2.id); // Active set from default
    });

    test('Adds first server and sets as active/default', () async {
      final success = await notifier.addServer(server1);
      expect(success, isTrue);
      expect(notifier.state.servers, [server1]);
      expect(notifier.state.activeServerId, server1.id);
      expect(notifier.state.defaultServerId, server1.id);

      // Verify saved state
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_multiServerConfigKey);
      expect(jsonString, isNotNull);
      final savedState = MultiServerConfigState.fromJsonString(jsonString!);
      expect(savedState.servers, [server1]);
      expect(savedState.defaultServerId, server1.id);
    });

    test('Adds subsequent server without changing active/default', () async {
      await notifier.addServer(server1); // Add first server
      final success = await notifier.addServer(server2); // Add second server

      expect(success, isTrue);
      expect(notifier.state.servers, [server1, server2]);
      expect(notifier.state.activeServerId, server1.id); // Remains server1
      expect(notifier.state.defaultServerId, server1.id); // Remains server1

      // Verify saved state
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_multiServerConfigKey);
      expect(jsonString, isNotNull);
      final savedState = MultiServerConfigState.fromJsonString(jsonString!);
      expect(savedState.servers, [server1, server2]);
      expect(savedState.defaultServerId, server1.id);
    });

    test('Updates an existing server', () async {
      await notifier.addServer(server1);
      final updatedServer1 = server1.copyWith(name: 'Updated Server One');
      final success = await notifier.updateServer(updatedServer1);

      expect(success, isTrue);
      expect(notifier.state.servers, [updatedServer1]);
      expect(notifier.state.activeServerId, updatedServer1.id);
      expect(notifier.state.defaultServerId, updatedServer1.id);

      // Verify saved state
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_multiServerConfigKey);
      expect(jsonString, isNotNull);
      final savedState = MultiServerConfigState.fromJsonString(jsonString!);
      expect(savedState.servers, [updatedServer1]);
      expect(savedState.defaultServerId, updatedServer1.id);
    });

    test('Removes a server (not active/default)', () async {
      await notifier.addServer(server1);
      await notifier.addServer(server2);
      final success = await notifier.removeServer(server2.id);

      expect(success, isTrue);
      expect(notifier.state.servers, [server1]);
      expect(notifier.state.activeServerId, server1.id);
      expect(notifier.state.defaultServerId, server1.id);

      // Verify saved state
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_multiServerConfigKey);
      expect(jsonString, isNotNull);
      final savedState = MultiServerConfigState.fromJsonString(jsonString!);
      expect(savedState.servers, [server1]);
      expect(savedState.defaultServerId, server1.id);
    });

    test('Removes the active and default server', () async {
      await notifier.addServer(server1);
      await notifier.addServer(server2);
      await notifier.setDefaultServer(server2.id); // Make server2 default
      notifier.setActiveServer(server2.id); // Make server2 active

      final success = await notifier.removeServer(server2.id);

      expect(success, isTrue);
      expect(notifier.state.servers, [server1]);
      expect(notifier.state.activeServerId, server1.id); // Falls back to server1
      expect(notifier.state.defaultServerId, server1.id); // Falls back to server1

      // Verify saved state
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_multiServerConfigKey);
      expect(jsonString, isNotNull);
      final savedState = MultiServerConfigState.fromJsonString(jsonString!);
      expect(savedState.servers, [server1]);
      expect(savedState.defaultServerId, server1.id);
    });

     test('Removes the only server', () async {
      await notifier.addServer(server1);
      final success = await notifier.removeServer(server1.id);

      expect(success, isTrue);
      expect(notifier.state.servers, isEmpty);
      expect(notifier.state.activeServerId, isNull);
      expect(notifier.state.defaultServerId, isNull);

      // Verify saved state
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_multiServerConfigKey);
      expect(jsonString, isNotNull);
      final savedState = MultiServerConfigState.fromJsonString(jsonString!);
      expect(savedState.servers, isEmpty);
      expect(savedState.defaultServerId, isNull);
    });

    test('Sets active server (ephemeral)', () async {
      await notifier.addServer(server1);
      await notifier.addServer(server2);

      notifier.setActiveServer(server2.id);
      expect(notifier.state.activeServerId, server2.id);
      expect(notifier.state.defaultServerId, server1.id); // Default unchanged

      // Verify active ID is NOT saved
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_multiServerConfigKey);
      expect(jsonString, isNotNull);
      final savedState = MultiServerConfigState.fromJsonString(jsonString!);
      expect(savedState.defaultServerId, server1.id); // Default is saved
      expect(savedState.activeServerId, isNull); // Active is not
    });

    test('Sets default server (persistent)', () async {
      await notifier.addServer(server1);
      await notifier.addServer(server2);

      final success = await notifier.setDefaultServer(server2.id);
      expect(success, isTrue);
      expect(notifier.state.activeServerId, server1.id); // Active unchanged
      expect(notifier.state.defaultServerId, server2.id); // Default changed

      // Verify default ID IS saved
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_multiServerConfigKey);
      expect(jsonString, isNotNull);
      final savedState = MultiServerConfigState.fromJsonString(jsonString!);
      expect(savedState.defaultServerId, server2.id); // Default is saved
    });

     test('Unsets default server', () async {
      await notifier.addServer(server1);
      await notifier.setDefaultServer(server1.id);
      expect(notifier.state.defaultServerId, server1.id);

      final success = await notifier.setDefaultServer(null);
      expect(success, isTrue);
      expect(notifier.state.defaultServerId, isNull);

      // Verify saved state
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_multiServerConfigKey);
      expect(jsonString, isNotNull);
      final savedState = MultiServerConfigState.fromJsonString(jsonString!);
      expect(savedState.defaultServerId, isNull);
    });

    test('activeServerConfigProvider returns correct active server', () async {
      await notifier.addServer(server1);
      await notifier.addServer(server2);
      notifier.setActiveServer(server2.id);

      final activeConfig = container.read(activeServerConfigProvider);
      expect(activeConfig, isNotNull);
      expect(activeConfig, server2);
    });

     test('activeServerConfigProvider returns null when no active server', () async {
      await notifier.addServer(server1);
      notifier.setActiveServer(null); // Explicitly set active to null

      final activeConfig = container.read(activeServerConfigProvider);
      expect(activeConfig, isNull);
    });

     test('activeServerConfigProvider returns null when active ID is invalid', () async {
      await notifier.addServer(server1);
      // Manually set state to an invalid active ID
      notifier.state = notifier.state.copyWith(activeServerId: 'invalid-id');

      final activeConfig = container.read(activeServerConfigProvider);
      expect(activeConfig, isNull);
    });
  });
}
