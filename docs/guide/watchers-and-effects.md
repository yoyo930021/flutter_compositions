# Watchers & Effects

Watchers let you run side effects when reactive dependencies change. Flutter Compositions provides two APIs: `watch()` for explicit dependency tracking, and `watchEffect()` for automatic tracking.

> **Prefer `computed` over `watch`**: If your goal is to derive a new value from reactive state, use `computed()` instead. `computed` is declarative, automatically cached, and only recalculates when its dependencies change. Reserve `watch`/`watchEffect` for **side effects** — operations that interact with the outside world (logging, navigation, API calls, analytics, local storage, etc.) rather than producing a value.
>
> ```dart
> // ❌ Using watch to derive a value
> final fullName = ref('');
> watch(
>   () => (firstName.value, lastName.value),
>   (names, _) => fullName.value = '${names.$1} ${names.$2}',
> );
>
> // ✅ Using computed to derive a value
> final fullName = computed(() => '${firstName.value} ${lastName.value}');
> ```

## watch()

`watch()` explicitly specifies what to observe and gives you access to both old and new values:

```dart
final count = ref(0);

watch(
  () => count.value,        // Getter: what to watch
  (newValue, oldValue) {    // Callback: what to do
    print('Count changed: $oldValue → $newValue');
  },
);

count.value = 1;  // Prints: "Count changed: 0 → 1"
```

### Watching Multiple Sources

Combine multiple refs in the getter to react when any of them change:

```dart
watch(
  () => (firstName.value, lastName.value),
  (newNames, oldNames) {
    print('Name changed from ${oldNames.$1} ${oldNames.$2} to ${newNames.$1} ${newNames.$2}');
  },
);
```

### Watching Value Transitions

Use the `previous` parameter to compare old and new values:

```dart
watch(() => cart.total.value, (total, previous) {
  if (total > previous) {
    analytics.trackCartChange(total);
  }
});
```

### Watching Props

React to prop changes by watching through `widget()`:

```dart
@override
Widget Function(BuildContext) setup() {
  final props = widget<UserAvatar>();
  watch(() => props.value.userId, (newId, oldId) {
    cache.loadAvatar(newId);
  });
  // ...
}
```

## watchEffect()

`watchEffect()` automatically tracks all reactive dependencies accessed inside its callback:

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

### Use Cases

- **Logging and debugging**: trace when and why values change
- **Syncing external systems**: push state changes to analytics, local storage, etc.
- **Side effects without old values**: when you don't need to compare previous state

## When to Use Which

| Scenario | Recommended |
|----------|-------------|
| Derive a new value from reactive state | `computed()` |
| Need old and new values for a side effect | `watch()` |
| Simple side effect, no comparison | `watchEffect()` |
| Explicit control over dependencies | `watch()` |
| Track many dependencies automatically | `watchEffect()` |

## Batched Updates

Multiple writes inside the same microtask collapse into a single re-execution:

```dart
void incrementTwice() {
  count.value++;
  count.value++;
  // The watcher fires once with the final value, not twice
}
```

If you need intermediate frames, schedule them explicitly with `Future.microtask` or `SchedulerBinding`.

## Automatic Cleanup

All watchers created during `setup()` are automatically cleaned up when the widget is unmounted. You don't need to manually cancel them — the `effectScope` handles teardown.

## Debugging Tips

- Use `debugPrint` inside `watchEffect` to trace when it re-runs and what values triggered it.
- Keep an eye out for `ref.value = ref.value` patterns — they trigger unnecessary updates.
- When the UI does not update, check that you read `.value` inside the builder or computation.

## Next Steps

- [Lifecycle Hooks](./lifecycle-hooks.md) — `onMounted`, `onUnmounted`, `onBuild`
- [Reactivity Fundamentals](./reactivity-fundamentals.md) — `ref`, `computed`, collections
- [Reactivity System internals](../internals/reactivity-system.md) — how dependency tracking works
