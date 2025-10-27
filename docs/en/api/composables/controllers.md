# Controller Composables

Composables for Flutter controllers with automatic disposal.

## useScrollController

Create a `ScrollController` with automatic disposal.

### Signature

```dart
Ref<ScrollController> useScrollController({
  double initialScrollOffset = 0.0,
  bool keepScrollOffset = true,
  String? debugLabel,
})
```

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final scrollController = useScrollController();

  // Listen to scroll events
  watchEffect(() {
    final offset = scrollController.value.offset;
    print('Scroll offset: $offset');
  });

  return (context) => ListView.builder(
    controller: scrollController.value,
    itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
  );
}
```

## usePageController

Create a `PageController` with automatic disposal.

### Signature

```dart
Ref<PageController> usePageController({
  int initialPage = 0,
  bool keepPage = true,
  double viewportFraction = 1.0,
})
```

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final pageController = usePageController(initialPage: 0);
  final currentPage = ref(0);

  watchEffect(() {
    final page = pageController.value.page?.round() ?? 0;
    currentPage.value = page;
  });

  return (context) => Column(
    children: [
      Text('Page: ${currentPage.value}'),
      Expanded(
        child: PageView(
          controller: pageController.value,
          children: [
            Page1(),
            Page2(),
            Page3(),
          ],
        ),
      ),
    ],
  );
}
```

## useTextEditingController

Create a `TextEditingController` with reactive text and selection.

### Signature

```dart
(
  Ref<TextEditingController>,
  Ref<String>,
  Ref<TextSelection>,
) useTextEditingController({
  String? text,
  TextSelection? selection,
})
```

### Returns

A record with:
- `controller` - The TextEditingController
- `text` - Reactive ref for current text
- `selection` - Reactive ref for current selection

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, text, selection) = useTextEditingController(
    text: 'Hello',
  );

  final uppercase = computed(() => text.value.toUpperCase());

  watch(() => text.value, (newText, oldText) {
    print('Text changed: $oldText -> $newText');
  });

  return (context) => Column(
    children: [
      TextField(controller: controller.value),
      Text('You typed: ${text.value}'),
      Text('Uppercase: ${uppercase.value}'),
    ],
  );
}
```

### Programmatic Updates

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, text, selection) = useTextEditingController();

  void clearText() {
    text.value = ''; // Updates the controller
  }

  void selectAll() {
    selection.value = TextSelection(
      baseOffset: 0,
      extentOffset: text.value.length,
    );
  }

  return (context) => Column(
    children: [
      TextField(controller: controller.value),
      ElevatedButton(onPressed: clearText, child: Text('Clear')),
      ElevatedButton(onPressed: selectAll, child: Text('Select All')),
    ],
  );
}
```

## useFocusNode

Create a `FocusNode` with automatic disposal.

### Signature

```dart
Ref<FocusNode> useFocusNode({
  String? debugLabel,
  bool skipTraversal = false,
  bool canRequestFocus = true,
})
```

### Example

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
        child: Text('Focus'),
      ),
    ],
  );
}
```

## useTabController

Create a `TabController` with automatic disposal.

### Signature

```dart
Ref<TabController> useTabController({
  required int length,
  int initialIndex = 0,
})
```

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final tabController = useTabController(length: 3, initialIndex: 0);
  final currentTab = ref(0);

  watchEffect(() {
    currentTab.value = tabController.value.index;
  });

  return (context) => Column(
    children: [
      TabBar(
        controller: tabController.value,
        tabs: [
          Tab(text: 'Tab 1'),
          Tab(text: 'Tab 2'),
          Tab(text: 'Tab 3'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: tabController.value,
          children: [
            Center(child: Text('Content 1')),
            Center(child: Text('Content 2')),
            Center(child: Text('Content 3')),
          ],
        ),
      ),
    ],
  );
}
```

## Best Practices

### Use Composables for Auto-Disposal

```dart
// ❌ Bad: Manual disposal required
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController();

  onUnmounted(() {
    controller.dispose(); // Don't forget!
  });

  return (context) => ListView(controller: controller);
}

// ✅ Good: Automatic disposal
@override
Widget Function(BuildContext) setup() {
  final controller = useScrollController();
  // Automatically disposed on unmount

  return (context) => ListView(controller: controller.value);
}
```

### Reactive Controller Access

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, text, _) = useTextEditingController();

  // Reactive: Rebuilds when text changes
  final wordCount = computed(() => text.value.split(' ').length);

  return (context) => Column(
    children: [
      TextField(controller: controller.value),
      Text('Words: ${wordCount.value}'),
    ],
  );
}
```

## See Also

- [Lifecycle hooks](../lifecycle.md) - onMounted, onUnmounted
- [ref](../reactivity.md#ref) - Reactive references
- [watch](../watch.md) - Side effects
