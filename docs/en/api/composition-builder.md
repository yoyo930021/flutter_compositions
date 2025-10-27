# CompositionBuilder

Functional composition API for building widgets without creating classes.

## Overview

`CompositionBuilder` provides a functional alternative to `CompositionWidget`, allowing you to use composition APIs without defining a custom widget class.

## Signature

```dart
class CompositionBuilder extends StatefulWidget {
  const CompositionBuilder({
    super.key,
    required this.setup,
  });

  final CompositionSetup setup;
}
```

`CompositionSetup` is a typedef that returns a widget builder:

```dart
typedef CompositionSetup = Widget Function(BuildContext) Function();
```

## Basic Usage

```dart
CompositionBuilder(
  setup: () {
    final count = ref(0);

    return (context) => Column(
      children: [
        Text('Count: ${count.value}'),
        ElevatedButton(
          onPressed: () => count.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  },
)
```

## With Composables

```dart
CompositionBuilder(
  setup: () {
    final (controller, text, _) = useTextEditingController();
    final results = computed(() => search(text.value));

    return (context) => Column(
      children: [
        TextField(controller: controller.value),
        Text('Results: ${results.value.length}'),
      ],
    );
  },
)
```

## Lifecycle Hooks

```dart
CompositionBuilder(
  setup: () {
    final data = ref<String?>(null);

    onMounted(() async {
      data.value = await fetchData();
    });

    onUnmounted(() {
      print('Cleaning up');
    });

    return (context) => Text(data.value ?? 'Loading...');
  },
)
```

## Comparison with CompositionWidget

### Using CompositionWidget

```dart
class CounterWidget extends CompositionWidget {
  const CounterWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    return (context) => Text('${count.value}');
  }
}

// Usage
CounterWidget()
```

### Using CompositionBuilder

```dart
CompositionBuilder(
  setup: () {
    final count = ref(0);
    return (context) => Text('${count.value}');
  },
)
```

## When to Use

### Use CompositionBuilder

- Quick prototyping
- One-off widgets
- Simple local state
- Inline composition logic

```dart
// ✅ Good: Simple, one-off usage
ListView(
  children: [
    CompositionBuilder(
      setup: () {
        final expanded = ref(false);
        return (context) => ExpansionTile(...);
      },
    ),
  ],
)
```

### Use CompositionWidget

- Reusable components
- Complex widgets
- Accept props
- Better testability

```dart
// ✅ Good: Reusable component
class UserCard extends CompositionWidget {
  const UserCard({super.key, required this.user});

  final User user;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    return (context) => Card(
      child: Text(props.value.user.name),
    );
  }
}
```

## Advanced Example

```dart
CompositionBuilder(
  setup: () {
    final userId = ref(1);
    final (userData, refresh) = useAsyncData<User, int>(
      (id) => api.fetchUser(id),
      watch: () => userId.value,
    );

    final scrollController = useScrollController();

    watchEffect(() {
      print('User data changed: ${userData.value}');
    });

    return (context) => RefreshIndicator(
      onRefresh: refresh,
      child: switch (userData.value) {
        AsyncLoading() => CircularProgressIndicator(),
        AsyncData(:final value) => ListView(
            controller: scrollController.value,
            children: [
              Text('Name: ${value.name}'),
              Text('Email: ${value.email}'),
            ],
          ),
        AsyncError(:final errorValue) => Text('Error: $errorValue'),
        _ => SizedBox.shrink(),
      },
    );
  },
)
```

## Best Practices

### Extract Complex Logic to Composables

```dart
// ❌ Bad: Too much logic in the returned builder
CompositionBuilder(
  setup: () {
    final name = ref('');
    final email = ref('');
    final isValid = computed(() =>
      name.value.isNotEmpty && email.value.contains('@'));

    void submit() {
      if (isValid.value) {
        api.submit(name.value, email.value);
      }
    }

    return (context) => Form(...);
  },
)

// ✅ Good: Extract to composable
(Ref<String>, Ref<String>, ComputedRef<bool>, void Function()) useFormValidation() {
  final name = ref('');
  final email = ref('');
  final isValid = computed(() =>
    name.value.isNotEmpty && email.value.contains('@'));

  void submit() {
    if (isValid.value) {
      api.submit(name.value, email.value);
    }
  }

  return (name, email, isValid, submit);
}

CompositionBuilder(
  setup: () {
    final (name, email, isValid, submit) = useFormValidation();
    return (context) => Form(...);
  },
)
```

### Use CompositionWidget for Reusable Components

```dart
// ❌ Bad: Repeating CompositionBuilder
ListView(
  children: [
    CompositionBuilder(setup: () => ...counterLogic...),
    CompositionBuilder(setup: () => ...counterLogic...), // Duplicate!
    CompositionBuilder(setup: () => ...counterLogic...),
  ],
)

// ✅ Good: Extract to reusable widget
class Counter extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    return (context) => Text('${count.value}');
  }
}

ListView(
  children: [
    Counter(),
    Counter(),
    Counter(),
  ],
)
```

## See Also

- [CompositionWidget](./composition-widget.md) - Class-based composition
- [ref](./reactivity.md#ref) - Reactive state
- [Composables](./composables/) - Reusable composition functions
