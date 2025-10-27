# Lifecycle Hooks

Lifecycle hooks for managing component lifecycle in Flutter Compositions.

## onMounted

Called after the first frame is rendered.

### Signature

```dart
void onMounted(void Function() callback)
```

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  onMounted(() {
    print('Component mounted and rendered');
  });

  return (context) => Text('Hello');
}
```

### Async Initialization

```dart
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);

  onMounted(() async {
    data.value = await fetchData();
  });

  return (context) => Text(data.value ?? 'Loading...');
}
```

### Multiple onMounted Hooks

```dart
@override
Widget Function(BuildContext) setup() {
  onMounted(() {
    print('First mount hook');
  });

  onMounted(() {
    print('Second mount hook');
  });

  return (context) => Container();
}
```

## onUnmounted

Called before the widget is disposed.

### Signature

```dart
void onUnmounted(void Function() callback)
```

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final timer = Timer.periodic(Duration(seconds: 1), (_) {
    print('Tick');
  });

  onUnmounted(() {
    timer.cancel(); // Clean up on unmount
  });

  return (context) => Text('Timer running');
}
```

### Cleanup Subscriptions

```dart
@override
Widget Function(BuildContext) setup() {
  final subscription = stream.listen((data) {
    print(data);
  });

  onUnmounted(() {
    subscription.cancel();
  });

  return (context) => Container();
}
```

## onBuild

Called every time the builder function executes.

### Signature

```dart
void onBuild(void Function() callback)
```

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  onBuild(() {
    print('Builder executed, count: ${count.value}');
  });

  return (context) {
    return Text('Count: ${count.value}');
  };
}
```

### Access BuildContext

```dart
@override
Widget Function(BuildContext) setup() {
  final theme = ref<ThemeData?>(null);

  onBuild(() {
    // onBuild callback doesn't have access to context
    // Access context in the builder itself
  });

  return (context) {
    theme.value = Theme.of(context); // Access context here
    return Text('Theme: ${theme.value?.brightness}');
  };
}
```

## Lifecycle Order

```
1. setup() called
2. builder() called (first time)
3. onBuild() callbacks executed
4. Frame rendered
5. onMounted() callbacks executed

... (widget active)

6. State changes trigger builder()
7. onBuild() callbacks executed again

... (widget disposed)

8. onUnmounted() callbacks executed
```

## Comparison with StatefulWidget

| StatefulWidget | CompositionWidget |
|----------------|-------------------|
| `initState()` | `setup()` |
| `build()` | `return (context) => ...` |
| `didChangeDependencies()` | `onBuild()` |
| First frame callback | `onMounted()` |
| `dispose()` | `onUnmounted()` |
| `didUpdateWidget()` | Automatic (via `widget()`) |

## Best Practices

### Use onMounted for Async

```dart
// ✅ Good: Async in onMounted
@override
Widget Function(BuildContext) setup() {
  final data = ref<User?>(null);

  onMounted(() async {
    data.value = await fetchUser();
  });

  return (context) => Text(data.value?.name ?? 'Loading...');
}
```

### Clean Up Resources

```dart
// ✅ Good: Clean up in onUnmounted
@override
Widget Function(BuildContext) setup() {
  final controller = AnimationController(vsync: this);

  onUnmounted(() {
    controller.dispose();
  });

  return (context) => AnimatedBuilder(...);
}
```

### Multiple Lifecycle Hooks

```dart
@override
Widget Function(BuildContext) setup() {
  // Mount hooks
  onMounted(() => print('Mounted 1'));
  onMounted(() => print('Mounted 2'));

  // Unmount hooks
  onUnmounted(() => print('Unmounted 1'));
  onUnmounted(() => print('Unmounted 2'));

  return (context) => Container();
}
// Execution order:
// Mounted 1
// Mounted 2
// ... (later)
// Unmounted 1
// Unmounted 2
```

## Automatic Cleanup

Composables that create resources typically handle cleanup automatically:

```dart
@override
Widget Function(BuildContext) setup() {
  // These automatically clean up on unmount
  final scrollController = useScrollController();
  final (animController, _) = useAnimationController();
  final subscription = useStream(myStream);

  // No need for manual onUnmounted cleanup!

  return (context) => Container();
}
```

## See Also

- [CompositionWidget](./composition-widget.md) - Base widget class
- [Composables](./composables/) - Built-in composables with auto-cleanup
- [watch](./watch.md) - Side effects
