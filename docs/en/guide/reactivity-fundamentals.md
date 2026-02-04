# Reactivity Fundamentals

Understanding Flutter Compositions' reactivity system is key to building efficient, maintainable applications. This guide explains the core reactive primitives and how they work together.

## Overview

Flutter Compositions uses a fine-grained reactivity system powered by [`alien_signals`](https://pub.dev/packages/alien_signals). Unlike Flutter's `setState` which rebuilds entire widget subtrees, this system updates only the specific parts of your UI that depend on changed data.

## The Three Pillars of Reactivity

### 1. Ref - Reactive State

`ref()` creates reactive state that can be read and written. When you modify a ref's value, all computations and UI components that depend on it automatically update.

```dart
// Create a ref
final count = ref(0);

// Read the value
print(count.value); // 0

// Write the value (triggers reactivity)
count.value++;
print(count.value); // 1
```

**Key Points**:
- Always access state through `.value`
- Writes trigger automatic updates
- Refs can hold any type: primitives, objects, lists, etc.

### 2. Computed - Derived State

`computed()` creates values derived from other reactive state. They automatically update when their dependencies change and are cached until dependencies change.

```dart
final count = ref(0);
final doubled = computed(() => count.value * 2);

print(doubled.value); // 0

count.value = 5;
print(doubled.value); // 10
```

**Key Points**:
- Lazy evaluation - only computes when accessed
- Automatic dependency tracking
- Cached results for performance
- Read-only (use `writableComputed` for bidirectional)

### 3. Watch - Side Effects

`watch()` and `watchEffect()` run side effects when reactive dependencies change.

#### watch()

Explicitly specify what to watch:

```dart
final count = ref(0);

watch(
  () => count.value,  // Getter: what to watch
  (newValue, oldValue) {  // Callback: what to do
    print('Count changed: $oldValue → $newValue');
  },
);

count.value = 1;  // Prints: "Count changed: 0 → 1"
```

#### watchEffect()

Automatically track all dependencies:

```dart
final firstName = ref('John');
final lastName = ref('Doe');

watchEffect(() {
  // Automatically tracks both refs
  print('Full name: ${firstName.value} ${lastName.value}');
});

firstName.value = 'Jane';  // Prints: "Full name: Jane Doe"
lastName.value = 'Smith';  // Prints: "Full name: Jane Smith"
```

**When to use which**:
- Use `watch()` when you need access to old and new values
- Use `watchEffect()` for simpler side effects
- Use `watch()` when you want explicit control over dependencies

## Reactivity in Action

### Example: Todo List

```dart
class TodoList extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // State: list of todos
    final todos = ref(<String>['Buy milk', 'Walk dog']);

    // State: filter
    final filter = ref('all'); // 'all', 'completed', 'active'

    // State: completion status
    final completed = ref(<bool>[false, false]);

    // Computed: filtered todos
    final filteredTodos = computed(() {
      if (filter.value == 'all') {
        return List.generate(
          todos.value.length,
          (i) => todos.value[i],
        );
      } else if (filter.value == 'completed') {
        return [
          for (var i = 0; i < todos.value.length; i++)
            if (completed.value[i]) todos.value[i],
        ];
      } else { // 'active'
        return [
          for (var i = 0; i < todos.value.length; i++)
            if (!completed.value[i]) todos.value[i],
        ];
      }
    });

    // Computed: stats
    final totalCount = computed(() => todos.value.length);
    final completedCount = computed(
      () => completed.value.where((c) => c).length,
    );

    // Side effect: log changes
    watch(
      () => completedCount.value,
      (newCount, oldCount) {
        print('Completed: $oldCount → $newCount');
      },
    );

    // Functions
    void addTodo(String todo) {
      todos.value = [...todos.value, todo];
      completed.value = [...completed.value, false];
    }

    void toggleTodo(int index) {
      final newCompleted = [...completed.value];
      newCompleted[index] = !newCompleted[index];
      completed.value = newCompleted;
    }

    return (context) => Column(
      children: [
        // Add todo input
        TextField(
          onSubmitted: addTodo,
          decoration: InputDecoration(hintText: 'Add todo...'),
        ),

        // Filter buttons
        Row(
          children: [
            for (final f in ['all', 'active', 'completed'])
              ElevatedButton(
                onPressed: () => filter.value = f,
                child: Text(f),
              ),
          ],
        ),

        // Stats
        Text('Total: ${totalCount.value}, Completed: ${completedCount.value}'),

        // Todo list
        for (var i = 0; i < filteredTodos.value.length; i++)
          ListTile(
            title: Text(filteredTodos.value[i]),
            leading: Checkbox(
              value: completed.value[todos.value.indexOf(filteredTodos.value[i])],
              onChanged: (_) => toggleTodo(
                todos.value.indexOf(filteredTodos.value[i]),
              ),
            ),
          ),
      ],
    );
  }
}
```

## Reactive Collections

When working with collections (Lists, Maps, Sets), you must create new instances to trigger reactivity:

```dart
final items = ref(<String>[]);

// ❌ This won't trigger updates
items.value.add('new item');

// ✅ Create a new list
items.value = [...items.value, 'new item'];

// ✅ Or use spread operator
items.value = [...items.value];
```

## Common Patterns

### Pattern 1: Input Binding

```dart
final name = ref('');

return (context) => TextField(
  onChanged: (value) => name.value = value,
  controller: TextEditingController(text: name.value),
);

// Better: use useTextEditingController
final (controller, text, _) = useTextEditingController();
return (context) => TextField(controller: controller);
```

### Pattern 2: Conditional Rendering

```dart
final isLoggedIn = ref(false);

return (context) => isLoggedIn.value
    ? Text('Welcome back!')
    : ElevatedButton(
        onPressed: () => isLoggedIn.value = true,
        child: Text('Login'),
      );
```

### Pattern 3: List Rendering

```dart
final items = ref(['Apple', 'Banana', 'Cherry']);

return (context) => Column(
  children: [
    for (final item in items.value)
      ListTile(title: Text(item)),
  ],
);
```

### Pattern 4: Async Data

```dart
final user = ref<User?>(null);
final loading = ref(false);

onMounted(() async {
  loading.value = true;
  user.value = await fetchUser();
  loading.value = false;
});

return (context) {
  if (loading.value) return CircularProgressIndicator();
  if (user.value == null) return Text('No user');
  return Text('Hello, ${user.value!.name}');
};

// Better: use useFuture or useAsyncData
final userData = useFuture(() => fetchUser());
return (context) => switch (userData.value) {
  AsyncLoading() => CircularProgressIndicator(),
  AsyncData(:final value) => Text('Hello, ${value.name}'),
  _ => Text('No user'),
};
```

## Performance Tips

### 1. Keep Computed Functions Pure

```dart
// ✅ Good - pure function
final greeting = computed(() => 'Hello, ${name.value}');

// ❌ Bad - side effects
final greeting = computed(() {
  print('Computing...'); // Side effect!
  return 'Hello, ${name.value}';
});
```

### 2. Minimize Dependencies in Builder

```dart
// ❌ Rebuilds on any count change
return (context) => Column(
  children: [
    Text('Count: ${count.value}'),
    ExpensiveWidget(), // Rebuilds unnecessarily
  ],
);

// ✅ Extract to separate widget
return (context) => Column(
  children: [
    Text('Count: ${count.value}'),
    const ExpensiveWidget(), // Doesn't rebuild
  ],
);
```

### 3. Use Computed for Expensive Calculations

```dart
// ❌ Calculates on every access
final sum = items.value.fold(0, (a, b) => a + b);

// ✅ Cached until items changes
final sum = computed(() => items.value.fold(0, (a, b) => a + b));
```

## Debugging Reactivity

### Check Dependencies

```dart
// Add logging to see when computed runs
final doubled = computed(() {
  print('Computing doubled');
  return count.value * 2;
});
```

### Watch All Changes

```dart
watchEffect(() {
  print('Count: ${count.value}');
  print('Name: ${name.value}');
  // Prints whenever count OR name changes
});
```

## Common Pitfalls

### Pitfall 1: Forgetting `.value`

```dart
// ❌ Compares Ref objects, not values
if (count == 5) { /* never true */ }

// ✅ Compare values
if (count.value == 5) { /* works */ }
```

### Pitfall 2: Reading Props Directly

```dart
// ❌ Captures initial prop value only
final greeting = computed(() => 'Hello, $name');

// ✅ Reactive to prop changes
final props = widget();
final greeting = computed(() => 'Hello, ${props.value.name}');
```

**Tip: Use Dart's Destructuring Pattern for Props**

When working with multiple props, you can use Dart's destructuring pattern in the builder function to extract props cleanly and ensure reactive access:

```dart
class UserCard extends CompositionWidget {
  final String userId;
  final String displayName;
  final bool isActive;

  const UserCard({
    super.key,
    required this.userId,
    required this.displayName,
    required this.isActive,
  });

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();

    return (context) {
      // Destructure props for cleaner access
      final UserCard(:userId, :displayName, :isActive) = props.value;

      return ListTile(
        title: Text(displayName),
        subtitle: Text('ID: $userId'),
        trailing: Icon(
          isActive ? Icons.check_circle : Icons.cancel,
          color: isActive ? Colors.green : Colors.grey,
        ),
      );
    };
  }
}
```

This pattern ensures that:
- All prop access goes through `props.value`, maintaining reactivity
- Props are clearly declared at the top of the builder function
- The code is more readable when using multiple props

### Pitfall 3: Mutating Collections

```dart
// ❌ Mutation doesn't trigger update
items.value.add('new');

// ✅ Create new collection
items.value = [...items.value, 'new'];
```

## Next Steps

- Learn about [Built-in Composables](./built-in-composables.md) for common patterns
- Explore [Async Operations](./async-operations.md) for handling futures and streams
- Read [Reactivity In-Depth](../internals/reactivity-in-depth.md) for advanced concepts
