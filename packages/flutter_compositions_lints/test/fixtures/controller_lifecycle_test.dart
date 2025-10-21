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
Ref<ScrollController> useScrollController() => throw UnimplementedError();
void onUnmounted(void Function() fn) {}

// ============================================================================
// TEST CASES
// ============================================================================

/// Should trigger lint: ScrollController without disposal
class ScrollControllerNoDisposal extends CompositionWidget {
  const ScrollControllerNoDisposal({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // expect_lint: flutter_compositions_controller_lifecycle
    final controller = ScrollController();

    return (context) => ListView(controller: controller, children: []);
  }
}

/// Should trigger lint: TextEditingController without disposal
class TextEditingControllerNoDisposal extends CompositionWidget {
  const TextEditingControllerNoDisposal({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // expect_lint: flutter_compositions_controller_lifecycle
    final controller = TextEditingController();

    return (context) => TextField(controller: controller);
  }
}

/// Should trigger lint: PageController without disposal
class PageControllerNoDisposal extends CompositionWidget {
  const PageControllerNoDisposal({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // expect_lint: flutter_compositions_controller_lifecycle
    final controller = PageController();

    return (context) => PageView(controller: controller, children: []);
  }
}

/// Should NOT trigger lint: controller with manual disposal
class ControllerWithManualDisposal extends CompositionWidget {
  const ControllerWithManualDisposal({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final controller = ScrollController();

    // Manual disposal in onUnmounted
    onUnmounted(() => controller.dispose());

    return (context) => ListView(controller: controller, children: []);
  }
}

/// Should NOT trigger lint: using useScrollController helper
class ControllerWithHelper extends CompositionWidget {
  const ControllerWithHelper({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Using helper - automatic disposal
    final controller = useScrollController();

    return (context) => ListView(controller: controller.value, children: []);
  }
}

/// Should trigger lint: FocusNode without disposal
class FocusNodeNoDisposal extends CompositionWidget {
  const FocusNodeNoDisposal({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // expect_lint: flutter_compositions_controller_lifecycle
    final node = FocusNode();

    return (context) => TextField(focusNode: node);
  }
}

/// Should NOT trigger lint: multiple controllers all disposed
class MultipleControllersAllDisposed extends CompositionWidget {
  const MultipleControllersAllDisposed({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final scroll = ScrollController();
    final text = TextEditingController();

    onUnmounted(() {
      scroll.dispose();
      text.dispose();
    });

    return (context) => Column(
          children: [
            ListView(controller: scroll, children: []),
            TextField(controller: text),
          ],
        );
  }
}
