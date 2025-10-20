# Design Philosophy & Trade-offs

The design of any framework or library involves a series of trade-offs. Understanding the design philosophy behind `flutter_compositions` and the trade-offs made can help you more deeply understand its strengths and suitable use cases.

## Core Design Philosophy

The creation of this library is based on several core goals:

1.  **Developer Experience First**: We believe that borrowing intuitive and powerful patterns from the Vue Composition API, such as `ref`, `computed`, and `watch`, can greatly simplify state management in Flutter, freeing developers from manual `setState` calls.

2.  **Performance Through Precision**: Through the fine-grained reactivity system provided by `alien_signals`, we aim to create a framework that is "performant by default." UI updates should be surgical and precise, not a carpet-bombing approach (i.e., unnecessary rebuilds of the entire subtree).

3.  **Composition Over Inheritance**: We promote breaking down UI logic into small, reusable `composable` functions instead of creating large and complex `StatefulWidget` classes. This makes the code easier to maintain, refactor, and test.

## Analysis of Technical Trade-offs

### `provide`/`inject` vs. `InheritedWidget`

`provide`/`inject` is the built-in dependency injection mechanism of this framework. It has clear design differences from Flutter's native `InheritedWidget`.

| Feature | `provide`/`inject` | `InheritedWidget` |
|---|---|---|
| Lookup Time | O(n), where n is ancestor depth | O(1) |
| Update Mechanism | Manual (via `Ref`) | Triggers automatic rebuilds |
| Rebuild Scope | None, only updates dependent `builder`s | All dependent descendants |
| Setup Cost | One-time in `initState` | On every `build` |

**Trade-off Consideration**:
We chose an O(n) parent chain lookup instead of `InheritedWidget`'s O(1) lookup. Why?

- **To Avoid Unnecessary Rebuilds**: The core function of `InheritedWidget` is to rebuild all descendants that depend on it when its value changes. This contradicts our philosophy of fine-grained updates. `provide`/`inject` passes a `Ref` (a reference). Even if the value inside the `Ref` changes, the `provide`/`inject` mechanism itself does not trigger any rebuilds. Only the `builder` that actually uses this `Ref` will update.
- **Sufficient Performance in Shallow Trees**: For most application scenarios, the depth of the component tree is relatively shallow (< 10 levels), making the performance overhead of an O(n) lookup completely negligible.

**Conclusion**: Use `provide`/`inject` when you need to pass **reactive state**. Use `InheritedWidget` when you need to pass truly global, infrequently changing configuration (like `ThemeData`).

### The Necessity of the `widget()` API

You might wonder why we need the slightly verbose `widget().value.prop` syntax to access properties instead of just `this.prop`.

**Trade-off Consideration**:
This is determined by the core design that `setup` runs only once.

- **The Problem**: If you access `this.prop` directly in `setup`, it will only be the initial value from when the widget was first created. When the parent passes in new properties, `setup` does not re-run, so it cannot get the updates.
- **The Solution**: We maintain a `WritableSignal` (`_widgetSignal`) in the `State`. In the `didUpdateWidget` lifecycle method, whenever a new widget instance is passed in, we update this `signal`. The `ComputedRef` returned by the `widget()` API is actually a subscription to this `signal`.

**Conclusion**: The `widget()` API is a clear and efficient balance between the benefits of `setup` running only once (no repeated initialization) and the need to react to property changes. While it adds a slight learning curve, it provides full reactivity and a clear data flow in return.

### Dependency on `alien_signals`

**Trade-off Consideration**:

- **Pros**: `alien_signals` is one of the fastest reactive libraries in the Dart ecosystem. Building on its solid foundation allows us to focus on the high-level API design for Flutter integration without reinventing the wheel.
- **Cons**: The performance of this library is tightly coupled with that of `alien_signals`. It also means our core behavior is constrained by its design.

**Conclusion**: This is a strategic choice. We believe that leveraging a low-level library dedicated to perfecting the reactive core is a wiser choice than building one from scratch. This makes `flutter_compositions` more lightweight and focused.
