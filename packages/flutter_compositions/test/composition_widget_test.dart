import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

// Define injection keys
const counterKey = InjectionKey<Ref<int>>('counter');
const optionalStringKey = InjectionKey<Ref<String>?>('optionalString');
const missingKey = InjectionKey<int>('missing');
const autoInferKey = InjectionKey<Ref<int>>('autoInfer');

void main() {
  group('CompositionWidget', () {
    testWidgets('setup runs once and widget() reacts to prop changes', (
      tester,
    ) async {
      final log = <String>[];
      ReactivePropsWidget.setupCount = 0;
      final harnessKey = GlobalKey<_ReactivePropsHarnessState>();

      await tester.pumpWidget(
        MaterialApp(
          home: ReactivePropsHarness(key: harnessKey, log: log),
        ),
      );

      expect(find.text('label:A'), findsOneWidget);
      expect(ReactivePropsWidget.setupCount, 1);
      expect(log, ['A']);

      harnessKey.currentState!.updateLabel('B');
      await tester.pump();

      expect(find.text('label:B'), findsOneWidget);
      expect(ReactivePropsWidget.setupCount, 1);
      expect(log, ['A', 'B']);
    });

    testWidgets('provide/inject shares dependencies within setup scope', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProvideAndInjectWidget()),
      );

      expect(find.text('provided:0'), findsOneWidget);
      expect(find.text('optional:none'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('increment-counter')));
      await tester.pumpAndSettle();

      expect(find.text('provided:1'), findsOneWidget);
    });

    testWidgets('inject throws when dependency is missing', (tester) async {
      final errors = <Object>[];

      await tester.pumpWidget(
        MaterialApp(home: MissingDependencyWidget(errors: errors)),
      );

      expect(errors.single, isA<StateError>());
      expect(
        (errors.single as StateError).message,
        contains('No provider found for injection key'),
      );
      expect(
        (errors.single as StateError).message,
        contains('To fix this:'),
      );
    });

    testWidgets('provide auto-infers type from value', (tester) async {
      final log = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: TypeInferenceProviderWidget(log: log),
        ),
      );

      expect(log, contains('success'));
      expect(find.text('value:42'), findsOneWidget);
    });

    testWidgets('onMounted/onUnmounted run and watch/watchEffect re-register', (
      tester,
    ) async {
      final events = <String>[];

      await tester.pumpWidget(
        MaterialApp(home: LifecycleWatcherWidget(events: events)),
      );

      // Trigger post-frame callbacks (onMounted).
      await tester.pump();

      expect(events, ['watch:null->0', 'effect:0', 'mounted']);

      await tester.tap(find.byKey(const ValueKey('increment')));
      await tester.pump();

      expect(events, [
        'watch:null->0',
        'effect:0',
        'mounted',
        'watch:0->1',
        'effect:1',
      ]);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      expect(events, [
        'watch:null->0',
        'effect:0',
        'mounted',
        'watch:0->1',
        'effect:1',
        'unmounted',
      ]);
    });

    testWidgets('optional inject returns null when provider absent', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProvideAndInjectWidget()),
      );

      expect(find.text('optional:none'), findsOneWidget);
    });
  });
}

class ReactivePropsHarness extends StatefulWidget {
  const ReactivePropsHarness({required this.log, super.key});

  final List<String> log;

  @override
  State<ReactivePropsHarness> createState() => _ReactivePropsHarnessState();
}

class _ReactivePropsHarnessState extends State<ReactivePropsHarness> {
  String _label = 'A';

  void updateLabel(String next) {
    setState(() => _label = next);
  }

  @override
  Widget build(BuildContext context) {
    return ReactivePropsWidget(label: _label, log: widget.log);
  }
}

class ReactivePropsWidget extends CompositionWidget {
  const ReactivePropsWidget({
    required this.label,
    required this.log,
    super.key,
  });

  final String label;
  final List<String> log;

  static int setupCount = 0;

  @override
  Widget Function(BuildContext) setup() {
    setupCount++;
    final props = widget();
    final labelRef = computed<String>(() => props.value.label);

    return (context) {
      final current = labelRef.value;
      log.add(current);
      return Text('label:$current', key: const ValueKey('label'));
    };
  }
}

class ProvideAndInjectWidget extends CompositionWidget {
  const ProvideAndInjectWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final counter = ref(0);
    provide(counterKey, counter);

    final injected = inject(counterKey);
    final optional = inject(optionalStringKey, defaultValue: null);

    return (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('provided:${injected.value}', key: const ValueKey('providedText')),
        Text(
          'optional:${optional == null ? 'none' : optional.value}',
          key: const ValueKey('optionalText'),
        ),
        ElevatedButton(
          key: const ValueKey('increment-counter'),
          onPressed: () => injected.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class MissingDependencyWidget extends CompositionWidget {
  const MissingDependencyWidget({required this.errors, super.key});

  final List<Object> errors;

  @override
  Widget Function(BuildContext) setup() {
    try {
      inject(missingKey);
      // Testing error handling - we want to catch any exception type
      // ignore: avoid_catches_without_on_clauses
    } catch (err) {
      errors.add(err);
    }
    return (context) => const SizedBox();
  }
}

class LifecycleWatcherWidget extends CompositionWidget {
  const LifecycleWatcherWidget({required this.events, super.key});

  final List<String> events;

  @override
  Widget Function(BuildContext) setup() {
    final counter = ref(0);

    watch<int>(
      () => counter.value,
      (newValue, oldValue) =>
          events.add('watch:${oldValue ?? 'null'}->$newValue'),
      immediate: true,
    );

    watchEffect(() {
      events.add('effect:${counter.value}');
    });

    onMounted(() => events.add('mounted'));
    onUnmounted(() => events.add('unmounted'));

    return (context) => ElevatedButton(
      key: const ValueKey('increment'),
      onPressed: () => counter.value++,
      child: const Text('Increment'),
    );
  }
}

class TypeInferenceProviderWidget extends CompositionWidget {
  const TypeInferenceProviderWidget({required this.log, super.key});

  final List<String> log;

  @override
  Widget Function(BuildContext) setup() {
    final value = ref(42);

    // Type should be inferred with InjectionKey
    provide(autoInferKey, value);

    final injected = inject(autoInferKey);
    log.add('success');

    return (context) => Text('value:${injected.value}');
  }
}
