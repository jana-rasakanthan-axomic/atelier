# Screen Pattern

Flutter screen/page widgets with GoRouter integration and Riverpod state consumption.

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

When implementing from wireframes/contract specifications:

1. **Define route** (`app_router.dart`) - Add GoRoute entry for the screen
2. **Write screen tests** (`test/widget/features/{feature}/`) - Mock providers, verify widget tree
3. **Implement screen** (`{feature}_screen.dart`) - Build the widget, consume state
4. **Run tests** - Validate widget contract

## GoRouter Route Definition

```dart
// lib/router/app_router.dart
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/recipes',
      name: 'recipes',
      builder: (context, state) => const RecipeListScreen(),
      routes: [
        GoRoute(
          path: ':id',
          name: 'recipe-detail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return RecipeDetailScreen(recipeId: id);
          },
        ),
      ],
    ),
  ],
);
```

## Screen with AsyncValue Pattern Matching

```dart
// lib/features/recipes/presentation/screens/recipe_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    if (recipes.isEmpty) {
      return const Center(child: Text('No recipes yet'));
    }
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
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

## Form Screen Pattern

```dart
// lib/features/recipes/presentation/screens/create_recipe_screen.dart
class CreateRecipeScreen extends ConsumerStatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  ConsumerState<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends ConsumerState<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = CreateRecipeRequest(
      title: _titleController.text,
      description: _descriptionController.text,
    );
    await ref.read(recipeListProvider.notifier).addRecipe(request);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Recipe')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submit,
        child: const Icon(Icons.save),
      ),
    );
  }
}
```

Rules for form screens:
- Use `ConsumerStatefulWidget` when managing `TextEditingController` or `FormState`
- Always dispose controllers in `dispose()`
- Validate form before submitting
- Use `ref.read()` (not `ref.watch()`) for one-shot mutation actions
- Check `mounted` before navigating after async operations

## Widget Test Example

```dart
// test/widget/features/recipes/recipe_list_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('RecipeListScreen', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeListProvider.overrideWith(
              () => _LoadingNotifier(),
            ),
          ],
          child: const MaterialApp(home: RecipeListScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows recipe list when data is loaded', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeListProvider.overrideWith(
              () => _DataNotifier([
                Recipe(id: '1', title: 'Pasta', description: 'Tasty', createdAt: DateTime.now()),
              ]),
            ),
          ],
          child: const MaterialApp(home: RecipeListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pasta'), findsOneWidget);
    });

    testWidgets('shows error view and retry button on failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeListProvider.overrideWith(
              () => _ErrorNotifier(),
            ),
          ],
          child: const MaterialApp(home: RecipeListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
```

## Anti-Patterns

```dart
// BAD: Business logic in screen
onPressed: () async {
  final repo = RecipeRepository(dio: Dio());
  await repo.create(request);
}

// GOOD: Delegate to notifier
onPressed: () => ref.read(recipeListProvider.notifier).addRecipe(request)

// BAD: Navigator.push directly
Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen()));

// GOOD: GoRouter named routes
context.goNamed('recipe-detail', pathParameters: {'id': recipe.id})

// BAD: Stateful widget for reading providers
class MyScreen extends StatefulWidget { ... }

// GOOD: ConsumerWidget for provider reads
class MyScreen extends ConsumerWidget { ... }

// BAD: ref.watch() for mutation actions
onPressed: () => ref.watch(provider.notifier).doAction()

// GOOD: ref.read() for one-shot actions
onPressed: () => ref.read(provider.notifier).doAction()
```

## Cross-References

- See `notifier.md` for state management patterns
- See `provider.md` for provider definitions and overrides
- See `model.md` for data classes used in screens
- See `../../flutter-dart.md` for full profile configuration
