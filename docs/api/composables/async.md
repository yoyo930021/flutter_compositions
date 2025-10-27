# 非同步組合式函式

用於處理非同步操作並追蹤其響應式狀態的組合式函式。

## `useFuture`

執行 Future 並追蹤其狀態（載入/成功/失敗）。

### 方法簽章

```dart
Ref<AsyncValue<T>> useFuture<T>(Future<T> Function() future)
```

### 參數

- `future`：回傳要執行之 Future 的函式

### 回傳值

`Ref<AsyncValue<T>>`，負責追蹤操作狀態。

### 範例

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

### 生命週期

- 元件掛載時（`onMounted`）自動執行 Future
- 初始狀態為 `AsyncLoading`
- 成功時轉換為 `AsyncData`，失敗時變為 `AsyncError`

---

## `useAsyncData`

進階非同步操作，支援 watch 與手動更新。

### 方法簽章

```dart
(
  ReadonlyRef<AsyncValue<T>> status,
  void Function() refresh,
) useAsyncData<T, W>(
  Future<T> Function(W watchValue) future, {
  W Function()? watch,
})
```

### 參數

- `future`：接受 watch 值的非同步函式
- `watch`：可選的監看函式，其回傳值變更時會重新執行 future

### 回傳值

包含以下項目的元組：
- `status`：追蹤操作狀態的 AsyncValue
- `refresh`：手動重新執行的函式

### 範例：基本使用

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

### 範例：搭配 watch

```dart
@override
Widget Function(BuildContext) setup() {
  final userId = ref(1);

  // userId 改變時自動重新取得
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

### 行為說明

- **未提供 watch**：元件掛載時執行一次
- **提供 watch**：掛載時以及 watch 值改變時執行
- **避免並發**：若正在載入中，`refresh()` 會被忽略
- **手動刷新**：呼叫 `refresh()` 可強制重新執行

---

## `useAsyncValue`

將 AsyncValue 拆成數個響應式 ref，讓讀取更方便。

### 方法簽章

```dart
(
  ReadonlyRef<T?> data,
  ReadonlyRef<Object?> error,
  ReadonlyRef<bool> loading,
  ReadonlyRef<bool> hasData,
) useAsyncValue<T>(ReadonlyRef<AsyncValue<T>> statusRef)
```

### 參數

- `statusRef`：由 `useFuture` 或 `useAsyncData` 取得的 AsyncValue ref

### 回傳值

包含以下項目的元組：
- `data`：成功取得的資料（若為載入/錯誤/閒置狀態則為 null）
- `error`：錯誤物件（非錯誤狀態時為 null）
- `loading`：布林值，表示是否正在執行
- `hasData`：布林值，表示是否已有資料或錯誤

### 範例

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

追蹤 Stream 最新輸出的值。

### 方法簽章

```dart
Ref<T> useStream<T>(Stream<T> stream, {required T initialValue})
```

### Parameters

- `stream`：要監聽的 Stream
- `initialValue`：第一筆資料發出前的初始值

### 回傳值

`Ref<T>`，會在每次 Stream 發出資料時更新。

### 範例

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

### 生命週期

- 元件掛載時訂閱 Stream
- 元件卸載時自動取消訂閱
- 不會自動處理錯誤，需要的話請自行補上

---

## `useStreamController`

建立 StreamController，並提供響應式的流狀態追蹤。

### 方法簽章

```dart
(StreamController<T>, Ref<T>) useStreamController<T>({
  required T initialValue,
})
```

### 參數

- `initialValue`：追蹤流的初始值

### 回傳值

包含以下項目的元組：
- `controller`：可加入事件的 StreamController
- `stream`：追蹤最新值的響應式 Ref

### 範例

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

### 生命週期

- 元件卸載時自動關閉 Controller
- 內部使用 broadcast StreamController

---

## AsyncValue 型別

### `AsyncValue<T>`

代表非同步操作狀態的密封類別。

```dart
sealed class AsyncValue<T> {
  const factory AsyncValue.idle() = AsyncIdle<T>;
  const factory AsyncValue.loading() = AsyncLoading<T>;
  const factory AsyncValue.data(T data) = AsyncData<T>;
  const factory AsyncValue.error(Object error, [StackTrace? stackTrace]) = AsyncError<T>;
}
```

### 屬性

```dart
// 狀態檢查
bool get isIdle;
bool get isLoading;
bool get isData;
bool get isError;
bool get hasData; // 若已有資料或錯誤則為 true

// 取得值（若不存在則回傳 null）
T? get dataOrNull;
Object? get errorOrNull;
StackTrace? get stackTraceOrNull;
```

### 狀態型別

#### `AsyncIdle<T>`

尚未連線，操作尚未啟動。

```dart
const idle = AsyncIdle<String>();
```

#### `AsyncLoading<T>`

等待資料中，操作正在進行。

```dart
const loading = AsyncLoading<String>();
```

#### `AsyncData<T>`

成功完成，取得資料。

```dart
final data = AsyncData('result');
print(data.value); // 'result'
```

#### `AsyncError<T>`

失敗，操作回傳錯誤。

```dart
final error = AsyncError('Connection failed', StackTrace.current);
print(error.errorValue); // 'Connection failed'
print(error.stackTrace); // StackTrace
```

### 模式比對

```dart
// 完整的 switch
return switch (asyncValue) {
  AsyncIdle() => Text('Not started'),
  AsyncLoading() => CircularProgressIndicator(),
  AsyncData(:final value) => Text('Data: $value'),
  AsyncError(:final errorValue) => Text('Error: $errorValue'),
};

// 條件判斷
if (asyncValue.isLoading) {
  return CircularProgressIndicator();
}

if (asyncValue case AsyncData(:final value)) {
  return Text('Data: $value');
}
```

---

## 最佳實務

### 1. 使用模式匹配處理 AsyncValue

```dart
// ✅ 較佳：完整且型別安全
return switch (userData.value) {
  AsyncLoading() => CircularProgressIndicator(),
  AsyncError(:final errorValue) => ErrorWidget(errorValue),
  AsyncData(:final value) => UserCard(value),
  AsyncIdle() => SizedBox.shrink(),
};

// ❌ 不佳：未涵蓋所有情況
if (userData.value.isData) {
  return UserCard(userData.value.dataOrNull!);
}
return CircularProgressIndicator();
```

### 2. 透過 `useAsyncData` 搭配 watch 處理相依擷取

```dart
// ✅ 較佳：依賴變更時自動重新取得
final (status, _) = useAsyncData<User, int>(
  (id) => api.fetchUser(id),
  watch: () => userId.value,
);

// ❌ 不佳：需手動重新擷取
final status = useFuture(() => api.fetchUser(userId.value));
watch(() => userId.value, (_) {
  // Can't refetch easily
});
```

### 3. 使用 `useAsyncValue` 讓 UI 邏輯更簡潔

```dart
// ✅ 較佳：語意清楚
final (data, error, loading, _) = useAsyncValue(status);

if (loading.value) return CircularProgressIndicator();
if (error.value != null) return ErrorWidget(error.value!);
return DataWidget(data.value!);

// ❌ 可讀性較差
if (status.value case AsyncLoading()) return CircularProgressIndicator();
// ...
```

### 4. 避免同時執行

```dart
// ✅ 較佳：useAsyncData 已內建處理
final (status, refresh) = useAsyncData<Data, void>(
  (_) => fetchData(),
);

// 多次呼叫 refresh() 沒問題，若仍在載入會被忽略
onPressed: refresh;

// ❌ 不佳：需要自行協調
final loading = ref(false);
Future<void> fetch() async {
  if (loading.value) return;
  loading.value = true;
  // ...
}
```

---

## 錯誤處理

### 在 UI 中處理錯誤

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

### 利用 watch 記錄錯誤

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

## 延伸閱讀

- [AsyncValue 型別說明](../types/async-value.md)
- [watch、watchEffect](../watch.md)
- [useFuture 範例](../../guide/async-operations.md)
