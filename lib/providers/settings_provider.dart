import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences storage
class PreferenceKeys {
  static const String todoistApiKey = 'todoist_api_key';
  static const String openAiApiKey = 'openai_api_key'; // Added OpenAI key
  // Add other preference keys as needed
}

/// Provider for the Todoist API key with persistence using SharedPreferences
final todoistApiKeyProvider =
    StateNotifierProvider<PersistentStringNotifier, String>(
      (ref) => PersistentStringNotifier(
        '', // default empty value
        PreferenceKeys.todoistApiKey, // storage key
      ),
      name: 'todoistApiKey',
    );

/// Provider for the OpenAI API key with persistence using SharedPreferences
final openAiApiKeyProvider =
    StateNotifierProvider<PersistentStringNotifier, String>(
      (ref) => PersistentStringNotifier(
        '', // default empty value
        PreferenceKeys.openAiApiKey, // storage key for OpenAI
      ),
      name: 'openAiApiKey', // Provider name
    );


/// A StateNotifier that persists string values to SharedPreferences
class PersistentStringNotifier extends StateNotifier<String> {
  final String preferenceKey;
  bool _initialized = false;

  PersistentStringNotifier(super.initialState, this.preferenceKey) {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getString(preferenceKey);

      if (storedValue != null && storedValue != state) {
        state = storedValue;
      }

      _initialized = true;
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Loaded value for $preferenceKey: ${storedValue?.isNotEmpty == true ? "present" : "empty"}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Error loading preference $preferenceKey: $e',
        );
      }
      _initialized = true; // Still mark as initialized to prevent blocking
    }
  }

  Future<bool> set(String value) async {
    if (!_initialized) {
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Warning: Setting value before initialization completed for $preferenceKey',
        );
      }
      // Wait for initialization if possible
      int attempts = 0;
      while (!_initialized && attempts < 5) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (!_initialized) {
        print(
          '[PersistentStringNotifier] Error: Initialization timed out for $preferenceKey. Cannot save value.',
        );
        return false;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(preferenceKey, value);

      if (success) {
        // Only update state if the value actually changed to avoid unnecessary rebuilds
        if (state != value) {
          state = value;
        }
        if (kDebugMode) {
          print(
            '[PersistentStringNotifier] Saved value for $preferenceKey: ${value.isNotEmpty ? "new value" : "empty"}',
          );
        }
      } else {
        if (kDebugMode) {
          print(
            '[PersistentStringNotifier] Failed to save value for $preferenceKey',
          );
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[PersistentStringNotifier] Error saving preference $preferenceKey: $e',
        );
      }
      return false;
    }
  }

  Future<bool> clear() async {
    return set('');
  }
}
