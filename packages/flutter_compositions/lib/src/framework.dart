import 'dart:async';

import 'package:alien_signals/alien_signals.dart' as signals;
import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/src/composables/animation_composables.dart'
    show useSingleTickerProvider;
import 'package:flutter_compositions/src/injection_key.dart';

part 'compositions.dart';

/// Interface for values that support hot reload state preservation.
///
/// Values implementing this interface can be automatically preserved
/// across hot reloads by tracking their raw values.
abstract class HotReloadable<T> {
  /// Gets the raw value without establishing reactive dependencies
  T get raw;

  /// Optional debug label for debugging hot reload issues
  String? get debugLabel;
}

class _HotReloadableSignal<T> implements HotReloadable<T> {
  _HotReloadableSignal({
    required this.signal,
    required this.type,
    required this.debugLabel,
  });

  final signals.WritableSignal<T> signal;
  final Type type;
  @override
  final String? debugLabel;

  @override
  T get raw => untracked(signal.call);
}

class _HotReloadableContainer<T> implements HotReloadable<T> {
  _HotReloadableContainer(
    this.value, {
    required this.debugLabel,
  });

  final T value;

  @override
  final String? debugLabel;

  @override
  T get raw => value;
}

/// Creates a hot-reloadable container that preserves state across hot reloads.
T hotReloadableContainer<T>(
  T Function() createFn, {
  String? debugLabel,
}) {
  final context = getCurrentSetupContext();

  assert(
    context != null,
    'hotReloadableContainer must be called within setup() of '
    'CompositionWidget or CompositionBuilder',
  );

  final value =
      context!.previousHotReloadableValues?[context.hotReloadableIndex] as T? ??
      createFn();

  context.addHotReloadable(
    _HotReloadableContainer<T>(
      value,
      debugLabel: debugLabel,
    ),
  );

  return value;
}

/// Internal registry for tracking the current setup context during setup().
///
/// This is used by both CompositionWidget and CompositionBuilder to track
/// which context is currently executing setup(), enabling composables to
/// access the correct context.
class _SetupContextRegistry {
  /// Current setup context (package-private for framework use)
  static SetupContextImpl? current;
}

/// Gets the current setup context, which can be either CompositionWidget or
/// CompositionBuilder.
///
/// Returns null if not currently in a setup() call.
///
/// This is the unified API for accessing the setup context, making it easier
/// to write composables that work with both CompositionWidget and
/// CompositionBuilder.
SetupContext? getCurrentSetupContext() {
  return _SetupContextRegistry.current;
}

/// Interface for setup context (internal use only)
abstract class SetupContext {
  /// Previous hot reloadable values (for restoring state)
  Map<int, dynamic>? get previousHotReloadableValues;

  /// List of hot-reloadable values created during setup, in order
  List<HotReloadable<dynamic>> get hotReloadables;

  /// Current position when creating new hot-reloadable values during setup
  int get hotReloadableIndex;

  /// Helper method to add a hot-reloadable value entry
  void addHotReloadable(HotReloadable<dynamic> entry);

  // Lifecycle callbacks
  /// Registers [callback] to run after the widget is mounted.
  void addMountedCallback(VoidCallback callback);

  /// Registers [callback] to run before the widget is unmounted.
  void addUnmountedCallback(VoidCallback callback);

  /// Registers [callback] to run on every build
  /// (when builder function executes).
  void addBuildCallback(void Function(BuildContext) callback);

  /// The reactive signal that represents the current widget instance.
  signals.WritableSignal<CompositionWidget>? get widgetSignal;

  /// Sets the reactive signal that represents the current widget instance.
  set widgetSignal(signals.WritableSignal<CompositionWidget>? value);

  /// Stores [value] so descendants can retrieve it with [inject].
  void provideValue(Object key, dynamic value);

  /// Retrieves a value previously stored with [provideValue].
  dynamic getProvided(Object key);

  /// Initializes the render effect that rebuilds when reactive
  /// dependencies change.
  /// Should be called in didChangeDependencies.
  void initializeRenderEffect(
    BuildContext context,
    Widget Function(BuildContext) builder,
    void Function() scheduleRebuild,
  );

  /// Disposes all resources (effects, callbacks, etc.)
  void dispose();

  /// Triggers all mounted callbacks
  void triggerMounted();

  /// Triggers all unmounted callbacks
  void triggerUnmounted();

  /// Triggers all build callbacks
  void triggerBuild(BuildContext context);
}

/// Mixin that provides shared setup context logic for both
/// CompositionWidget and CompositionBuilder states.
///
/// This mixin eliminates code duplication by providing common
/// lifecycle, render effect, and dependency injection logic.
mixin SetupContextMixin<T extends StatefulWidget> on State<T>
    implements SetupContext {
  SetupContextImpl? _setupContext;
  Widget Function(BuildContext)? _builder;

  /// Gets the setup context instance
  SetupContextImpl? get setupContext => _setupContext;

  /// Sets up the setup context with the given builder function.
  /// Must be called in initState.
  void initializeSetupContext({
    required Widget Function(BuildContext) Function() setupFunction,
    SetupContext? parent,
    signals.WritableSignal<CompositionWidget>? widgetSignal,
  }) {
    _setupContext = SetupContextImpl();

    // Set parent context for provide/inject
    if (parent != null) {
      _setupContext!.parent = parent;
    }

    // Set widget signal if provided (for CompositionWidget)
    if (widgetSignal != null) {
      _setupContext!.widgetSignal = widgetSignal;
    }

    // Run setup within an effect scope using the registry
    final previousContext = _SetupContextRegistry.current;
    final setupCtx = _setupContext!;
    _SetupContextRegistry.current = setupCtx;
    try {
      setupCtx.effectScope = signals.effectScope(() {
        _builder = setupFunction();
      });
    } finally {
      _SetupContextRegistry.current = previousContext;
    }

    // Trigger onMounted after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupContext?.triggerMounted();
      }
    });
  }

  /// Initializes the render effect in didChangeDependencies
  void initializeRenderEffectIfNeeded(BuildContext context) {
    if (_builder != null) {
      _setupContext?.initializeRenderEffect(
        context,
        _builder!,
        () {
          if (mounted) {
            setState(() {
              // Widget is already updated in _setupContext.cachedWidget
            });
          }
        },
      );
    }
  }

  /// Disposes the setup context
  void disposeSetupContext() {
    _setupContext?.triggerUnmounted();
    _setupContext?.dispose();
  }

  /// Handles hot reload by re-running setup
  void reassembleSetupContext({
    required Widget Function(BuildContext) Function() setupFunction,
  }) {
    if (_setupContext == null) return;

    // Capture current values before re-running setup
    _setupContext!._setPreviousHotReloadValues(_captureHotReloadableValues());

    // Reset index for new setup execution
    _setupContext!.resetHotReload();

    // Dispose old effect scope
    _setupContext!.effectScope?.dispose();

    // Clear old callbacks and hot-reloadables
    _setupContext!.clearCallbacks();
    _setupContext!.clearHotReloadables();

    // Clear cached widget
    _setupContext!.clearCache();

    // Re-run setup to get new builder using the registry
    final previousContext = _SetupContextRegistry.current;
    final setupCtx = _setupContext!;
    _SetupContextRegistry.current = setupCtx;
    try {
      setupCtx.effectScope = signals.effectScope(() {
        _builder = setupFunction();
      });
    } finally {
      _SetupContextRegistry.current = previousContext;
    }

    // Recreate render effect
    _setupContext!._setPreviousHotReloadValues(null);
    initializeRenderEffectIfNeeded(context);
  }

  /// Captures current values of all tracked hot reloadable containers
  Map<int, dynamic> _captureHotReloadableValues() {
    final values = <int, dynamic>{};
    for (var i = 0; i < _setupContext!.hotReloadables.length; i++) {
      final entry = _setupContext!.hotReloadables[i];
      values[i] = entry.raw;
    }
    return values;
  }

  /// Finds the parent SetupContext by walking up the Element tree
  static SetupContext? findParentSetupContext(BuildContext context) {
    SetupContext? parentContext;
    context.visitAncestorElements((element) {
      // Only check StatefulElements
      if (element is! StatefulElement) {
        return true; // Continue searching
      }

      final state = element.state;

      // Check if state implements SetupContext
      if (state is SetupContext) {
        parentContext = state as SetupContext;
        return false; // Stop searching
      }

      return true; // Continue searching
    });
    return parentContext;
  }

  // SetupContext implementation - delegate to _setupContext

  @override
  Map<int, dynamic>? get previousHotReloadableValues =>
      _setupContext?.previousHotReloadableValues;

  @override
  List<HotReloadable<dynamic>> get hotReloadables =>
      _setupContext?.hotReloadables ?? [];

  @override
  int get hotReloadableIndex => _setupContext?.hotReloadableIndex ?? 0;

  @override
  void addHotReloadable(HotReloadable<dynamic> entry) {
    _setupContext?.addHotReloadable(entry);
  }

  @override
  void addMountedCallback(VoidCallback callback) {
    _setupContext?.addMountedCallback(callback);
  }

  @override
  void addUnmountedCallback(VoidCallback callback) {
    _setupContext?.addUnmountedCallback(callback);
  }

  @override
  void addBuildCallback(void Function(BuildContext) callback) {
    _setupContext?.addBuildCallback(callback);
  }

  @override
  signals.WritableSignal<CompositionWidget>? get widgetSignal =>
      _setupContext?.widgetSignal;

  @override
  set widgetSignal(signals.WritableSignal<CompositionWidget>? value) {
    if (_setupContext != null) {
      _setupContext!.widgetSignal = value;
    }
  }

  @override
  void provideValue(Object key, dynamic value) {
    _setupContext?.provideValue(key, value);
  }

  @override
  dynamic getProvided(Object key) {
    return _setupContext?.getProvided(key);
  }

  @override
  void initializeRenderEffect(
    BuildContext context,
    Widget Function(BuildContext) builder,
    void Function() scheduleRebuild,
  ) {
    _setupContext?.initializeRenderEffect(context, builder, scheduleRebuild);
  }

  @override
  void triggerMounted() {
    _setupContext?.triggerMounted();
  }

  @override
  void triggerUnmounted() {
    _setupContext?.triggerUnmounted();
  }

  @override
  void triggerBuild(BuildContext context) {
    _setupContext?.triggerBuild(context);
  }

  /// Gets the cached widget for rendering
  Widget? get cachedWidget => _setupContext?.cachedWidget;
}

/// Internal implementation of SetupContext.
/// Used by both _CompositionWidgetState and CompositionBuilderState.
/// Package-private for use in composition_builder.dart.
class SetupContextImpl implements SetupContext {
  final List<VoidCallback> _mountedCallbacks = [];
  final List<VoidCallback> _unmountedCallbacks = [];
  final List<void Function(BuildContext)> _buildCallbacks = [];

  /// Effect scope for managing reactive effects (package-private)
  signals.EffectScope? effectScope;
  final Map<Object, dynamic> _provided = {};
  signals.WritableSignal<CompositionWidget>? _widgetSignal;

  /// Parent context for provide/inject (package-private)
  SetupContext? parent;

  /// Previous hot reloadable values (for restoring state)
  Map<int, dynamic>? _previousHotReloadableValues;

  /// List of hot-reloadable values created during setup, in order
  /// Used for position-based hot reload state preservation
  final List<HotReloadable<dynamic>> _hotReloadables = [];

  /// Current position when creating new hot-reloadable values during setup
  int _hotReloadableIndex = 0;

  /// Shared render effect state
  signals.Effect? _renderEffect;
  Widget? _cachedWidget;
  bool _isInitialized = false;
  bool _pendingRebuild = false;

  /// Helper method to add a hot-reloadable value entry
  /// Called from compositions.dart (part file) for signal registration
  void _addHotReloadableEntry(HotReloadable<dynamic> entry) {
    _hotReloadables.add(entry);
    _hotReloadableIndex++;
  }

  // SetupContext implementation
  @override
  Map<int, dynamic>? get previousHotReloadableValues =>
      _previousHotReloadableValues;

  @override
  List<HotReloadable<dynamic>> get hotReloadables => _hotReloadables;

  @override
  int get hotReloadableIndex => _hotReloadableIndex;

  @override
  void addHotReloadable(HotReloadable<dynamic> entry) {
    _addHotReloadableEntry(entry);
  }

  @override
  void addMountedCallback(VoidCallback callback) {
    _mountedCallbacks.add(callback);
  }

  @override
  void addUnmountedCallback(VoidCallback callback) {
    _unmountedCallbacks.add(callback);
  }

  @override
  void addBuildCallback(void Function(BuildContext) callback) {
    _buildCallbacks.add(callback);
  }

  @override
  signals.WritableSignal<CompositionWidget>? get widgetSignal => _widgetSignal;

  @override
  set widgetSignal(signals.WritableSignal<CompositionWidget>? value) {
    _widgetSignal = value;
  }

  @override
  void provideValue(Object key, dynamic value) {
    _provided[key] = value;
  }

  @override
  dynamic getProvided(Object key) {
    // Check current context
    if (_provided.containsKey(key)) {
      return _provided[key];
    }
    // Check parent contexts
    return parent?.getProvided(key);
  }

  @override
  void initializeRenderEffect(
    BuildContext context,
    Widget Function(BuildContext) builder,
    void Function() scheduleRebuild,
  ) {
    if (_isInitialized) return;
    _isInitialized = true;

    // Create render effect that only calls the builder function
    // The builder function re-runs when reactive dependencies change
    _renderEffect = signals.effect(() {
      // Trigger build callbacks before builder execution
      triggerBuild(context);

      final newWidget = builder(context);

      // First build: set cache directly without setState
      if (_cachedWidget == null) {
        _cachedWidget = newWidget;
        return;
      }

      // Subsequent updates: use batched setState to avoid multiple rebuilds
      // in the same frame when multiple signals change
      _cachedWidget = newWidget;

      if (!_pendingRebuild) {
        _pendingRebuild = true;

        // Schedule rebuild in next microtask to batch multiple signal changes
        scheduleMicrotask(() {
          if (_pendingRebuild) {
            _pendingRebuild = false;
            scheduleRebuild();
          }
        });
      }
    });
  }

  /// Gets the cached widget for rendering
  Widget? get cachedWidget => _cachedWidget;

  /// Clears the cached widget (used for hot reload)
  void clearCache() {
    _cachedWidget = null;
    _isInitialized = false;
  }

  /// Resets the hot reload state
  void resetHotReload() {
    _hotReloadableIndex = 0;
  }

  /// Sets previous hot reload values (for hot reload state restoration)
  // ignore: use_setters_to_change_properties
  void _setPreviousHotReloadValues(Map<int, dynamic>? values) {
    _previousHotReloadableValues = values;
  }

  /// Clears all callbacks (used for hot reload)
  void clearCallbacks() {
    _mountedCallbacks.clear();
    _unmountedCallbacks.clear();
    _buildCallbacks.clear();
  }

  /// Clears all hot-reloadables (used for hot reload)
  void clearHotReloadables() {
    _hotReloadables.clear();
  }

  @override
  void triggerMounted() {
    for (final callback in _mountedCallbacks) {
      callback();
    }
  }

  @override
  void triggerUnmounted() {
    for (final callback in _unmountedCallbacks) {
      callback();
    }
  }

  @override
  void triggerBuild(BuildContext context) {
    for (final callback in _buildCallbacks) {
      callback(context);
    }
  }

  @override
  void dispose() {
    _pendingRebuild = false;
    // Dispose render effect first
    _renderEffect?.dispose();
    _renderEffect = null;
    // Dispose the effect scope, which will dispose all effects created within
    effectScope?.dispose();
    effectScope = null;
    _mountedCallbacks.clear();
    _unmountedCallbacks.clear();
    _buildCallbacks.clear();
  }
}

/// Registers a callback to be called when the component is mounted,
/// similar to Vue's onMounted().
///
/// Must be called within the setup() method of CompositionWidget or
/// CompositionBuilder.
void onMounted(VoidCallback callback) {
  final context = getCurrentSetupContext();

  assert(
    context != null,
    'onMounted must be called within setup() of CompositionWidget or '
    'CompositionBuilder',
  );

  context?.addMountedCallback(callback);
}

/// Registers a callback to be called when the component is unmounted,
/// similar to Vue's onUnmounted().
///
/// Must be called within the setup() method of CompositionWidget or
/// CompositionBuilder.
void onUnmounted(VoidCallback callback) {
  final context = getCurrentSetupContext();

  assert(
    context != null,
    'onUnmounted must be called within setup() of CompositionWidget or '
    'CompositionBuilder',
  );

  context?.addUnmountedCallback(callback);
}

/// Registers a callback to be called on every build.
///
/// The callback is called when the builder function executes, which happens
/// on every reactive update.
///
/// This is useful for composables that need to react to BuildContext changes,
/// such as TickerMode tracking.
///
/// **Note**: This is an internal API primarily used by composables like
/// [useSingleTickerProvider]. Most users should not need to call this
/// directly.
///
/// Must be called within the setup() method of CompositionWidget or
/// CompositionBuilder.
void onBuild(void Function(BuildContext) callback) {
  final context = getCurrentSetupContext();

  assert(
    context != null,
    'onBuild must be called within setup() of CompositionWidget or '
    'CompositionBuilder',
  );

  context?.addBuildCallback(callback);
}

/// Provides a value that can be injected by descendant components,
/// similar to Flutter's Provider package but scoped to composition trees.
///
/// Must be called within the setup() method.
///
/// Uses [InjectionKey] for type-safe dependency injection, preventing
/// conflicts when multiple values of the same type need to be provided.
///
/// Example:
/// ```dart
/// // Define injection keys
/// final themeKey = InjectionKey<Ref<String>>('theme');
/// final userNameKey = InjectionKey<Ref<String>>('userName');
///
/// class ParentComponent extends CompositionWidget {
///   @override
///   Widget Function(BuildContext) setup() {
///     final theme = ref('dark');
///     final userName = ref('Alice');
///
///     // Provide with keys - no conflicts!
///     provide(themeKey, theme);
///     provide(userNameKey, userName);
///
///     return (context) => ChildComponent();
///   }
/// }
///
/// class ChildComponent extends CompositionWidget {
///   @override
///   Widget Function(BuildContext) setup() {
///     // Inject by key - type safe!
///     final theme = inject(themeKey);
///     final userName = inject(userNameKey);
///
///     return (context) =>
///       Text('Theme: ${theme.value}, User: ${userName.value}');
///   }
/// }
/// ```
void provide<T>(InjectionKey<T> key, T value) {
  final context = getCurrentSetupContext();

  assert(
    context != null,
    'provide() must be called within setup(). '
    'Make sure you are calling provide() inside the setup() method '
    'of a CompositionWidget or CompositionBuilder.',
  );

  context?.provideValue(key, value);
}

/// Injects a value provided by an ancestor component using an [InjectionKey].
///
/// Must be called within the setup() method.
///
/// The value is looked up by the [InjectionKey], enabling type-safe
/// dependency injection without type conflicts.
///
/// Returns the provided value if found.
/// If [defaultValue] is provided and the key is not found, returns the default.
/// Otherwise, throws an error when not found.
///
/// Example with required dependency:
/// ```dart
/// final themeKey = InjectionKey<Ref<String>>('theme');
///
/// class ChildComponent extends CompositionWidget {
///   @override
///   Widget Function(BuildContext) setup() {
///     // Inject by key - throws if not found
///     final theme = inject(themeKey);
///
///     return (context) => Text('Theme: ${theme.value}');
///   }
/// }
/// ```
///
/// Example with optional dependency:
/// ```dart
/// final optionalKey = InjectionKey<String>('optional');
///
/// class ChildComponent extends CompositionWidget {
///   @override
///   Widget Function(BuildContext) setup() {
///     // Inject with default value
///     final value = inject(
///       optionalKey,
///       defaultValue: 'default',
///     );
///
///     return (context) => Text('Value: $value');
///   }
/// }
/// ```
T inject<T>(
  InjectionKey<T> key, {
  Object? defaultValue = const _NoDefaultValue(),
}) {
  final context = getCurrentSetupContext();

  assert(
    context != null,
    'inject() must be called within setup(). '
    'Make sure you are calling inject() inside the setup() method '
    'of a CompositionWidget or CompositionBuilder.',
  );

  if (context == null) {
    // Fallback for release mode
    if (defaultValue is! _NoDefaultValue) {
      return defaultValue as T;
    }
    throw StateError('inject() called outside of setup context');
  }

  final value = context.getProvided(key);

  if (value == null) {
    // Check if a default value was provided
    if (defaultValue is! _NoDefaultValue) {
      return defaultValue as T;
    }

    throw StateError(
      'No provider found for injection key "${key.symbol}" '
      'with type "$T".\n'
      '\n'
      'To fix this:\n'
      '  1. Make sure a parent CompositionWidget calls provide() '
      'with this key\n'
      '  2. Verify the key matches: provide($key, value)\n'
      '  3. If the dependency is optional, provide a defaultValue parameter\n'
      '\n'
      'Example:\n'
      '  // In parent:\n'
      '  provide($key, myValue);\n'
      '  \n'
      '  // In child:\n'
      '  final value = inject($key);\n'
      '  // Or with default:\n'
      '  final value = inject($key, defaultValue: myDefault);',
    );
  }

  return value as T;
}

/// Sentinel value to distinguish "no default provided" from "null default"
class _NoDefaultValue {
  const _NoDefaultValue();
}

/// A [Widget] that uses Vue Composition API style.
///
/// Unlike React hooks which run on every build, the [setup] method
/// runs only once when the widget is first created, similar to Vue's setup().
/// Reactive updates are handled automatically by alien_signals.
///
/// ## ⚠️ Important: Using Props Reactively
///
/// **DO NOT** directly access widget properties in setup()!
/// Properties accessed directly will NOT be reactive.
///
/// ```dart
/// // Specify the type parameter as the class itself
/// class UserProfile extends CompositionWidget {
///   const UserProfile({required this.userId});
///   final String userId;
///
///   @override
///   Widget Function(BuildContext) setup() {
///     // ❌ WRONG: Direct access - NOT reactive!
///     final text = computed(() => 'User: $userId');
///
///     // ✅ CORRECT: Use widget() for reactive props
///     final props = widget();
///     final text2 = computed(() => 'User: ${props.value.userId}');
///
///     return (context) => Text(text2.value);
///   }
/// }
/// ```
///
/// Example without props:
/// ```dart
/// class Counter extends CompositionWidget {
///   const Counter({super.key});
///
///   @override
///   Widget Function(BuildContext) setup() {
///     final count = ref(0);
///
///     return (context) => Text('Count: ${count.value}');
///   }
/// }
/// ```
abstract class CompositionWidget extends StatefulWidget {
  /// Creates a [CompositionWidget].
  const CompositionWidget({super.key});

  /// Setup function that runs only once, similar to Vue's setup().
  ///
  /// Use [CompositionWidgetExtension.widget] (available as `widget()` or
  /// `this.widget()`) to get a reactive reference to this widget's props.
  /// The returned [ComputedRef] is typed to the concrete widget class.
  ///
  /// Access props with `.value` to ensure reactivity is tracked correctly.
  ///
  /// Create your reactive state and computed values here.
  /// Return a builder function that will be called when reactive
  /// dependencies change.
  ///
  /// The builder function receives BuildContext and should return a Widget.
  /// When any reactive dependency used in the builder changes, the builder
  /// will be called again to rebuild the widget.
  ///
  /// Note: Do NOT access InheritedWidgets (Theme, MediaQuery, etc.) in setup.
  /// Access them in the returned builder function instead, as setup only runs
  /// once.
  ///
  /// Example:
  /// ```dart
  /// class UserProfile extends CompositionWidget {
  ///   const UserProfile({required this.userId, required this.name});
  ///
  ///   final String userId;
  ///   final String name;
  ///
  ///   @override
  ///   Widget Function(BuildContext) setup() {
  ///     // No type annotation needed!
  ///     final props = widget();
  ///
  ///     final greeting = computed(() => 'Hello, ${props.value.name}!');
  ///
  ///     return (context) => Text(greeting.value);
  ///   }
  /// }
  /// ```
  Widget Function(BuildContext) setup();

  @override
  State<CompositionWidget> createState() => _CompositionWidgetState();
}

class _CompositionWidgetState extends State<CompositionWidget>
    with SetupContextMixin<CompositionWidget> {
  late signals.WritableSignal<CompositionWidget> _widgetSignal;

  @override
  void initState() {
    super.initState();

    // Create a reactive signal for the widget instance
    _widgetSignal = signals.signal(widget);

    // Initialize setup context using mixin
    initializeSetupContext(
      setupFunction: widget.setup,
      parent: SetupContextMixin.findParentSetupContext(context),
      widgetSignal: _widgetSignal,
    );
  }

  @override
  void didUpdateWidget(CompositionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the widget signal when props change
    _widgetSignal.call(widget, true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeRenderEffectIfNeeded(context);
  }

  @override
  Widget build(BuildContext context) {
    return cachedWidget ?? const SizedBox.shrink();
  }

  @override
  void dispose() {
    disposeSetupContext();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    reassembleSetupContext(
      setupFunction: widget.setup,
    );
  }
}

/// Extension on [CompositionWidget] that provides reactive widget access.
extension CompositionWidgetExtension<T extends CompositionWidget> on T {
  /// Gets a reactive reference to the current widget instance.
  ///
  /// Similar to `State.widget` in StatefulWidget, but reactive.
  /// Must be called within the setup() method on `this`.
  ///
  /// Returns a `ComputedRef<T>` that updates when parent passes new props.
  /// Access widget properties with `.value` to ensure reactivity is tracked.
  ///
  /// Example:
  /// ```dart
  /// class UserProfile extends CompositionWidget {
  ///   const UserProfile({
  ///     super.key,
  ///     required this.userId,
  ///     required this.name,
  ///   });
  ///
  ///   final String userId;
  ///   final String name;
  ///
  ///   @override
  ///   Widget Function(BuildContext) setup() {
  ///     // Get reactive widget reference (similar to State.widget)
  ///     final w = this.widget();
  ///
  ///     // Access widget properties with .value
  ///     final greeting = computed(() => 'Hello, ${w.value.name}!');
  ///
  ///     watch(() => w.value.userId, (newId, oldId) {
  ///       print('User ID changed: $oldId -> $newId');
  ///     });
  ///
  ///     return (context) => Text(greeting.value);
  ///   }
  /// }
  /// ```
  ComputedRef<T> widget() {
    final context = getCurrentSetupContext();

    assert(
      context != null,
      'widget() must be called within setup(). '
      'Similar to State.widget, but must be called during setup phase.',
    );

    final original = context?.widgetSignal;
    assert(
      original != null,
      'widget() can only be called from CompositionWidget, not '
      'CompositionBuilder. CompositionBuilder does not have props.',
    );
    return ComputedRef<T>(() => original!() as T);
  }
}
