# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

## [0.2.0] - 2026-02-15

## [0.2.0] - 2026-02-15

### Changed

- **BREAKING**: Replaced `flutter_compositions_no_mutable_fields` rule with `flutter_compositions_shallow_reactivity`
  - The new rule warns about shallow reactivity limitations instead of enforcing final fields
  - Detects direct mutations that won't trigger reactive updates:
    - Property assignments: `ref.value['key'] = x` or `ref.value.property = x`
    - Array element assignments: `ref.value[0] = x`
    - Mutating method calls: `ref.value.add()`, `.remove()`, `.clear()`, etc.
  - Updated all documentation (English and Chinese) to reflect the new rule
  - Updated example code and fixtures
- **BREAKING**: Migrate from `custom_lint` to `analysis_server_plugin`
  - New entry point: `lib/main.dart` with `analysis_server_plugin` format
  - Rules now extend `AnalysisRule` instead of `DartLintRule`
  - Tests migrated to `AnalysisRuleTest` with `@reflectiveTest`
  - Removed fixture files and old test utilities
- Upgrade Dart SDK constraint to `^3.10.0`

### Removed

- `flutter_compositions_no_mutable_fields` lint rule and all associated tests

### Added

- `flutter_compositions_shallow_reactivity` lint rule with comprehensive test coverage
- New test fixtures demonstrating shallow reactivity patterns
- Detailed documentation explaining common mutation patterns to avoid
- `flutter_compositions_no_logic_in_builder` lint rule — prevents logic in builder functions
- `flutter_compositions_prefer_raw_controller` lint rule — suggests `.raw` over `.value` for controllers in builders

## [0.1.1] - 2025-11-06

 - **REFACTOR**: remove type safety lint rule and related tests.
 - **FIX**: configure dart test to exclude fixture files from test runs.
 - **FEAT**: init project.

## [0.1.0] - 2025-10-27

### Added

- Initial release of Flutter Compositions Lints
- Custom lint rules for enforcing Flutter Compositions best practices:
  - `flutter_compositions_ensure_reactive_props` - Ensures props are accessed via `widget()` for reactivity
  - `flutter_compositions_no_async_setup` - Prevents async setup methods
  - `flutter_compositions_controller_lifecycle` - Ensures proper controller disposal with `use*` helpers
  - `flutter_compositions_no_mutable_fields` - Enforces immutable widget fields
  - `flutter_compositions_provide_inject_type_match` - Warns against common type conflicts in DI
  - `flutter_compositions_no_conditional_composition` - Prevents conditional composition API calls
- Comprehensive test coverage using `testAnalyzeAndRun()`
- Fixture files for each lint rule
- Integration tests
- Documentation for all rules

### Documentation

- Complete rules documentation in RULES.md
- Testing guide in test/README.md
- Example code for good and bad practices

### Development

- Automated testing with `custom_lint_builder`
- All tests passing (18/18)
- GitHub Actions CI integration
