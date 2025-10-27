# Technical Deep Dive

This document connects the dots between the runtime, lifecycle hooks, and the composable helpers that ship with Flutter Compositions.

## Setup Execution

`setup()` runs exactly once:

1. `_SetupContext` is created with stacks for effects, cleanups, and provides.
2. Composables can register lifecycle hooks (`onMounted`, `onUnmounted`, `onBuild`) by pushing callbacks onto the context.
3. The returned builder closes over any refs created during setup.

Hot reload preserves ref positions by index—keep the declaration order stable to retain state.

## Builders as Effects

- The builder runs inside an `effect`.
- Reading a ref inside the builder registers the effect as a subscriber.
- When the effect re-runs, Flutter triggers `setState`, leading to a standard rebuild.

## Cleanup Semantics

`onCleanup` (exposed via helpers like `watch`) registers teardown logic that fires when the effect is disposed or recreated. It guarantees that listeners, timers, and controllers are cleared.

Example from `useStream`:

```dart
final subscription = stream.listen((value) {
  ref.value = value;
});
onCleanup(subscription.cancel);
```

## Controller Management

Helpers like `useScrollController` and `useAnimationController` automatically:

- Create the controller once during setup.
- Register a cleanup to dispose the controller on unmount.
- Bridge imperative events into refs so UI stays reactive.

## Error Handling

- Unhandled exceptions from `setup()` bubble up just like in Flutter; add guards where needed.
- Inside effects, errors are caught and rethrown asynchronously so Flutter’s error widget still shows useful stack traces.

## Threading DI Through Composables

- Composables may call `inject` directly when they rely on shared services.
- Prefer passing dependencies explicitly when the composable should stay pure; use `inject` for cross-cutting concerns (analytics, localization, feature flags).
- `_SetupContext` stores provided values in an internal map and walks the parent chain when resolving keys, similar to `InheritedWidget` without forcing a widget-tree rebuild.

## Extending the Runtime

To create custom composables:

1. Call `ref`/`computed`/`watch` as needed.
2. Register any listeners and clean them up with `onCleanup`.
3. Return the reactive values so callers can keep composing.

```dart
(Ref<Brightness>, void Function()) useBrightnessToggle() {
  final brightness = ref(Brightness.light);
  void toggle() => brightness.value =
      brightness.value == Brightness.light ? Brightness.dark : Brightness.light;
  return (brightness, toggle);
}
```

## Additional Resources

- [Architecture Overview](./architecture.md)
- [Reactivity In Depth](./reactivity-in-depth.md)
- Explore the source in `packages/flutter_compositions/lib/src` for concrete implementations.
