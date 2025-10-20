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
void onMounted(void Function() fn) {}

// ============================================================================
// TEST CASES
// ============================================================================

/// Should trigger lint: async setup with async keyword
class AsyncSetupWithKeyword extends CompositionWidget {
  const AsyncSetupWithKeyword({super.key});

  @override
  // expect_lint: flutter_compositions_no_async_setup
  Future<Widget Function(BuildContext)> setup() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return (context) => const Text('Done');
  }
}

/// Should trigger lint: async arrow function setup
class AsyncSetupArrowFunction extends CompositionWidget {
  const AsyncSetupArrowFunction({super.key});

  @override
  // expect_lint: flutter_compositions_no_async_setup
  Future<Widget Function(BuildContext)> setup() async =>
      (context) => const Text('Done');
}

/// Should NOT trigger lint: synchronous setup
class SyncSetup extends CompositionWidget {
  const SyncSetup({super.key});

  @override
  Widget Function(BuildContext) setup() {
    return (context) => const Text('Done');
  }
}

/// Should NOT trigger lint: async operations in onMounted
class AsyncInLifecycleHook extends CompositionWidget {
  const AsyncInLifecycleHook({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final data = ref<String?>(null);

    // Async operations belong in lifecycle hooks
    onMounted(() async {
      await Future.delayed(const Duration(seconds: 1));
      data.value = 'loaded';
    });

    return (context) => Text(data.value ?? 'Loading...');
  }
}
