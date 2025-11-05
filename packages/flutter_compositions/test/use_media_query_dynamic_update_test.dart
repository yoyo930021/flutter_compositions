import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('useMediaQuery dynamic updates', () {
    testWidgets('updates when MediaQuery changes', (tester) async {
      // Use a key to ensure the same Widget instance is reused
      const testKey = Key('test-widget');

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
          ),
          child: const MaterialApp(
            home: TestWidget(key: testKey),
          ),
        ),
      );

      // Initial render
      expect(find.text('Width: 400.0'), findsOneWidget);

      // Change MediaQuery size - Widget instance should be reused
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(600, 800),
          ),
          child: const MaterialApp(
            home: TestWidget(key: testKey),
          ),
        ),
      );

      // Trigger frames to process updates
      await tester.pumpAndSettle();

      // Should show new width because MediaQuery changed
      expect(find.text('Width: 600.0'), findsOneWidget);
      expect(find.text('Width: 400.0'), findsNothing);
    });

    testWidgets('useMediaQueryInfo separate refs update independently',
        (tester) async {
      const testKey = Key('test-widget');

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800), // Portrait
          ),
          child: const MaterialApp(
            home: MediaQueryInfoTestWidget(key: testKey),
          ),
        ),
      );

      expect(find.text('Size: 400.0x800.0'), findsOneWidget);
      expect(find.text('Orientation: Orientation.portrait'), findsOneWidget);

      // Change only width (orientation stays portrait)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(500, 800), // Still portrait
          ),
          child: const MaterialApp(
            home: MediaQueryInfoTestWidget(key: testKey),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Size should update
      expect(find.text('Size: 500.0x800.0'), findsOneWidget);
      // Orientation should still be portrait
      expect(find.text('Orientation: Orientation.portrait'), findsOneWidget);

      // Change to landscape
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 500), // Landscape
          ),
          child: const MaterialApp(
            home: MediaQueryInfoTestWidget(key: testKey),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Both should update now
      expect(find.text('Size: 800.0x500.0'), findsOneWidget);
      expect(find.text('Orientation: Orientation.landscape'), findsOneWidget);
    });

    testWidgets('useTheme updates when theme changes', (tester) async {
      const testKey = Key('test-widget');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: Colors.blue),
          home: const ThemeTestWidget(key: testKey),
        ),
      );

      expect(find.textContaining('Primary: Blue'), findsOneWidget);

      // Change theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: Colors.red),
          home: const ThemeTestWidget(key: testKey),
        ),
      );

      await tester.pumpAndSettle();

      // Should show new theme color
      expect(find.textContaining('Primary: Red'), findsOneWidget);
      expect(find.textContaining('Primary: Blue'), findsNothing);
    });
  });
}

class TestWidget extends CompositionWidget {
  const TestWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final mediaQuery = useMediaQuery();

    final widthText = computed(() {
      return 'Width: ${mediaQuery.value.size.width}';
    });

    return (context) => Scaffold(
          body: Center(
            child: Text(widthText.value),
          ),
        );
  }
}

class MediaQueryInfoTestWidget extends CompositionWidget {
  const MediaQueryInfoTestWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (size, orientation) = useMediaQueryInfo();

    final sizeText = computed(() {
      return 'Size: ${size.value.width}x${size.value.height}';
    });

    final orientationText = computed(() {
      return 'Orientation: ${orientation.value}';
    });

    return (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(sizeText.value),
                Text(orientationText.value),
              ],
            ),
          ),
        );
  }
}

class ThemeTestWidget extends CompositionWidget {
  const ThemeTestWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final theme = useTheme();

    final colorName = computed(() {
      final color = theme.value.primaryColor;
      if (color == Colors.blue) return 'Blue';
      if (color == Colors.red) return 'Red';
      return 'Other';
    });

    return (context) => Scaffold(
          body: Center(
            child: Text('Primary: ${colorName.value}'),
          ),
        );
  }
}
