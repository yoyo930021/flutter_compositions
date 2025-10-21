import 'dart:io';

import 'package:flutter_compositions_lints/src/lints/ensure_reactive_props.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('EnsureReactiveProps', () {
    final rule = const EnsureReactiveProps();

    test('detects direct property access in setup', () async {
      final fixturePath = getFixturePath('ensure_reactive_props_test.dart');
      final file = File(fixturePath);

      expect(
        file.existsSync(),
        isTrue,
        reason: 'Fixture file should exist at $fixturePath',
      );

      // Use testAnalyzeAndRun to run the lint rule
      final errors = await rule.testAnalyzeAndRun(file);

      // Should detect at least 1 violation
      expect(
        errors.length,
        greaterThan(0),
        reason: 'Should detect direct property access violations',
      );

      // Print errors for debugging
      print('Found ${errors.length} errors:');
      for (final error in errors) {
        print('  Error at offset ${error.offset}: ${error.message}');
      }

      // Verify error code
      for (final error in errors) {
        expect(error.errorCode.name, rule.code.name);
        expect(error.errorCode.problemMessage, contains('widget()'));
      }
    });

    test('rule has correct metadata', () {
      expect(rule.code.name, 'flutter_compositions_ensure_reactive_props');
      expect(rule.code.problemMessage, contains('widget()'));
      expect(rule.code.correctionMessage, contains('reactive reference'));
    });
  });
}
