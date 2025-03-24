# Riverpod Implementation Strategy

## Current Challenges

We've encountered issues with setting up Riverpod code generation in this project:

1. Dependency conflicts between custom_lint, riverpod_lint, and the analyzer package
2. Build errors when trying to run build_runner

## Alternative Strategies

Given these challenges, here are some alternative strategies to move forward:

### Strategy 1: Incremental Refactoring Without Code Generation

We can improve our Riverpod usage without relying on code generation:

1. Optimize existing providers:
   - Use `ref.select()` to watch only needed parts of state
   - Use `ref.keepAlive()` for important providers
   - Organize providers into logical groups

2. Refactor StateNotifier implementations:
   - Ensure proper state immutability
   - Improve naming and documentation
   - Break up large notifiers into smaller, focused ones

3. Apply Provider best practices:
   - Avoid circular dependencies
   - Use Provider composition
   - Scope providers appropriately

### Strategy 2: Create a Separate Test Project

To experiment with Riverpod code generation safely:

1. Create a minimal Flutter project with just these dependencies:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_riverpod: ^2.4.0
     riverpod_annotation: ^2.1.5

   dev_dependencies:
     flutter_test:
       sdk: flutter
     build_runner: ^2.4.0
     riverpod_generator: ^2.1.5
   ```

2. Test the code generation in isolation
3. Once working, extract patterns to apply manually in this project
4. Later, when dependencies align better, integrate code generation

### Strategy 3: Gradual Migration Path

Even without code generation, we can prepare for future migration:

1. Structure providers to match the code-generated pattern:
   ```dart
   // Instead of:
   final counterProvider = StateProvider<int>((ref) => 0);
   
   // Use:
   int _counter(ProviderRef ref) => 0;
   final counterProvider = Provider<int>(_counter);
   ```

2. Create helper functions that mirror code-gen patterns:
   ```dart
   // Helper for simple providers
   Provider<T> simpleProvider<T>(T Function(ProviderRef<T> ref) create, {String? name}) {
     return Provider<T>((ref) => create(ref), name: name);
   }

   // Usage:
   final counterProvider = simpleProvider<int>((ref) => 0, name: 'counter');
   ```

3. Document providers in a way that makes future migration easier

## Recommended Approach

Given the technical challenges, we recommend Strategy 1 combined with elements of Strategy 3:

1. Focus on optimizing existing providers using current patterns
2. Structure new providers in a way that will make future migration easier
3. Create a separate test project to experiment with code generation
4. Revisit full code generation integration when the ecosystem is more stable

This approach allows us to improve code quality now while laying groundwork for code generation later.