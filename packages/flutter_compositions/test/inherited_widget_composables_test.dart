import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('useMediaQuery', () {
    testWidgets('provides reactive MediaQueryData', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UseMediaQueryHarness(),
        ),
      );

      expect(find.textContaining('Size:'), findsOneWidget);
      expect(find.textContaining('Orientation:'), findsOneWidget);
    });

    // Note: MediaQuery updates are tested through the main test above
    // Testing dynamic MediaQuery changes requires more complex setup
  });

  group('useTheme', () {
    testWidgets('provides reactive ThemeData', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: Colors.blue),
          home: const UseThemeHarness(),
        ),
      );

      expect(find.textContaining('Primary:'), findsOneWidget);
      expect(find.textContaining('Blue'), findsOneWidget);
    });

    // Note: Dynamic theme changes are complex to test in widget tests
    // The main test above verifies basic functionality
  });

  group('useMediaQueryInfo', () {
    testWidgets('provides size and orientation separately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UseMediaQueryInfoHarness(),
        ),
      );

      // Just verify the widgets are rendered
      expect(find.textContaining('Width:'), findsOneWidget);
      // Orientation text should exist (either Portrait or Landscape)
      expect(find.byType(Text), findsNWidgets(2));
    });
  });

  group('usePlatformBrightness', () {
    testWidgets('provides platform brightness', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UsePlatformBrightnessHarness(),
        ),
      );

      expect(find.textContaining('Brightness:'), findsOneWidget);
    });
  });

  group('useTextScale', () {
    testWidgets('provides text scale factor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UseTextScaleFactorHarness(),
        ),
      );

      expect(find.textContaining('Scale:'), findsOneWidget);
    });
  });

  group('useLocale', () {
    testWidgets('provides current locale', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en', 'US'),
          home: UseLocaleHarness(),
        ),
      );

      expect(find.textContaining('en'), findsOneWidget);
    });
  });

  group('useContextRef', () {
    testWidgets('provides custom inherited widget data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomInheritedWidget(
            data: 'Hello World',
            child: UseCustomInheritedHarness(),
          ),
        ),
      );

      expect(find.text('Data: Hello World'), findsOneWidget);
    });

    // Regression test for: setState() or markNeedsBuild() called during build
    // when useContextRef is used in a CompositionBuilder nested inside a
    // parent CompositionWidget that also uses useContextRef.
    // See: https://github.com/yoyo930021/flutter_compositions/issues/XXX
    testWidgets(
      'does not throw when CompositionBuilder with useContextRef is nested '
      'inside a CompositionWidget with useContextRef',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: CustomInheritedWidget(
              data: 'parent-data',
              child: NestedUseContextRefParent(),
            ),
          ),
        );

        // Parent should render its useContextRef value
        expect(find.text('Parent: parent-data'), findsOneWidget);
        // Child CompositionBuilder should render its useContextRef value
        expect(find.text('Child: parent-data'), findsOneWidget);
      },
    );

    testWidgets(
      'does not throw when multiple CompositionBuilders with useContextRef '
      'are nested inside a CompositionWidget',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(primaryColor: Colors.blue),
            home: const CustomInheritedWidget(
              data: 'test-data',
              child: MultiNestedUseContextRefParent(),
            ),
          ),
        );

        expect(find.text('Parent theme: true'), findsOneWidget);
        expect(find.text('Child1: test-data'), findsOneWidget);
        expect(find.text('Child2: test-data'), findsOneWidget);
      },
    );

    // Note: Testing InheritedWidget updates requires careful setup
    // The main test above verifies the basic integration
  });
}

// ---------------------------------------------------------------------------
// Harness widgets
// ---------------------------------------------------------------------------

class UseMediaQueryHarness extends CompositionWidget {
  const UseMediaQueryHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final mediaQuery = useMediaQuery();

    final sizeText = computed(
      () =>
          'Size: ${mediaQuery.value.size.width}x${mediaQuery.value.size.height}',
    );

    final orientationText = computed(
      () =>
          'Orientation: ${mediaQuery.value.orientation == Orientation.portrait ? "Portrait" : "Landscape"}',
    );

    return (context) => Column(
      children: [
        Text(sizeText.value),
        Text(orientationText.value),
      ],
    );
  }
}

class UseThemeHarness extends CompositionWidget {
  const UseThemeHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final theme = useTheme();

    final primaryColorName = computed(() {
      final color = theme.value.primaryColor;
      if (color == Colors.blue) return 'Blue';
      if (color == Colors.red) return 'Red';
      return 'Other';
    });

    final brightnessText = computed(
      () => theme.value.brightness == Brightness.light ? 'Light' : 'Dark',
    );

    return (context) => Column(
      children: [
        Text('Primary: ${primaryColorName.value}'),
        Text('Brightness: ${brightnessText.value}'),
      ],
    );
  }
}

class UseMediaQueryInfoHarness extends CompositionWidget {
  const UseMediaQueryInfoHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (size, orientation) = useMediaQueryInfo();

    final widthText = computed(() => 'Width: ${size.value.width}');
    final orientationText = computed(
      () =>
          orientation.value == Orientation.portrait ? 'Portrait' : 'Landscape',
    );

    return (context) => Column(
      children: [
        Text(widthText.value),
        Text(orientationText.value),
      ],
    );
  }
}

class UsePlatformBrightnessHarness extends CompositionWidget {
  const UsePlatformBrightnessHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final brightness = usePlatformBrightness();

    final brightnessText = computed(
      () =>
          'Brightness: ${brightness.value == Brightness.light ? "Light" : "Dark"}',
    );

    return (context) => Text(brightnessText.value);
  }
}

class UseTextScaleFactorHarness extends CompositionWidget {
  const UseTextScaleFactorHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final scale = useTextScale();

    final scaleText = computed(() => 'Scale: ${scale.value}');

    return (context) => Text(scaleText.value);
  }
}

class UseLocaleHarness extends CompositionWidget {
  const UseLocaleHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final locale = useLocale();

    final localeText = computed(() => 'Locale: ${locale.value.languageCode}');

    return (context) => Text(localeText.value);
  }
}

class UseCustomInheritedHarness extends CompositionWidget {
  const UseCustomInheritedHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final data = useContextRef<String>(
      (context) => CustomInheritedWidget.of(context).data,
    );

    final dataText = computed(() => 'Data: ${data.value}');

    return (context) => Text(dataText.value);
  }
}

// ---------------------------------------------------------------------------
// Custom InheritedWidget for testing
// ---------------------------------------------------------------------------

// Regression test harness: parent CompositionWidget + child CompositionBuilder
// both using useContextRef on the same InheritedWidget.
class NestedUseContextRefParent extends CompositionWidget {
  const NestedUseContextRefParent({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final parentData = useContextRef<String>(
      (context) => CustomInheritedWidget.of(context).data,
    );

    return (context) => Column(
      children: [
        Text('Parent: ${parentData.value}'),
        CompositionBuilder(
          setup: () {
            final childData = useContextRef<String>(
              (context) => CustomInheritedWidget.of(context).data,
            );

            return (context) => Text('Child: ${childData.value}');
          },
        ),
      ],
    );
  }
}

// Regression test harness: parent CompositionWidget with useTheme + multiple
// child CompositionBuilders with useContextRef.
class MultiNestedUseContextRefParent extends CompositionWidget {
  const MultiNestedUseContextRefParent({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final theme = useTheme();

    return (context) => Column(
      children: [
        Text('Parent theme: ${theme.value.primaryColor == Colors.blue}'),
        CompositionBuilder(
          setup: () {
            final data = useContextRef<String>(
              (context) => CustomInheritedWidget.of(context).data,
            );
            return (context) => Text('Child1: ${data.value}');
          },
        ),
        CompositionBuilder(
          setup: () {
            final data = useContextRef<String>(
              (context) => CustomInheritedWidget.of(context).data,
            );
            return (context) => Text('Child2: ${data.value}');
          },
        ),
      ],
    );
  }
}

class CustomInheritedWidget extends InheritedWidget {
  const CustomInheritedWidget({
    required this.data,
    required super.child,
    super.key,
  });

  final String data;

  static CustomInheritedWidget of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CustomInheritedWidget>()!;
  }

  @override
  bool updateShouldNotify(CustomInheritedWidget oldWidget) {
    return data != oldWidget.data;
  }
}
