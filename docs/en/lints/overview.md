# Custom Lint Guidance for Flutter Compositions

## English

Use custom lint rules to keep CompositionWidgets reactive and consistent:

- **Prefer calling `widget()` / `this.widget()` inside `setup()`** – direct field access skips reactivity.
- **Avoid mutable fields on the widget class**; keep mutable state in `ref` or `ComputedRef`.
- **Validate `provide` / `inject` pairs** by linting for matching generic types.
- **Disallow async void `setup()`** bodies; `setup()` must synchronously return a builder.
- **Flag orphaned controllers** by requiring `use*` helpers (e.g., `useScrollController`) or explicit dispose calls.

Example configuration snippet for `custom_lint`:

```yaml
custom_lint:
  rules:
    - flutter_compositions_ensure_reactive_props
    - flutter_compositions_no_async_setup
    - flutter_compositions_controller_lifecycle
```

Recommended quick fixes:

- Wrap direct property usage with `widget()` and, when necessary, computed selectors.
- Replace manual controller wiring with the provided `use*` helpers.
