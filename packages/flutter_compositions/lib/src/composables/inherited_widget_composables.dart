import 'package:flutter/material.dart';
import 'package:flutter_compositions/src/custom_ref.dart';
import 'package:flutter_compositions/src/framework.dart';

/// Creates a reactive reference that tracks a value from BuildContext.
///
/// This is the core helper that wraps any context-dependent value into
/// a reactive reference. The value is automatically updated when it changes.
///
/// **Type Parameter:**
/// - `T`: The type of value to track
///
/// **Parameters:**
/// - `selector`: A function that extracts the value from BuildContext
/// - `equals`: Optional equality comparison function (defaults to `identical`)
///
/// Example:
/// ```dart
/// // Track screen width
/// final width = useContextRef<double>(
///   (context) => MediaQuery.of(context).size.width,
/// );
///
/// // Track theme brightness with custom equality
/// final brightness = useContextRef<Brightness>(
///   (context) => Theme.of(context).brightness,
///   equals: (a, b) => a == b,
/// );
/// ```
ReadonlyRef<T> useContextRef<T>(
  T Function(BuildContext) selector, {
  bool Function(T, T)? equals,
}) {
  T? currentValue;
  var isInitialized = false;

  final ref = ReadonlyCustomRef<T>(
    getter: (track) {
      track();
      if (!isInitialized) {
        throw StateError(
          'useContextRef accessed before first build. '
          'The value is only available after the widget has been built at least once.',
        );
      }
      return currentValue as T;
    },
  );

  onBuild((context) {
    final newValue = selector(context);

    if (!isInitialized) {
      currentValue = newValue;
      isInitialized = true;
      ref.trigger();
      return;
    }

    final areEqual =
        equals?.call(currentValue as T, newValue) ??
        identical(currentValue, newValue);

    if (!areEqual) {
      currentValue = newValue;
      ref.trigger();
    }
  });

  return ref;
}

/// Creates a reactive reference to MediaQuery data.
///
/// The MediaQuery data is automatically updated when the device orientation,
/// size, or other properties change.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final mediaQuery = useMediaQuery();
///
///   final isPortrait = computed(() =>
///     mediaQuery.value.orientation == Orientation.portrait
///   );
///
///   final screenWidth = computed(() => mediaQuery.value.size.width);
///
///   return (context) => Column(
///     children: [
///       Text('Width: ${screenWidth.value}'),
///       Text('Orientation: ${isPortrait.value ? "Portrait" : "Landscape"}'),
///     ],
///   );
/// }
/// ```
ReadonlyRef<MediaQueryData> useMediaQuery() {
  return useContextRef(MediaQuery.of);
}

/// Creates a reactive reference to Theme data.
///
/// The Theme data is automatically updated when the app theme changes.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final theme = useTheme();
///
///   final primaryColor = computed(() => theme.value.primaryColor);
///   final isDark = computed(() => theme.value.brightness == Brightness.dark);
///
///   return (context) => Container(
///     color: primaryColor.value,
///     child: Text('Dark mode: $isDark'),
///   );
/// }
/// ```
ReadonlyRef<ThemeData> useTheme() {
  return useContextRef(Theme.of);
}

/// Creates a reactive reference to the current Locale.
///
/// The Locale is automatically updated when the system locale changes.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final locale = useLocale();
///
///   final languageCode = computed(() => locale.value.languageCode);
///
///   return (context) => Text('Language: ${languageCode.value}');
/// }
/// ```
ReadonlyRef<Locale> useLocale() {
  return useContextRef(Localizations.localeOf);
}

/// Creates reactive references to MediaQuery size and orientation.
///
/// This is a convenience function that extracts commonly used properties
/// from MediaQueryData.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final (size, orientation) = useMediaQueryInfo();
///
///   final isPortrait = computed(() => orientation.value == Orientation.portrait);
///   final isSmallScreen = computed(() => size.value.width < 600);
///
///   return (context) => Text(
///     'Screen: ${isSmallScreen.value ? "Small" : "Large"}, '
///     '${isPortrait.value ? "Portrait" : "Landscape"}'
///   );
/// }
/// ```
(ReadonlyRef<Size>, ReadonlyRef<Orientation>) useMediaQueryInfo() {
  final sizeRef = useContextRef(MediaQuery.sizeOf);
  final orientationRef = useContextRef(MediaQuery.orientationOf);

  return (sizeRef, orientationRef);
}

/// Creates a reactive reference to the platform brightness (light/dark mode).
///
/// This automatically updates when the system theme changes.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final brightness = usePlatformBrightness();
///
///   final isDark = computed(() => brightness.value == Brightness.dark);
///
///   return (context) => Text(
///     'Theme: ${isDark.value ? "Dark" : "Light"}'
///   );
/// }
/// ```
ReadonlyRef<Brightness> usePlatformBrightness() {
  return useContextRef(MediaQuery.platformBrightnessOf);
}

/// Creates a reactive reference to text scale factor.
///
/// This automatically updates when the system text scale changes.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final textScaleFactor = useTextScaleFactor();
///
///   final fontSize = computed(() => 16.0 * textScaleFactor.value);
///
///   return (context) => Text(
///     'Font size: ${fontSize.value}',
///     style: TextStyle(fontSize: fontSize.value),
///   );
/// }
/// ```
ReadonlyRef<TextScaler> useTextScale() {
  return useContextRef(MediaQuery.textScalerOf);
}
