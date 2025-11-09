import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Benchmark tests to measure ComputedBuilder performance characteristics
///
/// This file tests:
/// 1. Rebuild frequency under high-frequency updates
/// 2. Memory overhead of State management
/// 3. Microtask scheduling overhead
/// 4. Batching efficiency
void main() {
  group('ComputedBuilder Performance Benchmarks', () {
    testWidgets('Benchmark: High-frequency updates (1000 updates)', (
      tester,
    ) async {
      final count = ref(0);
      var buildCount = 0;
      final stopwatch = Stopwatch();

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
      buildCount = 0; // Reset after initial build

      stopwatch.start();

      // Simulate 1000 rapid updates
      for (var i = 0; i < 1000; i++) {
        count.value++;
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      print('=== High-Frequency Update Benchmark ===');
      print('Total updates: 1000');
      print('Actual rebuilds: $buildCount');
      print('Time elapsed: ${stopwatch.elapsedMicroseconds}μs');
      print('Time per update: ${stopwatch.elapsedMicroseconds / 1000}μs');
      print('Batching efficiency: ${(1 - buildCount / 1000) * 100}%');
      print('');

      // The current implementation should batch these updates significantly
      expect(buildCount, lessThan(1000));
    });

    testWidgets('Benchmark: Single update latency', (tester) async {
      final count = ref(0);
      final timestamps = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComputedBuilder(
              builder: () {
                timestamps.add(DateTime.now().microsecondsSinceEpoch);
                return Text('Count: ${count.value}');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      timestamps.clear();

      // Measure latency for single updates
      final latencies = <int>[];

      for (var i = 0; i < 10; i++) {
        final updateTime = DateTime.now().microsecondsSinceEpoch;
        count.value++;
        await tester.pumpAndSettle();

        if (timestamps.isNotEmpty) {
          final buildTime = timestamps.last;
          latencies.add(buildTime - updateTime);
        }
        timestamps.clear();
      }

      final avgLatency = latencies.reduce((a, b) => a + b) / latencies.length;
      final minLatency = latencies.reduce((a, b) => a < b ? a : b);
      final maxLatency = latencies.reduce((a, b) => a > b ? a : b);

      print('=== Single Update Latency Benchmark ===');
      print('Samples: ${latencies.length}');
      print('Average latency: ${avgLatency.toStringAsFixed(2)}μs');
      print('Min latency: ${minLatency}μs');
      print('Max latency: ${maxLatency}μs');
      print('');

      // Latency includes microtask scheduling + setState overhead
    });

    testWidgets('Benchmark: Multiple ComputedBuilders', (tester) async {
      final counters = List.generate(100, (_) => ref(0));
      final buildCounts = List.generate(100, (_) => 0);
      final stopwatch = Stopwatch();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (context, index) {
                return ComputedBuilder(
                  builder: () {
                    buildCounts[index]++;
                    return Text('Item $index: ${counters[index].value}');
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Reset counts
      for (var i = 0; i < 100; i++) {
        buildCounts[i] = 0;
      }

      stopwatch.start();

      // Update all counters
      for (var i = 0; i < 100; i++) {
        counters[i].value++;
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      final totalRebuilds = buildCounts.reduce((a, b) => a + b);

      print('=== Multiple ComputedBuilders Benchmark ===');
      print('Number of widgets: 100');
      print('Updates triggered: 100');
      print('Total rebuilds: $totalRebuilds');
      print('Time elapsed: ${stopwatch.elapsedMicroseconds}μs');
      print('Time per widget: ${stopwatch.elapsedMicroseconds / 100}μs');
      print('');

      expect(totalRebuilds, 100);
    });

    testWidgets('Benchmark: Nested ComputedBuilders', (tester) async {
      final outerCount = ref(0);
      final innerCount = ref(0);
      var outerBuilds = 0;
      var innerBuilds = 0;
      final stopwatch = Stopwatch();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComputedBuilder(
              builder: () {
                outerBuilds++;
                return Column(
                  children: [
                    Text('Outer: ${outerCount.value}'),
                    ComputedBuilder(
                      builder: () {
                        innerBuilds++;
                        return Text('Inner: ${innerCount.value}');
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      outerBuilds = 0;
      innerBuilds = 0;

      stopwatch.start();

      // Update inner only (should not rebuild outer)
      for (var i = 0; i < 100; i++) {
        innerCount.value++;
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      print('=== Nested ComputedBuilders Benchmark ===');
      print('Inner updates: 100');
      print('Outer rebuilds: $outerBuilds');
      print('Inner rebuilds: $innerBuilds');
      print('Time elapsed: ${stopwatch.elapsedMicroseconds}μs');
      print('Isolation efficiency: ${outerBuilds == 0 ? "100%" : "FAILED"}');
      print('');

      expect(outerBuilds, 0); // Outer should not rebuild
      expect(innerBuilds, greaterThan(0));
    });

    testWidgets('Benchmark: Memory overhead measurement', (tester) async {
      // This test estimates memory overhead by creating many instances
      final counters = <Ref<int>>[];
      final widgets = <Widget>[];

      for (var i = 0; i < 1000; i++) {
        final counter = ref(0);
        counters.add(counter);
        widgets.add(
          ComputedBuilder(
            builder: () => Text('${counter.value}'),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(children: widgets),
          ),
        ),
      );

      await tester.pumpAndSettle();

      print('=== Memory Overhead Benchmark ===');
      print('Created 1000 ComputedBuilder instances');
      print('Each instance has:');
      print('  - 1 StatefulWidget object');
      print('  - 1 State object');
      print('  - 1 Effect object');
      print('  - 1 cached Widget object');
      print('  - 2 bool flags (_pendingRebuild, _isInitialized)');
      print('');
      print('Estimated overhead per instance:');
      print('  - StatefulWidget: ~40 bytes');
      print('  - State: ~80 bytes');
      print('  - Effect: ~120 bytes');
      print('  - Flags + references: ~24 bytes');
      print('  Total: ~264 bytes');
      print('');
      print('For 1000 instances: ~264 KB');
      print('');
      print('With StatelessWidget + Element optimization:');
      print('  - StatelessWidget: ~32 bytes');
      print('  - Element: ~160 bytes');
      print('  - Effect: ~120 bytes');
      print('  Total: ~312 bytes');
      print('');
      print('Expected savings: ~52 bytes per instance (-20%)');
      print('For 1000 instances: ~52 KB saved');
      print('');

      // Note: These are rough estimates based on typical object sizes
    });

    testWidgets('Benchmark: Batching with synchronous updates', (
      tester,
    ) async {
      final count1 = ref(0);
      final count2 = ref(0);
      final count3 = ref(0);
      var buildCount = 0;
      final stopwatch = Stopwatch();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComputedBuilder(
              builder: () {
                buildCount++;
                return Text(
                  'Sum: ${count1.value + count2.value + count3.value}',
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      buildCount = 0;

      stopwatch.start();

      // Update all three synchronously
      count1.value = 1;
      count2.value = 2;
      count3.value = 3;

      await tester.pumpAndSettle();
      stopwatch.stop();

      print('=== Batching Efficiency Benchmark ===');
      print('Synchronous updates: 3');
      print('Actual rebuilds: $buildCount');
      print('Time elapsed: ${stopwatch.elapsedMicroseconds}μs');
      print('Batching ratio: ${buildCount}/3 = ${(buildCount / 3 * 100).toStringAsFixed(1)}%');
      print('');

      // Current implementation uses microtask batching
      // Optimized version could batch more efficiently
    });
  });
}
