import 'package:riverpod_annotation/riverpod_annotation.dart';

// This line is necessary to generate the .g.dart file
part 'counter_provider.g.dart';

/// A simple counter provider using Riverpod code generation
///
/// This replaces the older StateProvider-based implementation
/// with a simpler, more type-safe version
@riverpod
int counter(CounterRef ref) => 0;

/// A counter controller using a Riverpod Notifier
///
/// This demonstrates how to migrate from StateNotifier to
/// the code-generated Notifier pattern
@riverpod
class CounterController extends _$CounterController {
  /// Initialize the state
  @override
  int build() => 0;
  
  /// Increment the counter
  void increment() => state++;
  
  /// Decrement the counter
  void decrement() => state--;
  
  /// Reset the counter to zero
  void reset() => state = 0;
  
  /// Set the counter to a specific value
  void setValue(int value) => state = value;
}