import 'dart:convert';

import 'package:flutter/foundation.dart';
// Add Ref and CloudKitService imports
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart'; // <<< Add this import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

/// Keys for SharedPreferences storage (now primarily for migration check)
/// and SecureStorage / CloudKit keys.
class PreferenceKeys {
  static const String todoistApiKey = 'todoist_api_key';
  static const String openAiApiKey = 'openai_api_key'; // Added OpenAI key
  static const String openAiModelId = 'openai_model_id'; // Add this key
  // Add other preference keys as needed

  // New keys for Gemini and MCP
  static const String geminiApiKey = 'gemini_api_key';
  // Removed mcpServerListKey - Managed by McpServerConfigNotifier

  // Key for manually hidden note IDs (stored as JSON Set<String>)
  static const String manuallyHiddenNoteIds = 'manually_hidden_note_ids';
}

/// Provider for the Todoist API key with persistence using SharedPreferences
final todoistApiKeyProvider =
    StateNotifierProvider<PersistentStringNotifier, String>(
      (ref) => PersistentStringNotifier(
        ref,
        '', // default empty value
        PreferenceKeys.todoistApiKey, // storage key
      ),
      name: 'todoistApiKey',
    );

/// Provider for the OpenAI API key with persistence using SharedPreferences
final openAiApiKeyProvider =
    StateNotifierProvider<PersistentStringNotifier, String>(
      (ref) => PersistentStringNotifier(
        ref,
        '', // default empty value
        PreferenceKeys.openAiApiKey, // storage key for OpenAI
      ),
      name: 'openAiApiKey', // Provider name
    );

/// Provider for the selected OpenAI Model ID with persistence
final openAiModelIdProvider =
    StateNotifierProvider<PersistentStringNotifier, String>(
      (ref) => PersistentStringNotifier(
        ref,
        'gpt-3.5-turbo-instruct', // Sensible default model
        PreferenceKeys.openAiModelId, // storage key for OpenAI Model ID
      ),
      name: 'openAiModelIdProvider', // Provider name
    );

// --- Start Gemini ---
/// Provider for the Gemini API key with persistence
final geminiApiKeyProvider =
    StateNotifierProvider<PersistentStringNotifier, String>(
      (ref) => PersistentStringNotifier(
        ref,
        '', // default empty value
        PreferenceKeys.geminiApiKey, // storage key for Gemini
      ),
      name: 'geminiApiKeyProvider', // Provider name
    );
// --- End Gemini ---

/// Provider for the set of manually hidden note IDs
final manuallyHiddenNoteIdsProvider =
    StateNotifierProvider<PersistentSetNotifier<String>, Set<String>>(
      (ref) => PersistentSetNotifier<String>(
        ref,
        <String>{}, // Initial empty set
        PreferenceKeys.manuallyHiddenNoteIds,
      ),
      name: 'manuallyHiddenNoteIdsProvider',
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
    if (_initialized) {
      return;
    }
    await _loadValue();
  }

  // Rename and modify loading logic
  Future<void> _loadValue() async {
    // Prevent multiple initializations if called again somehow
    if (_initialized && _cloudKitChecked) {
      return;
    }

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
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Error reading $preferenceKey from Secure Storage: $e',
        );
      }
    }

    // 2. If not in Secure Storage, check old SharedPreferences key for migration
    final prefs = await SharedPreferences.getInstance();
    final oldPrefsValue = prefs.getString(preferenceKey);
    if (initialValue == null && oldPrefsValue != null) {
      initialValue = oldPrefsValue;
      migrationNeededFromPrefs = true;
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Secure Storage empty, using old SharedPreferences value for $preferenceKey. Migration needed.',
        );
      }
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
        if (kDebugMode) {
          print(
            '[PersistentStringNotifier] Checking CloudKit for $preferenceKey...',
          );
        }
        final cloudValue = await _cloudKitService.getSetting(preferenceKey);
        if (kDebugMode) {
          print(
            '[PersistentStringNotifier] CloudKit check for $preferenceKey complete. Value: ${cloudValue != null ? (cloudValue.isNotEmpty ? "present" : "empty") : "null"}',
          );
        }

        // Compare CloudKit value with current state (which came from cache/prefs)
        if (cloudValue != null && cloudValue != state) {
          if (kDebugMode) {
            print(
              '[PersistentStringNotifier] CloudKit value for $preferenceKey differs. Updating state and Secure Storage.',
            );
          }
          if (mounted) {
            state = cloudValue; // Update state
          }
          await _secureStorage.write(
            key: preferenceKey,
            value: cloudValue,
          ); // Update cache
          migrationNeededFromPrefs = false;
          if (oldPrefsValue != null) {
            await prefs.remove(preferenceKey);
            if (kDebugMode) {
              print(
                '[PersistentStringNotifier] Cleaned up stale SharedPreferences value for $preferenceKey after CloudKit update.',
              );
            }
          }
        } else if (cloudValue == null && state.isNotEmpty) {
          if (kDebugMode) {
            print(
              '[PersistentStringNotifier] Value for $preferenceKey exists locally but not in CloudKit. Uploading...',
            );
          }
          final uploadSuccess = await _cloudKitService.saveSetting(
            preferenceKey,
            state,
          );
          if (uploadSuccess &&
              migrationNeededFromPrefs &&
              oldPrefsValue != null) {
            await prefs.remove(preferenceKey);
            if (kDebugMode) {
              print(
                '[PersistentStringNotifier] Migration cleanup complete for $preferenceKey after successful upload.',
              );
            }
            migrationNeededFromPrefs = false;
          }
        } else if (cloudValue != null &&
            migrationNeededFromPrefs &&
            oldPrefsValue != null &&
            cloudValue == oldPrefsValue) {
          await prefs.remove(preferenceKey);
          if (kDebugMode) {
            print(
              '[PersistentStringNotifier] CloudKit matched migrated value. Cleaned up SharedPreferences for $preferenceKey.',
            );
          }
          migrationNeededFromPrefs = false;
        }

        if (migrationNeededFromPrefs && oldPrefsValue != null) {
          if (kDebugMode) {
            print(
              '[PersistentStringNotifier] Performing migration cleanup for $preferenceKey (post-CloudKit check)...',
            );
          }
          await _secureStorage.write(key: preferenceKey, value: oldPrefsValue);
          await prefs.remove(preferenceKey);
          if (kDebugMode) {
            print(
              '[PersistentStringNotifier] Migration cleanup complete for $preferenceKey.',
            );
          }
        }

      } catch (e) {
        if (kDebugMode) {
          print(
            '[PersistentStringNotifier] Error during async CloudKit check for $preferenceKey: $e',
          );
        }
      }
    } else {
      if (kDebugMode && _initialized) {
        print(
          '[PersistentStringNotifier] Skipping redundant CloudKit check for $preferenceKey.',
        );
      }
    }
    if (kDebugMode && initialValue == null && !_cloudKitChecked) {
      print(
        '[PersistentStringNotifier] No initial value found for $preferenceKey in Secure Storage or SharedPreferences.',
      );
    }
  }

  Future<bool> set(String value) async {
    if (!_initialized) {
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Warning: Setting value before initialization completed for $preferenceKey. Waiting briefly...',
        );
      }
      int attempts = 0;
      while (!_initialized && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (!_initialized) {
        if (kDebugMode) {
          print(
            '[PersistentStringNotifier] Error: Initialization timed out for $preferenceKey. Cannot save value.',
          );
        }
        return false;
      }
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Initialization complete for $preferenceKey. Proceeding with set.',
        );
      }
    }

    if (mounted && state != value) {
      state = value;
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Updated local state for $preferenceKey.',
        );
      }
    } else if (!mounted && kDebugMode) {
      print(
        '[PersistentStringNotifier] Warning: Attempted to set state on unmounted notifier for $preferenceKey',
      );
    } else if (mounted && state == value && kDebugMode) {
      print(
        '[PersistentStringNotifier] Local state for $preferenceKey already matches. Ensuring storage consistency.',
      );
    }

    try {
      await _secureStorage.write(key: preferenceKey, value: value);
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Updated Secure Storage for $preferenceKey.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Error writing $preferenceKey to Secure Storage: $e',
        );
      }
      return false;
    }

    try {
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Attempting to save $preferenceKey to CloudKit...',
        );
      }
      final cloudSuccess = await _cloudKitService.saveSetting(
        preferenceKey,
        value,
      );
      if (cloudSuccess) {
        if (kDebugMode) {
          print(
            '[PersistentStringNotifier] Successfully saved $preferenceKey to CloudKit.',
          );
        }
      } else {
        if (kDebugMode) {
          print(
            '[PersistentStringNotifier] Failed to sync value for $preferenceKey to CloudKit. Local value is saved.',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Error syncing preference $preferenceKey to CloudKit: $e',
        );
      }
    }
    return true;
  }

  Future<bool> clear() async {
    // Clearing means setting to empty string for both CloudKit and Secure Storage
    return set('');
  }
}

// --- Start PersistentSetNotifier ---

/// A StateNotifier that persists a Set<T> (specifically Set<String> for now)
/// to SecureStorage and syncs with CloudKit's UserSettings record.
/// Assumes T is serializable with jsonEncode/Decode (currently expects String).
class PersistentSetNotifier<T> extends StateNotifier<Set<T>> {
  final Ref _ref;
  final String preferenceKey; // Used for SecureStorage key AND CloudKit key
  late final CloudKitService _cloudKitService;
  FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _initialized = false;
  bool _cloudKitChecked = false; // Flag to prevent redundant CloudKit checks
  final _lock = Lock(); // Use a dedicated lock for this notifier instance

  @visibleForTesting
  set debugSecureStorage(FlutterSecureStorage storage) {
    _secureStorage = storage;
  }

  PersistentSetNotifier(this._ref, super.initialState, this.preferenceKey) {
    _cloudKitService = _ref.read(cloudKitServiceProvider);
    // Initialization (`init()`) must be called externally after provider creation.
  }

  Future<void> init() async {
    if (_initialized) return;

    await _lock.synchronized(() async {
      if (_initialized) return; // Double check inside lock

      Set<T> loadedState = <T>{};
      String? secureValue;
      String? cloudValueJson;

      // 1. Load from Secure Storage
      try {
        secureValue = await _secureStorage.read(key: preferenceKey);
        if (secureValue != null) {
          loadedState = _decodeSet(secureValue);
          if (kDebugMode) {
            print(
              '[PersistentSetNotifier<$T>] Loaded ${loadedState.length} items for $preferenceKey from Secure Storage.',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[PersistentSetNotifier<$T>] Error reading $preferenceKey from Secure Storage: $e',
          );
        }
      }

      // 2. Set initial state from Secure Storage if found
      if (mounted && loadedState.isNotEmpty) {
        state = loadedState;
      }
      _initialized = true; // Mark initialized after cache load attempt

      // 3. Asynchronously check CloudKit (only once)
      if (!_cloudKitChecked) {
        _cloudKitChecked = true;
        try {
          if (kDebugMode) {
            print(
              '[PersistentSetNotifier<$T>] Checking CloudKit for $preferenceKey...',
            );
          }
          cloudValueJson = await _cloudKitService.getSetting(preferenceKey);
          if (kDebugMode) {
            print(
              '[PersistentSetNotifier<$T>] CloudKit check for $preferenceKey complete. Value: ${cloudValueJson != null ? (cloudValueJson.isNotEmpty ? "present" : "empty") : "null"}',
            );
          }

          if (cloudValueJson != null) {
            final cloudState = _decodeSet(cloudValueJson);
            // CloudKit wins if different from current state (which came from secure storage)
            if (!setEquals(cloudState, state)) {
              if (kDebugMode) {
                print(
                  '[PersistentSetNotifier<$T>] CloudKit value for $preferenceKey differs. Updating state (${cloudState.length} items) and Secure Storage.',
                );
              }
              if (mounted) {
                state = cloudState; // Update state
              }
              await _secureStorage.write(
                key: preferenceKey,
                value: cloudValueJson,
              ); // Update cache
            }
          } else if (state.isNotEmpty) {
            // Value exists locally but not in CloudKit -> Upload
            if (kDebugMode) {
              print(
                '[PersistentSetNotifier<$T>] Value for $preferenceKey exists locally (${state.length} items) but not in CloudKit. Uploading...',
              );
            }
            await _cloudKitService.saveSetting(
              preferenceKey,
              _encodeSet(state),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '[PersistentSetNotifier<$T>] Error during async CloudKit check for $preferenceKey: $e',
            );
          }
        }
      } else if (kDebugMode && _initialized) {
        print(
          '[PersistentSetNotifier<$T>] Skipping redundant CloudKit check for $preferenceKey.',
        );
      }
      if (kDebugMode && secureValue == null && !_cloudKitChecked) {
        print(
          '[PersistentSetNotifier<$T>] No initial value found for $preferenceKey in Secure Storage.',
        );
      }
    });
  }

  Future<bool> add(T item) async {
    return _lock.synchronized(() async {
      if (!state.contains(item)) {
        final newState = Set<T>.from(state)..add(item);
        if (mounted) {
          state = newState;
        } else {
          if (kDebugMode) {
            print(
              '[PersistentSetNotifier<$T>] Warning: add called on unmounted notifier for $preferenceKey',
            );
          }
          return false; // Or handle differently?
        }
        return _saveState(newState);
      }
      return true; // Item already exists, no change needed
    });
  }

  Future<bool> remove(T item) async {
    return _lock.synchronized(() async {
      if (state.contains(item)) {
        final newState = Set<T>.from(state)..remove(item);
        if (mounted) {
          state = newState;
        } else {
          if (kDebugMode) {
            print(
              '[PersistentSetNotifier<$T>] Warning: remove called on unmounted notifier for $preferenceKey',
            );
          }
          return false; // Or handle differently?
        }
        return _saveState(newState);
      }
      return true; // Item doesn't exist, no change needed
    });
  }

  Future<bool> clear() async {
    return _lock.synchronized(() async {
      if (state.isNotEmpty) {
        // FIX: Cannot use const with type parameter T
        final newState = <T>{};
        if (mounted) {
          state = newState;
        } else {
          if (kDebugMode) {
            print(
              '[PersistentSetNotifier<$T>] Warning: clear called on unmounted notifier for $preferenceKey',
            );
          }
          return false; // Or handle differently?
        }
        return _saveState(newState);
      }
      return true; // Already empty
    });
  }

  // Helper to save state to SecureStorage and CloudKit
  Future<bool> _saveState(Set<T> stateToSave) async {
    if (!_initialized) {
      if (kDebugMode) {
        print(
          '[PersistentSetNotifier<$T>] Warning: Attempting to save state before initialization for $preferenceKey.',
        );
      }
      // Optionally wait for init or return false
      await init(); // Ensure init completes
      if (!_initialized) return false; // If init failed
    }

    final jsonString = _encodeSet(stateToSave);
    bool secureSuccess = false;
    bool cloudSuccess = false;

    try {
      await _secureStorage.write(key: preferenceKey, value: jsonString);
      secureSuccess = true;
      if (kDebugMode) {
        print(
          '[PersistentSetNotifier<$T>] Updated Secure Storage for $preferenceKey (${stateToSave.length} items).',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[PersistentSetNotifier<$T>] Error writing $preferenceKey to Secure Storage: $e',
        );
      }
    }

    // Save to CloudKit asynchronously (fire and forget, or await if critical)
    _cloudKitService
        .saveSetting(preferenceKey, jsonString)
        .then((success) {
          cloudSuccess = success;
          if (kDebugMode) {
            print(
              '[PersistentSetNotifier<$T>] CloudKit save attempt for $preferenceKey finished. Success: $cloudSuccess',
            );
          }
        })
        .catchError((e) {
          if (kDebugMode) {
            print(
              '[PersistentSetNotifier<$T>] Error syncing preference $preferenceKey to CloudKit: $e',
            );
          }
        });

    return secureSuccess; // Primarily report local save success
  }

  // Helper to encode the Set<T> to JSON string
  String _encodeSet(Set<T> value) {
    // Currently assumes T is String, adapt if needed for other types
    if (T == String) {
      return jsonEncode((value as Set<String>).toList());
    }
    // Add handling for other types if necessary
    throw UnsupportedError(
      'PersistentSetNotifier only supports Set<String> currently.',
    );
  }

  // Helper to decode JSON string to Set<T>
  Set<T> _decodeSet(String jsonString) {
    try {
      final decodedList = jsonDecode(jsonString);
      if (decodedList is List) {
        // Currently assumes T is String, adapt if needed
        if (T == String) {
          return Set<String>.from(
            decodedList.map((e) => e.toString()),
          ).cast<T>();
        }
        // Add handling for other types if necessary
        throw UnsupportedError(
          'PersistentSetNotifier only supports Set<String> currently.',
        );
      }
      return <T>{};
    } catch (e) {
      if (kDebugMode) {
        print(
          '[PersistentSetNotifier<$T>] Error decoding JSON for $preferenceKey: $e',
        );
      }
      return <T>{}; // Return empty set on error
    }
  }
}

// --- End PersistentSetNotifier ---


// --- Settings Service ---
