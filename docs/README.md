# Flutter Compositions Documentation

Welcome to the Flutter Compositions documentation! This guide will help you build reactive Flutter applications with Vue-inspired composition patterns.

## Getting Started

New to Flutter Compositions? Start here:

- **[What is a Composition?](./guide/what-is-a-composition.md)** - Core concepts and philosophy
- **[Getting Started](./guide/getting-started.md)** - Installation and first app
- **[Built-in Composables](./guide/built-in-composables.md)** - Overview of provided composables
- **[Creating Composables](./guide/creating-composables.md)** - Build your own composables

## Guides

### Core Concepts

- **[Reactivity Fundamentals](./en/guide/reactivity-fundamentals.md)** - Complete guide to reactive state management
- **[Understanding Compositions](./guide/what-is-a-composition.md)** - Deep dive into composition patterns
- **[Built-in Composables](./guide/built-in-composables.md)** - Overview of provided composables

### Migration & Comparison

- **[From StatefulWidget](./en/guide/from-stateful-widget.md)** - Side-by-side comparison and migration guide
- [Creating Composables](./guide/creating-composables.md) - Build custom reusable logic

### Common Patterns

- Form Handling - Building reactive forms
- Async Operations - Handling futures and streams
- Animations - Reactive animations
- State Management - Managing app state
- Best Practices - Recommended patterns and anti-patterns

## API Reference

Complete API documentation for all exports:

### Core APIs

- **[Reactivity](./api/reactivity.md)** - `ref`, `computed`, `writableComputed`
- **[Watch](./api/watch.md)** - `watch`, `watchEffect`
- **[Custom Ref](./api/custom-ref.md)** - `customRef`, `ReadonlyCustomRef`
- **[CompositionWidget](./api/composition-widget.md)** - Base widget class
- **[Lifecycle](./api/lifecycle.md)** - `onMounted`, `onUnmounted`, `onBuild`
- **[Provide/Inject](./api/provide-inject.md)** - Dependency injection
- **[InjectionKey](./api/injection-key.md)** - Type-safe injection keys

### Composables

- **[Controllers](./api/composables/controllers.md)** - `useScrollController`, `useTextEditingController`, etc.
- **[Animations](./api/composables/animations.md)** - `useAnimationController`, `useSingleTickerProvider`
- **[Async](./api/composables/async.md)** - `useFuture`, `useAsyncData`, `useStream`
- **[Listenable](./api/composables/listenable.md)** - `manageListenable`, `manageValueListenable`
- **[Framework](./api/composables/framework.md)** - `useContext`, `useAppLifecycleState`

### Types

- **[Ref Types](./api/types/refs.md)** - `Ref`, `ComputedRef`, `WritableRef`, etc.
- **[AsyncValue](./api/types/async-value.md)** - `AsyncIdle`, `AsyncLoading`, `AsyncData`, `AsyncError`

### Utilities

- **[ComputedBuilder](./api/utilities/computed-builder.md)** - Builder widget for computed values
- **[CompositionBuilder](./api/composition-builder.md)** - Functional composition API

## Lints

Custom lint rules to enforce best practices:

- **[Lint Overview](./lints/README.md)** - Installation and configuration
- **[Lint Rules](./lints/rules.md)** - Complete rules reference

### 快速開始

```yaml
# pubspec.yaml
dev_dependencies:
  custom_lint: ^0.7.0
  flutter_compositions_lints: ^0.1.0
```

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  enable_all_lint_rules: true
```

### 常用指令

```bash
dart run custom_lint          # 執行一次性分析
dart run custom_lint --watch  # 監聽檔案變更
dart run custom_lint --fix    # 套用可自動修復的規則
```

### Quick Lint Reference

| Rule | Description |
|------|-------------|
| `ensure_reactive_props` | Ensure props accessed via `widget()` |
| `no_async_setup` | Prevent async setup methods |
| `controller_lifecycle` | Ensure controller disposal |
| `no_mutable_fields` | Enforce immutable fields |

## Internals

Deep dive into implementation details for advanced engineers:

- **[Technical Deep Dive](./en/internals/technical-deep-dive.md)** - Complete technical overview
- **[Architecture](./internals/architecture.md)** - Internal architecture overview
- **[Reactivity In-Depth](./internals/reactivity-in-depth.md)** - How reactivity system works
- **[Performance](./internals/performance.md)** - Performance characteristics and benchmarks
- **[Design Trade-offs](./internals/design-trade-offs.md)** - Design decisions explained

## Examples

### Quick Examples

#### Basic Counter

```dart
class CounterPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    return (context) => Scaffold(
      body: Center(child: Text('${count.value}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

#### Async Data Fetching

```dart
class UserPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final userId = ref(1);
    final (status, _) = useAsyncData<User, int>(
      (id) => api.fetchUser(id),
      watch: () => userId.value,
    );

    return (context) => switch (status.value) {
      AsyncLoading() => CircularProgressIndicator(),
      AsyncData(:final value) => UserCard(user: value),
      AsyncError(:final errorValue) => Text('Error: $errorValue'),
      _ => SizedBox.shrink(),
    };
  }
}
```

#### Custom Composable

```dart
(Ref<int>, void Function()) useCounter({int initial = 0}) {
  final count = ref(initial);
  void increment() => count.value++;
  return (count, increment);
}

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (count, increment) = useCounter(initial: 10);
    return (context) => ElevatedButton(
      onPressed: increment,
      child: Text('${count.value}'),
    );
  }
}
```

### Full Example App

Check out the complete example app:

```bash
cd packages/flutter_compositions/example
flutter run
```

## Community

- **GitHub**: [flutter_compositions](https://github.com/yourusername/flutter_compositions)
- **Issues**: [Report bugs or request features](https://github.com/yourusername/flutter_compositions/issues)
- **Pub.dev**: [flutter_compositions](https://pub.dev/packages/flutter_compositions)

## Contributing

We welcome contributions! See our [contributing guidelines](./CONTRIBUTING.md) for details.

## Acknowledgments

Flutter Compositions is built upon excellent work from the open source community:

- **[alien_signals](https://pub.dev/packages/alien_signals)** - Provides the core reactivity system with fine-grained signal-based state management
- **[flutter_hooks](https://pub.dev/packages/flutter_hooks)** - Inspired composable patterns and demonstrated the viability of composition APIs in Flutter

We are grateful to these projects and their maintainers for paving the way.

## License

MIT © 2025

---

## Navigation

### By Task

- **Building UI**: [Getting Started](./guide/getting-started.md), [Reactivity](./guide/reactivity.md)
- **Managing State**: [State Management](./guide/state-management.md), [Ref API](./api/reactivity.md)
- **Async Operations**: [Async Guide](./guide/async-operations.md), [Async API](./api/composables/async.md)
- **Animations**: [Animation Guide](./guide/animations.md), [Animation API](./api/composables/animations.md)
- **Forms**: [Form Handling](./guide/forms.md), [Controller API](./api/composables/controllers.md)
- **Dependency Injection**: [DI Guide](./guide/dependency-injection.md), [Provide/Inject API](./api/provide-inject.md)

### By Experience Level

#### Beginner (New to Flutter Compositions)

Start here if you're new to the framework:

1. **[Getting Started](./en/guide/getting-started.md)** - Install and create your first widget (15 min)
2. **[What is a Composition?](./en/guide/what-is-a-composition.md)** - Core concepts: props, lifecycle, DI (20 min)
3. **[Reactivity Fundamentals](./en/guide/reactivity-fundamentals.md)** - Master ref, computed, watch (30 min)
4. **[Built-in Composables](./guide/built-in-composables.md)** - Learn provided helpers (20 min)

**Time to proficiency**: ~1.5 hours

#### Intermediate (Familiar with Basics)

Ready to build real applications:

1. **[From StatefulWidget](./en/guide/from-stateful-widget.md)** - Migration patterns and comparisons (30 min)
2. **[Creating Composables](./guide/creating-composables.md)** - Extract reusable logic (25 min)
3. **[Async Operations](./api/composables/async.md)** - Handle futures and streams (30 min)
4. **[Lint Rules](./lints/)** - Enforce best practices (15 min)

**Time to proficiency**: ~1.5 hours

#### Advanced (Production Applications)

Deep technical understanding for complex scenarios:

1. **[Technical Deep Dive](./en/internals/technical-deep-dive.md)** - Complete architecture overview (45 min)
2. **[Reactivity In-Depth](./internals/reactivity-in-depth.md)** - Signal system internals (30 min)
3. **[Performance](./internals/performance.md)** - Optimization strategies (25 min)
4. **[Design Trade-offs](./internals/design-trade-offs.md)** - Why design choices were made (20 min)

**Time to mastery**: ~2 hours
