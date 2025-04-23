import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart';
// Removed CloudKitService import
// import 'package:flutter_memos/providers/service_providers.dart';
// import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _taskServerConfigKey = 'task_server_config'; // Key for SharedPreferences

/// Notifier for managing the single Task server configuration with persistence
/// using SharedPreferences. CloudKit sync has been removed.
class TaskServerConfigNotifier extends StateNotifier<ServerConfig?> {
  // Removed Ref _ref and CloudKitService instance
  // final Ref _ref;
  // CloudKitService? _cloudKitService;

  TaskServerConfigNotifier(/* Removed Ref _ref */) : super(null) {
    // Removed CloudKit initialization
    // if (!kIsWeb) {
    //   _cloudKitService = _ref.read(cloudKitServiceProvider);
    // }
  }

  /// Load configuration from local cache (SharedPreferences).
  Future<void> loadConfiguration() async {
    if (kDebugMode) {
      print(
        '[TaskServerConfigNotifier] Starting configuration load from cache...',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    ServerConfig? initialStateFromCache;

    // Load from local cache (SharedPreferences)
    final cachedJsonString = prefs.getString(_taskServerConfigKey);
    if (cachedJsonString != null) {
      try {
        initialStateFromCache = ServerConfig.fromJson(
          jsonDecode(cachedJsonString) as Map<String, dynamic>,
        );
        // Ensure loaded type is valid for tasks (Vikunja?)
        if (!_isValidTaskServerType(initialStateFromCache.serverType)) {
           if (kDebugMode) {
             print(
               '[TaskServerConfigNotifier] Invalid server type (${initialStateFromCache.serverType}) loaded from cache. Discarding.',
             );
           }
           initialStateFromCache = null;
           await prefs.remove(_taskServerConfigKey); // Remove invalid cache
        } else if (kDebugMode) {
          print(
            '[TaskServerConfigNotifier] Loaded initial state from cache: ${initialStateFromCache.id}',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[TaskServerConfigNotifier] Error parsing cache JSON: $e. Clearing cache.',
          );
        }
        initialStateFromCache = null;
        await prefs.remove(_taskServerConfigKey);
      }
    }

    // Set initial state from cache immediately
    if (mounted) {
      state = initialStateFromCache;
      if (kDebugMode) {
        print(
          '[TaskServerConfigNotifier] Initial state set from cache. Server: ${state?.id}',
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
         if (!_isValidTaskServerType(config.serverType)) {
           if (kDebugMode) {
             print(
               '[TaskServerConfigNotifier] Attempted to cache invalid server type: ${config.serverType}. Aborting cache update.',
             );
           }
           return false;
         }
        final serverJson = jsonEncode(config.toJson());
        success = await prefs.setString(_taskServerConfigKey, serverJson);
      } else {
        success = await prefs.remove(_taskServerConfigKey);
      }
      if (kDebugMode) {
        print(
          '[TaskServerConfigNotifier] Updated local task server cache (success: $success). Cached server: ${config?.id}',
        );
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[TaskServerConfigNotifier] Error updating local task server cache: $e',
        );
      }
      return false;
    }
  }

  /// Set the task server configuration locally.
  Future<bool> setConfiguration(ServerConfig config) async {
     // Ensure type is valid
     if (!_isValidTaskServerType(config.serverType)) {
       if (kDebugMode) {
         print(
           '[TaskServerConfigNotifier] Attempted to set invalid server type: ${config.serverType}. Aborting.',
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
          '[TaskServerConfigNotifier] Set task server ${config.id} locally.',
        );
      }
      return true;
    } else {
      // Attempt to update cache even if not mounted, but return based on cache success
      return await _updateLocalCache(config);
    }
  }

  /// Remove the task server configuration locally.
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
          '[TaskServerConfigNotifier] Removed task server $currentConfigId locally.',
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
       print('[TaskServerConfigNotifier] Resetting state and clearing cache...');
     }
     if (mounted) {
       state = null; // Reset state
     }
     try {
       final prefs = await SharedPreferences.getInstance();
       await prefs.remove(_taskServerConfigKey); // Clear cache key
       if (kDebugMode) {
         print('[TaskServerConfigNotifier] Local cache key cleared.');
       }
     } catch (e) {
       if (kDebugMode) {
         print('[TaskServerConfigNotifier] Error clearing local cache: $e');
       }
     }
    // No CloudKit interaction needed for reset
   }

   /// Check if a server type is valid for tasks.
   bool _isValidTaskServerType(ServerType type) {
     // Currently, only Vikunja is a task server
     return type == ServerType.vikunja;
   }
}

/// Provider for the single Task server configuration state and management
final taskServerConfigProvider =
    StateNotifierProvider<TaskServerConfigNotifier, ServerConfig?>((ref) {
      // Removed ref dependency in constructor
      return TaskServerConfigNotifier();
}, name: 'taskServerConfigProvider');
