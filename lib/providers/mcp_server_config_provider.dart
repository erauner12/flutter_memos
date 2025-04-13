import 'dart:convert';

import 'package:collection/collection.dart'; // For DeepCollectionEquality
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mcpServerConfigCacheKey = 'mcp_server_config_cache'; // New cache key
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
      // If unmounted here, no point proceeding with CloudKit fetch for this instance
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
      final currentServers = state; // Get current state AFTER initial set

      // --- MODIFICATION START: Prevent overwriting local data with empty CloudKit ---
      // Only update from CloudKit if CloudKit provides non-empty data that differs,
      // or if the local state was initially empty and CloudKit provides data.
      final shouldUpdateFromCloudKit =
          (cloudServers.isNotEmpty &&
              !listEquals(cloudServers, currentServers)) ||
          (currentServers.isEmpty && cloudServers.isNotEmpty);

      if (shouldUpdateFromCloudKit) {
        // --- MODIFICATION END ---
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] CloudKit MCP data differs from local state. Updating state and cache...',
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
          // Add logging for the case where update is skipped
          if (cloudServers.isEmpty && currentServers.isNotEmpty) {
            print(
              '[McpServerConfigNotifier] CloudKit returned empty MCP data, but local state exists. Keeping local state.',
            );
          } else {
            print(
              '[McpServerConfigNotifier] CloudKit MCP data matches local state or no update needed. No state/cache change.',
            );
          }
        }
      }

      // Perform migration if needed (after CloudKit check)
      if (migrationNeededFromOldPrefs) {
        if (kDebugMode) {
          print('[McpServerConfigNotifier] Performing MCP migration cleanup...');
        }
        // Upload migrated servers to CloudKit in the background
        // Use the initially loaded state from old prefs for migration upload
        await _migratePrefsToCloudKit(initialStateFromCache);
        // Remove the old prefs key
        await prefs.remove(_oldMcpServerListKey);
        // Ensure the new cache key is populated if CloudKit sync didn't happen or failed
        // AND if the cache was initially empty (which it was if migrationNeeded is true)
        if (cachedJsonString == null) {
          await _updateLocalCache(
            state,
          ); // Use the potentially updated state from CloudKit
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
        // If cache was empty but old prefs existed (and CloudKit matched, so no migration needed)
        // ensure cache is populated with the final state.
        if (mounted) {
          await _updateLocalCache(state);
          if (kDebugMode) {
            print(
              '[McpServerConfigNotifier] Populated empty MCP cache after checking CloudKit (no migration needed).',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[McpServerConfigNotifier] Error during async CloudKit fetch: $e. Continuing with local data.',
        );
      }
      // If CloudKit fails during migration, still try to clean up
      if (migrationNeededFromOldPrefs) {
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] Performing MCP migration cleanup after CloudKit error...',
          );
        }
        // Don't attempt CloudKit upload again
        await prefs.remove(_oldMcpServerListKey);
        // Ensure cache is populated with the data loaded from old prefs
        if (cachedJsonString == null && mounted) {
          await _updateLocalCache(
            initialStateFromCache,
          ); // Use the data from old prefs
          if (kDebugMode) {
            print(
              '[McpServerConfigNotifier] Ensured new cache is populated with old prefs data after CloudKit error.',
            );
          }
        }
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] MCP migration cleanup (post-error) complete.',
          );
        }
      }
    }
  }

  /// Helper to upload migrated servers to CloudKit in the background.
  Future<void> _migratePrefsToCloudKit(
    List<McpServerConfig> serversToMigrate,
  ) async {
    if (kDebugMode) {
      print(
        '[McpServerConfigNotifier] Attempting background migration of ${serversToMigrate.length} MCP servers to CloudKit...',
      );
    }
    for (final server in serversToMigrate) {
      try {
        // Use the existing CloudKit service method
        await _cloudKitService.saveMcpServerConfig(server);
      } catch (e) {
        if (kDebugMode) {
          print(
            '[McpServerConfigNotifier] Error migrating MCP server ${server.id} to CloudKit: $e',
          );
        }
        // Continue trying to migrate others even if one fails
      }
    }
    if (kDebugMode) {
      print(
        '[McpServerConfigNotifier] Background MCP migration attempt complete.',
      );
    }
  }

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
    final cloudSuccess = await _cloudKitService.saveMcpServerConfig(
      updatedConfig,
    );

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
      print(
        "[McpServerConfigNotifier] Toggled MCP server '$serverId' isActive to: $isActive and synced.",
      );
    } else if (!success && kDebugMode) {
      print(
        "[McpServerConfigNotifier] Failed to toggle MCP server '$serverId' isActive status.",
      );
    }
    return success;
  }
}

/// Provider for the MCP server configuration state and management
final mcpServerConfigProvider =
    StateNotifierProvider<McpServerConfigNotifier, List<McpServerConfig>>((
      ref,
    ) {
      return McpServerConfigNotifier(ref);
    }, name: 'mcpServerConfigProvider');
