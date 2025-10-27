# 組合式函式 API 參考

組合式函式（composables）是可重用的組合函式，用於封裝具狀態的邏輯。所有組合式函式皆遵循 `use*` 命名慣例，並會自動處理資源釋放。

## 概覽

Flutter Compositions 提供多種常見情境的內建組合式函式：

- **[控制器](./controllers.md)**：自動釋放的 Flutter 控制器
- **[動畫](./animations.md)**：動畫控制器與響應式動畫值
- **[非同步](./async.md)**：具狀態追蹤的非同步操作
- **[Listenable](./listenable.md)**：管理 Listenable 與 ValueListenable
- **[框架整合](./framework.md)**：與 Flutter 框架整合的輔助工具

## 分類

### 控制器相關組合式函式

管理 Flutter 控制器並自動釋放資源：

| Composable | 說明 | 回傳值 |
|------------|------|--------|
| `useScrollController` | 自動釋放的 ScrollController | `Ref<ScrollController>` |
| `usePageController` | 自動釋放的 PageController | `Ref<PageController>` |
| `useTextEditingController` | Reactive 的 TextEditingController 與文字/選取狀態 | `(Ref<TextEditingController>, Ref<String>, Ref<TextSelection>)` |
| `useFocusNode` | 自動釋放的 FocusNode | `Ref<FocusNode>` |
| `useTabController` | 自動釋放的 TabController | `Ref<TabController>` |

[閱讀控制器文件 →](./controllers.md)

### 動畫相關組合式函式

建立具自動釋放與響應式值的動畫：

| Composable | 說明 | 回傳值 |
|------------|------|--------|
| `useAnimationController` | 具有響應式值的 AnimationController | `(AnimationController, Ref<double>)` |
| `useSingleTickerProvider` | 單一 AnimationController 用的 TickerProvider | `TickerProvider` |
| `manageAnimation` | 具自動釋放的 Tween 動畫 | `Animation<T>` |

[閱讀動畫文件 →](./animations.md)

### 非同步相關組合式函式

以響應式方式管理非同步操作：

| Composable | 說明 | 回傳值 |
|------------|------|--------|
| `useFuture` | 執行 Future 並追蹤其狀態 | `Ref<AsyncValue<T>>` |
| `useAsyncData` | 進階非同步工具，支援 watch 與手動更新 | `(ReadonlyRef<AsyncValue<T>>, void Function())` |
| `useAsyncValue` | 將 AsyncValue 拆成多個 refs | `(data, error, loading, hasData)` |
| `useStream` | 追蹤 Stream 最新值 | `Ref<T>` |
| `useStreamController` | 具響應式追蹤的 StreamController | `(StreamController<T>, Ref<T>)` |

[閱讀非同步文件 →](./async.md)

### Listenable 相關組合式函式

以響應式方式管理 Listenable 物件：

| Composable | 說明 | 回傳值 |
|------------|------|--------|
| `manageListenable` | 自動釋放 Listenable，並觸發重建 | `T` |
| `manageValueListenable` | 自動釋放 ValueListenable 並取得響應式值 | `Ref<V>` |

[閱讀 Listenable 文件 →](./listenable.md)

### 框架整合組合式函式

協助整合 Flutter 框架的工具：

| Composable | 說明 | 回傳值 |
|------------|------|--------|
| `useContext` | 在建構期間取得 BuildContext | `BuildContext` |
| `useAppLifecycleState` | 響應式追蹤 App 生命週期 | `Ref<AppLifecycleState>` |
| `useSearchController` | 自動釋放的 SearchController | `Ref<SearchController>` |

[閱讀框架整合文件 →](./framework.md)

## 使用範例

### 含文字輸入的基本計數器

```dart
class CounterForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    final (controller, text, _) = useTextEditingController();

    void incrementByInput() {
      final value = int.tryParse(text.value) ?? 1;
      count.value += value;
    }

    return (context) => Column(
      children: [
        Text('Count: ${count.value}'),
        TextField(
          controller: controller.value,
          decoration: InputDecoration(labelText: 'Increment by'),
          keyboardType: TextInputType.number,
        ),
        ElevatedButton(
          onPressed: incrementByInput,
          child: Text('Add'),
        ),
      ],
    );
  }
}
```

### 結合非同步資料的動畫清單

```dart
class UserList extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: Duration(milliseconds: 300),
    );

    final (userData, refresh) = useAsyncData<List<User>, void>(
      (_) => api.fetchUsers(),
    );

    watch(() => userData.value, (value, _) {
      if (value.isData) {
        controller.forward();
      }
    });

    onMounted(() => refresh());

    return (context) {
      return switch (userData.value) {
        AsyncLoading() => Center(child: CircularProgressIndicator()),
        AsyncError(:final errorValue) => Center(
          child: Column(
            children: [
              Text('Error: $errorValue'),
              ElevatedButton(onPressed: refresh, child: Text('Retry')),
            ],
          ),
        ),
        AsyncData(:final value) => FadeTransition(
          opacity: controller,
          child: ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, index) => UserTile(user: value[index]),
          ),
        ),
        AsyncIdle() => SizedBox.shrink(),
      };
    };
  }
}
```

### 根據捲動驅動的動畫

```dart
class ScrollAnimatedHeader extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final scrollController = useScrollController();
    final headerHeight = ref(200.0);

    watchEffect(() {
      final offset = scrollController.value.offset;
      headerHeight.value = (200 - offset).clamp(60.0, 200.0);
    });

    return (context) => CustomScrollView(
      controller: scrollController.value,
      slivers: [
        SliverAppBar(
          expandedHeight: headerHeight.value,
          flexibleSpace: FlexibleSpaceBar(title: Text('Dynamic Header')),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ListTile(title: Text('Item $index')),
            childCount: 50,
          ),
        ),
      ],
    );
  }
}
```

## 建立自訂組合式函式

組合式函式通常會使用響應式原語並回傳可重用的值：

```dart
/// Track mouse position (for web/desktop)
(Ref<Offset>, Ref<bool>) useMousePosition() {
  final position = ref(Offset.zero);
  final isInside = ref(false);

  onBuild((context) {
    // 針對指標事件更新位置
  });

  return (position, isInside);
}

/// 具防抖效果的輸入
Ref<String> useDebouncedValue(Ref<String> source, {Duration delay = const Duration(milliseconds: 500)}) {
  final debounced = ref(source.value);
  Timer? timer;

  watch(() => source.value, (newValue, _) {
    timer?.cancel();
    timer = Timer(delay, () {
      debounced.value = newValue;
    });
  });

  onUnmounted(() => timer?.cancel());

  return debounced;
}

/// 表單驗證
(Ref<bool>, Ref<String?>) useValidation(
  Ref<String> input,
  String? Function(String) validator,
) {
  final isValid = ref(false);
  final errorMessage = ref<String?>(null);

  watch(() => input.value, (value, _) {
    final error = validator(value);
    errorMessage.value = error;
    isValid.value = error == null;
  });

  return (isValid, errorMessage);
}
```

## 最佳實務

### 1. 控制器務必使用 `use*` 輔助函式

```dart
// ✅ 較佳：自動釋放
final scrollController = useScrollController();

// ❌ 不佳：需要手動釋放
final controller = ScrollController();
onUnmounted(() => controller.dispose());
```

### 2. 結合多個組合式函式以處理複雜邏輯

```dart
@override
Widget Function(BuildContext) setup() {
  // 結合多個組合式函式
  final (controller, text, _) = useTextEditingController();
  final scrollController = useScrollController();
  final (animController, animValue) = useAnimationController(
    duration: Duration(milliseconds: 300),
  );

  // 共同協作
  watch(() => text.value, (value, _) {
    if (value.isNotEmpty) {
      animController.forward();
    } else {
      animController.reverse();
    }
  });

  return (context) => /* ... */;
}
```

### 3. 將重複邏輯提取為自訂組合式函式

```dart
// 與其重覆撰寫以下邏輯：
final input1 = ref('');
final valid1 = computed(() => input1.value.length >= 6);

final input2 = ref('');
final valid2 = computed(() => input2.value.length >= 6);

// 建立一個組合式函式：
(Ref<String>, Ref<bool>) useValidatedInput({int minLength = 6}) {
  final input = ref('');
  final isValid = computed(() => input.value.length >= minLength);
  return (input, isValid);
}

// 直接使用：
final (email, emailValid) = useValidatedInput(minLength: 5);
final (password, passwordValid) = useValidatedInput(minLength: 8);
```

### 4. 以易懂的方式命名組合式函式

```dart
// ✅ 較佳：目的清楚
useFormValidation()
useDebounceInput()
useWindowSize()
usePagination()

// ❌ 不佳：意義含糊
useHelper()
useUtils()
useState()
```

## 延伸閱讀

- [建立組合式函式指南](../../guide/creating-composables.md) - 如何打造自訂 composable
- [內建組合式函式](../../guide/built-in-composables.md) - 各類型與使用範例
- [生命週期掛勾](../lifecycle.md) - onMounted、onUnmounted、onBuild
- [響應式基礎](../../guide/reactivity-fundamentals.md) - ref、computed、watch
