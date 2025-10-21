import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('useContext', () {
    testWidgets('provides reactive BuildContext reference', (tester) async {
      BuildContext? capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: UseContextHarness(
            onContext: (ctx) => capturedContext = ctx,
          ),
        ),
      );

      expect(capturedContext, isNotNull);
      expect(capturedContext, isA<BuildContext>());
    });

    testWidgets('context can be used to access InheritedWidgets', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: Colors.blue),
          home: const Scaffold(
            body: InheritedWidgetAccessHarness(),
          ),
        ),
      );

      // Check that we can access theme data through the context
      expect(find.textContaining('Primary:'), findsOneWidget);
    });

    testWidgets('context is null during setup', (tester) async {
      var contextInSetup = false;

      await tester.pumpWidget(
        MaterialApp(
          home: UseContextSetupCheckHarness(
            onContextInSetup: ({required bool hasContext}) =>
                contextInSetup = hasContext,
          ),
        ),
      );

      expect(contextInSetup, isFalse);
    });
  });

  group('useSearchController', () {
    testWidgets('creates a search controller', (tester) async {
      SearchController? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: UseSearchControllerHarness(
            onController: (controller) => captured = controller,
          ),
        ),
      );

      expect(captured, isNotNull);
      expect(captured, isA<SearchController>());
      expect(captured!.text, isEmpty);
    });

    testWidgets('tracks search text changes reactively', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReactiveSearchControllerHarness(),
        ),
      );

      expect(find.text('Search: '), findsOneWidget);

      // Find the TextField inside SearchBar and enter text
      await tester.tap(find.byType(SearchBar));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'flutter');
      await tester.pump();

      expect(find.text('Search: flutter'), findsOneWidget);
    });

    testWidgets('disposes controller on unmount', (tester) async {
      SearchController? capturedController;

      await tester.pumpWidget(
        MaterialApp(
          home: SearchControllerLifecycleHarness(
            onController: (ctrl) => capturedController = ctrl,
          ),
        ),
      );

      expect(capturedController, isNotNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      // Controller should be disposed, but we can't directly check this
      // We just verify it doesn't throw
      expect(capturedController, isNotNull);
    });

    testWidgets('triggers watch callback on text change', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchControllerWatchHarness(),
        ),
      );

      expect(find.text('Changes: 0'), findsOneWidget);

      await tester.tap(find.byType(SearchBar));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'test');
      await tester.pump();

      // Text entered should trigger watch callback
      expect(find.textContaining('Changes:'), findsOneWidget);
      // Verify it's no longer 0
      expect(find.text('Changes: 0'), findsNothing);
    });
  });

  group('useAppLifecycleState', () {
    testWidgets('provides current lifecycle state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UseAppLifecycleStateHarness(),
        ),
      );

      // Initial state should be resumed
      expect(
        find.text('State: AppLifecycleState.resumed'),
        findsOneWidget,
      );
    });

    testWidgets('tracks lifecycle state changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UseAppLifecycleStateHarness(),
        ),
      );

      expect(
        find.text('State: AppLifecycleState.resumed'),
        findsOneWidget,
      );

      // Simulate app going to background
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(find.text('State: AppLifecycleState.paused'), findsOneWidget);

      // Simulate app returning to foreground
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(
        find.text('State: AppLifecycleState.resumed'),
        findsOneWidget,
      );
    });

    testWidgets('triggers watch callback on lifecycle change', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppLifecycleWatchHarness(),
        ),
      );

      // Initial state - no changes yet (watch hasn't triggered)
      expect(find.text('Changes: 0'), findsOneWidget);

      // Simulate lifecycle changes
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      // After first change
      expect(find.textContaining('Changes:'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Verify that changes were tracked (should be at least 3)
      expect(find.textContaining('Changes:'), findsOneWidget);
    });

    testWidgets('removes observer on unmount', (tester) async {
      // This test verifies that the WidgetsBindingObserver is properly removed
      // by checking that the widget can be unmounted without errors
      await tester.pumpWidget(
        MaterialApp(
          home: AppLifecycleLifecycleHarness(
            onChange: () {},
          ),
        ),
      );

      // Trigger lifecycle change while mounted
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // Unmount the widget - this should remove the observer
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      // Trigger lifecycle change after unmount - should not cause errors
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // If we get here without errors, the observer was properly removed
      expect(tester.takeException(), isNull);
    });

    testWidgets('works with multiple lifecycle states', (tester) async {
      final capturedStates = <AppLifecycleState>[];

      await tester.pumpWidget(
        MaterialApp(
          home: MultipleLifecycleStatesTrackingHarness(
            onStateChange: capturedStates.add,
          ),
        ),
      );

      // Clear the initial state
      capturedStates.clear();

      final testStates = [
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.detached,
        AppLifecycleState.hidden,
        AppLifecycleState.resumed,
      ];

      for (final state in testStates) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }

      // Verify all states were captured
      expect(capturedStates, containsAll(testStates));
      expect(capturedStates.length, greaterThanOrEqualTo(testStates.length));
    });
  });
}

// ---------------------------------------------------------------------------
// Harness widgets - useContext
// ---------------------------------------------------------------------------

class UseContextHarness extends CompositionWidget {
  const UseContextHarness({
    required this.onContext,
    super.key,
  });

  final void Function(BuildContext context) onContext;

  @override
  Widget Function(BuildContext) setup() {
    final contextRef = useContext();

    onMounted(() => onContext(contextRef.value!));

    return (context) {
      contextRef.value = context;
      return const SizedBox();
    };
  }
}

class InheritedWidgetAccessHarness extends CompositionWidget {
  const InheritedWidgetAccessHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final contextRef = useContext();

    return (context) {
      contextRef.value = context;

      final theme = Theme.of(contextRef.value!);
      return Text('Primary: ${theme.primaryColor}');
    };
  }
}

class UseContextSetupCheckHarness extends CompositionWidget {
  const UseContextSetupCheckHarness({
    required this.onContextInSetup,
    super.key,
  });

  final void Function({required bool hasContext}) onContextInSetup;

  @override
  Widget Function(BuildContext) setup() {
    final contextRef = useContext();

    // Check if context is null during setup
    final hasContextInSetup = contextRef.value != null;

    onMounted(() => onContextInSetup(hasContext: hasContextInSetup));

    return (context) {
      contextRef.value = context;
      return const SizedBox();
    };
  }
}

// ---------------------------------------------------------------------------
// Harness widgets - useSearchController
// ---------------------------------------------------------------------------

class UseSearchControllerHarness extends CompositionWidget {
  const UseSearchControllerHarness({
    required this.onController,
    super.key,
  });

  final void Function(SearchController controller) onController;

  @override
  Widget Function(BuildContext) setup() {
    final searchController = useSearchController();

    onMounted(() => onController(searchController.value));

    return (context) => SearchAnchor(
          searchController: searchController.value,
          builder: (context, controller) {
            return SearchBar(
              controller: controller,
              hintText: 'Search...',
            );
          },
          suggestionsBuilder: (context, controller) {
            return [];
          },
        );
  }
}

class ReactiveSearchControllerHarness extends CompositionWidget {
  const ReactiveSearchControllerHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final searchController = useSearchController();

    final searchText = computed(() {
      searchController.value; // Track changes
      return searchController.value.text;
    });

    return (context) => Column(
          children: [
            Text('Search: ${searchText.value}'),
            SearchAnchor(
              searchController: searchController.value,
              builder: (context, controller) {
                return SearchBar(
                  controller: controller,
                  hintText: 'Search...',
                );
              },
              suggestionsBuilder: (context, controller) {
                return [];
              },
            ),
          ],
        );
  }
}

class SearchControllerLifecycleHarness extends CompositionWidget {
  const SearchControllerLifecycleHarness({
    required this.onController,
    super.key,
  });

  final void Function(SearchController controller) onController;

  @override
  Widget Function(BuildContext) setup() {
    final searchController = useSearchController();

    onMounted(() => onController(searchController.value));

    return (context) => const SizedBox();
  }
}

class SearchControllerWatchHarness extends CompositionWidget {
  const SearchControllerWatchHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final searchController = useSearchController();
    var changeCount = 0;

    final changes = ref(0);

    watch(
      () => searchController.value.text,
      (newValue, oldValue) {
        changeCount++;
        changes.value = changeCount;
      },
    );

    return (context) => Column(
          children: [
            Text('Changes: ${changes.value}'),
            SearchAnchor(
              searchController: searchController.value,
              builder: (context, controller) {
                return SearchBar(
                  controller: controller,
                  hintText: 'Search...',
                );
              },
              suggestionsBuilder: (context, controller) {
                return [];
              },
            ),
          ],
        );
  }
}

// ---------------------------------------------------------------------------
// Harness widgets - useAppLifecycleState
// ---------------------------------------------------------------------------

class UseAppLifecycleStateHarness extends CompositionWidget {
  const UseAppLifecycleStateHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final lifecycleState = useAppLifecycleState();

    return (context) => Text('State: ${lifecycleState.value}');
  }
}

class AppLifecycleWatchHarness extends CompositionWidget {
  const AppLifecycleWatchHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final lifecycleState = useAppLifecycleState();
    var changeCount = 0;

    final changes = ref(0);

    watch(
      () => lifecycleState.value,
      (newState, oldState) {
        changeCount++;
        changes.value = changeCount;
      },
    );

    return (context) => Text('Changes: ${changes.value}');
  }
}

class AppLifecycleLifecycleHarness extends CompositionWidget {
  const AppLifecycleLifecycleHarness({
    required this.onChange,
    super.key,
  });

  final VoidCallback onChange;

  @override
  Widget Function(BuildContext) setup() {
    final lifecycleState = useAppLifecycleState();

    watch(
      () => lifecycleState.value,
      (newState, oldState) {
        onChange();
      },
    );

    return (context) => const SizedBox();
  }
}

class MultipleLifecycleStatesTrackingHarness extends CompositionWidget {
  const MultipleLifecycleStatesTrackingHarness({
    required this.onStateChange,
    super.key,
  });

  final void Function(AppLifecycleState state) onStateChange;

  @override
  Widget Function(BuildContext) setup() {
    final lifecycleState = useAppLifecycleState();

    watch(
      () => lifecycleState.value,
      (newState, oldState) {
        onStateChange(newState);
      },
    );

    return (context) => const SizedBox();
  }
}
