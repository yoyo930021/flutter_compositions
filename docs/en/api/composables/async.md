# Async Composables

Composables for handling asynchronous operations with reactive state tracking.

## `useFuture`

Executes a Future and tracks its state (loading/success/error).

### Signature

```dart
Ref<AsyncValue<T>> useFuture<T>(Future<T> Function() future)
```

### Parameters

- `future`: A function that returns the Future to execute

### Returns

A `Ref<AsyncValue<T>>` that tracks the operation state.

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final userData = useFuture(() => api.fetchUser(userId));

  return (context) {
    return switch (userData.value) {
      AsyncLoading() => CircularProgressIndicator(),
      AsyncError(:final errorValue) => Text('Error: $errorValue'),
      AsyncData(:final value) => UserCard(user: value),
      AsyncIdle() => SizedBox.shrink(),
    };
  };
}
```

### Lifecycle

- Future executes automatically when component mounts (in `onMounted`)
- Starts in `AsyncLoading` state
- Updates to `AsyncData` on success or `AsyncError` on failure

---

## `useAsyncData`

Advanced async operation with watch support and manual refresh.

### Signature

```dart
(
  ReadonlyRef<AsyncValue<T>> status,
  void Function() refresh,
) useAsyncData<T, W>(
  Future<T> Function(W watchValue) future, {
  W Function()? watch,
})
```

### Parameters

- `future`: Async function that receives the watch value
- `watch`: Optional function to watch for changes. When return value changes, future is re-executed

### Returns

Tuple of:
- `status`: Reactive AsyncValue tracking operation state
- `refresh`: Function to manually trigger the async operation

### Example - Basic Usage

```dart
@override
Widget Function(BuildContext) setup() {
  final (status, refresh) = useAsyncData<List<Item>, void>(
    (_) => api.fetchItems(),
  );

  return (context) => Column(
    children: [
      if (status.value case AsyncData(:final value))
        ...value.map((item) => ListTile(title: Text(item.name))),
      ElevatedButton(
        onPressed: refresh,
        child: Text('Refresh'),
      ),
    ],
  );
}
```

### Example - With Watch

```dart
@override
Widget Function(BuildContext) setup() {
  final userId = ref(1);

  // Auto-refetch when userId changes
  final (status, refresh) = useAsyncData<User, int>(
    (id) => api.fetchUser(id),
    watch: () => userId.value,
  );

  return (context) => Column(
    children: [
      if (status.value case AsyncData(:final value))
        Text('User: ${value.name}'),
      TextField(
        onChanged: (value) => userId.value = int.tryParse(value) ?? 1,
      ),
    ],
  );
}
```

### Behavior

- **Without watch**: Executes once on mount
- **With watch**: Executes on mount and whenever watch value changes
- **Concurrent execution**: Prevented - refresh() is ignored if already loading
- **Manual refresh**: Call `refresh()` to manually trigger execution

---

## `useAsyncValue`

Splits AsyncValue into individual reactive refs for easier access.

### Signature

```dart
(
  ReadonlyRef<T?> data,
  ReadonlyRef<Object?> error,
  ReadonlyRef<bool> loading,
  ReadonlyRef<bool> hasData,
) useAsyncValue<T>(ReadonlyRef<AsyncValue<T>> statusRef)
```

### Parameters

- `statusRef`: An AsyncValue ref (from `useFuture` or `useAsyncData`)

### Returns

Tuple of:
- `data`: The successful result (null if loading/error/idle)
- `error`: The error object (null if not in error state)
- `loading`: Boolean indicating if operation is in progress
- `hasData`: Boolean indicating if data or error is available

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final (status, refresh) = useAsyncData<String, void>(
    (_) => api.getData(),
  );

  final (data, error, loading, hasData) = useAsyncValue(status);

  return (context) => Column(
    children: [
      if (loading.value)
        CircularProgressIndicator(),
      if (error.value != null)
        Text('Error: ${error.value}'),
      if (data.value != null)
        Text('Data: ${data.value}'),
      ElevatedButton(
        onPressed: loading.value ? null : refresh,
        child: Text('Refresh'),
      ),
    ],
  );
}
```

---

## `useStream`

Tracks the latest value emitted by a Stream.

### Signature

```dart
Ref<T> useStream<T>(Stream<T> stream, {required T initialValue})
```

### Parameters

- `stream`: The Stream to listen to
- `initialValue`: Initial value before first emission

### Returns

A `Ref<T>` that updates with each stream emission.

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final stream = Stream.periodic(
    Duration(seconds: 1),
    (count) => count,
  );

  final count = useStream(stream, initialValue: 0);

  return (context) => Text('Count: ${count.value}');
}
```

### Lifecycle

- Stream is subscribed when component mounts
- Subscription is automatically canceled when component unmounts
- Errors are not handled - use separate error handling if needed

---

## `useStreamController`

Creates a StreamController with reactive stream tracking.

### Signature

```dart
(StreamController<T>, Ref<T>) useStreamController<T>({
  required T initialValue,
})
```

### Parameters

- `initialValue`: Initial value for the tracked stream

### Returns

Tuple of:
- `controller`: StreamController for adding events
- `stream`: Reactive Ref tracking latest stream value

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, value) = useStreamController<int>(initialValue: 0);

  return (context) => Column(
    children: [
      Text('Value: ${value.value}'),
      ElevatedButton(
        onPressed: () => controller.add(value.value + 1),
        child: Text('Increment'),
      ),
    ],
  );
}
```

### Lifecycle

- Controller is automatically closed when component unmounts
- Uses broadcast StreamController internally

---

## AsyncValue Types

### `AsyncValue<T>`

Sealed class representing async operation state.

```dart
sealed class AsyncValue<T> {
  const factory AsyncValue.idle() = AsyncIdle<T>;
  const factory AsyncValue.loading() = AsyncLoading<T>;
  const factory AsyncValue.data(T data) = AsyncData<T>;
  const factory AsyncValue.error(Object error, [StackTrace? stackTrace]) = AsyncError<T>;
}
```

### Properties

```dart
// State checks
bool get isIdle;
bool get isLoading;
bool get isData;
bool get isError;
bool get hasData; // true if data or error

// Value access (returns null if not available)
T? get dataOrNull;
Object? get errorOrNull;
StackTrace? get stackTraceOrNull;
```

### State Types

#### `AsyncIdle<T>`

No connection - operation hasn't started yet.

```dart
const idle = AsyncIdle<String>();
```

#### `AsyncLoading<T>`

Waiting for data - operation in progress.

```dart
const loading = AsyncLoading<String>();
```

#### `AsyncData<T>`

Success - operation completed with data.

```dart
final data = AsyncData('result');
print(data.value); // 'result'
```

#### `AsyncError<T>`

Failure - operation completed with error.

```dart
final error = AsyncError('Connection failed', StackTrace.current);
print(error.errorValue); // 'Connection failed'
print(error.stackTrace); // StackTrace
```

### Pattern Matching

```dart
// Exhaustive switch
return switch (asyncValue) {
  AsyncIdle() => Text('Not started'),
  AsyncLoading() => CircularProgressIndicator(),
  AsyncData(:final value) => Text('Data: $value'),
  AsyncError(:final errorValue) => Text('Error: $errorValue'),
};

// Conditional checks
if (asyncValue.isLoading) {
  return CircularProgressIndicator();
}

if (asyncValue case AsyncData(:final value)) {
  return Text('Data: $value');
}
```

---

## Best Practices

### 1. Use Pattern Matching for AsyncValue

```dart
// ✅ Good - exhaustive and type-safe
return switch (userData.value) {
  AsyncLoading() => CircularProgressIndicator(),
  AsyncError(:final errorValue) => ErrorWidget(errorValue),
  AsyncData(:final value) => UserCard(value),
  AsyncIdle() => SizedBox.shrink(),
};

// ❌ Bad - not exhaustive
if (userData.value.isData) {
  return UserCard(userData.value.dataOrNull!);
}
return CircularProgressIndicator();
```

### 2. Use `useAsyncData` with Watch for Dependent Fetches

```dart
// ✅ Good - auto-refetch on dependency change
final (status, _) = useAsyncData<User, int>(
  (id) => api.fetchUser(id),
  watch: () => userId.value,
);

// ❌ Bad - manual refetch
final status = useFuture(() => api.fetchUser(userId.value));
watch(() => userId.value, (_) {
  // Can't refetch easily
});
```

### 3. Use `useAsyncValue` for Simpler UI Logic

```dart
// ✅ Good - clear intent
final (data, error, loading, _) = useAsyncValue(status);

if (loading.value) return CircularProgressIndicator();
if (error.value != null) return ErrorWidget(error.value!);
return DataWidget(data.value!);

// ❌ Less clear
if (status.value case AsyncLoading()) return CircularProgressIndicator();
// ...
```

### 4. Prevent Concurrent Executions

```dart
// ✅ Good - useAsyncData handles this
final (status, refresh) = useAsyncData<Data, void>(
  (_) => fetchData(),
);

// Multiple refresh() calls are safe - ignored if already loading
onPressed: refresh;

// ❌ Bad - manual coordination needed
final loading = ref(false);
Future<void> fetch() async {
  if (loading.value) return;
  loading.value = true;
  // ...
}
```

---

## Error Handling

### Handle Errors in UI

```dart
return switch (userData.value) {
  AsyncError(:final errorValue, :final stackTrace) => Column(
    children: [
      Text('Error: $errorValue'),
      Text('Stack: ${stackTrace?.toString() ?? "N/A"}'),
      ElevatedButton(onPressed: refresh, child: Text('Retry')),
    ],
  ),
  // ... other states
};
```

### Log Errors with Watch

```dart
watch(
  () => userData.value,
  (newValue, _) {
    if (newValue case AsyncError(:final errorValue, :final stackTrace)) {
      logger.error('User fetch failed', errorValue, stackTrace);
      analytics.logError(errorValue);
    }
  },
);
```

---

## See Also

- [AsyncValue Types](../types/async-value.md)
- [watch, watchEffect](../watch.md)
- [useFuture example](../../guide/async-operations.md)
