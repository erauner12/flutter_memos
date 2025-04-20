import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _noteServerConfigKey = 'note_server_config'; // Key for SharedPreferences

/// Notifier for managing the single Note server configuration with persistence
class NoteServerConfigNotifier extends StateNotifier<ServerConfig?> {
  final Ref _ref;

  NoteServerConfigNotifier(this._ref) : super(null);

  /// Load configuration, prioritizing local cache, then CloudKit.
  Future<void> loadConfiguration() async {
    if (kDebugMode) {
      print('[NoteServerConfigNotifier] Starting configuration load...');
    }
    final prefs = await SharedPreferences.getInstance();
    ServerConfig? initialStateFromCache;

    // 1. Load from local cache
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

    // --- Now, fetch from CloudKit asynchronously ---
    // TODO: Implement CloudKit sync logic for a single Note server config
    // This would involve:
    // 1. Defining a specific CloudKit record type or identifier for the Note server.
    // 2. Fetching that specific record.
    // 3. Comparing with local state and updating if necessary (local cache, state, CloudKit).
    // 4. Handling potential conflicts (e.g., local vs. cloud).
    try {
      if (kDebugMode) {
        print('[NoteServerConfigNotifier] Fetching Note server from CloudKit...');
      }
      // Example: Fetching a specific record (adapt CloudKitService)
      // final cloudConfig = await _cloudKitService.getNoteServerConfig();
      // if (cloudConfig != null && cloudConfig != state) {
      //   if (mounted) {
      //     state = cloudConfig;
      //     await _updateLocalCache(cloudConfig);
      //     print('[NoteServerConfigNotifier] Updated state from CloudKit.');
      //   }
      // } else if (cloudConfig == null && state != null) {
      //   // If cloud is empty but local exists, maybe upload local?
      //   print('[NoteServerConfigNotifier] CloudKit empty, local exists. Consider uploading.');
      //   // await _cloudKitService.saveNoteServerConfig(state!);
      // }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[NoteServerConfigNotifier] Error during CloudKit fetch: $e. Continuing with local data.',
        );
      }
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

  /// Set the note server configuration locally and sync to CloudKit
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

    // TODO: Sync change to CloudKit FIRST
    // final cloudSuccess = await _cloudKitService.saveNoteServerConfig(config);
    final cloudSuccess = true; // Placeholder

    if (cloudSuccess) {
      if (!mounted) return true; // CloudKit succeeded

      state = config; // Update local state
      await _updateLocalCache(config); // Update local cache
      if (kDebugMode) {
        print(
          '[NoteServerConfigNotifier] Set note server ${config.id} locally and synced to CloudKit.',
        );
      }
      return true;
    }
  }

  /// Remove the note server configuration locally and sync deletion to CloudKit
  Future<bool> removeConfiguration() async {
    final currentConfigId = state?.id;
    if (currentConfigId == null) return true; // Nothing to remove

    // TODO: Sync deletion to CloudKit FIRST
    // final cloudSuccess = await _cloudKitService.deleteNoteServerConfig(currentConfigId);
    final cloudSuccess = true; // Placeholder

    if (cloudSuccess) {
      if (!mounted) return true; // CloudKit succeeded

      state = null; // Update local state
      await _updateLocalCache(null); // Update local cache
      if (kDebugMode) {
        print(
          '[NoteServerConfigNotifier] Removed note server $currentConfigId locally and synced deletion to CloudKit.',
        );
      }
      return true;
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
   }

  /// Check if a server type is valid for note-taking.
  bool _isValidNoteServerType(ServerType type) {
    // Allow Memos and Blinko ONLY
    return type == ServerType.memos || type == ServerType.blinko;
  }
}

/// Provider for the single Note server configuration state and management
final noteServerConfigProvider =
    StateNotifierProvider<NoteServerConfigNotifier, ServerConfig?>((ref) {
  return NoteServerConfigNotifier(ref);
}, name: 'noteServerConfigProvider');
