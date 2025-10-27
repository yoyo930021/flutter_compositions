# Ref Types

Type interfaces and classes for reactive references in Flutter Compositions.

## Overview

Flutter Compositions provides a hierarchy of reactive reference types modeled after Vue 3's ref system. These types enable fine-grained reactivity through the underlying `alien_signals` library.

## Type Hierarchy

```
ReadonlyRef<T>
├── WritableRef<T>
│   ├── Ref<T>
│   └── WritableComputedRef<T>
└── ComputedRef<T>
```

---

## ReadonlyRef

Base interface for all reactive references that can be read.

### Signature

```dart
abstract class ReadonlyRef<T> {
  T get value;
  T get raw;
}
```

### Properties

- `value` - Gets the current value and establishes a reactive dependency
- `raw` - Gets the value without establishing a reactive dependency

### Description

`ReadonlyRef` is the base interface for all reactive references. Reading `.value` inside a reactive context (like `computed()` or `watchEffect()`) automatically tracks it as a dependency.

### Example - Basic Usage

```dart
final count = ref(0);
ReadonlyRef<int> readonlyCount = count; // Can be assigned

print(readonlyCount.value); // Can read
// readonlyCount.value = 1; // Error: Can't write to readonly ref
```

### Example - Using .raw

The `.raw` property allows you to read a value without tracking it as a dependency:

```dart
final scrollController = useScrollController();

return (context) => ListView(
  // Reading .raw - won't rebuild when controller changes
  controller: scrollController.raw,
  children: [...],
);
```

---

## WritableRef

Interface for reactive references that can be both read and written.

### Signature

```dart
abstract class WritableRef<T> implements ReadonlyRef<T> {
  T get value;
  set value(T newValue);
}
```

### Properties

- `value` - Gets or sets the value. Reading establishes a reactive dependency.

### Description

`WritableRef` extends `ReadonlyRef` and adds a setter for the value. Both `Ref` and `WritableComputedRef` implement this interface.

### Example

```dart
WritableRef<int> count = ref(0);

count.value = 10; // Can write
print(count.value); // Can read

// Can be used wherever WritableRef is expected
void increment(WritableRef<int> counter) {
  counter.value++;
}

increment(count);
```

---

## Ref

The standard reactive reference implementation.

### Signature

```dart
class Ref<T> implements WritableRef<T> {
  Ref(T initialValue);

  T get value;
  set value(T newValue);
  T get raw;
}
```

### Creation

Use the `ref()` function to create a `Ref`:

```dart
Ref<T> ref<T>(T initialValue, {String? debugLabel})
```

### Example - Basic Usage

```dart
final count = ref(0);  // Ref<int>
final name = ref('Alice');  // Ref<String>
final user = ref<User?>(null);  // Ref<User?>

count.value++;  // Triggers reactive updates
print(count.value);  // 1
```

### Example - With Objects

```dart
class User {
  final String name;
  final int age;

  User(this.name, this.age);
}

final user = ref(User('Alice', 30));

// Update entire object
user.value = User('Bob', 25);

// Access properties (doesn't track individual properties)
print(user.value.name);  // 'Bob'
```

### Example - Hot Reload Preservation

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0, debugLabel: 'count');  // Position 0
  final name = ref('Alice', debugLabel: 'name');  // Position 1

  // During hot reload, these values are preserved automatically
  // as long as their order doesn't change

  return (context) => Column(
    children: [
      Text('Count: ${count.value}'),
      Text('Name: ${name.value}'),
    ],
  );
}
```

### Best Practices

```dart
// Good - Type is inferred
final count = ref(0);  // Ref<int>

// Good - Explicit type for nullable
final user = ref<User?>(null);

// Avoid - Unnecessary type annotation
final count = ref<int>(0);

// Good - Meaningful debug labels
final userCount = ref(0, debugLabel: 'userCount');
```

---

## ComputedRef

Read-only computed reactive reference.

### Signature

```dart
class ComputedRef<T> implements ReadonlyRef<T> {
  ComputedRef(T Function() getter);

  T get value;
  T get raw;
}
```

### Creation

Use the `computed()` function to create a `ComputedRef`:

```dart
ReadonlyRef<T> computed<T>(T Function() getter)
```

### Example - Basic Usage

```dart
final count = ref(0);
final doubled = computed(() => count.value * 2);

print(doubled.value);  // 0
count.value = 5;
print(doubled.value);  // 10

// doubled.value = 20;  // Error: Can't set computed ref
```

### Example - Multiple Dependencies

```dart
final firstName = ref('John');
final lastName = ref('Doe');

final fullName = computed(() => '${firstName.value} ${lastName.value}');

print(fullName.value);  // 'John Doe'
firstName.value = 'Jane';
print(fullName.value);  // 'Jane Doe'
```

### Example - Chained Computeds

```dart
final count = ref(0);
final doubled = computed(() => count.value * 2);
final quadrupled = computed(() => doubled.value * 2);

print(quadrupled.value);  // 0
count.value = 5;
print(quadrupled.value);  // 20
```

### Example - Complex Computation

```dart
final items = ref<List<Item>>([
  Item('Apple', price: 1.0),
  Item('Banana', price: 0.5),
  Item('Orange', price: 1.5),
]);

final totalPrice = computed(() {
  return items.value.fold<double>(
    0.0,
    (sum, item) => sum + item.price,
  );
});

final averagePrice = computed(() {
  final total = totalPrice.value;
  final count = items.value.length;
  return count > 0 ? total / count : 0.0;
});

print(averagePrice.value);  // 1.0
```

### Best Practices

```dart
// Good - Pure computation
final doubled = computed(() => count.value * 2);

// Avoid - Side effects in computed
final doubled = computed(() {
  print('Computing...'); // Don't do this!
  return count.value * 2;
});

// Good - Use watch for side effects
watch(() => count.value, (value, _) {
  print('Count changed to $value');
});
```

---

## WritableComputedRef

Writable computed reactive reference with custom getter and setter.

### Signature

```dart
class WritableComputedRef<T> implements WritableRef<T> {
  WritableComputedRef(T Function() getter, void Function(T) setter);

  T get value;
  set value(T newValue);
  T get raw;
}
```

### Creation

Use the `writableComputed()` function to create a `WritableComputedRef`:

```dart
WritableRef<T> writableComputed<T>({
  required T Function() get,
  required void Function(T value) set,
})
```

### Example - Basic Usage

```dart
final count = ref(0);

final doubled = writableComputed<int>(
  get: () => count.value * 2,
  set: (value) => count.value = value ~/ 2,
);

print(doubled.value);  // 0
doubled.value = 10;  // Sets count to 5
print(count.value);  // 5
print(doubled.value);  // 10
```

### Example - Two-Way Binding

```dart
final celsius = ref(0.0);

final fahrenheit = writableComputed<double>(
  get: () => celsius.value * 9 / 5 + 32,
  set: (f) => celsius.value = (f - 32) * 5 / 9,
);

celsius.value = 100;
print(fahrenheit.value);  // 212.0

fahrenheit.value = 32;
print(celsius.value);  // 0.0
```

### Example - Form Field Binding

```dart
final user = ref(User(name: 'Alice', age: 30));

final userName = writableComputed<String>(
  get: () => user.value.name,
  set: (name) => user.value = User(name: name, age: user.value.age),
);

final userAge = writableComputed<int>(
  get: () => user.value.age,
  set: (age) => user.value = User(name: user.value.name, age: age),
);

return (context) => Column(
  children: [
    TextField(
      onChanged: (value) => userName.value = value,
      controller: TextEditingController(text: userName.value),
    ),
    TextField(
      onChanged: (value) => userAge.value = int.tryParse(value) ?? 0,
      controller: TextEditingController(text: userAge.value.toString()),
    ),
  ],
);
```

### Example - Validation

```dart
final rawInput = ref('');

final validatedInput = writableComputed<String>(
  get: () => rawInput.value,
  set: (value) {
    // Validate and sanitize input
    final sanitized = value.trim().toLowerCase();
    if (sanitized.length <= 50) {
      rawInput.value = sanitized;
    }
  },
);

validatedInput.value = '  HELLO  ';
print(rawInput.value);  // 'hello'

validatedInput.value = 'a' * 100;
print(rawInput.value);  // 'hello' (unchanged, too long)
```

### Best Practices

```dart
// Good - Bidirectional sync
final doubled = writableComputed(
  get: () => count.value * 2,
  set: (value) => count.value = value ~/ 2,
);

// Good - Validation in setter
final email = writableComputed(
  get: () => rawEmail.value,
  set: (value) {
    if (isValidEmail(value)) {
      rawEmail.value = value;
    }
  },
);

// Avoid - Setter with side effects
final computed = writableComputed(
  get: () => value.value,
  set: (v) {
    value.value = v;
    print('Changed!'); // Avoid side effects
    api.sync(v); // Don't do async operations
  },
);

// Good - Use watch for side effects
watch(() => value.value, (newValue, _) {
  print('Changed!');
  api.sync(newValue);
});
```

---

## Type Conversions

### Readonly from Writable

```dart
final count = ref(0);  // Ref<int>
ReadonlyRef<int> readonly = count;  // Can convert to readonly

print(readonly.value);  // Can read
// readonly.value = 1;  // Error: Can't write
```

### Computed to Readonly

```dart
final doubled = computed(() => count.value * 2);  // ComputedRef<int>
ReadonlyRef<int> readonly = doubled;  // Already readonly

print(readonly.value);
```

---

## Common Patterns

### Optional Values

```dart
final user = ref<User?>(null);

final userName = computed(() {
  final u = user.value;
  return u?.name ?? 'Guest';
});

if (user.value != null) {
  print('User: ${user.value!.name}');
}
```

### Collections

```dart
final items = ref<List<String>>([]);

final itemCount = computed(() => items.value.length);
final isEmpty = computed(() => items.value.isEmpty);

items.value = [...items.value, 'new item'];  // Trigger update
```

### Object Updates

```dart
class Settings {
  final bool darkMode;
  final String language;

  Settings({required this.darkMode, required this.language});

  Settings copyWith({bool? darkMode, String? language}) {
    return Settings(
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
    );
  }
}

final settings = ref(Settings(darkMode: false, language: 'en'));

// Update immutably
settings.value = settings.value.copyWith(darkMode: true);
```

### Derived State

```dart
final items = ref<List<Item>>([]);
final filter = ref('');

final filteredItems = computed(() {
  final query = filter.value.toLowerCase();
  if (query.isEmpty) return items.value;

  return items.value.where((item) {
    return item.name.toLowerCase().contains(query);
  }).toList();
});

final filteredCount = computed(() => filteredItems.value.length);
```

---

## Performance Tips

### Use .raw for Non-Reactive Access

```dart
// Avoid - Creates unnecessary dependency
final controller = useScrollController();
return ListView(
  controller: controller.value,  // Rebuilds on scroll
  children: [...],
);

// Good - No reactive tracking
return ListView(
  controller: controller.raw,  // Doesn't rebuild
  children: [...],
);
```

### Use untracked() for Complex Cases

```dart
final result = computed(() {
  final a = valueA.value;  // Tracked
  final b = untracked(() => valueB.value);  // Not tracked
  return a + b;
});
// Only re-computes when valueA changes
```

## See Also

- [ref](../reactivity.md#ref) - Creating reactive references
- [computed](../reactivity.md#computed) - Creating computed values
- [untracked](../reactivity.md#untracked) - Reading without tracking
- [customRef](../custom-ref.md) - Custom reactive references
- [watch](../watch.md) - Side effects and watchers
