# Architecture Overview

This page outlines how Flutter Compositions layers a composition-oriented runtime on top of Flutter’s `StatefulWidget`.

## Key Components

| Piece | Responsibility |
|-------|----------------|
| `CompositionWidget` | Developer-facing widget that exposes `setup()` and returns a builder. |
| `_CompositionWidgetState` | Manages lifecycle, runs `setup()` once, and registers reactive effects. |
| `_SetupContext` | Internal container that stores refs, lifecycle hooks, and provided values. |
| `alien_signals` runtime | Provides the reactive core (`Ref`, `ComputedRef`, effects). |

## Lifecycle

1. `initState` creates `_SetupContext` and calls `setup()`.
2. The returned builder is wrapped in an effect so it re-runs when dependencies change.
3. `build` delegates to the cached builder output.
4. `dispose` invokes cleanup handlers, disposes controllers, and tears down effects.

## Why a Custom Runtime?

- Keep the API close to Vue’s Composition API while staying idiomatic to Flutter.
- Enable fine-grained updates—only the widgets that touch a modified ref rebuild.
- Manage lifecycles declaratively through hooks instead of hand-written boilerplate.

## Integration Points

- Lifecycle hooks (`onMounted`, `onUnmounted`, `onBuild`) map to Flutter’s lifecycle methods.
- Dependency injection (`provide`/`inject`) uses the `_SetupContext` parent chain.
- Composables use the runtime to allocate refs and register cleanups.

## See Also

- [Technical Deep Dive](./technical-deep-dive.md)
- [Reactivity In Depth](./reactivity-in-depth.md)
- [Design Trade-offs](./design-trade-offs.md)
