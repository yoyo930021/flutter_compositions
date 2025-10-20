import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

/// Demonstrates using CompositionBuilder for inline reactive widgets.
class CompositionBuilderDemo extends StatelessWidget {
  const CompositionBuilderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CompositionBuilder Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _BasicCounterSection(),
          SizedBox(height: 16),
          _ExpandableCardsSection(),
          SizedBox(height: 16),
          _TodoListSection(),
        ],
      ),
    );
  }
}

/// Example 1: Basic counter without defining a class
class _BasicCounterSection extends StatelessWidget {
  const _BasicCounterSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Counter (Inline)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Using CompositionBuilder without defining a class',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Use CompositionBuilder inline - no class definition needed!
            CompositionBuilder(
              setup: () {
                final count = ref(0);
                final isEven = computed(() => count.value.isEven);

                return (context) => Row(
                  children: [
                    Text(
                      'Count: ${count.value}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isEven.value ? '(Even)' : '(Odd)',
                      style: TextStyle(
                        color: isEven.value ? Colors.green : Colors.orange,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => count.value--,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => count.value++,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 2: Expandable cards in a list
class _ExpandableCardsSection extends StatelessWidget {
  const _ExpandableCardsSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expandable Cards',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Each card has independent state managed inline',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...List.generate(
              3,
              (index) => CompositionBuilder(
                setup: () {
                  final expanded = ref(false);

                  return (context) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text('Item ${index + 1}'),
                          subtitle: Text(
                            expanded.value
                                ? 'Tap to collapse'
                                : 'Tap to expand',
                          ),
                          trailing: Icon(
                            expanded.value
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                          onTap: () => expanded.value = !expanded.value,
                        ),
                        if (expanded.value)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'This is the expanded content for item ${index + 1}. '
                              'Each card maintains its own independent state!',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 3: Todo list with inline state management
class _TodoListSection extends StatelessWidget {
  const _TodoListSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CompositionBuilder(
          setup: () {
            final todos = ref<List<_Todo>>([
              _Todo(
                id: 1,
                title: 'Learn Flutter Compositions',
                completed: true,
              ),
              _Todo(id: 2, title: 'Build an awesome app', completed: false),
              _Todo(id: 3, title: 'Share with the community', completed: false),
            ]);

            final (newTodoController, newTodoText, newTodoValue) =
                useTextEditingController();

            final completedCount = computed(
              () => todos.value.where((t) => t.completed).length,
            );

            void addTodo() {
              if (newTodoText.value.trim().isEmpty) return;

              todos.value = [
                ...todos.value,
                _Todo(
                  id: DateTime.now().millisecondsSinceEpoch,
                  title: newTodoText.value,
                  completed: false,
                ),
              ];

              newTodoValue.value = TextEditingValue.empty;
            }

            void toggleTodo(int id) {
              todos.value = todos.value.map((todo) {
                if (todo.id == id) {
                  return _Todo(
                    id: todo.id,
                    title: todo.title,
                    completed: !todo.completed,
                  );
                }
                return todo;
              }).toList();
            }

            void removeTodo(int id) {
              todos.value = todos.value.where((t) => t.id != id).toList();
            }

            return (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Todo List (Inline State)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Complex state management without defining a class',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Completed: ${completedCount.value}/${todos.value.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newTodoController,
                        decoration: const InputDecoration(
                          hintText: 'Add a new todo',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => addTodo(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: addTodo,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...todos.value.map(
                  (todo) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Checkbox(
                        value: todo.completed,
                        onChanged: (_) => toggleTodo(todo.id),
                      ),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          decoration: todo.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => removeTodo(todo.id),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Todo {
  const _Todo({required this.id, required this.title, required this.completed});

  final int id;
  final String title;
  final bool completed;
}
