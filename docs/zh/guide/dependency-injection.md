# 依賴注入

依賴注入 (Dependency Injection, DI) 是一種設計模式，可讓您在應用程式的不同部分之間共享服務、狀態和配置。本指南將探討如何使用 `provide`/`inject` 實現依賴注入、使用 `InjectionKey` 確保類型安全，以及依賴注入的最佳實踐。

## 為什麼需要依賴注入？

在沒有依賴注入的情況下，您需要透過建構函數傳遞所有依賴項，這會導致：

```dart
// ❌ 沒有 DI - Props 層層傳遞 (Props Drilling)
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      home: HomePage(authService: authService),
    );
  }
}

class HomePage extends StatelessWidget {
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(authService: authService),
        ProfileSection(authService: authService),
      ],
    );
  }
}

class Header extends StatelessWidget {
  final AuthService authService; // 即使 Header 不使用它

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserMenu(authService: authService),
      ],
    );
  }
}

// ✅ 使用 DI - 簡潔且可維護
const authServiceKey = InjectionKey<AuthService>('authService');

class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final authService = AuthService();
    provide(authServiceKey, authService);

    return (context) => MaterialApp(home: HomePage());
  }
}

class UserMenu extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final authService = inject(authServiceKey); // 直接注入

    return (context) => /* ... */;
  }
}
```

## Provide/Inject 基礎

### 基本用法

`provide` 和 `inject` 使用**父鏈查找**（不是 `InheritedWidget`）：

```dart
const themeKey = InjectionKey<ThemeState>('theme');

// 1. 在父 widget 中提供
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ThemeState();
    provide(themeKey, theme); // 提供給所有子孫

    return (context) => MaterialApp(home: HomePage());
  }
}

// 2. 在子 widget 中注入
class ThemedButton extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = inject(themeKey); // 從祖先注入

    return (context) => ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor.value,
      ),
      onPressed: () {},
      child: Text('按鈕'),
    );
  }
}

class ThemeState {
  final primaryColor = ref(Colors.blue);
}
```

### 提供多個值

```dart
// authServiceKey 從前述範例重複使用
const apiServiceKey = InjectionKey<ApiService>('apiService');
const storageServiceKey = InjectionKey<StorageService>('storageService');

class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // 提供多個服務
    final authService = AuthService();
    final apiService = ApiService();
    final storageService = StorageService();

    provide(authServiceKey, authService);
    provide(apiServiceKey, apiService);
    provide(storageServiceKey, storageService);

    return (context) => MaterialApp(home: HomePage());
  }
}

// 在任何地方注入
class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final auth = inject(authServiceKey);
    final api = inject(apiServiceKey);

    return (context) => /* ... */;
  }
}
```

### 提供預設值

如果找不到提供的值，使用預設值：

```dart
const settingsKey = InjectionKey<Settings>('settings');

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final settings = inject(
      settingsKey,
      defaultValue: Settings.defaults(),
    );

    return (context) => /* ... */;
  }
}
```

## InjectionKey - 類型安全的注入

`InjectionKey` 提供類型安全並避免類型衝突：

### 為什麼需要 InjectionKey？

```dart
// ❌ 問題：類型衝突
const sharedStringKey = InjectionKey<Ref<String>>('shared-string');

class ParentA extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    provide(sharedStringKey, ref('Theme A')); // Ref<String>
    return (context) => ChildWidget();
  }
}

class ParentB extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    provide(sharedStringKey, ref('User Name')); // 也是 Ref<String> - 衝突！
    return (context) => ChildWidget();
  }
}

class ChildWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final value = inject(sharedStringKey); // 會取得哪一個？
    return (context) => Text(value.value);
  }
}
```

### 定義 InjectionKey

```dart
// 定義自訂 injection key
class ThemeKey extends InjectionKey<Ref<String>> {
  const ThemeKey();
}

class UserNameKey extends InjectionKey<Ref<String>> {
  const UserNameKey();
}

// 建立 key 實例
const themeKey = ThemeKey();
const userNameKey = UserNameKey();

// 使用 key 提供
class ParentA extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    provide(themeKey, ref('Theme A'));
    return (context) => ChildWidget();
  }
}

class ParentB extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    provide(userNameKey, ref('User Name'));
    return (context) => ChildWidget();
  }
}

// 使用 key 注入 - 明確且類型安全
class ChildWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = inject(themeKey);
    final userName = inject(userNameKey);

    return (context) => Column(
      children: [
        Text('主題: ${theme.value}'),
        Text('使用者: ${userName.value}'),
      ],
    );
  }
}
```

### Key 的命名慣例

```dart
// ✅ 良好 - 描述性名稱
class AuthServiceKey extends InjectionKey<AuthService> {
  const AuthServiceKey();
}

class ApiClientKey extends InjectionKey<ApiClient> {
  const ApiClientKey();
}

const authServiceKey = AuthServiceKey();
const apiClientKey = ApiClientKey();

// ❌ 不良 - 通用名稱
class StringKey extends InjectionKey<String> {}
class IntKey extends InjectionKey<int> {}
```

## 實戰範例

### 範例 1：應用程式層級服務

```dart
// 定義服務
class AuthService {
  final _currentUser = ref<User?>(null);
  final _isAuthenticated = ref(false);

  ReadonlyRef<User?> get currentUser => _currentUser;
  ReadonlyRef<bool> get isAuthenticated => _isAuthenticated;

  Future<void> login(String email, String password) async {
    final user = await api.login(email, password);
    _currentUser.value = user;
    _isAuthenticated.value = true;
  }

  Future<void> logout() async {
    _currentUser.value = null;
    _isAuthenticated.value = false;
  }
}

class ApiService {
  Future<T> get<T>(String endpoint) async {
    // API 邏輯
    throw UnimplementedError();
  }

  Future<T> post<T>(String endpoint, Map<String, dynamic> data) async {
    // API 邏輯
    throw UnimplementedError();
  }
}

class NotificationService {
  final _notifications = ref(<Notification>[]);

  ReadonlyRef<List<Notification>> get notifications => _notifications;

  void show(String message) {
    _notifications.value = [
      ..._notifications.value,
      Notification(message: message, timestamp: DateTime.now()),
    ];
  }

  void clear() {
    _notifications.value = [];
  }
}

const notificationServiceKey =
    InjectionKey<NotificationService>('notificationService');

// 在應用程式根部提供所有服務
class MyApp extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final authService = AuthService();
    final apiService = ApiService();
    final notificationService = NotificationService();

    provide(authServiceKey, authService);
    provide(apiServiceKey, apiService);
    provide(notificationServiceKey, notificationService);

    return (context) => MaterialApp(
      home: HomePage(),
    );
  }
}

// 在任何地方使用
class ProfilePage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final authService = inject(authServiceKey);
    final notificationService = inject(notificationServiceKey);

    void logout() async {
      await authService.logout();
      notificationService.show('已登出');
    }

    return (context) {
      if (!authService.isAuthenticated.value) {
        return LoginPage();
      }

      return Column(
        children: [
          Text('歡迎, ${authService.currentUser.value?.name}'),
          ElevatedButton(
            onPressed: logout,
            child: Text('登出'),
          ),
        ],
      );
    };
  }
}
```

### 範例 2：主題系統

```dart
// 主題服務
class ThemeService {
  final _isDark = ref(false);
  final _primaryColor = ref(Colors.blue);

  ReadonlyRef<bool> get isDark => _isDark;
  ReadonlyRef<Color> get primaryColor => _primaryColor;

  late final themeData = computed(() {
    return ThemeData(
      brightness: _isDark.value ? Brightness.dark : Brightness.light,
      primaryColor: _primaryColor.value,
    );
  });

  void toggleTheme() {
    _isDark.value = !_isDark.value;
  }

  void setPrimaryColor(Color color) {
    _primaryColor.value = color;
  }
}

// 定義 key
class ThemeServiceKey extends InjectionKey<ThemeService> {
  const ThemeServiceKey();
}

const themeServiceKey = ThemeServiceKey();

// 提供
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final themeService = ThemeService();
    provide(themeServiceKey, themeService);

    return (context) => MaterialApp(
      theme: themeService.themeData.value,
      home: HomePage(),
    );
  }
}

// 使用
class ThemeSettings extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = inject(themeServiceKey);

    return (context) => Column(
      children: [
        SwitchListTile(
          title: Text('深色模式'),
          value: theme.isDark.value,
          onChanged: (_) => theme.toggleTheme(),
        ),
        ListTile(
          title: Text('主色'),
          trailing: CircleAvatar(
            backgroundColor: theme.primaryColor.value,
          ),
          onTap: () {
            // 顯示顏色選擇器
          },
        ),
      ],
    );
  }
}
```

### 範例 3：多層注入

```dart
// 應用程式層級配置
class AppConfig {
  final apiBaseUrl = 'https://api.example.com';
  final appName = 'My App';
}

// 功能層級狀態
class TodoFeatureState {
  final todos = ref(<Todo>[]);

  void addTodo(String title) {
    todos.value = [
      ...todos.value,
      Todo(id: DateTime.now().toString(), title: title),
    ];
  }
}

const appConfigKey = InjectionKey<AppConfig>('appConfig');
const todoFeatureStateKey =
    InjectionKey<TodoFeatureState>('todoFeatureState');

// 應用程式根部
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final appConfig = AppConfig();
    provide(appConfigKey, appConfig);

    return (context) => MaterialApp(
      home: HomePage(),
    );
  }
}

// 功能根部
class TodoPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final todoState = TodoFeatureState();
    provide(todoFeatureStateKey, todoState);

    return (context) => Column(
      children: [
        TodoInput(),
        TodoList(),
      ],
    );
  }
}

// 深層子元件
class TodoInput extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final appConfig = inject(appConfigKey); // 從應用程式層級
    final todoState = inject(todoFeatureStateKey); // 從功能層級

    final (controller, text, _) = useTextEditingController();

    void submit() {
      if (text.value.isNotEmpty) {
        todoState.addTodo(text.value);
        controller.value.clear();
      }
    }

    return (context) => Column(
      children: [
        Text(appConfig.appName),
        TextField(
          controller: controller.value,
          onSubmitted: (_) => submit(),
        ),
      ],
    );
  }
}
```

### 範例 4：Repository 模式

```dart
// Repository 介面
abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<User> getUser(String id);
  Future<void> createUser(User user);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String id);
}

// 實作
class ApiUserRepository implements UserRepository {
  final ApiService _api;

  ApiUserRepository(this._api);

  @override
  Future<List<User>> getUsers() async {
    return await _api.get<List<User>>('/users');
  }

  @override
  Future<User> getUser(String id) async {
    return await _api.get<User>('/users/$id');
  }

  @override
  Future<void> createUser(User user) async {
    await _api.post('/users', user.toJson());
  }

  @override
  Future<void> updateUser(User user) async {
    await _api.post('/users/${user.id}', user.toJson());
  }

  @override
  Future<void> deleteUser(String id) async {
    await _api.post('/users/$id/delete', {});
  }
}

// Injection key
class UserRepositoryKey extends InjectionKey<UserRepository> {
  const UserRepositoryKey();
}

const userRepositoryKey = UserRepositoryKey();

// 提供
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final apiService = ApiService();
    final userRepository = ApiUserRepository(apiService);

    provide(apiServiceKey, apiService);
    provide(userRepositoryKey, userRepository);

    return (context) => MaterialApp(home: HomePage());
  }
}

// 使用
class UserList extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final userRepo = inject(userRepositoryKey);

    final (users, refresh) = useAsyncData<List<User>, void>(
      (_) => userRepo.getUsers(),
    );

    onMounted(() => refresh());

    return (context) {
      return switch (users.value) {
        AsyncData(:final value) => ListView.builder(
          itemCount: value.length,
          itemBuilder: (context, index) => UserTile(user: value[index]),
        ),
        AsyncLoading() => CircularProgressIndicator(),
        AsyncError(:final errorValue) => Text('錯誤: $errorValue'),
        AsyncIdle() => SizedBox.shrink(),
      };
    };
  }
}
```

### 範例 5：環境配置

```dart
// 環境配置
enum Environment { development, staging, production }

class EnvConfig {
  final Environment env;
  final String apiUrl;
  final String appName;
  final bool enableLogging;

  const EnvConfig._({
    required this.env,
    required this.apiUrl,
    required this.appName,
    required this.enableLogging,
  });

  factory EnvConfig.development() => const EnvConfig._(
    env: Environment.development,
    apiUrl: 'http://localhost:3000',
    appName: 'My App (Dev)',
    enableLogging: true,
  );

  factory EnvConfig.staging() => const EnvConfig._(
    env: Environment.staging,
    apiUrl: 'https://staging-api.example.com',
    appName: 'My App (Staging)',
    enableLogging: true,
  );

  factory EnvConfig.production() => const EnvConfig._(
    env: Environment.production,
    apiUrl: 'https://api.example.com',
    appName: 'My App',
    enableLogging: false,
  );
}

class EnvConfigKey extends InjectionKey<EnvConfig> {
  const EnvConfigKey();
}

const envConfigKey = EnvConfigKey();

// 提供環境配置
class App extends CompositionWidget {
  final Environment environment;

  const App({required this.environment});

  @override
  Widget Function(BuildContext) setup() {
    final config = switch (environment) {
      Environment.development => EnvConfig.development(),
      Environment.staging => EnvConfig.staging(),
      Environment.production => EnvConfig.production(),
    };

    provide(envConfigKey, config);

    return (context) => MaterialApp(
      title: config.appName,
      home: HomePage(),
    );
  }
}

// 使用
class ApiWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final config = inject(envConfigKey);

    final (data, _) = useAsyncData<Data, void>(
      (_) => fetchData(config.apiUrl),
    );

    if (config.enableLogging) {
      watch(() => data.value, (value, _) {
        print('Data changed: $value');
      });
    }

    return (context) => /* ... */;
  }
}
```

## 服務組合

將相關服務組合在一起：

```dart
// 應用程式服務容器
class AppServices {
  final auth = AuthService();
  final api = ApiService();
  final storage = StorageService();
  final notifications = NotificationService();
  final theme = ThemeService();
}

class AppServicesKey extends InjectionKey<AppServices> {
  const AppServicesKey();
}

const appServicesKey = AppServicesKey();

// 提供
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final services = AppServices();
    provide(appServicesKey, services);

    return (context) => MaterialApp(home: HomePage());
  }
}

// 使用
class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final services = inject(appServicesKey);

    // 存取所有服務
    final isLoggedIn = services.auth.isAuthenticated;
    final isDarkMode = services.theme.isDark;

    return (context) => /* ... */;
  }
}
```

## 測試

依賴注入使測試變得容易：

```dart
void main() {
  testWidgets('UserList shows users', (tester) async {
    // 建立 mock repository
    final mockRepo = MockUserRepository();
    when(mockRepo.getUsers()).thenAnswer((_) async => [
      User(id: '1', name: 'Alice'),
      User(id: '2', name: 'Bob'),
    ]);

    // 建立測試 widget 並提供 mock
    await tester.pumpWidget(
      CompositionBuilder(
        setup: () {
          provide(userRepositoryKey, mockRepo);
          return (context) => MaterialApp(home: UserList());
        },
      ),
    );

    await tester.pumpAndSettle();

    // 驗證
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });
}
```

## 最佳實踐

### 1. 使用 InjectionKey 處理常見類型

```dart
// ✅ 良好 - 明確且類型安全
class UserNameKey extends InjectionKey<Ref<String>> {
  const UserNameKey();
}

provide(userNameKey, ref('John'));

// ❌ 不良 - 容易衝突
provide(sharedStringKey, ref('John')); // Key 太通用，語意不明
```

### 2. 在應用程式根部提供全域服務

```dart
// ✅ 良好 - 應用程式層級服務在根部
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    provide(authServiceKey, AuthService());
    provide(apiServiceKey, ApiService());
    return (context) => MaterialApp(home: HomePage());
  }
}

// ❌ 不良 - 在深層提供全域服務
class SomePage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    provide(authServiceKey, AuthService()); // 這應該在應用程式根部！
    return (context) => /* ... */;
  }
}
```

### 3. 使用唯讀引用暴露狀態

```dart
// ✅ 良好 - 防止外部修改
class UserService {
  final _currentUser = ref<User?>(null);

  ReadonlyRef<User?> get currentUser => _currentUser;

  void setUser(User user) {
    _currentUser.value = user;
  }
}

// ❌ 不良 - 暴露可變引用
class UserService {
  final currentUser = ref<User?>(null); // 任何人都可以修改！
}
```

### 4. 為服務分組

```dart
// ✅ 良好 - 邏輯分組
class AppServices {
  final auth = AuthService();
  final api = ApiService();
}

class FeatureServices {
  final repo = TodoRepository();
  final cache = TodoCache();
}

// ❌ 不良 - 全部混在一起
const todoRepositoryKey = InjectionKey<TodoRepository>('todoRepository');
const todoCacheKey = InjectionKey<TodoCache>('todoCache');
provide(authServiceKey, AuthService());
provide(apiServiceKey, ApiService());
provide(todoRepositoryKey, TodoRepository());
provide(todoCacheKey, TodoCache());
// ... 100 個其他服務
```

### 5. 提供介面而不是實作

```dart
// ✅ 良好 - 提供抽象
abstract class UserRepository {
  Future<List<User>> getUsers();
}

class ApiUserRepository implements UserRepository {
  // 實作
}

provide(userRepositoryKey, ApiUserRepository());

// ❌ 不良 - 提供具體實作
const apiUserRepositoryKey =
    InjectionKey<ApiUserRepository>('apiUserRepository');
provide(apiUserRepositoryKey, ApiUserRepository());
```

### 6. 使用預設值處理可選依賴項

```dart
// ✅ 良好 - 提供合理的預設值
const loggerKey = InjectionKey<Logger>('logger');
final logger = inject(
  loggerKey,
  defaultValue: ConsoleLogger(),
);

// ❌ 不良 - 可能會崩潰
final logger = inject(loggerKey); // 如果未提供會拋出異常
```

## Provide/Inject vs InheritedWidget

Flutter Compositions 使用**父鏈查找**而不是 `InheritedWidget`：

### 優勢

1. **不會傳播重建** - 更改提供的值不會重建整個子樹
2. **響應式追蹤** - 只有使用該值的元件會重建
3. **類型安全** - 使用 `InjectionKey` 的編譯時類型檢查
4. **更簡單** - 不需要建立 `InheritedWidget` 樣板程式碼

### 效能

- **查找**: O(d) 其中 d = widget 樹深度
- **更新**: 只重建使用值的響應式元件
- **記憶體**: 最小開銷，沒有 `InheritedWidget` 機制

## 常見模式

### 模式 1：服務定位器

```dart
class ServiceLocator {
  static final instance = ServiceLocator._();
  ServiceLocator._();

  final _services = <Type, dynamic>{};

  void register<T>(T service) {
    _services[T] = service;
  }

  T get<T>() {
    return _services[T] as T;
  }
}

// 但在 Flutter Compositions 中，使用 provide/inject 更好！
```

### 模式 2：工廠注入

```dart
class RepositoryFactory {
  final ApiService _api;

  RepositoryFactory(this._api);

  UserRepository createUserRepository() {
    return ApiUserRepository(_api);
  }

  ProductRepository createProductRepository() {
    return ApiProductRepository(_api);
  }
}

// 提供工廠
const repositoryFactoryKey =
    InjectionKey<RepositoryFactory>('repositoryFactory');
provide(repositoryFactoryKey, RepositoryFactory(apiService));

// 使用工廠
final factory = inject(repositoryFactoryKey);
final userRepo = factory.createUserRepository();
```

### 模式 3：範圍服務

```dart
const appLevelServiceKey =
    InjectionKey<AppLevelService>('appLevelService');
const featureLevelServiceKey =
    InjectionKey<FeatureLevelService>('featureLevelService');
const widgetLevelServiceKey =
    InjectionKey<WidgetLevelService>('widgetLevelService');

// 應用程式層級
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    provide(appLevelServiceKey, AppLevelService());
    return (context) => MaterialApp(home: HomePage());
  }
}

// 功能層級
class FeaturePage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    provide(featureLevelServiceKey, FeatureLevelService());
    return (context) => FeatureContent();
  }
}

// Widget 層級
class SpecificWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    provide(widgetLevelServiceKey, WidgetLevelService());
    return (context) => /* ... */;
  }
}
```

## 下一步

- 探索[狀態管理](./state-management.md)以了解應用程式狀態模式
- 學習[測試](../testing/testing-guide.md)以了解如何測試依賴注入
- 閱讀 [Provide/Inject 基礎](#provideinject-基礎) 以了解完整 API 參考
