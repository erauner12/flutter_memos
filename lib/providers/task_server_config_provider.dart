import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _taskServerConfigKey = 'task_server_config'; // Key for SharedPreferences

/// Notifier for managing the single Task server configuration with persistence
class TaskServerConfigNotifier extends StateNotifier<ServerConfig?> {
  final Ref _ref;

  TaskServerConfigNotifier(this._ref) : super(null);

  /// Load configuration, prioritizing local cache, then CloudKit.
  Future<void> loadConfiguration() async {
    if (kDebugMode) {
      print('[TaskServerConfigNotifier] Starting configuration load...');
    }
    final prefs = await SharedPreferences.getInstance();
    ServerConfig? initialStateFromCache;

    // 1. Load from local cache
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

    // --- Now, fetch from CloudKit asynchronously ---
    // TODO: Implement CloudKit sync logic for a single Task server config
    // Similar to NoteServerConfigNotifier, but for a Task server record type.
    try {
      if (kDebugMode) {
        print('[TaskServerConfigNotifier] Fetching Task server from CloudKit...');
      }
      // Example: Fetching a specific record (adapt CloudKitService)
      // final cloudConfig = await _cloudKitService.getTaskServerConfig();
      // if (cloudConfig != null && cloudConfig != state) {
      //   if (mounted) {
      //     state = cloudConfig;
      //     await _updateLocalCache(cloudConfig);
      //     print('[TaskServerConfigNotifier] Updated state from CloudKit.');
      //   }
      // } else if (cloudConfig == null && state != null) {
      //   print('[TaskServerConfigNotifier] CloudKit empty, local exists. Consider uploading.');
      //   // await _cloudKitService.saveTaskServerConfig(state!);
      // }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[TaskServerConfigNotifier] Error during CloudKit fetch: $e. Continuing with local data.',
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

  /// Set the task server configuration locally and sync to CloudKit
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

    // TODO: Sync change to CloudKit FIRST
    // final cloudSuccess = await _cloudKitService.saveTaskServerConfig(config);
    final cloudSuccess = true; // Placeholder

    if (cloudSuccess) {
      if (!mounted) return true; // CloudKit succeeded

      state = config; // Update local state
      await _updateLocalCache(config); // Update local cache
      if (kDebugMode) {
        print(
          '[TaskServerConfigNotifier] Set task server ${config.id} locally and synced to CloudKit.',
        );
      }
      return true;
    } else {
      if (kDebugMode) {
        print(
          '[TaskServerConfigNotifier] Failed to sync task server ${config.id} to CloudKit. Local state/cache not changed.',
        );
      }
      return false;
    }
  }

  /// Remove the task server configuration locally and sync deletion to CloudKit
  Future<bool> removeConfiguration() async {
    final currentConfigId = state?.id;
    if (currentConfigId == null) return true; // Nothing to remove

    // TODO: Sync deletion to CloudKit FIRST
    // final cloudSuccess = await _cloudKitService.deleteTaskServerConfig(currentConfigId);
    final cloudSuccess = true; // Placeholder

    if (cloudSuccess) {
      if (!mounted) return true; // CloudKit succeeded

      state = null; // Update local state
      await _updateLocalCache(null); // Update local cache
      if (kDebugMode) {
        print(
          '[TaskServerConfigNotifier] Removed task server $currentConfigId locally and synced deletion to CloudKit.',
        );
      }
      return true;
    } else {
      if (kDebugMode) {
        print(
          '[TaskServerConfigNotifier] Failed to sync deleted task server $currentConfigId to CloudKit. Local state/cache not changed.',
        );
      }
      return false;
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
  return TaskServerConfigNotifier(ref);
}, name: 'taskServerConfigProvider');
