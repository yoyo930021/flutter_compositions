# 快速上手

歡迎來到 Flutter Compositions！本指南將引導您完成安裝、並建立您的第一個響應式 `CompositionWidget`。

## 1. 安裝

首先，將 `flutter_compositions` 加入您專案的 `pubspec.yaml` 檔案中。

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_compositions: ^0.1.0 # 請使用最新版本
```

然後執行 `flutter pub get` 來安裝套件。

## 2. 建立您的第一個 CompositionWidget

`CompositionWidget` 是 `flutter_compositions` 的核心。它看起來像一個 `StatelessWidget`，但擁有一個只會執行一次的 `setup()` 方法，您可以在其中定義響應式狀態。

讓我們來建立一個簡單的計數器：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

class CounterWidget extends CompositionWidget {
  const CounterWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // 1. 建立一個響應式狀態 `count`，初始值為 0
    final count = ref(0);

    // 2. 建立一個計算屬性 `doubled`，它會根據 `count` 的變化自動更新
    final doubled = computed(() => count.value * 2);

    // 3. 返回一個 builder 函式，它會在響應式狀態變化時自動重建
    return (context) => Scaffold(
      appBar: AppBar(title: const Text('計數器範例')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('你按了這麼多次按鈕:'),
            Text(
              '${count.value}', // 直接讀取 .value
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text('兩倍的數字是: ${doubled.value}'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 4. 修改 .value 來觸發更新
          count.value++;
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## 核心概念解析

1.  **`CompositionWidget`**: 一個特殊的 Widget，其 `setup` 方法只在 `initState` 時執行一次。這意味著您的狀態和業務邏輯只會被初始化一次，而不是在每次重建時都重新執行。

2.  **`ref(initialValue)`**: 建立一個響應式引用 (Reactive Reference)。它是一個包裹物件，您需要透過其 `.value` 屬性來存取和修改內部值。當您修改 `.value` 時，所有依賴它的地方都會自動更新。

3.  **`computed(() => ...)`**: 建立一個計算屬性。它會根據內部的響應式依賴（例如 `count.value`）自動計算其值。當依賴項變化時，`computed` 的值也會更新，並觸發使用它的 UI 進行重建。

4.  **`builder` 函式**: `setup()` 的返回值是一個 `Widget Function(BuildContext)`。這個函式就像 `StatelessWidget` 的 `build` 方法，但它被一個響應式 `effect` 包裹。這意味著只有當您在其中使用的響應式狀態（如 `count.value`）發生變化時，它才會被重新執行，從而實現細粒度的 UI 更新。

## 3. 使用您的 Widget

現在，您可以像使用任何其他 Flutter Widget 一樣使用 `CounterWidget`：

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CounterWidget(),
    );
  }
}
```

就是這麼簡單！您已經建立了一個功能齊全、具備響應式能力的 Widget，而完全不需要使用 `StatefulWidget` 或 `setState()`。

在下一章節，我們將更深入地探討 `Composition` 的核心概念。
