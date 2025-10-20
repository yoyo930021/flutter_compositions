# 響應式系統詳解

`flutter_compositions` 的核心驅動力是 `alien_signals` 套件，它是一個為 Dart 量身打造的高效能響應式函式庫。理解 `alien_signals` 的基本原理，將幫助您完全掌握 `flutter_compositions` 的運作方式。

## Signal 系統的三大支柱

一個 Signal 系統通常由三個核心概念組成：

1.  **Signal (或 Ref)**: 響應式系統的**數據源**。在我們的框架中，這由 `ref()` 建立。它是一個包裹著值的容器。當您讀取它的 `.value` 時，您在讀取一個值；當您寫入它的 `.value` 時，您在觸發一個變化。

2.  **Computed (計算屬性)**: **衍生的數據**。由 `computed()` 建立。它本身沒有值，其值是透過一個函式從其他的 `Signal` 或 `Computed` 中計算得來。它會自動追蹤其計算過程中用到的依賴項。

3.  **Effect (副作用)**: **響應式系統的終端**。由 `watchEffect()`、`watch()` 或 `CompositionWidget` 的 `builder` 函式隱式建立。它是一個會執行某些操作（例如打印日誌、發送網路請求、或**更新 UI**）的函式。`Effect` 同樣會追蹤其執行過程中用到的依賴項。

這三者形成了一個**依賴圖 (Dependency Graph)**。`Computed` 和 `Effect` 會訂閱它們所依賴的 `Signal` 和 `Computed`。

## "魔法"是如何運作的：自動追蹤

當您在一個 `computed` 或 `effect` 函式內部讀取一個 `ref` 的 `.value` 時，神奇的事情發生了：

1.  在執行 `computed` 或 `effect` 函式之前，`alien_signals` 會設定一個全域的「當前監聽者」。
2.  當您存取 `ref.value` 時，`ref` 的 getter 會檢查這個「當前監聽者」是否存在。
3.  如果存在，`ref` 就會將這個「監聽者」（即那個 `computed` 或 `effect`）加入到它自己的訂閱者清單中。
4.  函式執行完畢後，全域的「當前監聽者」會被清除。

這就是為什麼您不需要手動聲明依賴關係。系統會自動記錄下誰依賴了誰。

## 更新流程

當您修改一個 `ref` 的值時（例如 `count.value++`），更新流程如下：

1.  `ref` 的 setter 被呼叫。
2.  `ref` 遍歷它內部儲存的訂閱者清單（所有依賴它的 `computed` 和 `effect`）。
3.  它會通知這些訂閱者：「我的值已經變了！」
4.  收到通知的 `computed` 會將自己標記為「過期」(stale)，但**不會立即重新計算**。它會等到下一次有人讀取它的 `.value` 時，才進行惰性計算 (Lazy Evaluation)。
5.  收到通知的 `effect` 會被加入到一個佇列中，由 `alien_signals` 的調度器 (Scheduler) 在一個微任務 (microtask) 中非同步地、批次地重新執行。

## 與 Flutter 的結合：`builder` 的角色

`CompositionWidget` 最巧妙的部分在於它如何將這個響應式系統與 Flutter 的 Widget 系統結合起來。

`_CompositionWidgetState` 將您的 `builder` 函式包裹在一個 `effect` 中。這個 `effect` 的內容大致如下：

```dart
// 這是一個簡化版的示意
_renderEffect = effect(() {
  // 執行您在 setup() 中返回的 builder 函式
  final newWidget = builder(context);

  // 如果產生的 Widget 與上次不同，就呼叫 setState
  if (_cachedWidget != newWidget) {
    setState(() {
      _cachedWidget = newWidget;
    });
  }
});
```

這意味著：

- 只有當 `builder` 函式內部使用的**響應式數據**發生變化時，`_renderEffect` 才會被重新執行。
- 只有當 `_renderEffect` 被重新執行時，`setState` 才有可能被呼叫。
- `setState` 只會觸發這個 `CompositionWidget` 自身的小範圍重建，而不是整個頁面。

這就是 `flutter_compositions` 能夠實現**細粒度更新**和**高效能**的秘密。它將 Flutter 粗粒度的 `setState` 機制，轉化為由底層響應式系統精確控制的自動化更新，讓開發者可以專注於業務邏輯，而無需手動管理狀態與 UI 的同步。
