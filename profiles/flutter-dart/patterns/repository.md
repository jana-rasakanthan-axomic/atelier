# Repository Pattern

Data access layer using dio for HTTP communication and optional local caching.

## Location

`lib/features/{feature}/data/{feature}_repository.dart`

## Key Rules

1. **Contract-first**: Define repository method signatures from notifier requirements (what data the UI needs)
2. **Constructor injection of Dio**: Accept `Dio` instance, never create internally
3. **Return typed models**: Parse JSON responses into domain model objects, never return raw `Response`
4. **Let interceptors handle cross-cutting concerns**: Auth tokens, base URL, logging handled by dio interceptors
5. **Throw typed exceptions**: Map HTTP status codes to `AppException` subclasses
6. **No business logic**: Pure data access and transformation only

## Minimal Example

```dart
// lib/features/recipes/data/recipe_repository.dart
import 'package:dio/dio.dart';

class RecipeRepository {
  RecipeRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Recipe>> getAll({int limit = 50, int offset = 0}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/recipes',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final items = response.data!['items'] as List<dynamic>;
    return items
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

  Future<Recipe> update(String id, UpdateRecipeRequest request) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/recipes/$id',
      data: request.toJson(),
    );
    return Recipe.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/recipes/$id');
  }
}
```

## Error Handling with Typed Exceptions

```dart
class RecipeRepository {
  RecipeRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<Recipe> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/recipes/$id');
      return Recipe.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  AppException _mapException(DioException e) {
    if (e.response == null) return const NetworkException();
    return switch (e.response!.statusCode) {
      404 => NotFoundException(resource: 'Recipe', id: ''),
      409 => ConflictException(message: 'Recipe already exists'),
      422 => ValidationException(message: e.response!.data['detail'] ?? 'Validation error'),
      _ => NetworkException(message: 'Unexpected error: ${e.response!.statusCode}'),
    };
  }
}
```

> See [repository-caching.md](repository-caching.md) for the local cache pattern with SharedPreferences fallback.

## Common Methods

| Method | Return Type | Purpose |
|--------|-------------|---------|
| `getAll({limit, offset})` | `Future<List<Model>>` | Paginated list |
| `getById(id)` | `Future<Model>` | Single lookup |
| `create(request)` | `Future<Model>` | Create new entity |
| `update(id, request)` | `Future<Model>` | Update existing entity |
| `delete(id)` | `Future<void>` | Remove entity |

## Dio Interceptor Setup

The repository does not configure dio directly. Interceptors are set up at the app level.

```dart
// lib/core/network/dio_provider.dart
Dio createDio({required String baseUrl, required String Function() tokenProvider}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.addAll([
    _AuthInterceptor(tokenProvider),
    LogInterceptor(requestBody: true, responseBody: true),
  ]);
  return dio;
}
```

## Unit Test Example

```dart
@GenerateMocks([Dio])
import 'recipe_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late RecipeRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = RecipeRepository(dio: mockDio);
  });

  group('RecipeRepository', () {
    test('getAll returns list of recipes from API', () async {
      when(mockDio.get<Map<String, dynamic>>(
        '/recipes',
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => Response(
        data: {'items': [{'id': '1', 'title': 'Pasta', 'description': 'Good', 'created_at': '2024-01-01T00:00:00Z'}]},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/recipes'),
      ));

      final result = await repository.getAll();
      expect(result, hasLength(1));
      expect(result.first.title, equals('Pasta'));
    });

    test('getById throws NotFoundException for 404', () async {
      when(mockDio.get<Map<String, dynamic>>('/recipes/999')).thenThrow(
        DioException(
          response: Response(statusCode: 404, requestOptions: RequestOptions(path: '/recipes/999')),
          requestOptions: RequestOptions(path: '/recipes/999'),
        ),
      );

      expect(() => repository.getById('999'), throwsA(isA<NotFoundException>()));
    });
  });
}
```

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|-------------|-----------------|
| Creating Dio inside repository | Constructor injection: `RecipeRepository({required Dio dio})` |
| Returning raw `Response` | Return typed domain models: `Future<List<Recipe>>` |
| Business logic in repository (e.g., client-side filtering) | Pass filters as query params, let server filter |
| Swallowing errors with empty catch | Rethrow as typed exceptions via `_mapException` |

## Cross-References

- See `notifier.md` for how notifiers consume repositories
- See `provider.md` for repository provider definitions
- See `model.md` for data classes returned by repositories
- See `screen.md` for how screens trigger repository calls via notifiers
