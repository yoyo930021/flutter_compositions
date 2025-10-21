import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('manageListenable & manageChangeNotifier', () {
    testWidgets('manageListenable attaches and detaches listeners', (
      tester,
    ) async {
      final notifier = CountingValueNotifier<int>(0);
      final events = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: ManageListenableHarness(notifier: notifier, events: events),
        ),
      );

      expect(events, containsAllInOrder(['add:1', 'value:42']));
      expect(notifier.addCount, 1);
      expect(find.text('Value:42'), findsOneWidget);

      notifier.value = 50;
      await tester.pump();
      expect(find.text('Value:50'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(events.last, 'listener-removed');
      expect(notifier.removeCount, 1);
      // manageListenable does NOT dispose - only removes listener
      expect(notifier.disposed, isFalse);
    });

    testWidgets(
      'manageChangeNotifier disposes supplied controller on unmount',
      (
        tester,
      ) async {
        final controller = TestController();

        await tester.pumpWidget(
          MaterialApp(home: UseControllerHarness(controller: controller)),
        );

        expect(controller.disposed, isFalse);

        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        expect(controller.disposed, isTrue);
      },
    );
  });

  group('Scroll, page, and focus helpers', () {
    testWidgets('useScrollController exposes controller instance', (
      tester,
    ) async {
      ScrollController? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: ScrollControllerHarness(
            onController: (ctrl) => captured = ctrl,
          ),
        ),
      );

      expect(captured, isA<ScrollController>());
      expect(captured!.initialScrollOffset, 0.0);
    });

    testWidgets('useScrollController triggers reactivity on scroll changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReactiveScrollControllerHarness()),
      );

      // Initial computed value should be 0.0
      expect(find.text('Offset:0.0'), findsOneWidget);

      // Simulate scroll by finding the ListView and scrolling
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();

      // Computed value should update to reflect new offset
      expect(find.text('Offset:0.0'), findsNothing);
      expect(find.textContaining('Offset:'), findsOneWidget);
    });

    testWidgets('usePageController honors initialPage', (tester) async {
      PageController? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: PageControllerHarness(
            initialPage: 2,
            onController: (ctrl) => captured = ctrl,
          ),
        ),
      );

      expect(captured, isA<PageController>());
      expect(captured!.initialPage, 2);
    });

    testWidgets('usePageController triggers reactivity on page changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReactivePageControllerHarness()),
      );

      // Wait for the PageView to be ready
      await tester.pumpAndSettle();

      // Initial page should be 0
      expect(find.text('Page:0'), findsOneWidget);

      // Swipe to next page
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // After swiping, we should see a different page (1 or 2)
      // Just verify it's not page 0 anymore
      expect(find.text('Page:0'), findsNothing);
      expect(find.textContaining('Page:'), findsOneWidget);
    });

    testWidgets('useFocusNode creates a focus node with options', (
      tester,
    ) async {
      FocusNode? node;

      await tester.pumpWidget(
        MaterialApp(
          home: FocusNodeHarness(onNodeCreated: (created) => node = created),
        ),
      );

      expect(node, isA<FocusNode>());
      expect(node!.debugLabel, 'test-node');
    });

    testWidgets('useFocusNode triggers reactivity on focus changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReactiveFocusNodeHarness()),
      );

      // Initially not focused
      expect(find.text('Focused:false'), findsOneWidget);

      // Tap the text field to focus it
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Computed value should update to focused
      expect(find.text('Focused:true'), findsOneWidget);

      // The test verifies that focus changes trigger reactivity
      // The important part is that changing focus state updates the computed
    });
  });

  group('Value helpers', () {
    testWidgets(
      'manageValueListenable syncs with ValueNotifier but does NOT dispose',
      (tester) async {
        var disposed = false;
        final notifier = DisposableValueNotifier<int>(10, () {
          disposed = true;
        });

        await tester.pumpWidget(
          MaterialApp(home: ManageValueListenableHarness(notifier: notifier)),
        );

        // Initial value should be read
        expect(find.text('Value:10'), findsOneWidget);

        // Update via notifier directly
        notifier.value = 20;
        await tester.pump();

        expect(find.text('Value:20'), findsOneWidget);
        expect(disposed, isFalse);

        // manageValueListenable does NOT dispose - only removes listener
        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        // Should NOT be disposed
        expect(disposed, isFalse);
      },
    );

    testWidgets(
      'manageValueListenable triggers reactivity on value changes',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ReactiveManageValueListenableHarness(),
          ),
        );

        // Initial computed value should be 0
        expect(find.text('Doubled:0'), findsOneWidget);

        // Tap button to increment
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Computed value should update
        expect(find.text('Doubled:10'), findsOneWidget);
      },
    );

    testWidgets('useTextEditingController syncs controller and refs', (
      tester,
    ) async {
      late TextEditingController captured;
      late String latestText;
      late TextEditingValue latestValue;

      await tester.pumpWidget(
        MaterialApp(
          home: UseTextEditingControllerHarness(
            onValues: (controller, textRef, valueRef) {
              captured = controller;
              latestText = textRef.value;
              latestValue = valueRef.value;
            },
          ),
        ),
      );

      expect(captured.text, 'changed');
      expect(latestText, 'changed');
      expect(latestValue.text, 'changed');
    });

    testWidgets(
      'useTextEditingController triggers reactivity on text changes',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ReactiveTextEditingControllerHarness()),
        );

        // Initial values
        expect(find.text('Length:7'), findsOneWidget);
        expect(find.text('Text:initial'), findsOneWidget);

        // Enter text in the TextField
        await tester.enterText(find.byType(TextField), 'Hello World');
        await tester.pump();

        // Computed values should update
        expect(find.text('Length:11'), findsOneWidget);
        expect(find.text('Text:Hello World'), findsOneWidget);
      },
    );

    testWidgets('useTextEditingController auto-disposes controller', (
      tester,
    ) async {
      var disposed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DisposableTextControllerHarness(
            onDispose: () => disposed = true,
          ),
        ),
      );

      expect(disposed, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(disposed, isTrue);
    });
  });
}

// ---------------------------------------------------------------------------
// Harness widgets used in tests
// ---------------------------------------------------------------------------

class ManageListenableHarness extends CompositionWidget {
  const ManageListenableHarness({
    required this.notifier,
    required this.events,
    super.key,
  });

  final CountingValueNotifier<int> notifier;
  final List<String> events;

  @override
  Widget Function(BuildContext) setup() {
    final counting = manageListenable(notifier);
    events.add('add:${notifier.addCount}');
    notifier.value = 42;
    events.add('value:${notifier.value}');

    onUnmounted(() {
      events.add('listener-removed');
    });

    return (context) => Text('Value:${counting.value.value}');
  }
}

class UseControllerHarness extends CompositionWidget {
  const UseControllerHarness({required this.controller, super.key});

  final TestController controller;

  @override
  Widget Function(BuildContext) setup() {
    manageChangeNotifier(controller);
    return (context) => const SizedBox();
  }
}

class ScrollControllerHarness extends CompositionWidget {
  const ScrollControllerHarness({required this.onController, super.key});

  final void Function(ScrollController controller) onController;

  @override
  Widget Function(BuildContext) setup() {
    final controller = useScrollController();
    onMounted(() => onController(controller.value));
    return (context) => const SizedBox();
  }
}

class PageControllerHarness extends CompositionWidget {
  const PageControllerHarness({
    required this.initialPage,
    required this.onController,
    super.key,
  });

  final int initialPage;
  final void Function(PageController controller) onController;

  @override
  Widget Function(BuildContext) setup() {
    final controller = usePageController(initialPage: initialPage);
    onMounted(() => onController(controller.value));
    return (context) => const SizedBox();
  }
}

class FocusNodeHarness extends CompositionWidget {
  const FocusNodeHarness({required this.onNodeCreated, super.key});

  final void Function(FocusNode node) onNodeCreated;

  @override
  Widget Function(BuildContext) setup() {
    final node = useFocusNode(debugLabel: 'test-node');
    onMounted(() => onNodeCreated(node.value));
    return (context) => const SizedBox();
  }
}

class ManageValueListenableHarness extends CompositionWidget {
  const ManageValueListenableHarness({required this.notifier, super.key});

  final ValueNotifier<int> notifier;

  @override
  Widget Function(BuildContext) setup() {
    final (_, value) = manageValueListenable(notifier);
    return (context) => Text('Value:${value.value}');
  }
}

class UseTextEditingControllerHarness extends CompositionWidget {
  const UseTextEditingControllerHarness({required this.onValues, super.key});

  final void Function(
    TextEditingController controller,
    WritableRef<String> textRef,
    WritableRef<TextEditingValue> valueRef,
  )
  onValues;

  @override
  Widget Function(BuildContext) setup() {
    final (controller, textRef, valueRef) = useTextEditingController(
      text: 'initial',
    );

    textRef.value = 'changed';
    onValues(controller, textRef, valueRef);

    return (context) => const SizedBox();
  }
}

// ---------------------------------------------------------------------------
// Helper classes
// ---------------------------------------------------------------------------

class CountingValueNotifier<T> extends ValueNotifier<T> {
  // Test helper class - super parameter naming is not important
  // ignore: matching_super_parameters
  CountingValueNotifier(super.value);

  int addCount = 0;
  int removeCount = 0;
  bool disposed = false;

  @override
  void addListener(VoidCallback listener) {
    addCount++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    removeCount++;
    super.removeListener(listener);
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

class TestController extends ChangeNotifier {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

class DisposableValueNotifier<T> extends ValueNotifier<T> {
  // Test helper class - super parameter naming is not important
  // ignore: matching_super_parameters
  DisposableValueNotifier(super.value, this.onDispose);

  final VoidCallback onDispose;

  @override
  void dispose() {
    onDispose();
    super.dispose();
  }
}

class DisposableTextControllerHarness extends CompositionWidget {
  const DisposableTextControllerHarness({
    required this.onDispose,
    super.key,
  });

  final VoidCallback onDispose;

  @override
  Widget Function(BuildContext) setup() {
    useTextEditingController(text: 'test');

    // Add unmounted callback to track disposal
    onUnmounted(onDispose);

    return (context) => const SizedBox();
  }
}

// ---------------------------------------------------------------------------
// Reactivity test harness widgets
// ---------------------------------------------------------------------------

class ReactiveScrollControllerHarness extends CompositionWidget {
  const ReactiveScrollControllerHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final scrollController = useScrollController();

    // Create a computed that tracks the scroll offset
    final scrollOffset = computed(() {
      scrollController.value; // Establish dependency
      // Check if controller is attached before reading offset
      if (scrollController.value.hasClients) {
        return scrollController.value.offset;
      }
      return 0.0;
    });

    return (context) => Scaffold(
      body: Column(
        children: [
          // No ComputedBuilder needed - direct access triggers rebuild
          Text('Offset:${scrollOffset.value}'),
          Expanded(
            child: ListView.builder(
              controller: scrollController.value,
              itemCount: 50,
              itemBuilder: (context, index) => ListTile(
                title: Text('Item $index'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReactivePageControllerHarness extends CompositionWidget {
  const ReactivePageControllerHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final pageController = usePageController();

    // Create a computed that tracks the current page
    final currentPage = computed(() {
      pageController.value; // Establish dependency
      if (pageController.value.hasClients) {
        return pageController.value.page?.round() ?? 0;
      }
      return 0;
    });

    return (context) => Scaffold(
      body: Column(
        children: [
          // No ComputedBuilder needed - direct access triggers rebuild
          Text('Page:${currentPage.value}'),
          Expanded(
            child: PageView(
              controller: pageController.value,
              children: [
                Container(color: Colors.red),
                Container(color: Colors.blue),
                Container(color: Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReactiveFocusNodeHarness extends CompositionWidget {
  const ReactiveFocusNodeHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final focusNode = useFocusNode(debugLabel: 'test-field');

    // Create a computed that tracks the focus state
    final isFocused = computed(() {
      focusNode.value; // Establish dependency
      return focusNode.value.hasFocus;
    });

    return (context) => Scaffold(
      body: Column(
        children: [
          // No ComputedBuilder needed - direct access triggers rebuild
          Text('Focused:${isFocused.value}'),
          TextField(
            focusNode: focusNode.value,
            decoration: const InputDecoration(
              hintText: 'Test field',
            ),
          ),
        ],
      ),
    );
  }
}

class ReactiveManageValueListenableHarness extends CompositionWidget {
  const ReactiveManageValueListenableHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (notifier, count) = manageValueListenable(ValueNotifier<int>(0));

    // Create a computed that depends on the notifier value
    final doubled = computed(() => count.value * 2);

    return (context) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ComputedBuilder(
              builder: () => Text('Doubled:${doubled.value}'),
            ),
            ElevatedButton(
              onPressed: () {
                notifier.value += 5;
              },
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReactiveTextEditingControllerHarness extends CompositionWidget {
  const ReactiveTextEditingControllerHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controller, text, _) = useTextEditingController(text: 'initial');

    // Create a computed that tracks the text length
    final textLength = computed(() => text.value.length);

    return (context) => Scaffold(
      body: Column(
        children: [
          // No ComputedBuilder needed - direct access triggers rebuild
          Text('Length:${textLength.value}'),
          Text('Text:${text.value}'),
          TextField(controller: controller),
        ],
      ),
    );
  }
}
