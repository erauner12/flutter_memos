import 'dart:async'; // For Timer
import 'dart:convert';

import 'package:flutter/foundation.dart';
// Removed CloudKitService import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

/// Keys for SharedPreferences storage (now primarily for migration check)
/// and SecureStorage keys.
class PreferenceKeys {
  // static const String todoistApiKey = 'todoist_api_key'; // REMOVED
  static const String openAiApiKey = 'openai_api_key'; // Added OpenAI key
  static const String openAiModelId = 'openai_model_id'; // Add this key
  // Add other preference keys as needed

  // New keys for Gemini and MCP
  static const String geminiApiKey = 'gemini_api_key';
  // Removed mcpServerListKey - Managed by McpServerConfigNotifier

  // Key for manually hidden note IDs (stored as JSON Set<String>)
  static const String manuallyHiddenNoteIds = 'manually_hidden_note_ids';

  // Key for the last selected tab index
  static const String selectedTabIndex = 'selectedTabIndex'; // <<< ADDED

  // REMOVED Vikunja API Key
  // static const String vikunjaApiKey = 'vikunja_api_key'; // REMOVED
}

// REMOVED Todoist API Key Provider

/// Provider for the OpenAI API key with persistence using SecureStorage
final openAiApiKeyProvider =
    StateNotifierProvider<PersistentStringNotifier, String>(
      (ref) => PersistentStringNotifier(
        ref,
        '', // default empty value
        PreferenceKeys.openAiApiKey, // storage key for OpenAI
      ),
      name: 'openAiApiKey', // Provider name
    );

/// Provider for the selected OpenAI Model ID with persistence using SecureStorage
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
/// Provider for the Gemini API key with persistence using SecureStorage
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

// --- Start Vikunja ---
// REMOVED Vikunja API Key Provider
// --- End Vikunja ---

/// Provider for the set of manually hidden note IDs using SecureStorage
final manuallyHiddenNoteIdsProvider =
    StateNotifierProvider<PersistentSetNotifier<String>, Set<String>>(
      (ref) => PersistentSetNotifier<String>(
        ref,
        <String>{}, // Initial empty set
        PreferenceKeys.manuallyHiddenNoteIds,
      ),
      name: 'manuallyHiddenNoteIdsProvider',
    );

// --- Start Selected Tab Index Persistence ---

/// Notifier to manage the selected tab index, persisting it to SharedPreferences.
class SelectedTabIndexNotifier extends StateNotifier<int> {
  final Ref _ref;
  final int defaultValue;
  final String storageKey = PreferenceKeys.selectedTabIndex;
  SharedPreferences? _prefs;
  bool _initialized = false;
  final _initLock = Lock(); // Lock for initialization

  SelectedTabIndexNotifier(this._ref, this.defaultValue) : super(defaultValue);

  Future<void> init() async {
    await _initLock.synchronized(() async {
      if (_initialized) return;

      try {
        _prefs = await SharedPreferences.getInstance();
        final savedIndex = _prefs?.getInt(storageKey);
        if (savedIndex != null) {
          if (mounted) {
            state = savedIndex;
          }
          if (kDebugMode) {
            print(
              '[SelectedTabIndexNotifier] Loaded saved tab index: $savedIndex',
            );
          }
        } else {
          if (mounted) {
            state = defaultValue; // Ensure state is default if nothing loaded
          }
          if (kDebugMode) {
            print(
              '[SelectedTabIndexNotifier] No saved tab index found, using default: $defaultValue',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('[SelectedTabIndexNotifier] Error loading tab index: $e');
        }
        if (mounted) {
          state = defaultValue; // Fallback to default on error
        }
      } finally {
        _initialized = true;
      }
    });
  }

  Future<void> set(int value) async {
    // Ensure initialized before setting
    if (!_initialized) {
      if (kDebugMode) {
        print(
          '[SelectedTabIndexNotifier] Waiting for initialization before setting value...',
        );
      }
      await init(); // Wait for initialization to complete
    }

    if (mounted && state != value) {
      state = value;
      try {
        await _prefs?.setInt(storageKey, value);
        if (kDebugMode) {
          print('[SelectedTabIndexNotifier] Saved tab index: $value');
        }
      } catch (e) {
        if (kDebugMode) {
          print('[SelectedTabIndexNotifier] Error saving tab index: $e');
        }
      }
    } else if (mounted && state == value) {
      // If state is already correct, ensure storage is consistent
      try {
        final storedValue = _prefs?.getInt(storageKey);
        if (storedValue != value) {
          await _prefs?.setInt(storageKey, value);
          if (kDebugMode) {
            print(
              '[SelectedTabIndexNotifier] Corrected inconsistent storage for tab index: $value',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[SelectedTabIndexNotifier] Error checking/correcting storage consistency: $e',
          );
        }
      }
    } else if (!mounted && kDebugMode) {
      print(
        '[SelectedTabIndexNotifier] Warning: Attempted to set state on unmounted notifier.',
      );
    }
  }
}

/// Provider for the persisted selected tab index.
/// Defaults to 1 (Workbench) if no value is saved.
final selectedTabIndexProvider =
    StateNotifierProvider<SelectedTabIndexNotifier, int>((ref) {
      // Default index is 1 (Workbench in the new order)
      const defaultIndex = 1;
      final notifier = SelectedTabIndexNotifier(ref, defaultIndex);
      // Initialize asynchronously after creation
      notifier.init();
      return notifier;
    }, name: 'selectedTabIndexProvider');

// --- End Selected Tab Index Persistence ---


/// A StateNotifier that persists string values to SecureStorage.
class PersistentStringNotifier extends StateNotifier<String> {
  final Ref _ref; // Keep ref for potential future use (e.g., logging)
  final String preferenceKey; // Used for SecureStorage key
  // Removed CloudKitService instance
  // late final CloudKitService _cloudKitService;
  // Make _secureStorage non-final to allow replacement in tests
  FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _initialized = false;
  // Removed CloudKit checked flag
  // bool _cloudKitChecked = false;

  // Add visible for testing setter
  @visibleForTesting
  set debugSecureStorage(FlutterSecureStorage storage) {
    _secureStorage = storage;
  }

  // Update constructor - REMOVE _loadValue() call
  PersistentStringNotifier(this._ref, super.initialState, this.preferenceKey) {
    // Removed CloudKitService initialization
    // _cloudKitService = _ref.read(cloudKitServiceProvider);
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

  // Rename and modify loading logic - Removed CloudKit checks and migration logic
  Future<void> _loadValue() async {
    // Prevent multiple initializations if called again somehow
    if (_initialized) {
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
      // On web, secure storage might throw if not configured properly, fallback gracefully
      if (kIsWeb) {
        print(
          '[PersistentStringNotifier] Secure Storage read failed on web for $preferenceKey, continuing...',
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
      // Write migrated value to secure storage immediately
      try {
        await _secureStorage.write(key: preferenceKey, value: initialValue);
        if (kDebugMode)
          print(
            '[PersistentStringNotifier] Migrated $preferenceKey from SharedPreferences to Secure Storage.',
          );
        // Remove old prefs key after successful migration write
        await prefs.remove(preferenceKey);
        if (kDebugMode)
          print(
            '[PersistentStringNotifier] Removed old SharedPreferences key for $preferenceKey after migration.',
          );
        migrationNeededFromPrefs = false; // Mark migration as done
      } catch (e) {
        if (kDebugMode)
          print(
            '[PersistentStringNotifier] Error writing migrated value $preferenceKey to Secure Storage: $e',
          );
        // If write fails, still proceed with the value in memory, but migration won't be fully complete
      }
    }

    // 3. Set initial state immediately if a value was found
    if (mounted && initialValue != null && initialValue != state) {
      state = initialValue;
    }
    _initialized = true; // Mark as initialized after attempting cache load

    // 4. Removed CloudKit check logic

    // Final migration cleanup if it wasn't handled above (e.g., secure storage write failed)
    if (migrationNeededFromPrefs && oldPrefsValue != null) {
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Performing final migration cleanup for $preferenceKey (post-load)...',
        );
      }
      await prefs.remove(preferenceKey);
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Final migration cleanup complete for $preferenceKey.',
        );
      }
    }

    if (kDebugMode && initialValue == null && oldPrefsValue == null) {
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
      // Use a timeout mechanism instead of fixed attempts
      try {
        await init().timeout(const Duration(seconds: 2));
      } catch (e) {
        if (kDebugMode) {
          print(
            '[PersistentStringNotifier] Error: Initialization timed out or failed for $preferenceKey. Cannot save value. Error: $e',
          );
        }
        return false;
      }
      if (!_initialized) {
        if (kDebugMode) {
          print(
            '[PersistentStringNotifier] Error: Initialization did not complete for $preferenceKey after waiting. Cannot save value.',
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

    // Save to Secure Storage (works on web via web storage)
    try {
      await _secureStorage.write(key: preferenceKey, value: value);
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Updated Secure Storage for $preferenceKey.',
        );
      }
      return true; // Return true on successful local save
    } catch (e) {
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Error writing $preferenceKey to Secure Storage: $e',
        );
      }
      return false; // Return false if local save fails
    }

    // Removed CloudKit save logic
  }

  Future<bool> clear() async {
    // Clearing means setting to empty string for Secure Storage
    return set('');
  }
}

// --- Start PersistentSetNotifier ---

/// A StateNotifier that persists a Set<T> (specifically Set<String> for now)
/// to SecureStorage.
/// Assumes T is serializable with jsonEncode/Decode (currently expects String).
class PersistentSetNotifier<T> extends StateNotifier<Set<T>> {
  final Ref _ref;
  final String preferenceKey; // Used for SecureStorage key
  // Removed CloudKitService instance
  // late final CloudKitService _cloudKitService;
  FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _initialized = false;
  // Removed CloudKit checked flag
  // bool _cloudKitChecked = false;
  final _lock = Lock(); // Use a dedicated lock for this notifier instance

  @visibleForTesting
  set debugSecureStorage(FlutterSecureStorage storage) {
    _secureStorage = storage;
  }

  PersistentSetNotifier(this._ref, super.initialState, this.preferenceKey) {
    // Removed CloudKitService initialization
    // _cloudKitService = _ref.read(cloudKitServiceProvider);
    // Initialization (`init()`) must be called externally after provider creation.
  }

  Future<void> init() async {
    if (_initialized) return;

    await _lock.synchronized(() async {
      if (_initialized) return; // Double check inside lock

      Set<T> loadedState = <T>{};
      String? secureValue;
      // Removed cloudValueJson

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
        if (kIsWeb) {
          print(
            '[PersistentSetNotifier<$T>] Secure Storage read failed on web for $preferenceKey, continuing...',
          );
        }
      }

      // 2. Set initial state from Secure Storage if found
      if (mounted && !setEquals(loadedState, state)) {
        // Only update if different
        state = loadedState;
      }
      _initialized = true; // Mark initialized after cache load attempt

      // 3. Removed CloudKit check logic

      if (kDebugMode && secureValue == null) {
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
          return false; // Cannot save if unmounted
        }
        return _saveState(newState);
      }
      return true; // Item already exists, no change needed (and no save needed)
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
          return false; // Cannot save if unmounted
        }
        return _saveState(newState);
      }
      return true; // Item doesn't exist, no change needed (and no save needed)
    });
  }

  Future<bool> clear() async {
    return _lock.synchronized(() async {
      if (state.isNotEmpty) {
        final newState = <T>{};
        if (mounted) {
          state = newState;
        } else {
          if (kDebugMode) {
            print(
              '[PersistentSetNotifier<$T>] Warning: clear called on unmounted notifier for $preferenceKey',
            );
          }
          return false; // Cannot save if unmounted
        }
        return _saveState(newState);
      }
      return true; // Already empty, no save needed
    });
  }

  // Helper to save state to SecureStorage
  Future<bool> _saveState(Set<T> stateToSave) async {
    if (!_initialized) {
      if (kDebugMode) {
        print(
          '[PersistentSetNotifier<$T>] Warning: Attempting to save state before initialization for $preferenceKey.',
        );
      }
      // Optionally wait for init or return false
      try {
        await init().timeout(const Duration(seconds: 2));
      } catch (e) {
        if (kDebugMode)
          print(
            '[PersistentSetNotifier<$T>] Initialization timed out or failed during save for $preferenceKey. Error: $e',
          );
        return false;
      }
      if (!_initialized) {
        if (kDebugMode)
          print(
            '[PersistentSetNotifier<$T>] Initialization did not complete for $preferenceKey after waiting during save.',
          );
        return false; // If init failed
      }
    }

    final jsonString = _encodeSet(stateToSave);
    bool secureSuccess = false;
    // Removed cloudSuccess flag

    // Save to Secure Storage (Web Safe)
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
      // If local save fails, report failure immediately
      return false;
    }

    // Removed CloudKit save logic

    return secureSuccess; // Primarily report local save success
  }

  // Helper to encode the Set<T> to JSON string
  String _encodeSet(Set<T> value) {
    // Currently assumes T is String, adapt if needed for other types
    if (T == String) {
      // Ensure elements are actually strings before encoding
      return jsonEncode((value).map((e) => e.toString()).toList());
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
// (No SettingsService class defined in the provided snippet)
