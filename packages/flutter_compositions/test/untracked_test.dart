import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('untracked', () {
    test('prevents reactive dependency tracking', () {
      final count = ref(0);
      var computeCount = 0;

      final doubled = computed(() {
        computeCount++;
        return count.value * 2;
      });

      expect(doubled.value, 0);
      expect(computeCount, 1);

      // Change count - should trigger recompute
      count.value = 1;
      expect(doubled.value, 2);
      expect(computeCount, 2);
    });

    test('.raw reads do not establish dependencies', () {
      final count = ref(0);
      final multiplier = ref(2);
      var computeCount = 0;

      final result = computed(() {
        computeCount++;
        final c = count.value; // Tracked
        final m = multiplier.raw; // Not tracked
        return c * m;
      });

      expect(result.value, 0);
      expect(computeCount, 1);

      // Change count - should trigger recompute (tracked)
      count.value = 5;
      expect(result.value, 10);
      expect(computeCount, 2);

      // Change multiplier - should NOT trigger recompute (.raw)
      multiplier.value = 3;
      expect(result.value, 10); // Still old value (5 * 2)
      expect(computeCount, 2); // No recompute

      // Accessing result.value doesn't recompute either
      expect(result.value, 10);
      expect(computeCount, 2);

      // But changing count will pick up new multiplier value
      count.value = 4;
      expect(result.value, 12); // 4 * 3 (new multiplier)
      expect(computeCount, 3);
    });

    testWidgets(
      '.raw prevents widget rebuild when reading controller',
      (tester) async {
        var buildCount = 0;

        final widget = _RawControllerHarness(
          onBuild: () => buildCount++,
        );

        await tester.pumpWidget(MaterialApp(home: widget));

        expect(buildCount, 1, reason: 'Initial build');
        buildCount = 0;

        // Perform scroll - should NOT trigger rebuild
        await tester.drag(find.byType(ListView), const Offset(0, -100));
        await tester.pump();

        expect(buildCount, 0, reason: 'Should not rebuild with .raw read');
      },
    );

    testWidgets('tracked read DOES trigger widget rebuild', (tester) async {
      var buildCount = 0;

      final widget = _TrackedControllerHarness(
        onBuild: () => buildCount++,
      );

      await tester.pumpWidget(MaterialApp(home: widget));

      expect(buildCount, 1, reason: 'Initial build');
      buildCount = 0;

      // Perform scroll - SHOULD trigger rebuild
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pump();

      expect(
        buildCount,
        greaterThan(0),
        reason: 'Should rebuild with tracked read',
      );
    });

    testWidgets('.raw with reactive computed still works', (tester) async {
      var buildCount = 0;

      final widget = _MixedTrackingHarness(
        onBuild: () => buildCount++,
      );

      await tester.pumpWidget(MaterialApp(home: widget));

      expect(find.text('Count: 0'), findsOneWidget);
      expect(buildCount, 1);
      buildCount = 0;

      // Scroll - should NOT trigger rebuild (controller uses .raw)
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pump();
      expect(buildCount, 0, reason: 'Scroll should not rebuild');

      // Tap button - SHOULD trigger rebuild (count is tracked)
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
      expect(buildCount, greaterThan(0), reason: 'Count change should rebuild');
    });
  });
}

/// Widget that uses .raw to read controller
class _RawControllerHarness extends CompositionWidget {
  const _RawControllerHarness({required this.onBuild});
  final VoidCallback onBuild;

  @override
  Widget Function(BuildContext) setup() {
    final scrollController = useScrollController();

    return (context) {
      onBuild();
      return Scaffold(
        body: ListView.builder(
          // .raw read - won't establish dependency
          controller: scrollController.raw,
          itemCount: 50,
          itemBuilder: (context, index) => ListTile(
            title: Text('Item $index'),
          ),
        ),
      );
    };
  }
}

/// Widget that uses normal (tracked) read of controller
class _TrackedControllerHarness extends CompositionWidget {
  const _TrackedControllerHarness({required this.onBuild});
  final VoidCallback onBuild;

  @override
  Widget Function(BuildContext) setup() {
    final scrollController = useScrollController();

    return (context) {
      onBuild();
      return Scaffold(
        body: ListView.builder(
          // Normal read - WILL establish dependency
          controller: scrollController.value,
          itemCount: 50,
          itemBuilder: (context, index) => ListTile(
            title: Text('Item $index'),
          ),
        ),
      );
    };
  }
}

/// Widget that mixes tracked and .raw reads
class _MixedTrackingHarness extends CompositionWidget {
  const _MixedTrackingHarness({required this.onBuild});
  final VoidCallback onBuild;

  @override
  Widget Function(BuildContext) setup() {
    final scrollController = useScrollController();
    final count = ref(0);

    return (context) {
      onBuild();
      return Scaffold(
        body: Column(
          children: [
            // Tracked - will rebuild when count changes
            Text('Count: ${count.value}'),
            ElevatedButton(
              onPressed: () => count.value++,
              child: const Text('Increment'),
            ),
            Expanded(
              child: ListView.builder(
                // .raw - won't rebuild when scrolling
                controller: scrollController.raw,
                itemCount: 50,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Item $index'),
                ),
              ),
            ),
          ],
        ),
      );
    };
  }
}
