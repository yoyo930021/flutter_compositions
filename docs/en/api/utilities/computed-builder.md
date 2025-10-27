# ComputedBuilder

A widget that creates a fine-grained reactive scope for its child.

## Overview

`ComputedBuilder` is a widget that creates an isolated reactive scope, allowing only specific parts of your widget tree to rebuild when reactive dependencies change. This is similar to Vue's fine-grained reactivity or Solid.js's reactive primitives.

Unlike the standard `CompositionWidget` builder which rebuilds the entire widget tree when any reactive dependency changes, `ComputedBuilder` only rebuilds itself and its children when its specific dependencies change.

## Signature

```dart
class ComputedBuilder extends StatefulWidget {
  const ComputedBuilder({
    required this.builder,
    Key? key,
  });

  final Widget Function() builder;
}
```

### Parameters

- `builder` - Function that creates the widget. Runs inside a reactive effect and automatically tracks dependencies.

### Returns

A `StatefulWidget` that rebuilds only when its reactive dependencies change.

## Basic Usage

```dart
class Counter extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count1 = ref(0);
    final count2 = ref(0);

    return (context) => Column(
      children: [
        // Only this text rebuilds when count1 changes
        ComputedBuilder(
          builder: () => Text('Count1: ${count1.value}'),
        ),

        // Only this text rebuilds when count2 changes
        ComputedBuilder(
          builder: () => Text('Count2: ${count2.value}'),
        ),

        // Static widgets never rebuild
        const Text('This is static'),

        ElevatedButton(
          onPressed: () => count1.value++,
          child: const Text('Increment Count1'),
        ),
      ],
    );
  }
}
```

## Performance Benefits

### Without ComputedBuilder

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  return (context) => Column(
    children: [
      Text('Count: ${count.value}'),
      const ExpensiveStaticWidget(),  // Rebuilds unnecessarily!
      const AnotherExpensiveWidget(), // Also rebuilds unnecessarily!
    ],
  );
}
```

Every time `count` changes, the entire `Column` and all children rebuild.

### With ComputedBuilder

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  return (context) => Column(
    children: [
      ComputedBuilder(
        builder: () => Text('Count: ${count.value}'),
      ),
      const ExpensiveStaticWidget(),  // Never rebuilds!
      const AnotherExpensiveWidget(), // Never rebuilds!
    ],
  );
}
```

Only the `Text` inside `ComputedBuilder` rebuilds when `count` changes.

## Use Cases

### 1. High-Frequency Updates

When you have values that update frequently (like progress bars or animations):

```dart
@override
Widget Function(BuildContext) setup() {
  final progress = ref(0.0);

  // Updates 60 times per second
  onMounted(() {
    Timer.periodic(const Duration(milliseconds: 16), (_) {
      progress.value = (progress.value + 0.01) % 1.0;
    });
  });

  return (context) => Column(
    children: [
      // Only this rebuilds at 60fps
      ComputedBuilder(
        builder: () => LinearProgressIndicator(value: progress.value),
      ),

      // Static content never rebuilds
      const Text('Loading...'),
      const Divider(),
      const Text('Please wait...'),
    ],
  );
}
```

### 2. List Items with Independent State

Each list item can have its own reactive scope:

```dart
class TodoItem {
  final String title;
  final Ref<bool> completed;

  TodoItem(this.title) : completed = ref(false);
}

@override
Widget Function(BuildContext) setup() {
  final items = ref<List<TodoItem>>([
    TodoItem('Task 1'),
    TodoItem('Task 2'),
    TodoItem('Task 3'),
  ]);

  return (context) => ListView.builder(
    itemCount: items.value.length,
    itemBuilder: (context, index) {
      final item = items.value[index];

      return ListTile(
        // Only this checkbox rebuilds when this item's state changes
        leading: ComputedBuilder(
          builder: () => Checkbox(
            value: item.completed.value,
            onChanged: (value) => item.completed.value = value ?? false,
          ),
        ),
        title: Text(item.title),
        // Other items in the list don't rebuild
      );
    },
  );
}
```

### 3. Complex Computed Values

Isolate expensive computations:

```dart
@override
Widget Function(BuildContext) setup() {
  final items = ref<List<Item>>([...]);
  final filter = ref('');

  final filteredItems = computed(() {
    final query = filter.value.toLowerCase();
    if (query.isEmpty) return items.value;

    return items.value.where((item) {
      return item.name.toLowerCase().contains(query);
    }).toList();
  });

  return (context) => Column(
    children: [
      TextField(
        onChanged: (value) => filter.value = value,
      ),

      // Only this text rebuilds when filter or items change
      ComputedBuilder(
        builder: () => Text('Found: ${filteredItems.value.length} items'),
      ),

      // Expensive widget tree never rebuilds
      const ExpensiveFilterPanel(),
      const ExpensiveChartWidget(),
    ],
  );
}
```

### 4. Form Validation

Show validation errors reactively:

```dart
@override
Widget Function(BuildContext) setup() {
  final email = ref('');
  final password = ref('');

  final emailError = computed(() {
    if (email.value.isEmpty) return null;
    if (!email.value.contains('@')) return 'Invalid email';
    return null;
  });

  final passwordError = computed(() {
    if (password.value.isEmpty) return null;
    if (password.value.length < 8) return 'Password too short';
    return null;
  });

  return (context) => Column(
    children: [
      TextField(
        onChanged: (value) => email.value = value,
        decoration: const InputDecoration(labelText: 'Email'),
      ),

      // Only rebuilds when email error changes
      ComputedBuilder(
        builder: () {
          final error = emailError.value;
          return error != null
              ? Text(error, style: const TextStyle(color: Colors.red))
              : const SizedBox.shrink();
        },
      ),

      TextField(
        onChanged: (value) => password.value = value,
        decoration: const InputDecoration(labelText: 'Password'),
        obscureText: true,
      ),

      // Only rebuilds when password error changes
      ComputedBuilder(
        builder: () {
          final error = passwordError.value;
          return error != null
              ? Text(error, style: const TextStyle(color: Colors.red))
              : const SizedBox.shrink();
        },
      ),
    ],
  );
}
```

### 5. Conditional Rendering

Optimize conditional widgets:

```dart
@override
Widget Function(BuildContext) setup() {
  final isLoggedIn = ref(false);
  final userData = ref<User?>(null);

  return (context) => Scaffold(
    appBar: AppBar(title: const Text('My App')),
    body: ComputedBuilder(
      builder: () {
        if (!isLoggedIn.value) {
          return const LoginScreen();
        }

        if (userData.value == null) {
          return const CircularProgressIndicator();
        }

        return UserDashboard(user: userData.value!);
      },
    ),
    // AppBar and other widgets never rebuild
  );
}
```

## How It Works

`ComputedBuilder` creates its own reactive effect that only tracks the signals used within its `builder` function. When those signals change:

1. The effect detects the change
2. The `builder` function re-runs
3. Only the `ComputedBuilder` widget calls `setState()`
4. Only the widget tree inside `ComputedBuilder` rebuilds
5. Parent and sibling widgets remain unchanged

```dart
// Internal behavior (simplified)
class _ComputedBuilderState extends State<ComputedBuilder> {
  Effect? _effect;

  @override
  void initState() {
    super.initState();

    // Create reactive effect
    _effect = effect(() {
      final newWidget = widget.builder();

      // Only rebuild this widget
      if (mounted) {
        setState(() {
          _cachedWidget = newWidget;
        });
      }
    });
  }
}
```

## Best Practices

### Isolate Frequent Updates

```dart
// Good - Isolate high-frequency updates
return Column(
  children: [
    ComputedBuilder(
      builder: () => Text('FPS: ${fps.value}'),
    ),
    const ExpensiveChart(),
  ],
);

// Avoid - Everything rebuilds frequently
return Column(
  children: [
    Text('FPS: ${fps.value}'),
    const ExpensiveChart(), // Rebuilds unnecessarily
  ],
);
```

### Minimize Scope

```dart
// Good - Minimal scope
return Column(
  children: [
    const Header(),
    ComputedBuilder(
      builder: () => Text('Count: ${count.value}'),
    ),
    const Footer(),
  ],
);

// Avoid - Too broad scope
return ComputedBuilder(
  builder: () => Column(
    children: [
      const Header(),  // In scope but doesn't need to be
      Text('Count: ${count.value}'),
      const Footer(),  // In scope but doesn't need to be
    ],
  ),
);
```

### Combine with Computed Values

```dart
// Good - Pre-compute outside, use in builder
final displayText = computed(() {
  final items = itemList.value;
  return 'Total: ${items.length} items';
});

return ComputedBuilder(
  builder: () => Text(displayText.value),
);

// Also Good - Compute inside builder
return ComputedBuilder(
  builder: () {
    final items = itemList.value;
    return Text('Total: ${items.length} items');
  },
);
```

### Avoid Side Effects

```dart
// Bad - Side effects in builder
ComputedBuilder(
  builder: () {
    print('Building...'); // Don't do this!
    api.trackView(count.value); // Don't do this!
    return Text('Count: ${count.value}');
  },
);

// Good - Use watch for side effects
watch(() => count.value, (value, _) {
  print('Count changed to $value');
  api.trackView(value);
});

return ComputedBuilder(
  builder: () => Text('Count: ${count.value}'),
);
```

### Use for Independent State

```dart
// Good - Independent reactive scopes
return Row(
  children: [
    ComputedBuilder(
      builder: () => Text('Left: ${leftCount.value}'),
    ),
    ComputedBuilder(
      builder: () => Text('Right: ${rightCount.value}'),
    ),
  ],
);

// Avoid - Single scope for independent values
return ComputedBuilder(
  builder: () => Row(
    children: [
      Text('Left: ${leftCount.value}'),
      Text('Right: ${rightCount.value}'),
    ],
  ),
);
// Both texts rebuild when either count changes
```

## Performance Comparison

### Scenario: List of 1000 Items

**Without ComputedBuilder:**

```dart
// All 1000 items rebuild on any change
return ListView.builder(
  itemCount: items.value.length,
  itemBuilder: (context, index) {
    final item = items.value[index];
    return ListTile(
      title: Text(item.name),
      trailing: Text('${item.count.value}'),
    );
  },
);
// Changing one item's count rebuilds entire list
```

**With ComputedBuilder:**

```dart
// Only the changed item rebuilds
return ListView.builder(
  itemCount: items.value.length,
  itemBuilder: (context, index) {
    final item = items.value[index];
    return ListTile(
      title: Text(item.name),
      trailing: ComputedBuilder(
        builder: () => Text('${item.count.value}'),
      ),
    );
  },
);
// Only one Text widget rebuilds
```

**Result:** 1000x fewer widget rebuilds!

## Common Patterns

### Loading Indicator

```dart
return Stack(
  children: [
    const MainContent(),

    // Only this rebuilds when loading state changes
    ComputedBuilder(
      builder: () {
        if (!isLoading.value) return const SizedBox.shrink();

        return Container(
          color: Colors.black26,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    ),
  ],
);
```

### Conditional Widget

```dart
return Column(
  children: [
    const Header(),

    ComputedBuilder(
      builder: () {
        return showDetails.value
            ? const DetailedView()
            : const SummaryView();
      },
    ),

    const Footer(),
  ],
);
```

### Theme-Based Styling

```dart
final isDark = ref(false);

return ComputedBuilder(
  builder: () => Container(
    color: isDark.value ? Colors.black : Colors.white,
    child: Text(
      'Hello',
      style: TextStyle(
        color: isDark.value ? Colors.white : Colors.black,
      ),
    ),
  ),
);
```

## Comparison with Other Solutions

### vs. StatefulWidget

```dart
// StatefulWidget - Verbose, more boilerplate
class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Text('Count: $count');
  }
}

// ComputedBuilder - Concise, reactive
final count = ref(0);
return ComputedBuilder(
  builder: () => Text('Count: ${count.value}'),
);
```

### vs. StreamBuilder

```dart
// StreamBuilder - Requires stream setup
final controller = StreamController<int>();
return StreamBuilder<int>(
  stream: controller.stream,
  initialData: 0,
  builder: (context, snapshot) {
    return Text('Count: ${snapshot.data}');
  },
);

// ComputedBuilder - Direct reactive value
final count = ref(0);
return ComputedBuilder(
  builder: () => Text('Count: ${count.value}'),
);
```

### vs. ValueListenableBuilder

```dart
// ValueListenableBuilder - Limited to ValueNotifier
final count = ValueNotifier<int>(0);
return ValueListenableBuilder<int>(
  valueListenable: count,
  builder: (context, value, child) {
    return Text('Count: $value');
  },
);

// ComputedBuilder - Works with any reactive value
final count = ref(0);
final doubled = computed(() => count.value * 2);
return ComputedBuilder(
  builder: () => Text('Doubled: ${doubled.value}'),
);
```

## See Also

- [CompositionWidget](../composition-widget.md) - Main reactive widget
- [computed](../reactivity.md#computed) - Computed values
- [ref](../reactivity.md#ref) - Reactive references
- [watch](../watch.md) - Side effects and watchers
- [Fine-grained Reactivity](../../guide/reactivity.md) - Reactivity concepts
