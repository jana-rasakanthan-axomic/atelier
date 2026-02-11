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

When `AsyncValue<T>` is not sufficient, define a custom state class.

```dart
// lib/features/recipes/application/recipe_form_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_form_state.freezed.dart';

@freezed
class RecipeFormState with _$RecipeFormState {
  const factory RecipeFormState({
    @Default('') String title,
    @Default('') String description,
    @Default(false) bool isSubmitting,
    String? errorMessage,
    @Default(false) bool isSuccess,
  }) = _RecipeFormState;
}
```

```dart
// lib/features/recipes/application/recipe_form_notifier.dart
@riverpod
class RecipeFormNotifier extends _$RecipeFormNotifier {
  @override
  RecipeFormState build() {
    return const RecipeFormState();
  }

  void setTitle(String title) {
    state = state.copyWith(title: title, errorMessage: null);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description, errorMessage: null);
  }

  Future<void> submit() async {
    if (state.title.isEmpty) {
      state = state.copyWith(errorMessage: 'Title is required');
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final repository = ref.read(recipeRepositoryProvider);
      await repository.create(
        CreateRecipeRequest(title: state.title, description: state.description),
      );
      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } on AppException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
    }
  }
}
```

## Unit Test Example

```dart
// test/unit/features/recipes/recipe_list_notifier_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([RecipeRepository])
import 'recipe_list_notifier_test.mocks.dart';

void main() {
  late MockRecipeRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockRecipeRepository();
    container = ProviderContainer(
      overrides: [
        recipeRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('RecipeListNotifier', () {
    test('build fetches all recipes from repository', () async {
      final recipes = [
        Recipe(id: '1', title: 'Pasta', description: 'Good', createdAt: DateTime.now()),
      ];
      when(mockRepository.getAll()).thenAnswer((_) async => recipes);

      final result = await container.read(recipeListProvider.future);

      expect(result, equals(recipes));
      verify(mockRepository.getAll()).called(1);
    });

    test('addRecipe creates recipe and refreshes list', () async {
      final request = CreateRecipeRequest(title: 'Soup', description: 'Warm');
      when(mockRepository.getAll()).thenAnswer((_) async => []);
      when(mockRepository.create(request)).thenAnswer((_) async =>
        Recipe(id: '2', title: 'Soup', description: 'Warm', createdAt: DateTime.now()),
      );

      await container.read(recipeListProvider.future);
      await container.read(recipeListProvider.notifier).addRecipe(request);

      verify(mockRepository.create(request)).called(1);
      verify(mockRepository.getAll()).called(2);
    });
  });
}
```

## Anti-Patterns

```dart
// BAD: Importing Flutter in notifier
import 'package:flutter/material.dart';

// GOOD: No Flutter imports in application layer

// BAD: Manual try/catch for state transitions
try {
  state = const AsyncLoading();
  final data = await repository.getAll();
  state = AsyncData(data);
} catch (e, st) {
  state = AsyncError(e, st);
}

// GOOD: AsyncValue.guard() handles transitions
state = const AsyncLoading();
state = await AsyncValue.guard(() => repository.getAll());

// BAD: Creating repository instances directly
final repo = RecipeRepository(dio: Dio());

// GOOD: Inject via ref
final repo = ref.read(recipeRepositoryProvider);

// BAD: Mutating state without setting AsyncLoading first
Future<void> addRecipe(request) async {
  await repository.create(request);
  state = AsyncData(await repository.getAll());
}

// GOOD: Set loading state before async operation
Future<void> addRecipe(request) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    await repository.create(request);
    return repository.getAll();
  });
}
```

## Cross-References

- See `provider.md` for provider definitions and wiring
- See `repository.md` for repository patterns used by notifiers
- See `screen.md` for how screens consume notifier state
- See `model.md` for data classes returned by notifiers
