import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart'; // Keep generic name or rename if needed
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// State definition for a single Focus Board instance
@immutable
class FocusState {
  final List<WorkbenchItemReference> items; // Keep generic name or rename
  final bool isLoading;
  final String? error;

  const FocusState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  FocusState copyWith({
    List<WorkbenchItemReference>? items, // Keep generic name or rename
    bool? isLoading,
    String? error,
    // bool clearError = false,
  }) {
    return FocusState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      // error: clearError ? null : (error ?? this.error),
    );
  }

   @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FocusState &&
        listEquals(other.items, items) &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), isLoading, error);

  @override
  String toString() {
    return 'FocusState(items: ${items.length} items, isLoading: $isLoading, error: $error)';
  }
}

// Notifier for managing the state of a single Focus Board instance
class FocusNotifier extends StateNotifier<FocusState> {
  final String instanceId;
  final String _prefsKey;

  FocusNotifier(this.instanceId)
      : _prefsKey = 'focus_instance_$instanceId', // Updated key prefix
        super(const FocusState(isLoading: true)) {
    _loadItems();
  }

  Future<void> _loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? itemsJson = prefs.getString(_prefsKey);
      List<WorkbenchItemReference> loadedItems = []; // Keep generic name or rename

      if (itemsJson != null) {
        final List<dynamic> decodedList = jsonDecode(itemsJson);
        loadedItems = decodedList
            .map((jsonItem) => WorkbenchItemReference.fromJson(jsonItem as Map<String, dynamic>)) // Keep generic name or rename
            .toList();
        // Sort items by addedTimestamp descending (newest first)
        loadedItems.sort((a, b) => b.addedTimestamp.compareTo(a.addedTimestamp));
      }
      state = state.copyWith(items: loadedItems, isLoading: false);
       if (kDebugMode) {
        print('[FocusNotifier($instanceId)] Loaded ${loadedItems.length} items.');
      }
    } catch (e, s) {
       if (kDebugMode) {
        print('[FocusNotifier($instanceId)] Error loading items: $e\n$s');
      }
      state = state.copyWith(isLoading: false, error: 'Failed to load focus items: $e');
    }
  }

  Future<void> _saveItemsToPrefs(List<WorkbenchItemReference> items) async { // Keep generic name or rename
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
          items.map((item) => item.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(jsonList));
       if (kDebugMode) {
        print('[FocusNotifier($instanceId)] Saved ${items.length} items to prefs.');
      }
    } catch (e, s) {
       if (kDebugMode) {
        print('[FocusNotifier($instanceId)] Error saving items: $e\n$s');
      }
      state = state.copyWith(error: 'Failed to save focus items: $e');
    }
  }

  Future<void> addItem(WorkbenchItemReference item) async { // Keep generic name or rename
     // Prevent adding duplicates based on referencedItemId and serverId? Or allow?
     // For now, allow duplicates but maybe add check later.
    final updatedItems = [item, ...state.items]; // Add to the beginning (newest first)
    await _saveItemsToPrefs(updatedItems);
    state = state.copyWith(items: updatedItems);
     if (kDebugMode) {
        print('[FocusNotifier($instanceId)] Added item: ${item.id} (ref: ${item.referencedItemId})');
      }
  }

  Future<void> removeItem(String itemId) async {
    final updatedItems = state.items.where((item) => item.id != itemId).toList();
    if (updatedItems.length < state.items.length) {
      await _saveItemsToPrefs(updatedItems);
      state = state.copyWith(items: updatedItems);
       if (kDebugMode) {
        print('[FocusNotifier($instanceId)] Removed item: $itemId');
      }
    } else {
       if (kDebugMode) {
        print('[FocusNotifier($instanceId)] Item $itemId not found for removal.');
      }
       state = state.copyWith(error: 'Focus item not found for removal.');
    }
  }

  Future<void> clearAllItems() async {
    await _saveItemsToPrefs([]);
    state = state.copyWith(items: []);
     if (kDebugMode) {
        print('[FocusNotifier($instanceId)] Cleared all items.');
      }
  }

  // Refresh function
  Future<void> refresh() async {
    await _loadItems();
  }
}

// Family provider for Focus Notifiers, keyed by instanceId
// Updated provider name
final focusProviderFamily = StateNotifierProvider.family<FocusNotifier, FocusState, String>(
  (ref, instanceId) {
    return FocusNotifier(instanceId);
  },
);

// Provider to get the list of items for a specific focus instance
final focusItemsProvider = Provider.family<List<WorkbenchItemReference>, String>((ref, instanceId) { // Keep generic name or rename
  return ref.watch(focusProviderFamily(instanceId)).items;
});
