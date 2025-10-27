# Lifecycle Hooks

用於管理 Flutter Compositions 元件生命週期的掛勾。

## onMounted

會在第一個畫面繪製完成後呼叫。

### 方法簽章

```dart
void onMounted(void Function() callback)
```

### 範例

```dart
@override
Widget Function(BuildContext) setup() {
  onMounted(() {
    print('元件已掛載並完成繪製');
  });

  return (context) => Text('Hello');
}
```

### 非同步初始化

```dart
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);

  onMounted(() async {
    data.value = await fetchData();
  });

  return (context) => Text(data.value ?? 'Loading...');
}
```

### 多個 onMounted 掛勾

```dart
@override
Widget Function(BuildContext) setup() {
  onMounted(() {
    print('First mount hook');
  });

  onMounted(() {
    print('Second mount hook');
  });

  return (context) => Container();
}
```

## onUnmounted

會在 Widget 被銷毀前呼叫。

### 方法簽章

```dart
void onUnmounted(void Function() callback)
```

### 範例

```dart
@override
Widget Function(BuildContext) setup() {
  final timer = Timer.periodic(Duration(seconds: 1), (_) {
    print('Tick');
  });

  onUnmounted(() {
    timer.cancel(); // 卸載時清除資源
  });

  return (context) => Text('Timer running');
}
```

### 清除訂閱

```dart
@override
Widget Function(BuildContext) setup() {
  final subscription = stream.listen((data) {
    print(data);
  });

  onUnmounted(() {
    subscription.cancel();
  });

  return (context) => Container();
}
```

## onBuild

每次 builder 函式執行時都會呼叫。

### 方法簽章

```dart
void onBuild(void Function() callback)
```

### 範例

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  onBuild(() {
    print('Builder 執行，count: ${count.value}');
  });

  return (context) {
    return Text('Count: ${count.value}');
  };
}
```

### 取得 BuildContext

```dart
@override
Widget Function(BuildContext) setup() {
  final theme = ref<ThemeData?>(null);

  onBuild(() {
    // onBuild 回呼無法取得 context
    // 請在 builder 內取得 context
  });

  return (context) {
    theme.value = Theme.of(context); // 在這裡取得 context
    return Text('Theme: ${theme.value?.brightness}');
  };
}
```

## 生命週期順序

```
1. 呼叫 setup()
2. 初次呼叫 builder()
3. 執行所有 onBuild() 回呼
4. 繪製畫面
5. 執行 onMounted() 回呼

...（Widget 活動中）

6. 狀態變更觸發 builder()
7. 再次執行 onBuild() 回呼

...（Widget 被銷毀）

8. 執行 onUnmounted() 回呼
```

## 與 StatefulWidget 比較

| StatefulWidget | CompositionWidget |
|----------------|-------------------|
| `initState()` | `setup()` |
| `build()` | `return (context) => ...` |
| `didChangeDependencies()` | `onBuild()` |
| 第一個畫面繪製後的回呼 | `onMounted()` |
| `dispose()` | `onUnmounted()` |
| `didUpdateWidget()` | 自動（透過 `widget()`） |

## 最佳實務

### 將非同步作業放在 onMounted

```dart
// ✅ 較佳：在 onMounted 執行非同步
@override
Widget Function(BuildContext) setup() {
  final data = ref<User?>(null);

  onMounted(() async {
    data.value = await fetchUser();
  });

  return (context) => Text(data.value?.name ?? 'Loading...');
}
```

### 確實清除資源

```dart
// ✅ 較佳：在 onUnmounted 清理
@override
Widget Function(BuildContext) setup() {
  final controller = AnimationController(vsync: this);

  onUnmounted(() {
    controller.dispose();
  });

  return (context) => AnimatedBuilder(...);
}
```

### 多組生命週期掛勾

```dart
@override
Widget Function(BuildContext) setup() {
  // 掛載時的掛勾
  onMounted(() => print('Mounted 1'));
  onMounted(() => print('Mounted 2'));

  // 卸載時的掛勾
  onUnmounted(() => print('Unmounted 1'));
  onUnmounted(() => print('Unmounted 2'));

  return (context) => Container();
}
// 執行順序：
// Mounted 1
// Mounted 2
// ...（之後）
// Unmounted 1
// Unmounted 2
```

## 自動清除

建立資源的組合式函式通常會自動負責清理：

```dart
@override
Widget Function(BuildContext) setup() {
  // 這些會在卸載時自動清理
  final scrollController = useScrollController();
  final (animController, _) = useAnimationController();
  final subscription = useStream(myStream);

  // 不需要手動撰寫 onUnmounted 來清理！

  return (context) => Container();
}
```

## 延伸閱讀

- [CompositionWidget](./composition-widget.md) - 基底 Widget 類別
- [組合式函式](./composables/) - 內建且具自動清理功能的 composable
- [watch](./watch.md) - 副作用處理
