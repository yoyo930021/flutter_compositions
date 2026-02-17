# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

## [0.2.2] - 2026-02-17

### Changed

- **BREAKING**: Upgrade `alien_signals` from 1.x to 2.x
  - Signal write: `.call(value, true)` → `.set(value)`
  - Effect/EffectScope disposal: `.dispose()` → `.call()` (callable syntax)
  - `getActiveSub`/`setActiveSub` now imported from `package:alien_signals/preset.dart`
- Upgrade `melos` to ^7.4.0
- Upgrade `very_good_analysis` to ^10.2.0
- Fix lint issues from `very_good_analysis` 10.2.0 in example app

## [0.2.1] - 2026-02-15

### Changed

- Upgrade Flutter SDK to 3.41.1 (Dart 3.11.0)
- Replace deprecated `TickerMode.getNotifier` with `TickerMode.getValuesNotifier`
- Add lints package to Dart workspace for unified dependency resolution

### Fixed

- Fix `comment_references` warning in `useContext` documentation

## [0.2.0] - 2026-02-15

### Changed

- **BREAKING PERF**: Complete StatelessWidget migration for all composition widgets
  - Migrated `ComputedBuilder`, `CompositionWidget`, and `CompositionBuilder` from `StatefulWidget` to `StatelessWidget` with custom `Element` implementations
  - **Architecture Change**: Removed `SetupContextMixin` - functionality now directly integrated into custom Elements
  - **Memory Savings**:
    - `ComputedBuilder`: ~56 bytes per instance (~15% reduction)
    - `CompositionWidget`: ~48 bytes per instance (~20% reduction)
    - `CompositionBuilder`: ~48 bytes per instance (~20% reduction)
  - **Performance Improvements**:
    - `ComputedBuilder`: 15-25% lower update latency for simple widgets
    - `CompositionWidget`/`CompositionBuilder`: 5-10% faster reactive updates
  - **Technical Benefits**:
    - Eliminates `scheduleMicrotask` overhead (~200-500 CPU cycles per update)
    - Eliminates `setState` closure creation overhead (~30 CPU cycles)
    - Direct `markNeedsBuild()` calls for more predictable batching
    - Uses `ComponentElement` lifecycle methods (`update`, `didChangeDependencies`, `reassemble`, `unmount`)
    - Reduced object creation overhead (2 objects instead of 3 per widget)
  - **API Compatibility**: Fully backward compatible - no changes required to existing code
  - **Lifecycle Handling**:
    - Props updates: `update(newWidget)` replaces `didUpdateWidget`
    - InheritedWidget dependencies: `didChangeDependencies()` remains available
    - Hot reload: `reassemble()` with state preservation support
    - Cleanup: `unmount()` replaces `dispose()`
  - **Provide/Inject**: Uses duck typing to find parent `SetupContext` across both old and new architectures
  - Inspired by [solidart PR #143](https://github.com/nank1ro/solidart/pull/143) and [flutter_hooks](https://github.com/rrousselGit/flutter_hooks)
- Upgrade Dart SDK constraint to `^3.10.0`
- Add `useController` generic helper and improve core composables
- Use `.raw` for controllers in builder widget parameters

### Fixed

- Correct `ComputedBuilder` mount timing and first build

## [0.1.1] - 2025-11-06

 - **FIX**: ensure InheritedWidget composables update correctly.
 - **FIX**: add example package to workspace configuration.
 - **FEAT**: add examples for InheritedWidget composables and their usage.
 - **FEAT**: useContext and add tests for context behavior.
 - **FEAT**: init project.
 - **DOCS**: update feature list formatting in README.md.
 - **DOCS**: enhance README with detailed documentation sections and examples.

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
