import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a simple data model for the demo
class DemoItem {
  final String id;
  final String name;
  final IconData icon; // Keep IconData, but use CupertinoIcons

  DemoItem({required this.id, required this.name, required this.icon});
}

// Define the state for the demo items
class DemoState {
  final List<DemoItem> items;
  final bool isLoading;
  final String? error;

  DemoState({this.items = const [], this.isLoading = false, this.error});

  DemoState copyWith({List<DemoItem>? items, bool? isLoading, String? error}) {
    return DemoState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Create a StateNotifier for managing the demo state
class DemoNotifier extends StateNotifier<DemoState> {
  DemoNotifier() : super(DemoState());

  // Simulate fetching data
  Future<void> fetchItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Simulate successful data fetch
      final fetchedItems = List.generate(
        5,
        (index) => DemoItem(
          id: 'item_$index',
          name: 'Demo Item ${index + 1}',
          // Use CupertinoIcons
          icon: CupertinoIcons.circle_fill,
        ),
      );
      state = state.copyWith(items: fetchedItems, isLoading: false);
    } catch (e) {
      // Simulate error
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Simulate adding an item
  void addItem(String name) {
    final newItem = DemoItem(
      id: 'item_${state.items.length}',
      name: name,
      // Use CupertinoIcons
      icon: CupertinoIcons.add_circled_solid,
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  // Simulate removing an item
  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }
}

// Create a provider for the DemoNotifier
final demoProvider = StateNotifierProvider<DemoNotifier, DemoState>((ref) {
  return DemoNotifier();
});
