# Framework Composables

Composables for Flutter framework integration with reactive state tracking.

## useContext

Creates a reactive reference to the BuildContext.

### Signature

```dart
Ref<BuildContext?> useContext()
```

### Returns

A `Ref<BuildContext?>` that can be populated with the BuildContext from the builder function.

### Important Note

The BuildContext is only available in the returned builder function, not during `setup()`. The ref starts as `null` and should be set in the builder.

### Example - Basic Usage

```dart
@override
Widget Function(BuildContext) setup() {
  final contextRef = useContext();

  return (buildContext) {
    // Set the context value in the builder
    contextRef.value = buildContext;

    // Now you can use it
    final theme = Theme.of(contextRef.value!);
    return Text('Primary color: ${theme.primaryColor}');
  };
}
```

### Better Approach - Direct Access

```dart
@override
Widget Function(BuildContext) setup() {
  // Direct access is simpler in most cases
  return (context) {
    final theme = Theme.of(context);
    return Text('Primary color: ${theme.primaryColor}');
  };
}
```

### When to Use

`useContext()` is mainly useful when you need to pass the context to callbacks or store it for later use. In most cases, accessing the context directly in the builder is simpler and more efficient.

```dart
@override
Widget Function(BuildContext) setup() {
  final contextRef = useContext();

  void showMessage() {
    if (contextRef.value != null) {
      ScaffoldMessenger.of(contextRef.value!).showSnackBar(
        const SnackBar(content: Text('Hello!')),
      );
    }
  }

  return (context) {
    contextRef.value = context;

    return ElevatedButton(
      onPressed: showMessage,
      child: const Text('Show Message'),
    );
  };
}
```

---

## useAppLifecycleState

Creates a reactive reference that tracks the app lifecycle state.

### Signature

```dart
Ref<AppLifecycleState> useAppLifecycleState()
```

### Returns

A `Ref<AppLifecycleState>` that updates whenever the app lifecycle state changes.

### Lifecycle States

- `AppLifecycleState.resumed` - App is visible and responding to user input
- `AppLifecycleState.inactive` - App is in an inactive state (e.g., during a phone call)
- `AppLifecycleState.paused` - App is not currently visible to the user
- `AppLifecycleState.detached` - App is still running but detached from the view
- `AppLifecycleState.hidden` - App is hidden (iOS 13+)

### Example - Basic Usage

```dart
@override
Widget Function(BuildContext) setup() {
  final lifecycleState = useAppLifecycleState();

  // React to lifecycle changes
  watch(
    () => lifecycleState.value,
    (newState, oldState) {
      print('App lifecycle changed: $oldState -> $newState');

      if (newState == AppLifecycleState.resumed) {
        print('App resumed - refresh data');
      } else if (newState == AppLifecycleState.paused) {
        print('App paused - save state');
      }
    },
  );

  return (context) => Column(
    children: [
      Text('Current state: ${lifecycleState.value}'),
      if (lifecycleState.value == AppLifecycleState.resumed)
        const Text('App is active')
      else
        const Text('App is not active'),
    ],
  );
}
```

### Example - Pause Video on Background

```dart
@override
Widget Function(BuildContext) setup() {
  final lifecycleState = useAppLifecycleState();
  final videoController = useVideoController();

  watch(
    () => lifecycleState.value,
    (newState, oldState) {
      if (newState == AppLifecycleState.paused) {
        videoController.value.pause();
      } else if (newState == AppLifecycleState.resumed) {
        videoController.value.play();
      }
    },
  );

  return (context) => VideoPlayer(videoController.value);
}
```

### Example - Auto-Refresh Data

```dart
@override
Widget Function(BuildContext) setup() {
  final lifecycleState = useAppLifecycleState();
  final (userData, refresh) = useAsyncData<User, void>(
    (_) => api.fetchUser(),
  );

  // Refresh data when app comes to foreground
  watch(
    () => lifecycleState.value,
    (newState, oldState) {
      if (newState == AppLifecycleState.resumed &&
          oldState == AppLifecycleState.paused) {
        refresh(); // Refresh data after returning from background
      }
    },
  );

  return (context) {
    return switch (userData.value) {
      AsyncData(:final value) => UserProfile(user: value),
      AsyncLoading() => const CircularProgressIndicator(),
      AsyncError(:final errorValue) => Text('Error: $errorValue'),
      AsyncIdle() => const SizedBox.shrink(),
    };
  };
}
```

### Lifecycle

The lifecycle observer is automatically registered when the component mounts and removed when it unmounts. No manual cleanup is required.

---

## useSearchController

Creates a SearchController with automatic lifecycle management and reactive tracking.

### Signature

```dart
ReadonlyRef<SearchController> useSearchController()
```

### Returns

A `ReadonlyRef<SearchController>` that reactively tracks search text changes.

### Example - Basic Search

```dart
@override
Widget Function(BuildContext) setup() {
  final searchController = useSearchController();

  // React to search text changes
  final searchText = computed(() {
    searchController.value; // Track changes
    return searchController.value.text;
  });

  watch(
    () => searchText.value,
    (newValue, oldValue) {
      print('Search text changed: $oldValue -> $newValue');
      // Perform search
    },
  );

  return (context) => SearchAnchor(
    searchController: searchController.value,
    builder: (context, controller) {
      return SearchBar(
        controller: controller,
        hintText: 'Search...',
      );
    },
    suggestionsBuilder: (context, controller) {
      return [
        ListTile(title: Text('Result for: ${searchText.value}')),
      ];
    },
  );
}
```

### Example - Search with Debounce

```dart
@override
Widget Function(BuildContext) setup() {
  final searchController = useSearchController();
  final searchResults = ref<List<String>>([]);

  // Debounced search
  Timer? debounceTimer;
  watch(
    () => searchController.value.text,
    (query, _) {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        if (query.isNotEmpty) {
          final results = await api.search(query);
          searchResults.value = results;
        } else {
          searchResults.value = [];
        }
      });
    },
  );

  onUnmounted(() => debounceTimer?.cancel());

  return (context) => SearchAnchor(
    searchController: searchController.value,
    builder: (context, controller) {
      return SearchBar(
        controller: controller,
        hintText: 'Search...',
      );
    },
    suggestionsBuilder: (context, controller) {
      return searchResults.value.map((result) {
        return ListTile(title: Text(result));
      }).toList();
    },
  );
}
```

### Example - Advanced Search with Filtering

```dart
@override
Widget Function(BuildContext) setup() {
  final searchController = useSearchController();
  final items = ref<List<Item>>([
    Item('Apple', category: 'Fruit'),
    Item('Banana', category: 'Fruit'),
    Item('Carrot', category: 'Vegetable'),
  ]);

  final filteredItems = computed(() {
    final query = searchController.value.text.toLowerCase();
    if (query.isEmpty) return items.value;

    return items.value.where((item) {
      return item.name.toLowerCase().contains(query);
    }).toList();
  });

  return (context) => Column(
    children: [
      SearchBar(
        controller: searchController.value,
        hintText: 'Search items...',
      ),
      Expanded(
        child: ComputedBuilder(
          builder: () => ListView.builder(
            itemCount: filteredItems.value.length,
            itemBuilder: (context, index) {
              final item = filteredItems.value[index];
              return ListTile(
                title: Text(item.name),
                subtitle: Text(item.category),
              );
            },
          ),
        ),
      ),
    ],
  );
}
```

### Lifecycle

The SearchController is automatically disposed when the component unmounts. The internal listener is also removed automatically.

---

## Best Practices

### Use Direct Context Access

```dart
// Good - Direct access in builder
return (context) {
  final theme = Theme.of(context);
  return Text('Color: ${theme.primaryColor}');
};

// Avoid - Unnecessary ref wrapper
final contextRef = useContext();
return (context) {
  contextRef.value = context;
  final theme = Theme.of(context);
  return Text('Color: ${theme.primaryColor}');
};
```

### Lifecycle State for Background Tasks

```dart
// Good - Pause/resume based on lifecycle
final lifecycleState = useAppLifecycleState();

watch(() => lifecycleState.value, (state, _) {
  if (state == AppLifecycleState.paused) {
    timer.cancel(); // Stop background work
  } else if (state == AppLifecycleState.resumed) {
    timer = Timer.periodic(...); // Resume background work
  }
});
```

### Debounce Search Input

```dart
// Good - Debounced search
Timer? debounceTimer;
watch(() => searchController.value.text, (query, _) {
  debounceTimer?.cancel();
  debounceTimer = Timer(Duration(milliseconds: 300), () {
    performSearch(query);
  });
});

onUnmounted(() => debounceTimer?.cancel());
```

---

## See Also

- [Lifecycle hooks](../lifecycle.md) - onMounted, onUnmounted
- [watch, watchEffect](../watch.md) - Side effects
- [ref](../reactivity.md#ref) - Reactive references
- [computed](../reactivity.md#computed) - Computed values
