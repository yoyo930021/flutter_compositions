# provide & inject

Type-safe dependency injection for sharing state across the widget tree.

## Overview

`provide` and `inject` allow you to share reactive state between ancestor and descendant widgets without prop drilling. Unlike InheritedWidget, they use a parent chain lookup and work with `InjectionKey` for type safety.

## provide

Provide a value to descendant widgets.

### Signature

```dart
void provide<T>(InjectionKey<T> key, T value)
```

### Example

```dart
final themeKey = InjectionKey<Ref<AppTheme>>('theme');

class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(AppTheme.light());

    provide(themeKey, theme); // Provide to descendants

    return (context) => MaterialApp(home: HomePage());
  }
}
```

## inject

Inject a value provided by an ancestor widget.

### Signature

```dart
T inject<T>(InjectionKey<T> key, {T? defaultValue})
```

### Parameters

- `key` - The injection key to look up
- `defaultValue` - Optional default if not found (throws if not provided and not found)

### Example

```dart
class ThemedButton extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = inject(themeKey); // Inject from ancestor

    return (context) => ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(theme.value.primary),
      ),
      child: Text('Click me'),
    );
  }
}
```

### With Default Value

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

## Complete Example

```dart
// 1. Define injection keys
final userKey = InjectionKey<Ref<User?>>('currentUser');
final apiKey = InjectionKey<ApiService>('api');

// 2. Provide at root
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

// 3. Inject in descendants
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

## Reactivity

Injected refs remain reactive:

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

// Consumer (rebuilds when theme changes)
class ThemedWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = inject(themeKey);

    return (context) => Container(
      color: theme.value.backgroundColor, // Reactive!
    );
  }
}
```

## Nested Providers

Closer providers shadow further ones:

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
    provide(myKey, value); // Shadows outer

    return (context) => Consumer();
  }
}

class Consumer extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final value = inject(myKey);

    return (context) => Text(value.value); // Shows "inner"
  }
}
```

## Type Safety

Always use `InjectionKey` for type safety:

```dart
// ❌ Bad: No type safety
// Can't distinguish between different String values
final nameKey = InjectionKey<String>('name');
final emailKey = InjectionKey<String>('email'); // Conflicts!

// ✅ Good: Wrap in custom types
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

## Performance

- **O(d) lookup** where d = widget tree depth
- No rebuilds propagated (unlike InheritedWidget)
- Lightweight parent chain traversal

## Best Practices

### Use Custom Types

```dart
// ✅ Good: Custom types prevent conflicts
class AppTheme {
  final Color primary;
  final Color background;
  AppTheme({required this.primary, required this.background});
}

final themeKey = InjectionKey<Ref<AppTheme>>('theme');
```

### Provide at Root

```dart
// ✅ Good: Provide global state at app root
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

### Use Defaults for Optional Dependencies

```dart
// ✅ Good: Provide default for optional features
final analyticsKey = InjectionKey<Analytics>('analytics');

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final analytics = inject(
      analyticsKey,
      defaultValue: NoOpAnalytics(), // Graceful fallback
    );

    return (context) => Container();
  }
}
```

## See Also

- [InjectionKey](./injection-key.md) - Type-safe injection keys
- [ref](./reactivity.md#ref) - Reactive references
- [CompositionWidget](./composition-widget.md) - Base widget class
