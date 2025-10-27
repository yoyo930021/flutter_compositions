# Advanced Reactivity

This page builds on the basics from [Reactivity Fundamentals](./reactivity-fundamentals.md) and covers patterns you will encounter in real-world apps.

## Combine Multiple Refs

Use `computed` when a value depends on more than one ref. Keep computations pure—no side effects.

```dart
final firstName = ref('');
final lastName = ref('');

final displayName = computed(() {
  if (firstName.value.isEmpty && lastName.value.isEmpty) {
    return 'Anonymous';
  }
  return '${firstName.value} ${lastName.value}'.trim();
});
```

## Memoize Expensive Work

Wrap heavy operations (sorting, filtering, formatting) in `computed` so they only re-run when needed.

```dart
final todos = ref(<Todo>[]);

final overdue = computed(() {
  final now = DateTime.now();
  return todos.value.where((t) => t.dueDate.isBefore(now)).toList();
});
```

## Watch Value Transitions

`watch` lets you observe how a value changes over time.

```dart
watch(() => cart.total.value, (total, previous) {
  if (total > previous) {
    analytics.trackCartChange(total);
  }
});
```

- Always provide a `previous` parameter to compare old and new values.
- The watcher cleans itself up when the widget unmounts.

## React to Props

`widget<T>()` exposes the current widget instance as a `ComputedRef<T>` so you can observe prop changes.

```dart
@override
Widget Function(BuildContext) setup() {
  final props = widget<UserAvatar>();
  watch(() => props.value.userId, cache.loadAvatar);
  // ...
}
```

## Imperative Context Access

Need `BuildContext` inside lifecycle hooks? Use `useContext()`.

```dart
final contextRef = useContext();

onMounted(() {
  final overlay = Overlay.of(contextRef.value!);
  // ...
});
```

`contextRef.value` stays null until the widget mounts, so guard against that in `setup()`.

## Batched Updates

Multiple writes inside the same microtask collapse into a single builder re-run.

```dart
void incrementTwice() {
  count.value++;
  count.value++;
}
```

If you need intermediate frames, schedule them explicitly with `Future.microtask` or `SchedulerBinding`.

## Debugging Tips

- Use `debugPrint` inside `watchEffect` to trace when it re-runs.
- Keep an eye out for `ref.value = ref.value` patterns—they trigger unnecessary updates.
- When the UI does not update, check that you read `.value` inside the builder or computation.

## Next Steps

- Dive deep into the internals in [Reactivity In Depth](../internals/reactivity-in-depth.md).
- Explore how `ComputedBuilder` optimizes rebuilds in the [utilities reference](../api/utilities/computed-builder.md).
