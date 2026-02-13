# Introduction

## What is Flutter Compositions?

Flutter Compositions is a reactive framework for Flutter inspired by [Vue's Composition API](https://vuejs.org/guide/extras/composition-api-faq.html). It replaces `StatefulWidget` boilerplate with a declarative, signal-based programming model built on [`alien_signals`](https://pub.dev/packages/alien_signals).

At its core, you write a `setup()` method that runs **once**, declare reactive state with `ref()`, derive values with `computed()`, and return a builder function that automatically re-runs when dependencies change:

```dart
class Counter extends CompositionWidget {
  const Counter({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    final doubled = computed(() => count.value * 2);

    return (context) => Column(
      children: [
        Text('Count: ${count.value}'),
        Text('Doubled: ${doubled.value}'),
        ElevatedButton(
          onPressed: () => count.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

No `State` class. No `setState()`. No manual `dispose()`. Just reactive state and a builder.

## Why Choose Flutter Compositions?

### 1. Fine-Grained Reactivity

Backed by `alien_signals`, reading `.value` registers dependencies automatically. Only the widgets that touch a modified ref rebuild — no unnecessary subtree reconstructions.

### 2. Vue-like Developer Experience

APIs (`ref()`, `computed()`, `watch()`) mirror the Vue Composition API, lowering the learning curve for frontend developers. `setup()` centralizes state initialization, computed values, and lifecycle hooks.

### 3. Lifecycle and Resource Management

| Feature | What it does |
|---------|-------------|
| `onMounted` / `onUnmounted` / `onBuild` | Declarative lifecycle hooks |
| `useScrollController`, `useAnimationController`, … | Auto-dispose controllers |
| Effect cleanup via `effectScope` | No forgotten subscriptions |

### 4. Built-in Type-Safe Dependency Injection

`InjectionKey<T>` powers `provide` / `inject` — pass `Ref<T>` or any object while staying reactive and type-safe. Works out of the box, yet remains compatible with Riverpod, GetIt, and other DI solutions.

### 5. Hot Reload & State Preservation

Each `Ref` keeps a stable position inside `setup()`. As long as the declaration order stays intact, hot reload preserves state. Builders rely on reactive signals, so only affected areas refresh after a reload.

## How Does It Compare?

### vs. `StatefulWidget`

| Aspect | StatefulWidget | Flutter Compositions |
|--------|---------------|---------------------|
| State declaration | Separate `State` class | Inline in `setup()` |
| Rebuilds | `setState()` rebuilds entire subtree | Only refs that changed |
| Prop changes | Manual `didUpdateWidget` | Automatic via `widget()` |
| Controllers | Manual `dispose()` | Auto-disposed `use*` helpers |

See the full [migration guide](./from-stateful-widget.md).

### vs. `flutter_hooks`

| Aspect | Flutter Compositions | flutter_hooks |
|--------|---------------------|---------------|
| Mental model | Vue Composition API | React Hooks |
| Reactivity | Fine-grained signals | Full `build` re-run |
| DI | Built-in `provide`/`inject` | External packages |
| Lifecycle | `onMounted`, `onUnmounted` | `useEffect` callbacks |

### vs. Vue Composition API

| Aspect | Flutter Compositions | Vue |
|--------|---------------------|-----|
| Rendering | Flutter widget tree | Virtual DOM / templates |
| Reactivity engine | `alien_signals` (explicit refs) | Proxy-based (deep by default) |
| Props | `widget()` returns `ComputedRef` | Props are reactive proxies |
| DI keys | `InjectionKey<T>` (compile-time safe) | String/Symbol keys |

## When It Shines

- You want a development model that feels like Vue Composition API.
- Performance matters and you need to avoid unnecessary rebuilds.
- Controllers, subscriptions, or effects must be consistently disposed.
- You value type-safe dependency injection without extra packages.
- The project targets multiple platforms but you want a unified reactive style.

## When to Think Twice

- The app is tiny and `setState` already covers your needs.
- The team is deeply invested in `flutter_hooks`, BLoC, or Redux with heavy custom tooling.
- You prefer external/global state managers to drive the entire app.

## Next Steps

- [Quick Start](./getting-started.md) — install and build your first widget
- [The Composition Widget](./composition-widget.md) — deep dive into `CompositionWidget` and `CompositionBuilder`
- [Reactivity Fundamentals](./reactivity-fundamentals.md) — understand `ref`, `computed`, and reactive collections
