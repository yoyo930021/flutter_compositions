# 內建 Composables

`flutter_compositions` 不僅提供核心的響應式 API，還包含了一系列以 `use` 為前綴的工具函式，我們稱之為 "Composables"。這些函式旨在封裝與 Flutter 特定物件（如控制器）相關的常見邏輯，特別是自動化的生命週期管理。

使用這些 `use` 函式的主要好處是：

1.  **自動銷毀 (Automatic Disposal)**: 您不再需要在 `dispose` 方法中手動呼叫 `controller.dispose()`。`use` 函式會在 `onUnmounted` 中自動為您處理。
2.  **響應式整合 (Reactivity Integration)**: 它們通常會返回一個響應式的 `Ref` 或 `ComputedRef`，讓您可以輕易地在 `computed` 或 `watch` 中使用控制器的狀態。

## `useController<T extends ChangeNotifier>`

這是一個通用的工具，用於管理任何繼承自 `ChangeNotifier` 的控制器。它會自動處理 `dispose`，並返回一個 `ComputedRef<T>`，該 Ref 會在控制器呼叫 `notifyListeners()` 時更新。

`useScrollController`, `usePageController`, `useFocusNode` 都是基於 `useController` 實現的特化版本。

**範例：使用 `useScrollController`**

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

## `useValueNotifier`

當您需要與既有的 `ValueNotifier` 或使用 `ValueListenableBuilder` 的舊有程式碼整合時，`useValueNotifier` 是一個橋樑。

它會將一個 `ValueNotifier<T>` 轉換成一個可寫的 `ComputedRef<T>`，實現兩者之間的雙向同步。

**範例：橋接一個 `ValueNotifier`**

```dart
// 假設您有一個來自其他地方的 ValueNotifier
final legacyCounter = ValueNotifier(0);

@override
Widget Function(BuildContext) setup() {
  // 將 ValueNotifier 轉換為響應式的 Ref
  // `disposeNotifier: true` 會在 unmount 時自動銷毀傳入的 notifier
  final count = useValueNotifier(legacyCounter, disposeNotifier: false);

  final doubled = computed(() => count.value * 2);

  return (context) => Column(
    children: [
      Text('Reactive Doubled: ${doubled.value}'),
      ElevatedButton(
        onPressed: () => count.value++, // 修改 Ref 會同步回 ValueNotifier
        child: const Text('Increment'),
      ),
      // 也可以繼續與 Flutter 的原生工具一起使用
      ValueListenableBuilder<int>(
        valueListenable: legacyCounter,
        builder: (context, value, child) => Text('Legacy Value: $value'),
      ),
    ],
  );
}
```
