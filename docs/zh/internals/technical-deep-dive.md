# 技術深入解析

本章節說明 runtime、生命週期掛勾與內建 composable 如何協同運作。

## `setup()` 執行流程

`setup()` 僅會執行一次：

1. 建立 `_SetupContext`，初始化 effect、clean-up、provide 等堆疊。
2. Composable 可透過 context 註冊 `onMounted`、`onUnmounted`、`onBuild` 等掛勾。
3. 回傳的 builder 會閉包住在 `setup()` 中建立的所有 ref。

Hot Reload 會依宣告順序重新套用 ref 的值，因此請保持宣告順序穩定；若調整順序，改用 Hot Restart 重置狀態。

## Builder 即 Effect

- builder 會在 `effect` 內執行。
- 讀取 ref 會把對應的 effect 註冊為訂閱者。
- 當 effect 重新執行時，會觸發 `setState` 進而進行標準的 Flutter rebuild。

## 清理語意

`onCleanup`（例如 `watch` 內部會用到）用來註冊釋放邏輯，在 effect 被釋放或重建時執行，確保監聽器、計時器、控制器不會洩漏。

```dart
final subscription = stream.listen((value) {
  ref.value = value;
});
onCleanup(subscription.cancel);
```

## 控制器管理

`useScrollController`、`useAnimationController` 等 helper 會：

- 在 `setup()` 中建立控制器。
- 使用 `onCleanup` 於卸載時自動呼叫 `dispose()`。
- 將命令式事件轉換成 ref，維持 UI 響應式。

## 錯誤處理

- `setup()` 拋出的例外會如同 Flutter 預設往外冒泡，必要時自行捕捉。
- effect 內的錯誤會被捕捉並以非同步方式重新拋出，好讓 Flutter ErrorWidget 顯示堆疊。

## 在 composable 中串接依賴

- 當 composable 需要跨畫面的服務時，可以直接呼叫 `inject`。
- 若希望 composable 保持純函式特性，改以參數傳入相依物件，將 `inject` 留給橫切關注點（analytics、localization 等）。
- `_SetupContext` 內部維護 `_provided` map，注入會沿著父層 context 向上搜尋，類似 `InheritedWidget` 但不會造成整棵 widget tree 重建。

## 擴充 runtime

客製 composable 時：

1. 根據需求呼叫 `ref`、`computed`、`watch`。
2. 註冊監聽器，並透過 `onCleanup` 確保釋放。
3. 回傳 reactive 值或方法，讓呼叫端自由組合。

```dart
(Ref<Brightness>, void Function()) useBrightnessToggle() {
  final brightness = ref(Brightness.light);
  void toggle() => brightness.value =
      brightness.value == Brightness.light ? Brightness.dark : Brightness.light;
  return (brightness, toggle);
}
```

## 延伸閱讀

- [架構概觀](./architecture.md)
- [響應式系統詳解](./reactivity-in-depth.md)
- [最佳實務指南](../guide/best-practices.md)
