import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/src/custom_ref.dart';
import 'package:flutter_compositions/src/framework.dart';

/// Manages a [Listenable] and creates a reactive read-only reference.
///
/// The returned [ReadonlyRef] re-triggers dependent computations whenever
/// the `listenable` notifies listeners. The value of the ref is the listenable
/// itself, allowing it to be used directly with Flutter widgets.
///
/// Works with any [Listenable] including [ChangeNotifier], [ValueNotifier],
/// [AnimationController], [Animation], and more.
///
/// **Note**: This only handles listener management (addListener/removeListener).
/// It does NOT dispose the listenable. Use [manageChangeNotifier] if you need
/// automatic disposal.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final animation = ...; // Animation from somewhere
///   final reactiveAnimation = manageListenable(animation);
///
///   // This computed will re-run whenever animation changes
///   final animValue = computed(() {
///     reactiveAnimation.value; // Access triggers tracking
///     return animation.value;
///   });
///
///   return (context) => Text('Animation: ${animValue.value}');
/// }
/// ```
ReadonlyRef<T> manageListenable<T extends Listenable>(T listenable) {
  final custom = ReadonlyCustomRef<T>(
    getter: (track) {
      track(); // Establish dependency
      return listenable;
    },
  );

  void listener() {
    custom.trigger(); // Manually trigger when listenable notifies
  }

  listenable.addListener(listener);

  onUnmounted(() {
    listenable.removeListener(listener);
  });

  return custom;
}

/// Manages a [ChangeNotifier] with automatic lifecycle management.
///
/// Similar to [manageListenable], but also handles disposal of the
/// [ChangeNotifier] when the component unmounts.
///
/// Use this for controllers and other [ChangeNotifier] instances that
/// you create and need to dispose.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final controller = ScrollController();
///   final reactiveController = manageChangeNotifier(controller);
///
///   final scrollOffset = computed(() {
///     reactiveController.value; // Track changes
///     return controller.offset;
///   });
///
///   return (context) => ListView(
///     controller: controller,
///     children: [...],
///   );
/// }
/// ```
ReadonlyRef<T> manageChangeNotifier<T extends ChangeNotifier>(T notifier) {
  final custom = ReadonlyCustomRef<T>(
    getter: (track) {
      track();
      return notifier;
    },
  );

  void listener() {
    custom.trigger();
  }

  notifier.addListener(listener);

  onUnmounted(() {
    notifier
      ..removeListener(listener)
      ..dispose();
  });

  return custom;
}

/// Creates and manages a [ChangeNotifier] with hot-reload support and
/// automatic lifecycle management.
///
/// Combines [hotReloadableContainer] for hot-reload state preservation
/// with [manageChangeNotifier] for reactive tracking and automatic disposal.
///
/// Returns a [ReadonlyRef] that tracks changes to the notifier.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final controller = useController(() => ScrollController());
///
///   return (context) => ListView(
///     controller: controller.raw, // Use .raw to avoid unnecessary rebuilds
///     children: [...],
///   );
/// }
/// ```
ReadonlyRef<T> useController<T extends ChangeNotifier>(
  T Function() create, {
  String? debugLabel,
}) {
  return manageChangeNotifier(
    hotReloadableContainer(create, debugLabel: debugLabel),
  );
}

/// Manages a [ValueListenable] and creates a reactive reference to its value.
///
/// This helper extracts and tracks the value from any [ValueListenable]
/// implementation including [ValueNotifier], [Animation], and others.
///
/// Returns a tuple of `(listenable, value)` where:
/// - listenable: The original [ValueListenable] for direct access
/// - value: [ReadonlyRef<T>] that tracks the current value reactively
///
/// **Note**: This uses [manageListenable] internally, so it only handles
/// listener management and does NOT dispose the listenable.
///
/// Example with Animation (no disposal needed):
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final controller = useAnimationController(duration: Duration(seconds: 1));
///   final (animation, animValue) = manageValueListenable(controller.value);
///
///   return (context) => Opacity(
///     opacity: animValue.value,
///     child: Text('Fading'),
///   );
/// }
/// ```
(L, ReadonlyRef<T>) manageValueListenable<L extends ValueListenable<T>, T>(
  L listenable,
) {
  // Use manageListenable to track changes (no dispose)
  final reactiveListenable = manageListenable(listenable);

  // Return a computed that extracts the value
  final value = computed(() => reactiveListenable.value.value);

  return (listenable, value);
}
