import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the current theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  if (kDebugMode) {
    print('[themeModeProvider] Initializing with dark theme');
  }
  return ThemeMode.dark; // Default to dark theme
}, name: 'themeMode');

/// Provider for loading the saved theme mode from preferences
final loadThemeModeProvider = FutureProvider<ThemeMode>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString('theme_mode');
    
    if (kDebugMode) {
      print('[loadThemeModeProvider] Loaded theme from preferences: $savedThemeMode');
    }
    
    if (savedThemeMode == 'light') {
      return ThemeMode.light;
    } else if (savedThemeMode == 'dark') {
      return ThemeMode.dark;
    } else if (savedThemeMode == 'system') {
      return ThemeMode.system;
    }
    
    return ThemeMode.dark; // Default to dark if no saved preference
  } catch (e) {
    if (kDebugMode) {
      print('[loadThemeModeProvider] Error loading theme preferences: $e');
    }
    return ThemeMode.dark; // Default to dark on error
  }
}, name: 'loadThemeMode');

/// Provider for saving theme preference
final saveThemeModeProvider = Provider<Future<bool> Function(ThemeMode)>((ref) {
  return (ThemeMode mode) async {
    try {
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
      
      if (kDebugMode) {
        print('[saveThemeModeProvider] Saving theme mode preference: $modeString');
      }
      
      final result = await prefs.setString('theme_mode', modeString);
      
      // Force invalidate the loadThemeModeProvider to avoid stale data
      ref.invalidate(loadThemeModeProvider);
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('[saveThemeModeProvider] Error saving theme preferences: $e');
      }
      return false;
    }
  };
}, name: 'saveThemeMode');

/// Provider for toggling between light and dark mode
final toggleThemeModeProvider = Provider<void Function()>((ref) {
  return () {
    final currentMode = ref.read(themeModeProvider);
    
    if (kDebugMode) {
      print('[toggleThemeModeProvider] Current theme mode: $currentMode');
    }
    
    ThemeMode newMode;

    // Simplified cycle: dark -> light -> system -> dark
    switch (currentMode) {
      case ThemeMode.dark:
        newMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        newMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        newMode = ThemeMode.dark;
        break;
      default:
        newMode = ThemeMode.dark;
    }
    
    if (kDebugMode) {
      print('[toggleThemeModeProvider] Changing to: $newMode');
    }
    
    // Update the theme mode provider
    ref.read(themeModeProvider.notifier).state = newMode;
    
    // Save the preference
    ref.read(saveThemeModeProvider)(newMode);
  };
}, name: 'toggleThemeMode');

/// Direct method to set a specific theme
final setThemeModeProvider = Provider<void Function(ThemeMode)>((ref) {
  return (ThemeMode mode) {
    if (kDebugMode) {
      print('[setThemeModeProvider] Setting theme to: $mode');
    }

    // Update the theme mode provider
    ref.read(themeModeProvider.notifier).state = mode;

    // Save the preference
    ref.read(saveThemeModeProvider)(mode);
  };
}, name: 'setThemeMode');