# Notifier Pattern — Extended Examples

Reference examples for the notifier pattern. See `../notifier.md` for core rules.

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
