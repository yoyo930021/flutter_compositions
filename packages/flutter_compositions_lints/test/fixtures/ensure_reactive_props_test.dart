// ignore_for_file: unused_local_variable, unused_element
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

class ComputedRef<T> {
  T get value => throw UnimplementedError();
}

Ref<T> ref<T>(T value) => throw UnimplementedError();
ComputedRef<T> computed<T>(T Function() fn) => throw UnimplementedError();

extension CompositionWidgetExtension on CompositionWidget {
  ComputedRef<CompositionWidget> widget() => throw UnimplementedError();
}

// ============================================================================
// TEST CASES
// ============================================================================

/// Should trigger lint: direct property access in setup
class DirectPropertyAccess extends CompositionWidget {
  const DirectPropertyAccess({super.key, required this.name});

  final String name;

  @override
  Widget Function(BuildContext) setup() {
    // expect_lint: flutter_compositions_ensure_reactive_props
    final greeting = 'Hello, $name!';

    return (context) => Text(greeting);
  }
}

/// Should trigger lint: implicit this property access
class ImplicitThisAccess extends CompositionWidget {
  const ImplicitThisAccess({super.key, required this.count});

  final int count;

  @override
  Widget Function(BuildContext) setup() {
    // expect_lint: flutter_compositions_ensure_reactive_props
    final doubled = count * 2;

    return (context) => Text('$doubled');
  }
}

/// Should NOT trigger lint: using widget() for reactive access
class ReactivePropertyAccess extends CompositionWidget {
  const ReactivePropertyAccess({super.key, required this.name});

  final String name;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    final greeting = computed(() => 'Hello, ${props.value.name}!');

    return (context) => Text(greeting.value);
  }
}

/// Should NOT trigger lint: property access in builder function is allowed
class PropertyAccessInBuilder extends CompositionWidget {
  const PropertyAccessInBuilder({super.key, required this.label});

  final String label;

  @override
  Widget Function(BuildContext) setup() {
    // Property access in the returned builder is allowed
    return (context) => Text('Label: $label');
  }
}

/// Should trigger lint: explicit this.property access
class ExplicitThisAccess extends CompositionWidget {
  const ExplicitThisAccess({super.key, required this.title});

  final String title;

  @override
  Widget Function(BuildContext) setup() {
    // expect_lint: flutter_compositions_ensure_reactive_props
    final uppercaseTitle = this.title.toUpperCase();

    return (context) => Text(uppercaseTitle);
  }
}
