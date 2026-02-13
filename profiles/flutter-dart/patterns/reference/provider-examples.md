# Provider Pattern — Extended Examples

Reference examples for the provider pattern. See `../provider.md` for core rules.

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
  +-- recipeRepositoryProvider
        +-- recipeListNotifierProvider
              +-- RecipeListScreen (ConsumerWidget)

sharedPreferencesProvider (keepAlive, overridden at startup)
  +-- settingsRepositoryProvider
        +-- settingsNotifierProvider
              +-- SettingsScreen (ConsumerWidget)
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
