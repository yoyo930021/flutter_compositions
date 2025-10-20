---
layout: home

hero:
  name: "Flutter Compositions"
  text: "為 Flutter 打造的響應式組合 API"
  tagline: 靈感源自 Vue Composition API，由 alien_signals 驅動，提供極致的效能與開發體驗。
  actions:
    - theme: brand
      text: 快速上手
      link: /guide/getting-started
    - theme: alt
      text: 為什麼選擇本框架？
      link: /internals/design-trade-offs

features:
  - title: 組合式 (Composable)
    details: 將 UI 邏輯封裝在可重用的 `composable` 函式中，告別巨大的 Widget build 方法。
  - title: 細粒度響應式 (Fine-Grained Reactivity)
    details: 只有真正依賴的數據發生變化時，UI 的特定部分才會更新，無需手動呼叫 setState()，避免不必要的 Widget 重建。
  - title: 型別安全 (Type-Safe)
    details: 利用 Dart 強大的型別系統，提供完全型別安全的依賴注入 (provide/inject) 和屬性 (props)。
  - title: 簡單直觀 (Simple & Intuitive)
    details: 熟悉的 `ref`, `computed`, `watch` API，讓具備 Vue 或 React Hooks 開發經驗的開發者能快速上手。
---
