import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hot Reload State Preservation', () {
    testWidgets('should preserve ref values after reassemble',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: TestCounter()));

      // Verify initial state
      expect(find.text('Count: 0'), findsOneWidget);

      // Increment the counter
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      // Increment again
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Count: 2'), findsOneWidget);

      // Simulate hot reload by calling reassemble
      final element = tester.element(find.byType(TestCounter));
      final state = element.findAncestorStateOfType<State>();
      // ignore: invalid_use_of_protected_member
      state?.reassemble();
      await tester.pump();

      // Verify state is preserved after hot reload
      expect(find.text('Count: 2'), findsOneWidget);
    });

    testWidgets('should preserve multiple ref values in correct positions',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestMultipleRefs()));

      // Verify initial state
      expect(find.text('Count: 0'), findsOneWidget);
      expect(find.text('Name: Alice'), findsOneWidget);

      // Update both refs
      await tester.tap(find.text('Increment'));
      await tester.pump();
      await tester.tap(find.text('Change Name'));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.text('Name: Bob'), findsOneWidget);

      // Simulate hot reload
      final element = tester.element(find.byType(TestMultipleRefs));
      final state = element.findAncestorStateOfType<State>();
      // ignore: invalid_use_of_protected_member
      state?.reassemble();
      await tester.pump();

      // Verify both states are preserved
      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.text('Name: Bob'), findsOneWidget);
    });

    testWidgets('should handle hot reload with computed values',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestWithComputed()));

      // Verify initial state
      expect(find.text('Count: 0'), findsOneWidget);
      expect(find.text('Doubled: 0'), findsOneWidget);

      // Increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Count: 5'), findsOneWidget);
      expect(find.text('Doubled: 10'), findsOneWidget);

      // Simulate hot reload
      final element = tester.element(find.byType(TestWithComputed));
      final state = element.findAncestorStateOfType<State>();
      // ignore: invalid_use_of_protected_member
      state?.reassemble();
      await tester.pump();

      // Verify state is preserved and computed still works
      expect(find.text('Count: 5'), findsOneWidget);
      expect(find.text('Doubled: 10'), findsOneWidget);

      // Verify reactivity still works after hot reload
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Count: 10'), findsOneWidget);
      expect(find.text('Doubled: 20'), findsOneWidget);
    });
  });
}

class TestCounter extends CompositionWidget {
  const TestCounter({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    return (context) => Scaffold(
          body: Column(
            children: [
              Text('Count: ${count.value}'),
              ElevatedButton(
                onPressed: () => count.value++,
                child: const Text('Increment'),
              ),
            ],
          ),
        );
  }
}

class TestMultipleRefs extends CompositionWidget {
  const TestMultipleRefs({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    final name = ref('Alice');

    return (context) => Scaffold(
          body: Column(
            children: [
              Text('Count: ${count.value}'),
              Text('Name: ${name.value}'),
              ElevatedButton(
                onPressed: () => count.value++,
                child: const Text('Increment'),
              ),
              ElevatedButton(
                onPressed: () => name.value = 'Bob',
                child: const Text('Change Name'),
              ),
            ],
          ),
        );
  }
}

class TestWithComputed extends CompositionWidget {
  const TestWithComputed({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    final doubled = computed(() => count.value * 2);

    return (context) => Scaffold(
          body: Column(
            children: [
              Text('Count: ${count.value}'),
              Text('Doubled: ${doubled.value}'),
              ElevatedButton(
                onPressed: () => count.value += 5,
                child: const Text('Add 5'),
              ),
            ],
          ),
        );
  }
}
