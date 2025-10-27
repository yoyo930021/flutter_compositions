# customRef

Create custom reactive references with full control over tracking and triggering.

## Overview

`customRef` allows you to create reactive references with custom getter and setter logic, giving you complete control over dependency tracking and update triggering.

## Signature

```dart
Ref<T> customRef<T>({
  required T Function(T Function() track) getter,
  required void Function(T newValue, void Function() trigger) setter,
})
```

## Parameters

- `getter` - Function that returns the current value. Call `track()` to track dependencies.
- `setter` - Function that sets a new value. Call `trigger()` to notify watchers.

## Example: Debounced Ref

```dart
Ref<String> useDebouncedRef(String initialValue, Duration delay) {
  String _value = initialValue;
  Timer? _timer;

  return customRef<String>(
    getter: (track) {
      track(); // Track this access
      return _value;
    },
    setter: (newValue, trigger) {
      _timer?.cancel();
      _timer = Timer(delay, () {
        _value = newValue;
        trigger(); // Notify watchers after delay
      });
    },
  );
}

// Usage
final searchQuery = useDebouncedRef('', Duration(milliseconds: 300));
searchQuery.value = 'flutter'; // Triggers after 300ms
```

## Example: Validated Ref

```dart
Ref<int> useValidatedRef(int min, int max) {
  int _value = min;

  return customRef<int>(
    getter: (track) {
      track();
      return _value;
    },
    setter: (newValue, trigger) {
      final clamped = newValue.clamp(min, max);
      if (clamped != _value) {
        _value = clamped;
        trigger();
      }
    },
  );
}

// Usage
final age = useValidatedRef(0, 120);
age.value = 150; // Actually sets to 120
```

## Example: Logged Ref

```dart
Ref<T> useLoggedRef<T>(T initialValue, String name) {
  T _value = initialValue;

  return customRef<T>(
    getter: (track) {
      print('[$name] Read: $_value');
      track();
      return _value;
    },
    setter: (newValue, trigger) {
      print('[$name] Write: $_value -> $newValue');
      _value = newValue;
      trigger();
    },
  );
}
```

## ReadonlyCustomRef

Create a readonly custom ref (no setter).

### Signature

```dart
ComputedRef<T> readonlyCustomRef<T>({
  required T Function(T Function() track) getter,
})
```

### Example

```dart
ComputedRef<DateTime> useCurrentTime(Duration updateInterval) {
  DateTime _time = DateTime.now();

  Timer.periodic(updateInterval, (_) {
    _time = DateTime.now();
    // trigger() is called automatically
  });

  return readonlyCustomRef<DateTime>(
    getter: (track) {
      track();
      return _time;
    },
  );
}
```

## Best Practices

### Always call track()

```dart
// Bad: Forgot to track
customRef<int>(
  getter: (track) => _value, // Missing track()!
  setter: (newValue, trigger) {
    _value = newValue;
    trigger();
  },
);

// Good: Properly tracked
customRef<int>(
  getter: (track) {
    track(); // Dependencies will be tracked
    return _value;
  },
  setter: (newValue, trigger) {
    _value = newValue;
    trigger();
  },
);
```

### Only trigger on actual changes

```dart
// Good: Avoid unnecessary updates
customRef<int>(
  getter: (track) {
    track();
    return _value;
  },
  setter: (newValue, trigger) {
    if (newValue != _value) { // Check before triggering
      _value = newValue;
      trigger();
    }
  },
);
```

### Clean up resources

```dart
Ref<T> useCustomRefWithCleanup<T>(T initial) {
  final subscription = someStream.listen((_) {});

  onUnmounted(() {
    subscription.cancel(); // Clean up on unmount
  });

  return customRef<T>(
    getter: (track) {
      track();
      return _value;
    },
    setter: (newValue, trigger) {
      _value = newValue;
      trigger();
    },
  );
}
```

## See Also

- [ref](./reactivity.md#ref) - Standard reactive references
- [computed](./reactivity.md#computed) - Computed values
- [watch](./watch.md) - Side effects
