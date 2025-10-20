# Flutter Compositions Lints

Custom lint rules for [Flutter Compositions](../flutter_compositions) to enforce best practices and prevent common pitfalls.

## Rules

### 1. `flutter_compositions_ensure_reactive_props`

**Severity:** Warning

Ensures widget properties are accessed through `widget()` in `setup()` to maintain reactivity.

❌ **Bad:**
```dart
@override
Widget Function(BuildContext) setup() {
  final name = this.displayName; // Direct access - not reactive!
  return (context) => Text(name);
}
```

✅ **Good:**
```dart
@override
Widget Function(BuildContext) setup() {
  final props = widget();
  final name = computed(() => props.value.displayName); // Reactive!
  return (context) => Text(name.value);
}
```

### 2. `flutter_compositions_no_async_setup`

**Severity:** Error

Prevents async `setup()` methods. The setup method must synchronously return a builder function.

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

  onMounted(() async {
    data.value = await loadData();
  });

  return (context) => Text(data.value ?? 'Loading...');
}
```

### 3. `flutter_compositions_controller_lifecycle`

**Severity:** Warning

Ensures Flutter controllers are properly disposed using `use*` helpers or explicit `onUnmounted()` calls.

❌ **Bad:**
```dart
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController(); // No disposal!
  return (context) => ListView(controller: controller);
}
```

✅ **Good:**
```dart
@override
Widget Function(BuildContext) setup() {
  // Option 1: Use helper (recommended)
  final controller = useScrollController();
  return (context) => ListView(controller: controller.value);

  // Option 2: Manual disposal
  final controller = ScrollController();
  onUnmounted(() => controller.dispose());
  return (context) => ListView(controller: controller);
}
```

### 4. `flutter_compositions_no_mutable_fields`

**Severity:** Warning

Ensures CompositionWidget fields are `final`. All mutable state should use `ref()`.

❌ **Bad:**
```dart
class MyWidget extends CompositionWidget {
  int count; // Mutable field!
}
```

✅ **Good:**
```dart
class MyWidget extends CompositionWidget {
  final int initialCount; // Immutable prop

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(initialCount); // Mutable via ref
    ...
  }
}
```

### 5. `flutter_compositions_provide_inject_type_match`

**Severity:** Info

Warns against using common types (String, int, etc.) with provide/inject to avoid type conflicts.

❌ **Bad:**
```dart
provide<Ref<String>>(theme); // Common type - conflicts likely!
```

✅ **Good:**
```dart
class AppTheme { ... } // Custom type
provide<Ref<AppTheme>>(theme); // No conflicts!
```

## Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  custom_lint: ^0.7.0
  flutter_compositions_lints:
    path: packages/flutter_compositions_lints
```

Create `analysis_options.yaml` in your project root:

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  enable_all_lint_rules: true
```

## Running the lints

```bash
# Analyze your code
dart run custom_lint

# Watch for changes
dart run custom_lint --watch

# Fix auto-fixable issues
dart run custom_lint --fix
```

## Contributing

Found a false positive or want to suggest a new rule? Please open an issue!
