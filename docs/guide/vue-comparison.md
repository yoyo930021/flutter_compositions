# Flutter Compositions vs Vue Composition API：API 與運作原理對照

Flutter Compositions 幾乎從 Vue Composition API 汲取靈感，但礙於語言、runtime 與渲染模式不同，最終呈現的 API 與內部機制仍存在差異。以下從「如何撰寫」與「底層怎麼運作」兩個角度拆解。

## 1. `setup()` 形態與回傳值

| 面向 | Flutter Compositions | Vue Composition API |
|------|----------------------|--------------------|
| 位置 | `CompositionWidget.setup()` 或 `CompositionBuilder` 的 `setup` | SFC 的 `setup()`、`script setup`、或 render function |
| 回傳值 | 必須回傳 `Widget Function(BuildContext)`（或 `CompositionBuilderCallback`） | 可回傳 render function，或回傳物件供 `<template>` 使用 |
| UI 描述 | 純 Dart Widget tree | HTML template / JSX / render function |

**意義**：兩者都在 `setup()` 中宣告 reactive 狀態，但 Flutter 仍須手動建立 Widget tree；Vue 可以直接依靠模板語法。

## 2. Reactive 核心實作

| 要素 | Flutter Compositions | Vue Composition API |
|------|----------------------|--------------------|
| Reactive 容器 | `Ref<T>`（`ref()` 建立）、`ComputedRef<T>`（`computed()` 建立） | `ref()` / `reactive()` 返回 Proxy；`computed()` 建立 Getter-based ref |
| 依賴追蹤 | 在 `.value` getter 中向 `alien_signals` 註冊依賴 | 在 Proxy getter 中向 Vue reactivity 追蹤器註冊依賴 |
| Effect 調度 | `effect` 以 microtask 批次執行；`watch` / `watchEffect` 建立副作用 | Effect queue + Scheduler，同樣以 microtask 觸發 |
| 更新範圍 | 依賴變動時會重新執行整個 builder（即該 `CompositionWidget` 的子樹），Flutter 再以 Element diff 只更新實際變動的部分 | 只 patch 受影響的虛擬 DOM 節點 |
| 物件/陣列響應性 | **淺層**：`Ref` 只追蹤 `.value` 的引用，若要響應須重新指定 `ref.value = {...}` | **深層**：`reactive()` Proxy 直接攔截物件與陣列的成員變動 |

**重點差異**：Flutter Compositions 以顯式的 `Ref` 容器運作；Vue 靠 Proxy 改寫物件存取。兩者同樣達成細粒度更新，但實作手段截然不同。

## 3. 組合式 API 的使用方式

- **Flutter**：在 `setup()` 內宣告 `final count = ref(0);`，最後回傳 `(context) => Text('${count.value}')`。計算屬性與副作用分別以 `computed()`、`watch()` 撰寫。  
- **Vue**：在 `setup()` 內 `const count = ref(0)`，模板 `<span>{{ count }}</span>` 會自動展開；或於 render function 中回傳 `h('span', count.value)`。

實務上，Flutter 需刻意把結果綁到 Widget；Vue 模板則自動展開 `Ref`。

## 4. 生命週期掛勾對照

| Flutter Compositions | Vue Composition API | 說明 |
|----------------------|--------------------|------|
| `onMounted` | `onMounted` | 第一次繪製完成後觸發 |
| `onUnmounted` | `onUnmounted` | 元件卸載前觸發 |
| `onBuild` | `onUpdated` / `watchEffect` | 每次 builder 執行對應於 Vue 更新後的副作用 |
| `onMounted(async)` | `onMounted(async)` | 皆可在掛勾內執行非同步流程 |

命名幾乎一致，但 Flutter 的 `onBuild` 是每次 builder 執行前觸發；Vue 的 `onUpdated` 則在 DOM patch 後。

## 5. 依賴注入：key 與型別的差異

| 面向 | Flutter Compositions | Vue Composition API |
|------|----------------------|--------------------|
| API | `provide(key, value)` / `inject(key, { defaultValue })` | `provide(key, value)` / `inject(key, default)` |
| Key 類型 | `InjectionKey<T>`（通常為 `const`） | 字串、Symbol、或物件 |
| 型別安全 | 泛型參與 `InjectionKey` 的 `==` 與 `hashCode`，防止錯誤注入 | 需自行確保 key 與值的型別一致 |
| Reactive 傳遞 | 建議提供 `Ref<T>`；子層取得後仍是 reactive | 須傳遞 `ref()` 或 `reactive()` 才能保持響應式 |

## 6. 狀態作用域與組合

- **Flutter Compositions**：`setup()` 每次只執行一次，`use*` 函式可產生可重複使用的 composable。跨 widget 重用邏輯時，可將組合式函式抽成 Dart 函式，回傳多個 `Ref` 或方法。
- **Vue**：`setup()` 在每個 component 實例呼叫；可封裝成 `useXxx()` composable 供多個 component 使用，回傳 `ref`、`computed`、`method` 等。

兩者皆支援將組合式邏輯抽出成獨立函式，只是輸出物件的型態與語法不同。

## 7. 渲染與更新管線

| 面向 | Flutter Compositions | Vue Composition API |
|------|----------------------|--------------------|
| 渲染目標 | Flutter Widget → RenderObject → Skia/Canvas | Virtual DOM → 真實 DOM |
| 更新時機 | `effect` 重新執行 builder，Framework 比對 Element | Vue 重新執行 render function 或 template，並做 DOM diff |
| UI 切分 | 可搭配 `ComputedBuilder`、獨立小部件 | 自動以 VDOM patch 分攤 |

因此，雖然 reactive 模型相似，Flutter 終究得依賴 Widget 建構，每次更新都是「重新建立 Widget tree」；Vue 則是產生新的 VDOM 再 diff。

## 8. 核心差異總表

| 面向 | Flutter Compositions | Vue Composition API |
|------|----------------------|--------------------|
| 語言與平台 | Dart / Flutter runtime | JavaScript / Browser runtime |
| `setup()` 產物 | `Widget Function(BuildContext)` | Render function 或 template state |
| Reactive 容器 | 顯式 `Ref<T>`、`ComputedRef<T>` | Proxy-based `ref()`、`reactive()` |
| Effect 調度 | `alien_signals` effect queue | Vue reactivity scheduler |
| DI key | `InjectionKey<T>` | 字串 / Symbol |
| 渲染流程 | Widget rebuild → Element diff | Virtual DOM diff → DOM patch |

---

**總結**：兩者皆提供 Composition API 的思維——在 `setup()` 中建立 reactive state、使用掛勾管理生命週期、透過 provide/inject 分享資料。但 Flutter Compositions 受限於 Widget-based UI，需要回傳 Widget builder，並以 **淺層 `Ref`** 搭配 Element diff 達成更新；Vue 則使用 Proxy 與模板語法，自帶 **深層響應式** 與 DOM diff。在跨框架遷移或共享設計概念時，理解這些 API 與運作原理的差異，能更貼切地調整心智模型。
