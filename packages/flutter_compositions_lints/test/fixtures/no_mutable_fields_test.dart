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

// ============================================================================
// TEST CASES
// ============================================================================

/// Should trigger lint: non-final field
// ignore: must_be_immutable
class MutableField extends CompositionWidget {
  MutableField({super.key});

  // expect_lint: flutter_compositions_no_mutable_fields
  int count = 0;

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Text('Count: $count');
  }
}

/// Should trigger lint: multiple non-final fields
// ignore: must_be_immutable
class MultipleMutableFields extends CompositionWidget {
  MultipleMutableFields({super.key});

  // expect_lint: flutter_compositions_no_mutable_fields
  String name = 'Default';
  // expect_lint: flutter_compositions_no_mutable_fields
  int age = 0;

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Text('$name, $age');
  }
}

/// Should NOT trigger lint: all fields are final
class AllFinalFields extends CompositionWidget {
  const AllFinalFields({super.key, required this.initialCount});

  final int initialCount;

  @override
  Widget Function(BuildContext) setup() {
    // Mutable state managed via ref
    final count = ref(initialCount);

    return (context) => Text('Count: ${count.value}');
  }
}

/// Should NOT trigger lint: const constructor with final fields
class ConstConstructorFinalFields extends CompositionWidget {
  const ConstConstructorFinalFields({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Column(children: [Text(title), Text(subtitle)]);
  }
}

/// Should NOT trigger lint: static fields are allowed
class StaticFieldsAllowed extends CompositionWidget {
  const StaticFieldsAllowed({super.key});

  static int counter = 0; // Static fields are allowed

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Text('Counter: $counter');
  }
}

/// Should trigger lint: nullable mutable field
// ignore: must_be_immutable
class NullableMutableField extends CompositionWidget {
  NullableMutableField({super.key});

  // expect_lint: flutter_compositions_no_mutable_fields
  String? optionalName;

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Text(optionalName ?? 'No name');
  }
}
