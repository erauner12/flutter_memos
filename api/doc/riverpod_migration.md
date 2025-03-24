# Riverpod Code Generation Migration

## Current Status

We're in the process of migrating from manually defined Riverpod providers to code-generated ones. This offers several benefits:

- Less boilerplate code
- Improved type safety
- Better IDE support with autocompletion
- More maintainable codebase

## Dependency Issues

We've encountered some compatibility issues with the current setup:

1. `custom_lint` and `riverpod_lint` packages have conflicts with the version of the analyzer being used
2. There are errors with `AugmentationImportDirective` and `LibraryAugmentationDirective` types

## Immediate Next Steps

1. **Temporarily disable linting packages**: We've commented out `custom_lint` and `riverpod_lint` in the pubspec.yaml file to avoid conflicts.

2. **Use compatible versions**: We're using `riverpod_annotation: ^2.1.5` and `riverpod_generator: ^2.1.5` which should work together.

3. **Start with simple providers**: We've created a simple example in `lib/providers/generated/simple_counter.dart`.

4. **Run build_runner**: After running `flutter pub get`, try:
   ```
   dart run build_runner build --delete-conflicting-outputs
   ```

## Migration Plan

Once the basic code generation is working:

1. Migrate simple providers first (StateProvider → @riverpod function)
2. Then migrate StateNotifier providers to @riverpod class
3. Finally migrate family providers

### Example Migrations

**Simple Provider:**
```dart
// Before
final counterProvider = StateProvider<int>((ref) => 0);

// After
@riverpod
int counter(CounterRef ref) => 0;
```

**StateNotifier Provider:**
```dart
// Before
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  void increment() => state++;
}

final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) => CounterNotifier());

// After
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;
  
  void increment() => state++;
}
```

**Family Provider:**
```dart
// Before
final memoProvider = FutureProvider.family<Memo, String>((ref, id) async {
  return ref.read(apiServiceProvider).getMemo(id);
});

// After
@riverpod
Future<Memo> memo(MemoRef ref, String id) async {
  return ref.read(apiServiceProvider).getMemo(id);
}
```

## Future Steps

Once we have basic code generation working:

1. Re-enable linting packages once compatibility issues are resolved
2. Gradually migrate all providers
3. Update tests and documentation

## Troubleshooting

If you encounter build errors:

1. Try cleaning the project: `flutter clean`
2. Delete the .dart_tool directory
3. Run `flutter pub get` again
4. Try `dart run build_runner build --delete-conflicting-outputs`
