import 'dart:io';

import 'package:flutter_compositions_lints/src/lints/shallow_reactivity_warning.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('ShallowReactivityWarning', () {
    final rule = const ShallowReactivityWarning();

    test('detects direct mutations of ref.value', () async {
      final fixturePath = getFixturePath('shallow_reactivity_warning_test.dart');
      final file = File(fixturePath);

      expect(
        file.existsSync(),
        isTrue,
        reason: 'Fixture file should exist at $fixturePath',
      );

      // Use testAnalyzeAndRun to run the lint rule
      final errors = await rule.testAnalyzeAndRun(file);

      // Should detect multiple violations:
      // 1. Property assignment: user.value['name'] = 'Jane'
      // 2. Index assignment: items.value[0] = 10
      // 3. Nested property assignment: config.value.settings.theme = 'dark'
      // 4. List.add() method: items.value.add(4)
      // 5. List.remove() method: items.value.remove(1)
      // 6. Map.putIfAbsent() method: user.value.putIfAbsent('email', () => '')
      expect(
        errors.length,
        greaterThanOrEqualTo(6),
        reason: 'Should detect at least 6 shallow reactivity violations',
      );

      // Verify error code
      for (final error in errors) {
        expect(error.errorCode.name, rule.code.name);
        expect(
          error.errorCode.problemMessage,
          contains('won\'t trigger reactive updates'),
        );
      }
    });

    test('rule has correct metadata', () {
      expect(rule.code.name, 'flutter_compositions_shallow_reactivity');
      expect(
        rule.code.problemMessage,
        contains('won\'t trigger reactive updates'),
      );
      expect(rule.code.correctionMessage, contains('Reassign'));
    });
  });
}
