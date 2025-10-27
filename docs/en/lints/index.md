# Lint Rules Overview

Flutter Compositions provides custom lint rules to enforce best practices and prevent common mistakes. This guide provides a quick overview of all available rules and how to use them.

## Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  custom_lint: ^0.7.0
  flutter_compositions_lints: ^0.1.0
```

Create or update `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  enable_all_lint_rules: true
```

### Running Lints

```bash
# Analyze code
dart run custom_lint

# Watch for changes
dart run custom_lint --watch

# Auto-fix issues (where applicable)
dart run custom_lint --fix
```

## All Lint Rules

### Reactivity Rules

Rules that ensure proper reactive state management.

#### `flutter_compositions_ensure_reactive_props`

**Severity:** Warning

Ensures that widget properties are accessed through `widget()` in the `setup()` method to maintain reactivity.

```dart
// ❌ Bad - not reactive
@override
Widget Function(BuildContext) setup() {
  final greeting = 'Hello, $name!'; // Direct access
  return (context) => Text(greeting);
}

// ✅ Good - reactive
@override
Widget Function(BuildContext) setup() {
  final props = widget();
  final greeting = computed(() => 'Hello, ${props.value.name}!');
  return (context) => Text(greeting.value);
}
```

[See detailed documentation →](./rules.md#flutter_compositions_ensure_reactive_props)

---

### Lifecycle Rules

Rules that manage component lifecycle and resource cleanup.

#### `flutter_compositions_no_async_setup`

**Severity:** Error

Prevents `setup()` methods from being async. The setup function must synchronously return a builder function.

```dart
// ❌ Bad - async setup
@override
Future<Widget Function(BuildContext)> setup() async {
  final data = await fetchData();
  return (context) => Text(data);
}

// ✅ Good - use onMounted for async
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);
  onMounted(() async {
    data.value = await fetchData();
  });
  return (context) => Text(data.value ?? 'Loading...');
}
```

[See detailed documentation →](./rules.md#flutter_compositions_no_async_setup)

#### `flutter_compositions_controller_lifecycle`

**Severity:** Warning

Ensures Flutter controllers are properly disposed using either `use*` helper functions or manual disposal in `onUnmounted()`.

**Detected controller types:**
- ScrollController
- PageController
- TextEditingController
- TabController
- AnimationController
- VideoPlayerController
- WebViewController

```dart
// ❌ Bad - never disposed
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController();
  return (context) => ListView(controller: controller);
}

// ✅ Good - auto-disposed
@override
Widget Function(BuildContext) setup() {
  final controller = useScrollController();
  return (context) => ListView(controller: controller.value);
}

// ✅ Good - manually disposed
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController();
  onUnmounted(() => controller.dispose());
  return (context) => ListView(controller: controller);
}
```

[See detailed documentation →](./rules.md#flutter_compositions_controller_lifecycle)

#### `flutter_compositions_no_conditional_composition`

**Severity:** Error

Ensures composition API calls are not placed inside conditionals or loops. Similar to React Hooks rules.

**Flagged composition APIs:**
- Reactivity: `ref`, `computed`, `writableComputed`, `customRef`, `watch`, `watchEffect`
- Lifecycle: `onMounted`, `onUnmounted`
- Dependency injection: `provide`, `inject`
- Controllers: `useScrollController`, `usePageController`, `useFocusNode`, `useTextEditingController`, `useValueNotifier`, `useAnimationController`, etc.

```dart
// ❌ Bad - conditional composition
@override
Widget Function(BuildContext) setup() {
  if (someCondition) {
    final count = ref(0); // Don't do this!
  }
  return (context) => Text('Hello');
}

// ✅ Good - composition at top level
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  // Conditional logic on values is OK
  if (someCondition) {
    count.value = 10;
  }

  return (context) => Text('${count.value}');
}
```

[See detailed documentation →](./rules.md#flutter_compositions_no_conditional_composition)

---

### Best Practices Rules

General best practice rules for clean code.

#### `flutter_compositions_no_mutable_fields`

**Severity:** Warning

Ensures all fields in CompositionWidget classes are `final`. Mutable state should be managed through `ref()` or `computed()`.

```dart
// ❌ Bad - mutable field
class Counter extends CompositionWidget {
  int count = 0; // Mutable field!

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Text('$count');
  }
}

// ✅ Good - immutable prop, mutable via ref
class Counter extends CompositionWidget {
  final int initialCount;

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(initialCount);
    return (context) => Text('${count.value}');
  }
}
```

[See detailed documentation →](./rules.md#flutter_compositions_no_mutable_fields)

---

## Configuring Rules

### Enable/Disable Specific Rules

In `analysis_options.yaml`:

```yaml
custom_lint:
  rules:
    # Enable specific rules
    - flutter_compositions_ensure_reactive_props: true
    - flutter_compositions_no_async_setup: true

    # Disable specific rules
    - flutter_compositions_no_mutable_fields: false
```

### Disable Rules in Code

#### Per File

```dart
// ignore_for_file: flutter_compositions_ensure_reactive_props
```

#### Per Line

```dart
// ignore: flutter_compositions_ensure_reactive_props
final name = this.name;
```

#### Per Block

```dart
// ignore: flutter_compositions_controller_lifecycle
final controller = ScrollController();
```

## IDE Integration

### VS Code
Run `dart run custom_lint --watch` in a terminal. The built-in Flutter/Dart
extensions surface diagnostics in the editor automatically, and quick fixes
remain available via `Ctrl/Cmd + .`.

### Android Studio / IntelliJ

1. Run `dart run custom_lint` in terminal
2. Lints will appear in the Problems panel
3. Or run `dart run custom_lint --watch` for live updates

## Rule Summary Table

| Rule | Severity | Category | Auto-Fix | Description |
|------|----------|----------|----------|-------------|
| [ensure_reactive_props](./rules.md#flutter_compositions_ensure_reactive_props) | Warning | Reactivity | No | Access props via `widget()` |
| [no_async_setup](./rules.md#flutter_compositions_no_async_setup) | Error | Lifecycle | No | Prevent async setup methods |
| [controller_lifecycle](./rules.md#flutter_compositions_controller_lifecycle) | Warning | Lifecycle | No | Ensure controller disposal |
| [no_mutable_fields](./rules.md#flutter_compositions_no_mutable_fields) | Warning | Best Practices | No | Enforce immutable fields |
| [no_conditional_composition](./rules.md#flutter_compositions_no_conditional_composition) | Error | Lifecycle | No | Prevent conditional composition APIs |

## Common Patterns

### Pattern 1: Reactive Props

Always use `widget()` to access props reactively:

```dart
class UserCard extends CompositionWidget {
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    final greeting = computed(() => 'Hello, ${props.value.name}!');
    return (context) => Text(greeting.value);
  }
}
```

### Pattern 2: Controller Management

Always use composables for controllers:

```dart
@override
Widget Function(BuildContext) setup() {
  // ✅ Auto-disposed
  final scrollController = useScrollController();
  final (textController, text, _) = useTextEditingController();
  final (animController, animValue) = useAnimationController(
    duration: Duration(seconds: 1),
  );

  return (context) => /* ... */;
}
```

### Pattern 3: Async Initialization

Use `onMounted()` for async operations:

```dart
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);
  final isLoading = ref(false);

  onMounted(() async {
    isLoading.value = true;
    try {
      data.value = await fetchData();
    } finally {
      isLoading.value = false;
    }
  });

  return (context) => /* ... */;
}
```

### Pattern 4: Type-Safe DI

Use `InjectionKey` for type-safe dependency injection:

```dart
class ThemeServiceKey extends InjectionKey<ThemeService> {
  const ThemeServiceKey();
}

const themeServiceKey = ThemeServiceKey();

// Provide
provide(themeServiceKey, ThemeService());

// Inject
final theme = inject(themeServiceKey);
```

## Troubleshooting

### Lints not showing up?

1. Make sure `custom_lint` is added to `dev_dependencies`
2. Run `flutter pub get`
3. Restart your IDE
4. Run `dart run custom_lint` manually

### False positives?

1. Check if the lint rule is correctly identifying the issue
2. Use `// ignore:` comments for intentional exceptions
3. Report false positives on [GitHub Issues](https://github.com/yourusername/flutter_compositions/issues)

### Performance issues?

1. Use `dart run custom_lint` instead of `--watch` for large codebases
2. Disable specific rules that are not relevant
3. Run lints in CI/CD instead of locally

## Best Practices

1. **Enable all rules by default** - Start strict, disable selectively
2. **Fix lints before committing** - Keep your codebase clean
3. **Use IDE integration** - Catch issues as you type
4. **Document exceptions** - Always explain `// ignore:` comments
5. **Run in CI/CD** - Enforce rules in your pipeline

## Contributing

Found a false positive or have suggestions for new rules?

1. Check existing issues on [GitHub](https://github.com/yourusername/flutter_compositions/issues)
2. Open a new issue with:
   - Code sample that triggers the lint
   - Expected behavior
   - Actual behavior
3. Submit a PR with:
   - Rule implementation
   - Tests
   - Documentation

## See Also

- [Complete Rules Reference](./rules.md) - Detailed documentation for each rule
- [Reactivity Fundamentals](../guide/reactivity-fundamentals.md) - Learn reactive patterns
- [Best Practices Guide](../guide/best-practices.md) - General best practices
- [Composables Reference](../guide/built-in-composables.md) - Catalog of built-in helpers

## Quick Reference

### Must-follow Rules (Errors)

These rules prevent bugs and should never be disabled:

- `flutter_compositions_no_async_setup` - Setup must be synchronous
- `flutter_compositions_no_conditional_composition` - Composition APIs must be called unconditionally

### Recommended Rules (Warnings)

These rules enforce best practices:

- `flutter_compositions_ensure_reactive_props` - Props must be reactive
- `flutter_compositions_controller_lifecycle` - Controllers must be disposed
- `flutter_compositions_no_mutable_fields` - Fields should be immutable

---

For detailed documentation of each rule, see [Complete Rules Reference](./rules.md).
