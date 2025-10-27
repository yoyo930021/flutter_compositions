# InjectionKey

Type-safe keys for dependency injection with provide/inject.

## Overview

`InjectionKey` creates unique, type-safe keys for dependency injection. It ensures type safety and prevents conflicts between different injected values.

## Signature

```dart
class InjectionKey<T> {
  const InjectionKey(this.description);

  final String description;
}
```

## Basic Usage

```dart
// Define key (usually as global constant)
final themeKey = InjectionKey<Ref<AppTheme>>('theme');

// Provide
provide(themeKey, ref(AppTheme.light()));

// Inject
final theme = inject(themeKey);
```

## Type Safety

`InjectionKey` includes the generic type in equality comparison:

```dart
final key1 = InjectionKey<String>('config');
final key2 = InjectionKey<int>('config');

// key1 != key2 (different types)
```

This prevents accidental type conflicts:

```dart
final userNameKey = InjectionKey<Ref<String>>('userName');
final userIdKey = InjectionKey<Ref<int>>('userId');

// ✅ Type-safe: Can't confuse userName with userId
final name = inject(userNameKey); // Ref<String>
final id = inject(userIdKey); // Ref<int>
```

## Common Patterns

### App-Level Services

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

### Feature-Specific State

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

### Theme and Styling

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

## Best Practices

### Use Descriptive Names

```dart
// ✅ Good: Clear, descriptive names
final currentUserKey = InjectionKey<Ref<User?>>('currentUser');
final userRepositoryKey = InjectionKey<UserRepository>('userRepository');

// ❌ Bad: Vague names
final key1 = InjectionKey<Ref<User?>>('user');
final key2 = InjectionKey<UserRepository>('repo');
```

### Group Related Keys

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

// Usage
provide(AppKeys.api, ApiService());
final auth = inject(AppKeys.auth);
```

### Avoid Primitive Types

```dart
// ❌ Bad: Primitive types cause conflicts
final nameKey = InjectionKey<String>('name');
final emailKey = InjectionKey<String>('email'); // Same type!

// ✅ Good: Wrap in custom types
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

### Use Const When Possible

```dart
// ✅ Good: Const for compile-time constants
const themeKey = InjectionKey<Ref<AppTheme>>('theme');
const authKey = InjectionKey<Ref<AuthState>>('auth');
```

## Naming Conventions

### Pattern: `{feature}{Purpose}Key`

```dart
// Authentication
final authStateKey = InjectionKey<Ref<AuthState>>('authState');
final authServiceKey = InjectionKey<AuthService>('authService');

// User
final currentUserKey = InjectionKey<Ref<User?>>('currentUser');
final userRepositoryKey = InjectionKey<UserRepository>('userRepository');

// Shopping Cart
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
