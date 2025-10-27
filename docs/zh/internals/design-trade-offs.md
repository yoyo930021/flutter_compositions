# 設計取捨

Flutter Compositions 在開發體驗與細粒度更新之間取了一組平衡，但也帶來相對應的成本。

## 與 Flutter 傳統模式相比

- **優點**：`setup()`、`ref`、`computed`、生命週期掛勾等概念貼近 Vue Composition API，熟悉者能快速上手並重複使用邏輯。
- **缺點**：與傳統 `StatefulWidget` 心智模型不同，新成員需要時間熟悉新的抽象。

## Runtime 層的代價

- **優點**：以 `alien_signals` 為基礎的 runtime 提供精準的依賴追蹤與自動清理。
- **缺點**：疊在 Flutter lifecycle 之上後，與舊有 `StatefulWidget` 混用時的除錯複雜度增加。

## 單次 `setup()` 執行

- **優點**：所有狀態集中於 `setup()`，生命週期語意可預期且與 Vue 相仿。
- **缺點**：props 不會自動成為 reactive，需要透過 `widget<T>()` 取用，容易被忽略。

## Hot Reload 行為

- **優點**：Hot Reload 會重新執行 `setup()` 並依宣告順序重建 refs，因此大多數狀態能保留。
- **缺點**：調整或刪除某個 ref 容易造成狀態錯位，必要時需執行 Hot Restart。

## 依賴注入策略

- **優點**：`InjectionKey` 在編譯期提供型別安全，不需要手刻 `InheritedWidget`。
- **缺點**：所有提供的服務都常駐記憶體；若需延後載入或釋放，必須額外管理生命週期。

## 細粒度重建

- **優點**：只要 ref 未變動，builder 就不會重跑，大幅減少不必要的 rebuild。
- **缺點**：Flutter Inspector 等工具習慣以 rebuild 視覺化狀態，反而可能讓偵錯較不直覺。

## 推薦的團隊約定

- 啟用 `flutter_compositions_lints` 或自訂 lint 規則，強制使用 `widget<T>()` 與 `InjectionKey`。
- 逐步封裝舊有 widget，避免一次性遷移造成負擔。
- 建立明確的專案結構（例如 `features/<name>/composables`、`services`、`widgets`）。
- 文件化依賴注入層級與 Hot Reload 注意事項，讓新成員能快速對齊。

## 延伸閱讀

- [最佳實務指南](../guide/best-practices.md)
- [Architecture 概觀](./architecture.md)
- [Technical Deep Dive](./technical-deep-dive.md)
