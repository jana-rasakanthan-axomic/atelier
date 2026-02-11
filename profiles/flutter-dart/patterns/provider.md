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

Centralized providers for shared dependencies.

```dart
// lib/core/providers/dio_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000'),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  return dio;
}
```

```dart
// lib/core/providers/storage_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'storage_provider.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
}
```

For async initialization (like `SharedPreferences`), override at app startup:

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}
```

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

### Widget Tests

```dart
// test/widget/features/recipes/recipe_list_screen_test.dart
void main() {
  testWidgets('shows recipes when data is loaded', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipeListNotifierProvider.overrideWith(
            () => FakeRecipeListNotifier(),
          ),
        ],
        child: const MaterialApp(home: RecipeListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pasta'), findsOneWidget);
  });
}

class FakeRecipeListNotifier extends RecipeListNotifier {
  @override
  Future<List<Recipe>> build() async {
    return [
      Recipe(id: '1', title: 'Pasta', description: 'Good', createdAt: DateTime.now()),
    ];
  }
}
```

### Unit Tests with ProviderContainer

```dart
// test/unit/features/recipes/recipe_list_notifier_test.dart
void main() {
  late MockRecipeRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockRecipeRepository();
    container = ProviderContainer(
      overrides: [
        recipeRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('build fetches recipes from repository', () async {
    when(mockRepo.getAll()).thenAnswer((_) async => []);

    final result = await container.read(recipeListNotifierProvider.future);

    expect(result, isEmpty);
    verify(mockRepo.getAll()).called(1);
  });
}
```

## Provider Dependency Graph

```
dioProvider (keepAlive)
  └── recipeRepositoryProvider
        └── recipeListNotifierProvider
              └── RecipeListScreen (ConsumerWidget)

sharedPreferencesProvider (keepAlive, overridden at startup)
  └── settingsRepositoryProvider
        └── settingsNotifierProvider
              └── SettingsScreen (ConsumerWidget)
```

## Anti-Patterns

```dart
// BAD: Hand-written provider when @riverpod works
final recipeListProvider = StateNotifierProvider<RecipeListNotifier, AsyncValue<List<Recipe>>>((ref) {
  return RecipeListNotifier(ref.watch(recipeRepositoryProvider));
});

// GOOD: Generated provider
@riverpod
class RecipeListNotifier extends _$RecipeListNotifier { ... }

// BAD: Auto-dispose for infrastructure providers
@riverpod  // This auto-disposes Dio when no one watches it
Dio dio(Ref ref) => Dio();

// GOOD: keepAlive for shared infrastructure
@Riverpod(keepAlive: true)
Dio dio(Ref ref) => Dio();

// BAD: Accessing providers outside ProviderScope
final container = ProviderContainer();
final dio = container.read(dioProvider);  // No overrides, raw usage

// GOOD: Override in tests, ProviderScope in app
ProviderScope(
  overrides: [dioProvider.overrideWithValue(mockDio)],
  child: const App(),
)

// BAD: Provider in wrong location
// lib/core/providers/recipe_notifier_provider.dart  <-- Wrong
final recipeProvider = ...;

// GOOD: Provider alongside its class
// lib/features/recipes/application/recipe_list_notifier.dart  <-- Right
@riverpod
class RecipeListNotifier extends _$RecipeListNotifier { ... }
```

## Cross-References

- See `notifier.md` for notifier class implementation
- See `repository.md` for repository class implementation
- See `screen.md` for how screens consume providers
- See `model.md` for data types flowing through providers
