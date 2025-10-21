/// This file showcases common prop mistakes and recommended fixes.
import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

class PropsBestPracticesPage extends StatelessWidget {
  const PropsBestPracticesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Props Best Practices')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionHeader('Anti-pattern: direct field access'),
          SizedBox(height: 8),
          WrongUserProfile(userId: 'user-1', name: 'Alice'),
          SizedBox(height: 24),
          _SectionHeader('Pattern: use widget() for reactive props'),
          SizedBox(height: 8),
          CorrectUserProfile1(userId: 'user-1', name: 'Alice'),
          SizedBox(height: 24),
          _SectionHeader('Pattern: computed selectors'),
          SizedBox(height: 8),
          CorrectUserProfile2(userId: 'user-1', name: 'Alice'),
          SizedBox(height: 24),
          _SectionHeader('Anti-pattern: mixing reactive and static reads'),
          SizedBox(height: 8),
          MixedUsage(userId: 'user-1', name: 'Alice'),
          SizedBox(height: 24),
          _SectionHeader('Pattern: initial seed value'),
          SizedBox(height: 8),
          InitialValueUsage(initialCount: 3),
          SizedBox(height: 24),
          _SectionHeader('Pattern: reactive + initial value'),
          SizedBox(height: 8),
          MixedCorrectUsage(userId: 'user-1', initialCount: 5),
          SizedBox(height: 24),
          _SectionHeader('Key takeaways'),
          SizedBox(height: 8),
          Text('• Call widget() for any prop that can change.'),
          Text('• Use computed selectors for derived fields.'),
          Text('• Prefix one-time parameters with `initial`.'),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  // ignore: unused_element_parameter
  const _SectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }
}

// ============================================================
// ❌ Anti-pattern 1: reading widget fields directly inside setup()
// ============================================================
class WrongUserProfile extends CompositionWidget {
  const WrongUserProfile({super.key, required this.userId, required this.name});

  final String userId;
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    // setup() runs once, so these values never update.
    final displayText = computed(() => 'User: $name ($userId)');

    return (context) => Text(displayText.value);
  }
}

// ============================================================
// ✅ Pattern 1: use widget() for reactive props
// ============================================================
class CorrectUserProfile1 extends CompositionWidget {
  const CorrectUserProfile1({
    super.key,
    required this.userId,
    required this.name,
  });

  final String userId;
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();

    final displayText = computed(
      () => 'User: ${props.value.name} (${props.value.userId})',
    );

    return (context) => Text(displayText.value);
  }
}

// ============================================================
// ✅ Pattern 2: derive single fields with computed selectors
// ============================================================
class CorrectUserProfile2 extends CompositionWidget {
  const CorrectUserProfile2({
    super.key,
    required this.userId,
    required this.name,
  });

  final String userId;
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();

    final userId = computed(() => props.value.userId);
    final name = computed(() => props.value.name);

    final displayText = computed(() => 'User: ${name.value} (${userId.value})');

    watch(
      () => userId.value,
      (newId, oldId) => debugPrint('User ID changed: $oldId -> $newId'),
    );

    return (context) => Text(displayText.value);
  }
}

// ============================================================
// ❌ Anti-pattern 2: mixing reactive and non-reactive access
// ============================================================
class MixedUsage extends CompositionWidget {
  const MixedUsage({super.key, required this.userId, required this.name});

  final String userId;
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    final userId = computed(() => props.value.userId);

    final text1 = computed(() => 'ID: ${userId.value}');
    final text2 = computed(() => 'Name: $name'); // never updates!

    return (context) =>
        Column(children: [Text(text1.value), Text(text2.value)]);
  }
}

// ============================================================
// ✅ Pattern 3: props used only as initial values
// ============================================================
class InitialValueUsage extends CompositionWidget {
  const InitialValueUsage({super.key, required this.initialCount});

  final int initialCount;

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(initialCount);
    final doubled = computed(() => count.value * 2);

    return (context) => Column(
      children: [
        Text('Count: ${count.value}'),
        Text('Doubled: ${doubled.value}'),
        ElevatedButton(
          onPressed: () => count.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

// ============================================================
// ✅ Pattern 4: mixing reactive props and initial values
// ============================================================
class MixedCorrectUsage extends CompositionWidget {
  const MixedCorrectUsage({
    super.key,
    required this.userId,
    required this.initialCount,
  });

  final String userId; // needs to stay reactive
  final int initialCount; // used only for initialization

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();

    final userId = computed(() => props.value.userId);
    final count = ref(props.value.initialCount);

    final displayText = computed(() => 'User ${userId.value}: ${count.value}');

    return (context) => Column(
      children: [
        Text(displayText.value),
        ElevatedButton(
          onPressed: () => count.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
