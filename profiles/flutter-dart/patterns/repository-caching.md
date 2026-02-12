# Repository with Local Cache Pattern

Extracted from repository.md. Shows how to add offline-first caching with SharedPreferences fallback.

## Pattern

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

## Key Rules

- Try network first, fall back to cache on `DioException`
- Cache successful responses automatically
- Return empty list when no cache exists (not null)
- Use a constant cache key per entity type
- Accept `SharedPreferences` via constructor injection (testable)
