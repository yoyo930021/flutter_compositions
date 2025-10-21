import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

/// Demonstrates ComputedBuilder for fine-grained reactivity and performance.
class ComputedBuilderDemo extends CompositionWidget {
  const ComputedBuilderDemo({super.key});

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Scaffold(
          appBar: AppBar(title: const Text('ComputedBuilder Demo')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              _PerformanceComparisonSection(),
              SizedBox(height: 16),
              _HighFrequencyUpdatesSection(),
              SizedBox(height: 16),
              _IndependentCountersSection(),
            ],
          ),
        );
  }
}

/// Compares performance with and without ComputedBuilder
class _PerformanceComparisonSection extends CompositionWidget {
  const _PerformanceComparisonSection();

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    var rebuilds = 0;

    return (context) {
      rebuilds++;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Comparison',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Parent rebuilds: $rebuilds times',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Without ComputedBuilder:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Count: ${count.value}'),
                        const SizedBox(height: 8),
                        const Text('⚠️ Entire card rebuilds'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'With ComputedBuilder:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        ComputedBuilder(
                          builder: () => Text('Count: ${count.value}'),
                        ),
                        const SizedBox(height: 8),
                        const Text('✅ Only text rebuilds'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => count.value++,
                    child: const Text('Increment'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => count.value = 0,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    };
  }
}

/// Demonstrates high-frequency updates (60 FPS)
class _HighFrequencyUpdatesSection extends CompositionWidget {
  const _HighFrequencyUpdatesSection();

  @override
  Widget Function(BuildContext) setup() {
    final progress = ref(0.0);
    final isAnimating = ref(false);
    Timer? timer;

    void startAnimation() {
      if (isAnimating.value) return;

      isAnimating.value = true;
      progress.value = 0.0;

      timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        progress.value += 0.01;
        if (progress.value >= 1.0) {
          timer?.cancel();
          isAnimating.value = false;
          progress.value = 0.0;
        }
      });
    }

    onUnmounted(() {
      timer?.cancel();
    });

    return (context) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'High-Frequency Updates',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Updates 60 times per second',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ComputedBuilder(
                  builder: () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(value: progress.value),
                      const SizedBox(height: 8),
                      Text('${(progress.value * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⬆️ Only the progress indicator rebuilds',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  '⬇️ This text never rebuilds',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: startAnimation,
                  child: ComputedBuilder(
                    builder: () => Text(
                      isAnimating.value ? 'Animating...' : 'Start Animation',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

/// Demonstrates independent counters
class _IndependentCountersSection extends CompositionWidget {
  const _IndependentCountersSection();

  @override
  Widget Function(BuildContext) setup() {
    final counters = List.generate(5, (i) => ref(0));

    return (context) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Independent Counters',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Each counter rebuilds independently',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...counters.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text('Counter ${entry.key + 1}:'),
                            ),
                            ComputedBuilder(
                              builder: () => SizedBox(
                                width: 50,
                                child: Text(
                                  '${entry.value.value}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              iconSize: 20,
                              onPressed: () => entry.value.value--,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              iconSize: 20,
                              onPressed: () => entry.value.value++,
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                ComputedBuilder(
                  builder: () {
                    final total = counters.fold<int>(
                      0,
                      (sum, counter) => sum + counter.value,
                    );
                    return Text(
                      'Total: $total',
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                  },
                ),
              ],
            ),
          ),
        );
  }
}
