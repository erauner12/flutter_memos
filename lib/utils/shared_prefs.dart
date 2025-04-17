import 'dart:convert'; // For jsonEncode/Decode

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for managing simple key-value storage using SharedPreferences.
/// Used for caching non-critical UI state like last active workbench instance
/// and last opened item per instance.
class SharedPrefsService {
  static const String _activeInstanceIdKey = 'activeWorkbenchInstanceId';
  static const String _lastOpenedItemMapKey = 'lastOpenedItemMap';

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

  // --- Active Workbench Instance ID ---

  /// Saves the last active workbench instance ID.
  Future<bool> saveActiveInstanceId(String instanceId) async {
    if (kDebugMode) {
      print('[SharedPrefsService] Saving active instance ID: $instanceId');
    }
    return _prefs.setString(_activeInstanceIdKey, instanceId);
  }

  /// Retrieves the last active workbench instance ID.
  /// Returns null if no ID has been saved.
  String? getActiveInstanceId() {
    final id = _prefs.getString(_activeInstanceIdKey);
    if (kDebugMode && id != null) {
      // print('[SharedPrefsService] Retrieved active instance ID: $id');
    }
    return id;
  }

  // --- Last Opened Item Map ---

  /// Saves the map of last opened item IDs per workbench instance.
  /// The map keys are instance IDs, and values are the item reference IDs (or null).
  Future<bool> saveLastOpenedItemMap(Map<String, String?> map) async {
    try {
      final jsonString = jsonEncode(map);
      if (kDebugMode) {
        print('[SharedPrefsService] Saving last opened item map: $jsonString');
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
             // print('[SharedPrefsService] Retrieved last opened item map: $resultMap');
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

  /// Clears all data stored by this service.
  Future<bool> clearAll() async {
    final activeCleared = await _prefs.remove(_activeInstanceIdKey);
    final mapCleared = await _prefs.remove(_lastOpenedItemMapKey);
     if (kDebugMode) {
      print('[SharedPrefsService] Cleared all cached data.');
    }
    return activeCleared && mapCleared;
  }
}
