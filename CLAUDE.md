# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 儲存庫概覽

Flutter Compositions 是一個 **Melos monorepo**，包含了受 Vue 3 Composition API 啟發的 Flutter 響應式框架。核心架構使用 **`alien_signals`** 實現細粒度響應式，並在 Flutter 的 `StatefulWidget` 之上構建了自定義 widget 系統。

### 套件結構

- **`packages/flutter_compositions/`** - 核心框架，包含響應式原語（`ref`、`computed`、`watch`）和 composables
- **`packages/flutter_compositions_lints/`** - 自定義 lint 規則，用於強制執行響應式最佳實踐
- **`packages/flutter_compositions/example/`** - Flutter 示範應用程式，展示框架功能

## 開發指令

### 初始設定

```bash
# Bootstrap monorepo（連結套件）
melos bootstrap
```

### 執行測試

```bash
# 在所有套件中執行測試
melos run test

# 測試特定套件
cd packages/flutter_compositions
flutter test

# 測試特定檔案
flutter test test/composables_test.dart

# Lints 套件使用 dart test（不是 flutter test）
cd packages/flutter_compositions_lints
dart test test/lints/
dart test test/lints/no_mutable_fields_test.dart
```

### Linting 與分析

```bash
# 分析所有套件
melos run analyze

# 執行自定義 lints（在 monorepo 根目錄）
dart run custom_lint

# 以 watch 模式執行自定義 lints
dart run custom_lint --watch
```

### 執行示範應用

```bash
cd packages/flutter_compositions/example
flutter run
```

## 核心架構

### 響應式系統

框架建立在三個層級上：

1. **`alien_signals`**（依賴項）- 底層響應式原語
   - `WritableSignal` → `Ref<T>`（可寫入的響應式值）
   - `Computed` → `ComputedRef<T>`（衍生值）
   - `Effect` → `watch`/`watchEffect`（副作用）

2. **`CompositionWidget`**（擴展 `StatefulWidget`）- Widget 生命週期整合
   - `setup()` 在 `initState()` 中**執行一次**，回傳一個 builder 函數
   - Builder 函數包裝在 `Effect` 中，當依賴項改變時重新執行
   - `_widgetSignal` 透過 `widget()` 擴展方法啟用響應式 props
   - `_SetupContext` 管理生命週期鉤子和 provide/inject

3. **Composables** - 可重用的組合函數（前綴：`use*`）
   - Controllers：`useScrollController()`、`useTextEditingController()` 等
   - Animations：`useAnimationController()`、`useSingleTickerProvider()`
   - Async：`useFuture()`、`useAsyncData()`、`useStream()`
   - Framework：`useAppLifecycleState()`、`useSearchController()`

### 關鍵實作細節

**Setup 執行流程：**
```
initState()
  → 創建 _SetupContext
  → 設定 parent context（用於 provide/inject）
  → 創建 _widgetSignal（用於響應式 props）
  → 在 effectScope 中執行一次 setup()
  → 儲存回傳的 builder 函數
  → 排程 onMounted 回呼在 post-frame 執行
```

**響應式更新流程：**
```
ref.value = newValue
  → Signal 通知訂閱者
  → Effects 在 microtask 中排隊（批次處理）
  → Builder effect 重新執行
  → 如果 widget tree 改變則呼叫 setState()
  → Flutter 重建
```

**Props 響應式：**
```
didUpdateWidget(oldWidget)
  → _widgetSignal.call(widget)
  → 依賴的 computed 重新計算
  → 如果使用了 props 則 builder 重新執行
```

### Provide/Inject 系統

使用 **parent chain**（不是 `InheritedWidget`）進行依賴注入：

- `_SetupContext._parent` 連結到最近的祖先 CompositionWidget 的 context
- O(d) 查找，其中 d = widget tree 深度
- 不會傳播重建 - refs 處理響應式
- 透過 `InjectionKey<T>` 實現類型安全（在相等比較中包含泛型類型）

### 生命週期鉤子

- **`onMounted(callback)`** - 在第一幀渲染後
- **`onUnmounted(callback)`** - 在 widget 釋放前（清理）
- **`onBuild(callback)`** - 每次 builder 執行（內部由 composables 使用）

鉤子儲存在 `_SetupContext` 中，並在適當的生命週期時刻觸發。

### Effect 管理

所有在 `setup()` 期間創建的 effects 都會透過 `effectScope` 自動追蹤：
- 註冊在 `_SetupContext._effectScope` 中
- 在 `dispose()` 中自動釋放
- `watch`、`watchEffect` 或 builder effects 不需要手動清理

## Custom Lints

### 測試方法

Lints 使用 **`testAnalyzeAndRun()`** 方法（不是 `AnalysisContextCollection`）：

```dart
// ✅ 正確的測試 custom_lint 規則的方法
final errors = await rule.testAnalyzeAndRun(file);
expect(errors.length, expectedCount);
```

**重要：** Custom lint 規則無法使用標準 analyzer APIs 測試。它們必須透過 `custom_lint_builder` 框架執行。

### Lint 規則

所有規則遵循命名慣例：`flutter_compositions_<rule_name>`

1. **`ensure_reactive_props`** - 強制在 `setup()` 中使用 `widget()` 存取 props
2. **`no_async_setup`** - 防止在 `setup()` 方法上使用 `async`
3. **`controller_lifecycle`** - 確保 controllers 使用 `use*` helpers 或手動釋放
4. **`no_mutable_fields`** - 在 CompositionWidget 上強制使用 `final` 欄位
5. **`provide_inject_type_match`** - 警告在 provide/inject 中使用常見類型
6. **`no_conditional_composition`** - 防止條件式呼叫 composition APIs

## 常見模式

### 創建 Composables

Composables 是使用 composition APIs 並回傳響應式值的函數：

```dart
(Ref<int>, void Function()) useCounter({int initialValue = 0}) {
  final count = ref(initialValue);
  void increment() => count.value++;

  // 如需清理
  onUnmounted(() {
    // 清理程式碼
  });

  return (count, increment);
}
```

**命名慣例：** 所有 composables 必須以 `use` 前綴開頭。

### 異步操作

**異步資料的兩階段模式：**

1. **`useFuture`** - 簡單的 future，帶有 `AsyncValue<T>` 狀態
2. **`useAsyncData`** - 進階版，支援 watch 和手動刷新

```dart
// 當 watch 值改變時自動重新獲取
final (status, refresh) = useAsyncData<User, int>(
  (userId) => api.fetchUser(userId),
  watch: () => userId.value,
);

// 如需要可將 status 拆分為個別 refs
final (data, error, loading, hasData) = useAsyncValue(status);
```

**`AsyncValue<T>`** 是一個密封類別，支援模式匹配：
- `AsyncIdle()` - 尚未開始
- `AsyncLoading()` - 進行中
- `AsyncData(value)` - 成功
- `AsyncError(errorValue, stackTrace)` - 失敗

### Controllers 與釋放

**始終使用 `use*` helpers** 處理 controllers 以確保自動釋放：

```dart
// ✅ 自動釋放
final scrollController = useScrollController();
final (textController, text, selection) = useTextEditingController();

// ❌ 需要手動釋放
final controller = ScrollController();
onUnmounted(() => controller.dispose());
```

### 響應式 Props

**必須使用 `widget()` 進行響應式存取：**

```dart
class UserCard extends CompositionWidget {
  final String userId;

  @override
  Widget Function(BuildContext) setup() {
    // ❌ 直接存取 - 非響應式
    final id = userId;

    // ✅ 透過 widget() 進行響應式存取
    final props = widget();
    final greeting = computed(() => 'Hello, user ${props.value.userId}!');

    return (context) => Text(greeting.value);
  }
}
```

## 文件

`docs/` 目錄中的完整文件：

- **`docs/en/guide/`** - 入門指南、響應式基礎、從 StatefulWidget 遷移
- **`docs/api/`** - API 參考（響應式、composables、類型）
- **`docs/lints/`** - Lint 規則文件
- **`docs/en/internals/`** - 技術深入探討、架構、效能

**文件為雙語**（英文/中文），英文在 `docs/en/`，中文在 `docs/guide/`。

## 重要限制

### Setup 函數規則

1. **不能是 async** - 必須同步回傳 builder 函數
   - 使用 `onMounted()` 進行異步初始化

2. **只執行一次** - 不像 React hooks 每次 build 都執行
   - 狀態透過 signals 在重建之間持久化

3. **不能條件式呼叫 composition APIs** - 類似 React hooks 規則
   - 始終以一致的順序呼叫 `ref()`、`computed()` 等

4. **無法存取 BuildContext** - Setup 期間無法使用 context
   - 在回傳的 builder 函數或 `onBuild` 回呼中存取 context

### Hot Reload 行為

- Setup **不會**在 hot reload 時重新執行（設計如此）
- State（refs）被保留
- Computed 值重新計算
- Watch effects 保持活躍

## 測試注意事項

### 核心套件測試

- 使用 `flutter test`（需要 Flutter SDK）
- 測試驗證響應式行為、生命週期和 composables
- Widget 測試使用 `flutter_test` 套件

### Lints 套件測試

- 使用 `dart test`（不是 `flutter test`）
- 測試使用 `custom_lint_builder` 的 `testAnalyzeAndRun()`
- Fixture 檔案在 `test/fixtures/`，帶有 `// expect_lint:` 註釋用於文件
- 所有 6 個 lint 規則都有自動化單元測試

## 檔案結構重點

```
packages/flutter_compositions/
├── lib/
│   ├── flutter_compositions.dart         # 主要匯出
│   └── src/
│       ├── framework.dart                # CompositionWidget、生命週期鉤子
│       ├── compositions.dart             # ref、computed、watch、watchEffect
│       ├── composables.dart              # 所有 composable 匯出
│       ├── composables/                  # 個別 composable 實作
│       ├── composition_builder.dart      # 函數式 composition API
│       └── injection_key.dart            # 類型安全的 DI keys

packages/flutter_compositions_lints/
├── lib/
│   ├── flutter_compositions_lints.dart   # Plugin 入口點
│   └── src/lints/                        # 個別 lint 規則實作
└── test/
    ├── fixtures/                         # 測試 fixture 檔案與範例
    ├── lints/                            # 使用 testAnalyzeAndRun() 的單元測試
    └── integration_test.dart             # 基礎設施測試
```

## 常見陷阱

1. **忘記 `.value`** - Refs 和 computed 值需要 `.value` 來存取/更新
2. **直接存取 prop** - 使用 `widget()` 而不是 `this.propName` 以實現響應式
3. **Async setup** - 使用 `onMounted` 進行異步初始化，不要使用 async setup
4. **Controller 釋放** - 始終使用 `use*` helpers，不要直接創建 controllers
5. **Setup 中的 BuildContext** - 在 builder 中存取 context，不要在 setup 函數中
