# watch & watchEffect

Side effects and reactive dependencies tracking.

## watch

Watch a reactive value and execute a callback when it changes.

### Signature

```dart
WatchHandle watch<T>(
  T Function() getter,
  void Function(T newValue, T oldValue) callback, {
  bool immediate = false,
})
```

### Parameters

- `getter` - Function that returns the value to watch
- `callback` - Function called when value changes, receives new and old values
- `immediate` - If `true`, run callback immediately with current value

### Returns

`WatchHandle` - Handle to stop watching

### Example

```dart
final count = ref(0);

watch(
  () => count.value,
  (newValue, oldValue) {
    print('Count changed from $oldValue to $newValue');
  },
);

count.value++; // Logs: "Count changed from 0 to 1"
```

### With immediate

```dart
watch(
  () => count.value,
  (newValue, oldValue) {
    print('Current: $newValue');
  },
  immediate: true,
); // Immediately logs: "Current: 0"
```

## watchEffect

Automatically track dependencies and re-run when any of them change.

### Signature

```dart
WatchHandle watchEffect(void Function() effect)
```

### Parameters

- `effect` - Function to run, dependencies are automatically tracked

### Returns

`WatchHandle` - Handle to stop watching

### Example

```dart
final count = ref(0);
final doubled = ref(0);

watchEffect(() {
  // Automatically tracks both count and doubled
  print('Count: ${count.value}, Doubled: ${doubled.value}');
});

count.value++; // Triggers watchEffect
doubled.value = count.value * 2; // Also triggers watchEffect
```

## WatchHandle

Handle returned by `watch` and `watchEffect` to control the watcher.

### Methods

- `stop()` - Stop watching and clean up

### Example

```dart
final handle = watchEffect(() {
  print(count.value);
});

// Later...
handle.stop(); // Stop watching
```

## Lifecycle Integration

When used inside `setup()`, watchers are automatically cleaned up when the widget is disposed.

```dart
class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    // Automatically cleaned up on dispose
    watch(() => count.value, (value, _) {
      print(value);
    });

    return (context) => Text('${count.value}');
  }
}
```

## Best Practices

### Use watch for specific values

```dart
// Good: Watch specific value
watch(() => user.value.id, (newId, oldId) {
  fetchUserData(newId);
});
```

### Use watchEffect for multiple dependencies

```dart
// Good: Auto-track multiple values
watchEffect(() {
  final result = count.value + multiplier.value;
  print('Result: $result');
});
```

### Avoid side effects in getter

```dart
// Bad: Side effect in getter
watch(() {
  print('Computing...'); // Don't do this!
  return count.value;
}, (value, _) {});

// Good: Side effects only in callback
watch(() => count.value, (value, _) {
  print('Value changed to $value');
});
```

## See Also

- [ref](./reactivity.md#ref) - Create reactive references
- [computed](./reactivity.md#computed) - Computed values
- [Lifecycle hooks](./lifecycle.md) - Component lifecycle
