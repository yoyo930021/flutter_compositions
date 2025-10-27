# 設計取捨

> 本章節概述 Flutter Compositions 在設計上的主要取捨。欲了解更詳細的討論，可閱讀英文版的 [Design Trade-offs](../en/internals/design-trade-offs.md)。

## 與 Flutter 傳統模式相比

- **優點**：提供類似 Vue Composition API 的開發體驗，邏輯集中在 `setup()`，狀態可透過 composable 重複使用。
- **挑戰**：心理模型與傳統 `StatefulWidget` 不同，需要重新熟悉 `ref`、`computed`、`watch` 的運作方式。

## Runtime 層的代價

- 引入 `alien_signals` 以支援細粒度 reactivity，需額外了解 effect 與 dependency tracking。
- debug 時必須同時考量 Flutter lifecycle 與 Composition 的 lifecycle hooks。

## Hot Reload 行為

- `setup()` 在 Hot Reload 時會重新執行，並依照 `ref` 宣告順序還原狀態。
- 改變宣告順序或刪除某個 ref 可能導致狀態錯位，必要時請使用 Hot Restart。

## 依賴注入策略

- 使用 `InjectionKey` 可避免型別衝突，但所有依賴都常駐在記憶體中；若需延後載入或釋放，需要額外管理。
- 建議建立明確的提供層級（App / Feature / Widget），讓團隊知道依賴應該在哪裡被提供。

## 推薦的團隊約定

1. **統一程式結構**：例如 `features/<name>/composables`、`services`、`widgets`。
2. **Lint 全開**：使用 `flutter_compositions_lints` 提醒常見錯誤。
3. **文件化 Hot Reload 指南**：提醒成員避免隨意調換 ref 順序。

## 延伸閱讀

- [最佳實務指南](../guide/best-practices.md)
- [Architecture 概觀](./architecture.md)
- [Technical Deep Dive](./technical-deep-dive.md)
