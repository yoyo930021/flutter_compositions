# 非同步操作

處理非同步操作（API 呼叫、資料獲取、檔案讀寫）是現代應用程式的核心。本指南將探討如何使用 Flutter Compositions 優雅地處理 futures 和 streams，包括載入狀態、錯誤處理和資料刷新。

## 為什麼不能使用 Async Setup？

在深入了解非同步操作之前，重要的是要理解為什麼 `setup()` 方法**不能**是 async：

```dart
// ❌ 這是不允許的！
@override
Future<Widget Function(BuildContext)> setup() async {
  final data = await fetchData();
  return (context) => Text(data);
}
```

`setup()` 必須同步回傳 builder 函數，因為：

1. **生命週期要求**：Flutter 需要立即取得 widget tree
2. **響應式追蹤**：響應式系統需要同步設定依賴項
3. **可預測性**：非同步 setup 會導致時序問題和不可預測的行為

相反，使用 `onMounted()` 和響應式狀態處理非同步初始化。

## AsyncValue 模式

Flutter Compositions 提供 `AsyncValue<T>` 來表示非同步操作的狀態。它是一個密封類別，有四種可能的狀態：

```dart
sealed class AsyncValue<T> {
  // 尚未開始
  AsyncIdle<T>();

  // 進行中
  AsyncLoading<T>();

  // 成功完成
  AsyncData<T>(T value);

  // 失敗
  AsyncError<T>(Object errorValue, StackTrace? stackTrace);
}
```

### 使用模式匹配

```dart
return switch (status.value) {
  AsyncIdle() => Text('準備開始'),
  AsyncLoading() => CircularProgressIndicator(),
  AsyncData(:final value) => Text('資料: $value'),
  AsyncError(:final errorValue) => Text('錯誤: $errorValue'),
};
```

### 狀態檢查

```dart
// 布林檢查
if (status.value.isLoading) {
  return CircularProgressIndicator();
}

if (status.value.isData) {
  return Text('資料: ${status.value.dataOrNull}');
}

// 更類型安全的方式
if (status.value case AsyncData(:final value)) {
  return Text('資料: $value');
}
```

## useFuture - 簡單的非同步操作

`useFuture` 是處理單一 future 的最簡單方式。它會自動追蹤載入狀態、資料和錯誤。

### 基本用法

```dart
class UserProfile extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // 在元件掛載時自動執行
    final userData = useFuture(() => api.fetchUser());

    return (context) {
      return switch (userData.value) {
        AsyncLoading() => Center(
          child: CircularProgressIndicator(),
        ),
        AsyncError(:final errorValue) => Center(
          child: Text('載入失敗: $errorValue'),
        ),
        AsyncData(:final value) => UserCard(user: value),
        AsyncIdle() => SizedBox.shrink(),
      };
    };
  }
}
```

### 帶參數的 Future

```dart
class ProductDetail extends CompositionWidget {
  const ProductDetail({required this.productId});
  final String productId;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();

    // 使用 computed 從 props 取得 productId
    final productId = computed(() => props.value.productId);

    final productData = useFuture(() => api.fetchProduct(productId.value));

    return (context) {
      return switch (productData.value) {
        AsyncLoading() => LoadingWidget(),
        AsyncError(:final errorValue) => ErrorWidget(errorValue),
        AsyncData(:final value) => ProductDetailView(product: value),
        AsyncIdle() => SizedBox.shrink(),
      };
    };
  }
}
```

## useAsyncData - 進階非同步操作

`useAsyncData` 提供更多控制，包括：
- 監聽依賴項變更時自動重新獲取
- 手動刷新功能
- 防止並發執行

### 基本用法

```dart
class TodoList extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (status, refresh) = useAsyncData<List<Todo>, void>(
      (_) => api.fetchTodos(),
    );

    return (context) => Column(
      children: [
        if (status.value case AsyncData(:final value))
          ...value.map((todo) => TodoItem(todo: todo)),

        ElevatedButton(
          onPressed: refresh,
          child: Text('刷新'),
        ),
      ],
    );
  }
}
```

### 使用 Watch 自動重新獲取

當依賴項變更時自動重新獲取資料：

```dart
class UserPosts extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final userId = ref(1);

    // 當 userId 變更時自動重新獲取
    final (status, refresh) = useAsyncData<List<Post>, int>(
      (id) => api.fetchUserPosts(id),
      watch: () => userId.value,
    );

    return (context) => Column(
      children: [
        // 使用者選擇器
        DropdownButton<int>(
          value: userId.value,
          items: [1, 2, 3].map((id) {
            return DropdownMenuItem(
              value: id,
              child: Text('User $id'),
            );
          }).toList(),
          onChanged: (id) => userId.value = id!,
        ),

        // 文章列表
        if (status.value case AsyncLoading())
          CircularProgressIndicator()
        else if (status.value case AsyncData(:final value))
          ...value.map((post) => PostCard(post: post))
        else if (status.value case AsyncError(:final errorValue))
          Text('錯誤: $errorValue'),
      ],
    );
  }
}
```

### 多個依賴項

```dart
class SearchResults extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final query = ref('');
    final category = ref('all');
    final sortBy = ref('recent');

    final (status, refresh) = useAsyncData<List<Item>, SearchParams>(
      (params) => api.search(
        query: params.query,
        category: params.category,
        sortBy: params.sortBy,
      ),
      watch: () => SearchParams(
        query: query.value,
        category: category.value,
        sortBy: sortBy.value,
      ),
    );

    return (context) => Column(
      children: [
        TextField(
          onChanged: (value) => query.value = value,
        ),
        // 過濾器和排序控制...

        if (status.value case AsyncData(:final value))
          ...value.map((item) => ItemCard(item: item)),
      ],
    );
  }
}

class SearchParams {
  const SearchParams({
    required this.query,
    required this.category,
    required this.sortBy,
  });

  final String query;
  final String category;
  final String sortBy;

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is SearchParams &&
    query == other.query &&
    category == other.category &&
    sortBy == other.sortBy;

  @override
  int get hashCode => Object.hash(query, category, sortBy);
}
```

## useAsyncValue - 分解狀態

`useAsyncValue` 將 `AsyncValue` 分解為個別的響應式引用，使 UI 邏輯更簡單：

```dart
class DataDisplay extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (status, refresh) = useAsyncData<String, void>(
      (_) => api.getData(),
    );

    // 分解為個別引用
    final (data, error, loading, hasData) = useAsyncValue(status);

    return (context) => Column(
      children: [
        if (loading.value)
          CircularProgressIndicator(),

        if (error.value != null)
          ErrorBanner(error: error.value!),

        if (data.value != null)
          DataView(data: data.value!),

        ElevatedButton(
          onPressed: loading.value ? null : refresh,
          child: Text('刷新'),
        ),
      ],
    );
  }
}
```

## 錯誤處理

### 顯示錯誤訊息

```dart
class UserList extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (status, refresh) = useAsyncData<List<User>, void>(
      (_) => api.fetchUsers(),
    );

    return (context) {
      return switch (status.value) {
        AsyncError(:final errorValue, :final stackTrace) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              '載入失敗',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              errorValue.toString(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: refresh,
              child: Text('重試'),
            ),
            if (stackTrace != null)
              TextButton(
                onPressed: () => showErrorDetails(context, stackTrace),
                child: Text('查看詳情'),
              ),
          ],
        ),
        AsyncData(:final value) => ListView.builder(
          itemCount: value.length,
          itemBuilder: (context, index) => UserTile(user: value[index]),
        ),
        AsyncLoading() => Center(child: CircularProgressIndicator()),
        AsyncIdle() => SizedBox.shrink(),
      };
    };
  }
}
```

### 記錄錯誤

```dart
@override
Widget Function(BuildContext) setup() {
  final (status, refresh) = useAsyncData<Data, void>(
    (_) => api.fetchData(),
  );

  // 監聽錯誤並記錄
  watch(
    () => status.value,
    (newValue, _) {
      if (newValue case AsyncError(:final errorValue, :final stackTrace)) {
        logger.error('資料獲取失敗', errorValue, stackTrace);
        analytics.logError(errorValue);

        // 可選：顯示 snackbar
        onBuild(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('無法載入資料')),
          );
        });
      }
    },
  );

  return (context) => /* ... */;
}
```

### 降級處理

當資料獲取失敗時顯示快取或預設資料：

```dart
class WeatherWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final cachedWeather = ref<Weather?>(null);

    final (status, refresh) = useAsyncData<Weather, void>(
      (_) async {
        try {
          final weather = await api.fetchWeather();
          cachedWeather.value = weather; // 快取成功的資料
          return weather;
        } catch (e) {
          // 如果有快取，使用快取資料
          if (cachedWeather.value != null) {
            return cachedWeather.value!;
          }
          rethrow;
        }
      },
    );

    return (context) {
      final weather = switch (status.value) {
        AsyncData(:final value) => value,
        _ => cachedWeather.value,
      };

      if (weather == null) {
        return LoadingOrErrorView(status: status.value);
      }

      return WeatherDisplay(
        weather: weather,
        isStale: status.value is AsyncError,
        onRefresh: refresh,
      );
    };
  }
}
```

## 載入狀態

### 基本載入指示器

```dart
if (status.value.isLoading) {
  return Center(child: CircularProgressIndicator());
}
```

### 骨架載入器

```dart
if (status.value.isLoading) {
  return ListView.builder(
    itemCount: 5,
    itemBuilder: (context, index) => ShimmerCard(),
  );
}
```

### 下拉刷新

```dart
return RefreshIndicator(
  onRefresh: () async {
    refresh();
    // 等待狀態不再是 loading
    while (status.value.isLoading) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  },
  child: ListView(...),
);
```

### 帶有重疊載入指示器的漸進式載入

```dart
return Stack(
  children: [
    // 顯示現有資料
    if (status.value case AsyncData(:final value))
      DataView(data: value),

    // 重新載入時顯示載入覆蓋層
    if (status.value.isLoading)
      Container(
        color: Colors.black26,
        child: Center(child: CircularProgressIndicator()),
      ),
  ],
);
```

## Streams

### useStream - 基本 Stream 處理

```dart
class RealtimeCounter extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // 每秒發出一次的 stream
    final stream = Stream.periodic(
      Duration(seconds: 1),
      (count) => count,
    );

    final count = useStream(stream, initialValue: 0);

    return (context) => Text('計數: ${count.value}');
  }
}
```

### useStreamController - 建立自訂 Stream

```dart
class MessageBoard extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, messages) = useStreamController<String>(
      initialValue: '',
    );

    void sendMessage(String message) {
      controller.add(message);
    }

    return (context) => Column(
      children: [
        Text('最新訊息: ${messages.value}'),
        TextField(
          onSubmitted: sendMessage,
        ),
      ],
    );
  }
}
```

### Firestore Stream 範例

```dart
class ChatMessages extends CompositionWidget {
  const ChatMessages({required this.chatId});
  final String chatId;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();

    // Firestore stream
    final messagesStream = computed(() {
      return FirebaseFirestore.instance
          .collection('chats')
          .doc(props.value.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();
    });

    final messages = useStream(
      messagesStream.value,
      initialValue: <QueryDocumentSnapshot>[],
    );

    return (context) => ListView.builder(
      itemCount: messages.value.length,
      itemBuilder: (context, index) {
        final doc = messages.value[index];
        return MessageBubble(
          text: doc['text'],
          sender: doc['sender'],
          timestamp: doc['timestamp'],
        );
      },
    );
  }
}
```

## 實戰範例

### 分頁載入

```dart
class InfiniteListPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final items = ref(<Item>[]);
    final page = ref(1);
    final hasMore = ref(true);
    final isLoadingMore = ref(false);

    final scrollController = useScrollController();

    Future<void> loadMore() async {
      if (isLoadingMore.value || !hasMore.value) return;

      isLoadingMore.value = true;
      try {
        final newItems = await api.fetchItems(page: page.value);
        items.value = [...items.value, ...newItems];
        page.value++;
        hasMore.value = newItems.isNotEmpty;
      } catch (e) {
        // 處理錯誤
      } finally {
        isLoadingMore.value = false;
      }
    }

    // 初始載入
    final (initialStatus, _) = useAsyncData<List<Item>, void>(
      (_) => api.fetchItems(page: 1),
    );

    watch(
      () => initialStatus.value,
      (value, _) {
        if (value case AsyncData(:final value)) {
          items.value = value;
          page.value = 2;
        }
      },
    );

    // 監聽滾動以載入更多
    watchEffect(() {
      final controller = scrollController.value;
      if (controller.position.pixels >= controller.position.maxScrollExtent * 0.8) {
        loadMore();
      }
    });

    return (context) => ListView.builder(
      controller: scrollController.value,
      itemCount: items.value.length + (isLoadingMore.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.value.length) {
          return Center(child: CircularProgressIndicator());
        }
        return ItemCard(item: items.value[index]);
      },
    );
  }
}
```

### 樂觀更新

在等待伺服器確認時立即更新 UI：

```dart
class TodoApp extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final todos = ref(<Todo>[]);

    Future<void> toggleTodo(String id) async {
      // 樂觀更新
      final oldTodos = todos.value;
      todos.value = todos.value.map((t) {
        if (t.id == id) {
          return Todo(id: t.id, title: t.title, completed: !t.completed);
        }
        return t;
      }).toList();

      try {
        // 發送到伺服器
        await api.toggleTodo(id);
      } catch (e) {
        // 失敗時回滾
        todos.value = oldTodos;
        // 顯示錯誤
        onBuild(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('無法更新待辦事項')),
          );
        });
      }
    }

    return (context) => /* ... */;
  }
}
```

### 輪詢

定期重新獲取資料：

```dart
class LiveDashboard extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (status, refresh) = useAsyncData<DashboardData, void>(
      (_) => api.fetchDashboard(),
    );

    // 每 30 秒輪詢一次
    onMounted(() {
      final timer = Timer.periodic(
        Duration(seconds: 30),
        (_) => refresh(),
      );

      onUnmounted(() => timer.cancel());
    });

    return (context) => /* ... */;
  }
}
```

### 依賴資料獲取

一個請求依賴於另一個請求的結果：

```dart
class UserProfile extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final userId = ref('user-123');

    // 首先獲取使用者
    final (userStatus, _) = useAsyncData<User, String>(
      (id) => api.fetchUser(id),
      watch: () => userId.value,
    );

    // 然後獲取使用者的文章
    final (postsStatus, _) = useAsyncData<List<Post>, User?>(
      (user) async {
        if (user == null) throw Exception('No user');
        return api.fetchUserPosts(user.id);
      },
      watch: () => userStatus.value.dataOrNull,
    );

    return (context) {
      // 等待兩個都載入
      final user = userStatus.value;
      final posts = postsStatus.value;

      if (user.isLoading || posts.isLoading) {
        return LoadingView();
      }

      if (user case AsyncData(:final value)) {
        return Column(
          children: [
            UserHeader(user: value),
            if (posts case AsyncData(:final value))
              ...value.map((post) => PostCard(post: post)),
          ],
        );
      }

      return ErrorView();
    };
  }
}
```

## 防抖和節流

### 防抖搜尋

```dart
class SearchPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final query = ref('');
    final debouncedQuery = ref('');

    // 防抖 500ms
    Timer? debounceTimer;
    watch(
      () => query.value,
      (newQuery, _) {
        debounceTimer?.cancel();
        debounceTimer = Timer(Duration(milliseconds: 500), () {
          debouncedQuery.value = newQuery;
        });
      },
    );

    onUnmounted(() => debounceTimer?.cancel());

    final (results, _) = useAsyncData<List<SearchResult>, String>(
      (q) => api.search(q),
      watch: () => debouncedQuery.value,
    );

    return (context) => Column(
      children: [
        TextField(
          onChanged: (value) => query.value = value,
        ),
        if (results.value case AsyncData(:final value))
          ...value.map((r) => SearchResultCard(result: r)),
      ],
    );
  }
}
```

### 節流 API 呼叫

```dart
class LocationTracker extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final location = ref<LatLng?>(null);
    DateTime? lastUpdate;

    Future<void> updateLocation(LatLng newLocation) async {
      final now = DateTime.now();

      // 節流：每 5 秒最多一次更新
      if (lastUpdate != null &&
          now.difference(lastUpdate!) < Duration(seconds: 5)) {
        return;
      }

      location.value = newLocation;
      lastUpdate = now;

      try {
        await api.updateLocation(newLocation);
      } catch (e) {
        // 處理錯誤
      }
    }

    return (context) => /* ... */;
  }
}
```

## 最佳實踐

### 1. 使用模式匹配處理 AsyncValue

```dart
// ✅ 良好 - 詳盡且類型安全
return switch (status.value) {
  AsyncLoading() => CircularProgressIndicator(),
  AsyncError(:final errorValue) => ErrorWidget(errorValue),
  AsyncData(:final value) => DataView(value),
  AsyncIdle() => SizedBox.shrink(),
};

// ❌ 不良 - 不詳盡
if (status.value.isData) {
  return DataView(status.value.dataOrNull!);
}
return CircularProgressIndicator();
```

### 2. 使用 useAsyncData 的 Watch 處理依賴獲取

```dart
// ✅ 良好 - 自動重新獲取
final (status, _) = useAsyncData<User, int>(
  (id) => api.fetchUser(id),
  watch: () => userId.value,
);

// ❌ 不良 - 手動重新獲取
final status = useFuture(() => api.fetchUser(userId.value));
watch(() => userId.value, (_) {
  // 無法輕鬆重新獲取
});
```

### 3. 使用 useAsyncValue 簡化 UI 邏輯

```dart
// ✅ 良好 - 清晰的意圖
final (data, error, loading, _) = useAsyncValue(status);

if (loading.value) return CircularProgressIndicator();
if (error.value != null) return ErrorWidget(error.value!);
return DataView(data.value!);
```

### 4. 處理重新獲取期間的載入狀態

```dart
// ✅ 良好 - 顯示現有資料同時載入
final (data, error, loading, hasData) = useAsyncValue(status);

return Stack(
  children: [
    if (hasData.value && data.value != null)
      DataView(data: data.value!),
    if (loading.value)
      LoadingOverlay(),
  ],
);
```

### 5. 防止並發執行

```dart
// ✅ 良好 - useAsyncData 自動處理
final (status, refresh) = useAsyncData<Data, void>(
  (_) => fetchData(),
);

// 多次 refresh() 呼叫是安全的 - 如果已經在載入則忽略
onPressed: refresh;
```

## 下一步

- 探索[表單處理](./forms.md)以構建響應式表單
- 學習[狀態管理](./state-management.md)以管理應用程式狀態
- 閱讀 [AsyncValue API](../api/types/async-value.md) 以了解完整 API 參考
