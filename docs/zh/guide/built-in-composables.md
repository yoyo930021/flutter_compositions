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


## InheritedWidget Composables

`flutter_compositions` 提供了一組 composables 來以響應式方式存取 Flutter 的 InheritedWidget 資料（如 `MediaQuery`、`Theme` 等）。這些 composables 會自動追蹤變更並**只在值實際改變時**才觸發更新，大幅提升性能。

### `useContextRef` - 核心函式

`useContextRef` 是所有 InheritedWidget composables 的基礎。它可以將任何來自 `BuildContext` 的值轉換為響應式引用。

**關鍵特性:**
- ✅ **性能優化**: 使用相等性比較，只在值實際變更時才觸發更新
- ✅ **自訂比較**: 支援自訂 `equals` 函式進行細粒度控制
- ✅ **類型安全**: 完整的泛型類型支援

```dart
@override
Widget Function(BuildContext) setup() {
  // 使用預設的 identical 比較追蹤螢幕寬度
  final width = useContextRef<double>(
    (context) => MediaQuery.of(context).size.width,
  );

  // 使用自訂相等性比較追蹤主題亮度
  final brightness = useContextRef<Brightness>(
    (context) => Theme.of(context).brightness,
    equals: (a, b) => a == b, // 值相等性，而非同一性
  );

  final message = computed(() =>
    \"Width: \${width.value}, Mode: \${brightness.value == Brightness.dark ? \"Dark\" : \"Light\"}\"
  );

  return (context) => Text(message.value);
}
```

**重要:** `useContextRef` 只在值比較結果為不相等時才會觸發響應式更新。這意味著即使 InheritedWidget 重建了，如果值保持不變，您的組件也不會重新計算。

### `useMediaQuery`

提供對完整 `MediaQueryData` 的響應式存取。當裝置方向、尺寸或其他屬性變更時自動更新。

```dart
@override
Widget Function(BuildContext) setup() {
  final mediaQuery = useMediaQuery();

  final isPortrait = computed(() =>
    mediaQuery.value.orientation == Orientation.portrait
  );

  final screenWidth = computed(() => mediaQuery.value.size.width);

  final pixelRatio = computed(() => mediaQuery.value.devicePixelRatio);

  return (context) => Column(
    children: [
      Text(\"寬度: \${screenWidth.value.toStringAsFixed(0)}\"),
      Text(\"方向: \${isPortrait.value ? \"直向\" : \"橫向\"}\"),
      Text(\"像素比: \${pixelRatio.value}\"),
    ],
  );
}
```

### `useMediaQueryInfo`

將 `size` 和 `orientation` 分離為獨立的響應式引用，實現更細粒度的響應式控制。

**為什麼使用這個?** 當您只需要尺寸或方向其中之一時，這可以避免不必要的重新計算。

```dart
@override
Widget Function(BuildContext) setup() {
  final (size, orientation) = useMediaQueryInfo();

  // 只有當尺寸變更時才會重新計算
  final isSmallScreen = computed(() => size.value.width < 600);

  // 只有當方向變更時才會重新計算
  final isPortrait = computed(() => orientation.value == Orientation.portrait);

  final columns = computed(() {
    if (isSmallScreen.value) return 1;
    return isPortrait.value ? 2 : 3;
  });

  return (context) => Text(\"欄數: \${columns.value}\");
}
```

**性能優勢:** 如果只有螢幕尺寸改變（沒有旋轉），`orientation` 引用不會觸發更新，依賴它的計算屬性也不會重新執行。

### `useTheme`

響應式存取當前主題資料。當應用程式主題變更時自動更新。

```dart
@override
Widget Function(BuildContext) setup() {
  final theme = useTheme();

  final primaryColor = computed(() => theme.value.primaryColor);

  final isDark = computed(() => theme.value.brightness == Brightness.dark);

  final textStyle = computed(() => TextStyle(
    color: isDark.value ? Colors.white : Colors.black,
    fontSize: 16,
  ));

  return (context) => Container(
    color: primaryColor.value,
    child: Text(
      \"主題: \${isDark.value ? \"深色\" : \"淺色\"}\",
      style: textStyle.value,
    ),
  );
}
```

### `usePlatformBrightness`

追蹤系統亮度設定（淺色/深色模式）。當使用者切換系統主題時自動更新。

```dart
@override
Widget Function(BuildContext) setup() {
  final brightness = usePlatformBrightness();

  final isDark = computed(() => brightness.value == Brightness.dark);

  final statusMessage = computed(() =>
    \"系統主題: \${isDark.value ? \"深色模式\" : \"淺色模式\"}\"
  );

  return (context) => Text(statusMessage.value);
}
```

### `useTextScale`

追蹤系統文字縮放因子。當使用者在系統設定中變更文字大小時自動更新。

```dart
@override
Widget Function(BuildContext) setup() {
  final textScale = useTextScale();

  final fontSize = computed(() => 16.0 * textScale.value.scale(1.0));

  final scaleLabel = computed(() {
    final scale = textScale.value.scale(1.0);
    if (scale < 1.0) return \"小\";
    if (scale > 1.5) return \"大\";
    return \"標準\";
  });

  return (context) => Text(
    \"字體大小: \${scaleLabel.value}\",
    style: TextStyle(fontSize: fontSize.value),
  );
}
```

### `useLocale`

追蹤當前地區設定。當系統語言變更時自動更新。

```dart
@override
Widget Function(BuildContext) setup() {
  final locale = useLocale();

  final languageCode = computed(() => locale.value.languageCode);

  final greeting = computed(() {
    switch (languageCode.value) {
      case \"zh\": return \"你好\";
      case \"ja\": return \"こんにちは\";
      case \"es\": return \"Hola\";
      default: return \"Hello\";
    }
  });

  return (context) => Text(\"\${greeting.value} (\${languageCode.value})\");
}
```

### 響應式設計範例

結合多個 InheritedWidget composables 來建立響應式佈局:

```dart
@override
Widget Function(BuildContext) setup() {
  final (size, orientation) = useMediaQueryInfo();
  final theme = useTheme();

  // 根據螢幕尺寸計算斷點
  final breakpoint = computed(() {
    final width = size.value.width;
    if (width < 600) return \"small\";
    if (width < 900) return \"medium\";
    return \"large\";
  });

  // 根據斷點和方向計算欄數
  final columns = computed(() {
    if (breakpoint.value == \"small\") return 1;
    if (breakpoint.value == \"medium\") {
      return orientation.value == Orientation.portrait ? 2 : 3;
    }
    return 4;
  });

  // 根據斷點計算字體大小
  final fontSize = computed(() {
    switch (breakpoint.value) {
      case \"small\": return 14.0;
      case \"medium\": return 16.0;
      default: return 18.0;
    }
  });

  return (context) => Container(
    color: theme.value.scaffoldBackgroundColor,
    child: GridView.count(
      crossAxisCount: columns.value,
      children: List.generate(
        12,
        (i) => Card(
          child: Center(
            child: Text(
              \"項目 \${i + 1}\",
              style: TextStyle(fontSize: fontSize.value),
            ),
          ),
        ),
      ),
    ),
  );
}
```

### 性能最佳實踐

1. **使用特定的 composables**: 優先使用 `useMediaQueryInfo()` 而不是 `useMediaQuery()`，如果您只需要尺寸或方向。

2. **自訂相等性**: 對於複雜物件，使用自訂 `equals` 函式來避免不必要的更新:

```dart
final customData = useContextRef<MyData>(
  (context) => MyInheritedWidget.of(context).data,
  equals: (a, b) => a.id == b.id, // 只在 ID 變更時更新
);
```

3. **細粒度 computed**: 將計算屬性分解為較小的部分，以最小化重新計算:

```dart
// ✅ 良好 - 獨立的 computed
final width = computed(() => size.value.width);
final height = computed(() => size.value.height);

// ❌ 較差 - 一個大的 computed
final dimensions = computed(() => \"\${size.value.width}x\${size.value.height}\");
```
