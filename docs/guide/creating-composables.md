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

**1. 建立 `use_orientation.dart` 檔案**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

// 一個 Composable 就是一個以 `use` 開頭的函式
Ref<Orientation> useOrientation() {
  // 1. 建立一個 ref 來儲存目前的螢幕方向
  final orientation = ref(Orientation.portrait);

  // 2. 使用 onMounted，因為我們需要 BuildContext 來獲取 MediaQuery
  onMounted(() {
    // 獲取當前的 BuildContext
    final context = inject<BuildContext>();

    // 設定初始值
    orientation.value = MediaQuery.of(context).orientation;

    // 注意：在真實世界的應用中，您可能需要一個更可靠的方式
    // 來監聽方向變化，例如使用 `WidgetsBindingObserver`。
    // 為了範例簡潔，我們只在掛載時設定一次。
  });

  // 3. 返回響應式引用
  return orientation;
}
```

**重要提示**: 在上面的範例中，為了在 `onMounted` 中獲取 `BuildContext`，我們使用了 `inject<BuildContext>()`。這是一個小技巧，因為 `CompositionWidget` 的框架在執行 `builder` 函式之前會自動 `provide` 當前的 `BuildContext`。

**2. 在您的 Widget 中使用它**

現在，您可以像使用任何內建 Composable 一樣，在您的 `setup` 方法中使用 `useOrientation`。

```dart
import './use_orientation.dart'; // 引入您建立的 Composable

class OrientationAwareWidget extends CompositionWidget {
  const OrientationAwareWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // 就像內建函式一樣呼叫它
    final orientation = useOrientation();

    // 建立一個計算屬性來顯示不同的文字
    final message = computed(() {
      return orientation.value == Orientation.portrait
          ? '現在是直向模式'
          : '現在是橫向模式';
    });

    return (context) => Scaffold(
      appBar: AppBar(title: const Text('螢幕方向')),
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
