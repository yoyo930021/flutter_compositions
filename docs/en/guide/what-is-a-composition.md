# Understanding the Composition API

In "Getting Started," you saw the basic usage of `CompositionWidget`. Now, let's dive deeper into its powerful features: Props, Lifecycle, and Dependency Injection.

## The Golden Rule of `setup()`

The `setup()` method is the heart of a `CompositionWidget`, but you must remember this golden rule:

> `setup()` runs only once in the widget's lifecycle (equivalent to `StatefulWidget`'s `initState`).

This means you can safely initialize state, create controllers, and register listeners here without worrying about them being recreated on every widget rebuild.

Conversely, the `builder` function returned from `setup()` will be re-executed whenever any of its reactive dependencies change.

## Reactive Props

If `setup` only runs once, how do we react to property changes from a parent widget? Accessing `widget.myProp` directly in `setup` is **ineffective**, as it will only read the initial value.

The correct answer is to use the `widget()` API.

The `widget()` function returns a reactive `ComputedRef` that always represents the **latest** widget instance. When the parent widget rebuilds and passes new props, this `ComputedRef` triggers an update.

Let's look at a `UserCard` example:

```dart
class UserCard extends CompositionWidget {
  const UserCard({super.key, required this.name});

  final String name;

  @override
  Widget Function(BuildContext) setup() {
    // ✅ CORRECT: Get a reactive reference to props using widget()
    final props = widget();

    // ❌ WRONG: Direct access to this.name or name is NOT reactive!
    // final greeting = computed(() => 'Hello, $name');

    // `greeting` will automatically update when `props.value.name` changes
    final greeting = computed(() => 'Hello, ${props.value.name}!');

    // Watch for changes to the name property
    watch(() => props.value.name, (newName, oldName) {
      print('Name changed from $oldName to $newName');
    });

    return (context) => Text(greeting.value);
  }
}
```

**Key takeaway**: Always access props via `widget().value.yourProp` to ensure your `computed` and `watch` effects react correctly to changes.

## Lifecycle Hooks

`flutter_compositions` provides Vue-like lifecycle hooks that let you attach logic to the component's lifecycle from within `setup`.

- `onMounted(callback)`: Executes after the widget is mounted on the screen (in the first frame after `initState`). Ideal for making network requests, initializing controllers that need a `BuildContext`, etc.
- `onUnmounted(callback)`: Executes just before the widget is destroyed (during `dispose`). This is the perfect place to clean up controllers, cancel subscriptions, and release resources.

```dart
@override
Widget Function(BuildContext) setup() {
  final myController = useController(AnimationController());

  onMounted(() {
    print('Widget is mounted!');
    myController.value.forward();
  });

  onUnmounted(() {
    print('Widget is unmounted, cleaning up.');
    // `useController` disposes automatically, but this is for demonstration
    // myController.value.dispose();
  });

  return (context) => /* ... */;
}
```

## Dependency Injection (Provide / Inject)

When you need to pass data down the component tree without passing it through constructors at every level, you can use `provide` and `inject`. This is similar to the Provider package but is more lightweight and type-safe.

- `provide(value)`: Makes a value available to all descendant `CompositionWidget`s.
- `inject<T>()`: Retrieves a value of type `T` from an ancestor `CompositionWidget`.

This mechanism is **type-based**, so it's recommended to use custom classes as keys to avoid conflicts.

**Example: Providing a Theme State**

```dart
// 1. Define a custom data class
class AppTheme {
  AppTheme(this.mode);
  String mode;
}

// 2. Provide a reactive state in the parent widget
class ThemeProvider extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(AppTheme('light'));
    provide(theme); // Type is automatically inferred as Ref<AppTheme>

    return (context) => Column(
      children: [
        // ... button to toggle theme ...
        const ThemeDisplay(),
      ],
    );
  }
}

// 3. Inject it in a child widget
class ThemeDisplay extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // Inject by type - fully type-safe!
    final theme = inject<Ref<AppTheme>>();

    return (context) => Text('Current mode: ${theme.value.mode}');
  }
}
```

A major advantage of `provide`/`inject` is that it doesn't cause unnecessary widget rebuilds. Only the `builder` that actually `inject`s and uses the reactive value will update when the value changes.
