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

### `flutter_compositions_shallow_reactivity`

**類別：** Best Practices
**嚴重度：** Warning
**是否可自動修正：** 否

#### 規則說明

警告淺層響應式的限制。Flutter Compositions 採用淺層響應式 - 只有重新賦值 `.value` 才會觸發更新。直接修改屬性或陣列項目**不會**觸發響應式更新。

#### 為什麼重要

響應式系統只追蹤 `ref.value` 本身的變更，不追蹤物件或陣列內部的變更。像 `ref.value.property = x` 或 `ref.value[0] = x` 這樣的直接修改不會通知訂閱者，導致 UI 無法更新。

#### 範例

❌ **不佳：**
```dart
@override
Widget Function(BuildContext) setup() {
  final user = ref({'name': 'John', 'age': 30});
  final items = ref([1, 2, 3]);

  void updateUser() {
    user.value['name'] = 'Jane'; // 不會觸發更新！
  }

  void updateItems() {
    items.value[0] = 10; // 不會觸發更新！
    items.value.add(4); // 不會觸發更新！
  }

  return (context) => Column(
    children: [
      Text(user.value['name']),
      Text('${items.value[0]}'),
    ],
  );
}
```

✅ **較佳：**
```dart
@override
Widget Function(BuildContext) setup() {
  final user = ref({'name': 'John', 'age': 30});
  final items = ref([1, 2, 3]);

  void updateUser() {
    // 建立新物件以觸發更新
    user.value = {...user.value, 'name': 'Jane'};
  }

  void updateItems() {
    // 建立新陣列以觸發更新
    items.value = [10, ...items.value.sublist(1)];
    items.value = [...items.value, 4];
  }

  return (context) => Column(
    children: [
      Text(user.value['name']),
      Text('${items.value[0]}'),
    ],
  );
}
```

#### 常見的錯誤模式

**直接賦值屬性：**
```dart
ref.value['key'] = newValue; // ❌
ref.value.property = newValue; // ❌
ref.value = {...ref.value, 'key': newValue}; // ✅
```

**陣列元素賦值：**
```dart
ref.value[index] = newValue; // ❌
ref.value = [...ref.value.sublist(0, index), newValue, ...ref.value.sublist(index + 1)]; // ✅
```

**修改性方法：**
```dart
ref.value.add(item); // ❌
ref.value.remove(item); // ❌
ref.value.clear(); // ❌
ref.value = [...ref.value, item]; // ✅
ref.value = ref.value.where((x) => x != item).toList(); // ✅
ref.value = []; // ✅
```

---

## 其他資源

- [lint 規則總覽](./index.md)
- [最佳實務指南](../guide/best-practices.md)
- [Composables 參考](../guide/built-in-composables.md)
