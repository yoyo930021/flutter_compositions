# CompositionWidget

用於以組合模式建立響應式 Flutter Widget 的基底類別。

## 概觀

`CompositionWidget` 是 Flutter Compositions 的根基。它取代 `StatefulWidget`，並提供一個唯一的 `setup()` 方法，讓你在其中定義響應式狀態、註冊副作用並回傳建構 UI 的函式。

## 基本用法

```dart
class CounterPage extends CompositionWidget {
  const CounterPage({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    return (context) => Text('Count: ${count.value}');
  }
}
```

## setup 方法

`setup()` 只會在 Widget 初始化時呼叫一次，且必須回傳一個建構函式。

### 方法簽章

```dart
abstract class CompositionWidget extends StatefulWidget {
  Widget Function(BuildContext) setup();
}
```

### 執行時機

- 在 `initState()` 中僅執行 **一次**
- 不可為 `async`
- 無法直接取得 `BuildContext`（需在 builder 中使用 context）
- 所有組合式 API 都必須在 setup 階段呼叫

## 搭配 Props 使用

要以響應式方式取得 props，請使用 `widget()`。

```dart
class UserCard extends CompositionWidget {
  const UserCard({super.key, required this.userId});

  final String userId;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget(); // Reactive access to this widget

    final user = computed(() => fetchUser(props.value.userId));

    return (context) => Text('User: ${user.value}');
  }
}
```

## 生命週期

在 `setup()` 中使用生命週期掛勾：

```dart
@override
Widget Function(BuildContext) setup() {
  onMounted(() {
    print('Widget mounted');
  });

  onUnmounted(() {
    print('Widget will unmount');
  });

  onBuild(() {
    print('Builder executed');
  });

  return (context) => Container();
}
```

## 狀態管理

所有可變狀態都必須透過 `ref()` 管理：

```dart
class TodoList extends CompositionWidget {
  const TodoList({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final todos = ref(<String>[]);
    final newTodo = ref('');

    void addTodo() {
      if (newTodo.value.isNotEmpty) {
        todos.value = [...todos.value, newTodo.value];
        newTodo.value = '';
      }
    }

    return (context) => Column(
      children: [
        TextField(
          onChanged: (value) => newTodo.value = value,
          onSubmitted: (_) => addTodo(),
        ),
        ...todos.value.map((todo) => Text(todo)),
      ],
    );
  }
}
```

## 與組合式函式搭配

使用 composable 函式將可重用的邏輯抽離：

```dart
class SearchPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (searchController, searchText, _) = useTextEditingController();
    final scrollController = useScrollController();

    final results = computed(() => performSearch(searchText.value));

    return (context) => ListView.builder(
      controller: scrollController.value,
      itemCount: results.value.length,
      itemBuilder: (context, index) => Text(results.value[index]),
    );
  }
}
```

## 依賴注入

使用 `provide` 與 `inject` 進行依賴注入：

```dart
// Provider
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(AppTheme.light());
    provide(themeKey, theme);

    return (context) => MaterialApp(home: HomePage());
  }
}

// Consumer
class ThemedWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = inject(themeKey);

    return (context) => Container(
      color: theme.value.backgroundColor,
    );
  }
}
```

## 規則與限制

### setup 不可為非同步

```dart
// ❌ 不佳：非同步的 setup
@override
Future<Widget Function(BuildContext)> setup() async {
  await loadData();
  return (context) => Text('Done');
}

// ✅ 較佳：使用 onMounted 處理非同步
@override
Widget Function(BuildContext) setup() {
  final data = ref<String?>(null);

  onMounted(() async {
    data.value = await loadData();
  });

  return (context) => Text(data.value ?? 'Loading...');
}
```

### 類別欄位必須為 final

```dart
// ❌ 不佳：可變欄位
class MyWidget extends CompositionWidget {
  int count = 0; // 不要這樣做！
}

// ✅ 較佳：使用 ref 管理可變狀態
class MyWidget extends CompositionWidget {
  final int initialCount;

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(initialCount);
    return (context) => Text('${count.value}');
  }
}
```

### 組合式 API 必須在 setup 中呼叫

```dart
// ❌ 不佳：條件式呼叫組合式 API
@override
Widget Function(BuildContext) setup() {
  if (someCondition) {
    final count = ref(0); // 不要這樣做！
  }

  return (context) => Container();
}

// ✅ 較佳：在頂層固定呼叫
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);
  final enabled = ref(someCondition);

  return (context) => enabled.value
    ? Text('${count.value}')
    : Container();
}
```

## 效能考量

- setup 只會執行 **一次**，不會在每次重建時重新執行
- builder 只有在被追蹤的依賴變動時才會重新執行
- 使用 `computed()` 建立衍生資料，避免重覆計算

## 熱重載行為

- 熱重載時不會重新執行 setup
- 透過 ref 管理的狀態會被保留
- computed 與 watcher 會持續運作

## 延伸閱讀

- [setup()](./lifecycle.md#setup) - setup 生命週期
- [widget()](./reactivity.md#widget) - 響應式 props
- [CompositionBuilder](./composition-builder.md) - 函式式 API
- [內建組合式函式](./composables/) - 可重用的組合函式
