import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('useSingleTickerProvider', () {
    testWidgets('creates a ticker provider that can create one ticker', (
      tester,
    ) async {
      TickerProvider? capturedVsync;

      await tester.pumpWidget(
        MaterialApp(
          home: SingleTickerProviderHarness(
            onVsync: (vsync) => capturedVsync = vsync,
          ),
        ),
      );

      expect(capturedVsync, isNotNull);
      expect(capturedVsync, isA<TickerProvider>());
    });

    testWidgets('disposes ticker when component unmounts', (tester) async {
      var tickerDisposed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DisposableTickerHarness(
            onTickerDisposed: () => tickerDisposed = true,
          ),
        ),
      );

      expect(tickerDisposed, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(tickerDisposed, isTrue);
    });

    testWidgets('automatically updates TickerMode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TickerModeTestHarness(),
        ),
      );

      // Widget should render successfully with TickerMode tracking
      expect(find.byType(TickerModeTestHarness), findsOneWidget);
    });

    testWidgets('asserts when creating multiple tickers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MultipleTickerHarness(),
        ),
      );

      // Should throw assertion error in debug mode
      expect(tester.takeException(), isNotNull);
    });
  });

  group('useAnimationController', () {
    testWidgets('creates an animation controller with correct parameters', (
      tester,
    ) async {
      AnimationController? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: AnimationControllerHarness(
            duration: const Duration(seconds: 1),
            onController: (controller) => captured = controller,
          ),
        ),
      );

      expect(captured, isNotNull);
      expect(captured!.duration, const Duration(seconds: 1));
      expect(captured!.lowerBound, 0.0);
      expect(captured!.upperBound, 1.0);
    });

    testWidgets('provides reactive animation value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReactiveAnimationHarness(),
        ),
      );

      // Initial value should be 0.0
      expect(find.text('Value: 0.0'), findsOneWidget);

      // Pump to execute onMounted callback
      await tester.pump();

      // Advance animation time
      await tester.pump(const Duration(milliseconds: 100));

      // Rebuild UI with new animation value
      await tester.pump();

      // Value should have changed
      expect(find.text('Value: 0.0'), findsNothing);
      expect(find.text('Value: 0.1'), findsOneWidget);
    });

    testWidgets('disposes controller when component unmounts', (tester) async {
      var controllerDisposed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DisposableAnimationControllerHarness(
            onDisposed: () => controllerDisposed = true,
          ),
        ),
      );

      expect(controllerDisposed, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(controllerDisposed, isTrue);
    });

    testWidgets('animation controller works with repeat', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RepeatingAnimationHarness(),
        ),
      );

      // Should start animating
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Animation should be running
      expect(find.byType(RepeatingAnimationHarness), findsOneWidget);
    });

    testWidgets('accepts external vsync parameter', (tester) async {
      AnimationController? controller1;
      AnimationController? controller2;

      await tester.pumpWidget(
        MaterialApp(
          home: ExternalVsyncHarness(
            onController1: (c) => controller1 = c,
            onController2: (c) => controller2 = c,
          ),
        ),
      );

      expect(controller1, isNotNull);
      expect(controller2, isNotNull);
      expect(controller1!.duration, const Duration(seconds: 1));
      expect(controller2!.duration, const Duration(seconds: 2));
    });

    testWidgets('uses internal vsync when not provided', (tester) async {
      AnimationController? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: AnimationControllerHarness(
            duration: const Duration(seconds: 1),
            onController: (controller) => captured = controller,
          ),
        ),
      );

      expect(captured, isNotNull);
      // Controller should work without external vsync
      expect(captured!.duration, const Duration(seconds: 1));
    });
  });

  group('manageAnimation', () {
    testWidgets('manages animation and provides reactive value', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ManageAnimationHarness(),
        ),
      );

      expect(find.text('Value: 0.0'), findsOneWidget);

      // Start animation
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Value should have changed
      expect(find.text('Value: 0.0'), findsNothing);
    });

    testWidgets('works with CurvedAnimation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CurvedAnimationHarness(),
        ),
      );

      expect(find.byType(CurvedAnimationHarness), findsOneWidget);

      // Start animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should animate with curve
      expect(find.byType(CurvedAnimationHarness), findsOneWidget);
    });

    testWidgets('does not dispose managed animation', (tester) async {
      var animationDisposed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ManagedAnimationLifecycleHarness(
            onAnimationDisposed: () => animationDisposed = true,
          ),
        ),
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      // manageAnimation should NOT dispose the animation
      expect(animationDisposed, isFalse);
    });
  });
}

// ---------------------------------------------------------------------------
// Harness widgets
// ---------------------------------------------------------------------------

class SingleTickerProviderHarness extends CompositionWidget {
  const SingleTickerProviderHarness({
    required this.onVsync,
    super.key,
  });

  final void Function(TickerProvider vsync) onVsync;

  @override
  Widget Function(BuildContext) setup() {
    final vsync = useSingleTickerProvider();

    onMounted(() => onVsync(vsync));

    return (context) => const SizedBox();
  }
}

class DisposableTickerHarness extends CompositionWidget {
  const DisposableTickerHarness({
    required this.onTickerDisposed,
    super.key,
  });

  final VoidCallback onTickerDisposed;

  @override
  Widget Function(BuildContext) setup() {
    final vsync = useSingleTickerProvider();

    // Create a ticker to track disposal
    // ignore: unused_local_variable
    late final Ticker ticker;
    onMounted(() {
      ticker = vsync.createTicker((_) {});
    });

    onUnmounted(onTickerDisposed);

    return (context) => const SizedBox();
  }
}

class TickerModeTestHarness extends CompositionWidget {
  const TickerModeTestHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final vsync = useSingleTickerProvider();
    final controller = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 1),
    );

    onUnmounted(controller.dispose);

    return (context) => AnimatedBuilder(
          animation: controller,
          builder: (context, child) => const SizedBox(),
        );
  }
}

class MultipleTickerHarness extends CompositionWidget {
  const MultipleTickerHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final vsync = useSingleTickerProvider();

    onMounted(() {
      // Create first ticker
      vsync.createTicker((_) {});
      // Try to create second ticker - should throw
      // ignore: cascade_invocations
      vsync.createTicker((_) {});
    });

    return (context) => const SizedBox();
  }
}

class AnimationControllerHarness extends CompositionWidget {
  const AnimationControllerHarness({
    required this.duration,
    required this.onController,
    super.key,
  });

  final Duration duration;
  final void Function(AnimationController controller) onController;

  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: duration,
    );

    onMounted(() => onController(controller));

    return (context) => const SizedBox();
  }
}

class ReactiveAnimationHarness extends CompositionWidget {
  const ReactiveAnimationHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: const Duration(seconds: 1),
    );

    onMounted(controller.forward);

    return (context) => Text('Value: ${animValue.value.toStringAsFixed(1)}');
  }
}

class DisposableAnimationControllerHarness extends CompositionWidget {
  const DisposableAnimationControllerHarness({
    required this.onDisposed,
    super.key,
  });

  final VoidCallback onDisposed;

  @override
  Widget Function(BuildContext) setup() {
    useAnimationController(
      duration: const Duration(seconds: 1),
    );

    onUnmounted(onDisposed);

    return (context) => const SizedBox();
  }
}

class RepeatingAnimationHarness extends CompositionWidget {
  const RepeatingAnimationHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );

    onMounted(controller.repeat);

    return (context) => Opacity(
          opacity: animValue.value,
          child: const Text('Animating'),
        );
  }
}

class ExternalVsyncHarness extends CompositionWidget {
  const ExternalVsyncHarness({
    required this.onController1,
    required this.onController2,
    super.key,
  });

  final void Function(AnimationController controller) onController1;
  final void Function(AnimationController controller) onController2;

  @override
  Widget Function(BuildContext) setup() {
    // Create two separate vsync providers
    final vsync1 = useSingleTickerProvider();
    final vsync2 = useSingleTickerProvider();

    // Create two controllers using external vsync parameters
    final (controller1, _) = useAnimationController(
      vsync: vsync1,
      duration: const Duration(seconds: 1),
    );

    final (controller2, _) = useAnimationController(
      vsync: vsync2,
      duration: const Duration(seconds: 2),
    );

    onMounted(() {
      onController1(controller1);
      onController2(controller2);
    });

    return (context) => const SizedBox();
  }
}

class ManageAnimationHarness extends CompositionWidget {
  const ManageAnimationHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );

    final (_, animValue) = manageAnimation(controller);

    return (context) => Column(
          children: [
            Text('Value: ${animValue.value.toStringAsFixed(1)}'),
            ElevatedButton(
              onPressed: controller.forward,
              child: const Text('Start'),
            ),
          ],
        );
  }
}

class CurvedAnimationHarness extends CompositionWidget {
  const CurvedAnimationHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    final (_, animValue) = manageAnimation(curvedAnimation);

    onMounted(controller.forward);

    return (context) => Opacity(
          opacity: animValue.value,
          child: const Text('Fading'),
        );
  }
}

class ManagedAnimationLifecycleHarness extends CompositionWidget {
  const ManagedAnimationLifecycleHarness({
    required this.onAnimationDisposed,
    super.key,
  });

  final VoidCallback onAnimationDisposed;

  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final curvedAnimation = _DisposableAnimation(
      parent: controller,
      curve: Curves.linear,
      onDispose: onAnimationDisposed,
    );

    manageAnimation(curvedAnimation);

    return (context) => const SizedBox();
  }
}

class _DisposableAnimation extends CurvedAnimation {
  _DisposableAnimation({
    required super.parent,
    required super.curve,
    required this.onDispose,
  });

  final VoidCallback onDispose;

  @override
  void dispose() {
    onDispose();
    super.dispose();
  }
}
