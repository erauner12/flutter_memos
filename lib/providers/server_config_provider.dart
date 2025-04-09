import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/multi_server_config_state.dart'; // Import new state model
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart'; // Import Uuid

const _multiServerConfigKey = 'multi_server_config';
const _legacyServerUrlKey = 'server_url';
const _legacyAuthTokenKey = 'auth_token';

/// Notifier for managing multiple server configurations with persistence
class MultiServerConfigNotifier extends StateNotifier<MultiServerConfigState> {
  MultiServerConfigNotifier() : super(const MultiServerConfigState());

  /// Load configuration from SharedPreferences, handling migration from legacy keys
  Future<void> loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_multiServerConfigKey);
      MultiServerConfigState loadedState;

      if (jsonString != null) {
        // Load existing multi-server config
        loadedState = MultiServerConfigState.fromJsonString(jsonString);
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] Loaded multi-server config: ${loadedState.servers.length} servers.',
          );
        }
      } else {
        // Check for legacy single-server config for migration
        final legacyUrl = prefs.getString(_legacyServerUrlKey);
        final legacyToken = prefs.getString(_legacyAuthTokenKey);

        if (legacyUrl != null && legacyUrl.isNotEmpty) {
          // Migrate legacy config
          final migratedServer = ServerConfig(
            id: const Uuid().v4(), // Generate new ID
            name: 'Migrated Server', // Assign a default name
            serverUrl: legacyUrl,
            authToken: legacyToken ?? '',
          );
          loadedState = MultiServerConfigState(
            servers: [migratedServer],
            defaultServerId: migratedServer.id, // Set migrated as default
          );
          if (kDebugMode) {
            print(
              '[MultiServerConfigNotifier] Migrated legacy config to server ID: ${migratedServer.id}',
            );
          }
          // Optionally remove legacy keys after successful migration
          // await prefs.remove(_legacyServerUrlKey);
          // await prefs.remove(_legacyAuthTokenKey);
          // Save the migrated state immediately
          await _saveStateToPreferences(loadedState);
        } else {
          // No existing config found
          loadedState = const MultiServerConfigState();
          if (kDebugMode) {
            print('[MultiServerConfigNotifier] No existing config found.');
          }
        }
      }

      // Set the active server based on the default, or the first available
      String? newActiveServerId = loadedState.defaultServerId;
      if (newActiveServerId == null && loadedState.servers.isNotEmpty) {
        newActiveServerId = loadedState.servers.first.id;
      }

      // Ensure the active ID actually exists in the list
      if (newActiveServerId != null &&
          !loadedState.servers.any((s) => s.id == newActiveServerId)) {
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] Warning: Default/Active server ID $newActiveServerId not found in list. Resetting active server.',
          );
        }
        newActiveServerId = loadedState.servers.firstOrNull?.id;
      }

      state = loadedState.copyWith(activeServerId: newActiveServerId);

      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier][loadFromPreferences] Final state: ${state.servers.length} servers, activeId=${state.activeServerId}, defaultId=${state.defaultServerId}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[MultiServerConfigNotifier][loadFromPreferences] Error: $e');
      }
      // Keep the default empty state on error
      state = const MultiServerConfigState();
    }
  }

  /// Save the current state to SharedPreferences
  Future<bool> _saveStateToPreferences(
    MultiServerConfigState stateToSave,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Persist only servers and defaultServerId
      final persistentState = MultiServerConfigState(
        servers: stateToSave.servers,
        defaultServerId: stateToSave.defaultServerId,
        activeServerId: null, // Don't save active ID
      );
      final jsonString = persistentState.toJsonString();
      final success = await prefs.setString(_multiServerConfigKey, jsonString);
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier][_saveStateToPreferences] Saved state (success: $success). Default ID: ${persistentState.defaultServerId}',
        );
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('[MultiServerConfigNotifier][_saveStateToPreferences] Error: $e');
      }
      return false;
    }
  }

  /// Add a new server configuration
  Future<bool> addServer(ServerConfig config) async {
    if (state.servers.any((s) => s.id == config.id)) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Attempted to add server with duplicate ID: ${config.id}',
        );
      }
      return false; // Or handle update? For now, prevent duplicates.
    }

    final newServers = [...state.servers, config];
    String? newDefaultId = state.defaultServerId;
    String? newActiveId = state.activeServerId;

    // If this is the first server, make it default and active
    if (newServers.length == 1) {
      newDefaultId = config.id;
      newActiveId = config.id;
    }

    final newState = state.copyWith(
      servers: newServers,
      defaultServerId: () => newDefaultId, // Use ValueGetter for nullable
      activeServerId: newActiveId,
    );
    state = newState; // Update local state immediately
    return _saveStateToPreferences(newState); // Persist changes
  }

  /// Update an existing server configuration
  Future<bool> updateServer(ServerConfig updatedConfig) async {
    final index = state.servers.indexWhere((s) => s.id == updatedConfig.id);
    if (index == -1) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Attempted to update non-existent server ID: ${updatedConfig.id}',
        );
      }
      return false;
    }

    final newServers = [...state.servers];
    newServers[index] = updatedConfig;

    final newState = state.copyWith(servers: newServers);
    state = newState; // Update local state
    return _saveStateToPreferences(newState); // Persist changes
  }

  /// Remove a server configuration by ID
  Future<bool> removeServer(String serverId) async {
    final initialServerCount = state.servers.length;
    final newServers = state.servers.where((s) => s.id != serverId).toList();
    if (newServers.length == initialServerCount) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Attempted to remove non-existent server ID: $serverId',
        );
      }
      return false; // Server ID not found
    }

    String? newDefaultId = state.defaultServerId;
    String? newActiveId = state.activeServerId;

    // Check if the list is now empty
    if (newServers.isEmpty) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Removed the last server. Resetting active and default IDs.',
        );
      }
      newDefaultId = null;
      newActiveId = null;
    } else {
      // If the removed server was the default, clear default or pick the first remaining
      if (state.defaultServerId == serverId) {
        newDefaultId =
            newServers.first.id; // Pick the first remaining as new default
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] Removed default server $serverId. Setting new default to $newDefaultId.',
          );
        }
      }

      // If the removed server was active, set active to the new default (or first if default was also removed)
      if (state.activeServerId == serverId) {
        newActiveId =
            newDefaultId ??
            newServers
                .first
                .id; // Fallback to first if newDefaultId is somehow null
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] Removed active server $serverId. Setting new active to $newActiveId.',
          );
        }
      }
    }

    final newState = state.copyWith(
      servers: newServers,
      defaultServerId: () => newDefaultId, // Use ValueGetter
      activeServerId: newActiveId,
    );
    state = newState; // Update local state
    return _saveStateToPreferences(newState); // Persist changes
  }

  /// Set the active server for the current session
  void setActiveServer(String? serverId) {
    if (serverId != null && !state.servers.any((s) => s.id == serverId)) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Attempted to set active server to non-existent ID: $serverId',
        );
      }
      return;
    }
    if (state.activeServerId != serverId) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Setting active server ID to: $serverId',
        );
      }
      state = state.copyWith(activeServerId: serverId);
      // Do NOT save preferences here, active state is ephemeral
    }
  }

  /// Set the default server (will be activated on next load)
  Future<bool> setDefaultServer(String? serverId) async {
    if (serverId != null && !state.servers.any((s) => s.id == serverId)) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Attempted to set default server to non-existent ID: $serverId',
        );
      }
      return false;
    }
    if (state.defaultServerId != serverId) {
      final newState = state.copyWith(
        defaultServerId: () => serverId,
      ); // Use ValueGetter
      state = newState; // Update local state
      return _saveStateToPreferences(newState); // Persist changes
    }
    return true; // No change needed
  }
}

/// Provider for multi-server configuration state and management
final multiServerConfigProvider =
    StateNotifierProvider<MultiServerConfigNotifier, MultiServerConfigState>((
      ref,
    ) {
      return MultiServerConfigNotifier();
    }, name: 'multiServerConfig');

/// Provider that returns the currently active ServerConfig object, or null
final activeServerConfigProvider = Provider<ServerConfig?>((ref) {
  final multiConfigState = ref.watch(multiServerConfigProvider);
  final activeId = multiConfigState.activeServerId;

  // Explicitly return null if no active server ID is set
  if (activeId == null) {
    if (kDebugMode) {
      print(
        '[activeServerConfigProvider] No active server ID set, returning null.',
      );
    }
    return null;
  }

  // Use firstWhereOrNull for safety
  final activeServer = multiConfigState.servers.firstWhereOrNull(
    (s) => s.id == activeId,
  );
  if (activeServer == null && kDebugMode) {
    print(
      '[activeServerConfigProvider] Warning: Active server ID $activeId not found in the list.',
    );
  }
  return activeServer;
}, name: 'activeServerConfig');


/// Provider for loading server configuration on app startup
final loadServerConfigProvider = FutureProvider<void>((ref) async {
  // Load config using the new notifier
  await ref.read(multiServerConfigProvider.notifier).loadFromPreferences();
  // No return value needed, FutureProvider<void> is fine
}, name: 'loadServerConfig');
