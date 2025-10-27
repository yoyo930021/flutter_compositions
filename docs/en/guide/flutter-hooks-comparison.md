# Flutter Compositions vs `flutter_hooks`

Both libraries aim to reduce boilerplate from classic `StatefulWidget` patterns, but they make different trade-offs. Use this summary to decide which suits your project.

## API Shape

| Topic | Flutter Compositions | flutter_hooks |
|-------|---------------------|---------------|
| Entry point | `CompositionWidget.setup()` (or `CompositionBuilder`) declares state once and returns a builder | `HookWidget` / `HookConsumerWidget` call `useState`, `useEffect`, … directly in `build` |
| Mental model | Inspired by Vue Composition API – state, computed values, and lifecycle hooks live in `setup()` | Inspired by React Hooks – hooks must be called in a consistent order on every build |
| Restrictions | `setup()` runs only once; lifecycle hooks must register inside it | Hooks cannot be called conditionally; violations throw at runtime |

## Reactivity Model

- **Flutter Compositions** uses `alien_signals` to drive fine-grained updates. Builders re-run only when the refs they read change.
- **flutter_hooks** wraps Flutter’s existing `State` classes. Updating a hook usually re-runs the entire `build` method, so you still need to split widgets manually for performance.

## Lifecycle Handling

- Compositions offers `onMounted`, `onUnmounted`, `onBuild`, plus helpers like `useAnimationController` that auto-dispose resources.
- Hooks rely on `useEffect` or `useMemoized` clean-up callbacks; controller disposal is manual unless you wrap it yourself.

## Dependency Injection

- Compositions ships `provide` / `inject` with `InjectionKey<T>` for type-safe DI.
- flutter_hooks delegates DI to external packages (Provider, Riverpod, GetIt, …).

## Hot Reload

Compositions re-runs `setup()` during hot reload and preserves `ref` state by position—adjust declarations carefully or hot-restart. Hooks rely on Flutter’s default behavior; state remains unless you change hook order.

## When to Choose Each

Choose **Flutter Compositions** when:
- You want Vue-style composition and fine-grained reactivity.
- Auto-managed controllers and DI are important.
- You plan to build a composable library of reusable `use*` helpers.

Choose **flutter_hooks** when:
- Your team already embraces HookWidget patterns.
- You prefer to stay closer to Flutter’s traditional `build` flow.
- You need the maturity and ecosystem around flutter_hooks.

For a deeper dive, see the [Chinese guide](../../guide/flutter-hooks-comparison.md) or the [Design Trade-offs](../internals/design-trade-offs.md).
