import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompositionBuilder', () {
    testWidgets('basic reactive state works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompositionBuilder(
              setup: () {
                final count = ref(0);

                return (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Count: ${count.value}'),
                        ElevatedButton(
                          key: const Key('increment'),
                          onPressed: () => count.value++,
                          child: const Text('Increment'),
                        ),
                      ],
                    );
              },
            ),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('increment')));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('setup runs only once', (tester) async {
      var setupCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompositionBuilder(
              setup: () {
                setupCount++;
                final count = ref(0);

                return (context) => ElevatedButton(
                      onPressed: () => count.value++,
                      child: Text('Count: ${count.value}'),
                    );
              },
            ),
          ),
        ),
      );

      expect(setupCount, 1);

      // Trigger rebuild
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Setup should still have run only once
      expect(setupCount, 1);
    });

    testWidgets('computed values work', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompositionBuilder(
              setup: () {
                final count = ref(5);
                final doubled = computed(() => count.value * 2);

                return (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Doubled: ${doubled.value}'),
                        ElevatedButton(
                          key: const Key('increment'),
                          onPressed: () => count.value++,
                          child: const Text('Increment'),
                        ),
                      ],
                    );
              },
            ),
          ),
        ),
      );

      expect(find.text('Doubled: 10'), findsOneWidget);

      await tester.tap(find.byKey(const Key('increment')));
      await tester.pump();

      expect(find.text('Doubled: 12'), findsOneWidget);
    });

    testWidgets('watch and watchEffect work', (tester) async {
      final watchLog = <String>[];
      final effectLog = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompositionBuilder(
              setup: () {
                final count = ref(0);

                watch(() => count.value, (newValue, oldValue) {
                  watchLog.add('watch: $oldValue -> $newValue');
                });

                watchEffect(() {
                  effectLog.add('effect: ${count.value}');
                });

                return (context) => ElevatedButton(
                      key: const Key('increment'),
                      onPressed: () => count.value++,
                      child: Text('Count: ${count.value}'),
                    );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(effectLog, ['effect: 0']);
      expect(watchLog, isEmpty);

      await tester.tap(find.byKey(const Key('increment')));
      await tester.pumpAndSettle();

      expect(effectLog, ['effect: 0', 'effect: 1']);
      expect(watchLog, ['watch: 0 -> 1']);
    });

    testWidgets('onMounted and onUnmounted work', (tester) async {
      final events = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompositionBuilder(
              setup: () {
                onMounted(() {
                  events.add('mounted');
                });

                onUnmounted(() {
                  events.add('unmounted');
                });

                return (context) => const Text('Hello');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(events, ['mounted']);

      // Remove the widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      expect(events, ['mounted', 'unmounted']);
    });

    testWidgets('can be used inline without defining a class', (tester) async {
      // This test demonstrates the main use case: using it inline
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                // Use CompositionBuilder inline without defining a class
                return CompositionBuilder(
                  setup: () {
                    final expanded = ref(false);

                    return (context) => Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text('Item $index'),
                                trailing: IconButton(
                                  key: Key('toggle-$index'),
                                  icon: Icon(
                                    expanded.value
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                  onPressed: () =>
                                      expanded.value = !expanded.value,
                                ),
                              ),
                              if (expanded.value)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('Details for item $index'),
                                ),
                            ],
                          ),
                        );
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Details for item 0'), findsNothing);

      await tester.tap(find.byKey(const Key('toggle-0')));
      await tester.pump();

      expect(find.text('Details for item 0'), findsOneWidget);
      expect(find.text('Details for item 1'), findsNothing);
    });

    testWidgets('effects are cleaned up on dispose', (tester) async {
      final count = ref(0);
      var effectRunCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompositionBuilder(
              setup: () {
                watchEffect(() {
                  effectRunCount++;
                  // Read the signal to subscribe
                  count.value;
                });

                return (context) => Text('Count: ${count.value}');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(effectRunCount, 1);

      // Trigger effect
      count.value++;
      await tester.pumpAndSettle();

      expect(effectRunCount, 2);

      // Remove the widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      // Trigger signal again - effect should NOT run
      count.value++;
      await tester.pumpAndSettle();

      expect(effectRunCount, 2); // Should still be 2
    });

    testWidgets('multiple CompositionBuilders are independent', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CompositionBuilder(
                  setup: () {
                    final count = ref(0);
                    return (context) => ElevatedButton(
                          key: const Key('button1'),
                          onPressed: () => count.value++,
                          child: Text('Count1: ${count.value}'),
                        );
                  },
                ),
                CompositionBuilder(
                  setup: () {
                    final count = ref(10);
                    return (context) => ElevatedButton(
                          key: const Key('button2'),
                          onPressed: () => count.value++,
                          child: Text('Count2: ${count.value}'),
                        );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Count1: 0'), findsOneWidget);
      expect(find.text('Count2: 10'), findsOneWidget);

      await tester.tap(find.byKey(const Key('button1')));
      await tester.pump();

      expect(find.text('Count1: 1'), findsOneWidget);
      expect(find.text('Count2: 10'), findsOneWidget);

      await tester.tap(find.byKey(const Key('button2')));
      await tester.pump();

      expect(find.text('Count1: 1'), findsOneWidget);
      expect(find.text('Count2: 11'), findsOneWidget);
    });
  });
}
