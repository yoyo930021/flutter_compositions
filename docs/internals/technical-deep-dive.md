# 技術深入解析

> 這裡提供官方技術深入解析的繁體中文摘要。欲掌握完整實作細節請參考英文版的 [Technical Deep Dive](../en/internals/technical-deep-dive.md)。

## setup() 執行流程

1. 建立 `_SetupContext`：用來記錄 `ref`、生命週期掛勾與 hot reload 狀態。
2. 呼叫 `setup()`：在 effect scope 中執行，回傳 builder。
3. 快取 builder：`initializeRenderEffect` 將 builder 包裝成 effect，以 reactive 方式重新執行。

## Hot Reload 支援

- 每個 `ref` / `hotReloadableContainer` 會依宣告順序被追蹤。
- Hot Reload 時重新執行 `setup()`，並套用之前記錄的值。
- 只要不改動宣告順序，就能維持現有狀態。

## Composable 如何整合

- `useScrollController`、`useAnimationController` 等 helper 透過 `onUnmounted` 自動釋放資源。
- `watch` / `watchEffect` 會在 effect scope 中註冊清理函式，避免記憶體洩漏。

## provide / inject 內部原理

- 提供者將資料儲存在 `_SetupContext` 的 `_provided` map 裡。
- 注入時會沿著父層 `_SetupContext` 向上尋找，類似 Flutter 的 `InheritedWidget`，但不會觸發整棵 widget tree 重建。

## 延伸閱讀

- [架構概觀](./architecture.md)
- [響應式系統詳解](./reactivity-in-depth.md)
- [最佳實務指南](../guide/best-practices.md)
