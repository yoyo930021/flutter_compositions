# Reactivity in Depth

`flutter_compositions` is powered by the `alien_signals` package, a high-performance reactive library tailored for Dart. Understanding the basic principles of `alien_signals` will help you fully grasp how `flutter_compositions` works.

## The Three Pillars of a Signal System

A signal system typically consists of three core concepts:

1.  **Signal (or Ref)**: The **source of truth** in a reactive system. In our framework, this is created by `ref()`. It's a container that wraps a value. When you read its `.value`, you are reading a value; when you write to its `.value`, you are triggering a change.

2.  **Computed**: **Derived data**. Created by `computed()`. It doesn't have a value of its own; its value is calculated from other `Signal`s or `Computed`s via a function. It automatically tracks the dependencies it uses during its computation.

3.  **Effect**: The **end-point** of the reactive system. Created by `watchEffect()`, `watch()`, or implicitly by a `CompositionWidget`'s `builder` function. It's a function that performs some action (like printing to the console, making a network request, or **updating the UI**). An `Effect` also tracks the dependencies it uses during its execution.

These three pillars form a **Dependency Graph**. `Computed`s and `Effect`s subscribe to the `Signal`s and `Computed`s they depend on.

## How the "Magic" Works: Automatic Tracking

When you read the `.value` of a `ref` inside a `computed` or `effect` function, something magical happens:

1.  Before executing the `computed` or `effect` function, `alien_signals` sets a global "current listener".
2.  When you access `ref.value`, the `ref`'s getter checks if this "current listener" exists.
3.  If it does, the `ref` adds this "listener" (i.e., the `computed` or `effect`) to its own list of subscribers.
4.  After the function finishes executing, the global "current listener" is cleared.

This is why you don't need to manually declare dependencies. The system automatically records who depends on whom.

## The Update Process

When you modify the value of a `ref` (e.g., `count.value++`), the update process is as follows:

1.  The `ref`'s setter is called.
2.  The `ref` iterates through its internal list of subscribers (all the `computed`s and `effect`s that depend on it).
3.  It notifies these subscribers, saying, "My value has changed!"
4.  A notified `computed` marks itself as "stale" but **does not immediately re-calculate**. It waits until the next time its `.value` is read to perform a lazy evaluation.
5.  A notified `effect` is added to a queue and re-executed asynchronously in a batch by the `alien_signals` scheduler in a microtask.

## Integration with Flutter: The Role of the `builder`

The most clever part of `CompositionWidget` is how it integrates this reactive system with Flutter's widget system.

The `_CompositionWidgetState` wraps your `builder` function in an `effect`. The content of this `effect` is roughly as follows:

```dart
// This is a simplified illustration
_renderEffect = effect(() {
  // Execute the builder function you returned from setup()
  final newWidget = builder(context);

  // If the generated widget is different from the last one, call setState
  if (_cachedWidget != newWidget) {
    setState(() {
      _cachedWidget = newWidget;
    });
  }
});
```

This means:

- The `_renderEffect` is only re-executed when the **reactive data** used inside the `builder` function changes.
- `setState` is only potentially called when the `_renderEffect` is re-executed.
- `setState` only triggers a small rebuild of this `CompositionWidget` itself, not the entire page.

This is the secret to how `flutter_compositions` achieves **fine-grained updates** and **high performance**. It transforms Flutter's coarse-grained `setState` mechanism into an automated update system precisely controlled by the underlying reactive system, allowing developers to focus on business logic without manually managing the synchronization between state and UI.
