// ignore_for_file: unused_local_variable
import 'package:flutter/material.dart';

// Mock types for testing
class CompositionWidget extends StatefulWidget {
  const CompositionWidget({super.key});

  Widget Function(BuildContext) setup() {
    throw UnimplementedError();
  }

  @override
  State<CompositionWidget> createState() => throw UnimplementedError();
}

class Ref<T> {
  T get value => throw UnimplementedError();
  set value(T val) => throw UnimplementedError();
}

Ref<T> ref<T>(T value) => throw UnimplementedError();
void provide<T>(T value) {}
T inject<T>() => throw UnimplementedError();

// ============================================================================
// TEST CASES
// ============================================================================

/// Should trigger lint: provide with Ref<String>
class ProvideCommonTypeString extends CompositionWidget {
  const ProvideCommonTypeString({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final theme = ref('light');

    // expect_lint: flutter_compositions_provide_inject_type_match
    provide<Ref<String>>(theme);

    return (context) => const Text('Theme provided');
  }
}

/// Should trigger lint: inject with Ref<int>
class InjectCommonTypeInt extends CompositionWidget {
  const InjectCommonTypeInt({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // expect_lint: flutter_compositions_provide_inject_type_match
    final count = inject<Ref<int>>();

    return (context) => Text('Count: ${count.value}');
  }
}

/// Should trigger lint: provide with Ref<bool>
class ProvideCommonTypeBool extends CompositionWidget {
  const ProvideCommonTypeBool({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final isDark = ref(false);

    // expect_lint: flutter_compositions_provide_inject_type_match
    provide<Ref<bool>>(isDark);

    return (context) => const Text('Dark mode provided');
  }
}

/// Should trigger lint: provide with Ref<double>
class ProvideCommonTypeDouble extends CompositionWidget {
  const ProvideCommonTypeDouble({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final opacity = ref(0.5);

    // expect_lint: flutter_compositions_provide_inject_type_match
    provide<Ref<double>>(opacity);

    return (context) => const Text('Opacity provided');
  }
}

/// Should trigger lint: provide with Ref<List>
class ProvideCommonTypeList extends CompositionWidget {
  const ProvideCommonTypeList({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final items = ref<List<String>>([]);

    // expect_lint: flutter_compositions_provide_inject_type_match
    provide<Ref<List<String>>>(items);

    return (context) => const Text('List provided');
  }
}

/// Should trigger lint: provide with Ref<Map>
class ProvideCommonTypeMap extends CompositionWidget {
  const ProvideCommonTypeMap({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final config = ref<Map<String, dynamic>>({});

    // expect_lint: flutter_compositions_provide_inject_type_match
    provide<Ref<Map<String, dynamic>>>(config);

    return (context) => const Text('Map provided');
  }
}

/// Should NOT trigger lint: custom type with provide
class ProvideCustomType extends CompositionWidget {
  const ProvideCustomType({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(AppTheme('light'));

    // Using custom type - no lint
    provide<Ref<AppTheme>>(theme);

    return (context) => Text('Theme: ${theme.value.mode}');
  }
}

/// Should NOT trigger lint: custom type with inject
class InjectCustomType extends CompositionWidget {
  const InjectCustomType({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Using custom type - no lint
    final theme = inject<Ref<AppTheme>>();

    return (context) => Text('Theme: ${theme.value.mode}');
  }
}

/// Should NOT trigger lint: providing custom class directly
class ProvideCustomClassDirectly extends CompositionWidget {
  const ProvideCustomClassDirectly({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final config = AppConfig(apiUrl: 'https://api.example.com');

    // Custom class, not a common type - no lint
    provide<AppConfig>(config);

    return (context) => Text('API: ${config.apiUrl}');
  }
}

// Custom data classes for testing
class AppTheme {
  const AppTheme(this.mode);
  final String mode;
}

class AppConfig {
  const AppConfig({required this.apiUrl});
  final String apiUrl;
}
