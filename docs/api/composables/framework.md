# 框架整合組合式函式

協助整合 Flutter 框架並具響應式狀態追蹤的組合式函式。

## useContext

建立指向 BuildContext 的響應式參照。

### 方法簽章

```dart
Ref<BuildContext?> useContext()
```

### 回傳值

`Ref<BuildContext?>`，可在 builder 函式中填入 BuildContext。

### 重要說明

BuildContext 只會在 builder 函式中可用，而非 `setup()`。ref 初始為 `null`，必須在 builder 中設定。

### 範例：基本使用

```dart
@override
Widget Function(BuildContext) setup() {
  final contextRef = useContext();

  return (buildContext) {
    // 在 builder 中設定 context
    contextRef.value = buildContext;

    // 之後即可使用
    final theme = Theme.of(contextRef.value!);
    return Text('Primary color: ${theme.primaryColor}');
  };
}
```

### 更好的方式：直接存取

```dart
@override
Widget Function(BuildContext) setup() {
  // 多數情況下直接存取更簡潔
  return (context) {
    final theme = Theme.of(context);
    return Text('Primary color: ${theme.primaryColor}');
  };
}
```

### 使用時機

`useContext()` 主要用在需要將 context 傳給回呼，或是稍後再存取時。大部分情況直接在 builder 中使用 context 更簡潔有效率。

```dart
@override
Widget Function(BuildContext) setup() {
  final contextRef = useContext();

  void showMessage() {
    if (contextRef.value != null) {
      ScaffoldMessenger.of(contextRef.value!).showSnackBar(
        const SnackBar(content: Text('Hello!')),
      );
    }
  }

  return (context) {
    contextRef.value = context;

    return ElevatedButton(
      onPressed: showMessage,
      child: const Text('Show Message'),
    );
  };
}
```

---

## useAppLifecycleState

建立可追蹤 App 生命週期狀態的響應式參照。

### 方法簽章

```dart
Ref<AppLifecycleState> useAppLifecycleState()
```

### 回傳值

`Ref<AppLifecycleState>`，當 App 生命週期改變時會自動更新。

### 生命週期狀態

- `AppLifecycleState.resumed`：App 可見且可回應使用者
- `AppLifecycleState.inactive`：App 暫時不活躍（例如通話期間）
- `AppLifecycleState.paused`：App 目前不可見
- `AppLifecycleState.detached`：App 仍在執行但與畫面分離
- `AppLifecycleState.hidden`：App 被隱藏（iOS 13+）

### 範例：基本使用

```dart
@override
Widget Function(BuildContext) setup() {
  final lifecycleState = useAppLifecycleState();

  // 對生命週期變化做出反應
  watch(
    () => lifecycleState.value,
    (newState, oldState) {
      print('App lifecycle changed: $oldState -> $newState');

      if (newState == AppLifecycleState.resumed) {
        print('App resumed - refresh data');
      } else if (newState == AppLifecycleState.paused) {
        print('App paused - save state');
      }
    },
  );

  return (context) => Column(
    children: [
      Text('Current state: ${lifecycleState.value}'),
      if (lifecycleState.value == AppLifecycleState.resumed)
        const Text('App is active')
      else
        const Text('App is not active'),
    ],
  );
}
```

### 範例：進入背景時暫停影片

```dart
@override
Widget Function(BuildContext) setup() {
  final lifecycleState = useAppLifecycleState();
  final videoController = useVideoController();

  watch(
    () => lifecycleState.value,
    (newState, oldState) {
      if (newState == AppLifecycleState.paused) {
        videoController.value.pause();
      } else if (newState == AppLifecycleState.resumed) {
        videoController.value.play();
      }
    },
  );

  return (context) => VideoPlayer(videoController.value);
}
```

### Example - Auto-Refresh Data

```dart
@override
Widget Function(BuildContext) setup() {
  final lifecycleState = useAppLifecycleState();
  final (userData, refresh) = useAsyncData<User, void>(
    (_) => api.fetchUser(),
  );

  // App 回到前景時刷新資料
  watch(
    () => lifecycleState.value,
    (newState, oldState) {
      if (newState == AppLifecycleState.resumed &&
          oldState == AppLifecycleState.paused) {
        refresh(); // 從背景回來後刷新資料
      }
    },
  );

  return (context) {
    return switch (userData.value) {
      AsyncData(:final value) => UserProfile(user: value),
      AsyncLoading() => const CircularProgressIndicator(),
      AsyncError(:final errorValue) => Text('Error: $errorValue'),
      AsyncIdle() => const SizedBox.shrink(),
    };
  };
}
```

### 生命週期

元件掛載時會自動註冊生命週期觀察者，卸載時自動移除，不需要手動清理。

---

## useSearchController

建立具自動生命週期管理與響應式追蹤的 SearchController。

### 方法簽章

```dart
ReadonlyRef<SearchController> useSearchController()
```

### 回傳值

`ReadonlyRef<SearchController>`，會響應式追蹤搜尋文字的變化。

### 範例：基本搜尋

```dart
@override
Widget Function(BuildContext) setup() {
  final searchController = useSearchController();

  // 對搜尋文字變化做出反應
  final searchText = computed(() {
    searchController.value; // Track changes
    return searchController.value.text;
  });

  watch(
    () => searchText.value,
    (newValue, oldValue) {
      print('Search text changed: $oldValue -> $newValue');
      // 在此執行搜尋
    },
  );

  return (context) => SearchAnchor(
    searchController: searchController.value,
    builder: (context, controller) {
      return SearchBar(
        controller: controller,
        hintText: 'Search...',
      );
    },
    suggestionsBuilder: (context, controller) {
      return [
        ListTile(title: Text('Result for: ${searchText.value}')),
      ];
    },
  );
}
```

### 範例：具防抖的搜尋

```dart
@override
Widget Function(BuildContext) setup() {
  final searchController = useSearchController();
  final searchResults = ref<List<String>>([]);

  // 具防抖的搜尋
  Timer? debounceTimer;
  watch(
    () => searchController.value.text,
    (query, _) {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        if (query.isNotEmpty) {
          final results = await api.search(query);
          searchResults.value = results;
        } else {
          searchResults.value = [];
        }
      });
    },
  );

  onUnmounted(() => debounceTimer?.cancel());

  return (context) => SearchAnchor(
    searchController: searchController.value,
    builder: (context, controller) {
      return SearchBar(
        controller: controller,
        hintText: 'Search...',
      );
    },
    suggestionsBuilder: (context, controller) {
      return searchResults.value.map((result) {
        return ListTile(title: Text(result));
      }).toList();
    },
  );
}
```

### 範例：進階搜尋與篩選

```dart
@override
Widget Function(BuildContext) setup() {
  final searchController = useSearchController();
  final items = ref<List<Item>>([
    Item('Apple', category: 'Fruit'),
    Item('Banana', category: 'Fruit'),
    Item('Carrot', category: 'Vegetable'),
  ]);

  final filteredItems = computed(() {
    final query = searchController.value.text.toLowerCase();
    if (query.isEmpty) return items.value;

    return items.value.where((item) {
      return item.name.toLowerCase().contains(query);
    }).toList();
  });

  return (context) => Column(
    children: [
      SearchBar(
        controller: searchController.value,
        hintText: 'Search items...',
      ),
      Expanded(
        child: ComputedBuilder(
          builder: () => ListView.builder(
            itemCount: filteredItems.value.length,
            itemBuilder: (context, index) {
              final item = filteredItems.value[index];
              return ListTile(
                title: Text(item.name),
                subtitle: Text(item.category),
              );
            },
          ),
        ),
      ),
    ],
  );
}
```

### 生命週期

SearchController 會在元件卸載時自動釋放，其內部監聽器也會一併移除。

---

## 最佳實務

### 優先直接存取 context

```dart
// 較佳：在 builder 中直接存取
return (context) {
  final theme = Theme.of(context);
  return Text('Color: ${theme.primaryColor}');
};

// 請避免：不必要的 ref 包裝
final contextRef = useContext();
return (context) {
  contextRef.value = context;
  final theme = Theme.of(context);
  return Text('Color: ${theme.primaryColor}');
};
```

### 依生命週期調整背景工作

```dart
// 較佳：依生命週期暫停/恢復
final lifecycleState = useAppLifecycleState();

watch(() => lifecycleState.value, (state, _) {
  if (state == AppLifecycleState.paused) {
    timer.cancel(); // 停止背景工作
  } else if (state == AppLifecycleState.resumed) {
    timer = Timer.periodic(...); // 恢復背景工作
  }
});
```

### 針對搜尋輸入使用防抖

```dart
// 較佳：具防抖的搜尋
Timer? debounceTimer;
watch(() => searchController.value.text, (query, _) {
  debounceTimer?.cancel();
  debounceTimer = Timer(Duration(milliseconds: 300), () {
    performSearch(query);
  });
});

onUnmounted(() => debounceTimer?.cancel());
```

---

## 延伸閱讀

- [生命週期掛勾](../lifecycle.md) - onMounted、onUnmounted
- [watch、watchEffect](../watch.md) - 副作用
- [ref](../reactivity.md#ref) - 響應式參照
- [computed](../reactivity.md#computed) - 衍生值
