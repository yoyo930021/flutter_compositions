# Built-in Composables

`flutter_compositions` provides two categories of composable utilities to help you integrate Flutter objects with the reactive system: **`use*` functions** and **`manage*` functions**.

## Understanding `use*` vs `manage*`

### `use*` Functions - Create and Manage

Functions prefixed with `use` (like `useScrollController`, `useTextEditingController`) **create new instances** and **automatically manage their lifecycle**:

- **Creates**: Returns a new instance of the controller/object
- **Disposes**: Automatically calls `dispose()` when the widget is unmounted
- **Returns**: A reactive `Ref` wrapping the controller

**When to use**: When you need a new controller for your widget.

```dart
// ✅ Use when you need a new controller
final scrollController = useScrollController();
// Automatically disposed on unmount
```

### `manage*` Functions - Integrate Existing

Functions prefixed with `manage` (like `manageValueListenable`, `manageChangeNotifier`) **integrate existing instances** into the reactive system with **automatic lifecycle management**:

- **Requires**: You pass in an existing object
- **Automatic Cleanup**: Always removes listeners on unmount
- **Automatic Disposal** (when applicable):
  - `manageListenable` / `manageValueListenable`: Can't dispose (`Listenable` has no `dispose()`)
  - `manageChangeNotifier`: Automatically calls `dispose()` on unmount
- **Returns**: A reactive `Ref` that syncs with the object

**When to use**: When you have an existing controller/notifier from somewhere else (e.g., inherited from parent, shared state, third-party libraries) that you want to integrate into the reactive system.

```dart
// ✅ Use for Listenable objects (e.g., Animation)
// Automatically removes listener, but can't dispose (Listenable has no dispose method)
final animation = ...; // From AnimationController
final reactiveAnimation = manageListenable(animation);

// ✅ Use for ChangeNotifier objects (e.g., ScrollController)
// Automatically removes listener AND disposes
final controller = ScrollController();
final reactiveController = manageChangeNotifier(controller);
```

## Key Differences

| Feature | `use*` Functions | `manage*` Functions |
|---------|-----------------|---------------------|
| **Creates Instance** | ✅ Yes | ❌ No (you provide it) |
| **Auto Cleanup** | ✅ Always | ✅ Always (removes listeners) |
| **Auto Dispose** | ✅ Always | `manageChangeNotifier`: ✅<br>`manageListenable`: N/A (no dispose method) |
| **Use Case** | New controllers for this widget | Integrate existing objects |
| **Example** | `useScrollController()` | `manageValueListenable(existing)` |

## `useScrollController`

```dart
@override
Widget Function(BuildContext) setup() {
  // Create a ScrollController that will be disposed automatically
  final scrollController = useScrollController();

  // Create a computed property to track the scroll offset
  final scrollOffset = computed(() {
    // This will re-compute when the scrollController notifies listeners
    return scrollController.value.offset;
  });

  // Watch for changes in the scroll position
  watch(() => scrollOffset.value, (offset, _) {
    print('Scrolled to: $offset');
  });

  return (context) => ListView.builder(
    controller: scrollController.value, // Pass the controller to the ListView
    itemCount: 100,
    itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
  );
}
```

## `usePageController`

Create an auto-disposed `PageController` and react to page changes without manual bookkeeping.

```dart
@override
Widget Function(BuildContext) setup() {
  final pageController = usePageController(initialPage: 0);
  final currentPage = ref(0);

  watchEffect(() {
    currentPage.value = pageController.value.page?.round() ?? 0;
  });

  return (context) => Column(
    children: [
      Text('Page: ${currentPage.value}'),
      Expanded(
        child: PageView(
          controller: pageController.value,
          children: const [Page1(), Page2(), Page3()],
        ),
      ),
    ],
  );
}
```

## `useFocusNode`

Manage focus state reactively with automatic disposal.

```dart
@override
Widget Function(BuildContext) setup() {
  final focusNode = useFocusNode();
  final hasFocus = ref(false);

  watchEffect(() {
    hasFocus.value = focusNode.value.hasFocus;
  });

  return (context) => Column(
    children: [
      TextField(
        focusNode: focusNode.value,
        decoration: InputDecoration(
          labelText: hasFocus.value ? 'Focused!' : 'Not focused',
        ),
      ),
      ElevatedButton(
        onPressed: () => focusNode.value.requestFocus(),
        child: const Text('Focus'),
      ),
    ],
  );
}
```

## `useTextEditingController`

This is a powerful utility for handling text input. It not only manages the `TextEditingController`'s lifecycle automatically but also provides two-way binding capabilities.

It returns a record: `(controller, text, value)`

- `controller`: The `TextEditingController` instance to pass to a `TextField`.
- `text`: A writable `ComputedRef<String>` that stays in sync with `controller.text`.
- `value`: A writable `ComputedRef<TextEditingValue>` that stays in sync with `controller.value`.

You can programmatically change the input's content by modifying `text.value`, and you can listen to changes in `text.value` to react to user input.

**Example: Two-Way Binding and Live Validation**

```dart
@override
Widget Function(BuildContext) setup() {
  final (usernameController, username, _) = useTextEditingController(text: 'guest');

  // A computed property for the greeting message
  final greeting = computed(() => 'Hello, ${username.value}!');

  // A computed property for simple validation logic
  final isValid = computed(() => username.value.length >= 3);

  return (context) => Column(
    children: [
      Text(greeting.value),
      TextField(
        controller: usernameController,
        decoration: InputDecoration(
          labelText: 'Username',
          errorText: isValid.value ? null : 'Minimum 3 characters required',
        ),
      ),
      ElevatedButton(
        onPressed: () => username.value = 'default', // Programmatically change the text
        child: const Text('Reset'),
      )
    ],
  );
}
```

## `manageValueListenable`

`manageValueListenable` is a bridge for when you need to integrate with existing `ValueNotifier`s or `ValueListenable`s from legacy code or third-party libraries.

It extracts and tracks the value from any `ValueListenable`, returning a tuple of `(listenable, value)`.

**Automatic Management**: This function automatically removes listeners on unmount. It cannot dispose the listenable because the `ValueListenable` interface doesn't have a `dispose()` method. If you're working with a `ChangeNotifier` (which extends both `Listenable` and has `dispose()`), use `manageChangeNotifier` instead.

**Example: Integrating an Existing `ValueNotifier`**

```dart
// Assume you have a ValueNotifier from another part of your app
final legacyCounter = ValueNotifier(0);

@override
Widget Function(BuildContext) setup() {
  // Integrate the existing ValueNotifier into the reactive system
  // Returns (listenable, value) tuple
  final (notifier, count) = manageValueListenable(legacyCounter);

  final doubled = computed(() => count.value * 2);

  return (context) => Column(
    children: [
      Text('Reactive Doubled: ${doubled.value}'),
      // You can also continue to use it with Flutter's native tools
      ValueListenableBuilder<int>(
        valueListenable: notifier,
        builder: (context, value, child) => Text('Legacy Value: $value'),
      ),
    ],
  );
}
```

**Note**:
- The returned value is **read-only**. To modify it, access the original listenable.
- If you're creating a new `ValueNotifier` specifically for this widget, use `ref()` instead.
- If you need to dispose a `ChangeNotifier`, use `manageChangeNotifier()` instead.
