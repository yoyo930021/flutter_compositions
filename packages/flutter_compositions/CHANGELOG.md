# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-11-06

### Features
- Add `useContext` composable to access `BuildContext` directly.
- Add `InheritedWidget` composables.

### Fixes
- Ensure `InheritedWidget` based composables update correctly when dependencies change.
- Correctly configure test runner to exclude fixture files.

### Documentation
- Refactor and improve clarity of documentation and internal links.
- Add a comprehensive testing guide.
- Enhance README with more detailed examples and documentation sections.

## [0.1.0] - 2025-10-27

### Added

- Initial release of Flutter Compositions
- Core reactivity system powered by `alien_signals`
- `CompositionWidget` base class for creating reactive widgets
- Reactive primitives: `ref`, `computed`, `writableComputed`, `untracked`
- Side effect APIs: `watch`, `watchEffect`
- Lifecycle hooks: `onMounted`, `onUnmounted`, `onBuild`
- Dependency injection: `provide`, `inject`, `InjectionKey`
- Reactive props access via `widget()`
- **Hot reload support**: `setup()` re-executes during hot reload to pick up code changes
- **Automatic hot reload state preservation**: `ref()` values are automatically preserved during hot reload based on their position in `setup()` - no manual configuration needed, similar to flutter_hooks
- Built-in composables:
  - Controllers: `useScrollController`, `useTextEditingController`, `usePageController`, `useFocusNode`
  - Animations: `useAnimationController`, `useSingleTickerProvider`, `manageAnimation`
  - Async: `useFuture`, `useAsyncData`, `useStream`, `useStreamController`, `useAsyncValue`
  - Framework: `useContext`, `useAppLifecycleState`, `useSearchController`
  - Listenable: `manageListenable`, `manageValueListenable`, `manageChangeNotifier`
- AsyncValue sealed class for type-safe async state handling with pattern matching
- Custom ref: `customRef`, `ReadonlyCustomRef`
- `ComputedBuilder` widget for using computed values in StatelessWidget
- `CompositionBuilder` for functional composition API
- Comprehensive documentation and examples
- Complete test coverage for all core features

### Documentation

- Complete API documentation
- Beginner guide: Reactivity Fundamentals
- Migration guide: From StatefulWidget
- Technical deep dive for experienced engineers
- Comparison with Provider, Riverpod, BLoC, and flutter_hooks
- VitePress documentation site with i18n support

### Development

- Monorepo structure with Melos
- Custom lint rules package
- Comprehensive test coverage
- GitHub Actions CI/CD
