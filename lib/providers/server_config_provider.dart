import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/multi_server_config_state.dart'; // Import new state model
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/service_providers.dart'; // Import service provider
import 'package:flutter_memos/providers/settings_provider.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart'; // Import CloudKit service
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

  /// Load configuration, prioritizing local cache and syncing with CloudKit.
  Future<void> loadConfiguration() async {
    if (kDebugMode)
      print('[MultiServerConfigNotifier] Starting configuration load...');
    final prefs = await SharedPreferences.getInstance();
    MultiServerConfigState initialStateFromCache =
        const MultiServerConfigState();
    bool migrationNeededFromOldPrefs = false;

    // 1. Load initial state from local cache (or old prefs for migration)
    final cachedJsonString = prefs.getString(_serverConfigCacheKey);
    final multiServerJsonString = prefs.getString(
      _multiServerConfigKey,
    ); // Old multi-key
    final legacyUrl = prefs.getString(_legacyServerUrlKey); // Old legacy key

    if (cachedJsonString != null) {
      try {
        initialStateFromCache = MultiServerConfigState.fromJsonString(
          cachedJsonString,
        );
        if (kDebugMode)
          print(
            '[MultiServerConfigNotifier] Loaded initial state from cache: ${initialStateFromCache.servers.length} servers.',
          );
      } catch (e) {
        if (kDebugMode)
          print(
            '[MultiServerConfigNotifier] Error parsing cache JSON: $e. Starting fresh.',
          );
        initialStateFromCache = const MultiServerConfigState();
        await prefs.remove(_serverConfigCacheKey);
      }
    } else if (multiServerJsonString != null) {
      try {
        initialStateFromCache = MultiServerConfigState.fromJsonString(
          multiServerJsonString,
        );
        migrationNeededFromOldPrefs = true;
        if (kDebugMode)
          print(
            '[MultiServerConfigNotifier] Cache empty, using old multi-server prefs for initial state. Migration needed.',
          );
      } catch (e) {
        if (kDebugMode)
          print(
            '[MultiServerConfigNotifier] Error parsing old multi-server JSON: $e. Starting fresh.',
          );
        initialStateFromCache = const MultiServerConfigState();
        await prefs.remove(_multiServerConfigKey);
      }
    } else if (legacyUrl != null && legacyUrl.isNotEmpty) {
      final legacyToken = prefs.getString(_legacyAuthTokenKey);
      final migratedServer = ServerConfig(
        id: const Uuid().v4(),
        name: 'Migrated Server',
        serverUrl: legacyUrl,
        authToken: legacyToken ?? '',
      );
      initialStateFromCache = MultiServerConfigState(
        servers: [migratedServer],
        defaultServerId: migratedServer.id,
      );
      migrationNeededFromOldPrefs = true;
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Cache empty, using legacy prefs for initial state. Migration needed.',
        );
    } else {
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] No cache or old prefs found for initial state.',
        );
    }

    // Load default ID separately (always from prefs)
    final defaultServerId = prefs.getString('defaultServerId');
    final effectiveDefaultId =
        (defaultServerId != null &&
                initialStateFromCache.servers.any(
                  (s) => s.id == defaultServerId,
                ))
            ? defaultServerId
            : null;
    initialStateFromCache = initialStateFromCache.copyWith(
      defaultServerId: () => effectiveDefaultId,
    );

    // Determine initial active ID based on cached state and effective default
    String? initialActiveId = effectiveDefaultId;
    if (initialActiveId == null && initialStateFromCache.servers.isNotEmpty) {
      initialActiveId = initialStateFromCache.servers.first.id;
    }
    if (initialActiveId != null &&
        !initialStateFromCache.servers.any((s) => s.id == initialActiveId)) {
      initialActiveId = initialStateFromCache.servers.firstOrNull?.id;
    }
    initialStateFromCache = initialStateFromCache.copyWith(
      activeServerId: initialActiveId,
    );

    // Set initial state immediately from cache/migration source
    if (mounted) {
      state = initialStateFromCache;
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Initial state set from cache/prefs. Servers: ${state.servers.length}, ActiveId: ${state.activeServerId}, DefaultId: ${state.defaultServerId}',
        );
    } else {
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Notifier unmounted before initial state could be set.',
        );
      return;
    }

    // --- Now, fetch from CloudKit asynchronously ---
    try {
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Fetching latest data from CloudKit...',
        );
      final cloudServers = await _cloudKitService.getAllServerConfigs();
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] CloudKit fetch successful: ${cloudServers.length} servers.',
        );

      final listEquals = const DeepCollectionEquality().equals;
      final currentServers = state.servers;

      if (!listEquals(cloudServers, currentServers)) {
        if (kDebugMode)
          print(
            '[MultiServerConfigNotifier] CloudKit data differs from cache. Updating state and cache...',
          );

        final newDefaultId = prefs.getString('defaultServerId');
        final effectiveNewDefaultId =
            (newDefaultId != null &&
                    cloudServers.any((s) => s.id == newDefaultId))
                ? newDefaultId
                : null;

        // Check if the old default ID (read from prefs earlier) is now invalid
        final oldDefaultIdFromPrefs = prefs.getString(
          'defaultServerId',
        ); // Re-read or use value read at start
        if (oldDefaultIdFromPrefs != null &&
            !cloudServers.any((s) => s.id == oldDefaultIdFromPrefs)) {
          if (kDebugMode) {
            print(
              '[MultiServerConfigNotifier] Old default server ID $oldDefaultIdFromPrefs is no longer valid after CloudKit sync. Clearing from prefs.',
            );
          }
          await prefs.remove(
            'defaultServerId',
          ); // Remove the invalid default ID
        }

        String? newActiveId = effectiveNewDefaultId;
        if (newActiveId == null && cloudServers.isNotEmpty) {
          newActiveId = cloudServers.first.id;
        }
        if (newActiveId != null &&
            !cloudServers.any((s) => s.id == newActiveId)) {
          newActiveId = cloudServers.firstOrNull?.id;
        }

        if (mounted) {
          state = MultiServerConfigState(
            servers: cloudServers,
            defaultServerId: effectiveNewDefaultId,
            activeServerId: newActiveId,
          );
          if (kDebugMode)
            print(
              '[MultiServerConfigNotifier] State updated from CloudKit. Servers: ${state.servers.length}, ActiveId: ${state.activeServerId}, DefaultId: ${state.defaultServerId}',
            );
          await _updateLocalCache(state.servers);
        } else {
          if (kDebugMode)
            print(
              '[MultiServerConfigNotifier] Notifier unmounted before CloudKit update could be applied.',
            );
        }
      } else {
        if (kDebugMode)
          print(
            '[MultiServerConfigNotifier] CloudKit data matches cache. No update needed.',
          );
      }

      if (migrationNeededFromOldPrefs) {
        if (kDebugMode)
          print('[MultiServerConfigNotifier] Performing migration cleanup...');
        await _migratePrefsToCloudKit(
          initialStateFromCache.servers,
          initialStateFromCache.defaultServerId,
        );
        if (multiServerJsonString != null)
          await prefs.remove(_multiServerConfigKey);
        if (legacyUrl != null) {
          await prefs.remove(_legacyServerUrlKey);
          await prefs.remove(_legacyAuthTokenKey);
        }
        await _updateLocalCache(initialStateFromCache.servers);
        if (kDebugMode)
          print('[MultiServerConfigNotifier] Migration cleanup complete.');
      } else if (cachedJsonString == null &&
          (multiServerJsonString != null || legacyUrl != null)) {
        if (mounted) {
          await _updateLocalCache(state.servers);
          if (kDebugMode)
            print(
              '[MultiServerConfigNotifier] Populated empty cache after checking CloudKit during migration.',
            );
        }
      }
    } catch (e) {
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Error during async CloudKit fetch: $e. Continuing with cached data.',
        );
    }
  }

  // Helper to update the local SharedPreferences cache
  Future<bool> _updateLocalCache(List<ServerConfig> servers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheState = MultiServerConfigState(servers: servers);
      final success = await prefs.setString(
        _serverConfigCacheKey,
        cacheState.toJsonString(),
      );
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Updated local server cache (success: $success). Cached ${servers.length} servers.',
        );
      return success;
    } catch (e) {
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Error updating local server cache: $e',
        );
      return false;
    }
  }

  // _migratePrefsToCloudKit remains the same...
  Future<void> _migratePrefsToCloudKit(
    List<ServerConfig> servers,
    String? defaultId,
  ) async {
    if (kDebugMode)
      print(
        '[MultiServerConfigNotifier] Attempting background migration of ${servers.length} servers to CloudKit...',
      );
    for (final server in servers) {
      try {
        await _cloudKitService.saveServerConfig(server);
      } catch (e) {
        if (kDebugMode)
          print(
            '[MultiServerConfigNotifier] Error migrating server ${server.id} to CloudKit: $e',
          );
      }
    }
    if (kDebugMode)
      print(
        '[MultiServerConfigNotifier] Background migration attempt complete.',
      );
  }

  /// Save only the default server ID to SharedPreferences
  Future<bool> _saveDefaultServerIdToPreferences(
    String? defaultServerId,
  ) async {
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
    if (state.servers.any((s) => s.id == config.id)) {
      if (kDebugMode) {
        print(
          '[MultiServerConfigNotifier] Attempted to add server with duplicate ID: ${config.id}',
        );
      }
      return false;
    }

    // 1. Sync change to CloudKit FIRST
    final cloudSuccess = await _cloudKitService.saveServerConfig(config);

    if (cloudSuccess) {
      if (!mounted) {
        if (kDebugMode)
          print(
            '[MultiServerConfigNotifier] AddServer: Notifier unmounted after CloudKit success. State/cache not updated.',
          );
        return true;
      }

      final newServers = [...state.servers, config];
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

      await _updateLocalCache(newServers);

      if (defaultChanged) {
        await _saveDefaultServerIdToPreferences(newDefaultId);
      }
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Added server ${config.id} locally and synced to CloudKit.',
        );
      return true;
    } else {
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Failed to sync added server ${config.id} to CloudKit. Local state/cache not changed.',
        );
      return false;
    }
  }

  /// Update an existing server configuration locally and sync to CloudKit
  Future<bool> updateServer(ServerConfig updatedConfig) async {
    final index = state.servers.indexWhere((s) => s.id == updatedConfig.id);
    if (index == -1) {
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] UpdateServer: Server ID ${updatedConfig.id} not found.',
        );
      return false;
    }

    // 1. Sync change to CloudKit FIRST
    final cloudSuccess = await _cloudKitService.saveServerConfig(updatedConfig);

    if (cloudSuccess) {
      if (!mounted) {
        if (kDebugMode)
          print(
            '[MultiServerConfigNotifier] UpdateServer: Notifier unmounted after CloudKit success. State/cache not updated.',
          );
        return true;
      }

      final newServers = [...state.servers];
      newServers[index] = updatedConfig;
      state = state.copyWith(servers: newServers);

      await _updateLocalCache(newServers);
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Updated server ${updatedConfig.id} locally and synced to CloudKit.',
        );
      return true;
    } else {
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Failed to sync updated server ${updatedConfig.id} to CloudKit. Local state/cache not changed.',
        );
      return false;
    }
  }

  /// Remove a server configuration locally and sync deletion to CloudKit
  Future<bool> removeServer(String serverId) async {
    final serverToRemove = state.servers.firstWhereOrNull(
      (s) => s.id == serverId,
    );
    if (serverToRemove == null) {
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] RemoveServer: Server ID $serverId not found.',
        );
      return false;
    }

    // 1. Sync deletion to CloudKit FIRST
    final cloudSuccess = await _cloudKitService.deleteServerConfig(serverId);

    if (cloudSuccess) {
      if (!mounted) {
        if (kDebugMode)
          print(
            '[MultiServerConfigNotifier] RemoveServer: Notifier unmounted after CloudKit success. State/cache not updated.',
          );
        return true;
      }

      final newServers = state.servers.where((s) => s.id != serverId).toList();

      String? newDefaultId = state.defaultServerId;
      String? newActiveId = state.activeServerId;
      bool defaultChanged = false;

      if (newServers.isEmpty) {
        if (kDebugMode)
          print(
            '[MultiServerConfigNotifier] Removed the last server. Resetting active and default IDs.',
          );
        newDefaultId = null;
        newActiveId = null;
        defaultChanged = state.defaultServerId != null;
      } else {
        if (state.defaultServerId == serverId) {
          newDefaultId = newServers.first.id;
          defaultChanged = true;
          if (kDebugMode)
            print(
              '[MultiServerConfigNotifier] Removed default server $serverId. Setting new default to $newDefaultId.',
            );
        }
        if (state.activeServerId == serverId) {
          newActiveId = newDefaultId ?? newServers.first.id;
          if (kDebugMode)
            print(
              '[MultiServerConfigNotifier] Removed active server $serverId. Setting new active to $newActiveId.',
            );
        }
      }

      state = state.copyWith(
        servers: newServers,
        defaultServerId: () => newDefaultId,
        activeServerId: newActiveId,
      );

      await _updateLocalCache(newServers);

      if (defaultChanged) {
        await _saveDefaultServerIdToPreferences(newDefaultId);
      }
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Removed server $serverId locally and synced deletion to CloudKit.',
        );
      return true;
    } else {
      if (kDebugMode)
        print(
          '[MultiServerConfigNotifier] Failed to sync deleted server $serverId to CloudKit. Local state/cache not changed.',
        );
      return false;
    }
  }

  /// Set the active server for the current session (no persistence change)
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
    }
  }

  /// Set the default server and save it to SharedPreferences
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
      final newState = state.copyWith(defaultServerId: () => serverId);
      state = newState;
      return _saveDefaultServerIdToPreferences(serverId);
    }
    return true;
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

  final activeServer = multiConfigState.servers.firstWhereOrNull(
    (s) => s.id == activeId,
  );
  return activeServer;
}, name: 'activeServerConfig');

/// Provider for loading server configuration on app startup
final loadServerConfigProvider = FutureProvider<void>((ref) async {
  if (kDebugMode)
    print('[loadServerConfigProvider] Starting initial data load sequence...');

  await ref.read(multiServerConfigProvider.notifier).loadConfiguration();
  if (kDebugMode)
    print('[loadServerConfigProvider] Server config load complete.');

  try {
    await ref.read(todoistApiKeyProvider.notifier).init();
    if (kDebugMode)
      print('[loadServerConfigProvider] Todoist API key load triggered.');
  } catch (e) {
    if (kDebugMode)
      print(
        '[loadServerConfigProvider] Error initializing Todoist provider: $e',
      );
  }
  try {
    await ref.read(openAiApiKeyProvider.notifier).init();
    if (kDebugMode)
      print('[loadServerConfigProvider] OpenAI API key load triggered.');
  } catch (e) {
    if (kDebugMode)
      print(
        '[loadServerConfigProvider] Error initializing OpenAI provider: $e',
      );
  }

  try {
    await ref.read(cloudKitServiceProvider).initialize();
    if (kDebugMode)
      print(
        '[loadServerConfigProvider] CloudKit account status check complete.',
      );
  } catch (e) {
    if (kDebugMode)
      print('[loadServerConfigProvider] Error checking CloudKit status: $e');
  }

  if (kDebugMode)
    print('[loadServerConfigProvider] Initial data load sequence finished.');
}, name: 'loadServerConfig');
