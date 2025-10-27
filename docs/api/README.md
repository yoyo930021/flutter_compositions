# API 參考

完整的 Flutter Compositions API 文件。

## 核心 API

### 響應式
- [ref, computed, writableComputed](./reactivity.md) - 響應式狀態原始型別
- [watch, watchEffect](./watch.md) - 副作用與監看器
- [customRef](./custom-ref.md) - 客製化響應式參照

### Widget
- [CompositionWidget](./composition-widget.md) - 基礎組合式 Widget 類別
- [CompositionBuilder](./composition-builder.md) - 函式式組合 API

### 生命週期
- [onMounted, onUnmounted, onBuild](./lifecycle.md) - 生命週期掛勾

### 依賴注入
- [provide, inject](./provide-inject.md) - 依賴注入工具
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
