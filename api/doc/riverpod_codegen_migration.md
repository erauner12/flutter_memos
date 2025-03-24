# Riverpod Code Generation Migration Guide

This document outlines the process for migrating from manual Riverpod providers to code-generated providers.

## Benefits of Code Generation

- **Less boilerplate**: Code generation requires fewer lines of code for the same functionality
- **Type safety**: Generated providers have better type checking
- **Autocomplete**: IDE can better understand and suggest methods and properties
- **Consistency**: All providers follow the same pattern, making the codebase more maintainable

## Migration Process

### 1. Ensure Dependencies

The following dependencies are required:

```yaml
dependencies:
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

dev_dependencies:
  build_runner: ^2.4.15
  riverpod_generator: ^2.3.9
```

### 2. Migration Patterns

#### Simple Provider

Before:
```dart
final counterProvider = StateProvider<int>((ref) => 0);
```

After:
```dart
@riverpod
int counter(CounterRef ref) => 0;
```

#### StateNotifier Provider

Before:
```dart
class CounterController extends StateNotifier<int> {
  CounterController() : super(0);
  void increment() => state++;
}

final counterControllerProvider = StateNotifierProvider<CounterController, int>((ref) => CounterController());
```

After:
```dart
@riverpod
class CounterController extends _$CounterController {
  @override
  int build() => 0;
  
  void increment() => state++;
}
```

#### Family Provider

Before:
```dart
final memoProvider = FutureProvider.family<Memo, String>((ref, id) async {
  return ref.read(apiServiceProvider).getMemo(id);
});
```

After:
```dart
@riverpod
Future<Memo> memo(MemoRef ref, String id) async {
  return ref.read(apiServiceProvider).getMemo(id);
}
```

### 3. Running Code Generation

After adding the `@riverpod` annotations, you need to generate the implementation files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Or use watch mode for continuous generation during development:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 4. Using the Generated Providers

The usage in widgets remains largely the same:

```dart
// Before
final counter = ref.watch(counterProvider);

// After
final counter = ref.watch(counterProvider);
```

For StateNotifier classes:

```dart
// Before
ref.read(counterControllerProvider.notifier).increment();

// After
ref.read(counterControllerProvider.notifier).increment();
```

### 5. Migrating Incrementally

You can migrate providers one by one:

1. Create the new code-generated provider
2. Run build_runner to generate the implementation
3. Update references in your code
4. Remove the old provider once all references are updated

### 6. Tips for Successful Migration

- Start with simple providers first
- Test thoroughly after each migration
- Use proper naming to avoid conflicts during transition
- Consider using a different directory (like `lib/providers/generated/`) for new providers
- Use the IDE to find all references to the old provider

## Common Issues

### Build Runner Errors

If you see errors like "Could not find generator for ...", try:

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Missing Generated Files

Ensure each file with `@riverpod` annotations has:

```dart
part 'filename.g.dart';
```

Where `filename` is the name of the current file.

### Keeping State During Migration

To ensure state is preserved during migration, you can temporarily have both providers and synchronize their states until you fully migrate.
