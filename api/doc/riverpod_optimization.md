# Riverpod Optimization Techniques

While we work on implementing code generation, here are several techniques to optimize our existing Riverpod code:

## 1. Selective Watching with select()

Instead of watching an entire object when you only need one property:

```dart
// Instead of this:
final user = ref.watch(userProvider);
final name = user.name;

// Do this:
final name = ref.watch(userProvider.select((user) => user.name));
```

Benefits:
- Widget only rebuilds when the selected property changes
- Reduces unnecessary rebuilds
- Improves performance

## 2. Cache Control with keepAlive()

For providers that do expensive work:

```dart
final expensiveProvider = FutureProvider<List<Item>>((ref) async {
  // Keep this provider alive even when no one is watching it
  ref.keepAlive();
  
  // Expensive operation (e.g., network request, database query)
  final data = await fetchItems();
  return data;
});
```

Benefits:
- Prevents re-execution of expensive operations
- Maintains state across widget rebuilds
- Useful for data that should persist

## 3. Provider Composition

Breaking down complex providers into smaller, focused ones:

```dart
// Base data provider
final itemsProvider = FutureProvider<List<Item>>((ref) async {
  return fetchItems();
});

// Filtered view of the data
final filteredItemsProvider = Provider<List<Item>>((ref) {
  final items = ref.watch(itemsProvider).value ?? [];
  final filter = ref.watch(filterProvider);
  
  return items.where((item) => item.matches(filter)).toList();
});

// Statistics based on the data
final itemStatsProvider = Provider<ItemStats>((ref) {
  final items = ref.watch(itemsProvider).value ?? [];
  return ItemStats.calculate(items);
});
```

Benefits:
- Better separation of concerns
- Improved reusability
- Easier testing

## 4. Error Handling

Consistent error handling patterns:

```dart
ref.listen<AsyncValue<User>>(userProvider, (previous, next) {
  next.whenOrNull(
    error: (error, stackTrace) {
      showErrorDialog(context, 'Failed to load user: $error');
    },
  );
});

// In the UI
userAsync.when(
  data: (user) => UserProfile(user: user),
  loading: () => const LoadingIndicator(),
  error: (error, _) => ErrorDisplay(message: error.toString()),
);
```

Benefits:
- Consistent user experience
- Better error recovery
- Improved debugging

## 5. Cancellation and Cleanup

For providers that need cleanup:

```dart
final streamProvider = StreamProvider<Data>((ref) {
  final controller = StreamController<Data>();
  
  // Set up the stream
  final subscription = source.listen((data) {
    controller.add(data);
  });
  
  // Dispose properly when no longer needed
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });
  
  return controller.stream;
});
```

Benefits:
- Prevents memory leaks
- Cleaner resource management
- Better application stability

## 6. State Normalization

For complex data structures:

```dart
// Instead of nested objects
final postsProvider = StateNotifierProvider<PostsNotifier, List<Post>>((ref) {
  return PostsNotifier();
});

// Use normalized state
final postsMapProvider = StateNotifierProvider<PostsMapNotifier, Map<String, Post>>((ref) {
  return PostsMapNotifier();
});

final postIdsProvider = Provider<List<String>>((ref) {
  final postsMap = ref.watch(postsMapProvider);
  return postsMap.keys.toList();
});

final postProvider = Provider.family<Post?, String>((ref, id) {
  final postsMap = ref.watch(postsMapProvider);
  return postsMap[id];
});
```

Benefits:
- Easier state updates
- Prevents duplication
- Better performance for large datasets

## 7. Logging and Debugging

Add a ProviderObserver for debugging:

```dart
void main() {
  runApp(
    ProviderScope(
      observers: [LoggingProviderObserver()],
      child: MyApp(),
    ),
  );
}

class LoggingProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('[${provider.name ?? provider.runtimeType}] value: $newValue');
  }
}
```

Benefits:
- Better visibility into state changes
- Easier debugging
- Helps identify rebuild issues

By applying these optimization techniques, we can significantly improve our Riverpod usage even without code generation.