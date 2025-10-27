# Contributing to Flutter Compositions

Thank you for your interest in contributing to Flutter Compositions! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful and constructive in all interactions. We're all here to learn and build great software together.

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK 3.9.0 or higher
- Git

### Setting Up Development Environment

1. **Fork and clone the repository**

```bash
git clone https://github.com/yourusername/flutter_compositions.git
cd flutter_compositions
```

2. **Install Melos**

```bash
flutter pub global activate melos
```

3. **Bootstrap the workspace**

```bash
melos bootstrap
```

4. **Verify setup**

```bash
melos run analyze
melos run test
```

## Development Workflow

### Running Tests

```bash
# Run all tests
melos run test

# Test specific package
cd packages/flutter_compositions
flutter test

# Test with coverage
flutter test --coverage
```

### Running Analysis

```bash
# Analyze all packages
melos run analyze

# Run custom lints
dart run custom_lint

# Watch mode
dart run custom_lint --watch
```

### Running the Example App

```bash
cd packages/flutter_compositions/example
flutter run
```

## Making Changes

### Branch Naming

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test improvements

Example: `feature/add-use-memo` or `fix/watch-memory-leak`

### Commit Messages

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat(composables): add useMemo for expensive computations

- Implement useMemo hook for memoizing expensive calculations
- Add comprehensive tests
- Update documentation

Closes #123
```

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `dart format` for formatting
- Run `dart analyze` to check for issues
- All public APIs must have documentation comments

### Testing Requirements

- All new features must include tests
- Bug fixes should include regression tests
- Aim for high test coverage (>80%)
- Tests should be deterministic and fast

### Documentation

- Update relevant documentation in `docs/`
- Add API documentation for public APIs
- Include examples in documentation
- Update CHANGELOG.md

## Pull Request Process

### Before Submitting

1. **Ensure all tests pass**
```bash
melos run test
```

2. **Run analysis**
```bash
melos run analyze
dart run custom_lint
```

3. **Format code**
```bash
dart format .
```

4. **Update documentation**
- Add/update API docs
- Update guides if needed
- Update CHANGELOG.md

### Pull Request Guidelines

1. **Title**: Use conventional commit format
2. **Description**:
   - Explain what changes were made and why
   - Reference related issues
   - Include screenshots for UI changes
3. **Checklist**:
   - [ ] Tests pass
   - [ ] Analysis passes
   - [ ] Documentation updated
   - [ ] CHANGELOG.md updated
   - [ ] No breaking changes (or clearly documented)

### Review Process

1. Maintainers will review your PR
2. Address review feedback
3. Once approved, a maintainer will merge

## Adding New Features

### New Composables

When adding a new composable:

1. **Implement** in `packages/flutter_compositions/lib/src/composables/`
2. **Export** in `packages/flutter_compositions/lib/src/composables.dart`
3. **Test** in `packages/flutter_compositions/test/composables/`
4. **Document** in `docs/api/composables/`
5. **Example** in example app if applicable

Example structure:
```dart
/// Brief description of what this composable does.
///
/// More detailed explanation with usage notes.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final value = useMyComposable();
///   return (context) => Text('${value.value}');
/// }
/// ```
Ref<T> useMyComposable<T>({
  required T initialValue,
}) {
  final value = ref(initialValue);

  onUnmounted(() {
    // Cleanup if needed
  });

  return value;
}
```

### New Lint Rules

When adding a new lint rule:

1. **Implement** in `packages/flutter_compositions_lints/lib/src/lints/`
2. **Register** in `packages/flutter_compositions_lints/lib/flutter_compositions_lints.dart`
3. **Test** in `packages/flutter_compositions_lints/test/lints/`
4. **Document** in `docs/lints/rules.md`
5. **Add fixture** in `packages/flutter_compositions_lints/test/fixtures/`

## Reporting Issues

### Bug Reports

Include:
- Flutter/Dart version
- Minimal reproduction code
- Expected vs actual behavior
- Stack traces if applicable

### Feature Requests

Include:
- Use case description
- Proposed API (if applicable)
- Examples of how it would be used
- Comparison with alternatives

## Project Structure

```
flutter_compositions/
├── packages/
│   ├── flutter_compositions/       # Core package
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── framework.dart  # CompositionWidget
│   │   │   │   ├── compositions.dart # ref, computed, watch
│   │   │   │   ├── composables/    # Built-in composables
│   │   │   │   └── ...
│   │   │   └── flutter_compositions.dart # Main export
│   │   ├── test/                   # Tests
│   │   └── example/                # Example app
│   └── flutter_compositions_lints/ # Lint rules package
├── docs/                           # Documentation
└── README.md
```

## Release Process

(Maintainers only)

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Create git tag: `git tag v1.0.0`
4. Push tag: `git push origin v1.0.0`
5. GitHub Actions will publish to pub.dev

## Questions?

- Open a [GitHub Discussion](https://github.com/yoyo930021/flutter_compositions/discussions)
- Check existing [issues](https://github.com/yoyo930021/flutter_compositions/issues)
- Read the [documentation](https://yoyo930021.github.io/flutter_compositions/)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Flutter Compositions! 🎉
