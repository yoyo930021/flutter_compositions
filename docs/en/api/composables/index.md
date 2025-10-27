# Composables API Reference

Composables are reusable composition functions that encapsulate stateful logic. All composables follow the `use*` naming convention and handle resource disposal automatically.

## Overview

Flutter Compositions provides built-in composables for common patterns:

- **[Controllers](./controllers.md)** - Flutter controllers with automatic disposal
- **[Animations](./animations.md)** - Animation controllers and reactive animation values
- **[Async](./async.md)** - Asynchronous operations with state tracking
- **[Listenable](./listenable.md)** - Listenable and ValueListenable management
- **[Framework](./framework.md)** - Framework integration utilities

## Categories

### Controller Composables

Manage Flutter controllers with automatic disposal:

| Composable | Description | Returns |
|------------|-------------|---------|
| `useScrollController` | ScrollController with auto-disposal | `Ref<ScrollController>` |
| `usePageController` | PageController with auto-disposal | `Ref<PageController>` |
| `useTextEditingController` | TextEditingController with reactive text/selection | `(Ref<TextEditingController>, Ref<String>, Ref<TextSelection>)` |
| `useFocusNode` | FocusNode with auto-disposal | `Ref<FocusNode>` |
| `useTabController` | TabController with auto-disposal | `Ref<TabController>` |

[View Controllers Documentation →](./controllers.md)

### Animation Composables

Create animations with automatic disposal and reactive values:

| Composable | Description | Returns |
|------------|-------------|---------|
| `useAnimationController` | AnimationController with reactive value | `(AnimationController, Ref<double>)` |
| `useSingleTickerProvider` | TickerProvider for single AnimationController | `TickerProvider` |
| `manageAnimation` | Tween animation with auto-disposal | `Animation<T>` |

[View Animations Documentation →](./animations.md)

### Async Composables

Handle asynchronous operations with reactive state tracking:

| Composable | Description | Returns |
|------------|-------------|---------|
| `useFuture` | Execute a Future and track its state | `Ref<AsyncValue<T>>` |
| `useAsyncData` | Advanced async with watch and manual refresh | `(ReadonlyRef<AsyncValue<T>>, void Function())` |
| `useAsyncValue` | Split AsyncValue into individual refs | `(data, error, loading, hasData)` |
| `useStream` | Track latest value from a Stream | `Ref<T>` |
| `useStreamController` | StreamController with reactive tracking | `(StreamController<T>, Ref<T>)` |

[View Async Documentation →](./async.md)

### Listenable Composables

Manage Listenable objects reactively:

| Composable | Description | Returns |
|------------|-------------|---------|
| `manageListenable` | Auto-dispose Listenable and trigger rebuilds | `T` |
| `manageValueListenable` | Auto-dispose ValueListenable with reactive value | `Ref<V>` |

[View Listenable Documentation →](./listenable.md)

### Framework Composables

Flutter framework integration utilities:

| Composable | Description | Returns |
|------------|-------------|---------|
| `useContext` | Access BuildContext during build | `BuildContext` |
| `useAppLifecycleState` | Track app lifecycle state reactively | `Ref<AppLifecycleState>` |
| `useSearchController` | SearchController with auto-disposal | `Ref<SearchController>` |

[View Framework Documentation →](./framework.md)

## Usage Examples

### Basic Counter with Text Input

```dart
class CounterForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    final (controller, text, _) = useTextEditingController();

    void incrementByInput() {
      final value = int.tryParse(text.value) ?? 1;
      count.value += value;
    }

    return (context) => Column(
      children: [
        Text('Count: ${count.value}'),
        TextField(
          controller: controller.value,
          decoration: InputDecoration(labelText: 'Increment by'),
          keyboardType: TextInputType.number,
        ),
        ElevatedButton(
          onPressed: incrementByInput,
          child: Text('Add'),
        ),
      ],
    );
  }
}
```

### Animated List with Async Data

```dart
class UserList extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: Duration(milliseconds: 300),
    );

    final (userData, refresh) = useAsyncData<List<User>, void>(
      (_) => api.fetchUsers(),
    );

    watch(() => userData.value, (value, _) {
      if (value.isData) {
        controller.forward();
      }
    });

    onMounted(() => refresh());

    return (context) {
      return switch (userData.value) {
        AsyncLoading() => Center(child: CircularProgressIndicator()),
        AsyncError(:final errorValue) => Center(
          child: Column(
            children: [
              Text('Error: $errorValue'),
              ElevatedButton(onPressed: refresh, child: Text('Retry')),
            ],
          ),
        ),
        AsyncData(:final value) => FadeTransition(
          opacity: controller,
          child: ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, index) => UserTile(user: value[index]),
          ),
        ),
        AsyncIdle() => SizedBox.shrink(),
      };
    };
  }
}
```

### Scroll-based Animation

```dart
class ScrollAnimatedHeader extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final scrollController = useScrollController();
    final headerHeight = ref(200.0);

    watchEffect(() {
      final offset = scrollController.value.offset;
      headerHeight.value = (200 - offset).clamp(60.0, 200.0);
    });

    return (context) => CustomScrollView(
      controller: scrollController.value,
      slivers: [
        SliverAppBar(
          expandedHeight: headerHeight.value,
          flexibleSpace: FlexibleSpaceBar(title: Text('Dynamic Header')),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ListTile(title: Text('Item $index')),
            childCount: 50,
          ),
        ),
      ],
    );
  }
}
```

## Creating Custom Composables

Composables are functions that use reactive primitives and return reusable values:

```dart
/// Track mouse position (for web/desktop)
(Ref<Offset>, Ref<bool>) useMousePosition() {
  final position = ref(Offset.zero);
  final isInside = ref(false);

  onBuild((context) {
    // Update position on pointer events
  });

  return (position, isInside);
}

/// Debounced input
Ref<String> useDebouncedValue(Ref<String> source, {Duration delay = const Duration(milliseconds: 500)}) {
  final debounced = ref(source.value);
  Timer? timer;

  watch(() => source.value, (newValue, _) {
    timer?.cancel();
    timer = Timer(delay, () {
      debounced.value = newValue;
    });
  });

  onUnmounted(() => timer?.cancel());

  return debounced;
}

/// Form validation
(Ref<bool>, Ref<String?>) useValidation(
  Ref<String> input,
  String? Function(String) validator,
) {
  final isValid = ref(false);
  final errorMessage = ref<String?>(null);

  watch(() => input.value, (value, _) {
    final error = validator(value);
    errorMessage.value = error;
    isValid.value = error == null;
  });

  return (isValid, errorMessage);
}
```

## Best Practices

### 1. Always Use `use*` Helpers for Controllers

```dart
// ✅ Good - Auto-disposal
final scrollController = useScrollController();

// ❌ Bad - Manual disposal required
final controller = ScrollController();
onUnmounted(() => controller.dispose());
```

### 2. Combine Composables for Complex Logic

```dart
@override
Widget Function(BuildContext) setup() {
  // Combine multiple composables
  final (controller, text, _) = useTextEditingController();
  final scrollController = useScrollController();
  final (animController, animValue) = useAnimationController(
    duration: Duration(milliseconds: 300),
  );

  // Orchestrate them together
  watch(() => text.value, (value, _) {
    if (value.isNotEmpty) {
      animController.forward();
    } else {
      animController.reverse();
    }
  });

  return (context) => /* ... */;
}
```

### 3. Extract Reusable Logic into Custom Composables

```dart
// Instead of repeating this pattern:
final input1 = ref('');
final valid1 = computed(() => input1.value.length >= 6);

final input2 = ref('');
final valid2 = computed(() => input2.value.length >= 6);

// Create a composable:
(Ref<String>, Ref<bool>) useValidatedInput({int minLength = 6}) {
  final input = ref('');
  final isValid = computed(() => input.value.length >= minLength);
  return (input, isValid);
}

// Use it:
final (email, emailValid) = useValidatedInput(minLength: 5);
final (password, passwordValid) = useValidatedInput(minLength: 8);
```

### 4. Name Composables Descriptively

```dart
// ✅ Good - Clear purpose
useFormValidation()
useDebounceInput()
useWindowSize()
usePagination()

// ❌ Bad - Vague names
useHelper()
useUtils()
useState()
```

## See Also

- [Creating Composables Guide](../../guide/creating-composables.md) - How to build custom composables
- [Built-in Composables](../../guide/built-in-composables.md) - Overview with examples
- [Lifecycle Hooks](../lifecycle.md) - onMounted, onUnmounted, onBuild
- [Reactivity Fundamentals](../../guide/reactivity-fundamentals.md) - ref, computed, watch
