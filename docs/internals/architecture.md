# Flutter Compositions Architecture Overview

## English

Flutter Compositions layers a thin runtime on top of `StatefulWidget` to mimic the ergonomics of Vue's Composition API while staying idiomatic to Flutter.

### Lifecycle

1. `CompositionWidget` creates a `_SetupContext` and runs `setup()` exactly once during `initState`.
2. `setup()` registers callbacks, effects, and provides a builder function.
3. The builder is executed within an alien_signals `effect`, so it re-runs only when dependencies change.
4. `provide` / `inject` walk the active context chain, allowing type-based dependency lookups without touching `BuildContext`.
5. When the widget updates, `_widgetSignal` emits the new instance so all computed props refresh.
6. On dispose, registered effects, controllers, and lifecycle hooks are cleaned up in order.

### Reactive Flow

```
parent passes props
        ↓
widget signal updates (WritableSignal)
        ↓
computed props + watchers re-run
        ↓
setup-provided builder executes inside effect
        ↓
UI rebuilds minimal parts
```

### Key Building Blocks

- **`Ref<T>`**: a writable signal, returned by `ref(initialValue)`.
- **`ComputedRef<T>`**: derived data created by `computed(() => expr)` or writable via `ComputedOptions`.
- **`watch` / `watchEffect`**: run callbacks when reactive sources change.
- **`use*` helpers**: integrate Flutter controllers, disposing them when appropriate.
- **`widget()` / `this.widget()`**: expose the latest widget instance as a reactive computed value.

### Error Prevention

- Assertions enforce calling lifecycle utilities only inside `setup()`.
- `inject<T>()` throws when a required dependency is missing, unless `T` is nullable.
- Effects registered through `watch` or `use*` are tied to the setup context and disposed automatically.
