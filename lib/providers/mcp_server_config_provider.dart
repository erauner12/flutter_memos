import 'dart:convert';

import 'package:collection/collection.dart'; // For DeepCollectionEquality
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/mcp_server_config.dart';
// Removed CloudKitService import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mcpServerConfigCacheKey = 'mcp_server_config_cache'; // New cache key
const _oldMcpServerListKey = 'mcp_server_list';

/// Notifier for managing multiple MCP server configurations with persistence
class McpServerConfigNotifier extends StateNotifier<List<McpServerConfig>> {
  final Ref _ref;
  // Removed CloudKitService instance
  // late final CloudKitService _cloudKitService;

  McpServerConfigNotifier(this._ref) : super([]) {
    // Removed CloudKitService initialization
    // _cloudKitService = _ref.read(cloudKitServiceProvider);
  }

  /// Load configuration from local cache, handling migration from old prefs key.
  Future<void> loadConfiguration() async {
    if (kDebugMode) {
      print('[McpServerConfigNotifier] Starting configuration load...');
    }
    final prefs = await SharedPreferences.getInstance();
    List<McpServerConfig> initialStateFromCache = [];
    bool migrationNeededFromOldPrefs = false; // Flag for migration

    // 1. Load initial state from local cache (or old prefs for migration)
    final cachedJsonString = prefs.getString(_mcpServerConfigCacheKey);
    final oldPrefsJsonString = prefs.getString(_oldMcpServerListKey); // Old key

    if (cachedJsonString != null) {
      // Cache exists, load from it
      try {
        final decodedList = jsonDecode(cachedJsonString) as List;
        initialStateFromCache = decodedList
            .map((item) => McpServerConfig.fromJson(item as Map<String, dynamic>))
            .toList();
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] Loaded initial state from cache: ${initialStateFromCache.length} servers.',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] Error parsing cache JSON: $e. Starting fresh.',
          );
        }
        initialStateFromCache = [];
        await prefs.remove(_mcpServerConfigCacheKey); // Remove bad cache key
      }
    } else if (oldPrefsJsonString != null) {
      // Cache is empty, try loading from the old key for migration
      try {
        final decodedList = jsonDecode(oldPrefsJsonString) as List;
        initialStateFromCache = decodedList
            .map((item) => McpServerConfig.fromJson(item as Map<String, dynamic>))
            .toList();
        migrationNeededFromOldPrefs = true; // Mark for migration
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] Cache empty, using old prefs key $_oldMcpServerListKey for initial state. Migration needed.',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] Error parsing old prefs JSON from key $_oldMcpServerListKey: $e. Starting fresh.',
          );
        }
        initialStateFromCache = [];
        await prefs.remove(
          _oldMcpServerListKey,
        ); // Remove the problematic old key
      }
    } else {
      // Neither cache nor old prefs exist
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] No cache or old prefs found for initial state.',
        );
      }
      initialStateFromCache = []; // Ensure it's empty
    }

    // Set initial state immediately from cache/migration source
    if (mounted) {
      state = initialStateFromCache;
      if (kDebugMode) {
        final source =
            cachedJsonString != null
                ? 'cache'
                : (oldPrefsJsonString != null ? 'old_prefs' : 'none');
        print(
          '[McpServerConfigNotifier] Initial state set. Source: $source. Servers in state: ${state.length}',
        );
        if (state.isNotEmpty) {
          print(
            '[McpServerConfigNotifier] Initial state server IDs: ${state.map((s) => s.id).join(', ')}',
          );
        }
      }
    } else {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Notifier unmounted before initial state could be set.',
        );
      }
      return;
    }

    // --- Removed CloudKit Fetch Logic ---

    // Perform migration if needed (after initial load)
    if (migrationNeededFromOldPrefs) {
      if (kDebugMode) {
        print('[McpServerConfigNotifier] Performing MCP migration cleanup...');
      }
      // Removed migration upload to CloudKit
      // await _migratePrefsToCloudKit(initialStateFromCache);
      // Remove the old prefs key
      await prefs.remove(_oldMcpServerListKey);
      // Ensure the new cache key is populated if it was initially empty
      if (cachedJsonString == null) {
        await _updateLocalCache(state); // Use the current state
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] Ensured new cache is populated after migration.',
          );
        }
      }
      if (kDebugMode) {
        print('[McpServerConfigNotifier] MCP migration cleanup complete.');
      }
    } else if (cachedJsonString == null && oldPrefsJsonString != null) {
      // If cache was empty but old prefs existed (and no migration needed because state was already set)
      // ensure cache is populated with the final state.
      if (mounted) {
        await _updateLocalCache(state);
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] Populated empty MCP cache (no migration needed).',
          );
        }
      }
    }
  }

  // Removed _migratePrefsToCloudKit helper method

  /// Helper to update the local SharedPreferences cache
  Future<bool> _updateLocalCache(List<McpServerConfig> servers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverListJson = jsonEncode(
        servers.map((s) => s.toJson()).toList(),
      );
      final success = await prefs.setString(
        _mcpServerConfigCacheKey,
        serverListJson,
      );
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Updated local MCP server cache (success: $success). Cached ${servers.length} servers.',
        );
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Error updating local MCP server cache: $e',
        );
      }
      return false;
    }
  }

  /// Add a new server configuration locally
  Future<bool> addServer(McpServerConfig config) async {
    if (state.any((s) => s.id == config.id)) {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Attempted to add MCP server with duplicate ID: ${config.id}',
        );
      }
      return false;
    }

    // Removed CloudKit sync
    // final cloudSuccess = await _cloudKitService.saveMcpServerConfig(config);
    // if (!cloudSuccess) { ... return false }

    if (!mounted) {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] AddServer: Notifier unmounted. State/cache not updated.',
        );
      }
      return false; // Cannot update local state if unmounted
    }

    final newServers = [...state, config];
    state = newServers; // Update local state
    await _updateLocalCache(newServers); // Update local cache

    if (kDebugMode) {
      print(
        '[McpServerConfigNotifier] Added MCP server ${config.id} locally.');
    }
    return true;
  }

  /// Update an existing server configuration locally
  Future<bool> updateServer(McpServerConfig updatedConfig) async {
    final index = state.indexWhere((s) => s.id == updatedConfig.id);
    if (index == -1) {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] UpdateServer: MCP Server ID ${updatedConfig.id} not found.',
        );
      }
      return false;
    }

    // Removed CloudKit sync
    // final cloudSuccess = await _cloudKitService.saveMcpServerConfig(updatedConfig);
    // if (!cloudSuccess) { ... return false }

    if (!mounted) {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] UpdateServer: Notifier unmounted. State/cache not updated.',
        );
      }
      return false; // Cannot update local state if unmounted
    }

    final newServers = [...state];
    newServers[index] = updatedConfig;
    state = newServers; // Update local state
    await _updateLocalCache(newServers); // Update local cache

    if (kDebugMode) {
      print(
        '[McpServerConfigNotifier] Updated MCP server ${updatedConfig.id} locally.',
      );
    }
    return true;
  }

  /// Remove a server configuration locally
  Future<bool> removeServer(String serverId) async {
    final serverExists = state.any((s) => s.id == serverId);
    if (!serverExists) {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] RemoveServer: MCP Server ID $serverId not found.',
        );
      }
      return false;
    }

    // Removed CloudKit sync
    // final cloudSuccess = await _cloudKitService.deleteMcpServerConfig(serverId);
    // if (!cloudSuccess) { ... return false }

    if (!mounted) {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] RemoveServer: Notifier unmounted. State/cache not updated.',
        );
      }
      return false; // Cannot update local state if unmounted
    }

    final newServers = state.where((s) => s.id != serverId).toList();
    state = newServers; // Update local state
    await _updateLocalCache(newServers); // Update local cache

    if (kDebugMode) {
      print(
        '[McpServerConfigNotifier] Removed MCP server $serverId locally.');
    }
    return true;
  }

  /// Toggle the isActive status of a specific server locally.
  Future<bool> toggleServerActive(String serverId, bool isActive) async {
    final server = state.firstWhereOrNull((s) => s.id == serverId);
    if (server == null) {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] ToggleActive: MCP Server ID $serverId not found.',
        );
      }
      return false;
    }

    // Create the updated config with the new isActive status
    final updatedConfig = server.copyWith(isActive: isActive);

    // Use the existing updateServer method which handles local state and cache
    final success = await updateServer(updatedConfig);

    if (success && kDebugMode) {
      print(
        "[McpServerConfigNotifier] Toggled MCP server '$serverId' isActive to: $isActive locally.",
      );
    } else if (!success && kDebugMode) {
      print(
        "[McpServerConfigNotifier] Failed to toggle MCP server '$serverId' isActive status.",
      );
    }
    return success;
  }

  /// Resets the notifier state to default and clears associated local cache.
  Future<void> resetStateAndCache() async {
    if (kDebugMode) {
      print('[McpServerConfigNotifier] Resetting state and clearing cache...');
    }
    if (mounted) {
      state = []; // Reset state to empty list
    } else {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Notifier unmounted during reset. State not reset.',
        );
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_mcpServerConfigCacheKey); // Clear new cache key
      await prefs.remove(_oldMcpServerListKey); // Clear old migration key
      if (kDebugMode) {
        print('[McpServerConfigNotifier] Local cache keys cleared.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[McpServerConfigNotifier] Error clearing local cache: $e');
      }
      // Logged error, but proceed. Reset is best-effort.
    }
  }
}

/// Provider for the MCP server configuration state and management
final mcpServerConfigProvider =
    StateNotifierProvider<McpServerConfigNotifier, List<McpServerConfig>>((
      ref,
    ) {
      return McpServerConfigNotifier(ref);
    }, name: 'mcpServerConfigProvider');
