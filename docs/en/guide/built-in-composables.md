# Built-in Composables

`flutter_compositions` not only provides the core reactive APIs but also includes a series of utility functions prefixed with `use`, which we call "Composables." These functions are designed to encapsulate common logic related to Flutter-specific objects (like controllers), especially for automatic lifecycle management.

The main benefits of using these `use` functions are:

1.  **Automatic Disposal**: You no longer need to manually call `controller.dispose()` in a `dispose` method. The `use` function handles it for you automatically in `onUnmounted`.
2.  **Reactivity Integration**: They often return a reactive `Ref` or `ComputedRef`, allowing you to easily use the controller's state within `computed` or `watch` effects.

## `useController<T extends ChangeNotifier>`

This is a generic utility for managing any controller that extends `ChangeNotifier`. It automatically handles disposal and returns a `ComputedRef<T>` that updates whenever the controller calls `notifyListeners()`.

`useScrollController`, `usePageController`, and `useFocusNode` are all specialized versions built on top of `useController`.

**Example: Using `useScrollController`**

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

## `useValueNotifier`

`useValueNotifier` is a bridge for when you need to integrate with existing `ValueNotifier`s or legacy code that uses `ValueListenableBuilder`.

It converts a `ValueNotifier<T>` into a writable `ComputedRef<T>`, enabling two-way synchronization between them.

**Example: Bridging a `ValueNotifier`**

```dart
// Assume you have a ValueNotifier from another part of your app
final legacyCounter = ValueNotifier(0);

@override
Widget Function(BuildContext) setup() {
  // Convert the ValueNotifier into a reactive Ref
  // `disposeNotifier: true` will automatically dispose the passed-in notifier on unmount
  final count = useValueNotifier(legacyCounter, disposeNotifier: false);

  final doubled = computed(() => count.value * 2);

  return (context) => Column(
    children: [
      Text('Reactive Doubled: ${doubled.value}'),
      ElevatedButton(
        onPressed: () => count.value++, // Modifying the Ref syncs back to the ValueNotifier
        child: const Text('Increment'),
      ),
      // You can also continue to use it with Flutter's native tools
      ValueListenableBuilder<int>(
        valueListenable: legacyCounter,
        builder: (context, value, child) => Text('Legacy Value: $value'),
      ),
    ],
  );
}
```
