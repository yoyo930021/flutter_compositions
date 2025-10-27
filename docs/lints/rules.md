# Flutter Compositions Lint 規則

完整列出所有可用規則與詳細說明。

## 規則分類

- **Reactivity**：與響應式狀態管理相關的規則
- **Lifecycle**：控制生命週期與資源釋放
- **Best Practices**：通用的最佳實務規範

---

## Reactivity 規則

### `flutter_compositions_ensure_reactive_props`

**類別：** Reactivity  
**嚴重度：** Warning  
**是否可自動修正：** 否

#### 規則說明

要求在 `setup()` 中透過 `widget()` 取得 props，維持響應式更新。直接取用 `this.property` 只會保留初始值，之後不會自動更新。

#### 為什麼重要

`setup()` 只執行一次，若直接抓取欄位值，就會固定在初始值；父層更新 props 也不會反映到子層。

#### 範例

❌ **不佳：**
```dart
class UserCard extends CompositionWidget {
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    final greeting = 'Hello, $name!'; // 只會取得初始值
    return (context) => Text(greeting);
  }
}
```

✅ **較佳：**
```dart
class UserCard extends CompositionWidget {
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    final greeting = computed(() => 'Hello, ${props.value.name}!');
    return (context) => Text(greeting.value);
  }
}
```

---

## Lifecycle 規則

### `flutter_compositions_no_async_setup`

**類別：** Lifecycle  
**嚴重度：** Error  
**是否可自動修正：** 否

#### 規則說明

禁止將 `setup()` 宣告為 `async`。該方法必須同步回傳 builder。

#### 為什麼重要

非同步的 `setup()` 會打亂組合式生命週期，造成框架在建立 widget 時時序不一致。

#### 範例

❌ **不佳：**
```dart
@override
Future<Widget Function(BuildContext)> setup() async {
  final data = await fetchData();
  return (context) => Text(data);
}
```

✅ **較佳：**
```dart
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);

  onMounted(() async {
    data.value = await fetchData();
  });

  return (context) => Text(data.value ?? 'Loading...');
}
```

### `flutter_compositions_controller_lifecycle`

**類別：** Lifecycle  
**嚴重度：** Warning  
**是否可自動修正：** 否

#### 規則說明

確保 Flutter 控制器（如 ScrollController、TextEditingController 等）會被正確釋放。建議使用 `use*` 輔助函式，或在 `onUnmounted()` 中手動 `dispose()`。

#### 為什麼重要

控制器持有系統資源與監聽器，未釋放會導致記憶體洩漏。

#### 會檢查的控制器

- ScrollController / PageController / TextEditingController
- TabController / AnimationController
- VideoPlayerController / WebViewController 等

#### 範例

❌ **不佳：**
```dart
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController(); // 未釋放
  return (context) => ListView(controller: controller);
}
```

✅ **較佳（推薦）：**
```dart
@override
Widget Function(BuildContext) setup() {
  final controller = useScrollController(); // 自動釋放
  return (context) => ListView(controller: controller.value);
}
```

✅ **較佳（手動）：**
```dart
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController();
  onUnmounted(() => controller.dispose());
  return (context) => ListView(controller: controller);
}
```

### `flutter_compositions_no_conditional_composition`

**類別：** Lifecycle  
**嚴重度：** Error  
**是否可自動修正：** 否

#### 規則說明

禁止在條件式或迴圈中呼叫組合式 API（例如 `ref()`、`computed()`、`watch()`、`useScrollController()` 等）。規則和 React Hooks 類似，所有組合式 API 必須在 `setup()` 的頂層呼叫。

#### 為什麼重要

條件式呼叫會導致依賴順序不一致、行為不可預期、清理流程缺失，甚至造成記憶體洩漏。

#### 會被偵測的 API

- Reactivity：`ref`, `computed`, `writableComputed`, `customRef`, `watch`, `watchEffect`
- Lifecycle：`onMounted`, `onUnmounted`
- 依賴注入：`provide`, `inject`
- 控制器相關：`useScrollController`, `usePageController`, `useFocusNode`, `useTextEditingController`, `useValueNotifier`, `useAnimationController`, `manageListenable`, `manageValueListenable` 等

#### 範例

❌ **不佳：**
```dart
@override
Widget Function(BuildContext) setup() {
  if (someCondition) {
    final count = ref(0); // ❌ 不可在條件內呼叫
  }

  for (var i = 0; i < 10; i++) {
    final item = ref(i); // ❌ 迴圈內呼叫
  }

  return (context) => Text('Hello');
}
```

✅ **較佳：**
```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  if (someCondition) {
    count.value = 10; // 只改值可以
  }

  return (context) => Text('${count.value}');
}
```

---

## Best Practices 規則

### `flutter_compositions_no_mutable_fields`

**類別：** Best Practices  
**嚴重度：** Warning  
**是否可自動修正：** 否

#### 規則說明

要求 CompositionWidget 的欄位必須為 `final`，真正的可變狀態應交給 `ref()` 或 `computed()`。

#### 範例

❌ **不佳：**
```dart
class Counter extends CompositionWidget {
  int count = 0; // 可變欄位

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Text('$count');
  }
}
```

✅ **較佳：**
```dart
class Counter extends CompositionWidget {
  final int initialCount;

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(initialCount);
    return (context) => Text('${count.value}');
  }
}
```

---

## 其他資源

- [lint 規則總覽](./index.md)
- [最佳實務指南](../guide/best-practices.md)
- [API 參考](../api/README.md)
