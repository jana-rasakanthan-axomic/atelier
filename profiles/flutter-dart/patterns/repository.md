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
// lib/features/recipes/data/recipe_repository.dart
import 'package:dio/dio.dart';

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
    if (e.response == null) {
      return const NetworkException();
    }
    return switch (e.response!.statusCode) {
      404 => NotFoundException(resource: 'Recipe', id: ''),
      409 => ConflictException(message: 'Recipe already exists'),
      422 => ValidationException(message: e.response!.data['detail'] ?? 'Validation error'),
      _ => NetworkException(message: 'Unexpected error: ${e.response!.statusCode}'),
    };
  }
}
```

## Repository with Local Cache

```dart
// lib/features/recipes/data/recipe_repository.dart
class RecipeRepository {
  RecipeRepository({
    required Dio dio,
    required SharedPreferences prefs,
  })  : _dio = dio,
        _prefs = prefs;

  final Dio _dio;
  final SharedPreferences _prefs;
  static const _cacheKey = 'cached_recipes';

  Future<List<Recipe>> getAll() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/recipes');
      final items = response.data!['items'] as List<dynamic>;
      final recipes = items
          .cast<Map<String, dynamic>>()
          .map(Recipe.fromJson)
          .toList();
      await _cacheRecipes(recipes);
      return recipes;
    } on DioException {
      return _getCachedRecipes();
    }
  }

  Future<void> _cacheRecipes(List<Recipe> recipes) async {
    final json = recipes.map((r) => r.toJson()).toList();
    await _prefs.setString(_cacheKey, jsonEncode(json));
  }

  List<Recipe> _getCachedRecipes() {
    final cached = _prefs.getString(_cacheKey);
    if (cached == null) return [];
    final list = jsonDecode(cached) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(Recipe.fromJson)
        .toList();
  }
}
```

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

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokenProvider);

  final String Function() _tokenProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenProvider();
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

## Unit Test Example

```dart
// test/unit/features/recipes/recipe_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

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
        data: {
          'items': [
            {'id': '1', 'title': 'Pasta', 'description': 'Good', 'created_at': '2024-01-01T00:00:00Z'},
          ],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/recipes'),
      ));

      final result = await repository.getAll();

      expect(result, hasLength(1));
      expect(result.first.title, equals('Pasta'));
    });

    test('getById returns single recipe', () async {
      when(mockDio.get<Map<String, dynamic>>('/recipes/1')).thenAnswer(
        (_) async => Response(
          data: {'id': '1', 'title': 'Pasta', 'description': 'Good', 'created_at': '2024-01-01T00:00:00Z'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/recipes/1'),
        ),
      );

      final result = await repository.getById('1');

      expect(result.id, equals('1'));
      expect(result.title, equals('Pasta'));
    });

    test('getById throws NotFoundException for 404', () async {
      when(mockDio.get<Map<String, dynamic>>('/recipes/999')).thenThrow(
        DioException(
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/recipes/999'),
          ),
          requestOptions: RequestOptions(path: '/recipes/999'),
        ),
      );

      expect(
        () => repository.getById('999'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
```

## Anti-Patterns

```dart
// BAD: Creating Dio instance inside repository
class RecipeRepository {
  final _dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
}

// GOOD: Constructor injection
class RecipeRepository {
  RecipeRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;
}

// BAD: Returning raw Response
Future<Response> getAll() async {
  return _dio.get('/recipes');
}

// GOOD: Return typed domain models
Future<List<Recipe>> getAll() async {
  final response = await _dio.get<Map<String, dynamic>>('/recipes');
  return (response.data!['items'] as List).cast<Map<String, dynamic>>().map(Recipe.fromJson).toList();
}

// BAD: Business logic in repository
Future<List<Recipe>> getFiltered(String category) async {
  final all = await getAll();
  return all.where((r) => r.category == category).toList();
}

// GOOD: Filtering is notifier/service responsibility
Future<List<Recipe>> getAll({String? category}) async {
  final params = <String, dynamic>{};
  if (category != null) params['category'] = category;
  final response = await _dio.get<Map<String, dynamic>>('/recipes', queryParameters: params);
  // ...
}

// BAD: Swallowing errors
Future<List<Recipe>> getAll() async {
  try {
    // ...
  } catch (_) {
    return [];
  }
}

// GOOD: Let errors propagate or throw typed exceptions
Future<List<Recipe>> getAll() async {
  try {
    // ...
  } on DioException catch (e) {
    throw _mapException(e);
  }
}
```

## Cross-References

- See `notifier.md` for how notifiers consume repositories
- See `provider.md` for repository provider definitions
- See `model.md` for data classes returned by repositories
- See `screen.md` for how screens trigger repository calls via notifiers
