# Flutter Compositions 與 `flutter_hooks` 的比較

兩者都想讓 Flutter 應用程式擺脫傳統 `StatefulWidget`／`setState` 的繁瑣，但著力點並不相同。以下從多個維度盤點差異，協助你在專案中選擇合適的工具。

## 1. API 風格

| 面向 | Flutter Compositions | flutter_hooks |
|------|----------------------|---------------|
| 建構方式 | 透過 `CompositionWidget.setup()`（或 `CompositionBuilder`）一次性宣告 reactive 狀態與掛勾 | 於 `HookWidget` / `HookConsumerWidget` 內，直接呼叫 `useState`、`useEffect` 等 hook 函式 |
| 撰寫體驗 | 類似 Vue Composition API：集中在 `setup()` 內建立狀態，再回傳 builder | 類似 React Hooks：在 build function 底下依序呼叫 hook，依靠「呼叫順序一致」維持狀態 |
| 限制 | `setup()` 只能呼叫一次，生命週期 API 必須在此註冊 | 必須遵守「Hook 只能在最頂端呼叫」規則，否則會觸發 runtime 例外 |

## 2. 響應式模型

- **Flutter Compositions**：以 `alien_signals` 為核心，`ref()`、`computed()`、`watch()` 組成可組合的資料流。widget builder 隱式包在 reactive effect 裡，只更新有依賴的區塊。
- **flutter_hooks**：Hook 主要就是封裝了 `StatefulWidget` 的 `State` 與 `State` 的某個欄位 (`useState`)、或 `State` + `dispose` (`useEffect`)。狀態仍然以 `useState().value`、`useRef()` 等形式存在，沒有額外的細粒度追蹤。

實務效果是：
- Compositions 的 builder 重跑時，只會因為 `Ref` 或 `Computed` 的實際變化而觸發。
- flutter_hooks 的 hook 值更新後，整個 `build` 會再次執行，仍需手動將 widget 拆解以避免重建成本。

## 3. 生命週期與清理

| 功能 | Flutter Compositions | flutter_hooks |
|------|----------------------|---------------|
| 掛勾註冊 | `onMounted`、`onUnmounted`、`onBuild` 等在 `setup()` 中呼叫 | `useEffect`、`useMemoized`、`useOnLifecycleEvent` 等在 build function 中呼叫 |
| 資源釋放 | `useScrollController` 等 `use*` helper 會自動綁定 `_SetupContext`，於 `dispose` 時清理 | 多數 hooks 需在 `useEffect` 內回傳清理函式，或依賴 hook 自帶的 `dispose` 行為 |
| 條件式呼叫保護 | 框架在 `setup()` 建立時即檢查，不允許在條件內呼叫 reactive API | 依賴 hook 規則；若違反呼叫順序，runtime 會丟出錯誤 |

## 4. 控制器與平台資源

- **Flutter Compositions**：提供 `useScrollController`、`usePageController`、`useAnimationController` 等 helper，回傳 reactive `Ref` 並保證自動 `dispose`。
- **flutter_hooks**：雖有 `useTextEditingController`、`useAnimationController` 等 hooks，但多數情況下仍需要在 hook 的回傳函式中手動釋放，或依賴 `Hook` 類別擴充。

## 5. 熱重載與狀態保存

- Compositions 會為每個 `setup()` 內建的 `Ref` 指派穩定位置，熱重載時只要宣告順序不變就能保留狀態。
- flutter_hooks 也能保留 hook 狀態，但若加入／刪除 hook 破壞呼叫順序，會在熱重載後收到「Hook order changed」錯誤並重置狀態。

## 6. 依賴注入與組合

- **Compositions**：內建 `InjectionKey<T>` + `provide/inject`，可以安全地傳遞 `Ref<T>` 或任何服務物件，且保持 reactive 更新。
- **flutter_hooks**：沒有官方 DI 機制，常見做法是搭配 Riverpod、Provider、GetIt 等套件；hooks 本身僅處理狀態。

## 7. 生態與擴充性

- `flutter_hooks` 擁有廣大社群與許多現成的 Hook（如 `useFuture`、`useStream`）以及與 Riverpod 的整合。
- Flutter Compositions 專注在細粒度 reactivity 與自帶的 `use*` 工具，目前社群規模較小，但與 alien_signals、provide/inject 深度整合。

## 8. 適用情境建議

| 若你需要… | 可以考慮 Flutter Compositions | 可以考慮 flutter_hooks |
|-------------|--------------------------------|-------------------------|
| 細粒度的 reactive 更新、避免 rebuild | ✅ | ⭕（需手動優化） |
| 近似 Vue Composition API 的寫法 | ✅ | ⭕（語法不同） |
| 已有 hooks 生態、想沿用現成 hook | ⭕ | ✅ |
| 快速為既有 StatefulWidget 引入局部 hook | ⭕ | ✅ |
| 型別安全的依賴注入（InjectionKey） | ✅ | ⭕（需第三方套件） |

### 總結

- **Flutter Compositions**：適合偏好宣告式 reactive 模型、需要 provide/inject、想透過 `Ref` 精準控制重建的團隊。
- **flutter_hooks**：如果你熟悉 React Hooks 或已有大量 Hook 範例，想快速在 Flutter 中導入函式式組件風格，它依舊是成熟的選項。 
