import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/src/composables/listenable_composables.dart';
import 'package:flutter_compositions/src/framework.dart';

/// Creates a SingleTickerProviderStateMixin for use with AnimationController.
///
/// This must be used in combination with [useAnimationController] when you
/// need a vsync provider. The returned ticker provider is automatically
/// disposed when the component unmounts.
///
/// The ticker provider automatically:
/// - Tracks [TickerMode] changes and mutes/unmutes the ticker accordingly
/// - Provides debug labels in debug mode
/// - Ensures only one ticker is created (asserts in debug mode)
/// - Disposes the ticker when the component unmounts
///
/// **Note**: This is a low-level API. Most of the time you should use
/// [useAnimationController] directly which handles the ticker provider
/// internally.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final vsync = useSingleTickerProvider();
///   final controller = AnimationController(
///     vsync: vsync,
///     duration: const Duration(seconds: 1),
///   );
///
///   onUnmounted(() => controller.dispose());
///
///   return (context) => AnimatedBuilder(
///     animation: controller,
///     builder: (context, child) => Transform.rotate(
///       angle: controller.value * 2 * 3.14159,
///       child: child,
///     ),
///     child: const Icon(Icons.refresh),
///   );
/// }
/// ```
SingleTickerProvider useSingleTickerProvider() {
  final ticker = SingleTickerProvider();

  // Automatically update ticker mode on every build
  onBuild(ticker.updateTickerMode);

  onUnmounted(ticker.dispose);

  return ticker;
}

/// Implementation of TickerProvider with automatic TickerMode support.
///
/// This class is created by [useSingleTickerProvider] and automatically
/// tracks [TickerMode] changes. Users should use [useSingleTickerProvider]
/// instead of instantiating this class directly.
///
/// The class provides a [updateTickerMode] method that can be called
/// manually if needed, but this is typically handled automatically by the
/// [useSingleTickerProvider] composable via [onBuild] callback.
class SingleTickerProvider implements TickerProvider {
  Ticker? _ticker;
  ValueListenable<bool>? _tickerModeNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(
      _ticker == null,
      'SingleTickerProvider is a single ticker provider but multiple '
      'tickers were created.\n'
      'A single ticker provider can only be used as a TickerProvider once. '
      'If you need multiple tickers, create multiple providers.',
    );

    _ticker = Ticker(
      onTick,
      debugLabel: kDebugMode ? 'created by useSingleTickerProvider' : null,
    );

    // Set initial mute state if TickerMode is already set up
    if (_tickerModeNotifier != null) {
      _ticker!.muted = !_tickerModeNotifier!.value;
    }

    return _ticker!;
  }

  void _updateTicker() {
    if (_ticker != null && _tickerModeNotifier != null) {
      _ticker!.muted = !_tickerModeNotifier!.value;
    }
  }

  /// Updates the ticker mode based on the current BuildContext.
  ///
  /// This should be called in the builder function on every build to ensure
  /// the ticker respects [TickerMode] changes. This is similar to how
  /// [SingleTickerProviderStateMixin] works in Flutter.
  ///
  /// This method is safe to call during disposal - it will silently ignore
  /// errors if the BuildContext is no longer active.
  void updateTickerMode(BuildContext context) {
    try {
      final newNotifier = TickerMode.getNotifier(context);
      if (newNotifier == _tickerModeNotifier) {
        return;
      }

      _tickerModeNotifier?.removeListener(_updateTicker);
      newNotifier.addListener(_updateTicker);
      _tickerModeNotifier = newNotifier;

      // Update mute state immediately
      _updateTicker();
    } on Object {
      // Ignore errors during disposal (BuildContext might be deactivated)
      // This can happen when AnimationController ticks during widget disposal
    }
  }

  /// Disposes the ticker provider and its ticker.
  ///
  /// This will dispose the ticker even if it's still active. While normally
  /// you should dispose the AnimationController before the ticker provider,
  /// the cleanup happens automatically during widget disposal so the order
  /// may vary depending on when composables are called in setup().
  void dispose() {
    _tickerModeNotifier?.removeListener(_updateTicker);
    _tickerModeNotifier = null;
    _ticker?.dispose();
    _ticker = null;
  }
}

/// Creates an AnimationController with automatic lifecycle management and
/// reactive tracking.
///
/// The controller is automatically disposed when the component unmounts.
///
/// Returns a tuple of `(controller, animValue)` where:
/// - controller: The [AnimationController] for controlling the animation
/// - animValue: [ReadonlyRef<double>] that tracks the animation value
///   (0.0 to 1.0)
///
/// Parameters:
/// - `vsync`: Optional [TickerProvider]. If not provided, creates an internal
///   [SingleTickerProvider] automatically
/// - All other parameters match Flutter's AnimationController constructor
///
/// Example - Basic animation using controller:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final (controller, animValue) = useAnimationController(
///     duration: const Duration(seconds: 2),
///   );
///
///   // React to animation value changes
///   final rotation = computed(() => animValue.value * 2 * 3.14159);
///
///   onMounted(() {
///     controller.repeat();
///   });
///
///   return (context) => Transform.rotate(
///     angle: rotation.value,
///     child: const Icon(Icons.refresh, size: 48),
///   );
/// }
/// ```
///
/// Example - With external vsync:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final vsync = useSingleTickerProvider();
///
///   final (controller1, _) = useAnimationController(
///     vsync: vsync,
///     duration: const Duration(seconds: 1),
///   );
///
///   final (controller2, _) = useAnimationController(
///     vsync: vsync,
///     duration: const Duration(seconds: 2),
///   );
///
///   return (context) => YourWidget();
/// }
/// ```
///
/// Example - With animation curves:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final (controller, _) = useAnimationController(
///     duration: const Duration(milliseconds: 300),
///   );
///
///   final (animation, animValue) = manageAnimation(
///     CurvedAnimation(
///       parent: controller,
///       curve: Curves.easeInOut,
///     ),
///   );
///
///   return (context) => Opacity(
///     opacity: animValue.value,
///     child: const Text('Fade in'),
///   );
/// }
/// ```
(AnimationController, ReadonlyRef<double>) useAnimationController({
  TickerProvider? vsync,
  double? value,
  Duration? duration,
  Duration? reverseDuration,
  String? debugLabel,
  double lowerBound = 0.0,
  double upperBound = 1.0,
  AnimationBehavior animationBehavior = AnimationBehavior.normal,
}) {
  final tickerProvider = vsync ?? useSingleTickerProvider();

  final controller = AnimationController(
    value: value,
    duration: duration,
    reverseDuration: reverseDuration,
    debugLabel: debugLabel,
    lowerBound: lowerBound,
    upperBound: upperBound,
    vsync: tickerProvider,
    animationBehavior: animationBehavior,
  );

  // AnimationController is an Animation<double>, so we use manageAnimation
  // for listener management, and manually handle disposal
  final (managedController, animValue) = manageAnimation<AnimationController, double>(controller);

  onUnmounted(() {
    // Stop the controller before disposing to prevent "active ticker" assertion
    controller
      ..stop(canceled: false)
      ..dispose();
  });

  return (managedController, animValue);
}

/// Manages an [Animation] and creates a reactive reference to its value.
///
/// Uses [manageValueListenable] internally since [Animation] implements
/// [ValueListenable]. The animation listener is automatically removed when
/// the component unmounts.
///
/// **Note**: This does NOT dispose the animation. Use this for derived
/// animations like [CurvedAnimation], [Tween.animate], etc. that you don't
/// own or that are managed elsewhere. Since [Animation] is abstract and
/// has many implementations, this function works with all animation types.
///
/// Type parameters:
/// - `A`: The animation type (e.g., `Animation<double>`, `CurvedAnimation`)
/// - `T`: The value type of the animation (e.g., `double`, `Offset`, `Color`)
///
/// Returns a tuple of `(animation, value)` where:
/// - animation: The original animation of type `A` for direct access
/// - value: [ReadonlyRef<T>] that tracks the current animation value
///
/// Example - With Tween (inferred types):
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final controller = useAnimationController(
///     duration: const Duration(seconds: 1),
///   );
///
///   final (offsetAnimation, offsetValue) = manageAnimation(
///     Tween<Offset>(
///       begin: const Offset(0, -1),
///       end: Offset.zero,
///     ).animate(controller.value),
///   );
///
///   onMounted(() {
///     controller.value.forward();
///   });
///
///   return (context) => SlideTransition(
///     position: offsetAnimation,
///     child: const Text('Slide in'),
///   );
/// }
/// ```
///
/// Example - With CurvedAnimation (preserving exact type):
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final controller = useAnimationController(
///     duration: const Duration(milliseconds: 500),
///   );
///
///   final (curvedAnimation, animValue) = manageAnimation(
///     CurvedAnimation(
///       parent: controller.value,
///       curve: Curves.elasticOut,
///     ),
///   );
///
///   // curvedAnimation is of type CurvedAnimation
///   final scale = computed(() => animValue.value);
///
///   return (context) => Transform.scale(
///     scale: scale.value,
///     child: const Icon(Icons.favorite, size: 64),
///   );
/// }
/// ```
(A, ReadonlyRef<T>) manageAnimation<A extends Animation<T>, T>(A animation) {
  // Animation implements ValueListenable<T>,
  // so we can use manageValueListenable
  return manageValueListenable(animation);
}
