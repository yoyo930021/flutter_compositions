# 狀態管理

管理應用程式狀態是構建可擴展 Flutter 應用程式的關鍵。本指南將探討如何使用 Flutter Compositions 管理本地和全域狀態、使用 provide/inject 進行狀態共享，以及常見的狀態模式。

## 狀態的類型

在 Flutter Compositions 中，我們區分三種狀態類型：

### 1. 本地狀態

僅在單個 widget 中使用的狀態。應該在該 widget 的 `setup()` 方法中定義。

```dart
class CounterButton extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // 本地狀態 - 只有這個 widget 需要
    final count = ref(0);

    return (context) => ElevatedButton(
      onPressed: () => count.value++,
      child: Text('點擊: ${count.value}'),
    );
  }
}
```

### 2. 共享狀態（Widget 樹範圍）

多個 widget 需要的狀態，但僅限於 widget 樹的特定部分。使用 `provide`/`inject` 共享。

```dart
const todosKey = InjectionKey<Ref<List<Todo>>>('todos');

// 在父 widget 中提供
class TodoListPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final todos = ref(<Todo>[]);
    provide(todosKey, todos); // 提供給子 widgets

    return (context) => Column(
      children: [
        TodoInput(),
        TodoList(),
        TodoStats(),
      ],
    );
  }
}

// 在子 widget 中注入
class TodoStats extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final todos = inject(todosKey); // 注入共享狀態

    final count = computed(() => todos.value.length);

    return (context) => Text('共 ${count.value} 個待辦事項');
  }
}
```

### 3. 全域狀態（應用程式範圍）

整個應用程式需要的狀態。在應用程式根部提供，任何地方都可以注入。

```dart
// 定義全域狀態
class AuthState {
  final user = ref<User?>(null);
  final isAuthenticated = ref(false);

  Future<void> login(String email, String password) async {
    // 登入邏輯
    user.value = await api.login(email, password);
    isAuthenticated.value = true;
  }

  void logout() {
    user.value = null;
    isAuthenticated.value = false;
  }
}

const authStateKey = InjectionKey<AuthState>('authState');

// 在應用程式根部提供
class MyApp extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final authState = AuthState();
    provide(authStateKey, authState);

    return (context) => MaterialApp(
      home: HomePage(),
    );
  }
}

// 在任何子 widget 中使用
class ProfilePage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final authState = inject(authStateKey);

    return (context) {
      if (!authState.isAuthenticated.value) {
        return LoginPage();
      }

      return Column(
        children: [
          Text('歡迎, ${authState.user.value?.name}'),
          ElevatedButton(
            onPressed: authState.logout,
            child: Text('登出'),
          ),
        ],
      );
    };
  }
}
```

## 使用 Provide/Inject 進行狀態共享

### 基本用法

```dart
const themeKey = InjectionKey<ThemeState>('theme');

// 1. 定義要共享的狀態
class ThemeState {
  final isDark = ref(false);

  void toggleTheme() {
    isDark.value = !isDark.value;
  }
}

// 2. 在父 widget 中提供
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ThemeState();
    provide(themeKey, theme);

    return (context) => MaterialApp(
      home: HomePage(),
    );
  }
}

// 3. 在子 widget 中注入
class ThemeToggle extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = inject(themeKey);

    return (context) => Switch(
      value: theme.isDark.value,
      onChanged: (_) => theme.toggleTheme(),
    );
  }
}
```

### 類型安全的注入

為了避免類型衝突並提供更好的開發者體驗，使用 `InjectionKey`：

```dart
// 定義 injection key
class ThemeStateKey extends InjectionKey<ThemeState> {
  const ThemeStateKey();
}

const themeKey = ThemeStateKey();

// 使用 key 提供
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ThemeState();
    provide(themeKey, theme);

    return (context) => MaterialApp(home: HomePage());
  }
}

// 使用 key 注入
class ThemeToggle extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = inject(themeKey);

    return (context) => Switch(
      value: theme.isDark.value,
      onChanged: (_) => theme.toggleTheme(),
    );
  }
}
```

### 提供預設值

```dart
const settingsKey = InjectionKey<SettingsState>('settings');

class SettingsState {
  final fontSize = ref(14.0);
}

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // 如果找不到，使用預設值
    final settings = inject(
      settingsKey,
      defaultValue: SettingsState(),
    );

    return (context) => Text(
      'Hello',
      style: TextStyle(fontSize: settings.fontSize.value),
    );
  }
}
```

## 狀態模式

### 模式 1：Repository 模式

將資料存取邏輯與 UI 分離。

```dart
// Repository
class UserRepository {
  final _users = ref(<User>[]);
  final _isLoading = ref(false);
  final _error = ref<String?>(null);

  ReadonlyRef<List<User>> get users => _users;
  ReadonlyRef<bool> get isLoading => _isLoading;
  ReadonlyRef<String?> get error => _error;

  Future<void> fetchUsers() async {
    _isLoading.value = true;
    _error.value = null;

    try {
      final result = await api.getUsers();
      _users.value = result;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> addUser(User user) async {
    try {
      await api.createUser(user);
      _users.value = [..._users.value, user];
    } catch (e) {
      _error.value = e.toString();
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await api.deleteUser(userId);
      _users.value = _users.value.where((u) => u.id != userId).toList();
    } catch (e) {
      _error.value = e.toString();
    }
  }
}

const userRepositoryKey = InjectionKey<UserRepository>('userRepository');

// 在應用程式中提供
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final userRepo = UserRepository();
    provide(userRepositoryKey, userRepo);

    return (context) => MaterialApp(home: UserListPage());
  }
}

// 在 UI 中使用
class UserListPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final userRepo = inject(userRepositoryKey);

    onMounted(() {
      userRepo.fetchUsers();
    });

    return (context) {
      if (userRepo.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (userRepo.error.value != null) {
        return Center(child: Text('Error: ${userRepo.error.value}'));
      }

      return ListView.builder(
        itemCount: userRepo.users.value.length,
        itemBuilder: (context, index) {
          final user = userRepo.users.value[index];
          return ListTile(
            title: Text(user.name),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => userRepo.deleteUser(user.id),
            ),
          );
        },
      );
    };
  }
}
```

### 模式 2：Store 模式（類似 Vuex/Pinia）

集中管理狀態、getters、actions 和 mutations。

```dart
// Store
class TodoStore {
  // State
  final _todos = ref(<Todo>[]);
  final _filter = ref<TodoFilter>(TodoFilter.all);

  // Getters（唯讀）
  ReadonlyRef<List<Todo>> get todos => _todos;
  ReadonlyRef<TodoFilter> get filter => _filter;

  // Computed
  late final activeTodos = computed(() {
    return _todos.value.where((t) => !t.completed).toList();
  });

  late final completedTodos = computed(() {
    return _todos.value.where((t) => t.completed).toList();
  });

  late final filteredTodos = computed(() {
    switch (_filter.value) {
      case TodoFilter.active:
        return activeTodos.value;
      case TodoFilter.completed:
        return completedTodos.value;
      case TodoFilter.all:
        return _todos.value;
    }
  });

  late final stats = computed(() => TodoStats(
    total: _todos.value.length,
    active: activeTodos.value.length,
    completed: completedTodos.value.length,
  ));

  // Actions
  void addTodo(String title) {
    final todo = Todo(
      id: DateTime.now().toString(),
      title: title,
      completed: false,
    );
    _todos.value = [..._todos.value, todo];
  }

  void removeTodo(String id) {
    _todos.value = _todos.value.where((t) => t.id != id).toList();
  }

  void toggleTodo(String id) {
    _todos.value = _todos.value.map((t) {
      if (t.id == id) {
        return Todo(id: t.id, title: t.title, completed: !t.completed);
      }
      return t;
    }).toList();
  }

  void setFilter(TodoFilter newFilter) {
    _filter.value = newFilter;
  }

  void clearCompleted() {
    _todos.value = activeTodos.value;
  }
}

enum TodoFilter { all, active, completed }

class TodoStats {
  const TodoStats({
    required this.total,
    required this.active,
    required this.completed,
  });

  final int total;
  final int active;
  final int completed;
}
```

### 模式 3：Service 模式

將業務邏輯封裝在服務中。

```dart
// 服務
class AuthService {
  final _currentUser = ref<User?>(null);
  final _isAuthenticated = ref(false);

  ReadonlyRef<User?> get currentUser => _currentUser;
  ReadonlyRef<bool> get isAuthenticated => _isAuthenticated;

  Future<void> login(String email, String password) async {
    try {
      final user = await api.login(email, password);
      _currentUser.value = user;
      _isAuthenticated.value = true;

      // 儲存 token
      await storage.saveToken(user.token);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _currentUser.value = null;
    _isAuthenticated.value = false;
    await storage.deleteToken();
  }

  Future<void> checkAuth() async {
    final token = await storage.getToken();
    if (token != null) {
      try {
        final user = await api.getCurrentUser(token);
        _currentUser.value = user;
        _isAuthenticated.value = true;
      } catch (e) {
        await logout();
      }
    }
  }
}

class NotificationService {
  final _notifications = ref(<Notification>[]);
  final _unreadCount = ref(0);

  ReadonlyRef<List<Notification>> get notifications => _notifications;
  ReadonlyRef<int> get unreadCount => _unreadCount;

  void addNotification(Notification notification) {
    _notifications.value = [..._notifications.value, notification];
    if (!notification.read) {
      _unreadCount.value++;
    }
  }

  void markAsRead(String id) {
    _notifications.value = _notifications.value.map((n) {
      if (n.id == id && !n.read) {
        _unreadCount.value--;
        return Notification(id: n.id, message: n.message, read: true);
      }
      return n;
    }).toList();
  }

  void clearAll() {
    _notifications.value = [];
    _unreadCount.value = 0;
  }
}

const authServiceKey = InjectionKey<AuthService>('authService');
const notificationServiceKey =
    InjectionKey<NotificationService>('notificationService');

// 在應用程式中提供所有服務
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final authService = AuthService();
    final notificationService = NotificationService();

    provide(authServiceKey, authService);
    provide(notificationServiceKey, notificationService);

    onMounted(() {
      authService.checkAuth();
    });

    return (context) => MaterialApp(home: HomePage());
  }
}
```

### 模式 4：複合狀態

組合多個狀態來源。

```dart
const appStateKey = InjectionKey<AppState>('appState');

class AppState {
  final auth = AuthService();
  final notifications = NotificationService();
  final theme = ThemeState();
  final settings = SettingsState();
}

class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final appState = AppState();
    provide(appStateKey, appState);

    return (context) => MaterialApp(home: HomePage());
  }
}

// 在子 widget 中使用
class Header extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final appState = inject(appStateKey);

    final userName = computed(() {
      return appState.auth.currentUser.value?.name ?? '訪客';
    });

    return (context) => AppBar(
      title: Text('歡迎, ${userName.value}'),
      actions: [
        IconButton(
          icon: Badge(
            label: Text('${appState.notifications.unreadCount.value}'),
            child: Icon(Icons.notifications),
          ),
          onPressed: () {/* 顯示通知 */},
        ),
      ],
    );
  }
}
```

## 實戰範例：購物應用

讓我們建立一個完整的購物應用狀態管理系統。

### 定義領域模型

```dart
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final double price;
  final String imageUrl;
}

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  double get total => product.price * quantity;
}

class Order {
  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final List<CartItem> items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
}

enum OrderStatus { pending, confirmed, shipped, delivered }
```

### 建立 Stores

```dart
// 產品 Store
class ProductStore {
  final _products = ref(<Product>[]);
  final _isLoading = ref(false);
  final _error = ref<String?>(null);

  ReadonlyRef<List<Product>> get products => _products;
  ReadonlyRef<bool> get isLoading => _isLoading;
  ReadonlyRef<String?> get error => _error;

  Future<void> fetchProducts() async {
    _isLoading.value = true;
    _error.value = null;

    try {
      final result = await api.getProducts();
      _products.value = result;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.value.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}

// 購物車 Store
class CartStore {
  final _items = ref(<String, CartItem>{}); // productId -> CartItem

  ReadonlyRef<Map<String, CartItem>> get items => _items;

  late final itemCount = computed(() {
    return _items.value.values.fold<int>(0, (sum, item) => sum + item.quantity);
  });

  late final total = computed(() {
    return _items.value.values.fold<double>(0.0, (sum, item) => sum + item.total);
  });

  late final isEmpty = computed(() => _items.value.isEmpty);

  void addItem(Product product) {
    final currentItems = Map<String, CartItem>.from(_items.value);

    if (currentItems.containsKey(product.id)) {
      final currentItem = currentItems[product.id]!;
      currentItems[product.id] = CartItem(
        product: product,
        quantity: currentItem.quantity + 1,
      );
    } else {
      currentItems[product.id] = CartItem(product: product, quantity: 1);
    }

    _items.value = currentItems;
  }

  void removeItem(String productId) {
    final currentItems = Map<String, CartItem>.from(_items.value);
    currentItems.remove(productId);
    _items.value = currentItems;
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final currentItems = Map<String, CartItem>.from(_items.value);
    if (currentItems.containsKey(productId)) {
      final item = currentItems[productId]!;
      currentItems[productId] = CartItem(
        product: item.product,
        quantity: quantity,
      );
      _items.value = currentItems;
    }
  }

  void clear() {
    _items.value = {};
  }
}

// 訂單 Store
class OrderStore {
  final _orders = ref(<Order>[]);
  final _isLoading = ref(false);

  ReadonlyRef<List<Order>> get orders => _orders;
  ReadonlyRef<bool> get isLoading => _isLoading;

  late final pendingOrders = computed(() {
    return _orders.value.where((o) => o.status == OrderStatus.pending).toList();
  });

  late final completedOrders = computed(() {
    return _orders.value.where((o) => o.status == OrderStatus.delivered).toList();
  });

  Future<void> fetchOrders() async {
    _isLoading.value = true;
    try {
      final result = await api.getOrders();
      _orders.value = result;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<Order?> createOrder(List<CartItem> items, double total) async {
    try {
      final order = await api.createOrder(items, total);
      _orders.value = [..._orders.value, order];
      return order;
    } catch (e) {
      return null;
    }
  }
}
```

### 應用程式根部設定

```dart
const productStoreKey = InjectionKey<ProductStore>('productStore');
const cartStoreKey = InjectionKey<CartStore>('cartStore');
const orderStoreKey = InjectionKey<OrderStore>('orderStore');
// authServiceKey 已在前文的範例中定義

class ShoppingApp extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // 建立所有 stores
    final productStore = ProductStore();
    final cartStore = CartStore();
    final orderStore = OrderStore();
    final authService = AuthService();

    // 提供給整個應用程式
    provide(productStoreKey, productStore);
    provide(cartStoreKey, cartStore);
    provide(orderStoreKey, orderStore);
    provide(authServiceKey, authService);

    // 初始化
    onMounted(() async {
      await authService.checkAuth();
      if (authService.isAuthenticated.value) {
        await productStore.fetchProducts();
        await orderStore.fetchOrders();
      }
    });

    // 監聽購物車變更以儲存到本地
    watch(
      () => cartStore.items.value,
      (items, _) async {
        await storage.saveCart(items);
      },
    );

    return (context) => MaterialApp(
      home: HomePage(),
      routes: {
        '/products': (context) => ProductListPage(),
        '/cart': (context) => CartPage(),
        '/orders': (context) => OrderHistoryPage(),
      },
    );
  }
}
```

### 在頁面中使用 Stores

```dart
class ProductListPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final productStore = inject(productStoreKey);
    final cartStore = inject(cartStoreKey);

    return (context) {
      if (productStore.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('產品'),
          actions: [
            IconButton(
              icon: Badge(
                label: Text('${cartStore.itemCount.value}'),
                child: Icon(Icons.shopping_cart),
              ),
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
          ],
        ),
        body: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          itemCount: productStore.products.value.length,
          itemBuilder: (context, index) {
            final product = productStore.products.value[index];
            return ProductCard(
              product: product,
              onAddToCart: () => cartStore.addItem(product),
            );
          },
        ),
      );
    };
  }
}

class CartPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final cartStore = inject(cartStoreKey);
    final orderStore = inject(orderStoreKey);

    Future<void> checkout() async {
      final items = cartStore.items.value.values.toList();
      final total = cartStore.total.value;

      final order = await orderStore.createOrder(items, total);
      if (order != null) {
        cartStore.clear();
        // 導航到訂單確認頁面
      }
    }

    return (context) {
      if (cartStore.isEmpty.value) {
        return Scaffold(
          appBar: AppBar(title: Text('購物車')),
          body: Center(child: Text('購物車是空的')),
        );
      }

      return Scaffold(
        appBar: AppBar(title: Text('購物車 (${cartStore.itemCount.value})')),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartStore.items.value.length,
                itemBuilder: (context, index) {
                  final item = cartStore.items.value.values.elementAt(index);
                  return CartItemTile(
                    item: item,
                    onUpdateQuantity: (qty) {
                      cartStore.updateQuantity(item.product.id, qty);
                    },
                    onRemove: () => cartStore.removeItem(item.product.id),
                  );
                },
              ),
            ),
            CartSummary(
              total: cartStore.total.value,
              onCheckout: checkout,
            ),
          ],
        ),
      );
    };
  }
}
```

## 持久化狀態

### 使用 SharedPreferences

```dart
class SettingsStore {
  final theme = ref('light');
  final language = ref('en');
  final notifications = ref(true);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    theme.value = prefs.getString('theme') ?? 'light';
    language.value = prefs.getString('language') ?? 'en';
    notifications.value = prefs.getBool('notifications') ?? true;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme.value);
    await prefs.setString('language', language.value);
    await prefs.setBool('notifications', notifications.value);
  }
}

// 使用
const settingsStoreKey = InjectionKey<SettingsStore>('settingsStore');

class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final settings = SettingsStore();
    provide(settingsStoreKey, settings);

    onMounted(() async {
      await settings.load();
    });

    // 監聽變更並自動儲存
    watchEffect(() {
      settings.save();
    });

    return (context) => MaterialApp(home: HomePage());
  }
}
```

### 使用 Hive

```dart
class UserStore {
  final _users = ref(<User>[]);

  Future<void> load() async {
    final box = await Hive.openBox<User>('users');
    _users.value = box.values.toList();
  }

  Future<void> addUser(User user) async {
    final box = await Hive.openBox<User>('users');
    await box.add(user);
    _users.value = [..._users.value, user];
  }

  Future<void> deleteUser(int index) async {
    final box = await Hive.openBox<User>('users');
    await box.deleteAt(index);
    _users.value = List.from(_users.value)..removeAt(index);
  }
}
```

## 最佳實踐

### 1. 保持狀態靠近使用位置

```dart
// ❌ 不良 - 所有狀態都是全域的
class GlobalState {
  final buttonColor = ref(Colors.blue);
  final textValue = ref('');
  // ... 100 個其他欄位
}

// ✅ 良好 - 只共享必要的狀態
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // 只提供真正全域的狀態
    final authService = AuthService();
    provide(authServiceKey, authService);

    return (context) => MaterialApp(home: HomePage());
  }
}
```

### 2. 使用唯讀引用暴露狀態

```dart
// ✅ 良好 - 防止外部直接修改
class CounterStore {
  final _count = ref(0);

  // 暴露為唯讀
  ReadonlyRef<int> get count => _count;

  // 透過方法修改
  void increment() => _count.value++;
}
```

### 3. 將相關狀態分組

```dart
// ✅ 良好 - 邏輯分組
class UserState {
  final profile = ref<UserProfile?>(null);
  final preferences = ref(UserPreferences());
  final settings = ref(UserSettings());
}
```

### 4. 使用 Computed 而不是重複計算

```dart
class TodoStore {
  final _todos = ref(<Todo>[]);

  // ✅ 良好 - 快取計算
  late final activeTodos = computed(() {
    return _todos.value.where((t) => !t.completed).toList();
  });

  // ❌ 不良 - 每次都重新計算
  List<Todo> getActiveTodos() {
    return _todos.value.where((t) => !t.completed).toList();
  }
}
```

### 5. 處理錯誤狀態

```dart
class DataStore<T> {
  final _data = ref<T?>(null);
  final _isLoading = ref(false);
  final _error = ref<String?>(null);

  ReadonlyRef<T?> get data => _data;
  ReadonlyRef<bool> get isLoading => _isLoading;
  ReadonlyRef<String?> get error => _error;

  Future<void> fetch(Future<T> Function() fetcher) async {
    _isLoading.value = true;
    _error.value = null;

    try {
      _data.value = await fetcher();
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }
}
```

## 測試狀態管理

```dart
void main() {
  group('CartStore', () {
    late CartStore cartStore;

    setUp(() {
      cartStore = CartStore();
    });

    test('should add item to cart', () {
      final product = Product(
        id: '1',
        name: 'Test',
        price: 10.0,
        imageUrl: '',
      );

      cartStore.addItem(product);

      expect(cartStore.itemCount.value, 1);
      expect(cartStore.total.value, 10.0);
    });

    test('should update quantity', () {
      final product = Product(
        id: '1',
        name: 'Test',
        price: 10.0,
        imageUrl: '',
      );

      cartStore.addItem(product);
      cartStore.updateQuantity('1', 3);

      expect(cartStore.itemCount.value, 3);
      expect(cartStore.total.value, 30.0);
    });

    test('should remove item', () {
      final product = Product(
        id: '1',
        name: 'Test',
        price: 10.0,
        imageUrl: '',
      );

      cartStore.addItem(product);
      cartStore.removeItem('1');

      expect(cartStore.isEmpty.value, true);
    });
  });
}
```

## 下一步

- 探索[依賴注入](./dependency-injection.md)以深入了解 provide/inject
- 學習[非同步操作](./async-operations.md)以處理 API 呼叫
- 閱讀[最佳實踐](../guide/best-practices.md)以了解進階模式
