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

**Allowed Bash tools:** `Bash(flutter:*), Bash(dart:*), Bash(git:*), Bash(uuidgen)`

---

## Test Patterns

### TDD Applicability

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

| Type | Location | Naming |
|------|----------|--------|
| Unit | `test/unit/` | `*_test.dart` |
| Widget | `test/widget/` | `*_test.dart` |
| Integration | `integration_test/` | `*_test.dart` |

All tests use AAA (Arrange, Act, Assert) pattern.

### Test Function Naming

Format: `test [method] [scenario] [expected]` using string descriptions (spaces, not underscores). Group related tests with `group('ClassName', () { ... })`.

Examples: `test('createRecipe with valid data returns recipe')`, `test('getRecipe when not found throws NotFoundException')`

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

Each layer has a dedicated pattern file with full implementation examples and rules.

| Layer | Pattern File | Key Rules |
|-------|-------------|-----------|
| **Screen** | [`patterns/screen.md`](flutter-dart/patterns/screen.md) | `ConsumerWidget`, `ref.watch()` for reactive state, thin `build()` methods |
| **Notifier** | [`patterns/notifier.md`](flutter-dart/patterns/notifier.md) | `@riverpod` annotation, `AsyncValue.guard()`, no Flutter/BuildContext imports |
| **Repository** | [`patterns/repository.md`](flutter-dart/patterns/repository.md) | Constructor-injected `Dio`, return typed models, let interceptors handle auth |
| **Model** | [`patterns/model.md`](flutter-dart/patterns/model.md) | `@freezed` for immutable data, `required` fields, pure data containers |
| **Provider** | [`patterns/provider.md`](flutter-dart/patterns/provider.md) | Riverpod provider definitions |

Exception pattern: Use `sealed class AppException` for exhaustive pattern matching. Include `message` for UI display and optional `statusCode` for API error mapping. Never expose internal stack traces.

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

```
project-root/
  pubspec.yaml, analysis_options.yaml
  lib/
    main.dart, app.dart
    router/app_router.dart
    features/{feature}/
      presentation/screens/{feature}_screen.dart
      presentation/widgets/{feature}_card.dart
      application/{feature}_notifier.dart, {feature}_state.dart
      data/{feature}_repository.dart, {feature}_dto.dart
      domain/{feature}_model.dart
    core/ (theme/, constants/, widgets/, exceptions/)
  test/
    unit/features/{feature}/
    widget/features/{feature}/
  integration_test/
```

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
