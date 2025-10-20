# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-14

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
