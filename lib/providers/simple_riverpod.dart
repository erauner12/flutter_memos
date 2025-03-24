import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Simple providers ----------------------------------------

/// A simple counter provider
final counterProvider = StateProvider<int>((ref) => 0);

/// A simple string provider
final greetingProvider = Provider<String>((ref) => 'Hello from Riverpod!');

// 2. Notifier providers -------------------------------------

/// A counter notifier with more functionality
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
  void setValue(int value) => state = value;
}

/// Provider for the counter notifier
final counterNotifierProvider = StateNotifierProvider<CounterNotifier, int>((
  ref,
) {
  return CounterNotifier();
});

// 3. Async providers ----------------------------------------

/// A provider that fetches data asynchronously
final asyncDataProvider = FutureProvider<String>((ref) async {
  // Simulate a network request
  await Future.delayed(const Duration(seconds: 1));
  return 'Async data loaded!';
});

// 4. Family providers ---------------------------------------

/// A provider that takes a parameter (family)
final parameterizedProvider = Provider.family<String, String>((ref, name) {
  return 'Hello, $name!';
});

/// An async provider that takes a parameter
final asyncParameterizedProvider = FutureProvider.family<String, int>((
  ref,
  delay,
) async {
  await Future.delayed(Duration(seconds: delay));
  return 'Data loaded after $delay seconds!';
});

// 5. Provider dependencies ----------------------------------

/// A provider that depends on another provider
final dependentProvider = Provider<String>((ref) {
  final counter = ref.watch(counterProvider);
  return 'Counter value is $counter';
});

/// A provider that depends on an async provider
final dependentAsyncProvider = Provider<AsyncValue<String>>((ref) {
  final asyncValue = ref.watch(asyncDataProvider);
  return asyncValue.whenData((value) => 'Processed: $value');
});

// 6. Advanced example: A memos provider with filtering -------

/// Filter state provider
final memoFilterProvider = StateProvider<String>((ref) => 'all');

/// Memos provider that simulates what you'd do with codegen
final advancedMemosProvider = FutureProvider<List<Memo>>((ref) async {
  // Watch dependencies
  final apiService = ref.watch(apiServiceProvider);
  final filter = ref.watch(memoFilterProvider);
  
  // Get memos from API
  final memos = await apiService.listMemos();
  
  // Apply filter
  if (filter == 'all') {
    return memos;
  } else if (filter == 'pinned') {
    return memos.where((memo) => memo.pinned).toList();
  } else if (filter == 'normal') {
    return memos.where((memo) => memo.state == MemoState.normal).toList();
  } else if (filter == 'archived') {
    return memos.where((memo) => memo.state == MemoState.archived).toList();
  }
  
  // Default: return all memos
  return memos;
});
