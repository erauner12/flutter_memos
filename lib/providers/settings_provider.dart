import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _todoistApiKeyPrefKey = 'todoistApiKey';

// Provider to manage the Todoist API Key state
final todoistApiKeyProvider = StateNotifierProvider<TodoistApiKeyNotifier, String>((ref) {
  // Consider providing SharedPreferences instance via another provider for better testability
  return TodoistApiKeyNotifier();
});

class TodoistApiKeyNotifier extends StateNotifier<String> {
  TodoistApiKeyNotifier() : super('') {
    _loadApiKey(); // Load initial value asynchronously
  }

  SharedPreferences? _prefs;

  // Initialize SharedPreferences instance
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Load the API key from SharedPreferences
  Future<void> _loadApiKey() async {
    await _initPrefs();
    // Set the state with the loaded key or default to empty string
    state = _prefs?.getString(_todoistApiKeyPrefKey) ?? '';
  }

  // Update the API key in both state and SharedPreferences
  Future<void> updateApiKey(String newKey) async {
    final trimmedKey = newKey.trim(); // Trim whitespace
    if (state == trimmedKey) return; // No change needed

    await _initPrefs();
    await _prefs?.setString(_todoistApiKeyPrefKey, trimmedKey);
    state = trimmedKey; // Update the state
    // The todoistApiServiceProvider watching this provider will automatically rebuild.
  }
}
