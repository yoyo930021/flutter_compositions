# AsyncValue

描述非同步操作狀態的密封類別。

## 概觀

`AsyncValue<T>` 與 Flutter 的 `AsyncSnapshot` 類似，但特別針對完整的模式匹配所設計。它代表非同步操作的四種狀態：idle、loading、data、error。由於採用密封類別（sealed class），編譯器能確保你在模式匹配時處理所有狀態。

## 類別定義

```dart
sealed class AsyncValue<T> {
  const AsyncValue();

  const factory AsyncValue.idle() = AsyncIdle<T>;
  const factory AsyncValue.loading() = AsyncLoading<T>;
  const factory AsyncValue.data(T data) = AsyncData<T>;
  const factory AsyncValue.error(Object error, [StackTrace? stackTrace]) = AsyncError<T>;
}
```

## 狀態型別

### AsyncIdle

代表操作尚未開始，尚未建立任何連線。

```dart
final class AsyncIdle<T> extends AsyncValue<T> {
  const AsyncIdle();
}
```

```dart
final status = ref<AsyncValue<String>>(const AsyncValue.idle());

return switch (status.value) {
  AsyncIdle() => const Text('Click to load'),
  // ... 其他狀態
};
```

---

### AsyncLoading

代表操作正在進行，等待資料。

```dart
final class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}
```

```dart
final status = ref<AsyncValue<User>>(const AsyncValue.loading());

return switch (status.value) {
  AsyncLoading() => const CircularProgressIndicator(),
  // ... 其他狀態
};
```

---

### AsyncData

代表操作成功並取得資料。

```dart
final class AsyncData<T> extends AsyncValue<T> {
  const AsyncData(this.value);

  final T value;
}
```

- `value`：成功取得的資料

```dart
final status = ref<AsyncValue<User>>(
  const AsyncValue.data(User(name: 'Alice')),
);

return switch (status.value) {
  AsyncData(:final value) => Text('User: ${value.name}'),
  // ... 其他狀態
};
```

---

### AsyncError

代表操作失敗並附帶錯誤資訊。

```dart
final class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(this.errorValue, [this.stackTrace]);

  final Object errorValue;
  final StackTrace? stackTrace;
}
```

- `errorValue`：發生的錯誤
- `stackTrace`：可選的錯誤堆疊

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
  // ... 其他狀態
};
```

---

## 屬性與工具

### 狀態檢查

```dart
bool get isIdle;      // 若為 AsyncIdle 回傳 true
bool get isLoading;   // 若為 AsyncLoading 回傳 true
bool get isData;      // 若為 AsyncData 回傳 true
bool get isError;     // 若為 AsyncError 回傳 true
bool get hasData;     // 若為 AsyncData 或 AsyncError 回傳 true
```

### 安全取值

```dart
T? get dataOrNull;              // AsyncData 時回傳資料，否則為 null
Object? get errorOrNull;        // AsyncError 時回傳錯誤，否則為 null
StackTrace? get stackTraceOrNull; // AsyncError 時回傳堆疊，否則為 null
```

## 模式匹配

### 完整 switch

```dart
return switch (asyncValue) {
  AsyncIdle() => const Text('Not started'),
  AsyncLoading() => const CircularProgressIndicator(),
  AsyncData(:final value) => Text('Data: $value'),
  AsyncError(:final errorValue) => Text('Error: $errorValue'),
};
```

### 拆構值

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

### case 表達式

```dart
if (asyncValue case AsyncData(:final value)) {
  print('Got data: $value');
}

if (asyncValue case AsyncError(:final errorValue)) {
  print('Error occurred: $errorValue');
}
```

### 透過屬性判斷

```dart
if (asyncValue.isLoading) {
  return const CircularProgressIndicator();
}

if (asyncValue.isData) {
  final data = asyncValue.dataOrNull;
  return Text('Data: $data');
}

if (asyncValue.hasData) {
  // 此時一定已經有資料或錯誤
  final data = asyncValue.dataOrNull;
  final error = asyncValue.errorOrNull;
}
```

## 搭配組合式函式

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

## 最佳實務

### 使用模式匹配

```dart
// ✅ 較佳：完整且型別安全
return switch (userData.value) {
  AsyncLoading() => const CircularProgressIndicator(),
  AsyncError(:final errorValue) => ErrorWidget(errorValue),
  AsyncData(:final value) => UserCard(value),
  AsyncIdle() => const SizedBox.shrink(),
};

// ⚠️ 請避免：未涵蓋所有情況
if (userData.value.isData) {
  return UserCard(userData.value.dataOrNull!);
}
return const CircularProgressIndicator();
```

### 處理所有狀態

```dart
// ✅ 較佳：每個狀態皆有對應處理
return switch (status.value) {
  AsyncIdle() => const Text('Click to load'),
  AsyncLoading() => const CircularProgressIndicator(),
  AsyncData(:final value) => DataView(value),
  AsyncError(:final errorValue) => ErrorView(errorValue),
};

// ⚠️ 不佳：遺漏部分狀態
return switch (status.value) {
  AsyncData(:final value) => DataView(value),
  _ => const CircularProgressIndicator(), // 將 idle、loading、error 混為一談
};
```

### 提供完整錯誤資訊

```dart
// ✅ 較佳：包含錯誤訊息與堆疊
return switch (userData.value) {
  AsyncError(:final errorValue, :final stackTrace) => ErrorView(
    message: errorValue.toString(),
    stackTrace: stackTrace,
    onRetry: refresh,
  ),
  // ... 其他狀態
};

// ⚠️ 請避免：缺乏脈絡
return switch (userData.value) {
  AsyncError(:final errorValue) => Text('Error: $errorValue'),
  // ... 其他狀態
};
```

### 使用 computed 產生衍生狀態

```dart
final userData = useFuture(() => api.fetchUser());

final isUserAdmin = computed(() {
  return switch (userData.value) {
    AsyncData(:final value) => value.role == 'admin',
    _ => false,
  };
});

return (context) => Text('Is admin: ${isUserAdmin.value}');
```

## 常見模式

### 載入遮罩

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

### 顯示錯誤並提供重試

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

### 樂觀更新

```dart
final (status, refresh) = useAsyncData<List<Item>, void>(
  (_) => api.fetchItems(),
);

void addItem(Item item) {
  // 樂觀更新
  if (status.value case AsyncData(:final value)) {
    status.value = AsyncData([...value, item]);
  }

  // 與伺服器同步
  api.addItem(item).then(
    (_) => refresh(),
    onError: (e) {
      status.value = AsyncError(e);
    },
  );
}
```

---

## 延伸閱讀

- [useFuture](../composables/async.md#usefuture) - 執行 Future 並追蹤狀態
- [useAsyncData](../composables/async.md#useasyncdata) - 具 watch 支援的進階非同步
- [useAsyncValue](../composables/async.md#useasyncvalue) - 將 AsyncValue 拆成複數 ref
- [Pattern Matching](https://dart.dev/language/patterns) - Dart 模式匹配指南
