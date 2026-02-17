import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_compositions/flutter_compositions.dart';

/// A read-only custom ref that allows manual control of tracking and
/// triggering.
///
/// This is a read-only version of [CustomRef] where the value cannot be set
/// directly. Only the [trigger] method can be used to notify dependent
/// computations.
///
/// This is typically used for wrapping external state systems like
/// [Listenable] where the value should not be directly settable.
///
/// Implements [ReadonlyRef] to provide a consistent interface with other
/// readonly reactive references.
class ReadonlyCustomRef<T> implements ReadonlyRef<T> {
  /// Creates a read-only custom ref.
  ReadonlyCustomRef({
    required T Function(void Function() track) getter,
  }) : _getter = getter,
       _version = ref(0);

  final T Function(void Function() track) _getter;
  final Ref<int> _version;

  /// Gets the current value. Reading this establishes a reactive dependency
  /// on the version counter, which is incremented when [trigger] is called.
  @override
  T get value {
    // Track the version (this establishes the reactive dependency)
    _version.value;

    // Call the getter with a no-op track callback
    // (tracking is already done by reading _version.value above)
    return _getter(() {});
  }

  /// Gets the raw value without establishing a reactive dependency.
  @override
  T get raw {
    // Don't track the version - just get the value
    return _getter(() {});
  }

  /// Manually triggers reactivity without setting a new value.
  ///
  /// This is useful when the underlying value has changed in a way that
  /// the reactive system wouldn't normally detect (e.g., mutation of
  /// an object's internal state, or notification from an external system).
  void trigger() {
    // Use .raw (untracked read) to avoid subscribing the currently running
    // effect to _version. In alien_signals 2.x, signal writes trigger
    // synchronous flush. If we used _version.value++ (tracked read + write),
    // the read would subscribe the current render effect, then the write
    // would propagate to that subscriber and flush synchronously, causing
    // re-entrance of the render effect during its first run.
    _version.value = _version.raw + 1;
  }
}

/// A custom ref that allows manual control of tracking and triggering.
///
/// Similar to Vue's `customRef`, this creates a ref where you have full control
/// over when dependencies are tracked and when updates are triggered.
///
/// Unlike regular [Ref] or [ComputedRef], `customRef` gives you manual control
/// via `track()` and `trigger()` callbacks:
/// - `track()`: Called in the getter to establish reactive dependencies
/// - `trigger()`: Called in the setter to notify dependent computations
///
/// This is useful for:
/// - Wrapping external state systems (like Listenable) in reactivity
/// - Debouncing or throttling updates
/// - Custom validation or transformation logic
///
/// Implements [WritableRef] to provide a consistent interface with other
/// writable reactive references.
///
/// Example - Wrapping a Listenable:
/// ```dart
/// CustomRef<ScrollController> useScrollController() {
///   final controller = ScrollController();
///
///   final custom = customRef<ScrollController>(
///     getter: (track) {
///       track(); // Establish dependency
///       return controller;
///     },
///     setter: (value, trigger) {
///       // Not used for controllers
///     },
///   );
///
///   void listener() {
///     custom.trigger(); // Notify when controller changes
///   }
///
///   controller.addListener(listener);
///   onUnmounted(() {
///     controller.removeListener(listener);
///     controller.dispose();
///   });
///
///   return custom;
/// }
/// ```
///
/// Example - Debounced ref:
/// ```dart
/// CustomRef<String> debouncedRef(String initial, Duration delay) {
///   var internalValue = initial;
///   Timer? timer;
///
///   return customRef<String>(
///     getter: (track) {
///       track();
///       return internalValue;
///     },
///     setter: (value, trigger) {
///       internalValue = value;
///       timer?.cancel();
///       timer = Timer(delay, () {
///         trigger(); // Only trigger after delay
///       });
///     },
///   );
/// }
/// ```
class CustomRef<T> implements WritableRef<T> {
  /// Creates a custom ref with manual track/trigger control.
  ///
  /// The [getter] function receives a `track()` callback that should be called
  /// to establish reactive dependencies.
  ///
  /// The [setter] function receives the new value and a `trigger()` callback
  /// that should be called to notify dependent computations.
  CustomRef({
    required T Function(void Function() track) getter,
    required void Function(T value, void Function() trigger) setter,
  }) : _getter = getter,
       _setter = setter,
       _version = ref(0);

  final T Function(void Function() track) _getter;
  final void Function(T value, void Function() trigger) _setter;
  final Ref<int> _version;

  /// Gets the current value. Reading this establishes a reactive dependency
  /// on the version counter, which is incremented when [trigger] is called.
  @override
  T get value {
    // Track the version (this establishes the reactive dependency)
    _version.value;

    // Call the getter with a no-op track callback
    // (tracking is already done by reading _version.value above)
    return _getter(() {});
  }

  /// Sets a new value. The setter callback decides whether to trigger updates.
  @override
  set value(T newValue) {
    _setter(newValue, () {
      _version.value = _version.raw + 1; // trigger() callback
    });
  }

  /// Gets the raw value without establishing a reactive dependency.
  @override
  T get raw {
    // Don't track the version - just get the value
    return _getter(() {});
  }

  /// Manually triggers reactivity without setting a new value.
  ///
  /// This is useful when the underlying value has changed in a way that
  /// the reactive system wouldn't normally detect (e.g., mutation of
  /// an object's internal state, or notification from an external system).
  ///
  /// Example:
  /// ```dart
  /// // External value changed, force update
  /// custom.trigger();
  /// ```
  void trigger() {
    // Use .raw (untracked read) to prevent self-subscription and
    // synchronous flush re-entrance in alien_signals 2.x.
    _version.value = _version.raw + 1;
  }
}

/// Creates a custom ref with manual track/trigger control.
///
/// See [CustomRef] for detailed documentation and examples.
CustomRef<T> customRef<T>({
  required T Function(void Function() track) getter,
  required void Function(T value, void Function() trigger) setter,
}) {
  return CustomRef(getter: getter, setter: setter);
}
