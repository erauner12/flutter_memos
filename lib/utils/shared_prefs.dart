import 'dart:convert'; // For jsonEncode/Decode

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for managing simple key-value storage using SharedPreferences.
/// Used for caching non-critical UI state like last opened item per instance.
class SharedPrefsService {
  // static const String _activeInstanceIdKey = 'activeWorkbenchInstanceId';
  static const String _lastOpenedItemMapKey = 'lastOpenedItemMap';
  // Define keys related to workbench data for clearing
  static const String _instancesPrefsKey = 'workbench_instances_list';
  static const String _workbenchItemsPrefix = 'workbench_items_';


  late SharedPreferences _prefs;

  // Private constructor
  SharedPrefsService._();

  // Static instance
  static SharedPrefsService? _instance;

  // Public factory constructor to get the instance
  static Future<SharedPrefsService> getInstance() async {
    if (_instance == null) {
      final service = SharedPrefsService._();
      await service._init();
      _instance = service;
    }
    return _instance!;
  }

  // Initialize SharedPreferences
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) {
      print('[SharedPrefsService] Initialized.');
    }
  }

  // --- Generic Getters/Setters ---

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  // --- Last Opened Item Map ---

  /// Saves the map of last opened item IDs per workbench instance.
  /// The map keys are instance IDs, and values are the item reference IDs (or null).
  Future<bool> saveLastOpenedItemMap(Map<String, String?> map) async {
    try {
      final jsonString = jsonEncode(map);
      if (kDebugMode) {
        // print('[SharedPrefsService] Saving last opened item map: $jsonString'); // Keep logging minimal
      }
      return _prefs.setString(_lastOpenedItemMapKey, jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('[SharedPrefsService] Error encoding last opened item map: $e');
      }
      return false;
    }
  }

  /// Retrieves the map of last opened item IDs per workbench instance.
  /// Returns an empty map if no map has been saved or if there's a decoding error.
  Map<String, String?> getLastOpenedItemMap() {
    final jsonString = _prefs.getString(_lastOpenedItemMapKey);
    if (jsonString != null) {
      try {
        final decodedMap = jsonDecode(jsonString);
        if (decodedMap is Map) {
          // Ensure keys are String and values are String?
          final resultMap = decodedMap.map<String, String?>(
            (key, value) => MapEntry(key.toString(), value?.toString()),
          );
           if (kDebugMode) {
             // print('[SharedPrefsService] Retrieved last opened item map: $resultMap'); // Keep logging minimal
           }
          return resultMap;
        }
      } catch (e) {
        if (kDebugMode) {
          print('[SharedPrefsService] Error decoding last opened item map: $e');
        }
      }
    }
    return {}; // Return empty map if not found or error
  }

  /// Clears all data stored by this service. Use with caution.
  Future<bool> clearAll() async {
    final success = await _prefs.clear();
     if (kDebugMode) {
      print('[SharedPrefsService] Cleared ALL SharedPreferences data.');
    }
    return success;
  }

  /// Clears only data related to workbench instances and items.
  Future<void> clearAllWorkbenchData() async {
    await _prefs.remove(_lastOpenedItemMapKey);
    await _prefs.remove(_instancesPrefsKey);
    // Remove all keys starting with the workbench items prefix
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_workbenchItemsPrefix)) {
        await _prefs.remove(key);
      }
    }
    if (kDebugMode) {
      print(
        '[SharedPrefsService] Cleared all workbench-related SharedPreferences data.',
      );
    }
  }
}
