# Why Choose Flutter Compositions

Flutter already offers many state-management and composition tools. Why add Flutter Compositions to the stack? This guide condenses the core advantages so you can quickly decide if it fits your project.

## 1. Developer Experience: Vue-like, but for Flutter

- `setup()` centralizes state initialization, computed values, and lifecycle hooks.  
- APIs (`ref()`, `computed()`, `watch()`) mirror the Vue Composition API, lowering the learning curve for frontend developers.  
- `CompositionBuilder` brings the same reactive experience to inline/one-off usages.

## 2. Fine-Grained Reactivity

Backed by `alien_signals`, reading `.value` registers dependencies automatically:

- Builders re-run only when a referenced `Ref` or `ComputedRef` changes.  
- Wrap hot spots with `ComputedBuilder` to reduce rebuilds to the absolute minimum.  
- `provide` / `inject` propagate reactive `Ref`s without propagating rebuilds through the widget tree.

## 3. Lifecycle and Resource Management

| Feature | Flutter Compositions | Result |
|---------|---------------------|--------|
| Lifecycle hooks | `onMounted`, `onUnmounted`, `onBuild` | Easy-to-test, consistent with Vue naming |
| Controller helpers | `useScrollController`, `useAnimationController`, … | Auto-dispose at unmount, less boilerplate |
| Effect cleanup | Tied to `_SetupContext` | No forgotten subscriptions |

## 4. Built-in, Type-Safe Dependency Injection

- `InjectionKey<T>` acts as the lookup key, so `provide` / `inject` can pass `Ref<T>` or any object while staying reactive.  
- Generics participate in equality checks, preventing mismatched keys at compile time and runtime.  
- Works out of the box, yet remains compatible with Riverpod, GetIt, and other DI solutions.

## 5. Hot Reload & State Preservation

- Each `Ref` keeps a stable position inside `setup()`. As long as the declaration order stays intact, hot reload preserves state.  
- Builders rely on reactive signals, so only affected areas refresh after a reload.

## 6. Snapshot vs. Alternatives

| Need | Flutter Compositions | flutter_hooks | Provider / BLoC |
|------|----------------------|---------------|------------------|
| Vue-like syntax | ✅ almost identical | ⭕ conceptually similar | ❌ |
| Fine-grained updates | ✅ built-in signals | ⭕ manual widget splitting | ❌ whole subtree rebuild |
| Auto controller disposal | ✅ yes | ⭕ depends on hook cleanup | ❌ manual |
| Dependency injection | ✅ built-in provide/inject | ⭕ external package | ⭕ external package |
| Ecosystem maturity | ⭕ growing | ✅ very mature | ✅ very mature |

For detailed breakdowns:
- [Flutter Compositions vs flutter_hooks](/en/guide/flutter-hooks-comparison)  
- [Flutter Compositions vs Vue Composition API](/en/guide/vue-comparison)

## 7. When It Shines

✅ You want a development model that feels like Vue Composition API.  
✅ Performance matters and you need to avoid unnecessary rebuilds.  
✅ Controllers, subscriptions, or effects must be consistently disposed.  
✅ You value type-safe dependency injection without extra packages.  
✅ The project targets multiple platforms but you want a unified reactive style.

## 8. When to Think Twice

❌ The app is tiny and `setState` already covers your needs.  
❌ The team is deeply invested in `flutter_hooks`, BLoC, or Redux with heavy custom tooling.  
❌ You prefer external/global state managers to drive the entire app.

## 9. Adoption Checklist

1. Identify key screens that can migrate to `CompositionWidget` or `CompositionBuilder`.  
2. Wrap recurring resources into reusable `use*` composables.  
3. Replace manual prop drilling with `provide` / `inject` where appropriate.  
4. Encapsulate hot spots with `ComputedBuilder` or dedicated reusable widgets.  
5. Follow the [Creating Your Own Composables](/en/guide/creating-composables) guide to build an internal library.

---

If you’re searching for a Flutter-native way to enjoy Vue-style composition, Flutter Compositions delivers precise reactivity, consistent lifecycle handling, and built-in DI. Master `setup()`, `ref()`, and `provide/inject`, and you’ll unlock a clean, maintainable architecture across mobile, desktop, and web.
