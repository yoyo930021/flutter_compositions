# Flutter Compositions vs Vue Composition API

Flutter Compositions draws heavy inspiration from Vue, yet the platforms differ. This guide highlights what carries over and what changes.

## Similarities

- **Composition mindset**: Declare reactive state, computed values, and lifecycle hooks inside `setup()`.
- **Core primitives**: `ref`, `computed`, `watch`, and dependency injection with `provide` / `inject`.
- **Lifecycle naming**: `onMounted`, `onUnmounted`, `onBuild` mirror Vue’s hooks.

## Key Differences

| Aspect | Flutter Compositions | Vue Composition API |
|--------|---------------------|----------------------|
| Rendering | Returns a Flutter widget tree | Returns render functions / template state |
| Reactivity engine | `alien_signals` (explicit refs) | Vue’s proxy-based reactivity |
| Hot reload | re-runs `setup()`; refs preserved by declaration order | reruns `setup()` automatically; proxies keep deep reactivity |
| Dependency injection | `InjectionKey<T>` for compile-time safety | Keys are string/symbol; type safety is up to you |

## Working with Props

- In Flutter, props are immutable fields. Use `widget<T>()` to get a reactive view of the latest props.
- In Vue, props are already reactive proxies accessed directly.

## Updating the UI

- Compositions relies on Flutter’s widget diff. Only widgets that read changed refs rebuild.
- Vue patches the virtual DOM; the framework updates DOM nodes directly.

## Porting Tips

1. Convert Vue `ref`/`reactive` to Flutter `ref` or custom model classes.
2. Replace template directives (`v-if`, `v-for`) with Flutter widgets (`if`/`switch`, `ListView.builder`).
3. Map Vue plugins/providers to `InjectionKey` + `provide/inject`.

## Further Reading

- Compare with `flutter_hooks`: [Flutter vs flutter_hooks](./flutter-hooks-comparison.md)
- Deep dive on the runtime: [Reactivity In Depth](../internals/reactivity-in-depth.md)
- Original Chinese article: [點我閱讀](../../guide/vue-comparison.md)
