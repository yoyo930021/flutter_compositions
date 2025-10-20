import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('useStream', () {
    testWidgets('tracks stream updates', (tester) async {
      final controller = StreamController<int>();

      await tester.pumpWidget(
        MaterialApp(
          home: UseStreamHarness(
            stream: controller.stream,
            initialValue: 0,
          ),
        ),
      );

      expect(find.text('Value: 0'), findsOneWidget);

      controller.add(5);
      await tester.pump(); // Process stream event
      await tester.pump(); // Process reactive update

      expect(find.text('Value: 5'), findsOneWidget);

      controller.add(10);
      await tester.pump(); // Process stream event
      await tester.pump(); // Process reactive update

      expect(find.text('Value: 10'), findsOneWidget);

      await controller.close();
    });

    testWidgets('cancels subscription on unmount', (tester) async {
      final controller = StreamController<int>.broadcast();
      var subscriptionCanceled = false;

      controller.onCancel = () {
        subscriptionCanceled = true;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: UseStreamHarness(
            stream: controller.stream,
            initialValue: 0,
          ),
        ),
      );

      expect(subscriptionCanceled, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(); // Process dispose

      expect(subscriptionCanceled, isTrue);

      await controller.close();
    });

    testWidgets('works with periodic stream', (tester) async {
      final firstTick = Completer<void>();
      final secondTick = Completer<void>();

      final stream = () async* {
        await firstTick.future;
        yield 1;
        await secondTick.future;
        yield 2;
      }();

      await tester.pumpWidget(
        MaterialApp(
          home: PeriodicStreamHarness(
            stream: stream,
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      firstTick.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      secondTick.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('Count: 2'), findsOneWidget);
    });
  });

  group('useStreamController', () {
    testWidgets('creates and tracks stream controller', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UseStreamControllerHarness(),
        ),
      );

      expect(find.text('Value: 0'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Value: 1'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Value: 2'), findsOneWidget);
    });

    testWidgets('closes controller on unmount', (tester) async {
      StreamController<int>? capturedController;

      await tester.pumpWidget(
        MaterialApp(
          home: StreamControllerLifecycleHarness(
            onController: (ctrl) => capturedController = ctrl,
          ),
        ),
      );

      expect(capturedController, isNotNull);
      expect(capturedController!.isClosed, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(capturedController!.isClosed, isTrue);
    });

    testWidgets('works with multiple listeners (broadcast)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BroadcastStreamControllerHarness(),
        ),
      );

      expect(find.text('Value1: 0'), findsOneWidget);
      expect(find.text('Value2: 0'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Value1: 1'), findsOneWidget);
      expect(find.text('Value2: 1'), findsOneWidget);
    });
  });

  group('useFuture', () {
    testWidgets('tracks future loading state', (tester) async {
      final completer = Completer<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: UseFutureHarness(
            future: () => completer.future,
          ),
        ),
      );

      // Initially loading
      expect(find.text('Loading...'), findsOneWidget);

      completer.complete('Success!');
      await tester.pump();

      // After completion
      expect(find.text('Data: Success!'), findsOneWidget);
    });

    testWidgets('tracks future error state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UseFutureHarness(
            future: () => Future.error('Test error'),
          ),
        ),
      );

      // Initially loading
      expect(find.text('Loading...'), findsOneWidget);

      await tester.pump();

      // After error
      expect(find.text('Error: Test error'), findsOneWidget);
    });

    testWidgets('executes future on mount', (tester) async {
      var futureCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: UseFutureHarness(
            future: () async {
              futureCalled = true;
              return 'Done';
            },
          ),
        ),
      );

      expect(futureCalled, isTrue);
    });

    testWidgets('AsyncValue provides correct state flags', (tester) async {
      final pendingExecutions = <Completer<void>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: AsyncValueStateFlagsHarness(
            onExecutionStart: pendingExecutions.add,
          ),
        ),
      );

      // Initially loading
      expect(find.text('isLoading: true'), findsOneWidget);
      expect(find.text('isSuccess: false'), findsOneWidget);
      expect(find.text('isError: false'), findsOneWidget);
      expect(pendingExecutions, hasLength(1));

      pendingExecutions.removeAt(0).complete();
      await tester.pump();
      await tester.pump();

      // After success
      expect(find.text('isLoading: false'), findsOneWidget);
      expect(find.text('isSuccess: true'), findsOneWidget);
      expect(find.text('isError: false'), findsOneWidget);
    });

    testWidgets('supports manual refresh', (tester) async {
      final pendingFetches = <Completer<void>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: RefreshableFutureHarness(
            onFetch: pendingFetches.add,
          ),
        ),
      );

      // Initial load
      expect(find.text('Loading...'), findsOneWidget);
      expect(pendingFetches, hasLength(1));

      pendingFetches.removeAt(0).complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      // Tap refresh button
      await tester.tap(find.text('Refresh'));
      await tester.pump();
      expect(find.text('Loading...'), findsOneWidget);
      expect(pendingFetches, hasLength(1));

      pendingFetches.removeAt(0).complete();
      await tester.pump();
      await tester.pump();

      // Should have new value
      expect(find.text('Count: 2'), findsOneWidget);
    });
  });

  group('useAsyncData', () {
    testWidgets('executes automatically on mount', (tester) async {
      var executed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: UseAsyncDataHarness(
            future: () async {
              executed = true;
              return 'result';
            },
          ),
        ),
      );

      // Should execute on mount
      await tester.pump();
      expect(executed, isTrue);
      expect(find.text('Data: result'), findsOneWidget);
    });

    testWidgets('re-executes when watch function changes', (tester) async {
      final pendingExecutions = <Completer<void>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UseAsyncDataReactiveHarness(
              onExecutionStart: pendingExecutions.add,
            ),
          ),
        ),
      );

      // Initial execution on mount - watchEffect triggers immediately
      await tester.pump();
      await tester.pump(); // Extra pump for watchEffect
      expect(find.text('Loading: true'), findsOneWidget);
      expect(pendingExecutions, hasLength(1));

      // Complete first execution
      pendingExecutions.removeAt(0).complete();
      await tester.pump();
      await tester.pump();
      await tester.pump(); // Extra pump for state updates

      // Give microtasks time to complete
      await tester.pumpAndSettle();

      expect(find.text('Data: User 1'), findsOneWidget);
      expect(find.text('Loading: false'), findsOneWidget);

      // Change userId - should trigger re-execution
      await tester.tap(find.text('Change User'));
      await tester.pump();
      await tester.pump(); // Extra pump for watch effect
      await tester.pump(); // Extra pump for async operation start

      expect(find.text('Loading: true'), findsOneWidget);
      expect(pendingExecutions, hasLength(1));

      // Complete second execution
      pendingExecutions.removeAt(0).complete();
      await tester.pump();
      await tester.pump();
      await tester.pump(); // Extra pump for state updates
      await tester.pumpAndSettle(); // Give microtasks time to complete

      expect(find.text('Data: User 2'), findsOneWidget);
      expect(find.text('Loading: false'), findsOneWidget);
    });

    testWidgets('provides status with AsyncValue', (tester) async {
      final pendingExecutions = <Completer<void>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: UseAsyncDataStatusHarness(
            onExecutionStart: pendingExecutions.add,
          ),
        ),
      );

      // Initially idle, then loading on mount
      await tester.pump();
      expect(find.textContaining('Status: AsyncLoading'), findsOneWidget);
      expect(pendingExecutions, hasLength(1));

      pendingExecutions.removeAt(0).complete();
      await tester.pump();
      await tester.pump();

      // Should have data status
      expect(find.textContaining('Status: AsyncData'), findsOneWidget);
    });

    testWidgets('provides error state on failure', (tester) async {
      final pendingExecutions = <Completer<void>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: UseAsyncDataErrorHarness(
            onExecutionStart: pendingExecutions.add,
          ),
        ),
      );

      await tester.pump();
      expect(pendingExecutions, hasLength(1));

      pendingExecutions.removeAt(0).complete();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Error: Test error'), findsOneWidget);
      expect(find.textContaining('Status: AsyncError'), findsOneWidget);
    });

    testWidgets('prevents concurrent executions', (tester) async {
      var executionCount = 0;
      final pendingExecutions = <Completer<void>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: UseAsyncDataConcurrentHarness(
            onExecute: () => executionCount++,
            onExecutionStart: pendingExecutions.add,
          ),
        ),
      );

      // Initial execution on mount
      await tester.pump();
      expect(executionCount, 1);
      expect(pendingExecutions, hasLength(1));

      // Tap refresh multiple times rapidly while loading
      await tester.tap(find.text('Refresh'));
      await tester.tap(find.text('Refresh'));
      await tester.pump();

      // Should still only be 1 execution
      expect(executionCount, 1);
      expect(pendingExecutions, hasLength(1));

      pendingExecutions.removeAt(0).complete();
      await tester.pump();

      // After completion, should be able to execute again
      await tester.tap(find.text('Refresh'));
      await tester.pump();

      expect(executionCount, 2);
      expect(pendingExecutions, hasLength(1));

      pendingExecutions.removeAt(0).complete();
      await tester.pump();
    });
  });

  group('AsyncValue', () {
    test('idle state', () {
      const value = AsyncValue<int>.idle();
      expect(value, isA<AsyncIdle<int>>());
      expect(value.isIdle, isTrue);
      expect(value.isLoading, isFalse);
      expect(value.isData, isFalse);
      expect(value.isError, isFalse);
      expect(value.dataOrNull, isNull);
      expect(value.errorOrNull, isNull);
    });

    test('loading state', () {
      const value = AsyncValue<int>.loading();
      expect(value, isA<AsyncLoading<int>>());
      expect(value.isLoading, isTrue);
      expect(value.isIdle, isFalse);
      expect(value.isData, isFalse);
      expect(value.isError, isFalse);
      expect(value.dataOrNull, isNull);
      expect(value.errorOrNull, isNull);
    });

    test('data state', () {
      const value = AsyncValue.data(42);
      expect(value, isA<AsyncData<int>>());
      expect(value.isData, isTrue);
      expect(value.isIdle, isFalse);
      expect(value.isLoading, isFalse);
      expect(value.isError, isFalse);
      expect(value.dataOrNull, 42);
      expect(value.errorOrNull, isNull);
      expect(value.hasData, isTrue);
    });

    test('error state', () {
      const value = AsyncValue<int>.error('Test error');
      expect(value, isA<AsyncError<int>>());
      expect(value.isError, isTrue);
      expect(value.isIdle, isFalse);
      expect(value.isLoading, isFalse);
      expect(value.isData, isFalse);
      expect(value.dataOrNull, isNull);
      expect(value.errorOrNull, 'Test error');
      expect(value.hasData, isTrue);
    });

    test('pattern matching works', () {
      const AsyncValue<int> value = AsyncData(42);

      final result = switch (value) {
        AsyncIdle() => 'idle',
        AsyncLoading() => 'loading',
        AsyncData(:final value) => 'data: $value',
        AsyncError(:final errorValue) => 'error: $errorValue',
      };

      expect(result, 'data: 42');
    });
  });
}

// ---------------------------------------------------------------------------
// Harness widgets
// ---------------------------------------------------------------------------

class UseStreamHarness extends CompositionWidget {
  const UseStreamHarness({
    required this.stream,
    required this.initialValue,
    super.key,
  });

  final Stream<int> stream;
  final int initialValue;

  @override
  Widget Function(BuildContext) setup() {
    final value = useStream(stream, initialValue: initialValue);

    return (context) => Text('Value: ${value.value}');
  }
}

class PeriodicStreamHarness extends CompositionWidget {
  const PeriodicStreamHarness({
    required Stream<int> stream,
    super.key,
  }) : _stream = stream;

  final Stream<int> _stream;

  @override
  Widget Function(BuildContext) setup() {
    final count = useStream(_stream, initialValue: 0);

    return (context) => Text('Count: ${count.value}');
  }
}

class UseStreamControllerHarness extends CompositionWidget {
  const UseStreamControllerHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controller, stream) = useStreamController<int>(initialValue: 0);

    return (context) => Column(
      children: [
        Text('Value: ${stream.value}'),
        ElevatedButton(
          onPressed: () => controller.add(stream.value + 1),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class StreamControllerLifecycleHarness extends CompositionWidget {
  const StreamControllerLifecycleHarness({
    required this.onController,
    super.key,
  });

  final void Function(StreamController<int> controller) onController;

  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useStreamController<int>(initialValue: 0);

    onMounted(() => onController(controller));

    return (context) => const SizedBox();
  }
}

class BroadcastStreamControllerHarness extends CompositionWidget {
  const BroadcastStreamControllerHarness({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controller, stream) = useStreamController<int>(initialValue: 0);

    // Subscribe twice to test broadcast
    final value1 = useStream(controller.stream, initialValue: 0);
    final value2 = useStream(controller.stream, initialValue: 0);

    return (context) => Column(
      children: [
        Text('Value1: ${value1.value}'),
        Text('Value2: ${value2.value}'),
        ElevatedButton(
          onPressed: () => controller.add(stream.value + 1),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class UseFutureHarness extends CompositionWidget {
  const UseFutureHarness({
    required this.future,
    super.key,
  });

  final Future<String> Function() future;

  @override
  Widget Function(BuildContext) setup() {
    final data = useFuture(future);

    return (context) {
      return switch (data.value) {
        AsyncLoading() => const Text('Loading...'),
        AsyncError(:final errorValue) => Text('Error: $errorValue'),
        AsyncData(:final value) => Text('Data: $value'),
        AsyncIdle() => const SizedBox.shrink(),
      };
    };
  }
}

class AsyncValueStateFlagsHarness extends CompositionWidget {
  const AsyncValueStateFlagsHarness({
    required this.onExecutionStart,
    super.key,
  });

  final void Function(Completer<void> completer) onExecutionStart;

  @override
  Widget Function(BuildContext) setup() {
    final data = useFuture(() async {
      final completer = Completer<void>();
      onExecutionStart(completer);
      await completer.future;
      return 'Done';
    });

    return (context) {
      final value = data.value;

      return Column(
        children: [
          Text('isLoading: ${value.isLoading}'),
          Text('isSuccess: ${value.isData}'),
          Text('isError: ${value.isError}'),
          Text('isIdle: ${value.isIdle}'),
        ],
      );
    };
  }
}

// ---------------------------------------------------------------------------
// Harness widgets - useAsyncData
// ---------------------------------------------------------------------------

class UseAsyncDataHarness extends CompositionWidget {
  const UseAsyncDataHarness({
    required this.future,
    super.key,
  });

  final Future<String> Function() future;

  @override
  Widget Function(BuildContext) setup() {
    final (status, refresh) = useAsyncData<String, void>(
      (_) => future(),
    );
    final (data, error, loading, hasData) = useAsyncValue(status);

    return (context) => Column(
      children: [
        Text('Data: ${data.value}'),
        Text('Loading: ${loading.value}'),
        Text('Error: ${error.value}'),
      ],
    );
  }
}

class UseAsyncDataReactiveHarness extends CompositionWidget {
  const UseAsyncDataReactiveHarness({
    required this.onExecutionStart,
    super.key,
  });

  final void Function(Completer<void> completer) onExecutionStart;

  @override
  Widget Function(BuildContext) setup() {
    final userId = ref(1);

    final (status, refresh) = useAsyncData<String, int>(
      (id) async {
        final completer = Completer<void>();
        onExecutionStart(completer);
        await completer.future;
        return 'User $id';
      },
      watch: () => userId.value,
    );
    final (data, _, loading, hasData) = useAsyncValue(status);

    return (context) => Column(
      children: [
        Text('Data: ${data.value}'),
        Text('Loading: ${loading.value}'),
        TextButton(
          onPressed: () => userId.value++,
          child: const Text('Change User'),
        ),
      ],
    );
  }
}

class UseAsyncDataStatusHarness extends CompositionWidget {
  const UseAsyncDataStatusHarness({
    required this.onExecutionStart,
    super.key,
  });

  final void Function(Completer<void> completer) onExecutionStart;

  @override
  Widget Function(BuildContext) setup() {
    final (status, refresh) = useAsyncData<String, void>(
      (_) async {
        final completer = Completer<void>();
        onExecutionStart(completer);
        await completer.future;
        return 'Done';
      },
    );
    final (data, _, loading, hasData) = useAsyncValue(status);

    return (context) => Column(
      children: [
        Text('Status: ${status.value.runtimeType}'),
        Text('Data: ${data.value}'),
      ],
    );
  }
}

class UseAsyncDataErrorHarness extends CompositionWidget {
  const UseAsyncDataErrorHarness({
    required this.onExecutionStart,
    super.key,
  });

  final void Function(Completer<void> completer) onExecutionStart;

  @override
  Widget Function(BuildContext) setup() {
    final (status, refresh) = useAsyncData<String, void>(
      (_) async {
        final completer = Completer<void>();
        onExecutionStart(completer);
        await completer.future;
        // ignore: only_throw_errors
        throw 'Test error';
      },
    );
    final (_, error, loading, hasData) = useAsyncValue(status);

    return (context) => Column(
      children: [
        Text('Error: ${error.value}'),
        Text('Status: ${status.value.runtimeType}'),
      ],
    );
  }
}

class UseAsyncDataConcurrentHarness extends CompositionWidget {
  const UseAsyncDataConcurrentHarness({
    required this.onExecute,
    required this.onExecutionStart,
    super.key,
  });

  final VoidCallback onExecute;
  final void Function(Completer<void> completer) onExecutionStart;

  @override
  Widget Function(BuildContext) setup() {
    final (status, refresh) = useAsyncData<String, void>(
      (_) async {
        onExecute();
        final completer = Completer<void>();
        onExecutionStart(completer);
        await completer.future;
        return 'Done';
      },
    );

    return (context) => Column(
      children: [
        TextButton(
          onPressed: refresh,
          child: const Text('Refresh'),
        ),
      ],
    );
  }
}

class RefreshableFutureHarness extends CompositionWidget {
  const RefreshableFutureHarness({
    required this.onFetch,
    super.key,
  });

  final void Function(Completer<void> completer) onFetch;

  @override
  Widget Function(BuildContext) setup() {
    var callCount = 0;

    Future<int> fetchData() async {
      callCount++;
      final completer = Completer<void>();
      onFetch(completer);
      await completer.future;
      return callCount;
    }

    final data = useFuture(fetchData);

    Future<void> refresh() async {
      data.value = const AsyncValue.loading();
      await fetchData().then(
        (result) {
          data.value = AsyncValue.data(result);
        },
        onError: (Object e, StackTrace s) {
          data.value = AsyncValue.error(e, s);
        },
      );
    }

    return (context) {
      return switch (data.value) {
        AsyncLoading() => const Text('Loading...'),
        AsyncData(:final value) => Column(
          children: [
            Text('Count: $value'),
            TextButton(
              onPressed: refresh,
              child: const Text('Refresh'),
            ),
          ],
        ),
        _ => Column(
          children: [
            TextButton(
              onPressed: refresh,
              child: const Text('Refresh'),
            ),
          ],
        ),
      };
    };
  }
}
