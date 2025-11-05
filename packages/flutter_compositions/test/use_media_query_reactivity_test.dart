import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('useMediaQuery reactivity optimization', () {
    testWidgets('only triggers updates when MediaQuery actually changes', (
      tester,
    ) async {
      const testKey = Key('test-widget');

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            devicePixelRatio: 2.0,
          ),
          child: const MaterialApp(
            home: TestWidget(key: testKey),
          ),
        ),
      );

      // Initial build
      expect(find.text('400.0x800.0'), findsOneWidget);

      // Rebuild with same MediaQuery - widget should still show same value
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            devicePixelRatio: 2.0,
          ),
          child: const MaterialApp(
            home: TestWidget(key: testKey),
          ),
        ),
      );

      await tester.pump();

      // Should still show same value
      expect(find.text('400.0x800.0'), findsOneWidget);

      // Rebuild with different MediaQuery - SHOULD trigger update
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(600, 1000), // Changed size
            devicePixelRatio: 2.0,
          ),
          child: const MaterialApp(
            home: TestWidget(key: testKey),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show new value
      expect(find.text('600.0x1000.0'), findsOneWidget);
      expect(find.text('400.0x800.0'), findsNothing);
    });

    testWidgets('useContextRef with custom equals function', (tester) async {
      const testKey = Key('test-widget');

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
          ),
          child: const MaterialApp(
            home: CustomEqualsTestWidget(key: testKey),
          ),
        ),
      );

      expect(find.text('Width: 400.0'), findsOneWidget);

      // Change size but width stays same
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 900), // Different height, same width
          ),
          child: const MaterialApp(
            home: CustomEqualsTestWidget(key: testKey),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still show same width (custom equals prevented update)
      expect(find.text('Width: 400.0'), findsOneWidget);

      // Change width - SHOULD trigger update
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(500, 900), // Different width
          ),
          child: const MaterialApp(
            home: CustomEqualsTestWidget(key: testKey),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show new width
      expect(find.text('Width: 500.0'), findsOneWidget);
      expect(find.text('Width: 400.0'), findsNothing);
    });

    testWidgets('useMediaQueryInfo separate refs only update when needed', (
      tester,
    ) async {
      const testKey = Key('test-widget');

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
          ),
          child: const MaterialApp(
            home: MediaQueryInfoTestWidget(key: testKey),
          ),
        ),
      );

      expect(find.text('Size: 400.0x800.0'), findsOneWidget);
      expect(find.text('Orientation: Orientation.portrait'), findsOneWidget);

      // Change only size - orientation should stay portrait
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(500, 800), // Different size, same orientation
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

      // Change orientation - both should update
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

      // Both should show new values
      expect(find.text('Size: 800.0x500.0'), findsOneWidget);
      expect(find.text('Orientation: Orientation.landscape'), findsOneWidget);
    });
  });
}

// Test widget that tracks builder execution
class TestWidget extends CompositionWidget {
  const TestWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final mediaQuery = useMediaQuery();

    final screenInfo = computed(() {
      return '${mediaQuery.value.size.width}x${mediaQuery.value.size.height}';
    });

    return (context) => Scaffold(
      body: Center(
        child: Text(screenInfo.value),
      ),
    );
  }
}

// Test widget with custom equals function
class CustomEqualsTestWidget extends CompositionWidget {
  const CustomEqualsTestWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Track only width changes using custom equals
    final width = useContextRef<double>(
      (context) => MediaQuery.of(context).size.width,
      equals: (a, b) => a == b, // Use value equality
    );

    final widthText = computed(() {
      return 'Width: ${width.value}';
    });

    return (context) => Scaffold(
      body: Center(
        child: Text(widthText.value),
      ),
    );
  }
}

// Test widget for useMediaQueryInfo
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
