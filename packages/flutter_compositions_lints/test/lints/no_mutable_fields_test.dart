import 'dart:io';

import 'package:flutter_compositions_lints/src/lints/no_mutable_fields.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('NoMutableFields', () {
    final rule = const NoMutableFields();

    test('detects non-final fields in CompositionWidget', () async {
      final fixturePath = getFixturePath('no_mutable_fields_test.dart');
      final file = File(fixturePath);

      expect(
        file.existsSync(),
        isTrue,
        reason: 'Fixture file should exist at $fixturePath',
      );

      // Use testAnalyzeAndRun to run the lint rule
      final errors = await rule.testAnalyzeAndRun(file);

      // Should detect 4 violations:
      // 1. MutableField.count (line 33)
      // 2. MultipleMutableFields.name (line 47)
      // 3. MultipleMutableFields.age (line 49)
      // 4. NullableMutableField.optionalName (line 107)
      expect(
        errors.length,
        4,
        reason: 'Should detect 4 mutable field violations',
      );

      // Verify error code
      for (final error in errors) {
        expect(error.errorCode.name, rule.code.name);
        expect(error.errorCode.problemMessage, contains('final'));
      }
    });

    test('rule has correct metadata', () {
      expect(rule.code.name, 'flutter_compositions_no_mutable_fields');
      expect(rule.code.problemMessage, contains('final'));
      expect(rule.code.correctionMessage, contains('ref()'));
    });
  });
}
