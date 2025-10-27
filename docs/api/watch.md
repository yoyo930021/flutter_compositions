# watch 與 watchEffect

管理副作用與響應式依賴追蹤。

## watch

監看某個響應式值，當它改變時執行回呼。

### 方法簽章

```dart
WatchHandle watch<T>(
  T Function() getter,
  void Function(T newValue, T oldValue) callback, {
  bool immediate = false,
})
```

### 參數

- `getter`：回傳要監看的值的函式
- `callback`：當值改變時執行的函式，會收到新舊值
- `immediate`：若為 `true`，會立即以當前值執行回呼

### 回傳值

`WatchHandle`，可用來停止監看

### 範例

```dart
final count = ref(0);

watch(
  () => count.value,
  (newValue, oldValue) {
    print('Count changed from $oldValue to $newValue');
  },
);

count.value++; // 印出：Count changed from 0 to 1
```

### 搭配 immediate

```dart
watch(
  () => count.value,
  (newValue, oldValue) {
    print('Current: $newValue');
  },
  immediate: true,
); // 會立即印出：Current: 0
```

## watchEffect

自動追蹤依賴，任一依賴改變時重新執行。

### 方法簽章

```dart
WatchHandle watchEffect(void Function() effect)
```

### 參數

- `effect`：要執行的函式，依賴會自動被追蹤

### 回傳值

`WatchHandle`，可用來停止監看

### 範例

```dart
final count = ref(0);
final doubled = ref(0);

watchEffect(() {
  // Automatically tracks both count and doubled
  print('Count: ${count.value}, Doubled: ${doubled.value}');
});

count.value++; // 觸發 watchEffect
doubled.value = count.value * 2; // 同樣會觸發 watchEffect
```

## WatchHandle

`watch` 與 `watchEffect` 回傳的控制柄，可管理監看行為。

### 方法

- `stop()`：停止監看並清除資源

### 範例

```dart
final handle = watchEffect(() {
  print(count.value);
});

// Later...
handle.stop(); // 停止監看
```

## Lifecycle Integration

在 `setup()` 中使用時，監看會在 Widget 銷毀時自動清除。

```dart
class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    // 在 dispose 時會自動清除
    watch(() => count.value, (value, _) {
      print(value);
    });

    return (context) => Text('${count.value}');
  }
}
```

## 最佳實務

### 使用 watch 監看特定值

```dart
// 較佳：監看特定值
watch(() => user.value.id, (newId, oldId) {
  fetchUserData(newId);
});
```

### 需要多個依賴時使用 watchEffect

```dart
// 較佳：自動追蹤多個值
watchEffect(() {
  final result = count.value + multiplier.value;
  print('Result: $result');
});
```

### 避免在 getter 中產生副作用

```dart
// 不佳：在 getter 中產生副作用
watch(() {
  print('Computing...'); // 不要這樣做！
  return count.value;
}, (value, _) {});

// 較佳：僅在回呼中處理副作用
watch(() => count.value, (value, _) {
  print('Value changed to $value');
});
```

## 延伸閱讀

- [ref](./reactivity.md#ref) - 建立響應式參照
- [computed](./reactivity.md#computed) - 衍生值
- [生命週期掛勾](./lifecycle.md) - 元件生命週期
