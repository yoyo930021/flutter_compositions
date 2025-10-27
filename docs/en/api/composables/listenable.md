# Listenable Composables

Composables for managing Flutter `Listenable` objects with automatic disposal.

## manageListenable

Manage a `Listenable` with automatic listener cleanup.

### Signature

```dart
T manageListenable<T extends Listenable>(
  T listenable,
  void Function() listener,
)
```

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final scrollController = ScrollController();
  final scrollOffset = ref(0.0);

  manageListenable(scrollController, () {
    scrollOffset.value = scrollController.offset;
  });

  onUnmounted(() => scrollController.dispose());

  return (context) => Column(
    children: [
      Text('Offset: ${scrollOffset.value}'),
      Expanded(
        child: ListView.builder(
          controller: scrollController,
          itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
        ),
      ),
    ],
  );
}
```

## manageValueListenable

Manage a `ValueListenable` and return a reactive ref.

### Signature

```dart
Ref<T> manageValueListenable<T>(ValueListenable<T> valueListenable)
```

### Returns

`Ref<T>` - Reactive reference that updates when the ValueListenable changes

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final controller = TextEditingController();
  final text = manageValueListenable(controller);

  onUnmounted(() => controller.dispose());

  final wordCount = computed(() => text.value.split(' ').length);

  return (context) => Column(
    children: [
      TextField(controller: controller),
      Text('Text: ${text.value}'),
      Text('Words: ${wordCount.value}'),
    ],
  );
}
```

## manageChangeNotifier

Manage a `ChangeNotifier` with automatic disposal.

### Signature

```dart
T manageChangeNotifier<T extends ChangeNotifier>(
  T notifier,
  void Function() listener,
)
```

### Example

```dart
class MyModel extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

@override
Widget Function(BuildContext) setup() {
  final model = MyModel();
  final count = ref(0);

  manageChangeNotifier(model, () {
    count.value = model.count;
  });

  return (context) => Column(
    children: [
      Text('Count: ${count.value}'),
      ElevatedButton(
        onPressed: model.increment,
        child: Text('Increment'),
      ),
    ],
  );
}
```

## Integration with Existing Code

### Wrapping ChangeNotifier

```dart
@override
Widget Function(BuildContext) setup() {
  final authService = inject(authServiceKey); // ChangeNotifier
  final isAuthenticated = ref(authService.isAuthenticated);

  manageChangeNotifier(authService, () {
    isAuthenticated.value = authService.isAuthenticated;
  });

  return (context) => Text(
    isAuthenticated.value ? 'Logged in' : 'Logged out',
  );
}
```

### Wrapping ValueNotifier

```dart
@override
Widget Function(BuildContext) setup() {
  final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
  final theme = manageValueListenable(themeNotifier);

  onUnmounted(() => themeNotifier.dispose());

  return (context) => Column(
    children: [
      Text('Theme: ${theme.value}'),
      ElevatedButton(
        onPressed: () {
          themeNotifier.value = theme.value == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light;
        },
        child: Text('Toggle Theme'),
      ),
    ],
  );
}
```

## Advanced Example: Animation with Listenable

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, _) = useAnimationController(
    duration: Duration(seconds: 2),
  );

  final animationValue = ref(0.0);

  manageListenable(controller, () {
    animationValue.value = controller.value;
  });

  onMounted(() => controller.repeat());

  return (context) => Transform.rotate(
    angle: animationValue.value * 2 * pi,
    child: Icon(Icons.refresh, size: 100),
  );
}
```

## Best Practices

### Automatic Cleanup

```dart
// ❌ Bad: Manual cleanup
@override
Widget Function(BuildContext) setup() {
  final controller = TextEditingController();

  void listener() {
    print(controller.text);
  }

  controller.addListener(listener);

  onUnmounted(() {
    controller.removeListener(listener); // Don't forget!
    controller.dispose();
  });

  return (context) => TextField(controller: controller);
}

// ✅ Good: Automatic cleanup
@override
Widget Function(BuildContext) setup() {
  final controller = TextEditingController();
  final text = manageValueListenable(controller);

  onUnmounted(() => controller.dispose());

  // Listener automatically removed on unmount

  return (context) => TextField(controller: controller);
}
```

### Prefer Composables

```dart
// ❌ OK: Using manageValueListenable
@override
Widget Function(BuildContext) setup() {
  final controller = TextEditingController();
  final text = manageValueListenable(controller);

  onUnmounted(() => controller.dispose());

  return (context) => TextField(controller: controller);
}

// ✅ Better: Use dedicated composable
@override
Widget Function(BuildContext) setup() {
  final (controller, text, _) = useTextEditingController();

  // Everything handled automatically!

  return (context) => TextField(controller: controller.value);
}
```

## See Also

- [useTextEditingController](./controllers.md#usetexteditingcontroller) - Text editing with reactive values
- [useScrollController](./controllers.md#usescrollcontroller) - Scroll controller
- [Lifecycle hooks](../lifecycle.md) - onMounted, onUnmounted
