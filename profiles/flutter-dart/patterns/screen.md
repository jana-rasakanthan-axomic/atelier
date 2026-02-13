# Screen Pattern

Flutter screen/page widgets with GoRouter integration and Riverpod state consumption.

> See [screen-forms.md](screen-forms.md) for form screen patterns.

## Location

- `lib/features/{feature}/presentation/screens/{feature}_screen.dart` - Screen widgets
- `lib/features/{feature}/presentation/widgets/{feature}_card.dart` - Extracted sub-widgets
- `lib/router/app_router.dart` - GoRouter route definitions

## Key Rules

1. **Contract-first**: Start with the screen layout and user interactions defined in wireframes/specs
2. **ConsumerWidget for state**: Use `ConsumerWidget` (not `StatefulWidget`) when reading Riverpod providers
3. **Pattern matching on AsyncValue**: Use Dart 3 switch expressions for loading/error/data states
4. **Extract sub-widgets**: Keep `build()` methods under 30 lines by extracting private widget classes
5. **No business logic**: Screens delegate all logic to notifiers via `ref.read()`
6. **GoRouter for navigation**: Define routes in `app_router.dart`, never use `Navigator.push()` directly

## Contract-First Workflow

1. **Define route** (`app_router.dart`) - Add GoRoute entry
2. **Write screen tests** (`test/widget/features/{feature}/`) - Mock providers, verify widget tree
3. **Implement screen** (`{feature}_screen.dart`) - Build the widget, consume state
4. **Run tests** - Validate widget contract

## GoRouter Route Definition

```dart
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/recipes', name: 'recipes',
      builder: (context, state) => const RecipeListScreen(),
      routes: [
        GoRoute(
          path: ':id', name: 'recipe-detail',
          builder: (context, state) => RecipeDetailScreen(recipeId: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);
```

## Screen with AsyncValue Pattern Matching

```dart
class RecipeListScreen extends ConsumerWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: switch (state) {
        AsyncData(:final value) => _RecipeList(
            recipes: value,
            onTap: (id) => context.goNamed('recipe-detail', pathParameters: {'id': id}),
          ),
        AsyncError(:final error) => _ErrorView(
            error: error,
            onRetry: () => ref.invalidate(recipeListProvider),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed('create-recipe'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## Extracted Sub-Widgets

```dart
class _RecipeList extends StatelessWidget {
  const _RecipeList({required this.recipes, required this.onTap});
  final List<Recipe> recipes;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const Center(child: Text('No recipes yet'));
    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return ListTile(
          title: Text(recipe.title),
          subtitle: Text(recipe.description),
          onTap: () => onTap(recipe.id),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
```

## Widget Test Example

```dart
void main() {
  group('RecipeListScreen', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [recipeListProvider.overrideWith(() => _LoadingNotifier())],
          child: const MaterialApp(home: RecipeListScreen()),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows recipe list when data is loaded', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeListProvider.overrideWith(() => _DataNotifier([
              Recipe(id: '1', title: 'Pasta', description: 'Tasty', createdAt: DateTime.now()),
            ])),
          ],
          child: const MaterialApp(home: RecipeListScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pasta'), findsOneWidget);
    });
  });
}
```

## Anti-Patterns

```dart
// BAD: Business logic in screen
onPressed: () async { final repo = RecipeRepository(dio: Dio()); await repo.create(request); }
// GOOD: Delegate to notifier
onPressed: () => ref.read(recipeListProvider.notifier).addRecipe(request)

// BAD: Navigator.push directly
Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen()));
// GOOD: GoRouter named routes
context.goNamed('recipe-detail', pathParameters: {'id': recipe.id})

// BAD: StatefulWidget for provider reads    // GOOD: ConsumerWidget
// BAD: ref.watch() for mutation actions     // GOOD: ref.read() for one-shot actions
```

## Cross-References

- See `notifier.md` for state management patterns
- See `provider.md` for provider definitions and overrides
- See `model.md` for data classes used in screens
- See `../../flutter-dart.md` for full profile configuration
