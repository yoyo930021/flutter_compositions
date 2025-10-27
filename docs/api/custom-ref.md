# customRef

建立自訂的響應式參照，完全掌控追蹤與觸發行為。

## 概觀

`customRef` 讓你能定義具有客製 getter 與 setter 的響應式參照，進而完全控制相依追蹤與更新觸發時機。

## 方法簽章

```dart
Ref<T> customRef<T>({
  required T Function(T Function() track) getter,
  required void Function(T newValue, void Function() trigger) setter,
})
```

## 參數說明

- `getter`：回傳目前值的函式。呼叫 `track()` 以追蹤依賴。
- `setter`：負責寫入新值的函式。呼叫 `trigger()` 以通知監聽者。

## 範例：具防抖功能的 ref

```dart
Ref<String> useDebouncedRef(String initialValue, Duration delay) {
  String _value = initialValue;
  Timer? _timer;

  return customRef<String>(
    getter: (track) {
      track(); // 追蹤這次存取
      return _value;
    },
    setter: (newValue, trigger) {
      _timer?.cancel();
      _timer = Timer(delay, () {
        _value = newValue;
        trigger(); // 延遲後通知監聽者
      });
    },
  );
}

// 用法
final searchQuery = useDebouncedRef('', Duration(milliseconds: 300));
searchQuery.value = 'flutter'; // 300 毫秒後才會觸發
```

## 範例：具驗證功能的 ref

```dart
Ref<int> useValidatedRef(int min, int max) {
  int _value = min;

  return customRef<int>(
    getter: (track) {
      track();
      return _value;
    },
    setter: (newValue, trigger) {
      final clamped = newValue.clamp(min, max);
      if (clamped != _value) {
        _value = clamped;
        trigger();
      }
    },
  );
}

// 用法
final age = useValidatedRef(0, 120);
age.value = 150; // 實際會被限制為 120
```

## 範例：具紀錄功能的 ref

```dart
Ref<T> useLoggedRef<T>(T initialValue, String name) {
  T _value = initialValue;

  return customRef<T>(
    getter: (track) {
      print('[$name] Read: $_value');
      track();
      return _value;
    },
    setter: (newValue, trigger) {
      print('[$name] Write: $_value -> $newValue');
      _value = newValue;
      trigger();
    },
  );
}
```

## ReadonlyCustomRef

建立僅可讀取（沒有 setter）的自訂 ref。

### 方法簽章

```dart
ComputedRef<T> readonlyCustomRef<T>({
  required T Function(T Function() track) getter,
})
```

### 範例

```dart
ComputedRef<DateTime> useCurrentTime(Duration updateInterval) {
  DateTime _time = DateTime.now();

  Timer.periodic(updateInterval, (_) {
    _time = DateTime.now();
    // trigger() 會自動被呼叫
  });

  return readonlyCustomRef<DateTime>(
    getter: (track) {
      track();
      return _time;
    },
  );
}
```

## 最佳實務

### 一定要呼叫 track()

```dart
// 不佳：忘記呼叫 track
customRef<int>(
  getter: (track) => _value, // 缺少 track()！
  setter: (newValue, trigger) {
    _value = newValue;
    trigger();
  },
);

// 較佳：正確追蹤
customRef<int>(
  getter: (track) {
    track(); // 依賴會被追蹤
    return _value;
  },
  setter: (newValue, trigger) {
    _value = newValue;
    trigger();
  },
);
```

### 僅在值真的變更時觸發

```dart
// 較佳：避免不必要的更新
customRef<int>(
  getter: (track) {
    track();
    return _value;
  },
  setter: (newValue, trigger) {
    if (newValue != _value) { // 觸發前先檢查
      _value = newValue;
      trigger();
    }
  },
);
```

### 確實清除資源

```dart
Ref<T> useCustomRefWithCleanup<T>(T initial) {
  final subscription = someStream.listen((_) {});

  onUnmounted(() {
    subscription.cancel(); // 元件卸載時釋放資源
  });

  return customRef<T>(
    getter: (track) {
      track();
      return _value;
    },
    setter: (newValue, trigger) {
      _value = newValue;
      trigger();
    },
  );
}
```

## 延伸閱讀

- [ref](./reactivity.md#ref) - 標準的響應式參照
- [computed](./reactivity.md#computed) - 衍生值
- [watch](./watch.md) - Side effects
