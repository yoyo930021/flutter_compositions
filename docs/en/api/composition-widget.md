# CompositionWidget

Base widget class for building reactive Flutter widgets with composition patterns.

## Overview

`CompositionWidget` is the foundation of Flutter Compositions. It replaces `StatefulWidget` and provides a single `setup()` method where you define reactive state, effects, and return a builder function.

## Basic Usage

```dart
class CounterPage extends CompositionWidget {
  const CounterPage({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    return (context) => Text('Count: ${count.value}');
  }
}
```

## Setup Method

The `setup()` method is called once during widget initialization and must return a builder function.

### Signature

```dart
abstract class CompositionWidget extends StatefulWidget {
  Widget Function(BuildContext) setup();
}
```

### Setup Execution

- Called **once** in `initState()`
- Cannot be `async`
- No access to `BuildContext` (use builder for context)
- All composition APIs must be called at setup time

## With Props

Props must be accessed reactively using `widget()`.

```dart
class UserCard extends CompositionWidget {
  const UserCard({super.key, required this.userId});

  final String userId;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget(); // Reactive access to this widget

    final user = computed(() => fetchUser(props.value.userId));

    return (context) => Text('User: ${user.value}');
  }
}
```

## Lifecycle

Use lifecycle hooks inside `setup()`:

```dart
@override
Widget Function(BuildContext) setup() {
  onMounted(() {
    print('Widget mounted');
  });

  onUnmounted(() {
    print('Widget will unmount');
  });

  onBuild(() {
    print('Builder executed');
  });

  return (context) => Container();
}
```

## State Management

All mutable state must use `ref()`:

```dart
class TodoList extends CompositionWidget {
  const TodoList({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final todos = ref(<String>[]);
    final newTodo = ref('');

    void addTodo() {
      if (newTodo.value.isNotEmpty) {
        todos.value = [...todos.value, newTodo.value];
        newTodo.value = '';
      }
    }

    return (context) => Column(
      children: [
        TextField(
          onChanged: (value) => newTodo.value = value,
          onSubmitted: (_) => addTodo(),
        ),
        ...todos.value.map((todo) => Text(todo)),
      ],
    );
  }
}
```

## With Composables

Extract reusable logic with composables:

```dart
class SearchPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (searchController, searchText, _) = useTextEditingController();
    final scrollController = useScrollController();

    final results = computed(() => performSearch(searchText.value));

    return (context) => ListView.builder(
      controller: scrollController.value,
      itemCount: results.value.length,
      itemBuilder: (context, index) => Text(results.value[index]),
    );
  }
}
```

## Dependency Injection

Use `provide` and `inject` for dependency injection:

```dart
// Provider
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(AppTheme.light());
    provide(themeKey, theme);

    return (context) => MaterialApp(home: HomePage());
  }
}

// Consumer
class ThemedWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = inject(themeKey);

    return (context) => Container(
      color: theme.value.backgroundColor,
    );
  }
}
```

## Rules and Constraints

### Setup Cannot Be Async

```dart
// ❌ Bad: Async setup
@override
Future<Widget Function(BuildContext)> setup() async {
  await loadData();
  return (context) => Text('Done');
}

// ✅ Good: Use onMounted for async
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);

  onMounted(() async {
    data.value = await loadData();
  });

  return (context) => Text(data.value ?? 'Loading...');
}
```

### Fields Must Be Final

```dart
// ❌ Bad: Mutable field
class MyWidget extends CompositionWidget {
  int count = 0; // Don't do this!
}

// ✅ Good: Use ref for mutable state
class MyWidget extends CompositionWidget {
  final int initialCount;

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(initialCount);
    return (context) => Text('${count.value}');
  }
}
```

### Composition APIs Must Be Called in Setup

```dart
// ❌ Bad: Conditional composition API call
@override
Widget Function(BuildContext) setup() {
  if (someCondition) {
    final count = ref(0); // Don't do this!
  }

  return (context) => Container();
}

// ✅ Good: Always call at top level
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);
  final enabled = ref(someCondition);

  return (context) => enabled.value
    ? Text('${count.value}')
    : Container();
}
```

## Performance

- Setup runs **once**, not on every rebuild
- Builder re-runs only when tracked dependencies change
- Use `computed()` for derived values to avoid recalculation

## Hot Reload Behavior

- Setup does **not** re-run on hot reload
- State (refs) is preserved
- Computed values and watchers remain active

## See Also

- [setup()](./lifecycle.md#setup) - Setup lifecycle
- [widget()](./reactivity.md#widget) - Reactive props
- [CompositionBuilder](./composition-builder.md) - Functional API
- [Built-in Composables](./composables/) - Reusable composition functions
