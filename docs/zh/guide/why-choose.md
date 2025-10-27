# 為什麼選擇 Flutter Compositions

Flutter 生態中已有多種狀態管理與組合工具，為何還需要 Flutter Compositions？以下從開發體驗、效能、資源管理到生態整合等面向，濃縮這個框架的核心價值，協助你判斷是否值得導入。

## 1. 開發體驗：接近 Vue 的宣告式流暢度

- `setup()` 將狀態初始、計算屬性、生命週期掛勾集中管理，語意明確。  
- `ref()`、`computed()`、`watch()` 的 API 與 Vue Composition API 幾乎一致，前端背景的成員能快速上手。  
- `CompositionBuilder` 讓一次性或內嵌的邏輯也能享受同樣的 reactive 模型。

## 2. 細粒度的響應式更新

`alien_signals` 追蹤 `.value` 的存取，只有用到變動資料的 UI 才會重建：

- 搭配 `ComputedBuilder` 可局部包裹高頻更新區域，避免整顆 Widget tree 重跑。  
- `watch` / `watchEffect` 支援副作用，確保只在必要時重新執行。  
- 透過 `provide` / `inject` 傳遞 `Ref`，資料更新不會牽動整個子樹重建。

## 3. 生命週期與資源管理一致化

- `onMounted`、`onUnmounted`、`onBuild`  等掛勾與 Vue 對齊，易記、可測試。  
- `useScrollController`、`useAnimationController` 等 `use*` 函式會自動在卸載時清理控制器，減少遺漏 `dispose` 的風險。  
- `watch` 註冊的 effect 皆綁定 `_SetupContext`，在 `dispose` 時自動撤銷。

## 4. 內建型別安全的依賴注入

- 透過 `InjectionKey<T>` 作為查詢 key，`provide` / `inject` 可傳遞 `Ref<T>` 或任意物件，同時保留 reactive 特性。  
- 泛型會參與相等性比較，避免把錯誤的 key/型別注入到子元件。  
- 不需額外套件即可跨組件共享設定、Service 或 ViewModel；若架構需要 Riverpod、GetIt 等亦能共存。

## 5. 熱重載與狀態保持

- `setup()` 內的 `Ref` 依宣告順序對應位置，熱重載時只要未更動順序就能保留狀態。  
- builder 重新執行時，僅受影響的 reactive 來源會觸發，再配合 `ComputedBuilder` 即可取得接近 Vue 的開發體驗。

## 6. 與其他工具的比較摘要

| 需求 | Flutter Compositions | flutter_hooks | 傳統 Provider / BLoC |
|------|----------------------|---------------|-----------------------|
| Vue 類似語法 | ✅ 幾乎一樣 | ⭕（Hook 概念相近） | ❌ |
| 細粒度更新 | ✅ 內建 signals | ⭕ 需手動切分 widget | ❌ 重建整個消費者 |
| 控制器自動釋放 | ✅ `use*` helper | ⭕ 需在 hook 中清理 | ❌ 需手動 dispose |
| 依賴注入 | ✅ `provide/inject` | ⭕ 需第三方 | ⭕ 依賴其他套件 |
| 生態成熟度 | ⭕ 正在成長 | ✅ 生態龐大 | ✅ 既有大量範例 |

詳細比較可參考：
- [與 `flutter_hooks` 的比較](/guide/flutter-hooks-comparison)  
- [與 Vue Composition API 的比較](/guide/vue-comparison)

## 7. 適合導入的情境

✅ 你希望 Flutter 專案擁有與 Vue 組合式 API 相近的體驗。  
✅ 團隊重視細粒度效能、想避免「整棵 Widget tree 重建」。  
✅ 需要統一管理控制器、訂閱與副作用的生命週期。  
✅ 想以型別安全的方式在專案中注入 Service 或設定資料。  
✅ 必須同時支援 Mobile、Web、Desktop，但仍想維持一致的 reactive 寫法。

## 8. 不一定適合的情境

❌ 專案完全依賴 UI builder 或 `setState` 且規模很小，導入成本大於收益。  
❌ 既有程式碼大量使用 `flutter_hooks` 或 Bloc，短期內無法大規模重構。  
❌ 團隊偏好使用外部狀態管理（如 Riverpod、Redux）集中處理邏輯。

## 9. 導入檢查清單

1. 確認核心元件是否可以改寫成 `CompositionWidget` 或 `CompositionBuilder`。  
2. 建立共用的 `use*` 函式，把常用控制器、Service 封裝成 composable。  
3. 以 `provide` / `inject` 重整跨層級傳遞的設定或 ViewModel。  
4. 將高頻率更新的區塊包成 `ComputedBuilder` 或獨立 component，減少重建。  
5. 參考指南中「[建立您自己的 Composables](/guide/creating-composables)」，建立團隊專屬的元件庫。

---

若你的團隊正在尋找一套「像 Vue 一樣好懂、又符合 Flutter 習慣」的組合式工具，Flutter Compositions 提供了兼具細膩效能與良好開發者體驗的選項。掌握 `setup()`、`ref()` 與 `provide/inject` 三大基石，就能在 Flutter 專案中享受到 Composition API 帶來的整潔架構與高維護性。
