import 'package:alien_signals/alien_signals.dart' as signals;
import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/src/framework.dart';

/// Signature for the builder callback used by [CompositionBuilder].
///
/// The builder receives a [BuildContext] and should return a [Widget].
/// This function runs inside a reactive effect, so any reactive dependencies
/// (ref, computed, etc.) accessed within will trigger rebuilds when they
/// change.
typedef CompositionBuilderCallback = Widget Function(BuildContext context);

/// Signature for the setup callback used by [CompositionBuilder].
///
/// The setup function is called once when the builder is first created.
/// It can create reactive state (ref, computed), register lifecycle callbacks
/// (onMounted, onUnmounted), and set up watchers (watch, watchEffect).
///
/// The setup function should return a [CompositionBuilderCallback] that will
/// be called to build the widget tree.
///
/// Similar to CompositionWidget.setup, but used inline without defining
/// a class.
typedef CompositionSetup = CompositionBuilderCallback Function();

/// A function-based alternative to CompositionWidget that can be used
/// inline without defining a class, similar to StatefulBuilder.
///
/// This is useful in scenarios where you cannot or don't want to define
/// a new widget class, such as:
/// - Inside builder callbacks
/// - For one-off stateful widgets
/// - Quick prototyping
///
/// Supports all composition APIs including:
/// - Reactive state (`ref`, `computed`)
/// - Lifecycle hooks (`onMounted`, `onUnmounted`)
/// - Watchers (`watch`, `watchEffect`)
/// - Dependency injection (`provide`, `inject`)
/// - Hot reload state preservation
///
/// ## Basic Example
///
/// ```dart
/// CompositionBuilder(
///   setup: () {
///     final count = ref(0);
///
///     return (context) => Column(
///       children: [
///         Text('Count: ${count.value}'),
///         ElevatedButton(
///           onPressed: () => count.value++,
///           child: Text('Increment'),
///         ),
///       ],
///     );
///   },
/// )
/// ```
///
/// ## With Lifecycle Callbacks
///
/// ```dart
/// CompositionBuilder(
///   setup: () {
///     final count = ref(0);
///
///     onMounted(() {
///       print('Builder mounted!');
///     });
///
///     onUnmounted(() {
///       print('Builder unmounted!');
///     });
///
///     return (context) => Text('Count: ${count.value}');
///   },
/// )
/// ```
///
/// ## With Watch and Computed
///
/// ```dart
/// CompositionBuilder(
///   setup: () {
///     final firstName = ref('John');
///     final lastName = ref('Doe');
///     final fullName = computed(() => '${firstName.value} ${lastName.value}');
///
///     watch(() => fullName.value, (newName, oldName) {
///       print('Name changed: $oldName -> $newName');
///     });
///
///     return (context) => Text('Hello, ${fullName.value}!');
///   },
/// )
/// ```
///
/// ## With Provide/Inject
///
/// ```dart
/// // Parent provides a value
/// CompositionBuilder(
///   setup: () {
///     final theme = ref('dark');
///     provide(themeKey, theme);
///
///     return (context) => ChildWidget();
///   },
/// )
///
/// // Child injects the value
/// CompositionBuilder(
///   setup: () {
///     final theme = inject(themeKey);
///
///     return (context) => Text('Theme: ${theme.value}');
///   },
/// )
/// ```
///
/// ## Comparison with StatefulBuilder
///
/// **StatefulBuilder:**
/// ```dart
/// StatefulBuilder(
///   builder: (context, setState) {
///     int count = 0;  // State is lost on rebuild!
///     return ElevatedButton(
///       onPressed: () => setState(() => count++),
///       child: Text('Count: $count'),
///     );
///   },
/// )
/// ```
///
/// **CompositionBuilder:**
/// ```dart
/// CompositionBuilder(
///   setup: () {
///     final count = ref(0);  // State is preserved!
///     return (context) => ElevatedButton(
///       onPressed: () => count.value++,
///       child: Text('Count: ${count.value}'),
///     );
///   },
/// )
/// ```
///
/// The key difference is that [CompositionBuilder]'s setup runs only once,
/// preserving reactive state, while [StatefulBuilder]'s builder runs on
/// every rebuild.
class CompositionBuilder extends StatelessWidget {
  /// Creates a [CompositionBuilder].
  ///
  /// The [setup] callback is called once when the widget is first created.
  /// It should return a builder function that will be called to build the
  /// widget tree whenever reactive dependencies change.
  const CompositionBuilder({
    required this.setup,
    super.key,
  });

  /// The setup function that creates reactive state and returns a builder.
  final CompositionSetup setup;

  @override
  Widget build(BuildContext context) {
    throw StateError('CompositionBuilder.build() should never be called');
  }

  @override
  StatelessElement createElement() => _CompositionBuilderElement(this);
}

class _CompositionBuilderElement extends StatelessElement
    implements SetupContextOwner {
  _CompositionBuilderElement(CompositionBuilder super.widget);

  late final SetupContextImpl _setupContext;
  late Widget Function(BuildContext) _builder;
  bool _initialized = false;

  @override
  CompositionBuilder get widget => super.widget as CompositionBuilder;

  @override
  SetupContextImpl get setupContext => _setupContext;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);

    // Trigger onMounted callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupContext.triggerMounted();
      }
    });
  }

  void _initialize() {
    // 1. Initialize setup context
    _setupContext = SetupContextImpl()
      // CompositionBuilder does not have widget props signal
      ..parent = findParentSetupContext(this);

    // 2. Run setup (only once)
    runWithSetupContext(_setupContext, () {
      _setupContext.effectScope = signals.effectScope(() {
        _builder = widget.setup();
      });
    });

    // 3. Initialize render effect
    _setupContext.initializeRenderEffect(
      this,
      _builder,
      () {
        if (mounted && !dirty) {
          markNeedsBuild();
        }
      },
    );
    _initialized = true;
  }

  @override
  void update(CompositionBuilder newWidget) {
    super.update(newWidget);
    // CompositionBuilder setup function is final and runs once.
    // If setup function reference changes, we don't re-run setup
    // (StatefulWidget behavior).
    // We rely on hot reload (reassemble) to re-run setup if needed.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      _setupContext.triggerBuild(this);
    }
  }

  @override
  Widget build() {
    if (!_initialized) {
      _initialize();
    }
    return _setupContext.cachedWidget ?? const SizedBox.shrink();
  }

  @override
  void unmount() {
    if (_initialized) {
      _setupContext
        ..disposeRenderEffect()
        ..triggerUnmounted()
        ..dispose();
    }

    super.unmount();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (_initialized) {
      _reassembleSetupContext();
    }
  }

  void _reassembleSetupContext() {
    _setupContext
      ..previousHotReloadableValues = _captureHotReloadableValues()
      ..resetHotReload()
      ..effectScope?.dispose()
      ..clearCallbacks()
      ..clearHotReloadables()
      ..clearCache();

    runWithSetupContext(_setupContext, () {
      _setupContext.effectScope = signals.effectScope(() {
        _builder = widget.setup();
      });
    });

    _setupContext
      ..previousHotReloadableValues = null
      ..initializeRenderEffect(
        this,
        _builder,
        () {
          if (mounted && !dirty) {
            markNeedsBuild();
          }
        },
      );
  }

  Map<int, dynamic> _captureHotReloadableValues() {
    final values = <int, dynamic>{};
    for (var i = 0; i < _setupContext.hotReloadables.length; i++) {
      final entry = _setupContext.hotReloadables[i];
      values[i] = entry.raw;
    }
    return values;
  }
}

/// Gets the current builder state (for internal use by getCurrentSetupContext)
/// Returns the SetupContextImpl to match the unified API
///
/// Note: This function now simply delegates to the unified registry.
/// It's kept for backward compatibility but may be removed in the future.
/// Use getCurrentSetupContext() from framework.dart instead.
SetupContextImpl? getCurrentBuilderState() {
  return getCurrentSetupContext() as SetupContextImpl?;
}
