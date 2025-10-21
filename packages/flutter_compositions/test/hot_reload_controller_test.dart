import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hot Reload with Controllers', () {
    testWidgets(
      'useTextEditingController should preserve text after reassemble',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: TestTextField()));

        // Find the text field
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        // Type some text
        await tester.enterText(textField, 'Hello World');
        await tester.pump();

        // Verify text is shown
        expect(find.text('Text: Hello World'), findsOneWidget);

        // Simulate hot reload
        final element = tester.element(find.byType(TestTextField));
        final state = element.findAncestorStateOfType<State>();
        // ignore: invalid_use_of_protected_member
        state?.reassemble();
        await tester.pump();

        // Check if text is preserved
        final controller = tester.widget<TextField>(textField).controller;
        print('After hot reload, controller text: "${controller?.text}"');

        // Check if the reactive ref still has the value
        expect(
          find.text('Text: Hello World'),
          findsOneWidget,
          reason: 'Text should be preserved after hot reload',
        );
      },
    );

    testWidgets('multiple refs with useTextEditingController', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TestMultipleControllers()),
      );

      // Type in first field
      await tester.enterText(find.byKey(const Key('field1')), 'First');
      await tester.pump();

      // Type in second field
      await tester.enterText(find.byKey(const Key('field2')), 'Second');
      await tester.pump();

      expect(find.text('Field 1: First'), findsOneWidget);
      expect(find.text('Field 2: Second'), findsOneWidget);

      // Simulate hot reload
      final element = tester.element(find.byType(TestMultipleControllers));
      final state = element.findAncestorStateOfType<State>();
      // ignore: invalid_use_of_protected_member
      state?.reassemble();
      await tester.pump();

      // Check if both are preserved
      print('After hot reload:');
      final field1 = tester.widget<TextField>(find.byKey(const Key('field1')));
      final field2 = tester.widget<TextField>(find.byKey(const Key('field2')));
      print('  Field 1: ${field1.controller?.text}');
      print('  Field 2: ${field2.controller?.text}');
    });
  });
}

class TestTextField extends CompositionWidget {
  const TestTextField({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controllerRef, text, _) = useTextEditingController();

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

class TestMultipleControllers extends CompositionWidget {
  const TestMultipleControllers({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controllerRef1, text1, _) = useTextEditingController();
    final (controllerRef2, text2, _) = useTextEditingController();

    return (context) => Scaffold(
          body: Column(
            children: [
              TextField(key: const Key('field1'), controller: controllerRef1),
              Text('Field 1: ${text1.value}'),
              TextField(key: const Key('field2'), controller: controllerRef2),
              Text('Field 2: ${text2.value}'),
            ],
          ),
        );
  }
}
