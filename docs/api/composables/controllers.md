# 控制器組合式函式

用於建立具自動釋放能力的 Flutter 控制器。

## useScrollController

建立自動釋放的 `ScrollController`。

### 方法簽章

```dart
Ref<ScrollController> useScrollController({
  double initialScrollOffset = 0.0,
  bool keepScrollOffset = true,
  String? debugLabel,
})
```

### 範例

```dart
@override
Widget Function(BuildContext) setup() {
  final scrollController = useScrollController();

  // 監聽捲動事件
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

建立自動釋放的 `PageController`。

### 方法簽章

```dart
Ref<PageController> usePageController({
  int initialPage = 0,
  bool keepPage = true,
  double viewportFraction = 1.0,
})
```

### 範例

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

建立具響應式文字與選取狀態的 `TextEditingController`。

### 方法簽章

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

### 回傳值

回傳包含以下項目的 record：
- `controller`：實際的 TextEditingController
- `text`：目前文字的響應式 ref
- `selection`：目前選取範圍的響應式 ref

### 範例

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

### 程式化更新

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, text, selection) = useTextEditingController();

  void clearText() {
    text.value = ''; // 同步更新 controller
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

建立自動釋放的 `FocusNode`。

### 方法簽章

```dart
Ref<FocusNode> useFocusNode({
  String? debugLabel,
  bool skipTraversal = false,
  bool canRequestFocus = true,
})
```

### 範例

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

建立自動釋放的 `TabController`。

### 方法簽章

```dart
Ref<TabController> useTabController({
  required int length,
  int initialIndex = 0,
})
```

### 範例

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

## 最佳實務

### 利用組合式函式自動釋放

```dart
// ❌ 不佳：需要手動釋放
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController();

  onUnmounted(() {
    controller.dispose(); // 不要忘記！
  });

  return (context) => ListView(controller: controller);
}

// ✅ 較佳：自動釋放
@override
Widget Function(BuildContext) setup() {
  final controller = useScrollController();
  // Automatically disposed on unmount

  return (context) => ListView(controller: controller.value);
}
```

### 以響應式方式存取控制器

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, text, _) = useTextEditingController();

  // 響應式：文字變更時會重新建構
  final wordCount = computed(() => text.value.split(' ').length);

  return (context) => Column(
    children: [
      TextField(controller: controller.value),
      Text('Words: ${wordCount.value}'),
    ],
  );
}
```

## 延伸閱讀

- [生命週期掛勾](../lifecycle.md) - onMounted、onUnmounted
- [ref](../reactivity.md#ref) - 響應式參照
- [watch](../watch.md) - 副作用
