# Design Trade-offs

Flutter Compositions prioritises developer ergonomics and fine-grained updates. These choices come with deliberate trade-offs.

## Familiar API vs. Flutter Conventions

- **Pro:** Developers coming from Vue or React Hooks feel at home with `setup()`, `ref`, `computed`, and lifecycle hooks.
- **Con:** The API diverges from idiomatic Flutter Widget patterns, so newcomers need to learn an additional abstraction.

## Runtime Layer

- **Pro:** The `alien_signals` based runtime gives precise dependency tracking and automatic clean-up.
- **Con:** It adds a thin layer above Flutter’s standard lifecycle, which can complicate debugging when mixing with legacy `StatefulWidget`s.

## Single `setup()` Execution

- **Pro:** Declaring state inside `setup()` mirrors Vue’s Composition API and guarantees predictable lifecycle behaviour.
- **Con:** Props are not reactive unless you access them via `widget<T>()`, which is easy to forget.

## Hot Reload Semantics

- **Pro:** Hot reload reruns `setup()` and restores refs by declaration order, so state sticks around during iterative work.
- **Con:** Reordering or removing refs can shuffle the saved state; team members need to know when a hot restart is safer.

## Dependency Injection Scope

- **Pro:** Keys provide compile-time safety without the ceremony of `InheritedWidget`.
- **Con:** Everything lives in memory; there is no lazy-loading or auto-disposal for provided values unless you add it manually.

## Granular Rebuilds

- **Pro:** Builders only rerun when the refs they read change, keeping UI updates tight.
- **Con:** Debug tools like Flutter Inspector expect widget rebuilds; when less of the tree rebuilds, it can feel unfamiliar.

## Recommended Mitigations

- Adopt team lint rules to enforce `widget<T>()` and `InjectionKey` usage.
- Wrap legacy widgets progressively; mixing paradigms is supported but requires clear coding standards.
- Document how and where services are provided so onboarding stays smooth.
- Define a project structure for composables/services (e.g. `features/<name>/composables`).
- Share hot-reload etiquette so developers know when to restart and how to order refs.

## Related Reading

- [Architecture Overview](./architecture.md)
- [Technical Deep Dive](./technical-deep-dive.md)
