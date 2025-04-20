import 'dart:convert';

import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:flutter/foundation.dart';
// Removed import for multi_server_config_state.dart
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/mcp_server_config_provider.dart';
import 'package:flutter_memos/providers/note_server_config_provider.dart'; // Import new provider
import 'package:flutter_memos/providers/service_providers.dart'; // Import service provider
import 'package:flutter_memos/providers/settings_provider.dart';
import 'package:flutter_memos/providers/task_server_config_provider.dart'; // Import new provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart'; // Import Uuid

// --- Old Keys for Migration ---
const _multiServerConfigKey =
    'multi_server_config'; // Old multi-server list key
const _legacyServerUrlKey = 'server_url'; // Old single server URL key
const _legacyAuthTokenKey = 'auth_token'; // Old single server token key
const _serverConfigCacheKey =
    'server_config_cache'; // Old multi-server cache key (might contain MultiServerConfigState JSON)
const _oldDefaultServerIdKey = 'defaultServerId'; // Old default server ID key

// --- New Keys (Imported for migration check) ---
// These constants are defined in their respective files but needed here for the migration check.
const _noteServerConfigKey = 'note_server_config';
const _taskServerConfigKey = 'task_server_config';


// --- Removed MultiServerConfigNotifier ---

// --- Removed multiServerConfigProvider ---

// --- Removed activeServerConfigProvider ---

/// Provider for loading server configurations (Note, Task, MCP) on app startup
final loadServerConfigProvider = FutureProvider<void>((ref) async {
  if (kDebugMode) {
    print('[loadServerConfigProvider] Starting initial data load sequence...');
  }

  // --- Migration Logic ---
  await _runMigrationIfNeeded(ref);

  // --- Load Current Configurations ---
  // Load Note server config
  await ref.read(noteServerConfigProvider.notifier).loadConfiguration();
  if (kDebugMode) {
    print('[loadServerConfigProvider] Note server config load complete.');
  }

  // Load Task server config
  await ref.read(taskServerConfigProvider.notifier).loadConfiguration();
  if (kDebugMode) {
    print('[loadServerConfigProvider] Task server config load complete.');
  }

  // Load MCP server configs (remains multi-server)
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

  // --- Load Other Providers ---
  // Removed Todoist API key init here
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
    await ref.read(geminiApiKeyProvider.notifier).init(); // Added Gemini init
    if (kDebugMode) {
      print('[loadServerConfigProvider] Gemini API key load triggered.');
    }
  } catch (e) {
    if (kDebugMode) {
      print(
        '[loadServerConfigProvider] Error initializing Gemini provider: $e',
      );
    }
  }
  try {
    await ref.read(vikunjaApiKeyProvider.notifier).init(); // Added Vikunja init
    if (kDebugMode) {
      print('[loadServerConfigProvider] Vikunja API key load triggered.');
    }
  } catch (e) {
    if (kDebugMode) {
      print(
        '[loadServerConfigProvider] Error initializing Vikunja provider: $e',
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

// --- Migration Helper Functions ---

/// Check if a server type is valid for note-taking (used in migration).
bool _isValidNoteServerType(ServerType type) {
  return type == ServerType.memos ||
      type == ServerType.blinko ||
      type == ServerType.vikunja;
}

/// Check if a server type is valid for tasks (used in migration).
bool _isValidTaskServerType(ServerType type) {
  return type == ServerType.vikunja;
}

/// Helper function to perform one-time migration from old storage keys
Future<void> _runMigrationIfNeeded(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final noteNotifier = ref.read(noteServerConfigProvider.notifier);
  final taskNotifier = ref.read(taskServerConfigProvider.notifier);

  // Check if new keys already exist. If so, assume migration is done.
  if (prefs.containsKey(_noteServerConfigKey) ||
      prefs.containsKey(_taskServerConfigKey)) {
    if (kDebugMode) {
      print('[Migration] New config keys found. Skipping migration.');
    }
    // Clean up old keys just in case they linger
    await _removeOldKeys(prefs);
    return;
  }

  if (kDebugMode) {
    print('[Migration] Checking for old configuration data...');
  }

  List<ServerConfig> oldServers = [];
  String? oldDefaultServerId;

  // Priority 1: Try loading from the old cache key (_serverConfigCacheKey)
  final cachedJsonString = prefs.getString(_serverConfigCacheKey);
  if (cachedJsonString != null) {
    try {
      final decodedJson = jsonDecode(cachedJsonString) as Map<String, dynamic>;
      // This assumes the structure was {'servers': [...], 'defaultServerId': '...'}
      final serversList = decodedJson['servers'] as List<dynamic>? ?? [];
      oldServers =
          serversList
              .map((s) => ServerConfig.fromJson(s as Map<String, dynamic>))
              .where(
                (s) => s.serverType != ServerType.todoist,
              ) // Filter out Todoist
              .toList();
      oldDefaultServerId = decodedJson['defaultServerId'] as String?;
      if (kDebugMode) {
        print(
          '[Migration] Loaded ${oldServers.length} servers from old cache key ($_serverConfigCacheKey).',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[Migration] Error parsing old cache key ($_serverConfigCacheKey): $e. Trying next source.',
        );
      }
      oldServers = [];
      oldDefaultServerId = null;
    }
  }

  // Priority 2: Try loading from the older multi-server key (_multiServerConfigKey)
  if (oldServers.isEmpty) {
    final multiServerJsonString = prefs.getString(_multiServerConfigKey);
    if (multiServerJsonString != null) {
      try {
        final decodedJson =
            jsonDecode(multiServerJsonString) as Map<String, dynamic>;
        final serversList = decodedJson['servers'] as List<dynamic>? ?? [];
        oldServers =
            serversList
                .map((s) => ServerConfig.fromJson(s as Map<String, dynamic>))
                .where(
                  (s) => s.serverType != ServerType.todoist,
                ) // Filter out Todoist
                .toList();
        oldDefaultServerId = decodedJson['defaultServerId'] as String?;
        if (kDebugMode) {
          print(
            '[Migration] Loaded ${oldServers.length} servers from old multi-server key ($_multiServerConfigKey).',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[Migration] Error parsing old multi-server key ($_multiServerConfigKey): $e. Trying next source.',
          );
        }
        oldServers = [];
        oldDefaultServerId = null;
      }
    }
  }

  // Priority 3: Try loading from legacy single server keys
  if (oldServers.isEmpty) {
    final legacyUrl = prefs.getString(_legacyServerUrlKey);
    if (legacyUrl != null && legacyUrl.isNotEmpty) {
      final legacyToken = prefs.getString(_legacyAuthTokenKey);
      final migratedServer = ServerConfig(
        id: const Uuid().v4(),
        name: 'Migrated Server',
        serverUrl: legacyUrl,
        authToken: legacyToken ?? '',
        serverType: ServerType.memos, // Legacy was always Memos
      );
      oldServers = [migratedServer];
      oldDefaultServerId = migratedServer.id; // Assume legacy was default
      if (kDebugMode) {
        print('[Migration] Loaded 1 server from legacy keys.');
      }
    }
  }

  // If no old servers found, migration is not needed or possible
  if (oldServers.isEmpty) {
    if (kDebugMode) {
      print('[Migration] No old server configurations found to migrate.');
    }
    await _removeOldKeys(prefs); // Clean up just in case
    return;
  }

  if (kDebugMode) {
    print(
      '[Migration] Found ${oldServers.length} potential servers to migrate.',
    );
  }

  // --- Migration Logic: Assign servers to Note/Task ---
  ServerConfig? noteServerToMigrate;
  ServerConfig? taskServerToMigrate;

  // Try finding the default server first
  final defaultServer = oldServers.firstWhereOrNull(
    (s) => s.id == oldDefaultServerId,
  );

  if (defaultServer != null) {
    if (_isValidNoteServerType(defaultServer.serverType)) {
      noteServerToMigrate = defaultServer;
      if (kDebugMode) {
        print(
          '[Migration] Assigning default server ${defaultServer.id} (${defaultServer.serverType}) as Note server.',
        );
      }
    } else if (_isValidTaskServerType(defaultServer.serverType)) {
      taskServerToMigrate = defaultServer;
      if (kDebugMode) {
        print(
          '[Migration] Assigning default server ${defaultServer.id} (${defaultServer.serverType}) as Task server.',
        );
      }
    }
  }

  // Fill remaining slots by iterating through the list
  for (final server in oldServers) {
    // Skip if it was already assigned as default
    if (server.id == noteServerToMigrate?.id ||
        server.id == taskServerToMigrate?.id) {
      continue;
    }

    if (noteServerToMigrate == null &&
        _isValidNoteServerType(server.serverType)) {
      noteServerToMigrate = server;
      if (kDebugMode) {
        print(
          '[Migration] Assigning server ${server.id} (${server.serverType}) as Note server.',
        );
      }
    } else if (taskServerToMigrate == null &&
        _isValidTaskServerType(server.serverType)) {
      taskServerToMigrate = server;
      if (kDebugMode) {
        print(
          '[Migration] Assigning server ${server.id} (${server.serverType}) as Task server.',
        );
      }
    }

    // Stop if both slots are filled
    if (noteServerToMigrate != null && taskServerToMigrate != null) {
      break;
    }
  }

  // --- Save Migrated Configs ---
  bool migrationHappened = false;
  if (noteServerToMigrate != null) {
    if (kDebugMode) {
      print(
        '[Migration] Saving migrated Note server: ${noteServerToMigrate.id}',
      );
    }
    await noteNotifier.setConfiguration(noteServerToMigrate);
    migrationHappened = true;
  }
  if (taskServerToMigrate != null) {
    if (kDebugMode) {
      print(
        '[Migration] Saving migrated Task server: ${taskServerToMigrate.id}',
      );
    }
    await taskNotifier.setConfiguration(taskServerToMigrate);
    migrationHappened = true;
  }

  // --- Cleanup Old Keys ---
  if (migrationHappened) {
    if (kDebugMode) {
      print('[Migration] Migration complete. Removing old keys...');
    }
    await _removeOldKeys(prefs);
  } else {
    if (kDebugMode) {
      print('[Migration] No suitable servers found for migration.');
    }
    await _removeOldKeys(prefs); // Clean up anyway
  }
}

/// Helper to remove all known old SharedPreferences keys
Future<void> _removeOldKeys(SharedPreferences prefs) async {
  await prefs.remove(_serverConfigCacheKey);
  await prefs.remove(_multiServerConfigKey);
  await prefs.remove(_legacyServerUrlKey);
  await prefs.remove(_legacyAuthTokenKey);
  await prefs.remove(_oldDefaultServerIdKey);
  if (kDebugMode) {
    print('[Migration] Removed old SharedPreferences keys.');
  }
}
