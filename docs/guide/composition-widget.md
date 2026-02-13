# The Composition Widget

Flutter Compositions provides three widget types that integrate with the reactive system. This page explains how each works and when to use them.

## CompositionWidget

`CompositionWidget` is the primary building block. It looks like a `StatelessWidget` but features a `setup()` method that runs **once** during the widget's lifetime.

```dart
class UserCard extends CompositionWidget {
  const UserCard({super.key, required this.name});

  final String name;

  @override
  Widget Function(BuildContext) setup() {
    // Runs once — declare state, computed values, watchers, and lifecycle hooks here
    final props = widget();
    final greeting = computed(() => 'Hello, ${props.value.name}!');

    return (context) => Text(greeting.value);
  }
}
```

### The Golden Rule of `setup()`

> `setup()` runs only once in the widget's lifecycle (equivalent to `StatefulWidget`'s `initState`).

This means you can safely initialize state, create controllers, and register listeners here without worrying about them being recreated on every widget rebuild.

The **builder function** returned from `setup()` is different — it re-executes whenever any of its reactive dependencies change.

### Rules for `setup()`

1. **Must be synchronous** — it must return a builder function directly. Use `onMounted()` for async initialization.
2. **Runs only once** — state persists across rebuilds via signals.
3. **No conditional composition APIs** — always call `ref()`, `computed()`, `watch()`, etc. in a consistent order (similar to React Hooks rules).
4. **No `BuildContext` access** — access context only in the returned builder function or in `onBuild` callbacks.

## CompositionBuilder

`CompositionBuilder` brings the same reactive experience to inline/one-off usages without creating a dedicated widget class:

```dart
CompositionBuilder(
  setup: () {
    final count = ref(0);

    return (context) => Scaffold(
      body: Center(child: Text('${count.value}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.add),
      ),
    );
  },
)
```

Use `CompositionBuilder` when:
- You need reactive state in a one-off location (e.g., a dialog, a test harness)
- You want to provide dependencies to a subtree without a dedicated widget class

## ComputedBuilder

`ComputedBuilder` wraps a section of UI in its own reactive effect. It observes the refs read inside its builder and only rebuilds **that subtree** when one of them changes:

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);
  final name = ref('Alice');

  return (context) => Column(
    children: [
      // This rebuilds when count OR name changes
      Text('${name.value}: ${count.value}'),

      // This only rebuilds when count changes
      ComputedBuilder(
        builder: (context) => Text('Count only: ${count.value}'),
      ),

      // This never rebuilds (no reactive deps)
      const ExpensiveWidget(),
    ],
  );
}
```

Use `ComputedBuilder` to:
- Isolate hot spots that update frequently from parents that should stay static
- Pair with `computed` values so expensive derivations only re-run when their dependencies change
- Wrap focused fragments of the widget tree for maximum granularity

## How It Works Under the Hood

All three widgets extend `StatelessWidget` with custom `Element` implementations:

| Widget | Element |
|--------|---------|
| `CompositionWidget` | `_CompositionElement extends StatelessElement` |
| `CompositionBuilder` | `_CompositionBuilderElement extends StatelessElement` |
| `ComputedBuilder` | `_ComputedBuilderElement extends StatelessElement` |

This architecture eliminates the need for `State` objects. The custom Elements:

1. **On mount**: create a `SetupContext`, run `setup()`, store the builder, register it as a reactive effect
2. **On dependency change**: the reactive system calls `markNeedsBuild()` directly (no `setState` overhead)
3. **On unmount**: dispose all effects, run `onUnmounted` callbacks, clean up controllers

### Memory and Performance

- **~15-20% less memory** per instance (no `State` object overhead)
- **5-25% lower update latency** (direct `markNeedsBuild()` instead of `setState`)
- **Automatic batching** — multiple ref writes in the same microtask collapse into a single rebuild

## Choosing the Right Widget

| Scenario | Widget |
|----------|--------|
| Reusable component with props | `CompositionWidget` |
| One-off reactive UI (tests, dialogs) | `CompositionBuilder` |
| Isolate a subtree for performance | `ComputedBuilder` |
| Static UI without reactive state | Regular `StatelessWidget` / `const` widgets |

## Next Steps

- [Reactivity Fundamentals](./reactivity-fundamentals.md) — learn `ref`, `computed`, and reactive collections
- [Lifecycle Hooks](./lifecycle-hooks.md) — `onMounted`, `onUnmounted`, `onBuild`
- [Reactive Props](./reactive-props.md) — how to react to prop changes with `widget()`
