# Notifier Pattern

Riverpod AsyncNotifier and Notifier for state management and business logic orchestration.

## Location

- `lib/features/{feature}/application/{feature}_notifier.dart` - Notifier implementation
- `lib/features/{feature}/application/{feature}_state.dart` - Custom state classes (if needed)

## Key Rules

1. **Contract-first**: Define the notifier's public methods and state type from UI requirements
2. **Use `@riverpod` annotation**: Code generation for provider boilerplate
3. **`build()` defines initial state**: Return type determines `AsyncValue` wrapping
4. **`AsyncValue.guard()` for mutations**: Automatic error catching and state transitions
5. **No Flutter imports**: Notifiers must never import `material.dart`, `widgets.dart`, or `BuildContext`
6. **Inject via `ref`**: Access repositories and other providers through `ref.watch()` / `ref.read()`

## AsyncNotifier (Async State)

Use when state depends on asynchronous operations (API calls, database reads).

```dart
// lib/features/recipes/application/recipe_list_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_list_notifier.g.dart';

@riverpod
class RecipeListNotifier extends _$RecipeListNotifier {
  @override
  Future<List<Recipe>> build() async {
    final repository = ref.watch(recipeRepositoryProvider);
    return repository.getAll();
  }

  Future<void> addRecipe(CreateRecipeRequest request) async {
    final repository = ref.read(recipeRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.create(request);
      return repository.getAll();
    });
  }

  Future<void> deleteRecipe(String id) async {
    final repository = ref.read(recipeRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.delete(id);
      return repository.getAll();
    });
  }

  Future<void> refresh() async {
    final repository = ref.read(recipeRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.getAll());
  }
}
```

## Notifier (Synchronous State)

Use when state is purely local with no async dependencies.

```dart
// lib/features/recipes/application/recipe_filter_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_filter_notifier.g.dart';

@riverpod
class RecipeFilterNotifier extends _$RecipeFilterNotifier {
  @override
  RecipeFilter build() {
    return const RecipeFilter();
  }

  void setCategory(String? category) {
    state = state.copyWith(category: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void reset() {
    state = const RecipeFilter();
  }
}
```

## Detail Notifier (Family Provider)

Use for entity-specific state that varies by ID.

```dart
// lib/features/recipes/application/recipe_detail_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_detail_notifier.g.dart';

@riverpod
class RecipeDetailNotifier extends _$RecipeDetailNotifier {
  @override
  Future<Recipe> build(String recipeId) async {
    final repository = ref.watch(recipeRepositoryProvider);
    return repository.getById(recipeId);
  }

  Future<void> update(UpdateRecipeRequest request) async {
    final repository = ref.read(recipeRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.update(arg, request);
      return repository.getById(arg);
    });
  }
}
```

Notes on family providers:
- The `arg` property on the notifier gives access to the build parameter (`recipeId`)
- The generated provider is called as `recipeDetailProvider('some-id')`
- Each ID gets its own independent notifier instance

## Custom State Classes

When `AsyncValue<T>` is not sufficient, define a custom state class using `@freezed`. Use `copyWith` for immutable state transitions. See `reference/notifier-examples.md` for a full form state and form notifier example.

## Testing

Test notifiers using `ProviderContainer` with repository overrides. See `reference/notifier-examples.md` for a full unit test example with Mockito.

## Anti-Patterns

Key mistakes to avoid:
- Importing Flutter in the application layer
- Manual `try/catch` instead of `AsyncValue.guard()` for state transitions
- Creating repository instances directly instead of injecting via `ref`
- Mutating state without setting `AsyncLoading` first

See `reference/notifier-examples.md` for detailed anti-pattern examples.

## Cross-References

- See `provider.md` for provider definitions and wiring
- See `repository.md` for repository patterns used by notifiers
- See `screen.md` for how screens consume notifier state
- See `model.md` for data classes returned by notifiers
