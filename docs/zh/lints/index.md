# Lint 規則總覽

Flutter Compositions 提供一組自訂 lint 規則，用來強化最佳實務並避免常見錯誤。本指南快速介紹各規則與使用方式。

## 快速上手

### 安裝

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

### 執行 Lint

```bash
# 分析程式碼
dart run custom_lint

# 監看檔案變動
dart run custom_lint --watch

# 可自動修正的規則
dart run custom_lint --fix
```

## 規則列表

### Reactivity 相關

確保正確運用響應式狀態。

#### `flutter_compositions_ensure_reactive_props`

**嚴重程度：** Warning

要求在 `setup()` 中透過 `widget()` 取得 props，以維持響應式。

```dart
// ❌ 不佳：非響應式
@override
Widget Function(BuildContext) setup() {
  final greeting = 'Hello, $name!'; // 直接讀取
  return (context) => Text(greeting);
}

// ✅ 較佳：響應式
@override
Widget Function(BuildContext) setup() {
  final props = widget();
  final greeting = computed(() => 'Hello, ${props.value.name}!');
  return (context) => Text(greeting.value);
}
```

[詳細說明 →](./rules.md#flutter_compositions_ensure_reactive_props)

---

### 生命週期相關

確保正確釋放資源與控制非同步流程。

#### `flutter_compositions_no_async_setup`

**嚴重程度：** Error

禁止將 `setup()` 宣告為 `async`，必須同步回傳 builder。

```dart
// ❌ 不佳：非同步 setup
@override
Future<Widget Function(BuildContext)> setup() async {
  final data = await fetchData();
  return (context) => Text(data);
}

// ✅ 較佳：改用 onMounted
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);
  onMounted(() async {
    data.value = await fetchData();
  });
  return (context) => Text(data.value ?? 'Loading...');
}
```

[詳細說明 →](./rules.md#flutter_compositions_no_async_setup)

#### `flutter_compositions_controller_lifecycle`

**嚴重程度：** Warning

確保 Flutter 控制器透過 `use*` 族群自動釋放，或在 `onUnmounted()` 中手動釋放。

**檢查的控制器型別：**
- ScrollController, PageController, TextEditingController
- TabController, AnimationController
- VideoPlayerController, WebViewController

```dart
// ❌ 不佳：未釋放
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController();
  return (context) => ListView(controller: controller);
}

// ✅ 較佳：自動釋放
@override
Widget Function(BuildContext) setup() {
  final controller = useScrollController();
  return (context) => ListView(controller: controller.value);
}

// ✅ 較佳：手動釋放
@override
Widget Function(BuildContext) setup() {
  final controller = ScrollController();
  onUnmounted(() => controller.dispose());
  return (context) => ListView(controller: controller);
}
```

[詳細說明 →](./rules.md#flutter_compositions_controller_lifecycle)

#### `flutter_compositions_no_conditional_composition`

**嚴重程度：** Error

禁止在條件或迴圈中呼叫組合式 API，類似 React Hooks 的限制。

**檢查的 API：**
- Reactivity：`ref`, `computed`, `writableComputed`, `customRef`, `watch`, `watchEffect`
- Lifecycle：`onMounted`, `onUnmounted`
- 依賴注入：`provide`, `inject`
- 控制器：`useScrollController`, `usePageController`, `useFocusNode`, `useTextEditingController`, `useValueNotifier`, `useAnimationController` 等

```dart
// ❌ 不佳：條件式呼叫
@override
Widget Function(BuildContext) setup() {
  if (someCondition) {
    final count = ref(0); // 不要這樣做！
  }
  return (context) => Text('Hello');
}

// ✅ 較佳：在頂層呼叫 API
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  if (someCondition) {
    count.value = 10; // 根據條件改值是可以的
  }

  return (context) => Text('${count.value}');
}
```

[詳細說明 →](./rules.md#flutter_compositions_no_conditional_composition)

---

### Best Practices 相關

保持程式碼簡潔、一致。

#### `flutter_compositions_no_mutable_fields`

**嚴重程度：** Warning

確保 CompositionWidget 的欄位皆為 `final`，可變狀態應交由 `ref()` 或 `computed()` 管理。

```dart
// ❌ 不佳：欄位可變
class Counter extends CompositionWidget {
  int count = 0;

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Text('$count');
  }
}

// ✅ 較佳：欄位保持 immutable，狀態交給 ref
class Counter extends CompositionWidget {
  final int initialCount;

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(initialCount);
    return (context) => Text('${count.value}');
  }
}
```

[詳細說明 →](./rules.md#flutter_compositions_no_mutable_fields)

---

## 設定規則

### 自行啟用 / 停用

在 `analysis_options.yaml`：

```yaml
custom_lint:
  rules:
    - flutter_compositions_ensure_reactive_props: true
    - flutter_compositions_no_async_setup: true
    - flutter_compositions_no_mutable_fields: false # 停用
```

### 在程式碼中忽略

**整個檔案**

```dart
// ignore_for_file: flutter_compositions_ensure_reactive_props
```

**單行**

```dart
// ignore: flutter_compositions_ensure_reactive_props
final name = this.name;
```

**指定區塊**

```dart
// ignore: flutter_compositions_controller_lifecycle
final controller = ScrollController();
```

## IDE 整合

### VS Code
在終端機執行 `dart run custom_lint --watch`。Flutter/Dart 官方擴充會自動將結果顯示在編輯器內，並可透過 `Ctrl/Cmd + .` 呼叫快速修正。

### Android Studio / IntelliJ

1. 在終端機執行 `dart run custom_lint`
2. 錯誤會顯示於 Problems 面板
3. 或使用 `dart run custom_lint --watch` 取得即時更新

## 規則速覽表

| 規則 | 嚴重度 | 類別 | Auto-Fix | 說明 |
|------|--------|------|----------|------|
| [ensure_reactive_props](./rules.md#flutter_compositions_ensure_reactive_props) | Warning | Reactivity | No | props 必須透過 `widget()` 取得 |
| [no_async_setup](./rules.md#flutter_compositions_no_async_setup) | Error | Lifecycle | No | 禁止非同步 setup |
| [controller_lifecycle](./rules.md#flutter_compositions_controller_lifecycle) | Warning | Lifecycle | No | 控制器必須釋放 |
| [no_mutable_fields](./rules.md#flutter_compositions_no_mutable_fields) | Warning | Best Practices | No | 欄位需為 immutable |
| [no_conditional_composition](./rules.md#flutter_compositions_no_conditional_composition) | Error | Lifecycle | No | 禁止條件式呼叫組合式 API |

## 常見範式

### 1. Reactive Props

```dart
class UserCard extends CompositionWidget {
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    final greeting = computed(() => 'Hello, ${props.value.name}!');
    return (context) => Text(greeting.value);
  }
}
```

### 2. 控制器管理

```dart
@override
Widget Function(BuildContext) setup() {
  final scrollController = useScrollController(); // ✅ 自動釋放
  final (textController, text, _) = useTextEditingController();
  final (animController, animValue) = useAnimationController(
    duration: Duration(seconds: 1),
  );

  return (context) => /* ... */;
}
```

### 3. 非同步初始化

```dart
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);
  final isLoading = ref(false);

  onMounted(() async {
    isLoading.value = true;
    try {
      data.value = await fetchData();
    } finally {
      isLoading.value = false;
    }
  });

  return (context) => /* ... */;
}
```

### 4. 型別安全 DI

```dart
class ThemeServiceKey extends InjectionKey<ThemeService> {
const ThemeServiceKey();
}

const themeServiceKey = ThemeServiceKey();

provide(themeServiceKey, ThemeService());
final theme = inject(themeServiceKey);
```

## 疑難排解

### 看不到 lint？

1. 確認 `custom_lint` 已加入 `dev_dependencies`
2. 執行 `flutter pub get`
3. 重啟 IDE
4. 手動執行 `dart run custom_lint`

### 懷疑是誤判？

1. 確認程式碼是否真有問題
2. 對特殊案例使用 `// ignore:` 註解
3. 於 [GitHub Issues](https://github.com/yourusername/flutter_compositions/issues) 回報

### 效能不佳？

1. 對大型專案使用 `dart run custom_lint`（非 watch 模式）
2. 停用不需要的規則
3. 改在 CI/CD 執行 lint

## 最佳實務

1. **預設啟用所有規則**，再視需要停用
2. **在提交前修正 lint**，保持程式碼整潔
3. **善用 IDE 整合**，即時修正
4. **忽略必須加上註解**，解釋原因
5. **在 CI/CD 執行**，確保規則被遵守

## 貢獻指南

若發現誤判或有新規則提案：

1. 於 [GitHub](https://github.com/yourusername/flutter_compositions/issues) 搜尋既有議題
2. 建立新議題並提供：
   - 觸發 lint 的程式碼
   - 預期與實際行為
3. 送出 PR 時請附上：
   - 規則實作
   - 測試
   - 文件更新

## 延伸閱讀

- [完整規則說明](./rules.md)
- [響應式基礎](../guide/reactivity-fundamentals.md)
- [最佳實務指南](../guide/best-practices.md)
- [Composables 參考](../guide/built-in-composables.md)

## 快速參考

### 必須遵守（Error）

- `flutter_compositions_no_async_setup`
- `flutter_compositions_no_conditional_composition`

### 建議遵守（Warning）

- `flutter_compositions_ensure_reactive_props`
- `flutter_compositions_controller_lifecycle`
- `flutter_compositions_no_mutable_fields`

---

更多細節請參考 [完整規則文件](./rules.md)。
