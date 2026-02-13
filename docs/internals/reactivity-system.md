# Reactivity System

This document explains how Flutter Compositions builds fine-grained reactivity on top of Flutter's widget system using `alien_signals`.

## Building Blocks

### Ref

`ref(value)` returns a `Ref<T>` — a wrapper that tracks reads and writes to `.value`.

- **Reads** register the current reactive observer (builder, computed, or effect)
- **Writes** mark the ref as dirty and notify subscribers

### Computed

`computed(() => ...)` lazily evaluates a function and caches the result until any dependency changes. It behaves like a memoized getter.

- Only computes when first accessed (lazy evaluation)
- Caches results until a dependency changes
- Can itself be a dependency for other computed values or effects

### Effect

Effects are registered by builders, `watch`, or `watchEffect`. Each effect captures the refs it touches and reruns when any of them change.

## Dependency Tracking

The dependency tracking algorithm follows the same model popularized by Vue's reactivity system:

1. Before a reactive function executes, the runtime pushes it onto a **"current observer" stack**
2. When a ref's getter runs, it attaches the current observer to its **subscriber list**
3. Once the function finishes, the observer is **popped** from the stack
4. When `.value` is written, every subscriber is **queued for re-execution**

```
┌─────────────────────────────────────────────┐
│  Effect/Computed runs                       │
│    → Push onto observer stack               │
│    → Read ref.value                         │
│       → ref registers this observer         │
│    → Read computed.value                    │
│       → computed registers this observer    │
│    → Pop from observer stack                │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  ref.value = newValue                       │
│    → Mark ref as dirty                      │
│    → Queue all subscribers for re-execution │
│    → Microtask scheduler deduplicates       │
│    → Each observer re-executes in order     │
└─────────────────────────────────────────────┘
```

## Scheduler

Updates are batched in a microtask queue:

1. A setter marks the ref dirty and enqueues observers
2. The runtime **deduplicates** observers to avoid redundant work
3. Once the microtask runs, each observer executes in order
4. Builders wrap their work via `markNeedsBuild()`, so Flutter sees them as ordinary widget updates

## Integration with Flutter

- `CompositionWidget` runs `setup()` once, grabs the returned builder, and registers it as an effect
- When dependencies change, the builder triggers `markNeedsBuild()`, scheduling a rebuild that Flutter diffs like any other widget
- Lifecycle hooks (`onMounted`, `onUnmounted`, `onBuild`) piggyback on Flutter's lifecycle and the reactive scheduler

## Effect Scope

All effects created during `setup()` are tracked via `effectScope`:

- Registered in `SetupContext._effectScope`
- Automatically disposed when the widget unmounts
- No manual cleanup needed for `watch`, `watchEffect`, or builder effects

## ComputedBuilder

`ComputedBuilder` wraps a section of UI in its own reactive effect. It observes the refs read inside the provided builder and only rebuilds that subtree when one of those refs changes.

- Use it to isolate hot spots that update frequently
- Pair it with `computed` values so expensive derivations only re-run when needed
- Prefer small builders for maximum effectiveness

## Avoiding Common Pitfalls

- **Stale props**: Access props via `widget()` so you get a reactive wrapper around the latest widget instance
- **Mutable collections**: Replace lists or maps wholesale (`todos.value = [...todos.value, todo]`) so the runtime sees a new reference
- **Async gaps**: When mixing async callbacks and refs, read the latest value inside the callback instead of capturing stale data

## Tooling Hooks

The runtime exposes `onCleanup` behind the scenes so every effect can register teardown logic. Composables like `watch` and `useStream` rely on it to remove listeners automatically.

## Performance Characteristics

| Operation | Complexity |
|-----------|-----------|
| Ref read | O(1) |
| Ref write | O(n) where n = subscriber count |
| Computed evaluation | O(1) amortized (cached) |
| Builder rebuild | Only widgets reading changed refs |
| Dependency tracking | O(1) per read |

## Further Reading

- [Architecture Overview](./architecture.md) — component layout and lifecycle
- [Performance](./performance.md) — optimization implementation details
- [Reactivity Fundamentals](../guide/reactivity-fundamentals.md) — user-facing API guide
