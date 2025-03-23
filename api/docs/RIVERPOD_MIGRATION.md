# Riverpod Migration Guide

This document outlines our approach to migrating the Flutter Memos app from `setState` to Riverpod for state management. The migration has been completed successfully, providing clear patterns for future development.

## Migration Approach

We followed a gradual migration approach:

1. **Started with key areas that benefit the most from Riverpod**:
   - Global or shared state (API services, theme, auth, etc.)
   - Complex state with multiple consumers
   - State that persists across multiple screens

2. **Kept using `setState` for**:
   - Truly ephemeral UI state (like form field focus or animation controllers)
   - Widget-specific toggles that don't affect other parts of the app

3. **Applied Riverpod to new features first**:
   - This allowed us to get familiar with Riverpod patterns without disrupting existing functionality

## Key Implemented Provider Types

The migration successfully uses several provider types to manage different kinds of state:

### 1. Simple Providers
```dart
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
```
Used for dependency injection of services and utility classes.

### 2. State Providers
```dart
final timeFilterProvider = StateProvider<String>((ref) => 'all');
final statusFilterProvider = StateProvider<String>((ref) => 'untagged');
```
Used for simple state that can change and needs to be watched by multiple widgets.

### 3. Future Providers
```dart
final memosProvider = FutureProvider<List<Memo>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final filter = ref.watch(combinedFilterProvider);
  // Fetch data based on current state...
  return apiService.listMemos(filter: filter);
});
```
Used for async data fetching that depends on other state.

### 4. Family Providers
```dart
final memoDetailProvider = FutureProvider.family<Memo, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMemo(id);
});
```
Used for data fetching that depends on parameters.

### 5. Action Providers
```dart
final saveMemoProvider = Provider.family<Future<void> Function(Memo), String>((
  ref,
  id,
) {
  return (Memo updatedMemo) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.updateMemo(id, updatedMemo);
    ref.invalidate(memosProvider); // Refresh the memos list
  };
});
```
Used for defining action handlers that can be called from the UI.

## Provider Organization

We've organized providers into domain-specific files:

- **api_providers.dart** - Services for API access
- **filter_providers.dart** - Filter state and logic
- **memo_providers.dart** - Memo data and operations
- **navigation_providers.dart** - Navigation state

## Established Best Practices

### 1. Watch vs. Read Pattern

- Use `ref.watch()` for values that should trigger rebuilds
- Use `ref.read()` for actions that don't need to trigger rebuilds

```dart
// Watching for reactive updates
final filteredMemos = ref.watch(filteredMemosProvider);

// Reading for actions
ref.read(saveMemoProvider(memoId))(updatedMemo);
```

### 2. Data Invalidation

After modifying data, invalidate the relevant providers to refresh:

```dart
await ref.read(apiServiceProvider).updateMemo(id, updatedMemo);
ref.invalidate(memosProvider); // Refresh affected providers
```

### 3. Local Caching Strategy

For better user experience, we cache data locally while remote data is loading:

```dart
return commentsAsync.when(
  data: (comments) {
    // Update the cache when new data arrives
    _comments = comments;
    return _buildContent(memo, comments);
  },
  loading: () => _buildContent(memo, _comments), // Use cached data during loading
  error: (_, __) => _buildContent(memo, _comments), // Use cached data on error
);
```

### 4. Error Handling

Consistent error handling with AsyncValue pattern:

```dart
return memoAsync.when(
  data: (memo) => /* Build UI with data */,
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (error, _) => Center(
    child: Text('Error: $error', style: TextStyle(color: Colors.red)),
  ),
);
```

### 5. Combined State Derivation

Creating derived state by combining multiple providers:

```dart
final combinedFilterProvider = Provider<String>((ref) {
  final timeFilter = ref.watch(timeFilterProvider);
  final statusFilter = ref.watch(statusFilterProvider);
  // Create combined filter expression...
  return combinedFilter;
});
```

## Example Implementations

### Memo Detail Screen

The `MemoDetailScreen` uses multiple providers to fetch and display data:

```dart
// Provider for memo details
final memoDetailProvider = FutureProvider.family<Memo, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMemo(id);
});

// Provider for memo comments
final memoCommentsProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  memoId,
) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.listMemoComments(memoId);
});

// Provider for adding a comment
final addCommentProvider =
    Provider.family<Future<void> Function(Comment), String>((ref, memoId) {
      return (Comment comment) async {
        final apiService = ref.read(apiServiceProvider);
        await apiService.createMemoComment(memoId, comment);
        ref.invalidate(memoCommentsProvider(memoId)); // Refresh comments
      };
    });
```

The UI then consumes these providers:

```dart
Widget _buildBody() {
  final memoAsync = ref.watch(memoDetailProvider(widget.memoId));
  final commentsAsync = ref.watch(memoCommentsProvider(widget.memoId));
  
  return memoAsync.when(
    data: (memo) {
      // Process memo data and manage local state
      
      // Then handle comments data
      return commentsAsync.when(
        data: (comments) => _buildContent(memo, comments),
        loading: () => _buildContent(memo, _comments),
        error: (_, __) => _buildContent(memo, _comments),
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => Center(child: Text('Error: $error')),
  );
}
```

## Testing with Riverpod

Our testing approach:

1. **Unit Tests**: Testing providers in isolation using `ProviderContainer`
2. **Widget Tests**: Using `ProviderScope` to override providers with mocks
3. **Integration Tests**: Testing multiple providers working together

Example:
```dart
testWidgets('EditMemoScreen loads memo data correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
      ],
      child: const MaterialApp(
        home: EditMemoScreen(memoId: 'test-memo-id'),
      ),
    ),
  );

  // Wait for async operations
  await tester.pumpAndSettle();

  // Verify UI reflects the fetched data
  expect(find.text('Test Memo Content'), findsOneWidget);
});
```

## Benefits Realized

1. **Improved Testability**: Services and dependencies are easily mocked in tests
2. **Reduced Boilerplate**: Complex state flow is managed with less code
3. **Better Separation of Concerns**: UI logic and business logic are cleanly separated
4. **More Reactive UI**: UI automatically updates when relevant state changes
5. **Efficient Rebuilding**: Only widgets that depend on changed state rebuild

## Next Steps

For future development:

1. **Consider Using Code Generation**: For larger apps, `riverpod_generator` can reduce boilerplate
2. **Add State Persistence**: Consider using Riverpod with storage solutions for persistence
3. **Implement State Restoration**: Add state restoration capabilities for improved UX
4. **Consider State Debugging Tools**: Riverpod DevTools can help debug complex state flows

## Learning Resources

- [Riverpod Documentation](https://riverpod.dev/docs/introduction/getting_started)
- [Flutter Riverpod Snippets](https://github.com/rrousselGit/riverpod/tree/master/examples)
- [Testing in Riverpod](https://riverpod.dev/docs/essentials/testing)
