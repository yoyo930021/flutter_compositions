import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

// Test cases for no_conditional_composition lint rule

// ❌ BAD: Composition API in if statement
class BadIfStatement extends CompositionWidget {
  const BadIfStatement({super.key, required this.showCount});
  final bool showCount;

  @override
  Widget Function(BuildContext) setup() {
    if (showCount) {
      // expect_lint: flutter_compositions_no_conditional_composition
      final count = ref(0);
    }

    return (context) => const Text('Hello');
  }
}

// ❌ BAD: Composition API in for loop
class BadForLoop extends CompositionWidget {
  const BadForLoop({super.key});

  @override
  Widget Function(BuildContext) setup() {
    for (var i = 0; i < 10; i++) {
      // expect_lint: flutter_compositions_no_conditional_composition
      final item = ref(i);
    }

    return (context) => const Text('Hello');
  }
}

// ❌ BAD: Composition API in while loop
class BadWhileLoop extends CompositionWidget {
  const BadWhileLoop({super.key});

  @override
  Widget Function(BuildContext) setup() {
    var i = 0;
    while (i < 10) {
      // expect_lint: flutter_compositions_no_conditional_composition
      final item = ref(i);
      i++;
    }

    return (context) => const Text('Hello');
  }
}

// ❌ BAD: onMounted in conditional
class BadConditionalOnMounted extends CompositionWidget {
  const BadConditionalOnMounted({super.key, required this.condition});
  final bool condition;

  @override
  Widget Function(BuildContext) setup() {
    if (condition) {
      // expect_lint: flutter_compositions_no_conditional_composition
      onMounted(() {
        print('Mounted');
      });
    }

    return (context) => const Text('Hello');
  }
}

// ❌ BAD: useScrollController in conditional
class BadConditionalController extends CompositionWidget {
  const BadConditionalController({super.key, required this.useScroll});
  final bool useScroll;

  @override
  Widget Function(BuildContext) setup() {
    if (useScroll) {
      // expect_lint: flutter_compositions_no_conditional_composition
      final controller = useScrollController();
    }

    return (context) => const Text('Hello');
  }
}

// ❌ BAD: watch in conditional
class BadConditionalWatch extends CompositionWidget {
  const BadConditionalWatch({super.key, required this.shouldWatch});
  final bool shouldWatch;

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    if (shouldWatch) {
      // expect_lint: flutter_compositions_no_conditional_composition
      watch(() => count.value, (newValue, oldValue) {
        print('Changed: $newValue');
      });
    }

    return (context) => Text('Count: ${count.value}');
  }
}

// ❌ BAD: computed in switch
class BadSwitchComputed extends CompositionWidget {
  const BadSwitchComputed({super.key, required this.mode});
  final String mode;

  @override
  Widget Function(BuildContext) setup() {
    switch (mode) {
      case 'count':
        // expect_lint: flutter_compositions_no_conditional_composition
        final count = ref(0);
        break;
      default:
        break;
    }

    return (context) => const Text('Hello');
  }
}

// ✅ GOOD: Composition APIs at top level
class GoodTopLevel extends CompositionWidget {
  const GoodTopLevel({super.key, required this.showCount});
  final bool showCount;

  @override
  Widget Function(BuildContext) setup() {
    // ✅ Composition APIs at top level
    final count = ref(0);
    final doubled = computed(() => count.value * 2);
    final controller = useScrollController();

    // ✅ Conditional logic for values is OK
    if (showCount) {
      count.value = 10;
    }

    onMounted(() {
      print('Mounted');
    });

    return (context) => Text('Count: ${count.value}');
  }
}

// ✅ GOOD: Conditional in returned builder is OK
class GoodConditionalInBuilder extends CompositionWidget {
  const GoodConditionalInBuilder({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    return (context) {
      // ✅ Conditionals in builder are OK
      if (count.value > 5) {
        return const Text('High');
      }
      return Text('Count: ${count.value}');
    };
  }
}

// ✅ GOOD: All composition APIs unconditionally
class GoodUnconditional extends CompositionWidget {
  const GoodUnconditional({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    final text = ref('Hello');
    final controller = useScrollController();

    watch(() => count.value, (newValue, oldValue) {
      print('Count changed');
    });

    onMounted(() {
      print('Mounted');
    });

    onUnmounted(() {
      print('Unmounted');
    });

    return (context) => ListView(
          controller: controller.raw,
          children: [Text('${count.value}'), Text(text.value)],
        );
  }
}
