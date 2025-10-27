# ComputedBuilder

建立細粒度響應式範圍的 Widget。

## 概觀

`ComputedBuilder` 會建立獨立的響應式範圍，僅在其中使用到的響應式依賴發生變化時重新建構。這類似 Vue 的細粒度響應式或 Solid.js 的 reactive primitive。

與 `CompositionWidget` 的 builder 不同，後者只要任一依賴改變就會重建整個子樹；`ComputedBuilder` 只會重建自己與子節點。

## 類別定義

```dart
class ComputedBuilder extends StatefulWidget {
  const ComputedBuilder({
    required this.builder,
    Key? key,
  });

  final Widget Function() builder;
}
```

- `builder`：負責建立 Widget 的函式，會在響應式效果中執行並自動追蹤依賴。

回傳的 `StatefulWidget` 只會在相關依賴變更時重建。

## 基本用法

```dart
class Counter extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count1 = ref(0);
    final count2 = ref(0);

    return (context) => Column(
      children: [
        // 只有 count1 改變時才會重建
        ComputedBuilder(
          builder: () => Text('Count1: ${count1.value}'),
        ),

        // 只有 count2 改變時才會重建
        ComputedBuilder(
          builder: () => Text('Count2: ${count2.value}'),
        ),

        // 靜態內容永遠不重建
        const Text('This is static'),

        ElevatedButton(
          onPressed: () => count1.value++,
          child: const Text('Increment Count1'),
        ),
      ],
    );
  }
}
```

## 效能優勢

### 未使用 ComputedBuilder

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  return (context) => Column(
    children: [
      Text('Count: ${count.value}'),
      const ExpensiveStaticWidget(),  // 會被迫重建
      const AnotherExpensiveWidget(), // 同樣重建
    ],
  );
}
```

每次 `count` 改變整個 `Column` 與子節點都會重建。

### 使用 ComputedBuilder

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  return (context) => Column(
    children: [
      ComputedBuilder(
        builder: () => Text('Count: ${count.value}'),
      ),
      const ExpensiveStaticWidget(),  // 永不重建
      const AnotherExpensiveWidget(), // 永不重建
    ],
  );
}
```

只有 `ComputedBuilder` 裡的 `Text` 會因 `count` 更新而重建。

## 適用情境

### 1. 高频率更新

```dart
@override
Widget Function(BuildContext) setup() {
  final progress = ref(0.0);

  // 以 60FPS 更新
  onMounted(() {
    Timer.periodic(const Duration(milliseconds: 16), (_) {
      progress.value = (progress.value + 0.01) % 1.0;
    });
  });

  return (context) => Column(
    children: [
      ComputedBuilder(
        builder: () => LinearProgressIndicator(value: progress.value),
      ),
      const Text('Loading...'),
      const Divider(),
      const Text('Please wait...'),
    ],
  );
}
```

### 2. 具獨立狀態的清單項目

```dart
class TodoItem {
  final String title;
  final Ref<bool> completed;

  TodoItem(this.title) : completed = ref(false);
}

@override
Widget Function(BuildContext) setup() {
  final items = ref<List<TodoItem>>([
    TodoItem('Task 1'),
    TodoItem('Task 2'),
    TodoItem('Task 3'),
  ]);

  return (context) => ListView.builder(
    itemCount: items.value.length,
    itemBuilder: (context, index) {
      final item = items.value[index];

      return ListTile(
        leading: ComputedBuilder(
          builder: () => Checkbox(
            value: item.completed.value,
            onChanged: (value) => item.completed.value = value ?? false,
          ),
        ),
        title: Text(item.title),
      );
    },
  );
}
```

### 3. 昂貴的衍生運算

```dart
@override
Widget Function(BuildContext) setup() {
  final items = ref<List<Item>>([...]);
  final filter = ref('');

  final filteredItems = computed(() {
    final query = filter.value.toLowerCase();
    if (query.isEmpty) return items.value;

    return items.value.where((item) {
      return item.name.toLowerCase().contains(query);
    }).toList();
  });

  return (context) => Column(
    children: [
      TextField(onChanged: (value) => filter.value = value),
      ComputedBuilder(
        builder: () => Text('Found: ${filteredItems.value.length} items'),
      ),
      const ExpensiveFilterPanel(),
      const ExpensiveChartWidget(),
    ],
  );
}
```

### 4. 表單驗證

```dart
@override
Widget Function(BuildContext) setup() {
  final email = ref('');
  final password = ref('');

  final emailError = computed(() {
    if (email.value.isEmpty) return null;
    if (!email.value.contains('@')) return 'Invalid email';
    return null;
  });

  final passwordError = computed(() {
    if (password.value.isEmpty) return null;
    if (password.value.length < 8) return 'Password too short';
    return null;
  });

  return (context) => Column(
    children: [
      TextField(
        onChanged: (value) => email.value = value,
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      ComputedBuilder(
        builder: () {
          final error = emailError.value;
          return error != null
              ? Text(error, style: const TextStyle(color: Colors.red))
              : const SizedBox.shrink();
        },
      ),
      TextField(
        onChanged: (value) => password.value = value,
        decoration: const InputDecoration(labelText: 'Password'),
        obscureText: true,
      ),
      ComputedBuilder(
        builder: () {
          final error = passwordError.value;
          return error != null
              ? Text(error, style: const TextStyle(color: Colors.red))
              : const SizedBox.shrink();
        },
      ),
    ],
  );
}
```

### 5. 條件式渲染

```dart
@override
Widget Function(BuildContext) setup() {
  final isLoggedIn = ref(false);
  final userData = ref<User?>(null);

  return (context) => Scaffold(
    appBar: AppBar(title: const Text('My App')),
    body: ComputedBuilder(
      builder: () {
        if (!isLoggedIn.value) return const LoginScreen();
        if (userData.value == null) return const CircularProgressIndicator();
        return UserDashboard(user: userData.value!);
      },
    ),
  );
}
```

## 運作原理

`ComputedBuilder` 會建立自己的 reactive effect，只追蹤 `builder` 內使用的 signal。當依賴改變時：

1. effect 偵測到變化
2. 重新執行 `builder`
3. 僅呼叫自身 `setState()`
4. 只重建 `ComputedBuilder` 內的 widget 子樹
5. 父層與兄弟節點維持不變

```dart
class _ComputedBuilderState extends State<ComputedBuilder> {
  Effect? _effect;
  Widget? _cachedWidget;

  @override
  void initState() {
    super.initState();
    _effect = effect(() {
      final newWidget = widget.builder();
      if (mounted) {
        setState(() {
          _cachedWidget = newWidget;
        });
      }
    });
  }
}
```

## 最佳實務

### 隔離高頻更新

```dart
// ✅ 較佳：只讓高頻更新的區域重建
return Column(
  children: [
    ComputedBuilder(
      builder: () => Text('FPS: ${fps.value}'),
    ),
    const ExpensiveChart(),
  ],
);

// ⚠️ 請避免：整個樹頻繁重建
return Column(
  children: [
    Text('FPS: ${fps.value}'),
    const ExpensiveChart(), // 不必要重建
  ],
);
```

### 只包裹需要更新的範圍

```dart
// ✅ 較佳：縮小作用範圍
return Column(
  children: [
    const Header(),
    ComputedBuilder(
      builder: () => Text('Count: ${count.value}'),
    ),
    const Footer(),
  ],
);

// ⚠️ 請避免：範圍過大
return ComputedBuilder(
  builder: () => Column(
    children: [
      const Header(),
      Text('Count: ${count.value}'),
      const Footer(),
    ],
  ),
);
```

### 與 computed 搭配

```dart
final displayText = computed(() {
  final items = itemList.value;
  return 'Total: ${items.length} items';
});

return ComputedBuilder(
  builder: () => Text(displayText.value),
);
```

### 避免在 builder 中做副作用

```dart
// ⚠️ 請避免：在 builder 內執行副作用
ComputedBuilder(
  builder: () {
    print('Building...'); // 不要這樣做！
    api.trackView(count.value); // 不要這樣做！
    return Text('Count: ${count.value}');
  },
);

// ✅ 較佳：改用 watch
watch(() => count.value, (value, _) {
  print('Count changed to $value');
  api.trackView(value);
});

return ComputedBuilder(
  builder: () => Text('Count: ${count.value}'),
);
```

### 為獨立狀態建立多個範圍

```dart
// ✅ 較佳：獨立的 reactive 範圍
return Row(
  children: [
    ComputedBuilder(
      builder: () => Text('Left: ${leftCount.value}'),
    ),
    ComputedBuilder(
      builder: () => Text('Right: ${rightCount.value}'),
    ),
  ],
);
```

## 效能比較

情境：1000 個清單項目

**未使用 ComputedBuilder**

```dart
return ListView.builder(
  itemCount: items.value.length,
  itemBuilder: (context, index) {
    final item = items.value[index];
    return ListTile(
      title: Text(item.name),
      trailing: Text('${item.count.value}'),
    );
  },
);
```

任一項目的 `count` 改變，整個清單重建。

**使用 ComputedBuilder**

```dart
return ListView.builder(
  itemCount: items.value.length,
  itemBuilder: (context, index) {
    final item = items.value[index];
    return ListTile(
      title: Text(item.name),
      trailing: ComputedBuilder(
        builder: () => Text('${item.count.value}'),
      ),
    );
  },
);
```

只有對應的 `Text` 會重建，重建次數減少 1000 倍。

## 常見模式

### 載入遮罩

```dart
return Stack(
  children: [
    const MainContent(),
    ComputedBuilder(
      builder: () {
        if (!isLoading.value) return const SizedBox.shrink();
        return Container(
          color: Colors.black26,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    ),
  ],
);
```

### 條件式內容

```dart
return Column(
  children: [
    const Header(),
    ComputedBuilder(
      builder: () =>
          showDetails.value ? const DetailedView() : const SummaryView(),
    ),
    const Footer(),
  ],
);
```

### 主題樣式

```dart
final isDark = ref(false);

return ComputedBuilder(
  builder: () => Container(
    color: isDark.value ? Colors.black : Colors.white,
    child: Text(
      'Hello',
      style: TextStyle(
        color: isDark.value ? Colors.white : Colors.black,
      ),
    ),
  ),
);
```

## 與其他解決方案比較

### vs. StatefulWidget

```dart
// StatefulWidget：樣板較多
class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Text('Count: $count');
  }
}

// ComputedBuilder：更精簡
final count = ref(0);
return ComputedBuilder(
  builder: () => Text('Count: ${count.value}'),
);
```

### vs. StreamBuilder

```dart
// StreamBuilder：需要額外建立 stream
final controller = StreamController<int>();
return StreamBuilder<int>(
  stream: controller.stream,
  initialData: 0,
  builder: (context, snapshot) => Text('Count: ${snapshot.data}'),
);

// ComputedBuilder：直接使用響應式值
final count = ref(0);
return ComputedBuilder(
  builder: () => Text('Count: ${count.value}'),
);
```

### vs. ValueListenableBuilder

```dart
// ValueListenableBuilder：限於 ValueNotifier
final count = ValueNotifier<int>(0);
return ValueListenableBuilder<int>(
  valueListenable: count,
  builder: (context, value, child) => Text('Count: $value'),
);

// ComputedBuilder：適用所有響應式值
final count = ref(0);
final doubled = computed(() => count.value * 2);
return ComputedBuilder(
  builder: () => Text('Doubled: ${doubled.value}'),
);
```

## 延伸閱讀

- [CompositionWidget](../composition-widget.md) - 主要的響應式 Widget
- [computed](../reactivity.md#computed) - 建立衍生值
- [ref](../reactivity.md#ref) - 建立響應式參照
- [watch](../watch.md) - 設定副作用與監看器
- [細粒度響應式指南](../../guide/reactivity-fundamentals.md) - Reactivity 基礎概念
