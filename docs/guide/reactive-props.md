# Reactive Props

Since `setup()` runs only once, accessing widget properties directly captures their **initial values** only. To react to prop changes from a parent widget, you must use the `widget()` API.

## The Problem

```dart
class UserCard extends CompositionWidget {
  const UserCard({super.key, required this.name});
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    // ❌ WRONG: captures the initial value of `name` — NOT reactive
    final greeting = computed(() => 'Hello, $name!');

    return (context) => Text(greeting.value);
  }
}
```

When the parent rebuilds and passes a new `name`, the `greeting` computed above will **not** update because `name` was read once during `setup()`.

## The Solution: `widget()`

`widget()` returns a reactive `ComputedRef` that always represents the **latest** widget instance. When the parent passes new props, this ref triggers an update:

```dart
class UserCard extends CompositionWidget {
  const UserCard({super.key, required this.name});
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    // ✅ CORRECT: reactive prop access
    final props = widget();
    final greeting = computed(() => 'Hello, ${props.value.name}!');

    return (context) => Text(greeting.value);
  }
}
```

## Watching Prop Changes

You can use `watch()` to run side effects when specific props change:

```dart
@override
Widget Function(BuildContext) setup() {
  final props = widget();

  watch(() => props.value.userId, (newId, oldId) {
    print('User changed from $oldId to $newId');
    cache.loadAvatar(newId);
  });

  return (context) => Text('User: ${props.value.userId}');
}
```

## Props Destructuring Pattern

When working with multiple props, use Dart's destructuring pattern in the builder function for cleaner access:

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

This pattern ensures:
- All prop access goes through `props.value`, maintaining reactivity
- Props are clearly declared at the top of the builder function
- Code is more readable when using multiple props

## How It Works

Under the hood, `widget()` creates a `_widgetSignal` — a reactive signal that the framework updates whenever `didUpdateWidget` fires (i.e., the parent rebuilds with new props). Any `computed` or `watch` that reads `props.value.someField` automatically subscribes to changes.

```
Parent rebuilds with new props
  → didUpdateWidget fires
  → _widgetSignal.call(newWidget)
  → Dependent computed values recompute
  → Builder re-runs if it uses those computed values
  → Flutter diffs and updates the UI
```

## Common Mistakes

### Accessing props directly

```dart
// ❌ Not reactive — captures initial value only
final id = userId;
final greeting = computed(() => 'Hello, user $id!');

// ✅ Reactive
final props = widget();
final greeting = computed(() => 'Hello, user ${props.value.userId}!');
```

### Comparing with StatefulWidget

In `StatefulWidget`, you'd write `didUpdateWidget` manually:

```dart
// StatefulWidget approach
@override
void didUpdateWidget(UserCard oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.userId != oldWidget.userId) {
    _loadUser();
  }
}

// CompositionWidget approach — much simpler
final props = widget();
watch(() => props.value.userId, (newId, _) {
  loadUser(newId);
});
```

## Next Steps

- [Dependency Injection](./dependency-injection.md) — share state without prop drilling
- [Watchers & Effects](./watchers-and-effects.md) — react to any reactive change
- [The Composition Widget](./composition-widget.md) — how `setup()` and builders work
