import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Manual hot reload simulation - check controller identity', (
    WidgetTester tester,
  ) async {
    TextEditingController? controller1;
    TextEditingController? controller2;

    // First build
    await tester.pumpWidget(
      MaterialApp(
        home: TestWidget(
          onControllerCreated: (c) => controller1 = c,
        ),
      ),
    );

    // Type text
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();

    print('=== Before reassemble ===');
    print('Controller 1: $controller1');
    print('Controller 1 text: "${controller1?.text}"');
    print('Controller 1 hashCode: ${controller1.hashCode}');

    // Get element and call reassemble (simulates hot reload)
    final element = tester.element(find.byType(TestWidget));
    element.reassemble();
    await tester.pump();

    // Get controller after reassemble
    final textField = tester.widget<TextField>(find.byType(TextField));
    controller2 = textField.controller;

    print('=== After reassemble ===');
    print('Controller 2: $controller2');
    print('Controller 2 text: "${controller2?.text}"');
    print('Controller 2 hashCode: ${controller2.hashCode}');
    print('Same instance? ${identical(controller1, controller2)}');
    print('controller1 still has text? "${controller1?.text}"');
  });

  testWidgets('Check ref preservation directly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RefCheckWidget()));

    // Check initial values
    expect(find.text('counter: 0'), findsOneWidget);
    expect(find.text('text: '), findsOneWidget);

    // Modify both
    await tester.tap(find.text('Increment'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Test');
    await tester.pump();

    print('=== Before reassemble ===');
    expect(find.text('counter: 1'), findsOneWidget);
    expect(find.text('text: Test'), findsOneWidget);

    // Reassemble
    final element = tester.element(find.byType(RefCheckWidget));
    element.reassemble();
    await tester.pump();

    print('=== After reassemble ===');

    // Check what's preserved
    final hasCounter = find.text('counter: 1').evaluate().isNotEmpty;
    final hasText = find.text('text: Test').evaluate().isNotEmpty;

    print('Counter preserved: $hasCounter');
    print('Text preserved: $hasText');

    if (!hasCounter) {
      print(
        'Counter value: ${find.textContaining('counter:').evaluate().first.widget}',
      );
    }
    if (!hasText) {
      print(
        'Text value: ${find.textContaining('text:').evaluate().first.widget}',
      );
    }
  });
}

class TestWidget extends CompositionWidget {
  const TestWidget({super.key, required this.onControllerCreated});

  final void Function(TextEditingController) onControllerCreated;

  @override
  Widget Function(BuildContext) setup() {
    print('>>> setup() called');
    final (controllerRef, text, _) = useTextEditingController();
    print('>>> Controller in setup: ${controllerRef.value}');
    print('>>> Controller text in setup: "${controllerRef.value.text}"');

    onControllerCreated(controllerRef);

    return (context) {
      print('>>> Builder called, text.value: "${text.value}"');
      return Scaffold(
        body: Column(
          children: [
            TextField(controller: controllerRef),
            Text('Display: ${text.value}'),
          ],
        ),
      );
    };
  }
}

class RefCheckWidget extends CompositionWidget {
  const RefCheckWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    print('>>> RefCheckWidget setup() called');

    final counter = ref(0);
    print('>>> counter ref created: ${counter.value}');

    final (controllerRef, text, _) = useTextEditingController();
    print('>>> controller created: ${controllerRef.value}');
    print('>>> controller text: "${controllerRef.value.text}"');

    return (context) => Scaffold(
      body: Column(
        children: [
          Text('counter: ${counter.value}'),
          ElevatedButton(
            onPressed: () => counter.value++,
            child: const Text('Increment'),
          ),
          TextField(controller: controllerRef),
          Text('text: ${text.value}'),
        ],
      ),
    );
  }
}
