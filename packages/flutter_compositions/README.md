# Flutter Compositions

> Vue-inspired reactive building blocks for Flutter

[![pub package](https://img.shields.io/pub/v/flutter_compositions.svg)](https://pub.dev/packages/flutter_compositions)
[![Test](https://github.com/yoyo930021/flutter_compositions/actions/workflows/test.yml/badge.svg)](https://github.com/yoyo930021/flutter_compositions/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Flutter Compositions brings Vue 3's Composition API patterns to Flutter, enabling fine-grained reactivity and composable logic with a clean, declarative API.

## Documentation

**📚 [Read the full documentation →](https://yoyo930021.github.io/flutter_compositions/)**

- **[Getting Started](https://yoyo930021.github.io/flutter_compositions/en/guide/getting-started)** - Quick start guide and installation
- **[Guide](https://yoyo930021.github.io/flutter_compositions/en/guide/what-is-a-composition)** - Learn core concepts and patterns
- **[API Reference](https://pub.dev/documentation/flutter_compositions/latest/)** - Complete API documentation
- **[Internals](https://yoyo930021.github.io/flutter_compositions/en/internals/architecture)** - Architecture and design decisions

## Features

- ✨ **Vue-inspired API** - Familiar `ref`, `computed`, `watch`, and `watchEffect` for reactive state
- 🎯 **Fine-grained reactivity** - Powered by [`alien_signals`](https://pub.dev/packages/alien_signals) for minimal rebuilds
- 🔧 **Composable logic** - Extract and reuse stateful logic with custom composables
- 💉 **Type-safe DI** - `provide`/`inject` with `InjectionKey` for zero conflicts
- 🎨 **Flutter integration** - Built-in composables for controllers, animations, async data, and more
- 📦 **Zero boilerplate** - Single `setup()` function replaces `initState`, `dispose`, and `didUpdateWidget`
- 🛡️ **Lint rules** - Custom lints enforce reactivity best practices

## Installation

```yaml
dependencies:
  flutter_compositions: ^0.1.0

dev_dependencies:
  flutter_compositions_lints: ^0.1.0
  custom_lint: ^0.7.0
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

class CounterPage extends CompositionWidget {
  const CounterPage({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Reactive state
    final count = ref(0);
    final doubled = computed(() => count.value * 2);

    // Side effects
    watch(() => count.value, (value, previous) {
      debugPrint('count: $previous → $value');
    });

    // Lifecycle
    onMounted(() => debugPrint('Mounted!'));

    // Return builder
    return (context) => Scaffold(
          appBar: AppBar(title: const Text('Counter')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Count: ${count.value}', style: Theme.of(context).textTheme.headlineMedium),
                Text('Doubled: ${doubled.value}'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => count.value++,
            child: const Icon(Icons.add),
          ),
        );
  }
}
```

## Core Concepts

### Reactive State

```dart
// Writable ref
final count = ref(0);
count.value++; // Updates trigger rebuilds

// Computed (derived state)
final doubled = computed(() => count.value * 2);

// Writable computed
final userName = writableComputed(
  getter: (get) => get(firstName) + ' ' + get(lastName),
  setter: (value, set) {
    final parts = value.split(' ');
    set(firstName, parts[0]);
    set(lastName, parts[1]);
  },
);
```

### Side Effects

```dart
// Watch specific values
watch(
  () => count.value,
  (newValue, oldValue) {
    print('Changed: $oldValue → $newValue');
  },
);

// Watch effect (auto-tracks dependencies)
watchEffect(() {
  print('Count or doubled changed: ${count.value}, ${doubled.value}');
});
```

### Reactive Props

```dart
class UserCard extends CompositionWidget {
  const UserCard({super.key, required this.userId, required this.name});

  final String userId;
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget(); // Reactive access to widget instance

    // Reacts to prop changes
    final greeting = computed(() => 'Hello, ${props.value.name}!');

    watch(() => props.value.userId, (newId, oldId) {
      debugPrint('User changed: $oldId → $newId');
    });

    return (context) => Text(greeting.value);
  }
}
```

### Dependency Injection

```dart
// Define keys (usually as global constants)
final themeKey = InjectionKey<Ref<AppTheme>>('theme');

// Provider
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(AppTheme.dark());
    provide(themeKey, theme);
    return (context) => MaterialApp(home: HomePage());
  }
}

// Consumer
class ThemedButton extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = inject(themeKey);
    return (context) => ElevatedButton(
      style: ButtonStyle(backgroundColor: MaterialStateProperty.all(theme.value.primary)),
      child: Text('Button'),
    );
  }
}
```

## Built-in Composables

### Controllers

```dart
// ScrollController with auto-disposal
final scrollController = useScrollController();

// TextEditingController with reactive text
final (controller, text, selection) = useTextEditingController(text: 'Hello');
final upperText = computed(() => text.value.toUpperCase());

// Other controllers
final pageController = usePageController();
final focusNode = useFocusNode();
```

### Animations

```dart
// AnimationController with auto-disposal and reactive value
final (controller, animValue) = useAnimationController(
  duration: Duration(seconds: 2),
);

onMounted(() => controller.repeat());

// Use in builder
return (context) => Transform.rotate(
  angle: animValue.value * 2 * pi,
  child: Icon(Icons.refresh),
);
```

### Async Operations

```dart
// Future with state tracking
final userData = useFuture(() => fetchUser(userId));

return (context) {
  return switch (userData.value) {
    AsyncLoading() => CircularProgressIndicator(),
    AsyncError(:final errorValue) => Text('Error: $errorValue'),
    AsyncData(:final value) => Text('User: ${value.name}'),
    AsyncIdle() => SizedBox.shrink(),
  };
};

// Async data with watch and refresh
final (status, refresh) = useAsyncData<User, int>(
  (userId) => api.fetchUser(userId),
  watch: () => userId.value, // Auto-refetch on userId change
);

// Stream tracking
final count = useStream(
  Stream.periodic(Duration(seconds: 1), (i) => i),
  initialValue: 0,
);
```

### Framework Integration

```dart
// App lifecycle
final lifecycleState = useAppLifecycleState();

watch(() => lifecycleState.value, (state, _) {
  if (state == AppLifecycleState.paused) {
    saveState();
  }
});

// Search controller
final searchController = useSearchController();
final searchText = computed(() => searchController.value.text);
```

## Custom Composables

Extract reusable logic into composables:

```dart
// Define composable
(Ref<int>, void Function()) useCounter({int initialValue = 0}) {
  final count = ref(initialValue);

  void increment() => count.value++;

  return (count, increment);
}

// Use in widgets
class CounterWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (count, increment) = useCounter(initialValue: 10);

    return (context) => ElevatedButton(
      onPressed: increment,
      child: Text('Count: ${count.value}'),
    );
  }
}
```

## Lint Rules

Enable custom lints to enforce best practices:

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  enable_all_lint_rules: true
```

Available rules:
- `flutter_compositions_ensure_reactive_props` - Ensure reactive prop access via `widget()`
- `flutter_compositions_no_async_setup` - Prevent async setup methods
- `flutter_compositions_controller_lifecycle` - Ensure proper controller disposal
- `flutter_compositions_no_mutable_fields` - Enforce immutable widget fields
- `flutter_compositions_provide_inject_type_match` - Warn against common type conflicts

[See all lint rules →](https://yoyo930021.github.io/flutter_compositions/lints/rules)

## Examples

Check out the example app for more patterns:

```bash
cd packages/flutter_compositions/example
flutter run
```

## Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) first.

## Acknowledgments

Flutter Compositions is built upon excellent work from the open source community:

- **[alien_signals](https://pub.dev/packages/alien_signals)** - Provides the core reactivity system with fine-grained signal-based state management
- **[flutter_hooks](https://pub.dev/packages/flutter_hooks)** - Inspired composable patterns and demonstrated the viability of composition APIs in Flutter

We are grateful to these projects and their maintainers for paving the way.

## License

MIT © 2025
