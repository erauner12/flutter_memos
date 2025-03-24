import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the current theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.dark; // Default to dark theme
}, name: 'themeMode');

/// Provider for loading the saved theme mode from preferences
final loadThemeModeProvider = FutureProvider<ThemeMode>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final savedThemeMode = prefs.getString('theme_mode');
  
  if (savedThemeMode == 'light') {
    return ThemeMode.light;
  } else if (savedThemeMode == 'dark') {
    return ThemeMode.dark;
  } else if (savedThemeMode == 'system') {
    return ThemeMode.system;
  }
  
  return ThemeMode.dark; // Default to dark if no saved preference
});

/// Provider for saving theme preference
final saveThemeModeProvider = Provider<Future<bool> Function(ThemeMode)>((ref) {
  return (ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    
    return prefs.setString('theme_mode', modeString);
  };
});

/// Provider for toggling between light and dark mode
final toggleThemeModeProvider = Provider<void Function()>((ref) {
  return () {
    final currentMode = ref.read(themeModeProvider);
    final newMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    
    // Update the theme mode provider
    ref.read(themeModeProvider.notifier).state = newMode;
    
    // Save the preference
    ref.read(saveThemeModeProvider)(newMode);
  };
});
