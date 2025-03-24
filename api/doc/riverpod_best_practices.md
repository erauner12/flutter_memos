# Riverpod Best Practices

This document outlines best practices for using Riverpod in our app, based on the optimizations we've implemented.

## 1. Provider Declaration

### Naming and Documentation

```dart
/// Clear documentation explaining what the provider does
/// and any important behavior notes
///
/// OPTIMIZATION: Notes about specific optimizations applied
final exampleProvider = Provider<String>((ref) {
  // Implementation...
  return "value";
}, name: 'example'); // Add a name for better debugging
```

### Provider Types

Choose the appropriate provider type:
- `Provider`: For values that don't change
- `StateProvider`: For simple state that can be modified
- `FutureProvider`: For async operations that fetch data
- `StreamProvider`: For values that come from a stream
- `Provider.family`: When parameters are needed
- `ChangeNotifierProvider`: For migration from ChangeNotifier (not preferred for new code)

## 2. State Management Techniques

### Use `ref.select()`

Watch only what you need:

```dart
// Instead of:
final user = ref.watch(userProvider);
final name = user.name;

// Do this:
final name = ref.watch(userProvider.select((user) => user.name));
```

### Use `ref.listen()`

Listen for changes and react:

```dart
ref.listen<AsyncValue<User>>(userProvider, (previous, next) {
  next.whenOrNull(
    error: (error, stackTrace) {
      showErrorDialog(context, 'Failed to load user: $error');
    },
  );
});
```

### Use `ref.read()` in Actions

For actions that don't need rebuilds:

```dart
void handleLogin() {
  final authService = ref.read(authServiceProvider);
  authService.login(username, password);
}
```

## 3. Caching and Performance

### Use `keepAlive()`

Keep expensive providers alive:

```dart
final expensiveDataProvider = FutureProvider<List<Item>>((ref) async {
  // Keep this provider alive even when no one is watching it
  ref.keepAlive();
  
  // Expensive operation...
  return data;
});
```

### Implement Local Caching

Cache data to avoid redundant API calls:

```dart
final dataCacheProvider = StateProvider<Map<String, Data>>((ref) {
  return {};
});

final dataProvider = FutureProvider.family<Data, String>((ref, id) async {
  // Check cache first
  final cache = ref.read(dataCacheProvider);
  if (cache.containsKey(id)) {
    return cache[id]!;
  }
  
  // Otherwise fetch and update cache
  final data = await fetchData(id);
  ref.read(dataCacheProvider.notifier).update((state) => {
    ...state,
    id: data,
  });
  
  return data;
});
```

## 4. Error Handling

### Centralize Error Handling

Use a central provider for error management:

```dart
final errorHandlerProvider = Provider<void Function(String message, ErrorType type)>((ref) {
  return (message, type) {
    // Log error, update state, notify user, etc.
  };
});

// In other providers
try {
  // Risky operation
} catch (e) {
  ref.read(errorHandlerProvider)('Operation failed', ErrorType.network);
  rethrow; // Let AsyncValue handle the error state
}
```

### Use AsyncValue Methods

Handle different states consistently:

```dart
myAsyncValue.when(
  data: (data) => SuccessWidget(data: data),
  loading: () => const LoadingWidget(),
  error: (error, stackTrace) => ErrorWidget(error: error),
);

// Or for more control:
if (myAsyncValue.isLoading) {
  return const LoadingWidget();
}

if (myAsyncValue.hasError) {
  return ErrorWidget(error: myAsyncValue.error!);
}

// Safe access to data
final data = myAsyncValue.value ?? fallbackValue;
```

## 5. Provider Composition

### Break Down Complex State

Divide complex state into smaller, focused providers:

```dart
// Base data provider
final itemsProvider = FutureProvider<List<Item>>((ref) async {
  return fetchItems();
});

// Derived state
final filteredItemsProvider = Provider<List<Item>>((ref) {
  final items = ref.watch(itemsProvider).value ?? [];
  final filter = ref.watch(filterProvider);
  
  return items.where((item) => item.matches(filter)).toList();
});

// Statistics
final statsProvider = Provider<Stats>((ref) {
  final items = ref.watch(itemsProvider).value ?? [];
  return calculateStats(items);
});
```

### Use Family Providers Efficiently

Cache results from family providers:

```dart
final itemsCacheProvider = StateProvider<Map<String, Item>>((ref) => {});

final itemProvider = Provider.family<Item?, String>((ref, id) {
  // Try the cache first
  final cache = ref.read(itemsCacheProvider);
  return cache[id];
});

// Fetch and update cache
final fetchItemProvider = FutureProvider.family<Item, String>((ref, id) async {
  final item = await fetchItem(id);
  ref.read(itemsCacheProvider.notifier).update((state) => {
    ...state,
    id: item,
  });
  return item;
});
```

## 6. Debugging and Development

### Add Logging

Use logging to track provider behavior:

```dart
if (kDebugMode) {
  print('[providerName] Significant event: $details');
}
```

### Use ProviderObserver

Add a ProviderObserver for global monitoring:

```dart
class LoggingProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('[${provider.name}] value: $newValue');
  }
}

// In main.dart
ProviderScope(
  observers: [LoggingProviderObserver()],
  child: MyApp(),
)
```

## 7. Cleanup and Disposal

### Use `ref.onDispose()`

Clean up resources when a provider is disposed:

```dart
final streamProvider = StreamProvider<Data>((ref) {
  final controller = StreamController<Data>();
  
  // Setup stream...
  
  // Clean up when disposed
  ref.onDispose(() {
    controller.close();
  });
  
  return controller.stream;
});
```

## 8. State Normalization

### Normalize State for Complex Data

For complex relationships, normalize state:

```dart
// Instead of nested objects
final postsProvider = StateNotifierProvider<PostsNotifier, List<Post>>((ref) {
  return PostsNotifier();
});

// Use normalized state
final postsMapProvider = StateProvider<Map<String, Post>>((ref) => {});
final postIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(postsMapProvider).keys.toList();
});
final postProvider = Provider.family<Post?, String>((ref, id) {
  return ref.watch(postsMapProvider)[id];
});
```

## 9. Optimistic Updates

Implement optimistic updates for better user experience:

```dart
final addItemProvider = Provider.family<Future<void> Function(Item), String>((ref, listId) {
  return (Item item) async {
    // Generate temporary ID
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final optimisticItem = item.copyWith(id: tempId);
    
    // Update state optimistically
    ref.read(itemsProvider.notifier).update((items) => [...items, optimisticItem]);
    
    try {
      // Make the API call
      final result = await saveItem(item);
      
      // Update with real item
      ref.read(itemsProvider.notifier).update((items) =>
        items.map((i) => i.id == tempId ? result : i).toList()
      );
    } catch (e) {
      // Remove optimistic item on failure
      ref.read(itemsProvider.notifier).update((items) =>
        items.where((i) => i.id != tempId).toList()
      );
      
      // Handle error
      rethrow;
    }
  };
});
```

## 10. Testing

### Make Providers Testable

Design providers for testability:

```dart
// Provide dependencies through a provider
final httpClientProvider = Provider<HttpClient>((ref) => HttpClient());

// Use the dependency
final apiProvider = Provider<ApiService>((ref) {
  final client = ref.watch(httpClientProvider);
  return ApiService(client);
});

// In tests
testWidgets('API test', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        httpClientProvider.overrideWithValue(MockHttpClient()),
      ],
      child: const MyApp(),
    ),
  );
  
  // Rest of test...
});
```

By following these best practices, we can make our Riverpod code more maintainable, performant, and testable.
