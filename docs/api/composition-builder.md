# CompositionBuilder

無需建立類別即可建構 Widget 的函式式組合 API。

## 概觀

`CompositionBuilder` 提供相較於 `CompositionWidget` 的函式式替代方案，讓你在不定義自訂 Widget 類別的情況下使用各種組合式 API。

## 方法簽章

```dart
class CompositionBuilder extends StatefulWidget {
  const CompositionBuilder({
    super.key,
    required this.setup,
  });

  final CompositionSetup setup;
}
```

`CompositionSetup` 是一個回傳 builder 函式的型別別名：

```dart
typedef CompositionSetup = Widget Function(BuildContext) Function();
```

## 基本用法

```dart
CompositionBuilder(
  setup: () {
    final count = ref(0);

    return (context) => Column(
      children: [
        Text('Count: ${count.value}'),
        ElevatedButton(
          onPressed: () => count.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  },
)
```

## 搭配組合式函式

```dart
CompositionBuilder(
  setup: () {
    final (controller, text, _) = useTextEditingController();
    final results = computed(() => search(text.value));

    return (context) => Column(
      children: [
        TextField(controller: controller.value),
        Text('Results: ${results.value.length}'),
      ],
    );
  },
)
```

## 生命週期掛勾

```dart
CompositionBuilder(
  setup: () {
    final data = ref<String?>(null);

    onMounted(() async {
      data.value = await fetchData();
    });

    onUnmounted(() {
      print('Cleaning up');
    });

    return (context) => Text(data.value ?? 'Loading...');
  },
)
```

## 與 CompositionWidget 比較

### 使用 CompositionWidget

```dart
class CounterWidget extends CompositionWidget {
  const CounterWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    return (context) => Text('${count.value}');
  }
}

// 使用方式
CounterWidget()
```

### 使用 CompositionBuilder

```dart
CompositionBuilder(
  setup: () {
    final count = ref(0);
    return (context) => Text('${count.value}');
  },
)
```

## 適用情境

### 適合使用 CompositionBuilder

- 快速原型開發
- 單次使用的 Widget
- 簡單的區域狀態
- 需要就地撰寫組合邏輯

```dart
// ✅ 較佳：簡單、一次性的用法
ListView(
  children: [
    CompositionBuilder(
      setup: () {
        final expanded = ref(false);
        return (context) => ExpansionTile(...);
      },
    ),
  ],
)
```

### 適合選擇 CompositionWidget

- 需要重複使用的元件
- 複雜的 Widget
- 需要接收 props
- 需要較佳的可測試性

```dart
// ✅ 較佳：可重用元件
class UserCard extends CompositionWidget {
  const UserCard({super.key, required this.user});

  final User user;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    return (context) => Card(
      child: Text(props.value.user.name),
    );
  }
}
```

## 進階範例

```dart
CompositionBuilder(
  setup: () {
    final userId = ref(1);
    final (userData, refresh) = useAsyncData<User, int>(
      (id) => api.fetchUser(id),
      watch: () => userId.value,
    );

    final scrollController = useScrollController();

    watchEffect(() {
      print('User data changed: ${userData.value}');
    });

    return (context) => RefreshIndicator(
      onRefresh: refresh,
      child: switch (userData.value) {
        AsyncLoading() => CircularProgressIndicator(),
        AsyncData(:final value) => ListView(
            controller: scrollController.value,
            children: [
              Text('Name: ${value.name}'),
              Text('Email: ${value.email}'),
            ],
          ),
        AsyncError(:final errorValue) => Text('Error: $errorValue'),
        _ => SizedBox.shrink(),
      },
    );
  },
)
```

## 最佳實務

### 將複雜邏輯抽成組合式函式

```dart
// ❌ 不佳：setup 回傳的 builder 中邏輯過多
CompositionBuilder(
  setup: () {
    final name = ref('');
    final email = ref('');
    final isValid = computed(() =>
      name.value.isNotEmpty && email.value.contains('@'));

    void submit() {
      if (isValid.value) {
        api.submit(name.value, email.value);
      }
    }

    return (context) => Form(...);
  },
)

// ✅ 較佳：抽成 composable
(Ref<String>, Ref<String>, ComputedRef<bool>, void Function()) useFormValidation() {
  final name = ref('');
  final email = ref('');
  final isValid = computed(() =>
    name.value.isNotEmpty && email.value.contains('@'));

  void submit() {
    if (isValid.value) {
      api.submit(name.value, email.value);
    }
  }

  return (name, email, isValid, submit);
}

CompositionBuilder(
  setup: () {
    final (name, email, isValid, submit) = useFormValidation();
    return (context) => Form(...);
  },
)
```

### 重複使用請改用 CompositionWidget

```dart
// ❌ 不佳：重複撰寫 CompositionBuilder
ListView(
  children: [
    CompositionBuilder(setup: () => ...counterLogic...),
    CompositionBuilder(setup: () => ...counterLogic...), // 重複！
    CompositionBuilder(setup: () => ...counterLogic...),
  ],
)

// ✅ 較佳：抽成可重用的 Widget
class Counter extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    return (context) => Text('${count.value}');
  }
}

ListView(
  children: [
    Counter(),
    Counter(),
    Counter(),
  ],
)
```

## 延伸閱讀

- [CompositionWidget](./composition-widget.md) - 類別式組合
- [ref](./reactivity.md#ref) - 響應式狀態
- [組合式函式](./composables/) - 可重用的組合邏輯
