# Flutter Compositions Lints - Testing Guide

## Testing Approach

This package uses **`custom_lint_builder`'s `testAnalyzeAndRun()` method** for automated testing of lint rules. This approach allows for fast, programmatic testing without needing to run the full custom_lint process.

## Test Structure

```
test/
├── fixtures/           # Test fixture files with code examples
│   ├── controller_lifecycle_test.dart
│   ├── ensure_reactive_props_test.dart
│   ├── no_async_setup_test.dart
│   ├── no_mutable_fields_test.dart
│   ├── no_conditional_composition_test.dart
│   └── provide_inject_type_match_test.dart
├── lints/             # Unit tests using testAnalyzeAndRun()
│   ├── controller_lifecycle_test.dart
│   ├── ensure_reactive_props_test.dart
│   ├── no_async_setup_test.dart
│   ├── no_mutable_fields_test.dart
│   ├── no_conditional_composition_test.dart
│   └── provide_inject_type_match_test.dart
└── integration_test.dart  # Basic fixture file existence tests
```

## Running Tests

```bash
# Run all tests (recommended)
dart test

# Run only lint rule tests
dart test test/lints/

# Run specific lint test
dart test test/lints/no_mutable_fields_test.dart

# Run integration tests
dart test test/integration_test.dart
```

## Writing Tests

### 1. Create Fixture File

Fixture files contain code examples that should trigger lint rules:

```dart
// test/fixtures/my_rule_test.dart

// Mock types needed for testing
class CompositionWidget extends StatefulWidget {
  Widget Function(BuildContext) setup() => throw UnimplementedError();
}

// Test cases with expect_lint comments (for documentation)
class BadExample extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // expect_lint: flutter_compositions_my_rule
    final problematicCode = ...;

    return (context) => Widget();
  }
}

class GoodExample extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // This should NOT trigger lint
    final correctCode = ...;

    return (context) => Widget();
  }
}
```

### 2. Create Unit Test

Unit tests use `testAnalyzeAndRun()` to programmatically analyze fixture files:

```dart
// test/lints/my_rule_test.dart
import 'dart:io';
import 'package:flutter_compositions_lints/src/lints/my_rule.dart';
import 'package:test/test.dart';

void main() {
  group('MyRule', () {
    final rule = const MyRule();

    test('detects violations', () async {
      final fixturePath =
          '${Directory.current.path}/test/fixtures/my_rule_test.dart';
      final file = File(fixturePath);

      expect(file.existsSync(), isTrue,
          reason: 'Fixture file should exist');

      // Use testAnalyzeAndRun to run the lint rule
      final errors = await rule.testAnalyzeAndRun(file);

      // Verify expected number of errors
      expect(
        errors.length,
        expectedCount,
        reason: 'Should detect violations',
      );

      // Verify error code and message
      for (final error in errors) {
        expect(error.errorCode.name, rule.code.name);
        expect(error.errorCode.problemMessage, contains('expected text'));
      }
    });

    test('rule has correct metadata', () {
      expect(rule.code.name, 'flutter_compositions_my_rule');
      expect(rule.code.problemMessage, contains('description'));
      expect(rule.code.correctionMessage, contains('suggestion'));
    });
  });
}
```

## Testing Method: testAnalyzeAndRun()

The `testAnalyzeAndRun()` method is provided by `custom_lint_builder` (added in v0.6.0) and offers:

1. **Programmatic Testing**: Run lint rules directly on Dart files
2. **Fast Execution**: No need to run full custom_lint process
3. **Automated CI**: Tests can run in CI/CD pipelines
4. **Detailed Results**: Returns list of `AnalysisError` objects with:
   - Error offset (position in file)
   - Error message
   - Error code
   - Severity level

### Example Usage

```dart
final errors = await rule.testAnalyzeAndRun(file);

// Debug output
for (final error in errors) {
  print('Error at offset ${error.offset}: ${error.message}');
}

// Expected output:
// Error at offset 1119: Flutter controllers must be disposed...
// Error at offset 1543: Flutter controllers must be disposed...
```

## Fixture Files with expect_lint Comments

Fixture files use `// expect_lint: rule_name` comments to **document** expected violations:

```dart
/// Should trigger lint: ScrollController without disposal
class ScrollControllerNoDisposal extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // expect_lint: flutter_compositions_controller_lifecycle
    final controller = ScrollController();

    return (context) => ListView(controller: controller);
  }
}
```

**Note**: These `expect_lint` comments are for **documentation only** when using `testAnalyzeAndRun()`. They help:
1. Document which lines should trigger lints
2. Serve as reference when writing unit tests
3. Enable manual verification with `dart run custom_lint` (if needed)

## Manual Verification (Optional)

You can also manually verify lint rules using custom_lint:

```bash
# From the monorepo root (requires pubspec.yaml)
dart run custom_lint

# Check specific fixture files
dart run custom_lint test/fixtures/
```

This will scan all Dart files and report lint violations.

## Test Coverage

| Rule | Fixture File | Unit Test | Status |
|------|--------------|-----------|--------|
| ensure_reactive_props | ✅ | ✅ | Passing |
| no_async_setup | ✅ | ✅ | Passing |
| controller_lifecycle | ✅ | ✅ | Passing |
| no_mutable_fields | ✅ | ✅ | Passing |
| provide_inject_type_match | ✅ | ✅ | Passing |
| no_conditional_composition | ✅ | ✅ | Passing |

All tests pass ✅ (12/12 tests)

## Troubleshooting

### Tests Take Long Time

The first run of `testAnalyzeAndRun()` can be slow (5-10 seconds per test) as it initializes the analyzer. Subsequent tests in the same run are faster.

**Solution**: This is normal behavior. Run all tests together (`dart test test/lints/`) for better performance.

### Errors Not Detected

If your unit test expects certain errors but they're not detected:

1. **Check Rule Implementation**: Verify the lint rule logic is correct
2. **Verify Fixture Syntax**: Ensure the fixture file has valid Dart code
3. **Debug with Print Statements**:
   ```dart
   print('Found ${errors.length} errors:');
   for (final error in errors) {
     print('  Error at ${error.offset}: ${error.message}');
   }
   ```
4. **Check Rule Type List**: Some rules only detect specific types (e.g., `controller_lifecycle` only checks certain controller types)

### Fixture File Not Found

**Error**: `Fixture file should exist at /path/to/file`

**Solution**: Ensure fixture paths use `Directory.current.path`:

```dart
final fixturePath = '${Directory.current.path}/test/fixtures/my_rule_test.dart';
```

### Test Expects Wrong Count

If the actual error count doesn't match your expectations:

1. **Print Actual Errors**: Add debug output to see what's detected
2. **Check Rule Logic**: The rule might not detect all cases you expect
3. **Update Test Expectations**: Adjust expected count based on actual behavior

## Example Test Output

When running tests with debug output:

```
00:00 +0: NoMutableFields detects non-final fields in CompositionWidget
Found 4 errors:
  Error at offset 1119: Fields in CompositionWidget must be final...
  Error at offset 1543: Fields in CompositionWidget must be final...
  Error at offset 1938: Fields in CompositionWidget must be final...
  Error at offset 3210: Fields in CompositionWidget must be final...
00:08 +1: NoMutableFields rule has correct metadata
00:08 +2: All tests passed!
```

## Migration from Old Test Approach

Previous tests used `AnalysisContextCollection` to directly analyze files, which **doesn't work** for custom_lint plugins. The new approach uses `testAnalyzeAndRun()` which properly integrates with the custom_lint framework.

**Old approach (incorrect)**:
```dart
// ❌ Doesn't work for custom_lint rules
final result = await context.currentSession.getResolvedUnit(path);
expect(result.errors.isEmpty, isFalse);
```

**New approach (correct)**:
```dart
// ✅ Works with custom_lint rules
final errors = await rule.testAnalyzeAndRun(file);
expect(errors.length, greaterThan(0));
```

## References

- [custom_lint Documentation](https://pub.dev/packages/custom_lint)
- [custom_lint_builder API](https://pub.dev/documentation/custom_lint_builder/latest/)
- [Testing Lints Guide](https://pub.dev/packages/custom_lint#testing-lints)
- [testAnalyzeAndRun() method](https://pub.dev/documentation/custom_lint_builder/latest/custom_lint_builder/DartLintRule/testAnalyzeAndRun.html)
