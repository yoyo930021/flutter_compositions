# 設計理念與取捨

任何框架或函式庫的設計都伴隨著一系列的取捨。了解 `flutter_compositions` 背後的設計理念和所做的權衡，可以幫助您更深入地理解其優勢和適用場景。

## 核心設計哲學

本函式庫的建立基於以下幾個核心目標：

1.  **開發者體驗優先**: 我們相信，借鑒 Vue Composition API 中 `ref`, `computed`, `watch` 這樣直觀且強大的模式，可以極大地簡化 Flutter 的狀態管理，讓開發者從手動的 `setState` 中解放出來。

2.  **效能源於精準**: 透過 `alien_signals` 提供的細粒度響應式系統，我們旨在實現一個「預設即高效能」的框架。UI 的更新應該是外科手術式的精準打擊，而不是地毯式的轟炸（即整個子樹的非必要重建）。

3.  **組合優於繼承**: 提倡將 UI 邏輯拆分成小的、可重用的 `composable` 函式，而不是建立龐大而複雜的 `StatefulWidget` 類別。這使得程式碼更易於維護、重構和測試。

## 技術取捨分析

### `provide`/`inject` vs. `InheritedWidget`

`provide`/`inject` 是本框架內建的依賴注入機制。它與 Flutter 原生的 `InheritedWidget` 有明顯的設計差異。

| 特性 | `provide`/`inject` | `InheritedWidget` |
|---|---|---|
| 查找時間 | O(n)，n 為祖先深度 | O(1) |
| 更新機制 | 手動（透過 `Ref`） | 自動觸發重建 |
| 重建範圍 | 無，僅更新依賴的 `builder` | 所有依賴的後代 |
| 設置成本 | `initState` 時一次性 | 每次 `build` |

**取捨考量**: 
我們選擇了 O(n) 的父層鏈查找，而不是 `InheritedWidget` 的 O(1) 查找。為什麼？

- **為了避免不必要的重建**：`InheritedWidget` 的核心功能是在其值變化時，重建所有依賴它的後代。這與我們的細粒度更新哲學相悖。`provide`/`inject` 傳遞的是一個 `Ref`（引用），即使 `Ref` 內部的值變化了，`provide`/`inject` 機制本身也不會觸發任何重建。只有真正使用了這個 `Ref` 的 `builder` 才會更新。
- **在淺層樹中效能足夠**: 對於大多數應用場景，組件樹的深度是相對較淺的（< 10 層），O(n) 查找的效能開銷完全可以忽略不計。

**結論**: 當您需要傳遞**響應式狀態**時，請使用 `provide`/`inject`。當您需要傳遞真正全域、不常變動的配置（如 `ThemeData`）時，`InheritedWidget` 仍然是很好的選擇。

### `widget()` API 的必要性

您可能會好奇，為什麼我們需要 `widget().value.prop` 這樣稍顯繁瑣的語法來存取屬性，而不是直接用 `this.prop`？

**取捨考量**:
這是由 `setup` 只執行一次的核心設計所決定的。

- **問題**: 如果在 `setup` 中直接存取 `this.prop`，它只會是 Widget 第一次建立時的初始值。當父層傳入新的屬性時，`setup` 不會重新執行，因此無法獲取到更新。
- **解決方案**: 我們在 `State` 中維護一個 `WritableSignal` (`_widgetSignal`)。在 `didUpdateWidget` 生命週期中，每當新的 Widget 實例傳入，我們就更新這個 `signal`。`widget()` API 返回的 `ComputedRef` 實際上就是對這個 `signal` 的訂閱。

**結論**: `widget()` API 是在「`setup` 只執行一次」帶來的好處（無需重複初始化）和「需要響應屬性變化」的矛盾之間找到的一個明確且高效的平衡點。它雖然增加了一點學習成本，但換來了完全的響應式能力和清晰的數據流。

### 對 `alien_signals` 的依賴

**取捨考量**:

- **優點**: `alien_signals` 是目前 Dart 生態中最快的響應式函式庫之一。直接利用其堅實的基礎，讓我們可以專注於與 Flutter 結合的上層 API 設計，而無需重新發明輪子。
- **缺點**: 本函式庫的效能與 `alien_signals` 緊密綁定。同時，這也意味著我們的核心行為受其設計約束。

**結論**: 這是一個策略性的選擇。我們認為，利用一個專注於把響應式核心做到極致的底層函式庫，是比自己從頭打造一個更明智的選擇。這使得 `flutter_compositions` 更加輕量和專注。
