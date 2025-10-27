# 內建 Composables

`flutter_compositions` 提供兩類 composable 工具來幫助您將 Flutter 物件與響應式系統整合：**`use*` 函式**和 **`manage*` 函式**。

## 理解 `use*` 與 `manage*` 的差異

### `use*` 函式 - 建立並管理

以 `use` 為前綴的函式（如 `useScrollController`、`useTextEditingController`）會**建立新實例**並**自動管理其生命週期**:

- **建立**: 返回控制器/物件的新實例
- **銷毀**: 在 Widget 卸載時自動呼叫 `dispose()`
- **返回**: 包裝控制器的響應式 `Ref`

**何時使用**: 當您需要為 Widget 建立新的控制器時。

```dart
// ✅ 當您需要新的控制器時使用
final scrollController = useScrollController();
// 在卸載時自動銷毀
```

### `manage*` 函式 - 整合既有物件

以 `manage` 為前綴的函式（如 `manageValueListenable`、`manageChangeNotifier`）會將**既有實例整合**到響應式系統中，並提供**自動生命週期管理**:

- **需要**: 您傳入一個既有的物件
- **自動清理**: 總是在卸載時移除監聽器
- **自動銷毀**（如果適用）:
  - `manageListenable` / `manageValueListenable`: 無法銷毀（`Listenable` 沒有 `dispose()` 方法）
  - `manageChangeNotifier`: 會在卸載時自動呼叫 `dispose()`
- **返回**: 與物件同步的響應式 `Ref`

**何時使用**: 當您有來自其他地方的既有控制器/notifier（例如：從父組件繼承、共享狀態、第三方函式庫），想要整合到響應式系統中。

```dart
// ✅ 用於 Listenable 物件（例如：Animation）
// 自動移除監聽器，但無法銷毀（Listenable 沒有 dispose 方法）
final animation = ...; // 來自 AnimationController
final reactiveAnimation = manageListenable(animation);

// ✅ 用於 ChangeNotifier 物件（例如：ScrollController）
// 自動移除監聽器並且銷毀
final controller = ScrollController();
final reactiveController = manageChangeNotifier(controller);
```

## 主要差異

| 特性 | `use*` 函式 | `manage*` 函式 |
|------|------------|---------------|
| **建立實例** | ✅ 是 | ❌ 否（您提供） |
| **自動清理** | ✅ 總是 | ✅ 總是（移除監聽器） |
| **自動銷毀** | ✅ 總是 | `manageChangeNotifier`: ✅<br>`manageListenable`: 不適用（沒有 dispose 方法） |
| **使用情境** | 為此 Widget 建立新控制器 | 整合既有物件 |
| **範例** | `useScrollController()` | `manageValueListenable(existing)` |

## `useScrollController`

```dart
@override
Widget Function(BuildContext) setup() {
  // 建立一個會自動 dispose 的 ScrollController
  final scrollController = useScrollController();

  // 建立一個計算屬性來追蹤捲動偏移量
  final scrollOffset = computed(() {
    // 當 scrollController 通知更新時，這裡會重新計算
    return scrollController.value.offset;
  });

  // 監聽捲動位置的變化
  watch(() => scrollOffset.value, (offset, _) {
    print('Scrolled to: $offset');
  });

  return (context) => ListView.builder(
    controller: scrollController.value, // 將控制器傳給 ListView
    itemCount: 100,
    itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
  );
}
```

## `usePageController`

建立自動釋放的 `PageController`，並搭配 `computed` 或 `watch` 追蹤分頁索引。

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

以響應式方式管理 `FocusNode`，并在卸載時自動釋放。

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

這是處理文字輸入的強大工具。它不僅會自動管理 `TextEditingController` 的生命週期，還提供了雙向綁定的能力。

它返回一個記錄 (Record)：`(controller, text, value)`

- `controller`: `TextEditingController` 實例，用於傳遞給 `TextField`。
- `text`: 一個可寫的 `ComputedRef<String>`，與 `controller.text` 同步。
- `value`: 一個可寫的 `ComputedRef<TextEditingValue>`，與 `controller.value` 同步。

您可以直接修改 `text.value` 來以程式碼改變輸入框的內容，也可以監聽 `text.value` 的變化來響應使用者的輸入。

**範例：雙向綁定與即時驗證**

```dart
@override
Widget Function(BuildContext) setup() {
  final (usernameController, username, _) = useTextEditingController(text: 'guest');

  // 計算屬性，用於顯示歡迎訊息
  final greeting = computed(() => 'Hello, ${username.value}!');

  // 計算屬性，用於簡單的驗證邏輯
  final isValid = computed(() => username.value.length >= 3);

  return (context) => Column(
    children: [
      Text(greeting.value),
      TextField(
        controller: usernameController,
        decoration: InputDecoration(
          labelText: 'Username',
          errorText: isValid.value ? null : '至少需要 3 個字元',
        ),
      ),
      ElevatedButton(
        onPressed: () => username.value = 'default', // 以程式碼修改文字
        child: const Text('Reset'),
      )
    ],
  );
}
```

## `manageValueListenable`

當您需要與既有的 `ValueNotifier` 或 `ValueListenable` 整合（來自舊有程式碼或第三方函式庫）時，`manageValueListenable` 是一個橋樑。

它會從任何 `ValueListenable` 中提取並追蹤值，返回一個 `(listenable, value)` 元組。

**自動管理**: 此函式會在卸載時自動移除監聽器。它無法銷毀 listenable，因為 `ValueListenable` 介面本身沒有 `dispose()` 方法。如果您使用的是 `ChangeNotifier`（它同時繼承 `Listenable` 並具有 `dispose()` 方法），請改用 `manageChangeNotifier`。

**範例：整合既有的 `ValueNotifier`**

```dart
// 假設您有一個來自應用程式其他部分的 ValueNotifier
final legacyCounter = ValueNotifier(0);

@override
Widget Function(BuildContext) setup() {
  // 將既有的 ValueNotifier 整合到響應式系統中
  // 返回 (listenable, value) 元組
  final (notifier, count) = manageValueListenable(legacyCounter);

  final doubled = computed(() => count.value * 2);

  return (context) => Column(
    children: [
      Text('Reactive Doubled: ${doubled.value}'),
      // 也可以繼續與 Flutter 的原生工具一起使用
      ValueListenableBuilder<int>(
        valueListenable: notifier,
        builder: (context, value, child) => Text('Legacy Value: $value'),
      ),
    ],
  );
}
```

**注意**:
- 返回的值是**唯讀的**。若要修改它，請存取原始的 listenable。
- 如果您專門為此 Widget 建立新的 `ValueNotifier`，請使用 `ref()` 替代。
- 如果您需要銷毀 `ChangeNotifier`，請使用 `manageChangeNotifier()` 替代。
