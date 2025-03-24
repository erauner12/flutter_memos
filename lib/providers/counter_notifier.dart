import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A traditional StateNotifier implementation for a counter
///
/// This is a fallback approach until we can get code generation working
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  
  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
  void setValue(int value) => state = value;
}

/// The provider for the counter
final counterNotifierProvider = StateNotifierProvider<CounterNotifier, int>(
  (ref) => CounterNotifier(),
);

/// A simple counter provider using the traditional approach
final simpleCounterProvider = StateProvider<int>((ref) => 0);

/// A simple string provider
final greetingProvider = Provider<String>((ref) => 'Hello from Riverpod!');