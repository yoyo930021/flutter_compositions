# Flutter Compositions Lints

提供自訂 lint 規則，協助落實最佳實務並避免常見陷阱。

## 安裝

在 `pubspec.yaml` 中加入：

```yaml
dev_dependencies:
  custom_lint: ^0.7.0
  flutter_compositions_lints: ^0.1.0
```

建立或更新 `analysis_options.yaml`：

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  enable_all_lint_rules: true
```

## 執行 Lint

```bash
# 一次性分析
dart run custom_lint

# 監看檔案變更
dart run custom_lint --watch

# 可自動修正的規則
dart run custom_lint --fix
```

## IDE 整合

### VS Code
在終端機執行 `dart run custom_lint --watch`，Flutter/Dart 官方擴充會自動顯示結果，不需要額外安裝外掛。

### Android Studio / IntelliJ
執行 `dart run custom_lint` 後，IDE 會自動顯示錯誤與警告。

## 可用的規則

| 規則 | 嚴重度 | 類別 | 說明 |
|------|--------|------|------|
| [flutter_compositions_ensure_reactive_props](./rules.md#flutter_compositions_ensure_reactive_props) | Warning | Reactivity | props 必須透過 `widget()` 取得 |
| [flutter_compositions_no_async_setup](./rules.md#flutter_compositions_no_async_setup) | Error | Lifecycle | 禁止非同步的 setup |
| [flutter_compositions_controller_lifecycle](./rules.md#flutter_compositions_controller_lifecycle) | Warning | Lifecycle | 控制器需正確釋放 |
| [flutter_compositions_no_mutable_fields](./rules.md#flutter_compositions_no_mutable_fields) | Warning | Best Practices | CompositionWidget 欄位須為 immutable |

[查看完整規則文件 →](./rules.md)

## 快速範例

### Reactive Props

❌ **不佳：**
```dart
@override
Widget Function(BuildContext) setup() {
  final name = this.displayName; // 非響應式
  return (context) => Text(name);
}
```

✅ **較佳：**
```dart
@override
Widget Function(BuildContext) setup() {
  final props = widget();
  final name = computed(() => props.value.displayName);
  return (context) => Text(name.value);
}
```

### Async Setup

❌ **不佳：**
```dart
@override
Future<Widget Function(BuildContext)> setup() async {
  await loadData();
  return (context) => Text('Loaded');
}
```

✅ **較佳：**
```dart
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);
  onMounted(() async => data.value = await loadData());
  return (context) => Text(data.value ?? 'Loading...');
}
```

### Controller Lifecycle

❌ **不佳：**
```dart
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController(); // 永遠沒釋放
  return (context) => ListView(controller: controller);
}
```

✅ **較佳：**
```dart
@override
Widget Function(BuildContext) setup() {
  final controller = useScrollController(); // 自動釋放
  return (context) => ListView(controller: controller.value);
}
```

## 停用規則

### 整個檔案

```dart
// ignore_for_file: flutter_compositions_ensure_reactive_props
```

### 單行

```dart
// ignore: flutter_compositions_ensure_reactive_props
final name = this.displayName;
```

### 設定檔

```yaml
custom_lint:
  rules:
    - flutter_compositions_ensure_reactive_props: false
    - flutter_compositions_no_async_setup: true
```

## 參與貢獻

發現誤判或有新規則提案？歡迎至 [GitHub Issues](https://github.com/yourusername/flutter_compositions/issues) 提出。

## 延伸閱讀

- [完整規則說明](./rules.md)
- [最佳實務指南](../guide/best-practices.md)
- [API 參考](../api/README.md)
