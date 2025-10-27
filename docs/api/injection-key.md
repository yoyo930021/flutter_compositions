# InjectionKey

搭配 provide/inject 的型別安全依賴注入鍵。

## 概觀

`InjectionKey` 可以建立唯一且具型別安全的依賴注入鍵，確保不會在不同的注入值之間產生衝突。

## 類別結構

```dart
class InjectionKey<T> {
  const InjectionKey(this.description);

  final String description;
}
```

## 基本用法

```dart
// 定義鍵（通常為全域常數）
final themeKey = InjectionKey<Ref<AppTheme>>('theme');

// 提供
provide(themeKey, ref(AppTheme.light()));

// 取用
final theme = inject(themeKey);
```

## 型別安全性

`InjectionKey` 在比對相等性時會連同泛型型別一起考量：

```dart
final key1 = InjectionKey<String>('config');
final key2 = InjectionKey<int>('config');

// key1 != key2（型別不同）
```

可避免意外的型別衝突：

```dart
final userNameKey = InjectionKey<Ref<String>>('userName');
final userIdKey = InjectionKey<Ref<int>>('userId');

// ✅ 型別安全：不會錯把 userName 當成 userId
final name = inject(userNameKey); // Ref<String>
final id = inject(userIdKey); // Ref<int>
```

## 常見模式

### 應用層級服務

```dart
// services.dart
final apiKey = InjectionKey<ApiService>('api');
final authKey = InjectionKey<Ref<AuthState>>('auth');
final routerKey = InjectionKey<AppRouter>('router');

// app.dart
class MyApp extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    provide(apiKey, ApiService());
    provide(authKey, ref(AuthState.initial()));
    provide(routerKey, AppRouter());

    return (context) => MaterialApp(...);
  }
}
```

### 功能模組狀態

```dart
// features/todo/keys.dart
final todoListKey = InjectionKey<Ref<List<Todo>>>('todoList');
final todoFilterKey = InjectionKey<Ref<TodoFilter>>('todoFilter');

// features/todo/todo_page.dart
class TodoPage extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final todos = ref(<Todo>[]);
    final filter = ref(TodoFilter.all);

    provide(todoListKey, todos);
    provide(todoFilterKey, filter);

    return (context) => TodoListView();
  }
}
```

### 主題與樣式

```dart
final themeKey = InjectionKey<Ref<AppTheme>>('theme');
final localeKey = InjectionKey<Ref<Locale>>('locale');

class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(AppTheme.fromSystem());
    final locale = ref(Locale('en'));

    provide(themeKey, theme);
    provide(localeKey, locale);

    return (context) => MaterialApp(...);
  }
}
```

## 最佳實務

### 使用具描述性的名稱

```dart
// ✅ 較佳：清楚的命名
final currentUserKey = InjectionKey<Ref<User?>>('currentUser');
final userRepositoryKey = InjectionKey<UserRepository>('userRepository');

// ❌ 不佳：語意模糊
final key1 = InjectionKey<Ref<User?>>('user');
final key2 = InjectionKey<UserRepository>('repo');
```

### 將相關鍵集中管理

```dart
// lib/core/injection_keys.dart
class AppKeys {
  // Services
  static final api = InjectionKey<ApiService>('api');
  static final storage = InjectionKey<StorageService>('storage');
  static final analytics = InjectionKey<AnalyticsService>('analytics');

  // State
  static final auth = InjectionKey<Ref<AuthState>>('auth');
  static final settings = InjectionKey<Ref<AppSettings>>('settings');
}

// 使用方式
provide(AppKeys.api, ApiService());
final auth = inject(AppKeys.auth);
```

### 避免使用原始型別

```dart
// ❌ 不佳：原始型別容易衝突
final nameKey = InjectionKey<String>('name');
final emailKey = InjectionKey<String>('email'); // Same type!

// ✅ 較佳：包裝為自訂型別
class UserName {
  final String value;
  const UserName(this.value);
}

class UserEmail {
  final String value;
  const UserEmail(this.value);
}

final nameKey = InjectionKey<Ref<UserName>>('userName');
final emailKey = InjectionKey<Ref<UserEmail>>('userEmail');
```

### 可以的話盡量使用 const

```dart
// ✅ 較佳：使用 const 取得編譯期常數
const themeKey = InjectionKey<Ref<AppTheme>>('theme');
const authKey = InjectionKey<Ref<AuthState>>('auth');
```

## 命名慣例

### 模式：`{feature}{Purpose}Key`

```dart
// 驗證
final authStateKey = InjectionKey<Ref<AuthState>>('authState');
final authServiceKey = InjectionKey<AuthService>('authService');

// 使用者
final currentUserKey = InjectionKey<Ref<User?>>('currentUser');
final userRepositoryKey = InjectionKey<UserRepository>('userRepository');

// 購物車
final cartItemsKey = InjectionKey<Ref<List<CartItem>>>('cartItems');
final cartServiceKey = InjectionKey<CartService>('cartService');
```

## Type Inference

TypeScript-style type inference works:

```dart
final theme = ref(AppTheme.light());
provide(themeKey, theme); // Type inferred as Ref<AppTheme>

final injected = inject(themeKey); // Type is Ref<AppTheme>
```

## Debugging

The `description` helps with debugging:

```dart
final key = InjectionKey<ApiService>('apiService');

// In error messages:
// "InjectionKey<ApiService>('apiService') not found in ancestor chain"
```

## Migration from InheritedWidget

```dart
// Before: InheritedWidget
class ThemeProvider extends InheritedWidget {
  final AppTheme theme;

  static AppTheme of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>()!.theme;
  }
}

// After: InjectionKey + provide/inject
final themeKey = InjectionKey<Ref<AppTheme>>('theme');

// Provide
provide(themeKey, ref(AppTheme.light()));

// Inject
final theme = inject(themeKey);
```

## See Also

- [provide & inject](./provide-inject.md) - Dependency injection
- [ref](./reactivity.md#ref) - Reactive references
- [CompositionWidget](./composition-widget.md) - Base widget class
