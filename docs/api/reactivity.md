# Reactivity API

Core reactive primitives for managing state.

## `ref<T>`

Creates a writable reactive reference.

### Signature

```dart
Ref<T> ref<T>(T initialValue)
```

### Parameters

- `initialValue`: The initial value of the ref

### Returns

A `Ref<T>` object with a `.value` property that triggers reactivity when read or written.

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  // Read value
  print(count.value); // 0

  // Write value (triggers reactivity)
  count.value++;

  return (context) => Text('Count: ${count.value}');
}
```

### Reactivity

- **Read**: When `.value` is read inside a reactive context (`computed`, `watch`, `watchEffect`, or builder function), the context tracks this ref as a dependency
- **Write**: When `.value` is written, all dependent contexts are notified and re-run

---

## `computed<T>`

Creates a readonly computed value that automatically updates when its dependencies change.

### Signature

```dart
ComputedRef<T> computed<T>(T Function() getter)
```

### Parameters

- `getter`: A function that computes the value. Dependencies are automatically tracked.

### Returns

A `ComputedRef<T>` that provides readonly access to the computed value via `.value`.

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);
  final doubled = computed(() => count.value * 2);
  final quadrupled = computed(() => doubled.value * 2);

  count.value++; // doubled and quadrupled automatically update

  return (context) => Column(
    children: [
      Text('Count: ${count.value}'),
      Text('Doubled: ${doubled.value}'),
      Text('Quadrupled: ${quadrupled.value}'),
    ],
  );
}
```

### Lazy Evaluation

Computed values are lazily evaluated - the getter function only runs when `.value` is accessed and dependencies have changed.

### Caching

Results are cached until a dependency changes. Multiple reads of `.value` without dependency changes return the cached value without re-running the getter.

---

## `writableComputed<T>`

Creates a computed value with both getter and setter logic.

### Signature

```dart
WritableComputedRef<T> writableComputed<T>({
  required T Function(T Function<V>(ReadonlyRef<V>) get) getter,
  required void Function(T value, void Function<V>(WritableRef<V>, V) set) setter,
})
```

### Parameters

- `getter`: Function that computes the value. Use the provided `get` function to read dependencies.
- `setter`: Function called when `.value` is assigned. Use the provided `set` function to update source refs.

### Returns

A `WritableComputedRef<T>` with readable and writable `.value` property.

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final firstName = ref('John');
  final lastName = ref('Doe');

  final fullName = writableComputed<String>(
    getter: (get) => '${get(firstName)} ${get(lastName)}',
    setter: (value, set) {
      final parts = value.split(' ');
      if (parts.length >= 2) {
        set(firstName, parts[0]);
        set(lastName, parts.sublist(1).join(' '));
      }
    },
  );

  // Read
  print(fullName.value); // "John Doe"

  // Write (updates firstName and lastName)
  fullName.value = 'Jane Smith';
  print(firstName.value); // "Jane"
  print(lastName.value); // "Smith"

  return (context) => TextField(
    controller: TextEditingController(text: fullName.value),
    onChanged: (value) => fullName.value = value,
  );
}
```

### Use Cases

- Two-way data binding
- Form field synchronization
- Derived state that can be written back to source

---

## Type Aliases

### `Ref<T>`

```dart
typedef Ref<T> = WritableRef<T>
```

Writable reactive reference. Alias for `WritableRef<T>`.

### `ComputedRef<T>`

```dart
typedef ComputedRef<T> = ReadonlyRef<T>
```

Readonly computed value. Alias for `ReadonlyRef<T>`.

---

## Interface Types

### `ReadonlyRef<T>`

Interface for readonly reactive references.

```dart
abstract class ReadonlyRef<T> {
  T get value;
}
```

### `WritableRef<T>`

Interface for writable reactive references.

```dart
abstract class WritableRef<T> extends ReadonlyRef<T> {
  set value(T newValue);
}
```

### `WritableComputedRef<T>`

Interface for writable computed references.

```dart
abstract class WritableComputedRef<T> extends WritableRef<T> {
  // Inherits value getter/setter
}
```

---

## Best Practices

### 1. Use `ref` for Mutable State

```dart
// ✅ Good
final count = ref(0);
count.value++;

// ❌ Bad - mutable widget fields
class MyWidget extends CompositionWidget {
  int count = 0; // Won't trigger reactivity!
}
```

### 2. Use `computed` for Derived State

```dart
// ✅ Good
final doubled = computed(() => count.value * 2);

// ❌ Bad - manual updates
final doubled = ref(0);
watch(() => count.value, (value, _) {
  doubled.value = value * 2; // Redundant
});
```

### 3. Keep Computed Functions Pure

```dart
// ✅ Good
final greeting = computed(() => 'Hello, ${name.value}!');

// ❌ Bad - side effects in computed
final greeting = computed(() {
  print('Computing...'); // Side effect!
  return 'Hello, ${name.value}!';
});
```

### 4. Use `writableComputed` for Bidirectional Data Flow

```dart
// ✅ Good for two-way binding
final fullName = writableComputed<String>(
  getter: (get) => '${get(firstName)} ${get(lastName)}',
  setter: (value, set) { /* split and update */ },
);

// ❌ Avoid if only reading
final fullName = writableComputed<String>(
  getter: (get) => '${get(firstName)} ${get(lastName)}',
  setter: (value, set) {}, // Empty setter is wasteful
);
```

---

## Performance Considerations

- **Computed values are lazy**: They only compute when accessed
- **Caching is automatic**: Same result returned if dependencies haven't changed
- **Fine-grained updates**: Only components that read a changed ref rebuild
- **Dependency tracking is automatic**: No need to manually declare dependencies

---

## See Also

- [watch, watchEffect](./watch.md) - React to changes
- [customRef](./custom-ref.md) - Custom reactive logic
- [CompositionWidget](./composition-widget.md) - Using refs in widgets
