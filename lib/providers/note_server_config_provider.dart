import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart';
// Removed CloudKitService import
// import 'package:flutter_memos/providers/service_providers.dart';
// import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _noteServerConfigKey = 'note_server_config'; // Key for SharedPreferences

/// Notifier for managing the single Note server configuration with persistence
/// using SharedPreferences. CloudKit sync has been removed.
class NoteServerConfigNotifier extends StateNotifier<ServerConfig?> {
  // Removed Ref _ref and CloudKitService instance
  // final Ref _ref;
  // CloudKitService? _cloudKitService;

  NoteServerConfigNotifier(/* Removed Ref _ref */) : super(null) {
    // Removed CloudKit initialization
    // if (!kIsWeb) {
    //   _cloudKitService = _ref.read(cloudKitServiceProvider);
    // }
  }

  /// Load configuration from local cache (SharedPreferences).
  Future<void> loadConfiguration() async {
    if (kDebugMode) {
      print(
        '[NoteServerConfigNotifier] Starting configuration load from cache...',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    ServerConfig? initialStateFromCache;

    // Load from local cache (SharedPreferences)
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

    // --- Removed CloudKit fetch logic ---
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

  /// Set the note server configuration locally.
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

    // --- Removed CloudKit sync logic ---

    // Update local state and cache directly
    if (mounted) {
      state = config; // Update local state
      await _updateLocalCache(config); // Update local cache
      if (kDebugMode) {
        print(
          '[NoteServerConfigNotifier] Set note server ${config.id} locally.',
        );
      }
      return true;
    } else {
      // Attempt to update cache even if not mounted, but return based on cache success
      return await _updateLocalCache(config);
    }
  }

  /// Remove the note server configuration locally.
  Future<bool> removeConfiguration() async {
    final currentConfigId = state?.id;
    if (currentConfigId == null) return true; // Nothing to remove

    // --- Removed CloudKit sync logic ---

    // Update local state and cache directly
    if (mounted) {
      state = null; // Update local state
      await _updateLocalCache(null); // Update local cache
      if (kDebugMode) {
        print(
          '[NoteServerConfigNotifier] Removed note server $currentConfigId locally.',
        );
      }
      return true;
    } else {
      // Attempt to update cache even if not mounted, but return based on cache success
      return await _updateLocalCache(null);
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
    // No CloudKit interaction needed for reset
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
      // Removed ref dependency in constructor
      return NoteServerConfigNotifier();
}, name: 'noteServerConfigProvider');
