// ignore_for_file: unused_local_variable, unused_element
import 'package:flutter/material.dart';

// Mock types for example purposes
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
// BAD EXAMPLES - These should trigger lint warnings
// ============================================================================

/// ❌ BAD: Direct property access (not reactive)
/// Should trigger: flutter_compositions_ensure_reactive_props
class BadReactiveProps extends CompositionWidget {
  const BadReactiveProps({super.key, required this.name});

  final String name;

  @override
  Widget Function(BuildContext) setup() {
    // Direct access to 'name' - not reactive!
    final greeting = 'Hello, $name!';

    return (context) => Text(greeting);
  }
}

/// ❌ BAD: Async setup function
/// Should trigger: flutter_compositions_no_async_setup
class BadAsyncSetup extends CompositionWidget {
  const BadAsyncSetup({super.key});

  @override
  // ignore: invalid_override
  Future<Widget Function(BuildContext)> setup() async {
    // Async setup is not allowed!
    await Future.delayed(const Duration(seconds: 1));

    return (context) => const Text('Done');
  }
}

/// ❌ BAD: Controller without disposal
/// Should trigger: flutter_compositions_controller_lifecycle
class BadControllerLifecycle extends CompositionWidget {
  const BadControllerLifecycle({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // ScrollController created but never disposed!
    final controller = ScrollController();

    return (context) => ListView(controller: controller, children: []);
  }
}

/// ❌ BAD: Mutable field
/// Should trigger: flutter_compositions_no_mutable_fields
// ignore: must_be_immutable
class BadMutableField extends CompositionWidget {
  BadMutableField({super.key});

  // Non-final field - should use ref() instead!
  int count = 0;

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Text('Count: $count');
  }
}

