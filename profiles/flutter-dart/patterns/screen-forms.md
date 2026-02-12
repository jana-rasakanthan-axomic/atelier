# Form Screen Pattern

Form handling in Flutter screens using `ConsumerStatefulWidget` with Riverpod.

> Extracted from [screen.md](screen.md). See that file for general screen patterns.

## Key Rules

- Use `ConsumerStatefulWidget` when managing `TextEditingController` or `FormState`
- Always dispose controllers in `dispose()`
- Validate form before submitting
- Use `ref.read()` (not `ref.watch()`) for one-shot mutation actions
- Check `mounted` before navigating after async operations

## Form Screen Example

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
