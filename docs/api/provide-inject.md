# provide 與 inject

以型別安全的方式在整個 Widget 樹中共享狀態。

## 概觀

`provide` 與 `inject` 讓祖先與子孫 Widget 之間能共享響應式狀態，而不需要層層傳遞 props。它們透過父層鏈結進行查找，並搭配 `InjectionKey` 取得型別安全性，與 InheritedWidget 的機制不同。

## provide

將值提供給子孫 Widget 使用。

### 方法簽章

```dart
void provide<T>(InjectionKey<T> key, T value)
```

### 範例

```dart
final themeKey = InjectionKey<Ref<AppTheme>>('theme');

class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(AppTheme.light());

    provide(themeKey, theme); // 提供給子孫節點

    return (context) => MaterialApp(home: HomePage());
  }
}
```

## inject

取得由祖先 Widget 提供的值。

### 方法簽章

```dart
T inject<T>(InjectionKey<T> key, {T? defaultValue})
```

### 參數

- `key`：要查找的注入鍵
- `defaultValue`：找不到時的預設值（若未提供且找不到則拋出例外）

### 範例

```dart
class ThemedButton extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = inject(themeKey); // 從祖先取得

    return (context) => ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(theme.value.primary),
      ),
      child: Text('Click me'),
    );
  }
}
```

### 搭配預設值

```dart
final configKey = InjectionKey<AppConfig>('config');

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final config = inject(configKey, defaultValue: AppConfig.defaults());

    return (context) => Text('API: ${config.apiUrl}');
  }
}
```

## 完整示範

```dart
// 1. 定義注入鍵
final userKey = InjectionKey<Ref<User?>>('currentUser');
final apiKey = InjectionKey<ApiService>('api');

// 2. 在根節點提供
class MyApp extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final currentUser = ref<User?>(null);
    final api = ApiService();

    provide(userKey, currentUser);
    provide(apiKey, api);

    onMounted(() async {
      currentUser.value = await api.getCurrentUser();
    });

    return (context) => MaterialApp(home: HomePage());
  }
}

// 3. 在子孫中取用
class UserProfile extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final user = inject(userKey);
    final api = inject(apiKey);

    void logout() async {
      await api.logout();
      user.value = null;
    }

    return (context) => Column(
      children: [
        Text('User: ${user.value?.name ?? "Guest"}'),
        ElevatedButton(
          onPressed: logout,
          child: Text('Logout'),
        ),
      ],
    );
  }
}
```

## 響應式特性

注入的 ref 仍然具備響應式行為：

```dart
// Provider
class ThemeProvider extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(AppTheme.light());

    provide(themeKey, theme);

    return (context) => Column(
      children: [
        ElevatedButton(
          onPressed: () => theme.value = AppTheme.dark(),
          child: Text('Toggle Theme'),
        ),
        child,
      ],
    );
  }
}

// Consumer（當 theme 改變時會重新建構）
class ThemedWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = inject(themeKey);

    return (context) => Container(
      color: theme.value.backgroundColor, // 保持響應式！
    );
  }
}
```

## 巢狀提供者

較接近的提供者會覆蓋外層提供者：

```dart
class OuterProvider extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final value = ref('outer');
    provide(myKey, value);

    return (context) => InnerProvider();
  }
}

class InnerProvider extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final value = ref('inner');
    provide(myKey, value); // 覆蓋外層的值

    return (context) => Consumer();
  }
}

class Consumer extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final value = inject(myKey);

    return (context) => Text(value.value); // 顯示為 "inner"
  }
}
```

## 型別安全

務必使用 `InjectionKey` 來確保型別安全：

```dart
// ❌ 不佳：缺乏型別安全
// 無法區分不同用途的 String
final nameKey = InjectionKey<String>('name');
final emailKey = InjectionKey<String>('email'); // Conflicts!

// ✅ 較佳：包裝為自訂型別
class UserName {
  final String value;
  UserName(this.value);
}

class UserEmail {
  final String value;
  UserEmail(this.value);
}

final nameKey = InjectionKey<Ref<UserName>>('userName');
final emailKey = InjectionKey<Ref<UserEmail>>('userEmail');
```

## 效能

- 查找成本為 **O(d)**（d 為 Widget 樹深度）
- 不會像 InheritedWidget 那樣向下觸發重建
- 透過輕量的父層鏈結搜尋完成

## 最佳實務

### 使用自訂型別

```dart
// ✅ 較佳：自訂型別可避免衝突
class AppTheme {
  final Color primary;
  final Color background;
  AppTheme({required this.primary, required this.background});
}

final themeKey = InjectionKey<Ref<AppTheme>>('theme');
```

### 在根節點提供

```dart
// ✅ 較佳：在應用程式根節點提供全域狀態
class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final auth = ref<AuthState>(AuthState.unauthenticated());
    final router = AppRouter();

    provide(authKey, auth);
    provide(routerKey, router);

    return (context) => MaterialApp.router(...);
  }
}
```

### 為可選依賴提供預設值

```dart
// ✅ 較佳：為可選功能提供預設實作
final analyticsKey = InjectionKey<Analytics>('analytics');

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final analytics = inject(
      analyticsKey,
      defaultValue: NoOpAnalytics(), // 優雅的後備方案
    );

    return (context) => Container();
  }
}
```

## 延伸閱讀

- [InjectionKey](./injection-key.md) - 型別安全的注入鍵
- [ref](./reactivity.md#ref) - 響應式參照
- [CompositionWidget](./composition-widget.md) - 基底 Widget 類別
