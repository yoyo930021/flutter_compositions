import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

/// Demonstrates bridging ValueNotifier with the reactive primitives.
class ValueNotifierDemo extends CompositionWidget {
  const ValueNotifierDemo({super.key});

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Scaffold(
      appBar: AppBar(title: const Text('ValueNotifier Integration')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _LocalNotifierSection(),
          SizedBox(height: 16),
          _ExternalNotifierSection(),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Shows how to manage a ValueNotifier that is created inside setup().
class _LocalNotifierSection extends CompositionWidget {
  const _LocalNotifierSection();

  @override
  Widget Function(BuildContext) setup() {
    final notifier = ValueNotifier(0);
    final (_, counterRef) = manageValueListenable(notifier);

    // Create writable computed to allow modifications
    final counter = writableComputed(
      get: () => counterRef.value,
      set: (value) => notifier.value = value,
    );

    final parity = computed(() => counter.value.isEven ? 'even' : 'odd');

    // Dispose notifier on unmount
    onUnmounted(() => notifier.dispose());

    watch(() => counter.value, (value, previous) {
      debugPrint('local counter changed: $previous → $value');
    });

    return (context) => _SectionCard(
      title: 'Local ValueNotifier',
      description:
          'manageValueListenable keeps the ValueNotifier in sync and we dispose it when the composition unmounts.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Count: ${counter.value} (${parity.value})',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              FilledButton(
                onPressed: () => counter.value--,
                child: const Icon(Icons.remove),
              ),
              OutlinedButton(
                onPressed: () => counter.value = 0,
                child: const Text('Reset'),
              ),
              FilledButton(
                onPressed: () => counter.value++,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Demonstrates bridging an external ValueNotifier (e.g. from a service).
class _ExternalThemeService {
  static final theme = ValueNotifier('light');
}

class _ExternalNotifierSection extends CompositionWidget {
  const _ExternalNotifierSection();

  @override
  Widget Function(BuildContext) setup() {
    final themeNotifier = _ExternalThemeService.theme;
    final (_, themeRef) = manageValueListenable(themeNotifier);

    // Create writable computed for external notifier
    final theme = writableComputed(
      get: () => themeRef.value,
      set: (value) => themeNotifier.value = value,
    );

    final bannerText = computed(
      () => theme.value == 'light' ? 'Sunlight mode' : 'Starlight mode',
    );

    return (context) => _SectionCard(
      title: 'External ValueNotifier',
      description:
          'Pass an existing notifier without disposal so other parts of the app can share it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current theme: ${theme.value}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(bannerText.value),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'light', label: Text('Light')),
              ButtonSegment(value: 'dark', label: Text('Dark')),
            ],
            selected: {theme.value},
            onSelectionChanged: (selection) {
              theme.value = selection.first;
            },
          ),
        ],
      ),
    );
  }
}
