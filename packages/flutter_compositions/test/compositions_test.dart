import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ref holds mutable values', () {
    final counter = ref(0);

    expect(counter.value, 0);

    counter.value++;

    expect(counter.value, 1);
  });

  test('writableComputed can derive and write values', () {
    final source = ref(10);

    final doubleValue = writableComputed<int>(
      get: () => source.value * 2,
      set: (int next) => source.value = next ~/ 2,
    );

    expect(doubleValue.value, 20);

    doubleValue.value = 12;

    expect(source.value, 6);
    expect(doubleValue.value, 12);
  });

  testWidgets('watch notifies on changes and stops after dispose', (
    tester,
  ) async {
    final values = <String>[];
    Ref<int>? countRef;

    await tester.pumpWidget(
      MaterialApp(
        home: WatchTestHarness(
          onValue: (value) => values.add(value),
          onCountRef: (ref) => countRef = ref,
        ),
      ),
    );

    // Initial watch with immediate: true should trigger
    expect(values, ['new:0 old:null']);

    // Change the value
    await tester.tap(find.text('Increment'));
    await tester.pump();

    expect(values, ['new:0 old:null', 'new:1 old:0']);

    // Dispose the widget (stops watching)
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    // The effectScope is disposed, so watch should be stopped
    expect(values, ['new:0 old:null', 'new:1 old:0']);

    // Change the ref externally after widget is disposed
    countRef!.value = 99;
    await tester.pump();

    // watch was disposed, so no new value should be added
    expect(values, ['new:0 old:null', 'new:1 old:0']);
  });

  testWidgets('watchEffect re-runs on dependency changes and can be disposed', (
    tester,
  ) async {
    final samples = <int>[];
    Ref<int>? countRef;

    await tester.pumpWidget(
      MaterialApp(
        home: WatchEffectTestHarness(
          onSample: (sample) => samples.add(sample),
          onCountRef: (ref) => countRef = ref,
        ),
      ),
    );

    // Initial watchEffect should run immediately
    expect(samples, [0]);

    // Change the value
    await tester.tap(find.text('Set to 3'));
    await tester.pump();

    expect(samples, [0, 3]);

    // Dispose the widget (stops watching)
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    // The effectScope is disposed, so watchEffect should be stopped
    expect(samples, [0, 3]);

    // Change the ref externally after widget is disposed
    countRef!.value = 99;
    await tester.pump();

    // watchEffect was disposed, so no new sample should be added
    expect(samples, [0, 3]);
  });

  test('read-only computed returns ReadonlyRef', () {
    final source = ref(10);
    final doubled = computed(() => source.value * 2);

    // computed() returns ReadonlyRef which doesn't have a setter
    expect(doubled, isA<ReadonlyRef<int>>());
    expect(doubled.value, 20);

    source.value = 5;
    expect(doubled.value, 10);
  });

  test('computed infers type from getter return type', () {
    final count = ref(5);
    final doubled = computed(() => count.value * 2);

    // Type should be inferred as int
    expect(doubled.value, isA<int>());
    expect(doubled.value, 10);
  });

  test('writable computed returns WritableRef', () {
    final source = ref(10);
    final doubled = writableComputed(
      get: () => source.value * 2,
      set: (int value) => source.value = value ~/ 2,
    );

    // writableComputed() returns WritableRef which has both getter and setter
    expect(doubled, isA<WritableRef<int>>());
    expect(doubled.value, 20);

    doubled.value = 30;
    expect(source.value, 15);
    expect(doubled.value, 30);
  });
}

// Test harness widgets

class WatchTestHarness extends CompositionWidget {
  const WatchTestHarness({
    required this.onValue,
    required this.onCountRef,
    super.key,
  });

  final void Function(String value) onValue;
  final void Function(Ref<int> ref) onCountRef;

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    // Expose the ref to the test
    onCountRef(count);

    // Test watch with immediate: true
    watch(
      () => count.value,
      (newValue, oldValue) {
        onValue('new:$newValue old:${oldValue ?? 'null'}');
      },
      immediate: true,
    );

    return (context) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Count: ${count.value}'),
            ElevatedButton(
              onPressed: () => count.value++,
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}

class WatchEffectTestHarness extends CompositionWidget {
  const WatchEffectTestHarness({
    required this.onSample,
    required this.onCountRef,
    super.key,
  });

  final void Function(int sample) onSample;
  final void Function(Ref<int> ref) onCountRef;

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    // Expose the ref to the test
    onCountRef(count);

    // Test watchEffect
    watchEffect(() {
      onSample(count.value);
    });

    return (context) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Count: ${count.value}'),
            ElevatedButton(
              onPressed: () => count.value = 3,
              child: const Text('Set to 3'),
            ),
          ],
        ),
      ),
    );
  }
}
