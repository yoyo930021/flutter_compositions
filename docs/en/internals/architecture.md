# Architecture Overview

This page outlines how Flutter Compositions layers a composition-oriented runtime on top of Flutter’s `StatefulWidget`.

## Key Components

| Piece | Responsibility |
|-------|----------------|
| `CompositionWidget` | Developer-facing widget (Stateless) that exposes `setup()` and returns a builder. |
| `_CompositionElement` | Custom `Element` (`StatelessElement`) replacing State object, manages lifecycle, runs `setup()`, and registers reactive effects. |
| `SetupContextImpl` | Internal container that stores refs, lifecycle hooks, and provided values. |
| `alien_signals` runtime | Provides the reactive core (`Ref`, `ComputedRef`, effects). |

## Lifecycle

1. `mount` creates `SetupContext` and calls `setup()`.
2. `didChangeDependencies` triggers dependency updates.
3. `build` initializes or runs effect, delegates to the cached builder output, marking dirty directly on change.
4. `unmount` invokes cleanup handlers, disposes controllers, and tears down effects.

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
