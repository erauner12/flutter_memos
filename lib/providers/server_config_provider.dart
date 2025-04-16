import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/multi_server_config_state.dart'; // Import new state model
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/mcp_server_config_provider.dart';
import 'package:flutter_memos/providers/service_providers.dart'; // Import service provider
import 'package:flutter_memos/providers/settings_provider.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart'; // Import Uuid

const _multiServerConfigKey = 'multi_server_config'; // Old key
const _legacyServerUrlKey = 'server_url'; // Old key
const _legacyAuthTokenKey = 'auth_token'; // Old key
const _serverConfigCacheKey = 'server_config_cache'; // New cache key

/// Notifier for managing multiple server configurations with persistence
class MultiServerConfigNotifier extends StateNotifier<MultiServerConfigState> {
  final Ref _ref;
  late final CloudKitService _cloudKitService;

  MultiServerConfigNotifier(this._ref) : super(const MultiServerConfigState()) {
    _cloudKitService = _ref.read(cloudKitServiceProvider);
  }

  /// Filters a list of ServerConfig, removing any that are identified as Todoist.
  /// This relies on ServerConfig.fromJson defaulting legacy 'todoist' types to 'memos',
  /// so this filter primarily acts as a safeguard or if identification logic changes.
  /// A more robust approach might involve checking raw JSON before parsing.
  List<ServerConfig> _filterOutTodoistConfigs(List<ServerConfig> configs) {
    // Because ServerConfig.fromJson now defaults 'todoist' to 'memos',
    // we might not find any with serverType == ServerType.todoist here.
    // This filter is kept as a safeguard. If needed, identification
    // logic would need to happen *before* ServerConfig.fromJson.
    final filteredList =
        configs.where((s) => s.serverType != ServerType.todoist).toList();
    if (kDebugMode && filteredList.length != configs.length) {
      print(
        '[MultiServerConfigNotifier][_filterOutTodoistConfigs] Filtered out ${configs.length - filteredList.length} legacy Todoist server(s).',
      );
    }
    return filteredList;
  }


  /// Load configuration, prioritizing local cache and syncing with CloudKit.
  Future<void> loadConfiguration() async {
    if (kDebugMode) {
      print('[MultiServerConfigNotifier] Starting configuration load...');
    }
    final prefs = await SharedPreferences.getInstance();
    MultiServerConfigState initialStateFromCache =
        const MultiServerConfigState();
    bool migrationNeededFromOldPrefs = false;

    // 1. Load initial state from local cache (or old prefs for migration)
    final cachedJsonString = prefs.getString(_serverConfigCacheKey);
    if (kDebugMode) {
      print(
        '[MultiServerConfigNotifier] Raw cache JSON string ($_serverConfigCacheKey): $cachedJsonString',
      );
    }
    final multiServerJsonString = prefs.getString(_multiServerConfigKey);
    if (kDebugMode) {
      print(
        '[MultiServerConfigNotifier] Raw old multi-server JSON string ($_multiServerConfigKey): $multiServerJsonString',
      );
    }
    final legacyUrl = prefs.getString(_legacyServerUrlKey);

    if (cachedJsonString != null) {
      try {
        initialStateFromCache = MultiServerConfigState.fromJsonString(
          cachedJsonString,
        );
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] Loaded initial state from cache (before filtering): ${initialStateFromCache.servers.length} servers.',
          );
        }
        // Filter out any potential legacy Todoist configs loaded from cache
        initialStateFromCache = initialStateFromCache.copyWith(
          servers: _filterOutTodoistConfigs(initialStateFromCache.servers),
        );
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] State after filtering cache: ${initialStateFromCache.servers.length} servers.',
          );
        }

      } catch (e) {
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] Error parsing cache JSON: $e. Starting fresh.',
          );
        }
        initialStateFromCache = const MultiServerConfigState();
        await prefs.remove(_serverConfigCacheKey);
      }
    } else if (multiServerJsonString != null) {
      try {
        initialStateFromCache = MultiServerConfigState.fromJsonString(
          multiServerJsonString,
        );
        migrationNeededFromOldPrefs = true;
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] Cache empty, using old multi-server prefs for initial state (before filtering).',
          );
        }
        // Filter out legacy Todoist configs from old prefs
        initialStateFromCache = initialStateFromCache.copyWith(
          servers: _filterOutTodoistConfigs(initialStateFromCache.servers),
        );
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] State after filtering old prefs: ${initialStateFromCache.servers.length} servers.',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] Error parsing old multi-server JSON: $e. Starting fresh.',
          );
        }
        initialStateFromCache = const MultiServerConfigState();
        await prefs.remove(_multiServerConfigKey);
      }
    } else if (legacyUrl != null && legacyUrl.isNotEmpty) {
      final legacyToken = prefs.getString(_legacyAuthTokenKey);
      // Legacy config is always Memos type
      final migratedServer = ServerConfig(
        id: const Uuid().v4(),
        name: 'Migrated Server',
        serverUrl: legacyUrl,
        authToken: legacyToken ?? '',
        serverType: ServerType.memos,
      );
      initialStateFromCache = MultiServerConfigState(
        servers: [migratedServer], // Already known to be Memos type
        defaultServerId: migratedServer.id,
      );
      migrationNeededFromOldPrefs = true;
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Cache empty, using legacy prefs for initial state. Migration needed.',
        );
      }
    } else {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] No cache or old prefs found for initial state.',
        );
      }
    }

    // Load default ID separately (always from prefs)
    final defaultServerId = prefs.getString('defaultServerId');
    // Ensure default ID points to a *valid* (non-Todoist) server in the loaded state
    final effectiveDefaultId =
        (defaultServerId != null &&
                initialStateFromCache.servers.any(
                  (s) => s.id == defaultServerId,
                ))
            ? defaultServerId
            : null;

    // Adjust initial state with the potentially nullified default ID
    initialStateFromCache = initialStateFromCache.copyWith(
      defaultServerId: () => effectiveDefaultId,
    );


    // Determine initial active ID based on the filtered state and effective default
    String? initialActiveId = effectiveDefaultId;
    if (initialActiveId == null && initialStateFromCache.servers.isNotEmpty) {
      // If no default, pick the first available (non-Todoist) server
      initialActiveId = initialStateFromCache.servers.first.id;
    }
    // Final check: ensure the derived active ID actually exists in the filtered list
    if (initialActiveId != null &&
        !initialStateFromCache.servers.any((s) => s.id == initialActiveId)) {
      initialActiveId = initialStateFromCache.servers.firstOrNull?.id;
    }

    initialStateFromCache = initialStateFromCache.copyWith(
      activeServerId: initialActiveId,
    );


    if (kDebugMode) {
      print(
        '[MultiServerConfigNotifier] Computed Initial State Before Setting:',
      );
      for (var server in initialStateFromCache.servers) {
        print(
          '[MultiServerConfigNotifier]   Server: ID=${server.id}, Name=${server.name}, Type=${server.serverType.name}',
        );
      }
      print(
        '[MultiServerConfigNotifier]   Default ID: ${initialStateFromCache.defaultServerId}',
      );
      print(
        '[MultiServerConfigNotifier]   Active ID: ${initialStateFromCache.activeServerId}',
      );
    }

    // Set initial state immediately from filtered cache/migration source
    if (mounted) {
      state = initialStateFromCache;
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Initial state set from cache/prefs. Servers: ${state.servers.length}, ActiveId: ${state.activeServerId}, DefaultId: ${state.defaultServerId}',
        );
      }
    } else {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Notifier unmounted before initial state could be set.',
        );
      }
      return;
    }

    // --- Now, fetch from CloudKit asynchronously ---
    try {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Fetching latest data from CloudKit...',
        );
      }
      // Fetch all raw configs from CloudKit
      final cloudServersRaw = await _cloudKitService.getAllServerConfigs();
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] CloudKit fetched ${cloudServersRaw.length} raw server configs.',
        );
      }
      // Filter out Todoist configs *after* fetching, before comparison/saving
      final cloudServers = _filterOutTodoistConfigs(cloudServersRaw);

      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] CloudKit fetch result: ${cloudServers.length} filtered (Memos/Blinko) servers.',
        );
        for (var server in cloudServers) {
          print(
            '[MultiServerConfigNotifier] CloudKit Filtered Detail: ID=${server.id}, Name=${server.name}, Type=${server.serverType.name}',
          );
        }
      }

      final listEquals = const DeepCollectionEquality().equals;
      final currentServers = state.servers; // Current state (already filtered)

      if (!listEquals(cloudServers, currentServers)) {
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] CloudKit data differs from local state. Updating state and cache...',
          );
        }

        // Re-validate default ID against the *new* filtered CloudKit list
        final prefsDefaultId = prefs.getString(
          'defaultServerId',
        ); // Re-read prefs value
        final effectiveNewDefaultId =
            (prefsDefaultId != null &&
                    cloudServers.any((s) => s.id == prefsDefaultId))
                ? prefsDefaultId
                : null;

        // Check if the default ID from prefs is now invalid (doesn't exist in filtered cloud list)
        if (prefsDefaultId != null && effectiveNewDefaultId == null) {
          if (kDebugMode) {
            print(
              '[MultiServerConfigNotifier] Default server ID $prefsDefaultId from prefs is no longer valid after CloudKit sync. Clearing from prefs.',
            );
          }
          await prefs.remove(
            'defaultServerId',
          ); // Remove the invalid default ID from prefs
        }

        // Determine new active ID based on the filtered cloud list and new default
        String? newActiveId = effectiveNewDefaultId;
        if (newActiveId == null && cloudServers.isNotEmpty) {
          newActiveId =
              cloudServers.first.id; // Fallback to first filtered server
        }
        // Final check: ensure new active ID exists in the filtered cloud list
        if (newActiveId != null &&
            !cloudServers.any((s) => s.id == newActiveId)) {
          newActiveId = cloudServers.firstOrNull?.id;
        }

        if (mounted) {
          state = MultiServerConfigState(
            servers: cloudServers, // Use filtered list
            defaultServerId: effectiveNewDefaultId, // Use validated default ID
            activeServerId: newActiveId, // Use derived active ID
          );
          if (kDebugMode) {
            print(
              '[MultiServerConfigNotifier] State updated from CloudKit. Servers: ${state.servers.length}, ActiveId: ${state.activeServerId}, DefaultId: ${state.defaultServerId}',
            );
          }
          // Update local cache with the filtered list
          await _updateLocalCache(state.servers);
        } else {
          if (kDebugMode) {
            print(
              '[MultiServerConfigNotifier] Notifier unmounted before CloudKit update could be applied.',
            );
          }
        }
      } else {
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] CloudKit data matches local state. No update needed.',
          );
        }
      }

      // Migration logic (only runs if old prefs were used)
      if (migrationNeededFromOldPrefs) {
        if (kDebugMode) {
          print('[MultiServerConfigNotifier] Performing migration cleanup...');
        }
        // Migrate only the filtered (non-Todoist) servers
        await _migratePrefsToCloudKit(
          initialStateFromCache.servers, // Already filtered list
          initialStateFromCache.defaultServerId,
        );
        if (multiServerJsonString != null) {
          await prefs.remove(_multiServerConfigKey);
        }
        if (legacyUrl != null) {
          await prefs.remove(_legacyServerUrlKey);
          await prefs.remove(_legacyAuthTokenKey);
        }
        // Ensure cache reflects the filtered list after migration attempt
        await _updateLocalCache(initialStateFromCache.servers);
        if (kDebugMode) {
          print('[MultiServerConfigNotifier] Migration cleanup complete.');
        }
      } else if (cachedJsonString == null &&
          (multiServerJsonString != null || legacyUrl != null)) {
        // If started from old prefs but no CloudKit update was needed, ensure cache is populated
        if (mounted) {
          await _updateLocalCache(
            state.servers,
          ); // Cache the current filtered state
          if (kDebugMode) {
            print(
              '[MultiServerConfigNotifier] Populated empty cache after checking CloudKit during migration.',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Error during async CloudKit fetch/update: $e. Continuing with local data.',
        );
      }
      // Optionally trigger explicit CloudKit cleanup for legacy Todoist items here or elsewhere
      // await _cleanupLegacyTodoistCloudKitConfigs();
    }
  }

  // Helper to update the local SharedPreferences cache
  Future<bool> _updateLocalCache(List<ServerConfig> servers) async {
    // Ensure we only cache Memos/Blinko types
    final serversToCache = _filterOutTodoistConfigs(servers);
    try {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier][_updateLocalCache] Preparing to cache ${serversToCache.length} servers (Memos/Blinko only):',
        );
        print(
          '[MultiServerConfigNotifier][_updateLocalCache] Caching Servers Details: ${serversToCache.map((s) => "ID=${s.id}, Name=${s.name}, Type=${s.serverType.name}").join("; ")}',
        );
      }
      final prefs = await SharedPreferences.getInstance();
      final cacheState = MultiServerConfigState(servers: serversToCache);
      final success = await prefs.setString(
        _serverConfigCacheKey,
        cacheState.toJsonString(),
      );
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Updated local server cache (success: $success). Cached ${serversToCache.length} servers.',
        );
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Error updating local server cache: $e',
        );
      }
      return false;
    }
  }

  // Migrate only non-Todoist servers
  Future<void> _migratePrefsToCloudKit(
    List<ServerConfig> servers,
    String? defaultId,
  ) async {
    final serversToMigrate = _filterOutTodoistConfigs(servers);
    if (kDebugMode) {
      print(
        '[MultiServerConfigNotifier] Attempting background migration of ${serversToMigrate.length} servers (Memos/Blinko) to CloudKit...',
      );
    }
    for (final server in serversToMigrate) {
      try {
        await _cloudKitService.saveServerConfig(server);
      } catch (e) {
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] Error migrating server ${server.id} to CloudKit: $e',
          );
        }
      }
    }
    if (kDebugMode) {
      print(
        '[MultiServerConfigNotifier] Background migration attempt complete.',
      );
    }
    // Note: Default ID migration isn't handled here, relies on loadConfiguration logic.
  }


  /// Save only the default server ID to SharedPreferences
  Future<bool> _saveDefaultServerIdToPreferences(
    String? defaultServerId,
  ) async {
    // Ensure the ID being saved actually exists in the current (filtered) state
    if (defaultServerId != null &&
        !state.servers.any((s) => s.id == defaultServerId)) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier][_saveDefaultServerIdToPreferences] Attempted to save invalid default ID: $defaultServerId. Removing instead.',
        );
      }
      defaultServerId = null; // Force removal if invalid
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      bool success;
      if (defaultServerId != null) {
        success = await prefs.setString('defaultServerId', defaultServerId);
      } else {
        success = await prefs.remove('defaultServerId');
      }
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier][_saveDefaultServerIdToPreferences] Saved default ID: $defaultServerId (success: $success).',
        );
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier][_saveDefaultServerIdToPreferences] Error: $e',
        );
      }
      return false;
    }
  }

  /// Add a new server configuration locally and sync to CloudKit
  Future<bool> addServer(ServerConfig config) async {
    // Crucial check: Do not add Todoist type servers via this method
    if (config.serverType == ServerType.todoist) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] addServer Error: Attempted to add a ServerConfig with ServerType.todoist. Operation aborted.',
        );
      }
      return false;
    }

    if (kDebugMode) {
      print(
        '[MultiServerConfigNotifier] addServer received config: ${config.toString()}',
      );
    }
    if (state.servers.any((s) => s.id == config.id)) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Attempted to add server with duplicate ID: ${config.id}',
        );
      }
      return false;
    }

    final cloudSuccess = await _cloudKitService.saveServerConfig(config);

    if (cloudSuccess) {
      if (!mounted) {
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] AddServer: Notifier unmounted after CloudKit success. State/cache not updated.',
          );
        }
        return true;
      }

      final newServers = [
        ...state.servers,
        config,
      ]; // Add the valid (non-Todoist) server
      String? newDefaultId = state.defaultServerId;
      String? newActiveId = state.activeServerId;
      bool isFirstServer = state.servers.isEmpty;
      bool defaultChanged = false;

      if (isFirstServer) {
        newDefaultId = config.id;
        newActiveId = config.id;
        defaultChanged = true;
      }

      state = state.copyWith(
        servers: newServers,
        defaultServerId: () => newDefaultId,
        activeServerId: newActiveId,
      );

      await _updateLocalCache(newServers); // Caches filtered list

      if (defaultChanged) {
        await _saveDefaultServerIdToPreferences(newDefaultId);
      }
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Added server ${config.id} locally and synced to CloudKit.',
        );
      }
      return true;
    } else {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Failed to sync added server ${config.id} to CloudKit. Local state/cache not changed.',
        );
      }
      return false;
    }
  }

  /// Update an existing server configuration locally and sync to CloudKit
  Future<bool> updateServer(ServerConfig updatedConfig) async {
    // Crucial check: Do not update to Todoist type
    if (updatedConfig.serverType == ServerType.todoist) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] updateServer Error: Attempted to update a ServerConfig to ServerType.todoist. Operation aborted.',
        );
      }
      return false;
    }

    if (kDebugMode) {
      print(
        '[MultiServerConfigNotifier] updateServer received config: ${updatedConfig.toString()}',
      );
    }
    final index = state.servers.indexWhere((s) => s.id == updatedConfig.id);
    if (index == -1) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] UpdateServer: Server ID ${updatedConfig.id} not found in current (filtered) state.',
        );
      }
      // Maybe it was a Todoist server that got filtered out?
      return false;
    }

    final cloudSuccess = await _cloudKitService.saveServerConfig(updatedConfig);

    if (cloudSuccess) {
      if (!mounted) {
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] UpdateServer: Notifier unmounted after CloudKit success. State/cache not updated.',
          );
        }
        return true;
      }

      final newServers = [...state.servers];
      newServers[index] =
          updatedConfig; // Update with valid (non-Todoist) config
      state = state.copyWith(servers: newServers);

      await _updateLocalCache(newServers); // Caches filtered list
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Updated server ${updatedConfig.id} locally and synced to CloudKit.',
        );
      }
      return true;
    } else {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Failed to sync updated server ${updatedConfig.id} to CloudKit. Local state/cache not changed.',
        );
      }
      return false;
    }
  }

  /// Remove a server configuration locally and sync deletion to CloudKit
  Future<bool> removeServer(String serverId) async {
    // Find server in the current (filtered) state
    final serverToRemove = state.servers.firstWhereOrNull(
      (s) => s.id == serverId,
    );
    if (serverToRemove == null) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] RemoveServer: Server ID $serverId not found in current (filtered) state.',
        );
      }
      // It might be a legacy Todoist ID. Try deleting from CloudKit anyway.
      // Or just return false if we assume removeServer is only called for visible servers.
      // Let's try deleting from CloudKit regardless, as it might be cleanup.
    }

    // Sync deletion to CloudKit FIRST (works even if server wasn't in local state)
    final cloudSuccess = await _cloudKitService.deleteServerConfig(serverId);

    if (cloudSuccess) {
      if (!mounted) {
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] RemoveServer: Notifier unmounted after CloudKit success. State/cache not updated.',
          );
        }
        return true; // CloudKit deletion succeeded
      }

      // If the server *was* in the local state, update state and cache
      if (serverToRemove != null) {
        final newServers =
            state.servers.where((s) => s.id != serverId).toList();

        String? newDefaultId = state.defaultServerId;
        String? newActiveId = state.activeServerId;
        bool defaultChanged = false;

        if (newServers.isEmpty) {
          if (kDebugMode) {
            print(
              '[MultiServerConfigNotifier] Removed the last server. Resetting active and default IDs.',
            );
          }
          newDefaultId = null;
          newActiveId = null;
          defaultChanged = state.defaultServerId != null;
        } else {
          if (state.defaultServerId == serverId) {
            newDefaultId =
                newServers.first.id; // New default is first remaining
            defaultChanged = true;
            if (kDebugMode) {
              print(
                '[MultiServerConfigNotifier] Removed default server $serverId. Setting new default to $newDefaultId.',
              );
            }
          }
          if (state.activeServerId == serverId) {
            newActiveId =
                newDefaultId ??
                newServers
                    .first
                    .id; // New active is new default or first remaining
            if (kDebugMode) {
              print(
                '[MultiServerConfigNotifier] Removed active server $serverId. Setting new active to $newActiveId.',
              );
            }
          }
        }

        state = state.copyWith(
          servers: newServers,
          defaultServerId: () => newDefaultId,
          activeServerId: newActiveId,
        );

        await _updateLocalCache(newServers); // Cache the updated filtered list

        if (defaultChanged) {
          await _saveDefaultServerIdToPreferences(newDefaultId);
        }
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] Removed server $serverId locally and synced deletion to CloudKit.',
          );
        }
      } else {
        // Server wasn't in local state, but CloudKit deletion succeeded (likely legacy cleanup)
        if (kDebugMode) {
          print(
            '[MultiServerConfigNotifier] Server $serverId not found locally, but deletion synced to CloudKit (likely legacy).',
          );
        }
        // Optionally re-validate default/active IDs here just in case they pointed to this ID somehow
        // (though loadConfiguration should handle this)
      }
      return true;
    } else {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Failed to sync deleted server $serverId to CloudKit. Local state/cache not changed.',
        );
      }
      return false;
    }
  }

  /// Set the active server for the current session (no persistence change)
  void setActiveServer(String? serverId) {
    // Ensure ID exists in the current filtered list
    if (serverId != null && !state.servers.any((s) => s.id == serverId)) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Attempted to set active server to non-existent (or filtered) ID: $serverId',
        );
      }
      // Optionally set to null or first available if the target is invalid
      // For now, just prevent setting to an invalid ID.
      return;
    }
    if (state.activeServerId != serverId) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Setting active server ID to: $serverId',
        );
      }
      state = state.copyWith(activeServerId: serverId);
    }
  }

  /// Set the default server and save it to SharedPreferences
  Future<bool> setDefaultServer(String? serverId) async {
    // Ensure ID exists in the current filtered list before setting
    if (serverId != null && !state.servers.any((s) => s.id == serverId)) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Attempted to set default server to non-existent (or filtered) ID: $serverId',
        );
      }
      return false; // Don't allow setting an invalid default
    }
    if (state.defaultServerId != serverId) {
      final newState = state.copyWith(defaultServerId: () => serverId);
      state = newState;
      // Save the validated ID to prefs
      return _saveDefaultServerIdToPreferences(serverId);
    }
    return true; // No change needed
  }

  /// Resets the notifier state to default and clears associated local cache.
  Future<void> resetStateAndCache() async {
    if (kDebugMode) {
      print(
        '[MultiServerConfigNotifier] Resetting state and clearing cache...',
      );
    }
    if (mounted) {
      state = const MultiServerConfigState(); // Reset state
    } else {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Notifier unmounted during reset. State not reset.',
        );
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_serverConfigCacheKey); // Clear new cache key
      await prefs.remove(_multiServerConfigKey); // Clear old migration key
      await prefs.remove('defaultServerId'); // Clear default ID key
      // Clear legacy single server keys too for good measure
      await prefs.remove(_legacyServerUrlKey);
      await prefs.remove(_legacyAuthTokenKey);
      if (kDebugMode) {
        print('[MultiServerConfigNotifier] Local cache keys cleared.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[MultiServerConfigNotifier] Error clearing local cache: $e');
      }
    }
  }
}

/// Provider for multi-server configuration state and management
final multiServerConfigProvider =
    StateNotifierProvider<MultiServerConfigNotifier, MultiServerConfigState>((
      ref,
    ) {
      return MultiServerConfigNotifier(ref);
    }, name: 'multiServerConfig');

/// Provider that returns the currently active ServerConfig object, or null
final activeServerConfigProvider = Provider<ServerConfig?>((ref) {
  final multiConfigState = ref.watch(multiServerConfigProvider);
  final activeId = multiConfigState.activeServerId;

  if (activeId == null) {
    return null;
  }
  // Find in the already filtered list from the state provider
  final activeServer = multiConfigState.servers.firstWhereOrNull(
    (s) => s.id == activeId,
  );
  return activeServer;
}, name: 'activeServerConfig');

// REMOVED todoistServerConfigProvider

/// Provider for loading server configuration on app startup
final loadServerConfigProvider = FutureProvider<void>((ref) async {
  if (kDebugMode) {
    print('[loadServerConfigProvider] Starting initial data load sequence...');
  }

  // Load and filter server configs first
  await ref.read(multiServerConfigProvider.notifier).loadConfiguration();
  if (kDebugMode) {
    print('[loadServerConfigProvider] Server config load complete.');
  }

  // Load other providers
  try {
    await ref.read(mcpServerConfigProvider.notifier).loadConfiguration();
    if (kDebugMode) {
      print('[loadServerConfigProvider] MCP server config load triggered.');
    }
  } catch (e) {
    if (kDebugMode) {
      print(
        '[loadServerConfigProvider] Error initializing MCP config provider: $e',
      );
    }
  }
  try {
    // Init Todoist API key provider (now independent of ServerConfig)
    await ref.read(todoistApiKeyProvider.notifier).init();
    if (kDebugMode) {
      print('[loadServerConfigProvider] Todoist API key load triggered.');
    }
  } catch (e) {
    if (kDebugMode) {
      print(
        '[loadServerConfigProvider] Error initializing Todoist provider: $e',
      );
    }
  }
  try {
    await ref.read(openAiApiKeyProvider.notifier).init();
    if (kDebugMode) {
      print('[loadServerConfigProvider] OpenAI API key load triggered.');
    }
  } catch (e) {
    if (kDebugMode) {
      print(
        '[loadServerConfigProvider] Error initializing OpenAI provider: $e',
      );
    }
  }
  try {
    await ref.read(openAiModelIdProvider.notifier).init();
    if (kDebugMode) {
      print('[loadServerConfigProvider] OpenAI Model ID load triggered.');
    }
  } catch (e) {
    if (kDebugMode) {
      print(
        '[loadServerConfigProvider] Error initializing OpenAI Model ID provider: $e',
      );
    }
  }
  try {
    await ref.read(cloudKitServiceProvider).initialize();
    if (kDebugMode) {
      print(
        '[loadServerConfigProvider] CloudKit account status check complete.',
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('[loadServerConfigProvider] Error checking CloudKit status: $e');
    }
  }

  if (kDebugMode) {
    print('[loadServerConfigProvider] Initial data load sequence finished.');
  }
}, name: 'loadServerConfig');
