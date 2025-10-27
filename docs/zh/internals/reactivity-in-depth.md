# 響應式系統詳解

Flutter Compositions 建立在 Flutter widget 系統之上，但透過細粒度響應式 runtime 來驅動更新。以下是運作方式。

## 核心組成

### Ref

呼叫 `ref(value)` 會回傳 `Ref<T>`，它會攔截對 `.value` 的所有讀寫。

- 讀取時會將目前的 reactive 觀察者（builder、`computed`、`watch` 等）註冊為訂閱者。
- 寫入時會標記該 ref 為髒並通知所有訂閱者重新執行。

### Computed

`computed(() => ...)` 會延後執行傳入函式，並在依賴變化前快取結果；行為類似備忘錄（memoized）getter。

### Effect

builder、`watch`、`watchEffect` 都會建立 effect。每個 effect 會記錄自身讀取過的 ref，任何 ref 變動都會讓 effect 重新執行。

## 依賴追蹤

1. 執行 reactive 函式前，runtime 會將它推入「目前觀察者」堆疊。
2. 當 `ref.value` 被讀取時，會把最上層觀察者加入訂閱清單。
3. 函式結束後，觀察者會被彈出堆疊。
4. 當 `.value` 改變時，該 ref 會將所有訂閱者排入重新執行佇列。

這套流程與 Vue 的 reactivity 模型一脈相承。

## 排程器

更新會被聚合在 microtask queue 中：

1. Setter 將 ref 標記為髒並排入觀察者。
2. Runtime 會去重觀察者，避免重複執行。
3. Microtask 執行時，觀察者依序重新執行。對 Flutter 而言，這些效果最終會觸發一般的 `setState` rebuild。

## 與 Flutter 整合

- `CompositionWidget` 僅在 `setup()` 期間建立一次 builder，接著將它註冊為 effect。
- 當依賴變動時，builder 會呼叫 `setState`，讓 Flutter 進行既有的 widget diff。
- 生命週期掛勾（`onMounted`、`onUnmounted`、`onBuild`）共用同一套排程機制，確保與 Flutter lifecycle 對齊。

## 避免常見陷阱

- **Props 陳舊**：改用 `widget<T>()` 取得 reactive props，確保讀到最新值。
- **就地修改集合**：改以建立新 List/Map (`todos.value = [...todos.value, todo]`)，讓 runtime 能偵測更新。
- **非同步閉包**：在 callback 內即時讀取最新的 ref，避免捕捉舊值。

## 工具支援

Runtime 暴露 `onCleanup`，讓每個 effect 都能註冊釋放邏輯。像 `watch`、`useStream` 等 composable 便利用這個機制自動移除監聽。

## 效能特性

- 讀取 ref 的成本為 O(1)。
- 寫入成本與訂閱該 ref 的 effect 數量成比例。
- builders 維持細粒度：只有讀取變動 ref 的 widget 會重新建構。

## ComputedBuilder 工具

`ComputedBuilder` 會為包裹的 UI 建立獨立的 reactive effect。當其內部讀取的 ref 變動時，只有這段 subtree 被重建。

- 適合包裝更新頻繁的區塊，避免拖累父層。
- 搭配 `computed` 可避免昂貴計算重複執行。
- 建議控制範圍維持精簡，以取得最佳效益。

內部實作會在 `initState` 註冊 effect，變動時觸發 `setState`，並在 widget 卸載時自動清理，無須手動釋放。

## 延伸閱讀

- [響應式基礎](../guide/reactivity-fundamentals.md)
- [進階響應式技巧](../guide/reactivity.md)
- [ComputedBuilder API](https://pub.dev/documentation/flutter_compositions/latest/flutter_compositions/ComputedBuilder-class.html)
