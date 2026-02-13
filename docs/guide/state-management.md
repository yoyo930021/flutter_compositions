# State Management

Managing application state is crucial to building scalable Flutter applications. This guide explores how to manage local and global state using Flutter Compositions, share state using provide/inject, and common state patterns.

## Types of State

In Flutter Compositions, we distinguish between three types of state:

### 1. Local State

State that is only used within a single widget. Should be defined in that widget's `setup()` method.

```dart
class CounterButton extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // Local state - only this widget needs it
    final count = ref(0);

    return (context) => ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Clicks: ${count.value}'),
    );
  }
}
```

### 2. Shared State (Widget Tree Scoped)

State that multiple widgets need, but limited to a specific part of the widget tree. Share using `provide`/`inject`.

```dart
const todosKey = InjectionKey<Ref<List<Todo>>>('todos');

// Provide in parent widget
class TodoListPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final todos = ref(<Todo>[]);
    provide(todosKey, todos); // Provide to child widgets

    return (context) => Column(
      children: [
        TodoInput(),
        TodoList(),
        TodoStats(),
      ],
    );
  }
}

// Inject in child widget
class TodoStats extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final todos = inject(todosKey); // Inject shared state

    final count = computed(() => todos.value.length);

    return (context) => Text('Total ${count.value} todos');
  }
}
```

### 3. Global State (Application Scoped)

State that the entire application needs. Provide at the application root, inject anywhere.

```dart
// Define global state
class AuthState {
  final user = ref<User?>(null);
  final isAuthenticated = ref(false);

  Future<void> login(String email, String password) async {
    // Login logic
    user.value = await api.login(email, password);
    isAuthenticated.value = true;
  }

  void logout() {
    user.value = null;
    isAuthenticated.value = false;
  }
}

const authStateKey = InjectionKey<AuthState>('authState');

// Provide at application root
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

// Use in any child widget
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
          Text('Welcome, ${authState.user.value?.name}'),
          ElevatedButton(
            onPressed: authState.logout,
            child: Text('Logout'),
          ),
        ],
      );
    };
  }
}
```

## State Sharing with Provide/Inject

### Basic Usage

```dart
const themeKey = InjectionKey<ThemeState>('theme');

// 1. Define state to share
class ThemeState {
  final isDark = ref(false);

  void toggleTheme() {
    isDark.value = !isDark.value;
  }
}

// 2. Provide in parent widget
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

// 3. Inject in child widget
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

### Type-Safe Injection

To avoid type collisions and provide better developer experience, use `InjectionKey`:

```dart
// Define injection key
class ThemeStateKey extends InjectionKey<ThemeState> {
  const ThemeStateKey();
}

const themeKey = ThemeStateKey();

// Provide using key
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ThemeState();
    provide(themeKey, theme);

    return (context) => MaterialApp(home: HomePage());
  }
}

// Inject using key
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

### Providing Default Values

```dart
const settingsKey = InjectionKey<SettingsState>('settings');

class SettingsState {
  final fontSize = ref(14.0);
}

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // Use default value if not found
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

## State Patterns

### Pattern 1: Repository Pattern

Separate data access logic from UI.

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

// Provide in application
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final userRepo = UserRepository();
    provide(userRepositoryKey, userRepo);

    return (context) => MaterialApp(home: UserListPage());
  }
}

// Use in UI
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

### Pattern 2: Store Pattern (Similar to Vuex/Pinia)

Centrally manage state, getters, actions, and mutations.

```dart
// Store
class TodoStore {
  // State
  final _todos = ref(<Todo>[]);
  final _filter = ref<TodoFilter>(TodoFilter.all);

  // Getters (readonly)
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

### Pattern 3: Service Pattern

Encapsulate business logic in services.

```dart
// Service
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

      // Save token
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

// Provide all services in application
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

### Pattern 4: Composed State

Compose multiple state sources.

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

// Use in child widget
class Header extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final appState = inject(appStateKey);

    final userName = computed(() {
      return appState.auth.currentUser.value?.name ?? 'Guest';
    });

    return (context) => AppBar(
      title: Text('Welcome, ${userName.value}'),
      actions: [
        IconButton(
          icon: Badge(
            label: Text('${appState.notifications.unreadCount.value}'),
            child: Icon(Icons.notifications),
          ),
          onPressed: () {/* Show notifications */},
        ),
      ],
    );
  }
}
```

## Real-World Example: Shopping Application

Let's build a complete state management system for a shopping application.

### Define Domain Models

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

### Create Stores

```dart
// Product Store
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

// Cart Store
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

// Order Store
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

### Application Root Setup

```dart
const productStoreKey = InjectionKey<ProductStore>('productStore');
const cartStoreKey = InjectionKey<CartStore>('cartStore');
const orderStoreKey = InjectionKey<OrderStore>('orderStore');
// authServiceKey already defined in previous example

class ShoppingApp extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // Create all stores
    final productStore = ProductStore();
    final cartStore = CartStore();
    final orderStore = OrderStore();
    final authService = AuthService();

    // Provide to entire application
    provide(productStoreKey, productStore);
    provide(cartStoreKey, cartStore);
    provide(orderStoreKey, orderStore);
    provide(authServiceKey, authService);

    // Initialize
    onMounted(() async {
      await authService.checkAuth();
      if (authService.isAuthenticated.value) {
        await productStore.fetchProducts();
        await orderStore.fetchOrders();
      }
    });

    // Watch cart changes to save locally
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

### Using Stores in Pages

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
          title: Text('Products'),
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
        // Navigate to order confirmation page
      }
    }

    return (context) {
      if (cartStore.isEmpty.value) {
        return Scaffold(
          appBar: AppBar(title: Text('Cart')),
          body: Center(child: Text('Cart is empty')),
        );
      }

      return Scaffold(
        appBar: AppBar(title: Text('Cart (${cartStore.itemCount.value})')),
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

## Persisting State

### Using SharedPreferences

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

// Usage
const settingsStoreKey = InjectionKey<SettingsStore>('settingsStore');

class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final settings = SettingsStore();
    provide(settingsStoreKey, settings);

    onMounted(() async {
      await settings.load();
    });

    // Watch changes and auto-save
    watchEffect(() {
      settings.save();
    });

    return (context) => MaterialApp(home: HomePage());
  }
}
```

### Using Hive

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

## Best Practices

### 1. Keep State Close to Where It's Used

```dart
// ❌ Bad - All state is global
class GlobalState {
  final buttonColor = ref(Colors.blue);
  final textValue = ref('');
  // ... 100 other fields
}

// ✅ Good - Only share necessary state
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // Only provide truly global state
    final authService = AuthService();
    provide(authServiceKey, authService);

    return (context) => MaterialApp(home: HomePage());
  }
}
```

### 2. Expose State as Readonly References

```dart
// ✅ Good - Prevent external direct modification
class CounterStore {
  final _count = ref(0);

  // Expose as readonly
  ReadonlyRef<int> get count => _count;

  // Modify through methods
  void increment() => _count.value++;
}
```

### 3. Group Related State

```dart
// ✅ Good - Logical grouping
class UserState {
  final profile = ref<UserProfile?>(null);
  final preferences = ref(UserPreferences());
  final settings = ref(UserSettings());
}
```

### 4. Use Computed Instead of Repeated Calculations

```dart
class TodoStore {
  final _todos = ref(<Todo>[]);

  // ✅ Good - Cached computation
  late final activeTodos = computed(() {
    return _todos.value.where((t) => !t.completed).toList();
  });

  // ❌ Bad - Recompute every time
  List<Todo> getActiveTodos() {
    return _todos.value.where((t) => !t.completed).toList();
  }
}
```

### 5. Handle Error States

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

## Testing State Management

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

## Next Steps

- Explore [Dependency Injection](./dependency-injection.md) for deeper understanding of provide/inject
- Learn [Async Operations](./async-operations.md) for handling API calls
- Read [Best Practices](./best-practices.md) for advanced patterns
