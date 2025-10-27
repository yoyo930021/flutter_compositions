# AsyncValue

Sealed class representing the state of an async operation.

## Overview

`AsyncValue<T>` is a sealed class similar to Flutter's `AsyncSnapshot` but designed for exhaustive pattern matching. It represents four possible states of an asynchronous operation: idle, loading, data, and error.

Unlike `AsyncSnapshot`, `AsyncValue` is a sealed class which enables compile-time exhaustive pattern matching, ensuring you handle all possible states.

## Signature

```dart
sealed class AsyncValue<T> {
  const AsyncValue();

  const factory AsyncValue.idle() = AsyncIdle<T>;
  const factory AsyncValue.loading() = AsyncLoading<T>;
  const factory AsyncValue.data(T data) = AsyncData<T>;
  const factory AsyncValue.error(Object error, [StackTrace? stackTrace]) = AsyncError<T>;
}
```

## State Types

### AsyncIdle

Represents an operation that hasn't started yet. No connection has been established.

#### Signature

```dart
final class AsyncIdle<T> extends AsyncValue<T> {
  const AsyncIdle();
}
```

#### Example

```dart
final status = ref<AsyncValue<String>>(const AsyncValue.idle());

return switch (status.value) {
  AsyncIdle() => const Text('Click to load'),
  // ... other states
};
```

---

### AsyncLoading

Represents an operation in progress. Waiting for data.

#### Signature

```dart
final class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}
```

#### Example

```dart
final status = ref<AsyncValue<User>>(const AsyncValue.loading());

return switch (status.value) {
  AsyncLoading() => const CircularProgressIndicator(),
  // ... other states
};
```

---

### AsyncData

Represents a successful operation with data.

#### Signature

```dart
final class AsyncData<T> extends AsyncValue<T> {
  const AsyncData(this.value);

  final T value;
}
```

#### Properties

- `value` - The successful result data

#### Example

```dart
final status = ref<AsyncValue<User>>(
  const AsyncValue.data(User(name: 'Alice')),
);

return switch (status.value) {
  AsyncData(:final value) => Text('User: ${value.name}'),
  // ... other states
};
```

---

### AsyncError

Represents a failed operation with error information.

#### Signature

```dart
final class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(this.errorValue, [this.stackTrace]);

  final Object errorValue;
  final StackTrace? stackTrace;
}
```

#### Properties

- `errorValue` - The error that occurred
- `stackTrace` - Optional stack trace of the error

#### Example

```dart
final status = ref<AsyncValue<String>>(
  AsyncValue.error('Connection failed', StackTrace.current),
);

return switch (status.value) {
  AsyncError(:final errorValue, :final stackTrace) => Column(
    children: [
      Text('Error: $errorValue'),
      if (stackTrace != null)
        Text('Stack: ${stackTrace.toString()}'),
    ],
  ),
  // ... other states
};
```

---

## Properties

### State Checks

```dart
bool get isIdle;      // true if AsyncIdle
bool get isLoading;   // true if AsyncLoading
bool get isData;      // true if AsyncData
bool get isError;     // true if AsyncError
bool get hasData;     // true if AsyncData or AsyncError
```

### Safe Value Access

```dart
T? get dataOrNull;              // Returns data if AsyncData, null otherwise
Object? get errorOrNull;        // Returns error if AsyncError, null otherwise
StackTrace? get stackTraceOrNull; // Returns stackTrace if AsyncError, null otherwise
```

## Pattern Matching

### Exhaustive Switch

The recommended way to handle AsyncValue is with exhaustive pattern matching:

```dart
return switch (asyncValue) {
  AsyncIdle() => const Text('Not started'),
  AsyncLoading() => const CircularProgressIndicator(),
  AsyncData(:final value) => Text('Data: $value'),
  AsyncError(:final errorValue) => Text('Error: $errorValue'),
};
```

### Destructuring Values

You can destructure values directly in patterns:

```dart
return switch (userData.value) {
  AsyncData(:final value) => UserCard(user: value),
  AsyncError(:final errorValue, :final stackTrace) => ErrorWidget(
    error: errorValue,
    stackTrace: stackTrace,
  ),
  AsyncLoading() => const CircularProgressIndicator(),
  AsyncIdle() => const SizedBox.shrink(),
};
```

### Case Expressions

```dart
if (asyncValue case AsyncData(:final value)) {
  print('Got data: $value');
}

if (asyncValue case AsyncError(:final errorValue)) {
  print('Error occurred: $errorValue');
}
```

### Property-Based Checks

```dart
if (asyncValue.isLoading) {
  return const CircularProgressIndicator();
}

if (asyncValue.isData) {
  final data = asyncValue.dataOrNull;
  return Text('Data: $data');
}

if (asyncValue.hasData) {
  // Either data or error is available
  final data = asyncValue.dataOrNull;
  final error = asyncValue.errorOrNull;
}
```

## Usage with Composables

### useFuture

```dart
@override
Widget Function(BuildContext) setup() {
  final userData = useFuture(() => api.fetchUser(userId));

  return (context) {
    return switch (userData.value) {
      AsyncLoading() => const CircularProgressIndicator(),
      AsyncError(:final errorValue) => Text('Error: $errorValue'),
      AsyncData(:final value) => UserCard(user: value),
      AsyncIdle() => const SizedBox.shrink(),
    };
  };
}
```

### useAsyncData

```dart
@override
Widget Function(BuildContext) setup() {
  final userId = ref(1);

  final (status, refresh) = useAsyncData<User, int>(
    (id) => api.fetchUser(id),
    watch: () => userId.value,
  );

  return (context) {
    return switch (status.value) {
      AsyncData(:final value) => UserProfile(user: value),
      AsyncError(:final errorValue) => ErrorView(
        error: errorValue,
        onRetry: refresh,
      ),
      AsyncLoading() => const CircularProgressIndicator(),
      AsyncIdle() => ElevatedButton(
        onPressed: refresh,
        child: const Text('Load'),
      ),
    };
  };
}
```

### useAsyncValue

```dart
@override
Widget Function(BuildContext) setup() {
  final (status, refresh) = useAsyncData<String, void>(
    (_) => api.getData(),
  );

  final (data, error, loading, hasData) = useAsyncValue(status);

  return (context) {
    if (loading.value) {
      return const CircularProgressIndicator();
    }

    if (error.value != null) {
      return Text('Error: ${error.value}');
    }

    if (data.value != null) {
      return Text('Data: ${data.value}');
    }

    return const SizedBox.shrink();
  };
}
```

## Best Practices

### Use Pattern Matching

```dart
// Good - Exhaustive and type-safe
return switch (userData.value) {
  AsyncLoading() => const CircularProgressIndicator(),
  AsyncError(:final errorValue) => ErrorWidget(errorValue),
  AsyncData(:final value) => UserCard(value),
  AsyncIdle() => const SizedBox.shrink(),
};

// Avoid - Not exhaustive, error-prone
if (userData.value.isData) {
  return UserCard(userData.value.dataOrNull!);
}
return const CircularProgressIndicator();
```

### Handle All States

```dart
// Good - All states handled
return switch (status.value) {
  AsyncIdle() => const Text('Click to load'),
  AsyncLoading() => const CircularProgressIndicator(),
  AsyncData(:final value) => DataView(value),
  AsyncError(:final errorValue) => ErrorView(errorValue),
};

// Bad - Missing states
return switch (status.value) {
  AsyncData(:final value) => DataView(value),
  _ => const CircularProgressIndicator(), // Lumps idle, loading, and error together
};
```

### Provide Error Context

```dart
// Good - Full error information
return switch (userData.value) {
  AsyncError(:final errorValue, :final stackTrace) => ErrorView(
    message: errorValue.toString(),
    stackTrace: stackTrace,
    onRetry: refresh,
  ),
  // ... other states
};

// Avoid - Missing context
return switch (userData.value) {
  AsyncError(:final errorValue) => Text('Error: $errorValue'),
  // ... other states
};
```

### Use Computed for Derived States

```dart
final userData = useFuture(() => api.fetchUser());

// Computed value based on async state
final isUserAdmin = computed(() {
  return switch (userData.value) {
    AsyncData(:final value) => value.role == 'admin',
    _ => false,
  };
});

return (context) => Text('Is admin: ${isUserAdmin.value}');
```

## Common Patterns

### Loading Overlay

```dart
return Stack(
  children: [
    switch (data.value) {
      AsyncData(:final value) => DataView(value),
      AsyncError(:final errorValue) => ErrorView(errorValue),
      _ => const SizedBox.shrink(),
    },
    if (data.value.isLoading)
      Container(
        color: Colors.black26,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
  ],
);
```

### Error with Retry

```dart
return switch (data.value) {
  AsyncError(:final errorValue) => Column(
    children: [
      Text('Error: $errorValue'),
      ElevatedButton(
        onPressed: refresh,
        child: const Text('Retry'),
      ),
    ],
  ),
  AsyncData(:final value) => DataView(value),
  AsyncLoading() => const CircularProgressIndicator(),
  AsyncIdle() => const Text('Ready to load'),
};
```

### Optimistic Updates

```dart
final (status, refresh) = useAsyncData<List<Item>, void>(
  (_) => api.fetchItems(),
);

void addItem(Item item) {
  // Optimistically update
  if (status.value case AsyncData(:final value)) {
    status.value = AsyncData([...value, item]);
  }

  // Sync with server
  api.addItem(item).then(
    (_) => refresh(),
    onError: (e) {
      status.value = AsyncError(e);
    },
  );
}
```

## See Also

- [useFuture](../composables/async.md#usefuture) - Execute futures with state tracking
- [useAsyncData](../composables/async.md#useasyncdata) - Advanced async with watch support
- [useAsyncValue](../composables/async.md#useasyncvalue) - Split AsyncValue into refs
- [Pattern Matching](https://dart.dev/language/patterns) - Dart pattern matching guide
