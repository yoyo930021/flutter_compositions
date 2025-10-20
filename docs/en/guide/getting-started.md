# Getting Started

Welcome to Flutter Compositions! This guide will walk you through the installation and the creation of your first reactive `CompositionWidget`.

## 1. Installation

First, add `flutter_compositions` to your project's `pubspec.yaml` file.

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_compositions: ^0.1.0 # Please use the latest version
```

Then, run `flutter pub get` to install the package.

## 2. Create Your First CompositionWidget

A `CompositionWidget` is the core of `flutter_compositions`. It looks like a `StatelessWidget` but features a `setup()` method that runs only once, where you can define your reactive state.

Let's create a simple counter:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

class CounterWidget extends CompositionWidget {
  const CounterWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // 1. Create a reactive state `count` with an initial value of 0
    final count = ref(0);

    // 2. Create a computed property `doubled` that automatically updates when `count` changes
    final doubled = computed(() => count.value * 2);

    // 3. Return a builder function that rebuilds automatically on reactive state changes
    return (context) => Scaffold(
      appBar: AppBar(title: const Text('Counter Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '${count.value}', // Read the .value directly
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text('The doubled value is: ${doubled.value}'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 4. Modify the .value to trigger an update
          count.value++;
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## Core Concepts Explained

1.  **`CompositionWidget`**: A special widget whose `setup` method runs only once during `initState`. This means your state and business logic are initialized only once, not on every rebuild.

2.  **`ref(initialValue)`**: Creates a Reactive Reference. It's a wrapper object, and you need to access and modify its internal value via the `.value` property. When you modify `.value`, everything that depends on it updates automatically.

3.  **`computed(() => ...)`**: Creates a computed property. It derives its value from its reactive dependencies (like `count.value`). When a dependency changes, the computed's value updates, triggering a rebuild of the UI that uses it.

4.  **The `builder` function**: The return value of `setup()` is a `Widget Function(BuildContext)`. This function is like the `build` method of a `StatelessWidget`, but it's wrapped in a reactive `effect`. This means it only re-executes when a reactive state used inside it (like `count.value`) changes, enabling fine-grained UI updates.

## 3. Use Your Widget

You can now use `CounterWidget` just like any other Flutter widget:

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CounterWidget(),
    );
  }
}
```

That's it! You've created a fully functional, reactive widget without ever using a `StatefulWidget` or `setState()`.

In the next chapter, we'll dive deeper into the core concepts of a `Composition`.
