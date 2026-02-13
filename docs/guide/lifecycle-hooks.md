# Lifecycle Hooks

Flutter Compositions provides declarative lifecycle hooks that let you attach logic to a widget's lifecycle from within `setup()`. All hooks are registered during `setup()` and fire at the appropriate moment.

## Available Hooks

### onMounted

Executes after the widget is mounted on the screen (in the first frame after mount). Ideal for:
- Making network requests
- Initializing resources that need a rendered widget
- Starting animations

```dart
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);

  onMounted(() async {
    // Safe to do async work here
    data.value = await fetchData();
  });

  return (context) => Text(data.value ?? 'Loading...');
}
```

### onUnmounted

Executes just before the widget is destroyed (during unmount). Use it to:
- Clean up timers, subscriptions, or event listeners
- Cancel ongoing operations
- Release resources not managed by `use*` helpers

```dart
@override
Widget Function(BuildContext) setup() {
  late final Timer timer;

  onMounted(() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      print('Tick ${t.tick}');
    });
  });

  onUnmounted(() {
    timer.cancel();
  });

  return (context) => Container();
}
```

### onBuild

Executes every time the builder function runs. This hook receives the current `BuildContext` and is primarily used internally by composables to access `InheritedWidget` data:

```dart
@override
Widget Function(BuildContext) setup() {
  final width = ref(0.0);

  onBuild((context) {
    width.value = MediaQuery.of(context).size.width;
  });

  return (context) => Text('Width: ${width.value}');
}
```

::: tip
For accessing `InheritedWidget` data reactively, prefer using `useContextRef()` or the built-in composables like `useMediaQuery()`, `useTheme()`, etc. They handle the `onBuild` integration for you.
:::

## Multiple Hooks

You can register multiple instances of the same hook. They execute in registration order:

```dart
@override
Widget Function(BuildContext) setup() {
  onMounted(() => print('First mounted callback'));
  onMounted(() => print('Second mounted callback'));

  onUnmounted(() => print('First cleanup'));
  onUnmounted(() => print('Second cleanup'));

  return (context) => Container();
}
```

## Colocating Setup and Cleanup

A common pattern is to register cleanup inside `onMounted`, keeping setup and teardown close together:

```dart
onMounted(() {
  final subscription = stream.listen((event) {
    handleEvent(event);
  });

  onUnmounted(() {
    subscription.cancel();
  });
});
```

## Lifecycle Mapping from StatefulWidget

| StatefulWidget | Flutter Compositions |
|---------------|---------------------|
| `initState()` | Body of `setup()` |
| `addPostFrameCallback` in `initState` | `onMounted()` |
| `dispose()` | `onUnmounted()` |
| `build()` | Builder function returned from `setup()` |
| `didUpdateWidget()` | Automatic via `widget()` reactive props |
| `didChangeDependencies()` | Automatic via `useContextRef()` / `onBuild()` |

## Automatic Cleanup

Most resources don't need manual cleanup when you use the framework's built-in helpers:

| Resource | Auto-cleaned by |
|----------|----------------|
| `Ref`, `ComputedRef` | `effectScope` disposal |
| `watch`, `watchEffect` | `effectScope` disposal |
| `ScrollController`, `TextEditingController`, etc. | `use*` helpers |
| `AnimationController` | `useAnimationController` |
| Provided values | Widget unmount |

You only need `onUnmounted` for external resources (timers, raw streams, platform channels, etc.) that aren't managed by composables.

## Next Steps

- [Reactive Props](./reactive-props.md) — how `widget()` handles prop changes
- [Built-in Composables](./built-in-composables.md) — auto-managed controllers
- [Migrating from StatefulWidget](./from-stateful-widget.md) — side-by-side lifecycle comparison
