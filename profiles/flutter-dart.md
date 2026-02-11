# Profile: flutter-dart

Flutter mobile app with Riverpod state management, GoRouter navigation, and dio HTTP client.

## Detection

How Atelier identifies a project as flutter-dart:

```yaml
markers:
  required:
    - pubspec.yaml
  content_match:
    - file: pubspec.yaml
      pattern: "flutter"
  optional:
    - lib/main.dart
    - android/app/build.gradle
    - ios/Runner.xcodeproj
```

If `pubspec.yaml` exists AND contains the string `flutter`, this profile activates.

---

## Stack

| Component        | Requirement                                      |
|------------------|--------------------------------------------------|
| **Language**     | Dart >= 3.0                                      |
| **Framework**    | Flutter >= 3.16                                  |
| **State Mgmt**  | Riverpod >= 2.0                                  |
| **Navigation**   | GoRouter                                         |
| **HTTP**         | dio >= 5.0                                       |
| **Storage**      | shared_preferences, flutter_secure_storage       |
| **Testing**      | flutter_test, mockito, integration_test          |
| **Quality**      | dart analyze, dart format                        |

---

## Architecture Layers

Ordered outside-in (the order you read contracts, write tests, and build implementation).

| # | Layer                  | Responsibility                                                                 |
|---|------------------------|--------------------------------------------------------------------------------|
| 1 | **Screen**             | Flutter widgets, UI layout, user interaction, GoRouter route definitions        |
| 2 | **Notifier/Provider**  | Riverpod state management, business logic, UI state transitions                |
| 3 | **Repository**         | Data access abstraction, API calls via dio, local cache coordination           |
| 4 | **Model**              | Data classes (freezed/json_serializable), DTOs, domain entities                |

---

## Build Order

```
Screen --> Notifier --> Repository --> Model
```

**Rationale:** Start from the user-facing screen contract and drive implementation inward from UI requirements, not from the API response shape.

**Note:** If the feature requires new data classes, define minimal model stubs first to satisfy type references, then flesh them out fully in the Model layer.

---

## Quality Tools

```yaml
tools:
  test_runner:
    command: "flutter test"
    single_file: "flutter test {file}"
    verbose: "flutter test --reporter expanded"
    coverage: "flutter test --coverage"
    confirm_red: "flutter test {test_file}"
    confirm_green: "flutter test {test_file}"

  linter:
    command: "dart analyze"
    fix: "dart fix --apply"

  type_checker:
    command: ""  # Dart is strongly typed at compile time; dart analyze covers this

  formatter:
    command: "dart format lib/"
    check: "dart format --set-exit-if-changed lib/"
```

### Verify Step (run after every layer)

```bash
flutter test {test_file} && dart analyze && dart format --set-exit-if-changed lib/
```

All checks must pass before a layer is considered complete.

---

## Allowed Bash Tools

For use in command and agent frontmatter `allowed-tools` fields:

```
Bash(flutter:*), Bash(dart:*), Bash(git:*), Bash(uuidgen)
```

---

## Test Patterns

### What Gets Tested First (TDD Applicability)

| Layer              | Test First? | Mock Target            | Rationale                                      |
|--------------------|-------------|------------------------|-------------------------------------------------|
| Screen             | YES         | Notifier/Provider      | Contract-driven; validates widget structure before logic exists |
| Notifier/Provider  | YES         | Repository             | State transitions verified in isolation         |
| Repository         | YES         | dio HTTP Client        | Data access logic verified without network      |
| Model              | NO          | --                     | Covered by freezed/json_serializable codegen and unit tests on serialization |

### Mocking Strategy

Each layer mocks the layer directly below it. Never mock two layers down.

```
Screen Tests    --> Mock Notifier/Provider (ProviderScope overrides)
Notifier Tests  --> Mock Repository
Repository Tests --> Mock dio HTTP Client
```

### Test Organization

```yaml
test_patterns:
  unit:
    location: "test/unit/"
    naming: "*_test.dart"
    pattern: "AAA (Arrange, Act, Assert) with group/test"
    markers: []
  widget:
    location: "test/widget/"
    naming: "*_test.dart"
    markers: []
  integration:
    location: "integration_test/"
    naming: "*_test.dart"
    markers: []
```

### Test Function Naming

```
test [method] [scenario] [expected]
```

Dart uses string descriptions in `test()` calls (spaces, not underscores):

Examples:
- `test('createRecipe with valid data returns recipe')`
- `test('createRecipe with duplicate title throws ConflictException')`
- `test('getRecipe when not found throws NotFoundException')`

Group related tests with `group()`:
- `group('RecipeNotifier', () { ... })`

---

## Naming Conventions

```yaml
naming:
  files: "snake_case.dart"
  classes: "PascalCase"
  functions: "camelCase"
  constants: "camelCase or kPrefixed"
  test_files: "*_test.dart"
  private: "_prefixed"
  widgets: "PascalCase extends StatelessWidget/StatefulWidget"
  providers: "camelCase + Provider suffix (e.g., recipeListProvider)"
  notifiers: "PascalCase + Notifier suffix (e.g., RecipeListNotifier)"
  states: "PascalCase + State suffix or sealed class (e.g., RecipeListState)"
  repositories: "PascalCase + Repository suffix (e.g., RecipeRepository)"
  models: "PascalCase matching domain entity (e.g., Recipe, Ingredient)"
```

---

## Code Patterns

### Screen Pattern

```dart
// lib/features/recipes/presentation/screens/recipe_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecipeListScreen extends ConsumerWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: switch (state) {
        AsyncData(:final value) => _RecipeList(recipes: value),
        AsyncError(:final error) => _ErrorView(error: error),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
```

Rules:
- Use `ConsumerWidget` for widgets that read providers
- Use `ref.watch()` for reactive state, `ref.read()` for one-shot actions
- Extract sub-widgets as private classes in the same file or separate widget files
- Keep `build()` methods thin; delegate layout to extracted widgets

### Notifier Pattern

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
}
```

Rules:
- Use `@riverpod` annotation (code generation) for provider definitions
- `build()` defines initial state; return type determines `AsyncValue` wrapping
- Use `AsyncValue.guard()` for error handling in mutations
- Inject repositories via `ref.watch()` / `ref.read()`
- Never import Flutter widgets or BuildContext

### Repository Pattern

```dart
// lib/features/recipes/data/recipe_repository.dart
import 'package:dio/dio.dart';

class RecipeRepository {
  RecipeRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Recipe>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/recipes');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(Recipe.fromJson)
        .toList();
  }

  Future<Recipe> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/recipes/$id');
    return Recipe.fromJson(response.data!);
  }

  Future<Recipe> create(CreateRecipeRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/recipes',
      data: request.toJson(),
    );
    return Recipe.fromJson(response.data!);
  }
}
```

Rules:
- Constructor injection of `Dio` instance
- Return typed domain models, not raw `Response` objects
- Use `fromJson` / `toJson` for serialization (json_serializable or freezed)
- Let dio interceptors handle auth tokens and base URL
- Throw typed exceptions for known error status codes

### Model Pattern

```dart
// lib/features/recipes/domain/recipe_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_model.freezed.dart';
part 'recipe_model.g.dart';

@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    required String id,
    required String title,
    required String description,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) =>
      _$RecipeFromJson(json);
}
```

Rules:
- Use `@freezed` for immutable data classes with value equality
- Use `@JsonSerializable` for simpler DTOs that do not need copyWith/unions
- All fields use `required` unless nullable
- Factory constructors for `fromJson` (generated by json_serializable)
- Keep models free of business logic; they are pure data containers

### Exception Pattern

```dart
// lib/core/exceptions/app_exception.dart
sealed class AppException implements Exception {
  const AppException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;
}

class NotFoundException extends AppException {
  const NotFoundException({required String resource, required String id})
      : super(message: '$resource with id $id not found', statusCode: 404);
}

class ConflictException extends AppException {
  const ConflictException({required String message})
      : super(message: message, statusCode: 409);
}

class NetworkException extends AppException {
  const NetworkException({String message = 'Network error occurred'})
      : super(message: message);
}
```

Rules:
- Use `sealed class` for exhaustive pattern matching on exception types
- Include human-readable `message` for UI display
- Include optional `statusCode` for API error mapping
- Never expose internal stack traces or server error details in `message`

---

## Style Limits

```yaml
limits:
  max_function_lines: 30
  max_file_lines: 300
  max_class_lines: 200
  max_parameters: 5
  max_nesting_depth: 3
```

If a function exceeds 30 lines, extract a helper. If a file exceeds 300 lines, split into modules. If nesting exceeds 3 levels, use early returns or extract logic.

---

## Dependencies

```yaml
dependencies:
  manager: "pub"
  install: "flutter pub get"
  add: "flutter pub add {pkg}"
  add_dev: "flutter pub add --dev {pkg}"
  lock_file: "pubspec.lock"
```

---

## Project Structure

```yaml
structure:
  source_root: "lib/"
  test_root: "test/"
  config_files:
    - pubspec.yaml
    - analysis_options.yaml
  entry_point: "lib/main.dart"
```

### Expected Directory Layout

```
project-root/
  pubspec.yaml
  analysis_options.yaml
  lib/
    main.dart
    app.dart
    router/
      app_router.dart
    features/
      {feature}/
        presentation/
          screens/
            {feature}_screen.dart
          widgets/
            {feature}_card.dart
        application/
          {feature}_notifier.dart
          {feature}_state.dart
        data/
          {feature}_repository.dart
          {feature}_dto.dart
        domain/
          {feature}_model.dart
    core/
      theme/
      constants/
      widgets/
      exceptions/
  test/
    unit/
      features/
        {feature}/
    widget/
      features/
        {feature}/
  integration_test/
```

---

## Pattern Files Reference

Detailed pattern files live alongside this profile for use by code-generation skills:

```
profiles/flutter-dart/patterns/
  screen.md        # Screen/page widget pattern with GoRouter
  notifier.md      # Riverpod AsyncNotifier/Notifier pattern
  repository.md    # Repository pattern with dio
  model.md         # Freezed/json_serializable model pattern
  provider.md      # Riverpod provider definitions pattern
```

Commands and agents reference these patterns by path:
```
$PROFILE_DIR/patterns/screen.md
$PROFILE_DIR/patterns/notifier.md
$PROFILE_DIR/patterns/repository.md
$PROFILE_DIR/patterns/model.md
$PROFILE_DIR/patterns/provider.md
```

Where `$PROFILE_DIR` resolves to `profiles/flutter-dart/` for this profile.

---

## Profile Metadata

```yaml
metadata:
  name: flutter-dart
  version: "1.0.0"
  description: "Flutter mobile app with Riverpod, GoRouter, and dio"
  authors: ["atelier"]
  tags: ["dart", "flutter", "riverpod", "mobile", "ios", "android"]
```
