# 建立您自己的 Composables

內建的 `use` 系列函式非常方便，但 `flutter_compositions` 真正的威力在於讓您能夠輕鬆建立自己的可組合函式 (Composables)。

## 什麼是 Composable？

一個 Composable 是一個普通的 Dart 函式，其名稱以 `use` 開頭。它讓您可以將與特定功能相關的響應式邏輯和生命週期管理封裝起來，以便在不同的 `CompositionWidget` 中重複使用。

建立您自己的 Composable 有幾個主要好處：

- **邏輯重用**: 將狀態ful邏輯從您的 Widget 中抽離出來，避免重複撰寫相同的程式碼。
- **關注點分離**: 讓您的 `setup` 方法保持簡潔，只關注於組合不同的 Composable，而不是實現所有細節。
- **可測試性**: 獨立的 Composable 函式比龐大的 Widget 更容易進行單元測試。

## 範例：建立 `useOrientation`

讓我們來建立一個 `useOrientation` Composable，它會回傳一個響應式的 `Ref` 來告訴我們目前裝置的方向（直向或橫向）。

**1. 建立 `use_media_query.dart` 檔案**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

// 一個 Composable 就是一個以 `use` 開頭的函式
(Ref<Size>, Ref<Orientation>) useMediaQuery() {
  // 1. 建立 refs 來儲存響應式值
  final size = ref(Size.zero);
  final orientation = ref(Orientation.portrait);

  // 2. 使用 onBuild 在每次 build 時存取 BuildContext
  // 這樣可以響應 MediaQuery 的變化
  onBuild((context) {
    final mediaQuery = MediaQuery.of(context);
    size.value = mediaQuery.size;
    orientation.value = mediaQuery.orientation;
  });

  // 3. 返回響應式引用
  return (size, orientation);
}
```

**重要提示**: 上面的範例使用 `onBuild()` 在每次 build 時存取 `BuildContext`。這是與 Flutter 的 `InheritedWidget` 系統（如 `MediaQuery`、`Theme` 等）整合的推薦方式。

**替代方案 - 使用 useContext()**: 如果您需要在生命週期鉤子中存取 context 來執行命令式操作（如顯示對話框或導航），請使用 `useContext()`：

```dart
void Function() useShowWelcomeDialog() {
  final context = useContext();

  return () {
    // 使用 context 的命令式操作
    showDialog(
      context: context.value!,
      builder: (context) => const AlertDialog(
        title: Text('歡迎！'),
      ),
    );
  };
}
```

**2. 在您的 Widget 中使用它**

現在，您可以像使用任何內建 Composable 一樣，在您的 `setup` 方法中使用 `useMediaQuery`。

```dart
import './use_media_query.dart'; // 引入您建立的 Composable

class ResponsiveWidget extends CompositionWidget {
  const ResponsiveWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // 就像內建函式一樣呼叫它
    final (screenSize, orientation) = useMediaQuery();

    // 根據螢幕資訊建立計算屬性
    final isPortrait = computed(() => orientation.value == Orientation.portrait);
    final isSmallScreen = computed(() => screenSize.value.width < 600);

    final message = computed(() {
      final orientationText = isPortrait.value ? '直向' : '橫向';
      final sizeText = isSmallScreen.value ? '小螢幕' : '大螢幕';
      return '螢幕：$sizeText，$orientationText (${screenSize.value.width.toInt()}x${screenSize.value.height.toInt()})';
    });

    return (context) => Scaffold(
      appBar: AppBar(title: const Text('響應式')),
      body: Center(
        child: Text(message.value), // UI 會自動響應變化
      ),
    );
  }
}
```

透過這種模式，您可以建立各種可重用的邏輯，例如：

- `useConnectivity()`: 監聽網路連線狀態。
- `useGeolocation()`: 追蹤使用者的地理位置。
- `useForm()`: 封裝複雜表單的狀態和驗證邏輯。

將您的應用程式邏輯分解成一個個小的、可管理的、可重用的 Composable，是使用 `flutter_compositions` 的最佳實踐。
