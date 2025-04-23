import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Optionally import shared_preferences if you want to persist settings
// import 'package:shared_preferences/shared_preferences.dart';

/// State object holding web-specific settings.
@immutable
class WebSettingsState {
  final bool darkMode;
  // Add other web-specific settings here (e.g., layout preferences)

  const WebSettingsState({
    this.darkMode = false, // Default to light mode
  });

  WebSettingsState copyWith({
    bool? darkMode,
  }) {
    return WebSettingsState(
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

/// Notifier for managing the web settings state.
class WebSettingsNotifier extends StateNotifier<WebSettingsState> {
  // Optional: Pass SharedPreferences instance if persisting
  // final SharedPreferences _prefs;

  WebSettingsNotifier(/* this._prefs */) : super(const WebSettingsState()) {
    // Optional: Load initial state from storage
    // _loadSettings();
  }

  // void _loadSettings() {
  //   final savedDarkMode = _prefs.getBool('web_dark_mode') ?? false;
  //   state = state.copyWith(darkMode: savedDarkMode);
  // }

  /// Toggles the dark mode setting.
  void updateDarkMode(bool enabled) {
    if (state.darkMode != enabled) {
      state = state.copyWith(darkMode: enabled);
      // Optional: Save to storage
      // _prefs.setBool('web_dark_mode', enabled);
    }
  }

  // Add methods to update other settings here
}

/// Provider definition for web settings.
final webSettingsProvider =
    StateNotifierProvider<WebSettingsNotifier, WebSettingsState>((ref) {
  // Optional: Initialize with SharedPreferences if needed
  // final prefs = await SharedPreferences.getInstance();
  // return WebSettingsNotifier(prefs);
  return WebSettingsNotifier();
});
