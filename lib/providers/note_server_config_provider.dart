import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart';
// Import CloudKitService to potentially use it (though it will be disabled on web)
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _noteServerConfigKey = 'note_server_config'; // Key for SharedPreferences

/// Notifier for managing the single Note server configuration with persistence
class NoteServerConfigNotifier extends StateNotifier<ServerConfig?> {
  final Ref _ref;
  // Lazily get CloudKitService only when needed (and not on web)
  CloudKitService? _cloudKitService;

  NoteServerConfigNotifier(this._ref) : super(null) {
    if (!kIsWeb) {
      _cloudKitService = _ref.read(cloudKitServiceProvider);
    }
  }

  /// Load configuration, prioritizing local cache, then CloudKit (if not web).
  Future<void> loadConfiguration() async {
    if (kDebugMode) {
      print('[NoteServerConfigNotifier] Starting configuration load...');
    }
    final prefs = await SharedPreferences.getInstance();
    ServerConfig? initialStateFromCache;

    // 1. Load from local cache (SharedPreferences)
    final cachedJsonString = prefs.getString(_noteServerConfigKey);
    if (cachedJsonString != null) {
      try {
        initialStateFromCache = ServerConfig.fromJson(
          jsonDecode(cachedJsonString) as Map<String, dynamic>,
        );
        // Ensure loaded type is valid for notes (Memos, Blinko ONLY)
        if (!_isValidNoteServerType(initialStateFromCache.serverType)) {
           if (kDebugMode) {
             print(
              '[NoteServerConfigNotifier] Invalid server type (${initialStateFromCache.serverType}) loaded from cache for Note server. Discarding.',
             );
           }
           initialStateFromCache = null;
           await prefs.remove(_noteServerConfigKey); // Remove invalid cache
        } else if (kDebugMode) {
          print(
            '[NoteServerConfigNotifier] Loaded initial state from cache: ${initialStateFromCache.id}',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[NoteServerConfigNotifier] Error parsing cache JSON: $e. Clearing cache.',
          );
        }
        initialStateFromCache = null;
        await prefs.remove(_noteServerConfigKey);
      }
    }

    // Set initial state from cache immediately
    if (mounted) {
      state = initialStateFromCache;
      if (kDebugMode) {
        print(
          '[NoteServerConfigNotifier] Initial state set from cache. Server: ${state?.id}',
        );
      }
    }

    // --- Now, fetch from CloudKit asynchronously (ONLY if not on web) ---
    if (!kIsWeb && _cloudKitService != null) {
      // TODO: Implement CloudKit sync logic for a single Note server config
      // This would involve:
      // 1. Defining a specific CloudKit record type or identifier for the Note server.
      // 2. Fetching that specific record using _cloudKitService.
      // 3. Comparing with local state and updating if necessary (local cache, state, CloudKit).
      // 4. Handling potential conflicts (e.g., local vs. cloud).
      try {
        if (kDebugMode) {
          print(
            '[NoteServerConfigNotifier] Fetching Note server from CloudKit...',
          );
        }
        // Example: Fetching a specific record (adapt CloudKitService if needed)
        // final cloudConfig = await _cloudKitService.getNoteServerConfig(); // Assuming this method exists
        // if (cloudConfig != null && cloudConfig != state) {
        //   if (mounted) {
        //     state = cloudConfig;
        //     await _updateLocalCache(cloudConfig);
        //     print('[NoteServerConfigNotifier] Updated state from CloudKit.');
        //   }
        // } else if (cloudConfig == null && state != null) {
        //   // If cloud is empty but local exists, maybe upload local?
        //   print('[NoteServerConfigNotifier] CloudKit empty, local exists. Consider uploading.');
        //   // await _cloudKitService.saveNoteServerConfig(state!); // Assuming this method exists
        // }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[NoteServerConfigNotifier] Error during CloudKit fetch: $e. Continuing with local data.',
          );
        }
      }
    } else if (kIsWeb) {
      if (kDebugMode)
        print('[NoteServerConfigNotifier] Skipping CloudKit fetch on web.');
    }
  }

  /// Helper to update the local SharedPreferences cache
  Future<bool> _updateLocalCache(ServerConfig? config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool success;
      if (config != null) {
        // Ensure type is valid before saving
        if (!_isValidNoteServerType(config.serverType)) {
          if (kDebugMode) {
            print(
              '[NoteServerConfigNotifier] Attempted to cache invalid server type for Note server: ${config.serverType}. Aborting cache update.',
            );
          }
          return false;
        }
        final serverJson = jsonEncode(config.toJson());
        success = await prefs.setString(_noteServerConfigKey, serverJson);
      } else {
        success = await prefs.remove(_noteServerConfigKey);
      }
      if (kDebugMode) {
        print(
          '[NoteServerConfigNotifier] Updated local note server cache (success: $success). Cached server: ${config?.id}',
        );
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[NoteServerConfigNotifier] Error updating local note server cache: $e',
        );
      }
      return false;
    }
  }

  /// Set the note server configuration locally and sync to CloudKit (if not web)
  Future<bool> setConfiguration(ServerConfig config) async {
    // Ensure type is valid
     if (!_isValidNoteServerType(config.serverType)) {
       if (kDebugMode) {
         print(
          '[NoteServerConfigNotifier] Attempted to set invalid server type for Note server: ${config.serverType}. Aborting.',
         );
       }
       return false;
     }

    bool cloudSuccess = true; // Assume success if on web or CloudKit disabled

    // Sync change to CloudKit FIRST (only if not on web)
    if (!kIsWeb && _cloudKitService != null) {
      try {
        if (kDebugMode)
          print(
            '[NoteServerConfigNotifier] Syncing setConfiguration to CloudKit...',
          );
        // TODO: Implement saving a single Note server config to CloudKit
        // cloudSuccess = await _cloudKitService.saveNoteServerConfig(config); // Assuming this method exists
        cloudSuccess = true; // Placeholder until CloudKit method is implemented
        if (kDebugMode)
          print(
            '[NoteServerConfigNotifier] CloudKit sync result: $cloudSuccess',
          );
      } catch (e) {
        if (kDebugMode)
          print(
            '[NoteServerConfigNotifier] Error syncing setConfiguration to CloudKit: $e',
          );
        cloudSuccess = false;
      }
    } else if (kIsWeb) {
      if (kDebugMode)
        print(
          '[NoteServerConfigNotifier] Skipping CloudKit sync for setConfiguration on web.',
        );
    }

    if (cloudSuccess) {
      if (!mounted)
        return true; // CloudKit succeeded (or was skipped), but widget unmounted

      state = config; // Update local state
      await _updateLocalCache(config); // Update local cache
      if (kDebugMode) {
        print(
          '[NoteServerConfigNotifier] Set note server ${config.id} locally ${kIsWeb ? "(web)" : "and synced to CloudKit"}.',
        );
      }
      return true;
    } else {
      if (kDebugMode)
        print(
          '[NoteServerConfigNotifier] CloudKit sync failed for setConfiguration. Local state/cache not updated.',
        );
      return false; // CloudKit sync failed
    }
  }

  /// Remove the note server configuration locally and sync deletion to CloudKit (if not web)
  Future<bool> removeConfiguration() async {
    final currentConfigId = state?.id;
    if (currentConfigId == null) return true; // Nothing to remove

    bool cloudSuccess = true; // Assume success if on web or CloudKit disabled

    // Sync deletion to CloudKit FIRST (only if not on web)
    if (!kIsWeb && _cloudKitService != null) {
      try {
        if (kDebugMode)
          print(
            '[NoteServerConfigNotifier] Syncing removeConfiguration to CloudKit...',
          );
        // TODO: Implement deleting a single Note server config from CloudKit
        // cloudSuccess = await _cloudKitService.deleteNoteServerConfig(currentConfigId); // Assuming this method exists
        cloudSuccess = true; // Placeholder until CloudKit method is implemented
        if (kDebugMode)
          print(
            '[NoteServerConfigNotifier] CloudKit deletion sync result: $cloudSuccess',
          );
      } catch (e) {
        if (kDebugMode)
          print(
            '[NoteServerConfigNotifier] Error syncing removeConfiguration to CloudKit: $e',
          );
        cloudSuccess = false;
      }
    } else if (kIsWeb) {
      if (kDebugMode)
        print(
          '[NoteServerConfigNotifier] Skipping CloudKit sync for removeConfiguration on web.',
        );
    }

    if (cloudSuccess) {
      if (!mounted)
        return true; // CloudKit succeeded (or was skipped), but widget unmounted

      state = null; // Update local state
      await _updateLocalCache(null); // Update local cache
      if (kDebugMode) {
        print(
          '[NoteServerConfigNotifier] Removed note server $currentConfigId locally ${kIsWeb ? "(web)" : "and synced deletion to CloudKit"}.',
        );
      }
      return true;
    } else {
      if (kDebugMode)
        print(
          '[NoteServerConfigNotifier] CloudKit deletion sync failed. Local state/cache not updated.',
        );
      return false; // CloudKit sync failed
    }
  }

  /// Resets the notifier state and clears associated local cache.
  Future<void> resetStateAndCache() async {
     if (kDebugMode) {
       print('[NoteServerConfigNotifier] Resetting state and clearing cache...');
     }
     if (mounted) {
       state = null; // Reset state
     }
     try {
       final prefs = await SharedPreferences.getInstance();
       await prefs.remove(_noteServerConfigKey); // Clear cache key
       if (kDebugMode) {
         print('[NoteServerConfigNotifier] Local cache key cleared.');
       }
     } catch (e) {
       if (kDebugMode) {
         print('[NoteServerConfigNotifier] Error clearing local cache: $e');
       }
     }
    // No CloudKit interaction needed for reset, as CloudKit data is cleared elsewhere (e.g., SettingsScreen reset)
   }

  /// Check if a server type is valid for note-taking.
  bool _isValidNoteServerType(ServerType type) {
    // Allow Memos and Blinko ONLY
    // TODO: Re-evaluate if Vikunja should be allowed as a Note server
    return type == ServerType.memos || type == ServerType.blinko;
  }
}

/// Provider for the single Note server configuration state and management
final noteServerConfigProvider =
    StateNotifierProvider<NoteServerConfigNotifier, ServerConfig?>((ref) {
  return NoteServerConfigNotifier(ref);
}, name: 'noteServerConfigProvider');
