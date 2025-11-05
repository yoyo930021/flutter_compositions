import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('useMediaQuery reactivity optimization', () {
    testWidgets('only triggers updates when MediaQuery actually changes',
        (tester) async {
      // Track the number of times the builder function is called
      var buildCount = 0;
      var computedEvaluationCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(
                  size: Size(400, 800),
                  devicePixelRatio: 2.0,
                ),
                child: TestWidget(
                  onBuild: () => buildCount++,
                  onComputedEvaluation: () => computedEvaluationCount++,
                ),
              );
            },
          ),
        ),
      );

      // Initial build
      await tester.pump();
      expect(buildCount, 1);
      expect(computedEvaluationCount, 1);

      // Rebuild with same MediaQuery - should NOT trigger update
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(
                  size: Size(400, 800),
                  devicePixelRatio: 2.0,
                ),
                child: TestWidget(
                  onBuild: () => buildCount++,
                  onComputedEvaluation: () => computedEvaluationCount++,
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      // Build is called because onBuild is triggered on every build,
      // but computed should not re-evaluate if MediaQuery is identical
      expect(buildCount, 2);
      // The computed value should not be re-evaluated since MediaQuery didn't change
      expect(computedEvaluationCount, 1);

      // Rebuild with different MediaQuery - SHOULD trigger update
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(
                  size: Size(600, 1000), // Changed size
                  devicePixelRatio: 2.0,
                ),
                child: TestWidget(
                  onBuild: () => buildCount++,
                  onComputedEvaluation: () => computedEvaluationCount++,
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      expect(buildCount, 3);
      // Now computed should re-evaluate because MediaQuery changed
      expect(computedEvaluationCount, 2);
    });

    testWidgets('useContextRef with custom equals function', (tester) async {
      var evaluationCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(
                  size: Size(400, 800),
                ),
                child: CustomEqualsTestWidget(
                  onEvaluation: () => evaluationCount++,
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      expect(evaluationCount, 1);

      // Change size but width stays same - should NOT trigger update
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(
                  size: Size(400, 900), // Different height, same width
                ),
                child: CustomEqualsTestWidget(
                  onEvaluation: () => evaluationCount++,
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      // Should not re-evaluate because width is the same (custom equals)
      expect(evaluationCount, 1);

      // Change width - SHOULD trigger update
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(
                  size: Size(500, 900), // Different width
                ),
                child: CustomEqualsTestWidget(
                  onEvaluation: () => evaluationCount++,
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      // Should re-evaluate because width changed
      expect(evaluationCount, 2);
    });

    testWidgets('useMediaQueryInfo separate refs only update when needed',
        (tester) async {
      var sizeEvaluationCount = 0;
      var orientationEvaluationCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(
                  size: Size(400, 800),
                ),
                child: MediaQueryInfoTestWidget(
                  onSizeEvaluation: () => sizeEvaluationCount++,
                  onOrientationEvaluation: () => orientationEvaluationCount++,
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      expect(sizeEvaluationCount, 1);
      expect(orientationEvaluationCount, 1);

      // Change only size - orientation should not re-evaluate
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(
                  size: Size(500, 800), // Different size, same orientation
                ),
                child: MediaQueryInfoTestWidget(
                  onSizeEvaluation: () => sizeEvaluationCount++,
                  onOrientationEvaluation: () => orientationEvaluationCount++,
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      // Size computed should re-evaluate
      expect(sizeEvaluationCount, 2);
      // Orientation should NOT re-evaluate (still portrait)
      expect(orientationEvaluationCount, 1);

      // Change orientation - both should re-evaluate
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(
                  size: Size(800, 500), // Landscape
                ),
                child: MediaQueryInfoTestWidget(
                  onSizeEvaluation: () => sizeEvaluationCount++,
                  onOrientationEvaluation: () => orientationEvaluationCount++,
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      // Both should re-evaluate now
      expect(sizeEvaluationCount, 3);
      expect(orientationEvaluationCount, 2);
    });
  });
}

// Test widget that tracks builder execution
class TestWidget extends CompositionWidget {
  const TestWidget({
    required this.onBuild,
    required this.onComputedEvaluation,
    super.key,
  });

  final VoidCallback onBuild;
  final VoidCallback onComputedEvaluation;

  @override
  Widget Function(BuildContext) setup() {
    final mediaQuery = useMediaQuery();

    final screenInfo = computed(() {
      onComputedEvaluation();
      return '${mediaQuery.value.size.width}x${mediaQuery.value.size.height}';
    });

    onBuild(() {
      onBuild();
    });

    return (context) => Text(screenInfo.value);
  }
}

// Test widget with custom equals function
class CustomEqualsTestWidget extends CompositionWidget {
  const CustomEqualsTestWidget({
    required this.onEvaluation,
    super.key,
  });

  final VoidCallback onEvaluation;

  @override
  Widget Function(BuildContext) setup() {
    // Track only width changes using custom equals
    final width = useContextRef<double>(
      (context) => MediaQuery.of(context).size.width,
      equals: (a, b) => a == b, // Use value equality instead of identical
    );

    final widthText = computed(() {
      onEvaluation();
      return 'Width: ${width.value}';
    });

    return (context) => Text(widthText.value);
  }
}

// Test widget for useMediaQueryInfo
class MediaQueryInfoTestWidget extends CompositionWidget {
  const MediaQueryInfoTestWidget({
    required this.onSizeEvaluation,
    required this.onOrientationEvaluation,
    super.key,
  });

  final VoidCallback onSizeEvaluation;
  final VoidCallback onOrientationEvaluation;

  @override
  Widget Function(BuildContext) setup() {
    final (size, orientation) = useMediaQueryInfo();

    final sizeText = computed(() {
      onSizeEvaluation();
      return 'Size: ${size.value.width}x${size.value.height}';
    });

    final orientationText = computed(() {
      onOrientationEvaluation();
      return 'Orientation: ${orientation.value}';
    });

    return (context) => Column(
          children: [
            Text(sizeText.value),
            Text(orientationText.value),
          ],
        );
  }
}
