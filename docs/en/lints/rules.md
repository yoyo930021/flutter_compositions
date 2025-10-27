# Flutter Compositions Lint Rules

Complete reference for all available lint rules.

## Rule Categories

- **Reactivity**: Rules ensuring proper reactive state management
- **Lifecycle**: Rules managing component lifecycle and resource cleanup
- **Best Practices**: General best practice rules

---

## Reactivity Rules

### `flutter_compositions_ensure_reactive_props`

**Category:** Reactivity
**Severity:** Warning
**Auto-fixable:** No

#### Description

Ensures that widget properties are accessed through `widget()` in the `setup()` method to maintain reactivity. Direct property access will not trigger reactive updates.

#### Why it matters

The `setup()` method runs only once. If you directly access `this.propertyName`, you capture a snapshot of the value at setup time. When the parent passes new props, your component won't react to the change.

#### Examples

❌ **Bad:**
```dart
class UserCard extends CompositionWidget {
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    // Captures initial value only - NOT reactive
    final greeting = 'Hello, $name!';
    return (context) => Text(greeting);
  }
}
```

✅ **Good:**
```dart
class UserCard extends CompositionWidget {
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    // Reacts to prop changes
    final greeting = computed(() => 'Hello, ${props.value.name}!');
    return (context) => Text(greeting.value);
  }
}
```

---

## Lifecycle Rules

### `flutter_compositions_no_async_setup`

**Category:** Lifecycle
**Severity:** Error
**Auto-fixable:** No

#### Description

Prevents `setup()` methods from being async. The setup function must synchronously return a builder function.

#### Why it matters

Making `setup()` async breaks the composition lifecycle. The framework expects a synchronous builder function return, and async setups can cause timing issues and unpredictable behavior.

#### Examples

❌ **Bad:**
```dart
@override
Future<Widget Function(BuildContext)> setup() async {
  final data = await fetchData();
  return (context) => Text(data);
}
```

✅ **Good:**
```dart
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);

  onMounted(() async {
    data.value = await fetchData();
  });

  return (context) => Text(data.value ?? 'Loading...');
}
```

### `flutter_compositions_controller_lifecycle`

**Category:** Lifecycle
**Severity:** Warning
**Auto-fixable:** No

#### Description

Ensures Flutter controllers (ScrollController, TextEditingController, etc.) are properly disposed using either:
1. `use*` helper functions (recommended)
2. Manual disposal in `onUnmounted()`

#### Why it matters

Controllers hold native resources and listeners. Failing to dispose them causes memory leaks.

#### Detected controller types

- ScrollController
- PageController
- TextEditingController
- TabController
- AnimationController
- VideoPlayerController
- WebViewController

#### Examples

❌ **Bad:**
```dart
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController(); // Never disposed!
  return (context) => ListView(controller: controller);
}
```

✅ **Good (Option 1 - Recommended):**
```dart
@override
Widget Function(BuildContext) setup() {
  final controller = useScrollController(); // Auto-disposed
  return (context) => ListView(controller: controller.value);
}
```

✅ **Good (Option 2 - Manual):**
```dart
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController();
  onUnmounted(() => controller.dispose());
  return (context) => ListView(controller: controller);
}
```

### `flutter_compositions_no_conditional_composition`

**Category:** Lifecycle
**Severity:** Error
**Auto-fixable:** No

#### Description

Ensures composition API calls (`ref()`, `computed()`, `watch()`, `useScrollController()`, etc.) are not placed inside conditionals or loops. Similar to React Hooks rules, composition APIs must be called unconditionally at the top level of `setup()`.

#### Why it matters

Conditional composition API calls can cause:
- Inconsistent ordering of reactive dependencies across renders
- Unpredictable reactivity behavior
- Difficult to debug lifecycle issues
- Memory leaks when cleanup hooks are skipped

#### Flagged composition APIs

- Reactivity: `ref`, `computed`, `writableComputed`, `customRef`, `watch`, `watchEffect`
- Lifecycle: `onMounted`, `onUnmounted`
- Dependency injection: `provide`, `inject`
- Controllers: `useScrollController`, `usePageController`, `useFocusNode`, `useTextEditingController`, `useValueNotifier`, `useAnimationController`, `manageListenable`, `manageValueListenable`

#### Examples

❌ **Bad:**
```dart
@override
Widget Function(BuildContext) setup() {
  if (someCondition) {
    final count = ref(0); // ❌ Conditional composition API
  }

  for (var i = 0; i < 10; i++) {
    final item = ref(i); // ❌ Inside loop
  }

  return (context) => Text('Hello');
}
```

✅ **Good:**
```dart
@override
Widget Function(BuildContext) setup() {
  // ✅ Composition APIs at top level
  final count = ref(0);
  final items = ref(<int>[]);

  // ✅ Conditional logic for values is OK
  if (someCondition) {
    count.value = 10;
  }

  return (context) => Text('Count: ${count.value}');
}
```

---

## Best Practices Rules

### `flutter_compositions_no_mutable_fields`

**Category:** Best Practices
**Severity:** Warning
**Auto-fixable:** No

#### Description

Ensures all fields in CompositionWidget classes are `final`. Mutable state should be managed through `ref()` or `computed()` in the `setup()` method.

#### Why it matters

Mutable fields bypass the reactive system. Changes to them won't trigger rebuilds, and they violate the composition pattern's design.

#### Examples

❌ **Bad:**
```dart
class Counter extends CompositionWidget {
  int count = 0; // Mutable field!

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Text('$count');
  }
}
```

✅ **Good:**
```dart
class Counter extends CompositionWidget {
  final int initialCount; // Immutable prop

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(initialCount); // Mutable via ref
    return (context) => Text('${count.value}');
  }
}
```

---

## Disabling Rules

### Per-file

```dart
// ignore_for_file: flutter_compositions_ensure_reactive_props
```

### Per-line

```dart
// ignore: flutter_compositions_ensure_reactive_props
final name = this.name;
```

### In analysis_options.yaml

```yaml
custom_lint:
  rules:
    - flutter_compositions_ensure_reactive_props: false
    - flutter_compositions_no_async_setup: true
```

---

## Contributing

Have suggestions for new rules or improvements to existing ones? Please open an issue or pull request!
