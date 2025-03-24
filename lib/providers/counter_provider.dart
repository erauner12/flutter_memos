import 'package:flutter_riverpod/flutter_riverpod.dart';

// We'll use a standard StateNotifier approach first before moving to codegen
// This ensures we have a working example without depending on code generation

class CounterController extends StateNotifier<int> {
  CounterController() : super(0);
  
  void increment() => state++;
  void decrement() => state--;
}

/// A simple counter provider to demonstrate the Riverpod pattern
final counterControllerProvider = StateNotifierProvider<CounterController, int>(
  (ref) {
    return CounterController();
},
);
