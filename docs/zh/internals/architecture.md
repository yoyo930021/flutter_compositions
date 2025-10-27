# 架構概觀

## 核心組成

| 元件 | 角色 |
|------|------|
| `CompositionWidget` | 對外公開的 widget，開發者在 `setup()` 中宣告狀態並回傳 builder。 |
| `_CompositionWidgetState` | 實際的 `State` 物件，負責呼叫 `setup()`、管理 reactive builder 與生命週期。 |
| `_SetupContext` | 儲存 `ref`、`computed`、生命週期掛勾與 provide/inject 內容的內部容器。 |
| `alien_signals` | 支援細粒度 reactivity 的訊號系統。 |

## 生命週期流程

1. `initState`：建立 `SetupContext`，執行 `setup()`，取得 builder。
2. `didChangeDependencies`：初始化 reactive builder，註冊成 effect。
3. `build`：回傳快取的 widget，當依賴變化時自動刷新。
4. `dispose`：呼叫 `onUnmounted`、釋放 effect 與控制器。

## 為何需要這一層 Runtime？

- **組合式 API**：讓 Flutter 開發者擁有類似 Vue Composition API 的開發體驗。
- **細粒度更新**：只有讀取變動 ref 的 builder 才會重新執行。
- **自動清理**：`useScrollController`、`useAnimationController` 等 helper 會自動釋放資源。

## 整合重點

- 生命週期掛勾（`onMounted`、`onUnmounted`、`onBuild`）對應到 Flutter 的生命週期方法。
- 依賴注入 (`provide`/`inject`) 透過 `_SetupContext` 的 parent chain 進行傳遞。
- Composable 會透過 runtime 建立 refs 並註冊清理邏輯，確保資源釋放。

## 延伸閱讀

- [Technical Deep Dive](./technical-deep-dive.md)
- [響應式系統詳解](./reactivity-in-depth.md)
- [設計取捨](./design-trade-offs.md)
