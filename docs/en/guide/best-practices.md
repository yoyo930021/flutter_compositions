# Best Practices

This guide distills patterns, performance tips, and team conventions that help real-world Flutter Compositions apps stay maintainable and testable.

## Table of Contents

1. [Composition Patterns](#composition-patterns)
2. [State Management](#state-management)
3. [Performance](#performance)
4. [Project Structure](#project-structure)
5. [Lint Workflow](#lint-workflow)
6. [Testing Strategy](#testing-strategy)
7. [Common Pitfalls](#common-pitfalls)
8. [Further Reading](#further-reading)

## Composition Patterns

### Extract Logic into Composables

Encapsulate reusable state and side effects in functions so multiple widgets do not repeat the same `setup()` code.

```dart
// ✅ Return only what callers need
(Ref<String>, Ref<bool>) useValidatedInput({
  String initialValue = '',
  int minLength = 6,
}) {
  final value = ref(initialValue);
  final isValid = computed(() => value.value.trim().length >= minLength);
  return (value, isValid);
}

class LoginForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (email, emailValid) = useValidatedInput(minLength: 5);
    final (password, passwordValid) = useValidatedInput(minLength: 8);
    final canSubmit = computed(() => emailValid.value && passwordValid.value);

    return (context) => ElevatedButton(
          onPressed: canSubmit.value ? () => submit(email.value) : null,
          child: const Text('Sign in'),
        );
  }
}
```

### Keep `setup()` Synchronous

`setup()` must return a builder synchronously. Move asynchronous work into lifecycle hooks.

```dart
@override
Widget Function(BuildContext) setup() {
  final profile = ref<User?>(null);
  final loading = ref(true);

  onMounted(() async {
    profile.value = await api.fetchProfile();
    loading.value = false;
  });

  return (context) => loading.value
      ? const CircularProgressIndicator()
      : Text(profile.value!.name);
}
```

### Model Domain State Explicitly

Prefer dedicated classes over raw `Map<String, dynamic>` so renames and refactors stay safe.

```dart
class SessionState {
  final user = ref<User?>(null);
  final isAuthenticated = ref(false);
}
```

### Handle Side Effects with Watchers

Keep navigation, analytics, and logging inside `watch`/`watchEffect` so cleanup happens automatically.

```dart
watch(() => session.isAuthenticated.value, (isAuthed, _) {
  if (!isAuthed) navigator.showLogin();
});
```

## State Management

### Scope State Deliberately

- **Local state** lives in a single widget—declare it with `ref`.
- **Shared state** spans a subtree—use `provide`/`inject`.
- **Global state** should be provided from the app shell or a top-level feature.

```dart
const sessionKey = InjectionKey<SessionState>('session');

class AppShell extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final session = SessionState();
    provide(sessionKey, session);
    return (context) => const HomePage();
  }
}

class ProfileMenu extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final session = inject(sessionKey);
    return (context) => Text(session.user.value?.name ?? 'Guest');
  }
}
```

### Keep Dependency Injection Type-Safe

- Always declare an `InjectionKey<T>` even if there is only one instance today.
- Provide dependencies at the highest sensible level and inject them where needed.
- Supply defaults via `inject(key, defaultValue: ...)` for optional services.

### Represent Async Work with `AsyncValue`

- Wrap async results in `AsyncValue<T>` so loading, error, and data states stay co-located with the UI.
- Expose refresh callbacks returned by `useAsyncData` when you need pull-to-refresh or retry flows.

## Performance

- **Cache expensive computations** with `computed` instead of recomputing inside builders.
- **Limit builder dependencies** to the refs that matter; move static UI into `const` widgets.
- **Avoid creating controllers in builders**—use `useScrollController`, `useAnimationController`, and friends inside `setup()`.
- **Break large widgets apart** once they grow beyond ~150 lines so only the changing subtree rebuilds.

```dart
@override
Widget Function(BuildContext) setup() {
  final todos = ref(<Todo>[]);
  final completed = computed(
    () => todos.value.where((todo) => todo.isDone).toList(growable: false),
  );

  return (context) => Column(
        children: [
          Text('Completed ${completed.value.length} items'),
          Expanded(child: TodoList(todos: todos.value)),
        ],
      );
}
```

## Project Structure

1. **Name composables descriptively**—`useDebouncedSearch()` communicates intent better than `useSearch()`.
2. **Group by feature**: `lib/features/<feature>/composables`, `services`, `widgets`, plus shared utilities.
3. **Expose a narrow public API** from each feature package and co-locate tests alongside implementations.

Example layout:

```
lib/
├── features/
│   └── checkout/
│       ├── composables/
│       │   ├── use_cart.dart
│       │   └── use_checkout_flow.dart
│       ├── services/
│       │   └── checkout_service.dart
│       └── widgets/
│           └── checkout_page.dart
└── shared/
    ├── services/
    └── widgets/
```

## Lint Workflow

- Add `custom_lint` and `flutter_compositions_lints` to `dev_dependencies`.
- Enable the plugin in `analysis_options.yaml`.
- Run `dart run custom_lint --watch` during development and `--fix` before committing.
- Consult the [Lint guide](../lints/index.md) for rule descriptions and IDE integration.

```yaml
dev_dependencies:
  custom_lint: ^0.7.0
  flutter_compositions_lints: ^0.1.0

analyzer:
  plugins:
    - custom_lint

custom_lint:
  enable_all_lint_rules: true
```

## Testing Strategy

### Test Composables Directly

Use `CompositionBuilder` or call the composable function and assert on the returned refs.

```dart
test('useCounter increments', () {
  final (count, increment) = useCounter(initialValue: 0);
  increment();
  expect(count.value, 1);
});
```

### Test Widgets with Injected Fakes

```dart
testWidgets('ProfilePage shows the user name', (tester) async {
  final mockSession = SessionState()..user.value = User(name: 'Alice');

  await tester.pumpWidget(
    CompositionBuilder(
      setup: () {
        provide(sessionKey, mockSession);
        return (context) => const MaterialApp(home: ProfilePage());
      },
    ),
  );

  await tester.pumpAndSettle();
  expect(find.text('Alice'), findsOneWidget);
});
```

- Inject spies or fakes via `provide` instead of mutating globals.
- Call `pump`/`pumpAndSettle` after triggering side effects so watchers can flush updates.

## Common Pitfalls

- Making `setup()` `async`—move await logic into `onMounted`.
- Accessing props via `this`/`widget` instead of `widget<T>()`, which breaks reactivity.
- Reordering or removing `ref` declarations and relying on hot reload; restart when layout changes dramatically.
- Forgetting to clean up external resources—use `onUnmounted` or the built-in `use*` helpers.

## Further Reading

- [Getting Started](./getting-started.md)
- [What Is a Composition?](./what-is-a-composition.md)
- [Reactivity Fundamentals](./reactivity-fundamentals.md)
- [Async Operations](./async-operations.md)
- [Dependency Injection](./dependency-injection.md)
- [Lint Guide](../lints/index.md)
- [Testing Guide](../testing/testing-guide.md)
