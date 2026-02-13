---
layout: home

hero:
  name: "Flutter Compositions"
  text: "Reactive Composition API for Flutter"
  tagline: Inspired by Vue Composition API, powered by alien_signals for ultimate performance and developer experience.
  actions:
    - theme: brand
      text: Get Started
      link: /guide/introduction
    - theme: alt
      text: Quick Start
      link: /guide/getting-started
    - theme: alt
      text: Lint Setup
      link: /lints/

features:
  - title: Composable
    details: Encapsulate UI logic into reusable composable functions and say goodbye to massive Widget build methods.
  - title: Fine-Grained Reactivity
    details: Only the specific parts of your UI that depend on a piece of state will update when it changes. No more manual setState() calls or unnecessary widget rebuilds.
  - title: Type-Safe
    details: Leverage Dart's powerful type system for fully type-safe dependency injection (provide/inject) and props.
  - title: Simple & Intuitive
    details: With a familiar API (`ref`, `computed`, `watch`), developers with Vue or React Hooks experience will feel right at home.
  - title: Hot Reload Friendly
    details: Hot reload reruns setup() while preserving `ref` state order, so tweaks to code keep your live data intact.
---
