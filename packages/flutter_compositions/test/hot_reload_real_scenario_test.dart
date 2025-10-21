import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hot Reload Real Scenario', () {
    testWidgets('TextEditingController instance should be NEW after reassemble', (
      WidgetTester tester,
    ) async {
      TextEditingController? firstController;

      // Build initial widget
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TestTextFieldWithCallback(
                onControllerCreated: (controller) {
                  firstController = controller;
                },
              );
            },
          ),
        ),
      );

      expect(firstController, isNotNull);
      print('First controller: $firstController');

      // Type some text
      await tester.enterText(find.byType(TextField), 'Hello World');
      await tester.pump();
      expect(find.text('Text: Hello World'), findsOneWidget);
      print('First controller text: "${firstController?.text}"');

      // Simulate hot reload
      TextEditingController? secondController;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TestTextFieldWithCallback(
                onControllerCreated: (controller) {
                  secondController = controller;
                },
              );
            },
          ),
        ),
      );

      final element = tester.element(find.byType(TestTextFieldWithCallback));
      final state = element.findAncestorStateOfType<State>();
      // ignore: invalid_use_of_protected_member
      state?.reassemble();
      await tester.pump();

      print('Second controller: $secondController');
      print('Second controller text: "${secondController?.text}"');
      print(
        'Are they the same instance? ${identical(firstController, secondController)}',
      );
      print('First controller after reload: "${firstController?.text}"');
    });

    testWidgets('Direct ref preservation test', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DirectRefTest()));

      // Increment counter
      await tester.tap(find.text('Increment'));
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      // Type in text field
      await tester.enterText(find.byType(TextField), 'Test Text');
      await tester.pump();
      expect(find.text('Text: Test Text'), findsOneWidget);

      // Simulate hot reload
      final element = tester.element(find.byType(DirectRefTest));
      final state = element.findAncestorStateOfType<State>();
      // ignore: invalid_use_of_protected_member
      state?.reassemble();
      await tester.pump();

      // Check what's preserved
      print('After reassemble:');
      print(
        '  Counter: ${find.text('Count: 1').evaluate().isEmpty ? "NOT preserved" : "preserved"}',
      );
      print(
        '  Text: ${find.text('Text: Test Text').evaluate().isEmpty ? "NOT preserved" : "preserved"}',
      );

      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        final controller = tester.widget<TextField>(textField).controller;
        print('  Controller text: "${controller?.text}"');
      }
    });
  });
}

class TestTextFieldWithCallback extends CompositionWidget {
  const TestTextFieldWithCallback({
    super.key,
    required this.onControllerCreated,
  });

  final void Function(TextEditingController) onControllerCreated;

  @override
  Widget Function(BuildContext) setup() {
    final (controllerRef, text, _) = useTextEditingController();

    // Report the controller instance
    onControllerCreated(controllerRef);

    return (context) => Scaffold(
      body: Column(
        children: [
          TextField(controller: controllerRef),
          Text('Text: ${text.value}'),
        ],
      ),
    );
  }
}

class DirectRefTest extends CompositionWidget {
  const DirectRefTest({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    final (controllerRef, text, _) = useTextEditingController();

    return (context) => Scaffold(
      body: Column(
        children: [
          Text('Count: ${count.value}'),
          ElevatedButton(
            onPressed: () => count.value++,
            child: const Text('Increment'),
          ),
          TextField(controller: controllerRef),
          Text('Text: ${text.value}'),
        ],
      ),
    );
  }
}
