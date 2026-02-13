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
  return (context) => ListView(controller: controller.raw);

  // Option 2: Manual disposal
  final controller = ScrollController();
  onUnmounted(() => controller.dispose());
  return (context) => ListView(controller: controller);
}
```

### 4. `flutter_compositions_shallow_reactivity`

**Severity:** Warning

Warns about shallow reactivity limitations. Direct mutations won't trigger reactive updates.

❌ **Bad:**
```dart
@override
Widget Function(BuildContext) setup() {
  final items = ref([1, 2, 3]);

  void addItem() {
    items.value.add(4); // Won't trigger update!
  }

  return (context) => Text('${items.value.length}');
}
```

✅ **Good:**
```dart
@override
Widget Function(BuildContext) setup() {
  final items = ref([1, 2, 3]);

  void addItem() {
    items.value = [...items.value, 4]; // Triggers update!
  }

  return (context) => Text('${items.value.length}');
}
```

### 5. `flutter_compositions_no_conditional_composition`

**Severity:** Error

Prevents composition API calls inside conditionals or loops (similar to React Hooks rules).

### 6. `flutter_compositions_no_logic_in_builder`

**Severity:** Warning

Prevents logic inside the builder function returned by `setup()`. The builder should only build the widget tree. The only exception is props destructuring.

❌ **Bad:**
```dart
return (context) {
  final filtered = items.value.where(...).toList(); // ❌ Logic in builder
  return ListView(children: filtered.map(ItemTile.new).toList());
};
```

✅ **Good:**
```dart
final filtered = computed(() => items.value.where(...).toList());
return (context) => ListView(children: filtered.value.map(ItemTile.new).toList());
```

### 7. `flutter_compositions_prefer_raw_controller`

**Severity:** Warning

Suggests using `.raw` instead of `.value` when passing controller refs to widget parameters like `controller:` or `focusNode:` in the builder. Using `.raw` avoids unnecessary reactive tracking.

❌ **Bad:**
```dart
return (context) => ListView(controller: scrollController.value);
```

✅ **Good:**
```dart
return (context) => ListView(controller: scrollController.raw);
```

## Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_compositions_lints: ^0.1.0
```

Configure in `analysis_options.yaml`:

```yaml
plugins:
  flutter_compositions_lints:
    path: .
```

## Contributing

Found a false positive or want to suggest a new rule? Please open an issue!
