/// Flutter Compositions provides Vue-like composition utilities for Flutter.
///
/// Build widgets with a `setup` function and fine-grained reactivity powered by
/// the `alien_signals` package.
library;

export 'src/composables/animation_composables.dart'
    show manageAnimation, useAnimationController, useSingleTickerProvider;
export 'src/composables/async_composables.dart'
    show
        AsyncData,
        AsyncError,
        AsyncIdle,
        AsyncLoading,
        AsyncValue,
        useAsyncData,
        useAsyncValue,
        useFuture,
        useStream,
        useStreamController;
export 'src/composables/controller_composables.dart'
    show
        useFocusNode,
        usePageController,
        useScrollController,
        useTextEditingController;
export 'src/composables/framework_composables.dart'
    show useAppLifecycleState, useContext, useSearchController;
export 'src/composables/listenable_composables.dart'
    show manageChangeNotifier, manageListenable, manageValueListenable;
export 'src/composition_builder.dart'
    show CompositionBuilder, CompositionBuilderCallback, CompositionSetup;
export 'src/computed_builder.dart' show ComputedBuilder;
export 'src/custom_ref.dart' show CustomRef, ReadonlyCustomRef, customRef;
export 'src/framework.dart'
    show
        CompositionWidget,
        CompositionWidgetExtension,
        ComputedRef,
        ReadonlyRef,
        Ref,
        WritableComputedRef,
        WritableRef,
        computed,
        inject,
        onBuild,
        onMounted,
        onUnmounted,
        provide,
        ref,
        untracked,
        watch,
        watchEffect,
        writableComputed;
export 'src/injection_key.dart' show InjectionKey;
