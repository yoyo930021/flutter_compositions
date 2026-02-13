# Architecture Overview

This page explains how Flutter Compositions layers a composition-oriented runtime on top of Flutter's widget system.

## Key Components

| Component | Responsibility |
|-----------|----------------|
| `CompositionWidget` | Developer-facing widget (extends `StatelessWidget`) that exposes `setup()` and returns a builder |
| `_CompositionElement` | Custom `StatelessElement` that manages lifecycle, runs `setup()`, and registers reactive effects |
| `SetupContextImpl` | Internal container that stores refs, lifecycle hooks, effect scopes, and provided values |
| `alien_signals` runtime | Provides the reactive core (`Ref`, `ComputedRef`, effects) |

## Widget Lifecycle

1. **Mount** — creates `SetupContext`, sets up parent chain for `provide`/`inject`, creates `_widgetSignal` for reactive props, runs `setup()` inside an `effectScope`, stores the returned builder, schedules `onMounted` callbacks for the post-frame.

2. **Build** — the builder runs inside a reactive effect. Reading any ref inside the builder registers the effect as a subscriber. When dependencies change, `markNeedsBuild()` is called directly.

3. **Props update** — `update(newWidget)` fires, calling `_widgetSignal.call(widget)`. Dependent computed values recompute, triggering the builder if needed.

4. **Dependencies change** — `didChangeDependencies()` triggers `onBuild` callbacks for `InheritedWidget` integration.

5. **Unmount** — invokes `onUnmounted` callbacks, disposes the effect scope (which cleans up all refs, computed values, watchers), and tears down the `SetupContext`.

## Setup Execution Flow

```
mount()
  → Create SetupContext
  → Set up parent context (for provide/inject)
  → Create _widgetSignal (for reactive props)
  → Run setup() inside effectScope (once)
  → Store returned builder function
  → Schedule onMounted callbacks for post-frame
```

## Reactive Update Flow

```
ref.value = newValue
  → Signal notifies subscribers
  → Effects queued in microtask (batched)
  → Builder effect re-runs
  → markNeedsBuild() called
  → Flutter rebuilds the element
```

## Builders as Effects

The builder returned from `setup()` runs inside a reactive `effect`. This means:

- Reading a ref inside the builder **registers** the effect as a subscriber
- When any subscribed ref changes, the effect re-runs
- The effect calls `markNeedsBuild()`, triggering a standard Flutter rebuild
- Flutter diffs the widget tree as usual

## Cleanup Semantics

`onCleanup` (exposed via helpers like `watch`) registers teardown logic that fires when the effect is disposed or recreated. This guarantees that listeners, timers, and controllers are properly cleared.

Example from `useStream`:

```dart
final subscription = stream.listen((value) {
  ref.value = value;
});
onCleanup(subscription.cancel);
```

## Controller Management

Helpers like `useScrollController` and `useAnimationController` automatically:

1. Create the controller once during setup
2. Register a cleanup to dispose the controller on unmount
3. Bridge imperative events into refs so UI stays reactive

## Provide/Inject Architecture

The DI system uses a **parent chain** (not `InheritedWidget`) for dependency injection:

- `SetupContext._parent` links to the nearest ancestor `CompositionWidget`'s context
- O(d) lookup where d = widget tree depth
- Does **not** propagate rebuilds — refs handle reactivity
- Type-safe via `InjectionKey<T>` (generic type participates in equality)

```
inject(key)
  → Check current SetupContext._providedValues
  → Walk _parent chain upward
  → Return first match or throw
```

## Error Handling

- Unhandled exceptions from `setup()` bubble up like any Flutter error
- Inside effects, errors are caught and rethrown asynchronously so Flutter's error widget shows useful stack traces

## Performance Architecture

All reactive widgets use a unified StatelessWidget + custom Element architecture:

- **2 objects instead of 3** per widget (no separate `State` object)
- **Direct `markNeedsBuild()`** instead of `setState()` (saves ~200-500 CPU cycles per update)
- **No closure creation** for setState (saves ~30 CPU cycles per update)
- **Memory savings**: ~48-56 bytes per widget instance (15-20% reduction)

This implementation is inspired by [solidart PR #143](https://github.com/nank1ro/solidart/pull/143) and [flutter_hooks](https://github.com/rrousselGit/flutter_hooks).

## Further Reading

- [Reactivity System](./reactivity-system.md) — how dependency tracking works
- [Performance](./performance.md) — optimization strategies
- [Design Trade-offs](./design-trade-offs.md) — deliberate design decisions
