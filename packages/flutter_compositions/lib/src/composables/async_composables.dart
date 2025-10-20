import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/src/framework.dart';
import 'package:flutter_compositions/src/framework.dart' as fw;

/// Creates a reactive reference that tracks a Stream's latest value.
///
/// The returned [Ref] will update its value whenever the stream emits a new
/// value. The stream is automatically canceled when the component unmounts.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final stream = Stream.periodic(
///     const Duration(seconds: 1),
///     (count) => count,
///   );
///
///   final count = useStream(stream, initialValue: 0);
///
///   return (context) => Text('Count: ${count.value}');
/// }
/// ```
///
/// Example with error handling:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final stream = fetchDataStream();
///   final data = useStream<String?>(stream, initialValue: null);
///   final error = ref<Object?>(null);
///
///   // Handle errors
///   stream.listen(
///     (_) {},
///     onError: (e) => error.value = e,
///   );
///
///   return (context) {
///     if (error.value != null) {
///       return Text('Error: ${error.value}');
///     }
///     return Text('Data: ${data.value ?? "Loading..."}');
///   };
/// }
/// ```
Ref<T> useStream<T>(Stream<T> stream, {required T initialValue}) {
  final value = ref<T>(initialValue);

  late StreamSubscription<T> subscription;

  // Subscribe to the stream
  subscription = stream.listen(
    (newValue) {
      value.value = newValue;
    },
    // Errors are not handled here - use watch() or listen separately for errors
  );

  // Cancel subscription on unmount
  onUnmounted(() {
    unawaited(subscription.cancel());
  });

  return value;
}

/// Creates a StreamController with automatic lifecycle management.
///
/// Returns a tuple of `(controller, stream)` where:
/// - controller: StreamController for adding events
/// - stream: Reactive Ref that tracks the latest stream value
///
/// The controller is automatically closed when the component unmounts.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final (controller, stream) = useStreamController<int>(initialValue: 0);
///
///   return (context) => Column(
///     children: [
///       Text('Value: ${stream.value}'),
///       ElevatedButton(
///         onPressed: () => controller.add(stream.value + 1),
///         child: const Text('Increment'),
///       ),
///     ],
///   );
/// }
/// ```
(StreamController<T>, Ref<T>) useStreamController<T>({
  required T initialValue,
}) {
  final controller = StreamController<T>.broadcast();
  final stream = useStream(controller.stream, initialValue: initialValue);

  onUnmounted(controller.close);

  return (controller, stream);
}

/// Result of an async operation tracked by [useFuture].
///
/// This is a sealed class similar to [AsyncSnapshot] with four possible states:
/// - [AsyncIdle]: No connection, no data
/// - [AsyncLoading]: Waiting for data
/// - [AsyncData]: Has data
/// - [AsyncError]: Has error
///
/// Unlike [AsyncSnapshot], this is a sealed class that enables exhaustive
/// pattern matching.
sealed class AsyncValue<T> {
  const AsyncValue();

  /// Creates an idle state (no connection).
  const factory AsyncValue.idle() = AsyncIdle<T>;

  /// Creates a loading state (waiting).
  const factory AsyncValue.loading() = AsyncLoading<T>;

  /// Creates a data state with the result.
  const factory AsyncValue.data(T data) = AsyncData<T>;

  /// Creates an error state.
  const factory AsyncValue.error(Object error, [StackTrace? stackTrace]) =
      AsyncError<T>;

  /// Whether the operation hasn't started yet.
  bool get isIdle => this is AsyncIdle<T>;

  /// Whether the operation is in progress (ConnectionState.waiting).
  bool get isLoading => this is AsyncLoading<T>;

  /// Whether the operation completed successfully (ConnectionState.done with
  /// data).
  bool get isData => this is AsyncData<T>;

  /// Whether the operation failed (has error).
  bool get isError => this is AsyncError<T>;

  /// Returns the data if available, null otherwise.
  T? get dataOrNull => switch (this) {
    AsyncData<T>(:final value) => value,
    _ => null,
  };

  /// Returns the error if available, null otherwise.
  Object? get errorOrNull => switch (this) {
    AsyncError<T>(:final errorValue) => errorValue,
    _ => null,
  };

  /// Returns the stack trace if available, null otherwise.
  StackTrace? get stackTraceOrNull => switch (this) {
    AsyncError<T>(:final stackTrace) => stackTrace,
    _ => null,
  };

  /// Whether there is data or error available.
  bool get hasData => isData || isError;
}

/// Idle state - no connection, no data.
///
/// Corresponds to [ConnectionState.none].
final class AsyncIdle<T> extends AsyncValue<T> {
  /// Creates an idle state.
  const AsyncIdle();
}

/// Loading state - waiting for data.
///
/// Corresponds to [ConnectionState.waiting].
final class AsyncLoading<T> extends AsyncValue<T> {
  /// Creates a loading state.
  const AsyncLoading();
}

/// Data state - operation completed successfully.
///
/// Corresponds to [ConnectionState.done] with data.
final class AsyncData<T> extends AsyncValue<T> {
  /// Creates a data state with the result.
  const AsyncData(this.value);

  /// The successful result data.
  final T value;
}

/// Error state - operation failed.
///
/// Corresponds to [ConnectionState.done] with error.
final class AsyncError<T> extends AsyncValue<T> {
  /// Creates an error state with the error and optional stack trace.
  const AsyncError(this.errorValue, [this.stackTrace]);

  /// The error that occurred.
  final Object errorValue;

  /// The stack trace of the error, if available.
  final StackTrace? stackTrace;
}

/// Creates a reactive reference that tracks a Future's state and result.
///
/// Unlike [useStream], this provides access to loading/error states.
/// The future is executed when the component mounts.
///
/// Returns a [Ref] containing an [AsyncValue] that tracks the operation state.
///
/// Example with pattern matching (recommended):
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final userData = useFuture(() => fetchUserData(userId));
///
///   return (context) {
///     return switch (userData.value) {
///       AsyncLoading() => const CircularProgressIndicator(),
///       AsyncError(:final errorValue) => Text('Error: $errorValue'),
///       AsyncData(:final value) => Text('User: ${value.name}'),
///       AsyncIdle() => const SizedBox.shrink(),
///     };
///   };
/// }
/// ```
///
/// Example with is-checks and safe property access:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final userData = useFuture(() => fetchUserData(userId));
///
///   return (context) {
///     final snapshot = userData.value;
///
///     if (snapshot.isLoading) {
///       return const CircularProgressIndicator();
///     }
///
///     if (snapshot.isError) {
///       return Text('Error: ${snapshot.errorOrNull}');
///     }
///
///     if (snapshot.isData) {
///       return Text('User: ${snapshot.dataOrNull?.name}');
///     }
///
///     return const SizedBox.shrink();
///   };
/// }
/// ```
///
/// Example with manual refresh:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   Future<String> fetchData() => api.getData();
///
///   final data = useFuture(fetchData);
///
///   void refresh() {
///     data.value = const AsyncValue.loading();
///     fetchData().then(
///       (result) => data.value = AsyncValue.data(result),
///       onError: (e, s) => data.value = AsyncValue.error(e, s),
///     );
///   }
///
///   return (context) => Column(
///     children: [
///       if (data.value case AsyncData(:final value))
///         Text('Data: $value'),
///       ElevatedButton(
///         onPressed: refresh,
///         child: const Text('Refresh'),
///       ),
///     ],
///   );
/// }
/// ```
Ref<AsyncValue<T>> useFuture<T>(Future<T> Function() future) {
  final value = ref<AsyncValue<T>>(const AsyncValue.loading());

  // Execute the future on mount
  onMounted(() async {
    await future().then(
      (result) {
        value.value = AsyncValue.data(result);
      },
      onError: (Object error, StackTrace stackTrace) {
        value.value = AsyncValue.error(error, stackTrace);
      },
    );
  });

  return value;
}

/// Creates a reactive async operation that re-executes when watch function
/// changes.
///
/// Unlike [useFuture], this composable:
/// 1. Tracks changes in the watch function
/// 2. Automatically re-executes when watch function returns different value
/// 3. Passes watch value to the future function (if watch provided)
/// 4. Provides manual `refresh` function for triggering
/// 5. Returns detailed status and loading state
///
/// Type Parameters:
/// - `T`: The type of data returned by the future
/// - `W`: The type of value returned by the watch function (defaults to void)
///
/// Parameters:
/// - `future`: The async function to execute. Receives watch value if watch
///   function is provided
/// - `watch`: Optional function that returns a value to watch. When the
///   returned value changes, the future is automatically re-executed with the
///   new value
///
/// Returns a tuple of:
/// - `status`: Reactive AsyncValue with full state (idle/loading/data/error)
/// - `loading`: Reactive boolean indicating if operation is in progress
/// - `refresh`: Function to manually trigger the async operation
///
/// Example with watch function:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final userId = ref(1);
///
///   final (status, loading, refresh) = useAsyncData<User, int>(
///     (id) => api.fetchUser(id), // Receives userId
///     watch: () => userId.value, // Re-executes when userId changes
///   );
///
///   return (context) => Column(
///     children: [
///       if (loading.value)
///         const CircularProgressIndicator()
///       else if (status.value case AsyncData(:final value))
///         Text('User: ${value.name}'),
///       TextField(
///         onChanged: (value) => userId.value = int.parse(value),
///       ),
///     ],
///   );
/// }
/// ```
///
/// Example without watch (executes once on mount):
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final (status, loading, refresh) = useAsyncData<String, void>(
///     (_) => fetchData(),
///   );
///
///   return (context) {
///     return switch (status.value) {
///       AsyncLoading() => const CircularProgressIndicator(),
///       AsyncError(:final errorValue) => Text('Error: $errorValue'),
///       AsyncData(:final value) => Text('Data: $value'),
///       AsyncIdle() => ElevatedButton(
///           onPressed: refresh,
///           child: const Text('Load'),
///         ),
///     };
///   };
/// }
/// ```
///
/// Example with manual refresh:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final (status, loading, refresh) = useAsyncData<List<Item>, void>(
///     (_) => api.fetchItems(),
///   );
///
///   return (context) => Column(
///     children: [
///       if (status.value case AsyncData(:final value))
///         ...value.map((item) => ListTile(title: Text(item.name))),
///       ElevatedButton(
///         onPressed: loading.value ? null : refresh,
///         child: const Text('Refresh'),
///       ),
///     ],
///   );
/// }
/// ```
(ReadonlyRef<AsyncValue<T>> status, void Function() refresh) useAsyncData<T, W>(
  Future<T> Function(W watchValue) future, {
  W Function()? watch,
}) {
  final statusRef = ref<AsyncValue<T>>(const AsyncValue.idle());

  Future<void> refresh() async {
    if (statusRef.value.isLoading) return; // Prevent concurrent executions

    statusRef.value = const AsyncValue.loading();

    final watchValue = watch != null ? watch() : null as W;

    await future(watchValue).then(
      (result) {
        statusRef.value = AsyncValue.data(result);
      },
      onError: (Object error, StackTrace stackTrace) {
        statusRef.value = AsyncValue.error(error, stackTrace);
      },
    );
  }

  // Watch the function and re-execute when it changes
  if (watch != null) {
    final watchFn = watch; // Capture to avoid shadowing
    // Use watch API to track value changes and trigger refresh
    fw.watch(watchFn, (newVal, oldVal) {
      // Only refresh if value actually changed
      // This prevents infinite loops when watch source is re-evaluated
      if (newVal != oldVal) {
        // Don't await here - refresh updates statusRef asynchronously
        unawaited(refresh());
      }
    });

    // Execute once on mount for initial load
    onMounted(refresh);
  } else {
    // Execute once on mount if no watch function provided
    onMounted(refresh);
  }

  return (statusRef, refresh);
}

/// Creates separate reactive refs for data, error, and status
/// from an AsyncValue.
///
/// This is a convenience composable that splits an [AsyncValue] into individual
/// reactive references for easier access to data, error, and the full status.
///
/// Returns a tuple of:
/// - `data`: Reactive reference to the result data (null if not available)
/// - `error`: Reactive reference to the error (null if no error)
/// - `status`: The original AsyncValue ref
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final statusRef = useFuture(() => fetchUserData());
///   final (data, error, status) = useAsyncValue(statusRef);
///
///   return (context) => Column(
///     children: [
///       if (error.value != null)
///         Text('Error: ${error.value}')
///       else if (data.value != null)
///         Text('User: ${data.value!.name}')
///       else
///         const CircularProgressIndicator(),
///     ],
///   );
/// }
/// ```
///
/// Example with useAsyncData:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final (statusRef, loading, refresh) = useAsyncData<String>(
///     () => api.getData(),
///   );
///   final (data, error, status) = useAsyncValue(statusRef);
///
///   return (context) => Column(
///     children: [
///       if (error.value != null)
///         Text('Error: ${error.value}'),
///       if (data.value != null)
///         Text('Data: ${data.value}'),
///       ElevatedButton(
///         onPressed: loading.value ? null : refresh,
///         child: const Text('Refresh'),
///       ),
///     ],
///   );
/// }
/// ```
(
  ReadonlyRef<T?> data,
  ReadonlyRef<Object?> error,
  ReadonlyRef<bool> loading,
  ReadonlyRef<bool> hasData,
)
useAsyncValue<T>(ReadonlyRef<AsyncValue<T>> statusRef) {
  final dataRef = computed(() => statusRef.value.dataOrNull);
  final errorRef = computed(() => statusRef.value.errorOrNull);
  final loadingRef = computed(() => statusRef.value.isLoading);
  final hasDataRef = computed(() => statusRef.value.hasData);

  return (dataRef, errorRef, loadingRef, hasDataRef);
}
