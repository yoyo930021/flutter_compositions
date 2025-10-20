import 'dart:io';

import 'package:flutter_compositions_lints/src/lints/no_async_setup.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('NoAsyncSetup', () {
    final rule = const NoAsyncSetup();

    test('detects async setup methods', () async {
      final fixturePath = getFixturePath('no_async_setup_test.dart');
      final file = File(fixturePath);

      expect(file.existsSync(), isTrue,
          reason: 'Fixture file should exist at $fixturePath');

      // Use testAnalyzeAndRun to run the lint rule
      final errors = await rule.testAnalyzeAndRun(file);

      // Should detect 2 violations:
      // 1. AsyncSetupWithKeyword (line 34)
      // 2. AsyncSetupArrowFunction (line 46)
      expect(
        errors.length,
        2,
        reason: 'Should detect 2 async setup violations',
      );

      // Verify error code
      for (final error in errors) {
        expect(error.errorCode.name, rule.code.name);
        expect(error.errorCode.problemMessage, contains('async'));
      }
    });

    test('rule has correct metadata', () {
      expect(rule.code.name, 'flutter_compositions_no_async_setup');
      expect(rule.code.problemMessage, contains('async'));
      expect(rule.code.correctionMessage, contains('onMounted'));
    });
  });
}
