# Flutter Compositions

[![Test](https://github.com/yoyo930021/flutter_compositions/actions/workflows/test.yml/badge.svg)](https://github.com/yoyo930021/flutter_compositions/actions/workflows/test.yml)
[![Documentation](https://github.com/yoyo930021/flutter_compositions/actions/workflows/docs.yml/badge.svg)](https://github.com/yoyo930021/flutter_compositions/actions/workflows/docs.yml)
[![pub package](https://img.shields.io/pub/v/flutter_compositions.svg)](https://pub.dev/packages/flutter_compositions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Vue-inspired reactive building blocks for Flutter

Flutter Compositions brings Vue 3's Composition API patterns to Flutter, enabling fine-grained reactivity and composable logic with a clean, declarative API.

## Documentation

**📚 [Read the full documentation →](https://yoyo930021.github.io/flutter_compositions/)**

- **[Getting Started](https://yoyo930021.github.io/flutter_compositions/guide/getting-started)** - Quick start guide and installation
- **[Guide](https://yoyo930021.github.io/flutter_compositions/guide/what-is-a-composition)** - Learn core concepts and patterns
- **[API Reference](https://pub.dev/documentation/flutter_compositions/latest/)** - Complete API documentation
- **[Internals](https://yoyo930021.github.io/flutter_compositions/internals/architecture)** - Architecture and design decisions

## Packages

This repository uses a Melos-managed monorepo layout:

| Package | Description | Version |
|---------|-------------|---------|
| **[flutter_compositions](./packages/flutter_compositions)** | Core reactive composition primitives for Flutter | [![pub](https://img.shields.io/pub/v/flutter_compositions.svg)](https://pub.dev/packages/flutter_compositions) |
| **[flutter_compositions_lints](./packages/flutter_compositions_lints)** | Custom lint rules to enforce best practices | [![pub](https://img.shields.io/pub/v/flutter_compositions_lints.svg)](https://pub.dev/packages/flutter_compositions_lints) |

## Quick Example

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

    // Return builder
    return (context) => Scaffold(
          appBar: AppBar(title: const Text('Counter')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Count: ${count.value}'),
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

## Features

- **Vue-inspired API** - Familiar `ref`, `computed`, `watch`, and `watchEffect`
- **Fine-grained reactivity** - Powered by [`alien_signals`](https://pub.dev/packages/alien_signals)
- **Composable logic** - Extract and reuse stateful logic with custom composables
- **Type-safe DI** - `provide`/`inject` with `InjectionKey`
- **Built-in composables** - Controllers, animations, async data, and more
- **Zero boilerplate** - Single `setup()` function replaces multiple lifecycle methods
- **Lint rules** - Custom lints enforce best practices

## Development

This is a Melos monorepo. To get started:

```bash
# Install Melos
flutter pub global activate melos

# Bootstrap the workspace
melos bootstrap

# Run tests across all packages
melos run test

# Run analysis
melos run analyze
```

### Running the Example App

```bash
cd packages/flutter_compositions/example
flutter run
```

## For AI / LLM Users

This project provides [llms.txt](https://yoyo930021.github.io/flutter_compositions/llms.txt) and [llms-full.txt](https://yoyo930021.github.io/flutter_compositions/llms-full.txt) following the [llms.txt standard](https://llmstxt.org/) to help AI assistants understand and use this library effectively.

- **`llms.txt`** — A concise guide with core concepts, API patterns, and best practices
- **`llms-full.txt`** — Complete documentation content for in-depth reference

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

Flutter Compositions is built upon excellent work from the open source community:

- **[alien_signals](https://pub.dev/packages/alien_signals)** - Provides the core reactivity system with fine-grained signal-based state management
- **[flutter_hooks](https://pub.dev/packages/flutter_hooks)** - Inspired composable patterns and demonstrated the viability of composition APIs in Flutter

We are grateful to these projects and their maintainers for paving the way.

## License

MIT © 2025
