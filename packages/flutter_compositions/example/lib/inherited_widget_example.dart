import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

/// Example demonstrating the use of InheritedWidget composables
class InheritedWidgetExample extends StatelessWidget {
  const InheritedWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InheritedWidget Composables')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          MediaQueryCard(),
          SizedBox(height: 16),
          ThemeCard(),
          SizedBox(height: 16),
          ResponsiveCard(),
        ],
      ),
    );
  }
}

/// Example using useMediaQuery
class MediaQueryCard extends CompositionWidget {
  const MediaQueryCard({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final mediaQuery = useMediaQuery();

    final width = computed(() => mediaQuery.value.size.width.toStringAsFixed(0));
    final height = computed(() => mediaQuery.value.size.height.toStringAsFixed(0));
    final orientation = computed(() =>
      mediaQuery.value.orientation == Orientation.portrait
        ? 'Portrait'
        : 'Landscape'
    );
    final pixelRatio = computed(() => mediaQuery.value.devicePixelRatio.toStringAsFixed(2));

    return (context) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MediaQuery Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Screen size: ${width.value} x ${height.value}'),
            Text('Orientation: ${orientation.value}'),
            Text('Pixel ratio: ${pixelRatio.value}'),
          ],
        ),
      ),
    );
  }
}

/// Example using useTheme
class ThemeCard extends CompositionWidget {
  const ThemeCard({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final theme = useTheme();

    final primaryColorHex = computed(() {
      final color = theme.value.primaryColor;
      // Convert Color to hex string using new component accessors
      final r = ((color.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
      final g = ((color.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
      final b = ((color.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
      return '#$r$g$b'.toUpperCase();
    });

    final brightness = computed(() =>
      theme.value.brightness == Brightness.light ? 'Light' : 'Dark'
    );

    return (context) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Primary color: ${primaryColorHex.value}'),
            Text('Brightness: ${brightness.value}'),
          ],
        ),
      ),
    );
  }
}

/// Example using useMediaQueryInfo for responsive design
class ResponsiveCard extends CompositionWidget {
  const ResponsiveCard({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (size, orientation) = useMediaQueryInfo();

    // Computed responsive breakpoints
    final isSmallScreen = computed(() => size.value.width < 600);
    final isMediumScreen = computed(() =>
      size.value.width >= 600 && size.value.width < 900
    );
    final isPortrait = computed(() => orientation.value == Orientation.portrait);

    // Derived UI values
    final screenSizeLabel = computed(() {
      if (isSmallScreen.value) return 'Small';
      if (isMediumScreen.value) return 'Medium';
      return 'Large';
    });

    final columns = computed(() {
      if (isSmallScreen.value) return 1;
      if (isMediumScreen.value) return 2;
      return 3;
    });

    final fontSize = computed(() {
      if (isSmallScreen.value) return 14.0;
      if (isMediumScreen.value) return 16.0;
      return 18.0;
    });

    return (context) => Card(
      color: isSmallScreen.value
          ? Colors.red[50]
          : isMediumScreen.value
              ? Colors.blue[50]
              : Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Responsive Design',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Screen: ${screenSizeLabel.value} (${size.value.width.toStringAsFixed(0)}dp)',
              style: TextStyle(fontSize: fontSize.value),
            ),
            Text(
              'Orientation: ${isPortrait.value ? "Portrait" : "Landscape"}',
              style: TextStyle(fontSize: fontSize.value),
            ),
            Text(
              'Columns: ${columns.value}',
              style: TextStyle(fontSize: fontSize.value),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: (size.value.width - 48) / columns.value - 8,
                  height: 60,
                  child: Container(
                    color: Colors.blue[200],
                    alignment: Alignment.center,
                    child: Text('${index + 1}'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
