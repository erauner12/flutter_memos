import 'dart:convert';

import 'package:collection/collection.dart'; // For DeepCollectionEquality
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/providers/service_providers.dart';
// REMOVE: import 'package:flutter_memos/providers/settings_provider.dart'; // For old PreferenceKeys
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mcpServerConfigCacheKey = 'mcp_server_config_cache'; // New cache key
// ADD: Define the old key locally for migration purposes
const _oldMcpServerListKey = 'mcp_server_list';

/// Notifier for managing multiple MCP server configurations with persistence
class McpServerConfigNotifier extends StateNotifier<List<McpServerConfig>> {
  final Ref _ref;
  late final CloudKitService _cloudKitService;

  McpServerConfigNotifier(this._ref) : super([]) {
    _cloudKitService = _ref.read(cloudKitServiceProvider);
  }

  /// Load configuration, prioritizing local cache, syncing with CloudKit, and handling migration.
  Future<void> loadConfiguration() async {
    if (kDebugMode) {
      print('[McpServerConfigNotifier] Starting configuration load...');
    }
    final prefs = await SharedPreferences.getInstance();
    List<McpServerConfig> initialStateFromCache = [];
    bool migrationNeededFromOldPrefs = false;

    // 1. Load initial state from local cache (or old prefs for migration)
    final cachedJsonString = prefs.getString(_mcpServerConfigCacheKey);
    final oldPrefsJsonString = prefs.getString(
      // MODIFY: Use the local constant
      _oldMcpServerListKey,
    ); // Old key from SettingsService

    if (cachedJsonString != null) {
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
        // MODIFY: Use the local constant
        await prefs.remove(_oldMcpServerListKey);
      }
    } else {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] No cache or old prefs found for initial state.',
        );
      }
    }

    // Set initial state immediately from cache/migration source
    if (mounted) {
      state = initialStateFromCache;
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Initial state set from cache/prefs. Servers: ${state.length}',
        );
      }
    } else {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Notifier unmounted before initial state could be set.',
        );
      }
      return;
    }

    // --- Now, fetch from CloudKit asynchronously ---
    try {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Fetching latest MCP data from CloudKit...',
        );
      }
      final cloudServers = await _cloudKitService.getAllMcpServerConfigs();
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] CloudKit MCP fetch successful: ${cloudServers.length} servers.',
        );
      }

      final listEquals = const DeepCollectionEquality().equals;
      final currentServers = state; // Get current state

      if (!listEquals(cloudServers, currentServers)) {
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] CloudKit MCP data differs from cache. Updating state and cache...',
          );
        }

        if (mounted) {
          state = cloudServers; // Update state with CloudKit data
          if (kDebugMode) {
            print(
              '[McpServerConfigNotifier] State updated from CloudKit. Servers: ${state.length}',
            );
          }
          await _updateLocalCache(state); // Update cache with CloudKit data
        } else {
          if (kDebugMode) {
            print(
              '[McpServerConfigNotifier] Notifier unmounted before CloudKit update could be applied.',
            );
          }
        }
      } else {
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] CloudKit MCP data matches cache. No update needed.',
          );
        }
      }

      // Perform migration if needed (after CloudKit check)
      if (migrationNeededFromOldPrefs) {
        if (kDebugMode) {
          print('[McpServerConfigNotifier] Performing MCP migration cleanup...');
        }
        // Upload migrated servers to CloudKit in the background
        await _migratePrefsToCloudKit(initialStateFromCache);
        // Remove the old prefs key
        // MODIFY: Use the local constant
        await prefs.remove(_oldMcpServerListKey);
        // Ensure the new cache key is populated if CloudKit sync didn't happen or failed
        if (cachedJsonString == null) {
           await _updateLocalCache(initialStateFromCache);
        }
        if (kDebugMode) {
          print('[McpServerConfigNotifier] MCP migration cleanup complete.');
        }
      } else if (cachedJsonString == null && oldPrefsJsonString != null) {
         // If cache was empty but old prefs existed, ensure cache is populated after CloudKit check
         if (mounted) {
           await _updateLocalCache(state);
           if (kDebugMode) {
             print(
               '[McpServerConfigNotifier] Populated empty MCP cache after checking CloudKit during migration phase.',
             );
           }
         }
      }

    } catch (e) {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Error during async CloudKit fetch: $e. Continuing with cached data.',
        );
      }
      // Optionally, trigger migration cleanup even on CloudKit error if needed
      if (migrationNeededFromOldPrefs) {
         if (kDebugMode) {
           print('[McpServerConfigNotifier] Performing MCP migration cleanup after CloudKit error...');
         }
        // MODIFY: Use the local constant
        await prefs.remove(_oldMcpServerListKey);
         if (cachedJsonString == null) {
            await _updateLocalCache(initialStateFromCache);
         }
         if (kDebugMode) {
           print('[McpServerConfigNotifier] MCP migration cleanup complete after CloudKit error.');
         }
      }
    }
  }

  // Helper to update the local SharedPreferences cache
  Future<bool> _updateLocalCache(List<McpServerConfig> servers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverListJson = jsonEncode(
        servers.map((s) => s.toJson()).toList(),
      );
      final success = await prefs.setString(_mcpServerConfigCacheKey, serverListJson);
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

  // Helper to migrate old prefs data to CloudKit
  Future<void> _migratePrefsToCloudKit(List<McpServerConfig> servers) async {
    if (kDebugMode) {
      print(
        '[McpServerConfigNotifier] Attempting background migration of ${servers.length} MCP servers to CloudKit...',
      );
    }
    for (final server in servers) {
      try {
        // Use the specific MCP save method
        await _cloudKitService.saveMcpServerConfig(server);
      } catch (e) {
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] Error migrating MCP server ${server.id} to CloudKit: $e',
          );
        }
        // Decide if you want to stop migration on first error or continue
      }
    }
    if (kDebugMode) {
      print(
        '[McpServerConfigNotifier] Background MCP migration attempt complete.',
      );
    }
  }

  /// Add a new server configuration locally and sync to CloudKit
  Future<bool> addServer(McpServerConfig config) async {
    if (state.any((s) => s.id == config.id)) {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Attempted to add MCP server with duplicate ID: ${config.id}',
        );
      }
      return false;
    }

    // 1. Sync change to CloudKit FIRST
    final cloudSuccess = await _cloudKitService.saveMcpServerConfig(config);

    if (cloudSuccess) {
      if (!mounted) {
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] AddServer: Notifier unmounted after CloudKit success. State/cache not updated.',
          );
        }
        return true; // CloudKit succeeded, even if local state didn't update
      }

      final newServers = [...state, config];
      state = newServers; // Update local state

      await _updateLocalCache(newServers); // Update local cache
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Added MCP server ${config.id} locally and synced to CloudKit.',
        );
      }
      return true;
    } else {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Failed to sync added MCP server ${config.id} to CloudKit. Local state/cache not changed.',
        );
      }
      return false;
    }
  }

  /// Update an existing server configuration locally and sync to CloudKit
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

    // 1. Sync change to CloudKit FIRST
    final cloudSuccess = await _cloudKitService.saveMcpServerConfig(updatedConfig);

    if (cloudSuccess) {
      if (!mounted) {
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] UpdateServer: Notifier unmounted after CloudKit success. State/cache not updated.',
          );
        }
        return true; // CloudKit succeeded
      }

      final newServers = [...state];
      newServers[index] = updatedConfig;
      state = newServers; // Update local state

      await _updateLocalCache(newServers); // Update local cache
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Updated MCP server ${updatedConfig.id} locally and synced to CloudKit.',
        );
      }
      return true;
    } else {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Failed to sync updated MCP server ${updatedConfig.id} to CloudKit. Local state/cache not changed.',
        );
      }
      return false;
    }
  }

  /// Remove a server configuration locally and sync deletion to CloudKit
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

    // 1. Sync deletion to CloudKit FIRST
    final cloudSuccess = await _cloudKitService.deleteMcpServerConfig(serverId);

    if (cloudSuccess) {
      if (!mounted) {
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] RemoveServer: Notifier unmounted after CloudKit success. State/cache not updated.',
          );
        }
        return true; // CloudKit succeeded
      }

      final newServers = state.where((s) => s.id != serverId).toList();
      state = newServers; // Update local state

      await _updateLocalCache(newServers); // Update local cache
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Removed MCP server $serverId locally and synced deletion to CloudKit.',
        );
      }
      return true;
    } else {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Failed to sync deleted MCP server $serverId to CloudKit. Local state/cache not changed.',
        );
      }
      return false;
    }
  }

  /// Toggle the isActive status of a specific server and sync the change.
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

    // Use the existing updateServer method which handles CloudKit sync and local state
    final success = await updateServer(updatedConfig);

    if (success && kDebugMode) {
      // COMMENT OUT: print(
      //   "[McpServerConfigNotifier] Toggled MCP server '$serverId' isActive to: $isActive and synced.",
      // );
    } else if (!success && kDebugMode) {
      // COMMENT OUT: print(
      //  "[McpServerConfigNotifier] Failed to toggle MCP server '$serverId' isActive status.",
      // );
    }
    return success;
  }
}

/// Provider for the MCP server configuration state and management
final mcpServerConfigProvider =
    StateNotifierProvider<McpServerConfigNotifier, List<McpServerConfig>>((ref) {
  return McpServerConfigNotifier(ref);
}, name: 'mcpServerConfigProvider');
