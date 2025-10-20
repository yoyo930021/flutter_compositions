# Flutter Compositions Lints

Custom lint rules to enforce best practices and prevent common pitfalls in Flutter Compositions.

## Installation

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

## Running Lints

```bash
# Analyze code
dart run custom_lint

# Watch for changes
dart run custom_lint --watch

# Auto-fix issues
dart run custom_lint --fix
```

## IDE Integration

### VS Code
Install the [Custom Lint extension](https://marketplace.visualstudio.com/items?itemName=VeryGoodVentures.custom-lint).

### Android Studio / IntelliJ
Custom lint is automatically detected when running `dart run custom_lint`.

## Available Rules

| Rule | Severity | Category | Description |
|------|----------|----------|-------------|
| [flutter_compositions_ensure_reactive_props](./rules.md#flutter_compositions_ensure_reactive_props) | Warning | Reactivity | Ensure props accessed via `widget()` |
| [flutter_compositions_no_async_setup](./rules.md#flutter_compositions_no_async_setup) | Error | Lifecycle | Prevent async setup methods |
| [flutter_compositions_controller_lifecycle](./rules.md#flutter_compositions_controller_lifecycle) | Warning | Lifecycle | Ensure controller disposal |
| [flutter_compositions_no_mutable_fields](./rules.md#flutter_compositions_no_mutable_fields) | Warning | Best Practices | Enforce immutable fields |
| [flutter_compositions_provide_inject_type_match](./rules.md#flutter_compositions_provide_inject_type_match) | Info | Type Safety | Warn on common type conflicts |

[See detailed rule documentation →](./rules.md)

## Quick Examples

### Reactive Props

❌ **Bad:**
```dart
@override
Widget Function(BuildContext) setup() {
  final name = this.displayName; // Not reactive!
  return (context) => Text(name);
}
```

✅ **Good:**
```dart
@override
Widget Function(BuildContext) setup() {
  final props = widget();
  final name = computed(() => props.value.displayName);
  return (context) => Text(name.value);
}
```

### Async Setup

❌ **Bad:**
```dart
@override
Future<Widget Function(BuildContext)> setup() async {
  await loadData();
  return (context) => Text('Loaded');
}
```

✅ **Good:**
```dart
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);
  onMounted(() async => data.value = await loadData());
  return (context) => Text(data.value ?? 'Loading...');
}
```

### Controller Lifecycle

❌ **Bad:**
```dart
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController(); // Never disposed!
  return (context) => ListView(controller: controller);
}
```

✅ **Good:**
```dart
@override
Widget Function(BuildContext) setup() {
  final controller = useScrollController(); // Auto-disposed
  return (context) => ListView(controller: controller.value);
}
```

## Disabling Rules

### Per File

```dart
// ignore_for_file: flutter_compositions_ensure_reactive_props
```

### Per Line

```dart
// ignore: flutter_compositions_ensure_reactive_props
final name = this.displayName;
```

### In Configuration

```yaml
custom_lint:
  rules:
    - flutter_compositions_ensure_reactive_props: false
    - flutter_compositions_no_async_setup: true
```

## Contributing

Found a false positive or have suggestions for new rules? [Open an issue](https://github.com/yourusername/flutter_compositions/issues)!

## See Also

- [Complete Rules Reference](./rules.md)
- [Best Practices Guide](../guide/best-practices.md)
- [API Reference](../api/)
