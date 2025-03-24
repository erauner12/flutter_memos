import 'package:riverpod_annotation/riverpod_annotation.dart';

// This line will generate the file once we run build_runner
part 'simple_counter.g.dart';

/// A simple counter provider using Riverpod code generation
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;
  
  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

/// A simple string provider using Riverpod code generation
@riverpod
String greeting(GreetingRef ref) => 'Hello from code-generated Riverpod!';
