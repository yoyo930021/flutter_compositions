import 'dart:io';

import 'package:flutter_compositions_lints/src/lints/controller_lifecycle.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('ControllerLifecycle', () {
    final rule = const ControllerLifecycle();

    test('detects controllers without disposal', () async {
      final fixturePath = getFixturePath('controller_lifecycle_test.dart');
      final file = File(fixturePath);

      expect(file.existsSync(), isTrue,
          reason: 'Fixture file should exist at $fixturePath');

      // Use testAnalyzeAndRun to run the lint rule
      final errors = await rule.testAnalyzeAndRun(file);

      // Should detect 3 violations:
      // 1. ScrollControllerNoDisposal
      // 2. TextEditingControllerNoDisposal
      // 3. PageControllerNoDisposal
      // Note: FocusNode is not in _controllerTypes list
      expect(
        errors.length,
        3,
        reason: 'Should detect 3 controller lifecycle violations',
      );

      // Verify error code
      for (final error in errors) {
        expect(error.errorCode.name, rule.code.name);
        expect(error.errorCode.problemMessage, contains('disposed'));
      }
    });

    test('rule has correct metadata', () {
      expect(rule.code.name, 'flutter_compositions_controller_lifecycle');
      expect(rule.code.problemMessage, contains('disposed'));
      expect(rule.code.correctionMessage, contains('useScrollController'));
    });
  });
}
