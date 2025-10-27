# 測試指南

本指南介紹開發 Flutter Compositions 應用程式時的測試策略，涵蓋組合式函式、Widget、整合測試、非同步流程以及依賴注入的模擬技巧。

## 目錄

1. [測試組合式函式](#測試組合式函式)
2. [Widget 測試](#widget-測試)
3. [模擬依賴](#模擬依賴)
4. [測試非同步操作](#測試非同步操作)
5. [測試範式](#測試範式)
6. [最佳實務](#最佳實務)

## 測試組合式函式

組合式函式可脫離 Widget 獨立測試，讓邏輯驗證更簡潔。

### 基本測試

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

void main() {
  group('useCounter', () {
    test('初始化數值', () {
      final (count, increment) = useCounter(initialValue: 5);

      expect(count.value, 5);
    });

    test('遞增計數', () {
      final (count, increment) = useCounter(initialValue: 0);

      increment();
      expect(count.value, 1);

      increment();
      expect(count.value, 2);
    });

    test('遞減計數', () {
      final (count, increment, decrement) = useCounter(initialValue: 10);

      decrement();
      expect(count.value, 9);
    });
  });
}

// 範例組合式函式
(Ref<int>, void Function(), void Function()) useCounter({int initialValue = 0}) {
  final count = ref(initialValue);

  void increment() => count.value++;
  void decrement() => count.value--;

  return (count, increment, decrement);
}
```

### 測試 watch 行為

```dart
test('值變更時應觸發 watch 回呼', () async {
  final values = <int>[];
  final count = ref(0);

  watch(() => count.value, (newValue, oldValue) {
    values.add(newValue);
  });

  count.value = 1;
  count.value = 2;
  count.value = 3;

  await Future.delayed(Duration.zero);

  expect(values, [1, 2, 3]);
});
```

### 測試 computed

```dart
test('依賴變更時應重新計算', () {
  final firstName = ref('John');
  final lastName = ref('Doe');

  final fullName = computed(() => '${firstName.value} ${lastName.value}');

  expect(fullName.value, 'John Doe');

  firstName.value = 'Jane';
  expect(fullName.value, 'Jane Doe');

  lastName.value = 'Smith';
  expect(fullName.value, 'Jane Smith');
});
```

## Widget 測試

### 測試 CompositionWidget

使用 Flutter 標準的 widget 測試工具：

```dart
testWidgets('按下按鈕後計數遞增', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: CounterPage()),
  );

  expect(find.text('0'), findsOneWidget);
  expect(find.text('1'), findsNothing);

  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();

  expect(find.text('0'), findsNothing);
  expect(find.text('1'), findsOneWidget);
});
```

### 測試響應式 props

```dart
testWidgets('props 改變時應更新 UI', (tester) async {
  Future<void> buildWidget(String name) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserGreeting(username: name),
      ),
    );
  }

  await buildWidget('Alice');
  expect(find.text('Hello, Alice!'), findsOneWidget);

  await buildWidget('Bob');
  await tester.pump();
  expect(find.text('Hello, Bob!'), findsOneWidget);
});

class UserGreeting extends CompositionWidget {
  final String username;
  const UserGreeting({required this.username});

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    final greeting = computed(() => 'Hello, ${props.value.username}!');
    return (context) => Text(greeting.value);
  }
}
```

### 使用 CompositionBuilder

```dart
testWidgets('透過 CompositionBuilder 測試', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CompositionBuilder(
        setup: () {
          final count = ref(0);

          return (context) => Scaffold(
            body: Center(child: Text('${count.value}')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => count.value++,
              child: Icon(Icons.add),
            ),
          );
        },
      ),
    ),
  );

  expect(find.text('0'), findsOneWidget);

  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump();

  expect(find.text('1'), findsOneWidget);
});
```

## 模擬依賴

### 使用 InjectionKey

```dart
class FakeApiService implements ApiService {
  @override
  Future<User> fetchUser() async => User('Mock');
}

testWidgets('可注入模擬服務', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CompositionBuilder(
        setup: () {
          provide(apiServiceKey, FakeApiService());

          return (context) => UserProfile();
        },
      ),
    ),
  );

  await tester.pump();
  expect(find.text('Mock'), findsOneWidget);
});
```

### 使用 mocktail / Mockito

```dart
class MockRepository extends Mock implements UserRepository {}

test('可模擬 repository', () async {
  final repo = MockRepository();
  when(() => repo.fetchUsers()).thenAnswer(
    (_) async => [User('Alice')],
  );

  final (status, refresh) = useAsyncData<List<User>, void>(
    (_) => repo.fetchUsers(),
  );

  await refresh();
  expect(status.value, isA<AsyncData<List<User>>>());
});
```

## 測試非同步操作

### 測試 `useAsyncData`

```dart
test('useAsyncData 可重新整理資料', () async {
  var callCount = 0;
  final (status, refresh) = useAsyncData<int, void>(
    (_) async {
      callCount++;
      return 42;
    },
  );

  await refresh();
  expect(status.value, AsyncData(42));
  expect(callCount, 1);

  await refresh();
  expect(callCount, 2);
});
```

### 測試 `useAsyncValue`

```dart
test('useAsyncValue 會拆解 AsyncValue', () async {
  final status = ref<AsyncValue<int>>(const AsyncValue.loading());
  final (data, error, loading, hasData) = useAsyncValue(status);

  expect(loading.value, true);

  status.value = const AsyncValue.data(10);
  await Future.delayed(Duration.zero);

  expect(data.value, 10);
  expect(hasData.value, true);
});
```

## 測試範式

### 1. `pump` 與 `pumpAndSettle`

- `pump()`：觸發一次 rebuild。
- `pumpAndSettle()`：等待所有動畫/非同步操作完成，適合測試 loading→完成 的流程。

### 2. 使用 `async` 與 `await`

- 測試非同步組合式函式時，記得 `await` `refresh()` 或 `Future.delayed(Duration.zero)`。
- 測試 widget 非同步流程時，使用 `tester.runAsync` 包裹。

### 3. Keep it pure

- 組合式函式應保持純粹、副作用集中在 `watch` 或生命週期掛勾，讓測試更容易。

## 最佳實務

1. **先測組合式函式，再測 Widget**：邏輯與 UI 分開驗證。
2. **使用依賴注入**：透過 `provide` / `inject` 替換實作，方便模擬。
3. **拆解非同步狀態**：搭配 `AsyncValue` 與 `useAsyncValue` 取得更清晰的判斷條件。
4. **保持測試獨立性**：每個測試獨立建立組合式函式、重設狀態。
5. **善用測試工具**：`pump`, `pumpAndSettle`, `runAsync`, `fakeAsync` 等可因應不同情境。

只要遵循上述原則，便能建立穩定、易於維護的 Flutter Compositions 測試流程。
