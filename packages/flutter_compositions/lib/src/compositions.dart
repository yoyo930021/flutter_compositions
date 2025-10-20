part of 'framework.dart';

// =============================================================================
// Reactive Compositions API
// =============================================================================

/// A read-only reactive reference.
///
/// This is the base interface for all reactive references that can be read.
abstract class ReadonlyRef<T> {
  /// Gets the current value. Reading this establishes a reactive dependency.
  T get value;

  /// Gets the raw value without establishing a reactive dependency.
  ///
  /// Similar to Vue 3's `toRaw()`. This is useful when you need to access
  /// the value but don't want the current effect to re-run when this ref
  /// changes.
  ///
  /// **Use cases:**
  /// - Passing controllers to widgets without triggering reactivity
  /// - Reading values in callbacks without creating dependencies
  /// - Performance optimization when you know a value won't be used reactively
  ///
  /// Example - Pass controller without reactivity:
  /// ```dart
  /// final scrollController = useScrollController();
  /// return (context) => ListView(
  ///   controller: scrollController.raw, // Won't rebuild on scroll
  ///   children: [...],
  /// );
  /// ```
  T get raw;
}

/// A writable reactive reference interface.
///
/// Extends [ReadonlyRef] and adds a setter for the value.
/// All writable reactive types implement this interface.
abstract class WritableRef<T> implements ReadonlyRef<T> {
  /// Gets or sets the value. Reading establishes a reactive dependency.
  @override
  T get value;
  set value(T newValue);
}

/// A reactive reference, similar to Vue's Ref.
///
/// This is a simple wrapper around alien_signals' WritableSignal
/// to provide a Vue-like API.
///
/// Implements [WritableRef] to provide both read and write access.
class Ref<T> implements WritableRef<T> {
  /// Creates a [Ref] seeded with [initialValue].
  Ref(T initialValue) : _signal = signals.signal(initialValue);

  final signals.WritableSignal<T> _signal;

  /// Gets or sets the value.
  @override
  T get value => _signal.call();

  @override
  set value(T newValue) => _signal.call(newValue, true);

  @override
  T get raw => untracked(_signal.call);

  @override
  String toString() => 'Ref<$T>($value)';
}

/// Creates a reactive reference, similar to Vue's ref().
///
/// When used within a CompositionWidget's setup(), the ref is automatically
/// registered for hot reload state preservation based on its position in the
/// setup() function.
///
/// **Hot Reload State Preservation:**
/// - Refs are automatically tracked by their position in setup()
/// - As long as you don't reorder refs during hot reload, their values are
///   preserved
/// - Optional [debugLabel] can be provided for debugging purposes
///
/// Example:
/// ```dart
/// final count = ref(0);
/// count.value++;  // triggers reactive updates
/// print(count.value);
/// ```
///
/// **Hot Reload Behavior:**
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final count = ref(0);      // Position 0
///   final name = ref('Alice'); // Position 1
///
///   // During hot reload, as long as these refs stay in the same order,
///   // their values will be preserved automatically!
///
///   return (context) => Text('${count.value}');
/// }
/// ```
Ref<T> ref<T>(T initialValue, {String? debugLabel}) {
  final setupContext = getCurrentSetupContext();

  final refInstance = Ref<T>(
    setupContext
            ?.previousHotReloadableValues?[setupContext.hotReloadableIndex]
            as T? ??
        initialValue,
  );

  // Register the signal for hot reload preservation if in setup context
  setupContext?.addHotReloadable(
    _HotReloadableSignal(
      signal: refInstance._signal,
      type: T,
      debugLabel: debugLabel,
    ),
  );

  return refInstance;
}

/// A read-only computed reference, similar to Vue's ComputedRef.
///
/// Implements [ReadonlyRef] for read-only computed values.
/// Use [WritableComputedRef] or [writableComputed] for writable computed.
class ComputedRef<T> implements ReadonlyRef<T> {
  /// Creates a read-only computed ref whose value is produced by [getter].
  ComputedRef(T Function() getter)
    : _computed = signals.computed<T>((_) => getter());

  final signals.Computed<T> _computed;

  /// Gets the computed value.
  @override
  T get value => _computed.call();

  @override
  T get raw => untracked(_computed.call);

  @override
  String toString() => 'ComputedRef<$T>($value)';
}

/// A writable computed reference.
///
/// Implements [WritableRef] to provide both read and write access.
/// The getter tracks reactive dependencies and the setter allows modification.
class WritableComputedRef<T> implements WritableRef<T> {
  /// Creates a writable computed ref with the provided [getter] and [setter].
  WritableComputedRef(T Function() getter, void Function(T) setter)
    : _computed = signals.computed<T>((_) => getter()),
      _setter = setter;

  final signals.Computed<T> _computed;
  final void Function(T) _setter;

  /// Gets the computed value.
  @override
  T get value => _computed.call();

  /// Sets the computed value using the provided setter.
  @override
  set value(T newValue) {
    _setter(newValue);
  }

  @override
  T get raw => untracked(_computed.call);

  @override
  String toString() => 'WritableComputedRef<$T>($value)';
}

/// Creates a read-only computed value, similar to Vue's computed().
///
/// Returns a [ReadonlyRef] that automatically tracks reactive dependencies
/// and re-computes when they change.
///
/// **Type is automatically inferred from the getter's return type:**
/// ```dart
/// final count = ref(0);
/// final doubled = computed(() => count.value * 2);  // Type inferred as int
/// print(doubled.value); // 0
/// count.value = 1;
/// print(doubled.value); // 2
/// ```
ReadonlyRef<T> computed<T>(T Function() getter) {
  return ComputedRef<T>(getter);
}

/// Creates a writable computed value with custom getter and setter.
///
/// Returns a [WritableRef] that tracks dependencies via the getter and allows
/// modification via the setter.
///
/// **Type is automatically inferred from the getter's return type:**
/// ```dart
/// final count = ref(0);
/// final doubled = writableComputed(
///   get: () => count.value * 2,     // Return type inferred as int
///   set: (value) => count.value = value ~/ 2,
/// );
/// doubled.value = 10; // sets count.value to 5
/// print(count.value); // 5
/// print(doubled.value); // 10
/// ```
WritableRef<T> writableComputed<T>({
  required T Function() get,
  required void Function(T value) set,
}) {
  return WritableComputedRef<T>(get, set);
}

/// Watches a reactive source and calls a callback when it changes,
/// similar to Vue's watch().
///
/// When called within a CompositionWidget's setup(), the effect is
/// automatically tracked by the effectScope and will be disposed when
/// the component unmounts.
///
/// You can also manually dispose it by calling the returned dispose function.
///
/// **Type inference:** The type T is automatically inferred from the source
/// function.
///
/// Example:
/// ```dart
/// final count = ref(0);
///
/// // Type is automatically inferred as int
/// watch(() => count.value, (newValue, oldValue) {
///   print('Count changed from $oldValue to $newValue');
/// });
///
/// // The watch will be automatically cleaned up when component unmounts
/// ```
///
/// **Immediate execution:**
/// ```dart
/// watch(() => count.value, (newValue, oldValue) {
///   print('Initial: $newValue');
/// }, immediate: true);
/// ```
void Function() watch<T>(
  T Function() source,
  void Function(T newValue, T? oldValue) callback, {
  bool immediate = false,
}) {
  assert(
    getCurrentSetupContext() != null,
    'watch() must be called within setup() of CompositionWidget or '
    'CompositionBuilder.\n'
    'The effect created by watch() needs to be tracked by an effectScope '
    'to be automatically disposed on unmount.\n'
    'If you need to use watch() outside of setup, use signals.effect() '
    'directly and manually dispose it.',
  );

  var previousValue = null as T?;
  var isFirst = true;

  final effect = signals.effect(() {
    final newValue = source();
    if (isFirst) {
      isFirst = false;
      if (immediate) {
        callback(newValue, null);
      }
      previousValue = newValue;
    } else {
      callback(newValue, previousValue);
      previousValue = newValue;
    }
  });

  // Effect is automatically tracked by the active effectScope (if any)
  // No need to manually register

  // Return dispose function
  return effect.dispose;
}

/// Runs a function and automatically re-runs it when reactive dependencies
/// change, similar to Vue's `watchEffect`.
///
/// When called within a CompositionWidget's setup(), the effect is
/// automatically tracked by the effectScope and will be disposed when
/// the component unmounts.
///
/// You can also manually dispose it by calling the returned dispose function.
///
/// Example:
/// ```dart
/// final count = ref(0);
/// watchEffect(() {
///   print('Count is: ${count.value}');
/// });
///
/// // The effect will be automatically cleaned up when component unmounts
/// ```
void Function() watchEffect(void Function() callback) {
  assert(
    getCurrentSetupContext() != null,
    'watchEffect() must be called within setup() of CompositionWidget or '
    'CompositionBuilder.\n'
    'The effect created by watchEffect() needs to be tracked by an '
    'effectScope to be automatically disposed on unmount.\n'
    'If you need to use watchEffect() outside of setup, use '
    'signals.effect() directly and manually dispose it.',
  );

  final effect = signals.effect(callback);

  // Effect is automatically tracked by the active effectScope (if any)
  // No need to manually register

  // Return dispose function
  return effect.dispose;
}

/// Executes a function without tracking reactive dependencies.
///
/// Similar to Vue 3's `untracked()`, this allows you to read reactive values
/// without establishing a reactive dependency. This is useful when you need
/// to access a ref's value but don't want the current effect to re-run when
/// that ref changes.
///
/// This is particularly useful for performance optimization when passing
/// controllers to widgets without needing reactive updates.
///
/// Example - Pass controller without triggering reactivity:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final scrollController = useScrollController();
///
///   return (context) => ListView(
///     // Reading without tracking - won't rebuild on scroll
///     controller: untracked(() => scrollController.value),
///     children: [...],
///   );
/// }
/// ```
///
/// Example - Mix tracked and untracked reads:
/// ```dart
/// final count = ref(0);
/// final multiplier = ref(2);
///
/// final result = computed(() {
///   final c = count.value;  // Tracked - will re-compute on change
///   final m = untracked(() => multiplier.value);  // Not tracked
///   return c * m;
/// });
/// // Result only re-computes when count changes, not when multiplier changes
/// ```
T untracked<T>(T Function() callback) {
  final prevSub = signals.getActiveSub();
  signals.setActiveSub(null);
  try {
    return callback();
  } finally {
    signals.setActiveSub(prevSub);
  }
}
