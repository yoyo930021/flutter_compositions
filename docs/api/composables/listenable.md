# Listenable 組合式函式

用於管理 Flutter `Listenable` 物件並自動釋放資源的組合式函式。

## manageListenable

管理 `Listenable`，並自動清除監聽器。

### 方法簽章

```dart
T manageListenable<T extends Listenable>(
  T listenable,
  void Function() listener,
)
```

### 範例

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

管理 `ValueListenable` 並回傳響應式 ref。

### 方法簽章

```dart
Ref<T> manageValueListenable<T>(ValueListenable<T> valueListenable)
```

### 回傳值

`Ref<T>`：當 ValueListenable 變更時會更新的響應式參照

### 範例

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

管理 `ChangeNotifier` 並自動釋放。

### 方法簽章

```dart
T manageChangeNotifier<T extends ChangeNotifier>(
  T notifier,
  void Function() listener,
)
```

### 範例

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

## 與既有程式碼整合

### 包裝 ChangeNotifier

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

### 包裝 ValueNotifier

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

## 進階範例：搭配 Listenable 的動畫

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

## 最佳實務

### 自動清除

```dart
// ❌ 不佳：手動清除
@override
Widget Function(BuildContext) setup() {
  final controller = TextEditingController();

  void listener() {
    print(controller.text);
  }

  controller.addListener(listener);

  onUnmounted(() {
    controller.removeListener(listener); // 不要忘記！
    controller.dispose();
  });

  return (context) => TextField(controller: controller);
}

// ✅ 較佳：自動清除
@override
Widget Function(BuildContext) setup() {
  final controller = TextEditingController();
  final text = manageValueListenable(controller);

  onUnmounted(() => controller.dispose());

  // 卸載時會自動移除監聽器

  return (context) => TextField(controller: controller);
}
```

### 優先使用組合式函式

```dart
// ❌ 可以但較繁瑣：使用 manageValueListenable
@override
Widget Function(BuildContext) setup() {
  final controller = TextEditingController();
  final text = manageValueListenable(controller);

  onUnmounted(() => controller.dispose());

  return (context) => TextField(controller: controller);
}

// ✅ 較佳：使用專用的 composable
@override
Widget Function(BuildContext) setup() {
  final (controller, text, _) = useTextEditingController();

  // 所有細節都會自動處理！

  return (context) => TextField(controller: controller.value);
}
```

## 延伸閱讀

- [useTextEditingController](./controllers.md#usetexteditingcontroller) - 具響應式值的文字編輯
- [useScrollController](./controllers.md#usescrollcontroller) - Scroll 控制器
- [生命週期掛勾](../lifecycle.md) - onMounted、onUnmounted
