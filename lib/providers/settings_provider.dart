import 'package:flutter/foundation.dart';
// Add Ref and CloudKitService imports
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences storage (now primarily for migration check)
/// and SecureStorage / CloudKit keys.
class PreferenceKeys {
  static const String todoistApiKey = 'todoist_api_key';
  static const String openAiApiKey = 'openai_api_key'; // Added OpenAI key
  // Add other preference keys as needed
}

/// Provider for the Todoist API key with persistence using SharedPreferences
final todoistApiKeyProvider =
    StateNotifierProvider<PersistentStringNotifier, String>(
      (ref) => PersistentStringNotifier(
        // Pass ref
        ref, // Pass ref
        '', // default empty value
        PreferenceKeys.todoistApiKey, // storage key
      ),
      name: 'todoistApiKey',
    );

/// Provider for the OpenAI API key with persistence using SharedPreferences
final openAiApiKeyProvider =
    StateNotifierProvider<PersistentStringNotifier, String>(
      (ref) => PersistentStringNotifier(
        // Pass ref
        ref, // Pass ref
        '', // default empty value
        PreferenceKeys.openAiApiKey, // storage key for OpenAI
      ),
      name: 'openAiApiKey', // Provider name
    );


/// A StateNotifier that persists string values to SharedPreferences
class PersistentStringNotifier extends StateNotifier<String> {
  final Ref _ref; // Add ref
  final String preferenceKey; // Used for SecureStorage key AND CloudKit key
  late final CloudKitService _cloudKitService; // Add service instance
  // Make _secureStorage non-final to allow replacement in tests
  FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _initialized = false;
  bool _cloudKitChecked = false; // Flag to prevent redundant CloudKit checks

  // Add visible for testing setter
  @visibleForTesting
  set debugSecureStorage(FlutterSecureStorage storage) {
    _secureStorage = storage;
  }

  // Update constructor - REMOVE _loadValue() call
  PersistentStringNotifier(this._ref, super.initialState, this.preferenceKey) {
    _cloudKitService = _ref.read(cloudKitServiceProvider);
    // DO NOT CALL _loadValue() here anymore
  }

  // Add init method to be called externally
  Future<void> init() async {
    // Prevent multiple initializations
    if (_initialized) return;
    await _loadValue();
  }

  // Rename and modify loading logic
  Future<void> _loadValue() async {
    // Prevent multiple initializations if called again somehow
    if (_initialized && _cloudKitChecked) return;

    String? initialValue;
    bool migrationNeededFromPrefs = false;

    // 1. Load initial value from Secure Storage
    try {
      initialValue = await _secureStorage.read(key: preferenceKey);
      if (kDebugMode && initialValue != null) {
        print(
          '[PersistentStringNotifier] Loaded initial value for $preferenceKey from Secure Storage: ${initialValue.isNotEmpty ? "present" : "empty"}',
        );
      }
    } catch (e) {
      if (kDebugMode)
        print(
          '[PersistentStringNotifier] Error reading $preferenceKey from Secure Storage: $e',
        );
      // Potentially clear corrupted value? For now, just log.
      // await _secureStorage.delete(key: preferenceKey);
    }

    // 2. If not in Secure Storage, check old SharedPreferences key for migration
    final prefs = await SharedPreferences.getInstance();
    final oldPrefsValue = prefs.getString(preferenceKey);
    if (initialValue == null && oldPrefsValue != null) {
      initialValue = oldPrefsValue;
      migrationNeededFromPrefs = true;
      if (kDebugMode)
        print(
          '[PersistentStringNotifier] Secure Storage empty, using old SharedPreferences value for $preferenceKey. Migration needed.',
        );
    }

    // 3. Set initial state immediately if a value was found
    if (mounted && initialValue != null && initialValue != state) {
      state = initialValue;
    }
    _initialized = true; // Mark as initialized after attempting cache load

    // 4. Asynchronously check CloudKit (only if not already checked)
    if (!_cloudKitChecked) {
      _cloudKitChecked = true; // Prevent re-checking on rebuilds
      try {
        if (kDebugMode)
          print(
            '[PersistentStringNotifier] Checking CloudKit for $preferenceKey...',
          );
        final cloudValue = await _cloudKitService.getSetting(preferenceKey);
        if (kDebugMode)
          print(
            '[PersistentStringNotifier] CloudKit check for $preferenceKey complete. Value: ${cloudValue != null ? (cloudValue.isNotEmpty ? "present" : "empty") : "null"}',
          );

        // Compare CloudKit value with current state (which came from cache/prefs)
        if (cloudValue != null && cloudValue != state) {
          if (kDebugMode)
            print(
              '[PersistentStringNotifier] CloudKit value for $preferenceKey differs. Updating state and Secure Storage.',
            );
          if (mounted) state = cloudValue; // Update state
          await _secureStorage.write(
            key: preferenceKey,
            value: cloudValue,
          ); // Update cache
          // If we updated from CloudKit, migration from prefs is no longer needed for *this* value
          migrationNeededFromPrefs = false;
          // Clean up prefs if it existed, as CloudKit is now the source
          if (oldPrefsValue != null) {
            await prefs.remove(preferenceKey);
            if (kDebugMode)
              print(
                '[PersistentStringNotifier] Cleaned up stale SharedPreferences value for $preferenceKey after CloudKit update.',
              );
          }
        } else if (cloudValue == null && state.isNotEmpty) {
          // Value exists locally (from secure storage or migrated prefs) but not in CloudKit -> Upload local value
          if (kDebugMode)
            print(
              '[PersistentStringNotifier] Value for $preferenceKey exists locally but not in CloudKit. Uploading...',
            );
          final uploadSuccess = await _cloudKitService.saveSetting(
            preferenceKey,
            state,
          );
          if (uploadSuccess &&
              migrationNeededFromPrefs &&
              oldPrefsValue != null) {
            // If upload succeeded AND we were migrating, clean up prefs
            await prefs.remove(preferenceKey);
            if (kDebugMode)
              print(
                '[PersistentStringNotifier] Migration cleanup complete for $preferenceKey after successful upload.',
              );
            migrationNeededFromPrefs = false; // Mark migration as done
          }
        } else if (cloudValue != null &&
            migrationNeededFromPrefs &&
            oldPrefsValue != null &&
            cloudValue == oldPrefsValue) {
          // CloudKit matched the migrated value. Just clean up prefs.
          await prefs.remove(preferenceKey);
          if (kDebugMode)
            print(
              '[PersistentStringNotifier] CloudKit matched migrated value. Cleaned up SharedPreferences for $preferenceKey.',
            );
          migrationNeededFromPrefs = false; // Mark migration as done
        }

        // Handle remaining migration case: If migration was needed but CloudKit check didn't resolve it
        // (e.g., CloudKit failed, or CloudKit had no value and local state was empty)
        if (migrationNeededFromPrefs && oldPrefsValue != null) {
          if (kDebugMode)
            print(
              '[PersistentStringNotifier] Performing migration cleanup for $preferenceKey (post-CloudKit check)...',
            );
          // Ensure value is in Secure Storage (might be redundant but safe)
          await _secureStorage.write(key: preferenceKey, value: oldPrefsValue);
          // Remove from SharedPreferences
          await prefs.remove(preferenceKey);
          if (kDebugMode)
            print(
              '[PersistentStringNotifier] Migration cleanup complete for $preferenceKey.',
            );
        }

      } catch (e) {
        if (kDebugMode)
          print(
            '[PersistentStringNotifier] Error during async CloudKit check for $preferenceKey: $e',
          );
        // Continue with cached value. If migration was needed, it will be retried on next launch.
      }
    } else {
      if (kDebugMode && _initialized)
        print(
          '[PersistentStringNotifier] Skipping redundant CloudKit check for $preferenceKey.',
        );
    }
    if (kDebugMode && initialValue == null && !_cloudKitChecked) {
      print(
        '[PersistentStringNotifier] No initial value found for $preferenceKey in Secure Storage or SharedPreferences.',
      );
    }
  }


  Future<bool> set(String value) async {
    // Initialization check - wait briefly if needed
    if (!_initialized) {
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Warning: Setting value before initialization completed for $preferenceKey. Waiting briefly...',
        );
      }
      int attempts = 0;
      while (!_initialized && attempts < 10) {
        // Increased wait time slightly
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (!_initialized) {
        print(
          '[PersistentStringNotifier] Error: Initialization timed out for $preferenceKey. Cannot save value.',
        );
        return false;
      }
      if (kDebugMode)
        print(
          '[PersistentStringNotifier] Initialization complete for $preferenceKey. Proceeding with set.',
        );
    }

    // 1. Save to CloudKit FIRST
    try {
      if (kDebugMode)
        print(
          '[PersistentStringNotifier] Attempting to save $preferenceKey to CloudKit...',
        );
      final cloudSuccess = await _cloudKitService.saveSetting(
        preferenceKey,
        value,
      );

      if (cloudSuccess) {
        if (kDebugMode)
          print(
            '[PersistentStringNotifier] Successfully saved $preferenceKey to CloudKit.',
          );
        // 2. Update local state (optimistic, only if mounted and changed)
        bool stateChanged = false;
        if (mounted && state != value) {
          state = value;
          stateChanged = true;
          if (kDebugMode)
            print(
              '[PersistentStringNotifier] Updated local state for $preferenceKey.',
            );
        } else if (!mounted && kDebugMode) {
          print(
            '[PersistentStringNotifier] Warning: Attempted to set state on unmounted notifier for $preferenceKey',
          );
        } else if (mounted && state == value && kDebugMode) {
          print(
            '[PersistentStringNotifier] Local state for $preferenceKey already matches. No state update needed.',
          );
        }

        // 3. Update Secure Storage cache
        try {
          await _secureStorage.write(key: preferenceKey, value: value);
          if (kDebugMode)
            print(
              '[PersistentStringNotifier] Updated Secure Storage for $preferenceKey.',
            );
        } catch (e) {
          if (kDebugMode)
            print(
              '[PersistentStringNotifier] Error writing $preferenceKey to Secure Storage: $e',
            );
          // CloudKit succeeded, but cache failed. Maybe log this more prominently.
          return true; // Return true because CloudKit succeeded, but log the cache error.
        }

        return true; // CloudKit and cache (attempted) update successful
      } else {
        if (kDebugMode) {
          print(
            '[PersistentStringNotifier] Failed to sync value for $preferenceKey to CloudKit. Local state/cache not updated.',
          );
        }
        // Maybe show error
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Error syncing preference $preferenceKey to CloudKit: $e',
        );
      }
      return false;
    }
  }

  Future<bool> clear() async {
    // Clearing means setting to empty string for both CloudKit and Secure Storage
    return set('');
  }
}
