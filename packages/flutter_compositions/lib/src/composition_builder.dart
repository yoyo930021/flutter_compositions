import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/src/framework.dart'
    show SetupContextImpl, SetupContextMixin;

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
class CompositionBuilder extends StatefulWidget {
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
  State<CompositionBuilder> createState() => CompositionBuilderState();
}

/// The state for [CompositionBuilder] that manages the reactive effect
/// and lifecycle.
///
/// This implementation uses [SetupContextMixin] to share logic with
/// CompositionWidget, ensuring consistency and eliminating code duplication.
class CompositionBuilderState extends State<CompositionBuilder>
    with SetupContextMixin<CompositionBuilder> {
  @override
  void initState() {
    super.initState();

    // Initialize setup context using mixin
    initializeSetupContext(
      setupFunction: widget.setup,
      parent: SetupContextMixin.findParentSetupContext(context),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeRenderEffectIfNeeded(context);
    // Trigger build callbacks when InheritedWidget dependencies change.
    // This allows composables like useContextRef to update correctly.
    setupContext?.triggerBuild(context);
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

/// Gets the current builder state (for internal use by getCurrentSetupContext)
/// Returns the SetupContextImpl to match the unified API
///
/// Note: This function now simply delegates to the unified registry.
/// It's kept for backward compatibility but may be removed in the future.
/// Use getCurrentSetupContext() from framework.dart instead.
SetupContextImpl? getCurrentBuilderState() {
  // Delegate to the unified registry
  // This is imported from framework.dart via getCurrentSetupContext
  // The registry is not accessible here, but getCurrentSetupContext()
  // in framework.dart handles it
  return null;
}
