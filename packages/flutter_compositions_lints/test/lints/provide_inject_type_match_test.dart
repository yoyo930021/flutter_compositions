import 'dart:io';

import 'package:flutter_compositions_lints/src/lints/provide_inject_type_match.dart';
import 'package:test/test.dart';

void main() {
  group('ProvideInjectTypeMatch', () {
    final rule = const ProvideInjectTypeMatch();

    test('detects common types in provide/inject', () async {
      final fixturePath =
          '${Directory.current.path}/test/fixtures/provide_inject_type_match_test.dart';
      final file = File(fixturePath);

      expect(file.existsSync(), isTrue,
          reason: 'Fixture file should exist at $fixturePath');

      // Use testAnalyzeAndRun to run the lint rule
      final errors = await rule.testAnalyzeAndRun(file);

      // Should detect 5 violations (actual based on rule implementation)
      expect(
        errors.length,
        5,
        reason: 'Should detect 5 common type violations',
      );

      // Verify error code
      for (final error in errors) {
        expect(error.errorCode.name, rule.code.name);
        expect(error.errorCode.problemMessage, contains('common types'));
      }
    });

    test('rule has correct metadata', () {
      expect(rule.code.name, 'flutter_compositions_provide_inject_type_match');
      expect(rule.code.problemMessage, contains('common types'));
      expect(rule.code.correctionMessage, contains('custom data classes'));
    });
  });
}
