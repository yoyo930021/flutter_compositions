# Reactivity In Depth

This document explains how Flutter Compositions builds fine-grained reactivity on top of Flutter’s widget system.

> The original Traditional Chinese article lives at `/internals/reactivity-in-depth.md`. This version summarizes the key ideas for English readers.

## Building Blocks

### Ref

`ref(value)` returns a `Ref<T>`—a wrapper that tracks reads and writes to `.value`.

- Reads register the current reactive observer (builder, computed, or effect).
- Writes mark the ref as dirty and notify subscribers.

### Computed

`computed(() => ...)` lazily evaluates a function and caches the result until any dependency changes. It behaves like a memoized getter.

### Effect

Effects are registered by builders, `watch`, or `watchEffect`. Each effect captures the refs it touches and reruns when any of them change.

## Dependency Tracking

1. Before a reactive function executes, the runtime pushes it onto a “current observer” stack.
2. When a ref’s getter runs, it attaches the current observer to its subscriber list.
3. Once the function finishes, the observer is popped.
4. When `.value` mutates, every subscriber is queued for re-execution.

This is the same model popularized by Vue’s reactivity system.

## Scheduler

Updates are batched in a microtask queue:

1. A setter marks the ref dirty and enqueues observers.
2. Flutter Compositions deduplicates observers to avoid redundant work.
3. Once the microtask runs, each observer executes in order.

Builders wrap their work in `setState`, so Flutter sees them as ordinary widget updates.

## Integration with Flutter

- `CompositionWidget` runs `setup()` once, grabs the returned builder, and registers it as an effect.
- When dependencies change, the builder triggers `setState`, scheduling a rebuild that Flutter diffs like any other widget.
- Lifecycle hooks (`onMounted`, `onUnmounted`, `onBuild`) piggyback on Flutter’s lifecycle and the reactive scheduler.

## Avoiding Common Pitfalls

- **Stale props:** Access props via `widget<T>()` so you get a reactive wrapper around the latest widget instance.
- **Mutable collections:** Replace lists or maps wholesale (`todos.value = [...todos.value, todo]`) so the runtime sees a new reference.
- **Async gaps:** When mixing async callbacks and refs, read the latest value inside the callback instead of capturing stale data.

## Tooling Hooks

The runtime exposes `onCleanup` behind the scenes so every effect can register teardown logic. Composables like `watch` and `useStream` rely on it to remove listeners automatically.

## Performance Characteristics

- Accessing refs is O(1).
- Each write is proportional to the number of subscribed observers.
- Builders stay granular: only the widgets that read a changing ref rebuild.

## Further Reading

- [Reactivity Fundamentals](../guide/reactivity-fundamentals.md)
- [Advanced Reactivity](../guide/reactivity.md)
- [ComputedBuilder Utility](../api/utilities/computed-builder.md)
