# Provider Pattern

Riverpod provider definitions for dependency injection and state wiring.

## Location

- `lib/features/{feature}/application/{feature}_notifier.dart` - Generated providers (via `@riverpod` annotation)
- `lib/core/providers/dio_provider.dart` - Infrastructure providers (dio, shared_preferences)
- `lib/features/{feature}/data/{feature}_repository.dart` - Repository providers (alongside class definition)

## Key Rules

1. **Use `@riverpod` code generation**: Prefer generated providers over hand-written `Provider()` calls
2. **Providers defined alongside their class**: Repository provider lives in repository file, notifier provider in notifier file
3. **Infrastructure providers centralized**: `Dio`, `SharedPreferences`, and other shared instances in `lib/core/providers/`
4. **`ProviderScope` at app root**: Wrap `MaterialApp` in `ProviderScope` for dependency injection
5. **Override providers in tests**: Use `ProviderScope(overrides: [...])` for mocking

## Generated Provider (Preferred)

The `@riverpod` annotation generates provider definitions automatically.

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
}
// Generated: recipeListNotifierProvider (auto-dispose, async)
```

```dart
// lib/features/recipes/data/recipe_repository.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_repository.g.dart';

@riverpod
RecipeRepository recipeRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return RecipeRepository(dio: dio);
}

class RecipeRepository {
  RecipeRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;
  // ...
}
```

## Infrastructure Providers

Centralized providers for shared dependencies. Use `@Riverpod(keepAlive: true)` for long-lived infrastructure (Dio, SharedPreferences). For async initialization, override at app startup via `ProviderScope(overrides: [...])`.

See `reference/provider-examples.md` for full infrastructure provider examples.

## Provider Types Reference

| Annotation | Generated Type | Auto-Dispose | Use Case |
|------------|---------------|--------------|----------|
| `@riverpod` on function | `Provider` / `FutureProvider` | Yes | Stateless value or async computation |
| `@riverpod` on class | `NotifierProvider` / `AsyncNotifierProvider` | Yes | Stateful logic with methods |
| `@Riverpod(keepAlive: true)` on function | `Provider` (no auto-dispose) | No | Long-lived infrastructure (Dio, prefs) |
| `@Riverpod(keepAlive: true)` on class | `NotifierProvider` (no auto-dispose) | No | App-wide state (auth, theme) |

## Family Providers (Parameterized)

Generated automatically when `build()` accepts parameters.

```dart
// lib/features/recipes/application/recipe_detail_notifier.dart
@riverpod
class RecipeDetailNotifier extends _$RecipeDetailNotifier {
  @override
  Future<Recipe> build(String recipeId) async {
    final repository = ref.watch(recipeRepositoryProvider);
    return repository.getById(recipeId);
  }
}

// Usage: ref.watch(recipeDetailNotifierProvider('recipe-123'))
```

## App Root Setup

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

// lib/app.dart
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
    );
  }
}
```

## Testing with Provider Overrides

Override providers in tests using `ProviderScope(overrides: [...])` for widget tests or `ProviderContainer(overrides: [...])` for unit tests.

See `reference/provider-examples.md` for full widget test and unit test examples.

## Anti-Patterns

Key mistakes to avoid:
- Hand-written `StateNotifierProvider` when `@riverpod` code generation works
- Using `@riverpod` (auto-dispose) for infrastructure providers -- use `@Riverpod(keepAlive: true)` instead
- Placing providers in the wrong location -- provider belongs alongside its class, not in a central folder
- Accessing providers outside `ProviderScope`

See `reference/provider-examples.md` for detailed anti-pattern examples.

## Cross-References

- See `notifier.md` for notifier class implementation
- See `repository.md` for repository class implementation
- See `screen.md` for how screens consume providers
- See `model.md` for data types flowing through providers
