# 最佳實務指南

本指南彙整在 Flutter Compositions 開發中常見的模式、效能技巧與團隊約定，協助你建立可維護且易於測試的應用程式。

## 目錄

1. [組合模式](#組合模式)
2. [狀態管理](#狀態管理)
3. [效能優化](#效能優化)
4. [程式結構](#程式結構)
5. [Lint 工作流程](#lint-工作流程)
6. [測試策略](#測試策略)
7. [常見陷阱](#常見陷阱)
8. [延伸閱讀](#延伸閱讀)

## 組合模式

### 將邏輯抽成 Composable

把可重複使用的狀態與副作用封裝成函式，避免在多個 widget 中重複同樣的 setup 寫法。

```dart
// ✅ 推薦做法：回傳需要的 ref 與工具方法
(Ref<String>, Ref<bool>) useValidatedInput({
  String initialValue = '',
  int minLength = 6,
}) {
  final value = ref(initialValue);
  final isValid = computed(() => value.value.trim().length >= minLength);
  return (value, isValid);
}

class LoginForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (email, emailValid) = useValidatedInput(minLength: 5);
    final (password, passwordValid) = useValidatedInput(minLength: 8);
    final canSubmit = computed(() => emailValid.value && passwordValid.value);

    return (context) => ElevatedButton(
          onPressed: canSubmit.value ? () => submit(email.value) : null,
          child: const Text('登入'),
        );
  }
}
```

### 使用 Domain Model 表達狀態

相較於直接操作 `Map<String, dynamic>`，以類別封裝狀態能降低欄位名稱打錯的風險，也讓重構更輕鬆。

```dart
class SessionState {
  final user = ref<User?>(null);
  final isAuthenticated = ref(false);
}
```

### Setup 保持同步

`setup()` 必須同步回傳 builder。若需要非同步流程，使用 `onMounted` 或其他生命週期鉤子。

```dart
@override
Widget Function(BuildContext) setup() {
  final profile = ref<User?>(null);
  final loading = ref(true);

  onMounted(() async {
    profile.value = await api.fetchProfile();
    loading.value = false;
  });

  return (context) => loading.value
      ? const CircularProgressIndicator()
      : Text(profile.value!.name);
}
```

### 使用 watch / watchEffect 處理副作用

將導頁、分析、紀錄等副作用寫在 `watch` 或 `watchEffect` 中，系統會在卸載時自動清理監聽。

```dart
watch(() => session.isAuthenticated.value, (isAuthed, _) {
  if (!isAuthed) navigator.showLogin();
});
```

## 狀態管理

### 明確區分狀態範圍

- **本地狀態**：僅在單一 widget 使用，透過 `ref` 宣告。
- **共享狀態**：同一分支的多個 widget 共用，使用 `provide`/`inject` 傳遞。
- **全域狀態**：整個應用程式皆需存取，建議集中在 App shell 提供。

```dart
const sessionKey = InjectionKey<SessionState>('session');

class AppShell extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final session = SessionState();
    provide(sessionKey, session);
    return (context) => const HomePage();
  }
}

class ProfileMenu extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final session = inject(sessionKey);
    return (context) => Text(session.user.value?.name ?? 'Guest');
  }
}
```

### 使用 InjectionKey 確保型別安全

即使目前只有單一實例，也建議宣告 `const InjectionKey<T>`，避免衝突並讓錯誤更好追蹤。

### 使用 AsyncValue 表示非同步狀態

- 以 `AsyncValue<T>` 包裝所有非同步結果，將載入、錯誤、資料狀態集中在同一個地方。
- 需要重新整理或重試時，可暴露 `useAsyncData` 回傳的 `refresh()`。

## 效能優化

- **使用 `computed` 快取昂貴計算**：避免在 builder 中重複計算篩選、排序等昂貴邏輯。
- **減少 builder 依賴**：盡量只讀取必要的 ref，將固定內容抽成 const widget。
- **避免在 builder 內建立新物件**：控制器、動畫等應在 setup 中建立；必要時使用 `useScrollController`、`useAnimationController` 等內建 helper。

```dart
@override
Widget Function(BuildContext) setup() {
  final todos = ref(<Todo>[]);
  final completed = computed(
    () => todos.value.where((todo) => todo.isDone).toList(growable: false),
  );

  return (context) => Column(
        children: [
          Text('完成 ${completed.value.length} 項'),
          Expanded(child: TodoList(todos: todos.value)),
        ],
      );
}
```

## 程式結構

1. **命名清楚**：`useDebouncedSearch()`、`useAuthSession()` 等名稱能立即說明用途。
2. **按照功能分層**：`lib/features/<feature>/composables`、`services`、`widgets` 等資料夾讓團隊快速定位。
3. **維持小型 composable**：若單一 composable 處理所有流程（驗證、呼叫 API、路由），應拆成多個函式。
4. **測試與程式碼共置**：將測試檔案放在對應的 composable 或 widget 同層，方便一起維護。

範例結構：

```
lib/
├── features/
│   └── checkout/
│       ├── composables/
│       │   ├── use_cart.dart
│       │   └── use_checkout_flow.dart
│       ├── services/
│       │   └── checkout_service.dart
│       └── widgets/
│           └── checkout_page.dart
└── shared/
    ├── services/
    └── widgets/
```

## Lint 工作流程

- 在 `pubspec.yaml` 加入：

```yaml
dev_dependencies:
  custom_lint: ^0.7.0
  flutter_compositions_lints: ^0.1.0
```

- 在 `analysis_options.yaml` 啟用：

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  enable_all_lint_rules: true
```

- 開發時執行 `dart run custom_lint --watch`，提交前可搭配 `--fix`。
- 詳細規則請參考 [Lint 使用指南](../lints/index.md)。

## 測試策略

### 測試 composable

利用 `CompositionBuilder` 或直接呼叫 composable 函式，檢查回傳的 ref 是否如預期改變。

```dart
test('useCounter increments', () {
  final (count, increment) = useCounter(initialValue: 0);
  increment();
  expect(count.value, 1);
});
```

### 測試 widget

```dart
testWidgets('ProfilePage 顯示使用者名稱', (tester) async {
  final mockSession = SessionState()..user.value = User(name: 'Alice');

  await tester.pumpWidget(
    CompositionBuilder(
      setup: () {
        provide(sessionKey, mockSession);
        return (context) => const MaterialApp(home: ProfilePage());
      },
    ),
  );

  await tester.pumpAndSettle();
  expect(find.text('Alice'), findsOneWidget);
});
```

- 若測試依賴 `watch` 或 `watchEffect` 的副作用，記得使用 `tester.pump()` 讓更新生效。
- 使用 `provide` 注入 mock service，比直接改動全域單例更可靠。

## 常見陷阱

- 在 `setup()` 中直接使用 `await`：應改放在 `onMounted`。
- 直接存取 `this.xxx` 或 `widget.xxx`：請透過 `widget<T>()` 取得 reactive props。
- 重新排序或刪除 `ref` 宣告：Hot Reload 依據宣告順序保存狀態，調整順序時需重新整理 (Hot Restart)。
- 忘記清理外部資源：使用 `onUnmounted` 或內建 `use*` helper 自動釋放控制器、監聽器。

## 延伸閱讀

- [快速上手](./getting-started.md)
- [深入理解組合式 API](./what-is-a-composition.md)
- [響應式基礎](./reactivity-fundamentals.md)
- [非同步操作實戰](./async-operations.md)
- [依賴注入指南](./dependency-injection.md)
- [Lint 規則總覽](../lints/index.md)
- [測試指南](../testing/testing-guide.md)
