# Dependency Injection

Dependency injection (DI) lets you share services, configuration, and state across the widget tree without threading them through constructors.

Flutter Compositions ships a minimal DI story built on two APIs:

- `provide(key, value)` stores a value for descendants.
- `inject(key, { defaultValue })` retrieves it later.

The APIs ride on `InjectionKey<T>` so you get compile-time safety.

## Why Dependency Injection?

Without DI you end up threading services through every constructor:

```dart
// ❌ No DI – props drilling everywhere
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
  const HomePage({required this.authService, super.key});
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
  const Header({required this.authService, super.key});
  final AuthService authService; // Even if Header never touches it

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserMenu(authService: authService),
      ],
    );
  }
}

// ✅ With DI – cleaner and easier to maintain
const authServiceKey = InjectionKey<AuthService>('authService');

class App extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final authService = AuthService();
    provide(authServiceKey, authService);

    return (context) => MaterialApp(home: const HomePage());
  }
}

class UserMenu extends CompositionWidget {
  const UserMenu({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final authService = inject(authServiceKey); // Pull only where needed

    return (context) => /* ... */;
  }
}
```

## Defining Keys

Always declare an `InjectionKey<T>` close to the dependency. Keep the symbol descriptive—it becomes part of error messages.

```dart
const authServiceKey = InjectionKey<AuthService>('authService');
const localeKey = InjectionKey<Ref<Locale>>('locale');
```

## Providing Dependencies

Call `provide` inside `setup()`. Provide at the highest level where the dependency is valid, usually an app shell or feature root.

```dart
class AppShell extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final auth = AuthService();
    final locale = ref(const Locale('en'));

    provide(authServiceKey, auth);
    provide(localeKey, locale);

    return (context) => MaterialApp(
          locale: locale.value,
          home: const HomePage(),
        );
  }
}
```

## Injecting Dependencies

Descendants call `inject(key)` inside their own `setup()` methods.

```dart
class ProfileMenu extends CompositionWidget {
  const ProfileMenu({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final auth = inject(authServiceKey);
    final locale = inject(localeKey);

    return (context) => PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(
              onTap: auth.logout,
              child: const Text('Log out'),
            ),
            PopupMenuItem(
              onTap: () => locale.value = const Locale('zh'),
              child: const Text('Switch language'),
            ),
          ],
        );
  }
}
```

## Optional Dependencies

When a dependency is optional, supply a default:

```dart
const loggerKey = InjectionKey<Logger>('logger');

final logger = inject(
  loggerKey,
  defaultValue: ConsoleLogger(),
);
```

## Scope and Overriding

- Keys respect the widget tree. A closer provider shadows any ancestor.
- This makes feature-level overrides easy (e.g., swapping analytics backends in dev builds).
- Providers are disposed automatically with the widget that created them—no extra wiring.

```dart
class FeatureRoot extends CompositionWidget {
  const FeatureRoot({super.key});

  @override
  Widget Function(BuildContext) setup() {
    provide(analyticsKey, DebugAnalytics());
    return (context) => const FeatureContent();
  }
}
```

## Testing Pattern

Wrap widgets under test in a `CompositionBuilder` and call `provide` before returning the widget tree.

```dart
testWidgets('shows user profile', (tester) async {
  final fakeRepo = FakeUserRepository();
  provide(userRepositoryKey, fakeRepo);

  await tester.pumpWidget(
    CompositionBuilder(
      setup: () {
        provide(userRepositoryKey, fakeRepo);
        return (context) => const MaterialApp(home: ProfilePage());
      },
    ),
  );
});
```

## Common Anti-Patterns

- **Omitting keys.** `provide(someService)` compiles, but you lose type safety and risk conflicts.
- **Providing in deep widgets.** Prefer providing once (e.g., app shell) and injecting anywhere.
- **Relying on globals.** Compose services through DI to keep widgets pure and testable.

## Next Steps

- [Best Practices](./best-practices.md)
- [Async Operations](./async-operations.md)
- [Reactivity Fundamentals](./reactivity-fundamentals.md)
