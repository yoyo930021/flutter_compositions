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

class ComputedRef<T> {
  T get value => throw UnimplementedError();
}

Ref<T> ref<T>(T value) => throw UnimplementedError();
ComputedRef<T> computed<T>(T Function() fn) => throw UnimplementedError();
ComputedRef<T> useScrollController<T>() => throw UnimplementedError();
void onUnmounted(void Function() fn) {}
void onMounted(void Function() fn) {}

// ============================================================================
// GOOD EXAMPLES - These should pass all lint checks
// ============================================================================

/// ✅ GOOD: Using widget() for reactive props
class GoodReactiveProps extends CompositionWidget {
  const GoodReactiveProps({super.key, required this.name});

  final String name;

  @override
  Widget Function(BuildContext) setup() {
    // Access props through widget() - fully reactive!
    final props = widget();
    final greeting = computed(
      () => 'Hello, ${(props.value as GoodReactiveProps).name}!',
    );

    return (context) => Text(greeting.value);
  }
}

// Mock widget() extension
extension on CompositionWidget {
  ComputedRef<CompositionWidget> widget() => throw UnimplementedError();
}

/// ✅ GOOD: Synchronous setup with async in onMounted
class GoodAsyncInLifecycle extends CompositionWidget {
  const GoodAsyncInLifecycle({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final data = ref<String?>(null);

    // Async operations in onMounted, not setup!
    onMounted(() async {
      data.value = await loadData();
    });

    return (context) => Text(data.value ?? 'Loading...');
  }

  Future<String> loadData() async {
    await Future.delayed(Duration(seconds: 1));
    return 'Data loaded';
  }
}

/// ✅ GOOD: Using useScrollController helper
class GoodControllerWithHelper extends CompositionWidget {
  const GoodControllerWithHelper({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Using helper - automatic disposal!
    final controller = useScrollController();

    return (context) => ListView(
      controller: controller.value as ScrollController,
      children: [],
    );
  }
}

/// ✅ GOOD: Manual disposal with onUnmounted
class GoodControllerWithManualDisposal extends CompositionWidget {
  const GoodControllerWithManualDisposal({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final controller = ScrollController();

    // Manual disposal - properly managed!
    onUnmounted(() => controller.dispose());

    return (context) => ListView(controller: controller, children: []);
  }
}

/// ✅ GOOD: All fields are final
class GoodFinalFields extends CompositionWidget {
  const GoodFinalFields({super.key, required this.initialCount});

  // Final field - immutable prop
  final int initialCount;

  @override
  Widget Function(BuildContext) setup() {
    // Mutable state managed via ref
    final count = ref(initialCount);

    return (context) => Text('Count: ${count.value}');
  }
}

/// ✅ GOOD: Custom type for provide/inject
class GoodProvideCustomType extends CompositionWidget {
  const GoodProvideCustomType({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(AppTheme('light'));

    // Using custom type - no conflicts!
    provide<Ref<AppTheme>>(theme);

    return (context) => Text('Theme provided');
  }
}

// Custom data class for type safety
class AppTheme {
  const AppTheme(this.mode);
  final String mode;
}

// Mock provide function
void provide<T>(T value) {}
