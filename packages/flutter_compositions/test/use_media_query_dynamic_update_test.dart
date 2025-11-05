import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('useMediaQuery dynamic updates', () {
    testWidgets('updates when MediaQuery changes', (tester) async {
      // Track how many times computed is evaluated
      var computedEvaluationCount = 0;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
          ),
          child: MaterialApp(
            home: TestWidget(
              onComputedEvaluation: () => computedEvaluationCount++,
            ),
          ),
        ),
      );

      // Initial evaluation
      expect(computedEvaluationCount, 1);
      expect(find.text('Width: 400.0'), findsOneWidget);

      // Change MediaQuery size
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(600, 800),
          ),
          child: MaterialApp(
            home: TestWidget(
              onComputedEvaluation: () => computedEvaluationCount++,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should re-evaluate because MediaQuery changed
      expect(computedEvaluationCount, 2);
      expect(find.text('Width: 600.0'), findsOneWidget);
    });

    testWidgets('useMediaQueryInfo separate refs update independently',
        (tester) async {
      var sizeEvaluationCount = 0;
      var orientationEvaluationCount = 0;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800), // Portrait
          ),
          child: MaterialApp(
            home: MediaQueryInfoTestWidget(
              onSizeEvaluation: () => sizeEvaluationCount++,
              onOrientationEvaluation: () => orientationEvaluationCount++,
            ),
          ),
        ),
      );

      expect(sizeEvaluationCount, 1);
      expect(orientationEvaluationCount, 1);

      // Change only width (orientation stays portrait)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(500, 800), // Still portrait
          ),
          child: MaterialApp(
            home: MediaQueryInfoTestWidget(
              onSizeEvaluation: () => sizeEvaluationCount++,
              onOrientationEvaluation: () => orientationEvaluationCount++,
            ),
          ),
        ),
      );

      await tester.pump();

      // Size should update, but orientation should not
      expect(sizeEvaluationCount, 2);
      expect(orientationEvaluationCount, 1); // Should still be 1

      // Change to landscape
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 500), // Landscape
          ),
          child: MaterialApp(
            home: MediaQueryInfoTestWidget(
              onSizeEvaluation: () => sizeEvaluationCount++,
              onOrientationEvaluation: () => orientationEvaluationCount++,
            ),
          ),
        ),
      );

      await tester.pump();

      // Both should update now
      expect(sizeEvaluationCount, 3);
      expect(orientationEvaluationCount, 2);
    });

    testWidgets('useTheme updates when theme changes', (tester) async {
      var evaluationCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: Colors.blue),
          home: ThemeTestWidget(
            onEvaluation: () => evaluationCount++,
          ),
        ),
      );

      expect(evaluationCount, 1);
      expect(find.textContaining('Primary: Blue'), findsOneWidget);

      // Change theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: Colors.red),
          home: ThemeTestWidget(
            onEvaluation: () => evaluationCount++,
          ),
        ),
      );

      await tester.pump();

      // Should re-evaluate
      expect(evaluationCount, 2);
      expect(find.textContaining('Primary: Red'), findsOneWidget);
    });
  });
}

class TestWidget extends CompositionWidget {
  const TestWidget({
    required this.onComputedEvaluation,
    super.key,
  });

  final VoidCallback onComputedEvaluation;

  @override
  Widget Function(BuildContext) setup() {
    final mediaQuery = useMediaQuery();

    final widthText = computed(() {
      onComputedEvaluation();
      return 'Width: ${mediaQuery.value.size.width}';
    });

    return (context) => Scaffold(
          body: Text(widthText.value),
        );
  }
}

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

    return (context) => Scaffold(
          body: Column(
            children: [
              Text(sizeText.value),
              Text(orientationText.value),
            ],
          ),
        );
  }
}

class ThemeTestWidget extends CompositionWidget {
  const ThemeTestWidget({
    required this.onEvaluation,
    super.key,
  });

  final VoidCallback onEvaluation;

  @override
  Widget Function(BuildContext) setup() {
    final theme = useTheme();

    final colorName = computed(() {
      onEvaluation();
      final color = theme.value.primaryColor;
      if (color == Colors.blue) return 'Blue';
      if (color == Colors.red) return 'Red';
      return 'Other';
    });

    return (context) => Scaffold(
          body: Text('Primary: ${colorName.value}'),
        );
  }
}
