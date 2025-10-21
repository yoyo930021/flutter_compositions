import 'dart:io';

import 'package:flutter_compositions_lints/src/lints/no_conditional_composition.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('NoConditionalComposition', () {
    final rule = const NoConditionalComposition();

    test('detects composition APIs in conditionals', () async {
      final fixturePath =
          getFixturePath('no_conditional_composition_test.dart');
      final file = File(fixturePath);

      expect(file.existsSync(), isTrue,
          reason: 'Fixture file should exist at $fixturePath');

      // Use testAnalyzeAndRun to run the lint rule
      final errors = await rule.testAnalyzeAndRun(file);

      // Should detect violations (actual number depends on implementation)
      expect(
        errors.length,
        greaterThan(0),
        reason: 'Should detect conditional composition API violations',
      );

      // Print errors for debugging
      print('Found ${errors.length} errors:');
      for (final error in errors) {
        print('  Error at offset ${error.offset}: ${error.message}');
      }

      // Verify error code
      for (final error in errors) {
        expect(error.errorCode.name, rule.code.name);
      }
    });

    test('rule has correct metadata', () {
      expect(rule.code.name, 'flutter_compositions_no_conditional_composition');
      expect(rule.code.problemMessage, contains('conditionals or loops'));
      expect(rule.code.correctionMessage, contains('top level of setup()'));
    });
  });
}
