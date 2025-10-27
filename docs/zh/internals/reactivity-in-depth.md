# 響應式系統詳解

> 本文件為繁體中文摘要。若想深入了解實作細節，建議閱讀英文版的 [Reactivity In Depth](../en/internals/reactivity-in-depth.md)。

## 三大基石

1. **Ref**：透過 `ref()` 建立可追蹤讀寫的反應式容器，讀取 `.value` 會建立依賴，寫入會通知訂閱者。
2. **Computed**：以 `computed()` 包裝衍生資料，採惰性計算並快取結果。
3. **Effect**：由 builder、`watch`、`watchEffect` 建立，負責在依賴變化時重新執行。

## 依賴追蹤與排程

- 執行 reactive 函式時，系統會暫存「目前觀察者」。
- 存取 `ref.value` 時將觀察者加入訂閱清單。
- 資料變動後使用 microtask 佇列批次重新執行 effect，以避免重複刷新。

## 與 Flutter 整合

- `CompositionWidget` 的 builder 被包裹在 effect 中，當依賴改變時呼叫 `setState`。
- Flutter 自身的 element diff 負責更新實際 widget tree。
- `onMounted`、`onUnmounted`、`onBuild` 對應到 Flutter 的生命週期與 build 流程。

## 常見技巧

- 搭配 `computed` 封裝昂貴計算，避免在 builder 內重複執行。
- 使用 `watch` 追蹤資料變化並觸發副作用（如導航、記錄 log）。
- 重新安排 `ref` 順序會影響 Hot Reload 的狀態保存，變動後請重新熱啟動 (Hot Restart)。

## 延伸閱讀

- [進階響應式技巧指南](../guide/reactivity.md)
- [Technical Deep Dive](./technical-deep-dive.md)
