# 響應式基礎

理解 Flutter Compositions 的響應式系統是構建高效、可維護應用程式的關鍵。本指南將解釋核心的響應式原語以及它們如何協同工作。

## 概述

Flutter Compositions 使用由 [`alien_signals`](https://pub.dev/packages/alien_signals) 提供支援的細粒度響應式系統。與 Flutter 的 `setState` 重建整個 Widget 子樹不同，此系統僅更新依賴於已更改資料的 UI 特定部分。

## 響應式的三大支柱

### 1. Ref - 響應式狀態

`ref()` 建立可讀寫的響應式狀態。當你修改 ref 的值時，所有依賴它的計算和 UI 元件會自動更新。

```dart
// Create a ref
final count = ref(0);

// Read the value
print(count.value); // 0

// Write the value (triggers reactivity)
count.value++;
print(count.value); // 1
```

**重點**:
- 始終透過 `.value` 存取狀態
- 寫入操作會觸發自動更新
- Ref 可以儲存任何類型:基本類型、物件、列表等

### 2. Computed - 衍生狀態

`computed()` 建立從其他響應式狀態衍生的值。它們會在依賴項變更時自動更新,並會快取直到依賴項變更。

```dart
final count = ref(0);
final doubled = computed(() => count.value * 2);

print(doubled.value); // 0

count.value = 5;
print(doubled.value); // 10
```

**重點**:
- 惰性求值 - 僅在存取時計算
- 自動依賴追蹤
- 快取結果以提升效能
- 唯讀(使用 `writableComputed` 實現雙向)

### 3. Watch - 副作用

`watch()` 和 `watchEffect()` 在響應式依賴項變更時執行副作用。

#### watch()

明確指定要監聽的內容:

```dart
final count = ref(0);

watch(
  () => count.value,  // Getter: what to watch
  (newValue, oldValue) {  // Callback: what to do
    print('Count changed: $oldValue → $newValue');
  },
);

count.value = 1;  // Prints: "Count changed: 0 → 1"
```

#### watchEffect()

自動追蹤所有依賴項:

```dart
final firstName = ref('John');
final lastName = ref('Doe');

watchEffect(() {
  // Automatically tracks both refs
  print('Full name: ${firstName.value} ${lastName.value}');
});

firstName.value = 'Jane';  // Prints: "Full name: Jane Doe"
lastName.value = 'Smith';  // Prints: "Full name: Jane Smith"
```

**何時使用哪個**:
- 當你需要存取新舊值時使用 `watch()`
- 對於更簡單的副作用使用 `watchEffect()`
- 當你想要明確控制依賴項時使用 `watch()`

## 響應式實戰

### 範例:待辦事項清單

```dart
class TodoList extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // State: list of todos
    final todos = ref(<String>['Buy milk', 'Walk dog']);

    // State: filter
    final filter = ref('all'); // 'all', 'completed', 'active'

    // State: completion status
    final completed = ref(<bool>[false, false]);

    // Computed: filtered todos
    final filteredTodos = computed(() {
      if (filter.value == 'all') {
        return List.generate(
          todos.value.length,
          (i) => todos.value[i],
        );
      } else if (filter.value == 'completed') {
        return [
          for (var i = 0; i < todos.value.length; i++)
            if (completed.value[i]) todos.value[i],
        ];
      } else { // 'active'
        return [
          for (var i = 0; i < todos.value.length; i++)
            if (!completed.value[i]) todos.value[i],
        ];
      }
    });

    // Computed: stats
    final totalCount = computed(() => todos.value.length);
    final completedCount = computed(
      () => completed.value.where((c) => c).length,
    );

    // Side effect: log changes
    watch(
      () => completedCount.value,
      (newCount, oldCount) {
        print('Completed: $oldCount → $newCount');
      },
    );

    // Functions
    void addTodo(String todo) {
      todos.value = [...todos.value, todo];
      completed.value = [...completed.value, false];
    }

    void toggleTodo(int index) {
      final newCompleted = [...completed.value];
      newCompleted[index] = !newCompleted[index];
      completed.value = newCompleted;
    }

    return (context) => Column(
      children: [
        // Add todo input
        TextField(
          onSubmitted: addTodo,
          decoration: InputDecoration(hintText: 'Add todo...'),
        ),

        // Filter buttons
        Row(
          children: [
            for (final f in ['all', 'active', 'completed'])
              ElevatedButton(
                onPressed: () => filter.value = f,
                child: Text(f),
              ),
          ],
        ),

        // Stats
        Text('Total: ${totalCount.value}, Completed: ${completedCount.value}'),

        // Todo list
        for (var i = 0; i < filteredTodos.value.length; i++)
          ListTile(
            title: Text(filteredTodos.value[i]),
            leading: Checkbox(
              value: completed.value[todos.value.indexOf(filteredTodos.value[i])],
              onChanged: (_) => toggleTodo(
                todos.value.indexOf(filteredTodos.value[i]),
              ),
            ),
          ),
      ],
    );
  }
}
```

## 響應式集合

在處理集合(Lists、Maps、Sets)時,你必須建立新實例來觸發響應式:

```dart
final items = ref(<String>[]);

// ❌ This won't trigger updates
items.value.add('new item');

// ✅ Create a new list
items.value = [...items.value, 'new item'];

// ✅ Or use spread operator
items.value = [...items.value];
```

## 常見模式

### 模式 1:輸入綁定

```dart
final name = ref('');

return (context) => TextField(
  onChanged: (value) => name.value = value,
  controller: TextEditingController(text: name.value),
);

// Better: use useTextEditingController
final (controller, text, _) = useTextEditingController();
return (context) => TextField(controller: controller);
```

### 模式 2:條件渲染

```dart
final isLoggedIn = ref(false);

return (context) => isLoggedIn.value
    ? Text('Welcome back!')
    : ElevatedButton(
        onPressed: () => isLoggedIn.value = true,
        child: Text('Login'),
      );
```

### 模式 3:列表渲染

```dart
final items = ref(['Apple', 'Banana', 'Cherry']);

return (context) => Column(
  children: [
    for (final item in items.value)
      ListTile(title: Text(item)),
  ],
);
```

### 模式 4:非同步資料

```dart
final user = ref<User?>(null);
final loading = ref(false);

onMounted(() async {
  loading.value = true;
  user.value = await fetchUser();
  loading.value = false;
});

return (context) {
  if (loading.value) return CircularProgressIndicator();
  if (user.value == null) return Text('No user');
  return Text('Hello, ${user.value!.name}');
};

// Better: use useFuture or useAsyncData
final userData = useFuture(() => fetchUser());
return (context) => switch (userData.value) {
  AsyncLoading() => CircularProgressIndicator(),
  AsyncData(:final value) => Text('Hello, ${value.name}'),
  _ => Text('No user'),
};
```

## 效能提示

### 1. 保持 Computed 函式的純粹性

```dart
// ✅ Good - pure function
final greeting = computed(() => 'Hello, ${name.value}');

// ❌ Bad - side effects
final greeting = computed(() {
  print('Computing...'); // Side effect!
  return 'Hello, ${name.value}';
});
```

### 2. 最小化 Builder 中的依賴項

```dart
// ❌ Rebuilds on any count change
return (context) => Column(
  children: [
    Text('Count: ${count.value}'),
    ExpensiveWidget(), // Rebuilds unnecessarily
  ],
);

// ✅ Extract to separate widget
return (context) => Column(
  children: [
    Text('Count: ${count.value}'),
    const ExpensiveWidget(), // Doesn't rebuild
  ],
);
```

### 3. 對昂貴的計算使用 Computed

```dart
// ❌ Calculates on every access
final sum = items.value.fold(0, (a, b) => a + b);

// ✅ Cached until items changes
final sum = computed(() => items.value.fold(0, (a, b) => a + b));
```

## 除錯響應式

### 檢查依賴項

```dart
// Add logging to see when computed runs
final doubled = computed(() {
  print('Computing doubled');
  return count.value * 2;
});
```

### 監聽所有變更

```dart
watchEffect(() {
  print('Count: ${count.value}');
  print('Name: ${name.value}');
  // Prints whenever count OR name changes
});
```

## 常見陷阱

### 陷阱 1:忘記 `.value`

```dart
// ❌ Compares Ref objects, not values
if (count == 5) { /* never true */ }

// ✅ Compare values
if (count.value == 5) { /* works */ }
```

### 陷阱 2:直接讀取 Props

```dart
// ❌ Captures initial prop value only
final greeting = computed(() => 'Hello, $name');

// ✅ Reactive to prop changes
final props = widget();
final greeting = computed(() => 'Hello, ${props.value.name}');
```

### 陷阱 3:變更集合

```dart
// ❌ Mutation doesn't trigger update
items.value.add('new');

// ✅ Create new collection
items.value = [...items.value, 'new'];
```

## 下一步

- 了解[內建 Composables](./built-in-composables.md) 以學習常見模式
- 探索[非同步操作](./async-operations.md) 以處理 futures 和 streams
- 閱讀[深入響應式](../internals/reactivity-in-depth.md) 以學習進階概念
