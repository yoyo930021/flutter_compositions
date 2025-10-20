# API Reference

Complete API documentation for Flutter Compositions.

## Core APIs

### Reactivity
- [ref, computed, writableComputed](./reactivity.md) - Reactive state primitives
- [watch, watchEffect](./watch.md) - Side effects and watchers
- [customRef](./custom-ref.md) - Custom reactive references

### Widget
- [CompositionWidget](./composition-widget.md) - Base widget class
- [CompositionBuilder](./composition-builder.md) - Functional composition API

### Lifecycle
- [onMounted, onUnmounted, onBuild](./lifecycle.md) - Lifecycle hooks

### Dependency Injection
- [provide, inject](./provide-inject.md) - Dependency injection
- [InjectionKey](./injection-key.md) - Type-safe injection keys

## Composables

### Controllers
- [useScrollController](./composables/controllers.md#usescrollcontroller)
- [usePageController](./composables/controllers.md#usepagecontroller)
- [useFocusNode](./composables/controllers.md#usefocusnode)
- [useTextEditingController](./composables/controllers.md#usetexteditingcontroller)

### Animations
- [useAnimationController](./composables/animations.md#useanimationcontroller)
- [useSingleTickerProvider](./composables/animations.md#usesingletic kerprovider)
- [manageAnimation](./composables/animations.md#manageanimation)

### Async Operations
- [useFuture](./composables/async.md#usefuture)
- [useAsyncData](./composables/async.md#useasyncdata)
- [useAsyncValue](./composables/async.md#useasyncvalue)
- [useStream](./composables/async.md#usestream)
- [useStreamController](./composables/async.md#usestreamcontroller)

### Listenable Integration
- [manageListenable](./composables/listenable.md#managelistenable)
- [manageValueListenable](./composables/listenable.md#managevaluelistenable)
- [manageChangeNotifier](./composables/listenable.md#managechangenotifier)

### Framework
- [useContext](./composables/framework.md#usecontext)
- [useAppLifecycleState](./composables/framework.md#useapplifecyclestate)
- [useSearchController](./composables/framework.md#usesearchcontroller)

## Types

### AsyncValue
- [AsyncValue, AsyncIdle, AsyncLoading, AsyncData, AsyncError](./types/async-value.md)

### Ref Types
- [Ref, WritableRef, ReadonlyRef, ComputedRef, WritableComputedRef](./types/refs.md)

## Utilities

- [ComputedBuilder](./utilities/computed-builder.md) - Builder widget for computed values
