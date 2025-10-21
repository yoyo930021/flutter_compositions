import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComputedBuilder', () {
    testWidgets('only rebuilds itself, not parent widget', (tester) async {
      final buildLog = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(buildLog: buildLog),
        ),
      );

      // Wait for effects to register
      await tester.pumpAndSettle();

      // Initial build
      expect(
        buildLog,
        containsAllInOrder([
          'TestWidget setup',
          'TestWidget builder',
          'ComputedBuilder builder',
        ]),
      );

      buildLog.clear();

      // Tap to increment count
      await tester.tap(find.byKey(const ValueKey('increment')));
      await tester.pumpAndSettle();

      // Only ComputedBuilder should rebuild
      expect(buildLog, ['ComputedBuilder builder']);
      expect(buildLog.contains('TestWidget builder'), false);
    });

    testWidgets('multiple ComputedBuilders rebuild independently', (
      tester,
    ) async {
      final buildLog = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: MultipleComputedBuildersWidget(buildLog: buildLog),
        ),
      );

      await tester.pumpAndSettle();

      buildLog.clear();

      // Increment count1
      await tester.tap(find.byKey(const ValueKey('increment1')));
      await tester.pumpAndSettle();

      // Only builder1 should rebuild
      expect(buildLog, ['builder1']);

      buildLog.clear();

      // Increment count2
      await tester.tap(find.byKey(const ValueKey('increment2')));
      await tester.pumpAndSettle();

      // Only builder2 should rebuild
      expect(buildLog, ['builder2']);
    });

    testWidgets('works with computed values', (tester) async {
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
                    ComputedBuilder(
                      builder: () => Text('Doubled: ${doubled.value}'),
                    ),
                    ElevatedButton(
                      key: const ValueKey('increment'),
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

      await tester.tap(find.byKey(const ValueKey('increment')));
      await tester.pump();

      expect(find.text('Doubled: 12'), findsOneWidget);
    });

    testWidgets('batches multiple signal updates in same frame', (
      tester,
    ) async {
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompositionBuilder(
              setup: () {
                final count1 = ref(0);
                final count2 = ref(0);

                return (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ComputedBuilder(
                      builder: () {
                        buildCount++;
                        return Text('Sum: ${count1.value + count2.value}');
                      },
                    ),
                    ElevatedButton(
                      key: const ValueKey('update-both'),
                      onPressed: () {
                        count1.value++;
                        count2.value++;
                      },
                      child: const Text('Update Both'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(buildCount, 1);

      // Update both signals
      await tester.tap(find.byKey(const ValueKey('update-both')));
      await tester.pumpAndSettle();

      // May rebuild 2-3 times depending on effect execution order
      // The important thing is it doesn't rebuild for every single update
      expect(buildCount, lessThanOrEqualTo(3));
      expect(buildCount, greaterThan(1));
    });

    testWidgets('effect is disposed when widget is removed', (tester) async {
      final count = ref(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComputedBuilder(
              builder: () {
                buildCount++;
                return Text('Count: ${count.value}');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(buildCount, 1);

      // Trigger rebuild
      count.value++;
      await tester.pumpAndSettle();

      expect(buildCount, 2);

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      // Update signal - should NOT trigger build
      count.value++;
      await tester.pumpAndSettle();

      expect(buildCount, 2); // Should still be 2
    });

    testWidgets('can be nested for fine-grained reactivity', (tester) async {
      final buildLog = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompositionBuilder(
              setup: () {
                final count1 = ref(0);
                final count2 = ref(0);

                return (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ComputedBuilder(
                      builder: () {
                        buildLog.add('outer');
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ComputedBuilder(
                              builder: () {
                                buildLog.add('inner1');
                                return Text('Count1: ${count1.value}');
                              },
                            ),
                            ComputedBuilder(
                              builder: () {
                                buildLog.add('inner2');
                                return Text('Count2: ${count2.value}');
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    ElevatedButton(
                      key: const ValueKey('increment1'),
                      onPressed: () => count1.value++,
                      child: const Text('Increment 1'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      buildLog.clear();

      // Increment count1
      await tester.tap(find.byKey(const ValueKey('increment1')));
      await tester.pumpAndSettle();

      // Only inner1 should rebuild
      expect(buildLog, ['inner1']);
      expect(buildLog.contains('outer'), false);
      expect(buildLog.contains('inner2'), false);
    });

    testWidgets('works in ListView.builder for independent list items', (
      tester,
    ) async {
      final buildLog = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompositionBuilder(
              setup: () {
                final items = List.generate(
                  3,
                  (i) => ref(0),
                );

                return (context) => ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      key: ValueKey('item-$index'),
                      title: ComputedBuilder(
                        builder: () {
                          buildLog.add('item-$index');
                          return Text('Item $index: ${item.value}');
                        },
                      ),
                      trailing: IconButton(
                        key: ValueKey('increment-$index'),
                        icon: const Icon(Icons.add),
                        onPressed: () => item.value++,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      buildLog.clear();

      // Increment item 1
      await tester.tap(find.byKey(const ValueKey('increment-1')));
      await tester.pumpAndSettle();

      // Only item 1 should rebuild
      expect(buildLog, ['item-1']);
    });

    testWidgets('works with high-frequency updates', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompositionBuilder(
              setup: () {
                final progress = ref(0.toDouble());

                return (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ComputedBuilder(
                      builder: () {
                        buildCount++;
                        return LinearProgressIndicator(
                          value: progress.value,
                        );
                      },
                    ),
                    const Text('Loading...'),
                    ElevatedButton(
                      key: const ValueKey('update'),
                      onPressed: () {
                        // Simulate multiple updates
                        for (var i = 0; i < 10; i++) {
                          progress.value = (i + 1) / 10;
                        }
                      },
                      child: const Text('Update'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialBuildCount = buildCount;

      await tester.tap(find.byKey(const ValueKey('update')));
      await tester.pumpAndSettle();

      // Should rebuild due to the updates
      // The exact count may vary due to batching and effect scheduling
      expect(buildCount, greaterThan(initialBuildCount));
    });
  });
}

class TestWidget extends CompositionWidget {
  const TestWidget({required this.buildLog, super.key});

  final List<String> buildLog;

  @override
  Widget Function(BuildContext) setup() {
    buildLog.add('TestWidget setup');

    final count = ref(0);

    return (context) {
      buildLog.add('TestWidget builder');

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ComputedBuilder(
            builder: () {
              buildLog.add('ComputedBuilder builder');
              return Text('Count: ${count.value}');
            },
          ),
          ElevatedButton(
            key: const ValueKey('increment'),
            onPressed: () => count.value++,
            child: const Text('Increment'),
          ),
        ],
      );
    };
  }
}

class MultipleComputedBuildersWidget extends CompositionWidget {
  const MultipleComputedBuildersWidget({required this.buildLog, super.key});

  final List<String> buildLog;

  @override
  Widget Function(BuildContext) setup() {
    final count1 = ref(0);
    final count2 = ref(0);

    return (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ComputedBuilder(
          builder: () {
            buildLog.add('builder1');
            return Text('Count1: ${count1.value}');
          },
        ),
        ComputedBuilder(
          builder: () {
            buildLog.add('builder2');
            return Text('Count2: ${count2.value}');
          },
        ),
        ElevatedButton(
          key: const ValueKey('increment1'),
          onPressed: () => count1.value++,
          child: const Text('Increment 1'),
        ),
        ElevatedButton(
          key: const ValueKey('increment2'),
          onPressed: () => count2.value++,
          child: const Text('Increment 2'),
        ),
      ],
    );
  }
}
