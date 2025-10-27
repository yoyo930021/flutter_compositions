# Best Practices

These recommendations capture what has worked well while building production apps with Flutter Compositions.

> Prefer a pragmatic mindset: the framework stays lightweight on purpose, so most “rules” are conventions that keep teams aligned.

## Organize Composables by Feature

- Group composables inside `lib/features/<feature>/composables`.
- Keep the public API small—export only what other features should touch.
- Co-locate tests with the composables they cover.

## Prefer Domain Models over Raw Maps

Expose rich domain objects through `Ref`s rather than loose `Map<String, dynamic>`. This reduces field-name typos and makes refactoring easier.

```dart
class SessionState {
  final user = ref<User?>(null);
  final isAuthenticated = ref(false);
}
```

## Keep `setup()` Lean

- Declare refs, computed values, watchers, and lifecycle hooks.
- Push complex logic into composables or plain Dart services.
- Avoid deep widget trees—return another widget that contains the actual layout.

```dart
@override
Widget Function(BuildContext) setup() {
  final (state, refresh) = useAsyncData(loadDashboard);
  return (ctx) => DashboardScaffold(status: state.value, onRefresh: refresh);
}
```

## Watch for Side Effects Explicitly

Use `watch` or `watchEffect` to model side effects (analytics, logging, navigation). This keeps them declarative and automatically cleaned up on dispose.

```dart
watch(() => session.isAuthenticated.value, (isAuthed, _) {
  if (!isAuthed) navigator.showLogin();
});
```

## Keep Dependency Injection Type-Safe

- Always declare an `InjectionKey<T>` even if there is only one instance today.
- Provide dependencies at the highest level that makes sense and inject them where needed.
- For optional dependencies, supply a default directly in `inject(key, defaultValue: ...)`.

```dart
const analyticsKey = InjectionKey<AnalyticsService>('analytics');
provide(analyticsKey, AnalyticsService());
final analytics = inject(analyticsKey);
```

## Model Async Work with `AsyncValue`

- Wrap every async operation in an `AsyncValue<T>` so the UI can express loading, error, and data states without branching logic scattered through the tree.
- Keep the async operation near the UI that consumes it unless multiple widgets truly share the result.

## Compose Small Widgets

When a widget grows past ~150 lines, split it into smaller `CompositionWidget`s or regular Flutter widgets. Composition encourages reuse—lean into it.

## Keep Lints Running

- Install `flutter_compositions_lints` alongside `custom_lint`.
- Enable the plugin in `analysis_options.yaml`.
- Run `dart run custom_lint --watch` during development and `--fix` before commits.
- See the [Lint guide](../lints/README.md) for rule descriptions and IDE integration tips.

## Testing Checklist

- Wrap widgets under test with a `CompositionBuilder` to run `setup()`.
- Provide fake services via `InjectionKey`s before pumping the widget.
- Use `tester.pumpAndSettle()` or manual `pump` calls to flush async work.
- Verify side effects (like logging) by injecting spies instead of relying on global singletons.

## Recommended Reading

- [Dependency Injection](./dependency-injection.md)
- [Async Operations](./async-operations.md)
- [Reactivity Fundamentals](./reactivity-fundamentals.md)
- [Testing Guide](../testing/testing-guide.md)
